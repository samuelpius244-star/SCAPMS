
#include "patientcache.h"

namespace scapms {

void PatientCache::storePatient(
    std::shared_ptr<PatientRecord> patient)
{
    if (!patient) {
        return;
    }

    cache[nextIndex] = patient;

    nextIndex = (nextIndex + 1) % CACHE_SIZE;
}

PatientRecord* PatientCache::findPatientById(
    const QString &id)
{
    for (const auto &patient : cache) {
        if (patient && patient->getPatientId() == id) {
            return patient.get();
        }
    }

    return nullptr;
}

void PatientCache::clearCache()
{
    for (auto &patient : cache) {
        patient.reset();
    }

    nextIndex = 0;
}

}
