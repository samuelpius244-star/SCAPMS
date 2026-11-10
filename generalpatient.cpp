
#include "generalpatient.h"

namespace scapms {

GeneralPatient::GeneralPatient(const QString &id,
                               const QString &name,
                               int age,
                               const QString &contact)
    : PatientRecord(id, name, age, contact)
{
}

QString GeneralPatient::patientType() const
{
    return "General";
}

bool GeneralPatient::scheduleAppointment(const QString &date,
                                         const QString &time)
{
    if (date.trimmed().isEmpty() || time.trimmed().isEmpty()) {
        return false;
    }

    appointmentDate = date;
    appointmentTime = time;
    hasAppointment = true;

    return true;
}

bool GeneralPatient::cancelAppointment()
{
    if (!hasAppointment) {
        return false;
    }

    hasAppointment = false;
    appointmentDate.clear();
    appointmentTime.clear();

    return true;
}

}
