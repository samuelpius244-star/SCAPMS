#include "patientstore.h"
#include "patientalgorithms.h"
#include "generalpatient.h"
#include "emergencypatient.h"
#include "followuppatient.h"

#include <QVariantMap>
#include <QDate>
#include <QTime>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QStandardPaths>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>
#include <QSet>
#include <cmath>
#include <QDebug>
#include <exception>
#include <stdexcept>

PatientStore::PatientStore(QObject *parent)
    : QObject(parent)
{
}

// Public save: any unexpected exception is caught and reported as a
// failed save instead of crashing the application.
bool PatientStore::saveData()
{
    try {
        return saveDataInternal();
    } catch (const std::exception &error) {
        qWarning() << "Saving failed:" << error.what();
    } catch (...) {
        qWarning() << "Saving failed: unknown error.";
    }

    return false;
}

// Public load: a damaged file or invalid record is caught here, and the
// current data is left unchanged.
bool PatientStore::loadData()
{
    try {
        return loadDataInternal();
    } catch (const std::invalid_argument &error) {
        qWarning() << "Loading failed (invalid record):" << error.what();
    } catch (const std::exception &error) {
        qWarning() << "Loading failed:" << error.what();
    } catch (...) {
        qWarning() << "Loading failed: unknown error.";
    }

    return false;
}

QVariantList PatientStore::patients() const
{
    return m_patients;
}

QVariantList PatientStore::appointments() const
{
    QVariantList result;

    for (const auto &appointment : m_appointments) {
        QVariantMap item;

        item["patientId"] = appointment.getPatientId();
        item["date"] = appointment.getDate();
        item["time"] = appointment.getTime();
        item["status"] = appointment.getStatus();

        for (const auto &patientItem : m_patients) {
            QVariantMap patient = patientItem.toMap();

            if (patient["patientId"].toString()
                == appointment.getPatientId()) {
                item["patientName"] = patient["name"];
                break;
            }
        }

        result.append(item);
    }

    return result;
}

// Return the patients currently in the waiting queue.
QVariantList PatientStore::waitingQueue() const
{
    QVariantList result;

    std::queue<QString> queueCopy = m_waitingQueue;

    while (!queueCopy.empty()) {
        const QString patientId = queueCopy.front();
        queueCopy.pop();

        for (const auto &entry : m_patients) {
            const QVariantMap patient = entry.toMap();

            if (patient.value("patientId").toString() == patientId) {
                QVariantMap waitingPatient;

                waitingPatient["patientId"] = patientId;
                waitingPatient["name"] = patient.value("name");
                waitingPatient["age"] = patient.value("age");
                waitingPatient["patientType"] =
                    patient.value("patientType");

                result.append(waitingPatient);
                break;
            }
        }
    }

    return result;
}

// Add a registered patient to the end of the waiting queue.
bool PatientStore::addToWaitingQueue(const QString &patientId)
{
    const QString cleanId = patientId.trimmed();

    if (cleanId.isEmpty()) {
        return false;
    }

    bool patientExists = false;

    for (const auto &entry : m_patients) {
        const QVariantMap patient = entry.toMap();

        if (patient.value("patientId").toString() == cleanId) {
            patientExists = true;
            break;
        }
    }

    if (!patientExists) {
        return false;
    }

    // Prevent duplicate entries in the waiting queue.
    std::queue<QString> queueCopy = m_waitingQueue;

    while (!queueCopy.empty()) {
        if (queueCopy.front() == cleanId) {
            return false;
        }

        queueCopy.pop();
    }

    m_waitingQueue.push(cleanId);

    emit waitingQueueChanged();

    if (!saveData()) {
        qWarning() << "Failed to save waiting queue.";
    }

    return true;
}

// Call and remove the first patient in the waiting queue.
QVariantMap PatientStore::callNextPatient()
{
    QVariantMap result;

    if (m_waitingQueue.empty()) {
        result["found"] = false;
        result["message"] = "The waiting queue is empty.";
        return result;
    }

    const QString patientId = m_waitingQueue.front();
    m_waitingQueue.pop();

    if (!saveData()) {
        qWarning() << "Failed to save waiting queue.";
    }
    saveData();

    for (const auto &entry : m_patients) {
        const QVariantMap patient = entry.toMap();

        if (patient.value("patientId").toString() == patientId) {
            result["found"] = true;
            result["patientId"] = patientId;
            result["name"] = patient.value("name");
            result["age"] = patient.value("age");
            result["patientType"] = patient.value("patientType");

            emit waitingQueueChanged();

            return result;
        }
    }

    emit waitingQueueChanged();

    result["found"] = false;
    result["message"] = "The queued patient could not be found.";

    return result;
}

