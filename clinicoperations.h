
#ifndef CLINICOPERATIONS_H
#define CLINICOPERATIONS_H

#include "patientrecord.h"
#include <queue>
#include <stack>
#include <memory>

namespace scapms {

class ClinicOperations
{
private:
    std::queue<std::shared_ptr<PatientRecord>> waitingQueue;

    std::stack<std::shared_ptr<PatientRecord>> undoStack;

public:
    // Waiting queue operations
    void addToWaitingQueue(
        std::shared_ptr<PatientRecord> patient);

    std::shared_ptr<PatientRecord> getNextWaitingPatient();

    int getWaitingCount() const;

    // Undo deletion operations
    void recordDeletedPatient(
        std::shared_ptr<PatientRecord> patient);

    std::shared_ptr<PatientRecord> undoLastDeletion();
};

}

#endif
