
#include "appointment.h"

namespace scapms {

Appointment::Appointment(const QString &id,
                         const QString &appointmentDate,
                         const QString &appointmentTime)
    : patientId(id),
    date(appointmentDate),
    time(appointmentTime),
    status("Scheduled")
{
}

QString Appointment::getPatientId() const
{
    return patientId;
}

QString Appointment::getDate() const
{
    return date;
}

QString Appointment::getTime() const
{
    return time;
}

QString Appointment::getStatus() const
{
    return status;
}

void Appointment::setStatus(const QString &newStatus)
{
    status = newStatus;
}

}
