
#ifndef PATIENTRECORD_H
#define PATIENTRECORD_H

#include <QString>

namespace scapms {

class PatientRecord
{
protected:
    QString patientId;
    QString name;
    int age;
    QString contact;

public:
    PatientRecord(const QString &id,
                  const QString &patientName,
                  int patientAge,
                  const QString &patientContact);

    virtual ~PatientRecord() = default;

    QString getPatientId() const;
    QString getName() const;
    int getAge() const;
    QString getContact() const;

    // Pure virtual function makes this an abstract class
    virtual QString patientType() const = 0;
};

}

#endif