// Create the correct patient subclass at runtime.
std::shared_ptr<scapms::PatientRecord>
PatientStore::createPatientRecord(
    const QString &id,
    const QString &name,
    int age,
    const QString &phone,
    const QString &patientType)
{
    if (patientType == "Emergency") {
        return std::make_shared<scapms::EmergencyPatient>(
            id, name, age, phone);
    }

    if (patientType == "Follow-Up") {
        return std::make_shared<scapms::FollowUpPatient>(
            id, name, age, phone);
    }

    return std::make_shared<scapms::GeneralPatient>(
        id, name, age, phone);
}

// Register a patient.
bool PatientStore::addPatient(
    const QString &name,
    int age,
    const QString &gender,
    const QString &phone,
    const QString &address,
    const QString &patientType)
{
    const QString cleanName = name.trimmed();
    const QString cleanGender = gender.trimmed();
    const QString cleanPhone = phone.trimmed();
    const QString cleanAddress = address.trimmed();
    const QString cleanType = patientType.trimmed();

    if (cleanName.isEmpty() ||
        age < 1 || age > 120 ||
        cleanGender.isEmpty() ||
        cleanPhone.isEmpty() ||
        cleanAddress.isEmpty()) {
        return false;
    }

    if (cleanType != "General" &&
        cleanType != "Emergency" &&
        cleanType != "Follow-Up") {
        return false;
    }

    QString id = QString("PAT%1")
                     .arg(m_nextId, 4, 10, QChar('0'));

    std::shared_ptr<scapms::PatientRecord> record;

    try {
        record = createPatientRecord(
            id, cleanName, age, cleanPhone, cleanType);
    } catch (const std::invalid_argument &error) {
        qWarning() << "Patient rejected:" << error.what();
        return false;
    }

    if (!m_database.addPatient(record)) {
        return false;
    }

    QVariantMap patient;
    patient["patientId"] = id;
    patient["name"] = cleanName;
    patient["age"] = age;
    patient["gender"] = cleanGender;
    patient["phone"] = cleanPhone;
    patient["address"] = cleanAddress;
    patient["patientType"] = record->patientType();

    m_patients.append(patient);
    ++m_nextId;

    emit patientsChanged();

    return true;
}

// Remove a patient and keep the information needed for undo.
void PatientStore::removePatient(const QString &patientId)
{
    for (qsizetype i = 0; i < m_patients.size(); ++i) {
        QVariantMap patient = m_patients.at(i).toMap();

        if (patient["patientId"].toString() != patientId) {
            continue;
        }

        auto records = m_database.getAllPatients();
        std::shared_ptr<scapms::PatientRecord> record;

        for (const auto &item : records) {
            if (item->getPatientId() == patientId) {
                record = item;
                break;
            }
        }

        if (!record) {
            return;
        }

        // Keep the display information for undo.
        m_deletedPatientDetails.append(patient);

        // Keep the actual C++ object for undo.
        m_operations.recordDeletedPatient(record);

        if (m_database.deletePatientById(patientId)) {
            m_cache.clearCache();
            m_patients.removeAt(i);
            emit patientsChanged();
        } else {
            m_deletedPatientDetails.removeLast();
            m_operations.undoLastDeletion();
        }

        return;
    }
}

bool PatientStore::undoLastDeletion()
{
    if (m_deletedPatientDetails.isEmpty()) {
        return false;
    }

    auto record = m_operations.undoLastDeletion();

    if (!record) {
        return false;
    }

    if (!m_database.addPatient(record)) {
        m_operations.recordDeletedPatient(record);
        return false;
    }

    QVariantMap patient = m_deletedPatientDetails.takeLast();
    m_patients.append(patient);

    emit patientsChanged();

    return true;
}

