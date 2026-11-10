
#ifndef CLINICDATABASE_H
#define CLINICDATABASE_H

#include "patientrecord.h"
#include <vector>
#include <memory>

namespace scapms {

class ClinicDatabase
{
private:
    std::vector<std::shared_ptr<PatientRecord>> patients;

public:
    bool addPatient(std::shared_ptr<PatientRecord> patient);

    PatientRecord* findPatientById(const QString &id);

    // Linear search that returns the shared pointer (so it can be cached)
    // and reports how many records were compared.
    std::shared_ptr<PatientRecord> findSharedPatientById(
        const QString &id, int *comparisons = nullptr);

    bool deletePatientById(const QString &id);

    int getPatientCount() const;

    std::vector<std::shared_ptr<PatientRecord>> getAllPatients() const;
};

}

#endif
