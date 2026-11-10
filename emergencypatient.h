
#ifndef EMERGENCYPATIENT_H
#define EMERGENCYPATIENT_H

#include "patientrecord.h"
#include "appointable.h"

namespace scapms {

class EmergencyPatient : public PatientRecord, public Appointable
{
private:
    QString appointmentDate;
    QString appointmentTime;
    bool hasAppointment = false;

public:
    EmergencyPatient(const QString &id,
                     const QString &name,
                     int age,
                     const QString &contact);

    QString patientType() const override;

    bool scheduleAppointment(const QString &date,
                             const QString &time) override;

    bool cancelAppointment() override;
};

}

#endif