QVariantMap PatientStore::searchPatientById(
    const QString &patientId)
{
    QVariantMap result;
    const QString cleanId = patientId.trimmed();

    // 1. Check the cache of the 5 most recently found patients.
    scapms::PatientRecord *patient = m_cache.findPatientById(cleanId);
    int comparisons = 0;
    QString source = "recent-patient cache";

    // 2. Otherwise do a linear search of the clinic database.
    if (!patient) {
        auto shared = m_database.findSharedPatientById(
            cleanId, &comparisons);

        if (shared) {
            m_cache.storePatient(shared);
            patient = shared.get();
        }

        source = "patient list";
    }

    result["comparisons"] = comparisons;
    result["source"] = source;

    if (!patient) {
        result["found"] = false;
        result["message"] = "Patient not found.";
        return result;
    }

    result["found"] = true;
    result["patientId"] = patient->getPatientId();
    result["name"] = patient->getName();
    result["age"] = patient->getAge();
    result["contact"] = patient->getContact();
    result["patientType"] = patient->patientType();

    return result;
}

QVariantMap PatientStore::binarySearchPatientById(
    const QString &patientId)
{
    QVariantMap result;

    auto sortedPatients = m_database.getAllPatients();

    scapms::PatientAlgorithms::insertionSortById(sortedPatients);

    auto *patient = scapms::PatientAlgorithms::binarySearchById(
        sortedPatients, patientId.trimmed());

    if (!patient) {
        result["found"] = false;
        result["message"] = "Patient not found.";
        return result;
    }

    result["found"] = true;
    result["patientId"] = patient->getPatientId();
    result["name"] = patient->getName();
    result["age"] = patient->getAge();
    result["contact"] = patient->getContact();
    result["patientType"] = patient->patientType();

    return result;
}

void PatientStore::sortPatientsByName()
{
    auto sortedPatients = m_database.getAllPatients();

    scapms::PatientAlgorithms::selectionSortByName(sortedPatients);

    QVariantList sortedList;

    for (const auto &record : sortedPatients) {
        for (const auto &item : m_patients) {
            QVariantMap patient = item.toMap();

            if (patient["patientId"].toString()
                == record->getPatientId()) {
                sortedList.append(patient);
                break;
            }
        }
    }

    m_patients = sortedList;
    emit patientsChanged();
}

void PatientStore::sortPatientsByAge()
{
    auto sortedPatients = m_database.getAllPatients();

    scapms::PatientAlgorithms::insertionSortByAge(sortedPatients);

    QVariantList sortedList;

    for (const auto &record : sortedPatients) {
        for (const auto &item : m_patients) {
            QVariantMap patient = item.toMap();

            if (patient["patientId"].toString()
                == record->getPatientId()) {
                sortedList.append(patient);
                break;
            }
        }
    }

    m_patients = sortedList;
    emit patientsChanged();
}

// Schedule an appointment for a registered patient.
bool PatientStore::scheduleAppointment(
    const QString &patientId,
    const QString &date,
    const QString &time)
{
    if (!m_database.findPatientById(patientId.trimmed())) {
        return false;
    }

    QDate appointmentDate = QDate::fromString(
        date, "yyyy-MM-dd");

    QTime appointmentTime = QTime::fromString(
        time, "HH:mm");

    if (!appointmentDate.isValid() ||
        !appointmentTime.isValid()) {
        return false;
    }

    // Prevent duplicate scheduled appointments.
    for (const auto &appointment : m_appointments) {
        if (appointment.getPatientId() == patientId &&
            appointment.getDate() == date &&
            appointment.getTime() == time &&
            appointment.getStatus() == "Scheduled") {
            return false;
        }
    }

    scapms::Appointment appointment(patientId, date, time);

    m_appointments.append(appointment);

    emit appointmentsChanged();

    return true;
}

// Cancel a scheduled appointment.
bool PatientStore::cancelAppointment(
    const QString &patientId,
    const QString &date,
    const QString &time)
{
    for (auto &appointment : m_appointments) {
        if (appointment.getPatientId() == patientId &&
            appointment.getDate() == date &&
            appointment.getTime() == time &&
            appointment.getStatus() == "Scheduled") {

            appointment.setStatus("Cancelled");
            saveData();
            emit appointmentsChanged();

            return true;
        }
    }

    return false;
}

// Location of the JSON file used by Save and Load.
QString PatientStore::dataFilePath() const
{
    return QStandardPaths::writableLocation(
               QStandardPaths::DocumentsLocation)
           + "/SCAPMS/scapms_data.json";
}

