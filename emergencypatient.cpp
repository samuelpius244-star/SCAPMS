
#include "emergencypatient.h"

namespace scapms {

EmergencyPatient::EmergencyPatient(const QString &id,
                                   const QString &name,
                                   int age,
                                   const QString &contact)
    : PatientRecord(id, name, age, contact)
{
}

QString EmergencyPatient::patientType() const
{
    return "Emergency";
}

bool EmergencyPatient::scheduleAppointment(const QString &date,
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

bool EmergencyPatient::cancelAppointment()
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
