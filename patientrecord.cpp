
#include "patientrecord.h"
#include <stdexcept>

namespace scapms {

PatientRecord::PatientRecord(const QString &id,
                             const QString &patientName,
                             int patientAge,
                             const QString &patientContact)
    : patientId(id),
    name(patientName),
    age(patientAge),
    contact(patientContact)
{
    // Reject impossible data so an invalid patient object can never exist.
    if (patientId.trimmed().isEmpty() ||
        name.trimmed().isEmpty() ||
        age < 1 || age > 120) {
        throw std::invalid_argument("Invalid patient data");
    }
}

QString PatientRecord::getPatientId() const
{
    return patientId;
}

QString PatientRecord::getName() const
{
    return name;
}

int PatientRecord::getAge() const
{
    return age;
}

QString PatientRecord::getContact() const
{
    return contact;
}

}