// Save patient records, appointments and the waiting queue to JSON.
bool PatientStore::saveDataInternal()
{
    const QString path = dataFilePath();
    const QFileInfo fileInfo(path);

    if (!QDir().mkpath(fileInfo.absolutePath())) {
        return false;
    }

    QJsonArray patientArray;

    for (const auto &entry : m_patients) {
        const QVariantMap patient = entry.toMap();

        QJsonObject object;
        object["patientId"] =
            patient.value("patientId").toString();
        object["name"] =
            patient.value("name").toString();
        object["age"] =
            patient.value("age").toInt();
        object["gender"] =
            patient.value("gender").toString();
        object["phone"] =
            patient.value("phone").toString();
        object["address"] =
            patient.value("address").toString();
        object["patientType"] =
            patient.value("patientType").toString();

        patientArray.append(object);
    }

    QJsonArray appointmentArray;

    for (const auto &appointment : m_appointments) {
        QJsonObject object;
        object["patientId"] = appointment.getPatientId();
        object["date"] = appointment.getDate();
        object["time"] = appointment.getTime();
        object["status"] = appointment.getStatus();

        appointmentArray.append(object);
    }

    // Save the waiting queue in FIFO order without emptying it.
    QJsonArray waitingQueueArray;

    std::queue<QString> queueCopy = m_waitingQueue;

    while (!queueCopy.empty()) {
        waitingQueueArray.append(queueCopy.front());
        queueCopy.pop();
    }

    // Save billing records.
    QJsonArray billingArray;

    for (const QVariant &entry : m_billingRecords) {
        const QVariantMap bill = entry.toMap();

        QJsonObject object;
        object["billId"] = bill.value("billId").toString();
        object["patientId"] = bill.value("patientId").toString();
        object["service"] = bill.value("service").toString();
        object["quantity"] = bill.value("quantity").toInt();
        object["unitPrice"] = bill.value("unitPrice").toDouble();
        object["total"] = bill.value("total").toDouble();
        object["amountPaid"] = bill.value("amountPaid").toDouble();
        object["status"] = bill.value("status").toString();

        billingArray.append(object);
    }

    QJsonObject root;
    root["format"] = "SCAPMS_DATA_V1";
    root["patients"] = patientArray;
    root["appointments"] = appointmentArray;
    root["waitingQueue"] = waitingQueueArray;
    root["billingRecords"] = billingArray;
    root["nextBillId"] = m_nextBillId;

    QFile file(path);

    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        return false;
    }
    const QByteArray jsonData =
        QJsonDocument(root).toJson(QJsonDocument::Indented);

    const qint64 written = file.write(jsonData);

    file.close();

    return written == jsonData.size();
}

