
#ifndef APPOINTABLE_H
#define APPOINTABLE_H

#include <QString>

namespace scapms {

class Appointable
{
public:
    virtual ~Appointable() = default;

    virtual bool scheduleAppointment(
        const QString &date,
        const QString &time
        ) = 0;

    virtual bool cancelAppointment() = 0;
};

}

#endif

