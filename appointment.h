
#ifndef APPOINTMENT_H
#define APPOINTMENT_H

#include <QString>

namespace scapms {

class Appointment
{
private:
    QString patientId;
    QString date;
    QString time;
    QString status;

public:
    Appointment(const QString &id,
                const QString &appointmentDate,
                const QString &appointmentTime);

    virtual ~Appointment() = default;

    QString getPatientId() const;
    QString getDate() const;
    QString getTime() const;
    QString getStatus() const;

    void setStatus(const QString &newStatus);
};

}

#endif