// Load and validate saved patients, appointments and waiting queue.
bool PatientStore::loadDataInternal()
{
    const QString path = dataFilePath();

    QFile file(path);

    if (!file.open(QIODevice::ReadOnly)) {
        return false;
    }

    QJsonParseError parseError;

    const QJsonDocument document =
        QJsonDocument::fromJson(file.readAll(), &parseError);

    file.close();

    if (parseError.error != QJsonParseError::NoError ||
        !document.isObject()) {
        return false;
    }

    const QJsonObject root = document.object();

    if (root.value("format").toString() != "SCAPMS_DATA_V1" ||
        !root.value("patients").isArray() ||
        !root.value("appointments").isArray()) {
        return false;
    }


    // Validate patient data before replacing the current data.
    const QJsonArray patientArray =
        root.value("patients").toArray();

    QVariantList loadedPatients;

    QVector<std::shared_ptr<scapms::PatientRecord>> loadedRecords;

    int nextId = 1;

    for (const QJsonValue &value : patientArray) {
        if (!value.isObject()) {
            return false;
        }

        const QJsonObject object = value.toObject();

        const QString id =
            object.value("patientId").toString().trimmed();

        const QString name =
            object.value("name").toString().trimmed();

        const int age = object.value("age").toInt(-1);

        const QString gender =
            object.value("gender").toString().trimmed();

        const QString phone =
            object.value("phone").toString().trimmed();

        const QString address =
            object.value("address").toString().trimmed();

        // Older saved files may not contain patientType.
        QString patientType =
            object.value("patientType").toString("General").trimmed();

        if (patientType.isEmpty()) {
            patientType = "General";
        }

        if (id.isEmpty() ||
            name.isEmpty() ||
            age < 1 || age > 120 ||
            gender.isEmpty() ||
            phone.isEmpty() ||
            address.isEmpty()) {
            return false;
        }

        if (patientType != "General" &&
            patientType != "Emergency" &&
            patientType != "Follow-Up") {
            return false;
        }

        for (const auto &existing : loadedPatients) {
            if (existing.toMap().value("patientId").toString() == id) {
                return false;
            }
        }

        // Recreate the correct subclass from the saved type.
        auto record = createPatientRecord(
            id, name, age, phone, patientType);

        loadedRecords.append(record);

        QVariantMap patient;
        patient["patientId"] = id;
        patient["name"] = name;
        patient["age"] = age;
        patient["gender"] = gender;
        patient["phone"] = phone;
        patient["address"] = address;
        patient["patientType"] = record->patientType();

        loadedPatients.append(patient);

        if (id.startsWith("PAT")) {
            bool ok = false;
            const int number = id.mid(3).toInt(&ok);

            if (ok && number >= nextId) {
                nextId = number + 1;
            }
        }
    }

    // Validate appointment data.
    const QJsonArray appointmentArray =
        root.value("appointments").toArray();

    QVector<scapms::Appointment> loadedAppointments;

    for (const QJsonValue &value : appointmentArray) {
        if (!value.isObject()) {
            return false;
        }

        const QJsonObject object = value.toObject();

        const QString patientId =
            object.value("patientId").toString();

        const QString date =
            object.value("date").toString();

        const QString time =
            object.value("time").toString();

        const QString status =
            object.value("status").toString("Scheduled");

        bool patientExists = false;

        for (const auto &patient : loadedPatients) {
            if (patient.toMap().value("patientId").toString()
                == patientId) {
                patientExists = true;
                break;
            }
        }

        if (!patientExists ||
            !QDate::fromString(date, "yyyy-MM-dd").isValid() ||
            !QTime::fromString(time, "HH:mm").isValid()) {
            return false;
        }

        if (status != "Scheduled" && status != "Cancelled") {
            if (status != "Scheduled" &&
                status != "Completed" &&
                status != "Cancelled") {
                return false;
            }
        }

        scapms::Appointment appointment(patientId, date, time);
        appointment.setStatus(status);

        loadedAppointments.append(appointment);
    }

    // Restore the waiting queue. Older files without this field
    // remain compatible and simply load with an empty queue.
    std::queue<QString> loadedWaitingQueue;
    QSet<QString> queuedPatientIds;

    if (root.contains("waitingQueue")) {
        if (!root.value("waitingQueue").isArray()) {
            return false;
        }

        const QJsonArray waitingQueueArray =
            root.value("waitingQueue").toArray();

        for (const QJsonValue &value : waitingQueueArray) {
            if (!value.isString()) {
                return false;
            }

            const QString patientId = value.toString().trimmed();

            if (patientId.isEmpty()) {
                continue;
            }

            bool patientExists = false;

            for (const auto &entry : loadedPatients) {
                const QVariantMap patient = entry.toMap();

                if (patient.value("patientId").toString() == patientId) {
                    patientExists = true;
                    break;
                }
            }

            // Keep only existing patients and prevent duplicate IDs.
            if (patientExists &&
                !queuedPatientIds.contains(patientId)) {
                loadedWaitingQueue.push(patientId);
                queuedPatientIds.insert(patientId);
            }
        }
    }

    // Restore billing records before replacing the current data.
    QVariantList loadedBillingRecords;
    QSet<QString> loadedBillIds;
    int nextBillId = 1;

    if (root.contains("billingRecords")) {
        if (!root.value("billingRecords").isArray()) {
            return false;
        }

        const QJsonArray billingArray =
            root.value("billingRecords").toArray();

        for (const QJsonValue &value : billingArray) {
            if (!value.isObject()) {
                return false;
            }

            const QJsonObject object = value.toObject();

            const QString billId =
                object.value("billId").toString().trimmed();

            const QString patientId =
                object.value("patientId").toString().trimmed();

            const QString service =
                object.value("service").toString().trimmed();

            const double quantityValue =
                object.value("quantity").toDouble(-1);

            const double unitPrice =
                object.value("unitPrice").toDouble(-1);

            const double total =
                object.value("total").toDouble(-1);

            const double amountPaid =
                object.value("amountPaid").toDouble(-1);

            const QString status =
                object.value("status").toString();

            // Confirm the bill belongs to a registered patient.
            bool patientExists = false;

            for (const QVariant &entry : loadedPatients) {
                const QVariantMap patient = entry.toMap();

                if (patient.value("patientId").toString() == patientId) {
                    patientExists = true;
                    break;
                }
            }

            if (billId.isEmpty() ||
                patientId.isEmpty() ||
                service.isEmpty() ||
                !patientExists ||
                !object.value("quantity").isDouble() ||
                quantityValue < 1 ||
                std::floor(quantityValue) != quantityValue ||
                quantityValue > 1000000 ||
                !std::isfinite(unitPrice) ||
                unitPrice < 0 ||
                !std::isfinite(total) ||
                !std::isfinite(amountPaid) ||
                amountPaid < 0 ||
                amountPaid > total + 0.000001) {
                return false;
            }

            // Check that the saved total matches quantity x unit price.
            const double expectedTotal = quantityValue * unitPrice;

            if (!std::isfinite(expectedTotal) ||
                std::abs(expectedTotal - total) > 0.000001) {
                return false;
            }

            // Reject duplicate bill IDs.
            if (loadedBillIds.contains(billId)) {
                return false;
            }

            // Validate the payment status.
            QString expectedStatus;

            if (total == 0.0) {
                expectedStatus = "Paid";
            } else if (amountPaid >= total - 0.000001) {
                expectedStatus = "Paid";
            } else if (amountPaid > 0) {
                expectedStatus = "Partially Paid";
            } else {
                expectedStatus = "Unpaid";
            }

            if (status != expectedStatus) {
                return false;
            }

            QVariantMap bill;
            bill["billId"] = billId;
            bill["patientId"] = patientId;
            bill["service"] = service;
            bill["quantity"] = static_cast<int>(quantityValue);
            bill["unitPrice"] = unitPrice;
            bill["total"] = total;
            bill["amountPaid"] = amountPaid;
            bill["status"] = status;

            loadedBillingRecords.append(bill);
            loadedBillIds.insert(billId);

            // Determine the next available bill number.
            if (billId.startsWith("BILL")) {
                bool ok = false;
                const int number = billId.mid(4).toInt(&ok);

                if (ok && number >= nextBillId &&
                    number < 2147483647) {
                    nextBillId = number + 1;
                }
            }
        }
    }

    // Restore the saved counter, if present.
    if (root.contains("nextBillId")) {
        const QJsonValue savedCounter = root.value("nextBillId");

        if (!savedCounter.isDouble()) {
            return false;
        }

        const double savedNumber = savedCounter.toDouble();

        if (!std::isfinite(savedNumber) ||
            savedNumber < 1 ||
            savedNumber > 2147483647 ||
            std::floor(savedNumber) != savedNumber) {
            return false;
        }

        nextBillId = qMax(
            nextBillId,
            static_cast<int>(savedNumber));
    }

    // Replace the current database after validation.
    const auto oldRecords = m_database.getAllPatients();

    for (const auto &record : oldRecords) {
        m_database.deletePatientById(record->getPatientId());
    }

    for (const auto &record : loadedRecords) {
        if (!m_database.addPatient(record)) {
            // Restore the old database if an insertion fails.
            for (const auto &inserted : loadedRecords) {
                m_database.deletePatientById(
                    inserted->getPatientId());
            }

            for (const auto &oldRecord : oldRecords) {
                m_database.addPatient(oldRecord);
            }

            return false;
        }
    }


    m_cache.clearCache();
    m_patients = loadedPatients;
    m_appointments = loadedAppointments;
    m_waitingQueue = loadedWaitingQueue;
    m_nextId = nextId;

    // Restore saved bills and the next bill number.
    m_billingRecords = loadedBillingRecords;
    m_nextBillId = nextBillId;

    m_deletedPatientDetails.clear();

    emit patientsChanged();
    emit appointmentsChanged();
    emit waitingQueueChanged();
    emit billingRecordsChanged();

    return true;

}

