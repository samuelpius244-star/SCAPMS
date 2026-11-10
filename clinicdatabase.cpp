
#include "clinicdatabase.h"

namespace scapms {

bool ClinicDatabase::addPatient(
    std::shared_ptr<PatientRecord> patient)
{
    if (!patient) {
        return false;
    }

    if (findPatientById(patient->getPatientId()) != nullptr) {
        return false;
    }

    patients.push_back(patient);
    return true;
}

PatientRecord* ClinicDatabase::findPatientById(
    const QString &id)
{
    // Manual linear search
    for (const auto &patient : patients) {
        if (patient->getPatientId() == id) {
            return patient.get();
        }
    }

    return nullptr;
}

std::shared_ptr<PatientRecord> ClinicDatabase::findSharedPatientById(
    const QString &id, int *comparisons)
{
    int count = 0;

    for (const auto &patient : patients) {
        ++count;

        if (patient->getPatientId() == id) {
            if (comparisons) {
                *comparisons = count;
            }
            return patient;
        }
    }

    if (comparisons) {
        *comparisons = count;
    }

    return nullptr;
}

bool ClinicDatabase::deletePatientById(
    const QString &id)
{
    for (auto it = patients.begin(); it != patients.end(); ++it) {
        if ((*it)->getPatientId() == id) {
            patients.erase(it);
            return true;
        }
    }

    return false;
}

int ClinicDatabase::getPatientCount() const
{
    return static_cast<int>(patients.size());
}

std::vector<std::shared_ptr<PatientRecord>>
ClinicDatabase::getAllPatients() const
{
    return patients;
}

}
