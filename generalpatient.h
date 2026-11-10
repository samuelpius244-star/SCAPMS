
#ifndef GENERALPATIENT_H
#define GENERALPATIENT_H

#include "patientrecord.h"
#include "appointable.h"

namespace scapms {

class GeneralPatient : public PatientRecord, public Appointable
{
private:
    QString appointmentDate;
    QString appointmentTime;
    bool hasAppointment = false;

public:
    GeneralPatient(const QString &id,
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