QVariantList PatientStore::billingRecords() const
{
    return m_billingRecords;
}
QVariantList PatientStore::getPatientBillingHistory(
    const QString &patientId) const
{
    QVariantList history;

    // An empty patient ID means show all billing records.
    for (const QVariant &record : m_billingRecords) {
        QVariantMap bill = record.toMap();

        if (patientId.isEmpty() ||
            bill.value("patientId").toString() == patientId) {

            double total = bill.value("total").toDouble();
            double amountPaid = bill.value("amountPaid").toDouble();

            double balance = total - amountPaid;

            // Prevent tiny floating-point errors from showing
            // a negative outstanding balance.
            if (balance < 0.0 && balance > -0.000001) {
                balance = 0.0;
            }

            bill.insert("balance", balance);

            // Calculate the status from the actual amounts.
            QString status;

            if (total <= 0.0 || balance <= 0.000001) {
                status = "Paid";
            } else if (amountPaid > 0.0) {
                status = "Partially Paid";
            } else {
                status = "Unpaid";
            }

            bill.insert("status", status);

            history.append(bill);
        }
    }

    return history;
}
// Create a bill for an existing registered patient.
bool PatientStore::createBill(
    const QString &patientId,
    const QString &service,
    int quantity,
    double unitPrice)
{
    const QString cleanId = patientId.trimmed();
    const QString cleanService = service.trimmed();

    // Check that the patient exists.
    if (!m_database.findPatientById(cleanId)) {
        return false;
    }

    // Validate the bill details.
    if (cleanService.isEmpty() ||
        quantity < 1 ||
        !std::isfinite(unitPrice) ||
        unitPrice < 0) {
        return false;
    }

    const double total = quantity * unitPrice;

    if (!std::isfinite(total)) {
        return false;
    }

    QVariantMap bill;

    bill["billId"] = QString("BILL%1")
                         .arg(m_nextBillId, 4, 10, QChar('0'));
    bill["patientId"] = cleanId;
    bill["service"] = cleanService;
    bill["quantity"] = quantity;
    bill["unitPrice"] = unitPrice;
    bill["total"] = total;
    bill["amountPaid"] = 0.0;
    bill["status"] = "Unpaid";

    m_billingRecords.append(bill);
    ++m_nextBillId;

    emit billingRecordsChanged();

    if (!saveData()) {
        return false;
    }

    return true;
}

