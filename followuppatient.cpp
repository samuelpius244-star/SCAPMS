
#include "followuppatient.h"

namespace scapms {

FollowUpPatient::FollowUpPatient(const QString &id,
                                 const QString &name,
                                 int age,
                                 const QString &contact)
    : PatientRecord(id, name, age, contact)
{
}

QString FollowUpPatient::patientType() const
{
    return "Follow-Up";
}

bool FollowUpPatient::scheduleAppointment(const QString &date,
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

bool FollowUpPatient::cancelAppointment()
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
