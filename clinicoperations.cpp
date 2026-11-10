
#include "clinicoperations.h"

namespace scapms {

void ClinicOperations::addToWaitingQueue(
    std::shared_ptr<PatientRecord> patient)
{
    if (patient) {
        waitingQueue.push(patient);
    }
}

std::shared_ptr<PatientRecord>
ClinicOperations::getNextWaitingPatient()
{
    if (waitingQueue.empty()) {
        return nullptr;
    }

    auto patient = waitingQueue.front();
    waitingQueue.pop();

    return patient;
}

int ClinicOperations::getWaitingCount() const
{
    return static_cast<int>(waitingQueue.size());
}

void ClinicOperations::recordDeletedPatient(
    std::shared_ptr<PatientRecord> patient)
{
    if (patient) {
        undoStack.push(patient);
    }
}

std::shared_ptr<PatientRecord>
ClinicOperations::undoLastDeletion()
{
    if (undoStack.empty()) {
        return nullptr;
    }

    auto patient = undoStack.top();
    undoStack.pop();

    return patient;
}

}
