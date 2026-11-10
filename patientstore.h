#ifndef PATIENTSTORE_H
#define PATIENTSTORE_H

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QString>
#include <QVector>
#include <memory>
#include <queue>

#include "clinicdatabase.h"
#include "clinicoperations.h"
#include "appointment.h"
#include "patientcache.h"

namespace scapms {
class PatientRecord;
}

class PatientStore : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QVariantList patients READ patients
                   NOTIFY patientsChanged)

    Q_PROPERTY(QVariantList appointments READ appointments
                   NOTIFY appointmentsChanged)
    Q_PROPERTY(QVariantList waitingQueue READ waitingQueue
                   NOTIFY waitingQueueChanged)
    Q_PROPERTY(QVariantList billingRecords READ billingRecords
                   NOTIFY billingRecordsChanged)

public:
    explicit PatientStore(QObject *parent = nullptr);

    // Patient management
    QVariantList patients() const;

    Q_INVOKABLE bool addPatient(
        const QString &name,
        int age,
        const QString &gender,
        const QString &phone,
        const QString &address,
        const QString &patientType);

    Q_INVOKABLE void removePatient(
        const QString &patientId);

    Q_INVOKABLE bool undoLastDeletion();

    // Patient search
    Q_INVOKABLE QVariantMap searchPatientById(
        const QString &patientId);

    Q_INVOKABLE QVariantMap binarySearchPatientById(
        const QString &patientId);

    // Patient sorting
    Q_INVOKABLE void sortPatientsByName();
    Q_INVOKABLE void sortPatientsByAge();

    // Appointment management
    QVariantList appointments() const;

    Q_INVOKABLE bool scheduleAppointment(
        const QString &patientId,
        const QString &date,
        const QString &time);

    Q_INVOKABLE bool cancelAppointment(
        const QString &patientId,
        const QString &date,
        const QString &time);

    // Waiting queue management
    QVariantList waitingQueue() const;

    Q_INVOKABLE bool addToWaitingQueue(
        const QString &patientId);

    Q_INVOKABLE QVariantMap callNextPatient();

    // Billing management
    QVariantList billingRecords() const;
    Q_INVOKABLE QVariantList getPatientBillingHistory(
        const QString &patientId) const;

    Q_INVOKABLE bool createBill(
        const QString &patientId,
        const QString &service,
        int quantity,
        double unitPrice);

    Q_INVOKABLE bool recordPayment(
        const QString &billId,
        double amount);

    Q_INVOKABLE double getOutstandingBalance(
        const QString &billId) const;

    // Save and restore application data as JSON
    Q_INVOKABLE bool saveData();
    Q_INVOKABLE bool loadData();
    Q_INVOKABLE QString dataFilePath() const;

signals:
    void patientsChanged();
    void appointmentsChanged();
    void waitingQueueChanged();
    void billingRecordsChanged();

private:
    QVariantList m_patients;
    int m_nextId = 1;

    // Stores complete patient details for undo operations
    QVector<QVariantMap> m_deletedPatientDetails;

    // Stores appointment records
    QVector<scapms::Appointment> m_appointments;

    // Stores clinic billing records.
    QVariantList m_billingRecords;
    int m_nextBillId = 1;

    // FIFO queue storing waiting patients by patient ID
    std::queue<QString> m_waitingQueue;

    scapms::ClinicDatabase m_database;
    scapms::ClinicOperations m_operations;

    // File operations. The public saveData()/loadData() call these
    // inside try/catch blocks.
    bool saveDataInternal();
    bool loadDataInternal();

    // Remembers the 5 most recently searched patients.
    scapms::PatientCache m_cache;

    std::shared_ptr<scapms::PatientRecord> createPatientRecord(
        const QString &id,
        const QString &name,
        int age,
        const QString &phone,
        const QString &patientType);
};

#endif