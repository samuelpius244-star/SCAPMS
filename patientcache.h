
#ifndef PATIENTCACHE_H
#define PATIENTCACHE_H

#include "patientrecord.h"
#include <array>
#include <memory>

namespace scapms {

class PatientCache
{
private:
    static constexpr int CACHE_SIZE = 5;

    std::array<std::shared_ptr<PatientRecord>, CACHE_SIZE> cache;
    int nextIndex = 0;

public:
    void storePatient(std::shared_ptr<PatientRecord> patient);

    PatientRecord* findPatientById(const QString &id);

    void clearCache();
};

}

#endif