// Record a payment against an existing bill.

bool PatientStore::recordPayment(
    const QString &billId,
    double amount)
{
    const QString cleanBillId = billId.trimmed();

    if (cleanBillId.isEmpty() ||
        !std::isfinite(amount) ||
        amount <= 0) {
        return false;
    }

    for (qsizetype i = 0; i < m_billingRecords.size(); ++i) {
        QVariantMap bill = m_billingRecords.at(i).toMap();

        if (bill.value("billId").toString() != cleanBillId) {
            continue;
        }

        const double total = bill.value("total").toDouble();
        const double amountPaid = bill.value("amountPaid").toDouble();

        if (!std::isfinite(total) ||
            !std::isfinite(amountPaid) ||
            amountPaid + amount > total + 0.000001) {
            return false;
        }

        const double newAmountPaid = amountPaid + amount;

        bill["amountPaid"] = newAmountPaid;

        if (newAmountPaid >= total - 0.000001) {
            bill["amountPaid"] = total;
            bill["status"] = "Paid";
        } else {
            bill["status"] = "Partially Paid";
        }

        // IMPORTANT: Store the modified bill back into the list.
        m_billingRecords[i] = bill;

        emit billingRecordsChanged();

        if (!saveData()) {
            return false;
        }

        return true;
    }

    return false;
}

// Return the unpaid balance for a bill.
// Returns -1 if the bill ID cannot be found.
double PatientStore::getOutstandingBalance(
    const QString &billId) const
{
    const QString cleanBillId = billId.trimmed();

    for (const QVariant &entry : m_billingRecords) {
        const QVariantMap bill = entry.toMap();

        if (bill.value("billId").toString() == cleanBillId) {
            const double total =
                bill.value("total").toDouble();

            const double amountPaid =
                bill.value("amountPaid").toDouble();

            return qMax(0.0, total - amountPaid);
        }
    }

    return -1.0;
}