
#include "patientalgorithms.h"

namespace scapms {

void PatientAlgorithms::selectionSortByName(
    std::vector<std::shared_ptr<PatientRecord>> &patients)
{
    int n = static_cast<int>(patients.size());

    for (int i = 0; i < n - 1; ++i) {
        int minIndex = i;

        for (int j = i + 1; j < n; ++j) {
            if (patients[j]->getName().toLower()
                < patients[minIndex]->getName().toLower()) {
                minIndex = j;
            }
        }

        if (minIndex != i) {
            auto temp = patients[i];
            patients[i] = patients[minIndex];
            patients[minIndex] = temp;
        }
    }
}

void PatientAlgorithms::insertionSortByAge(
    std::vector<std::shared_ptr<PatientRecord>> &patients)
{
    int n = static_cast<int>(patients.size());

    for (int i = 1; i < n; ++i) {
        auto key = patients[i];
        int j = i - 1;

        while (j >= 0 && patients[j]->getAge() > key->getAge()) {
            patients[j + 1] = patients[j];
            --j;
        }

        patients[j + 1] = key;
    }
}

PatientRecord* PatientAlgorithms::binarySearchById(
    std::vector<std::shared_ptr<PatientRecord>> &patients,
    const QString &id)
{
    return binarySearchByIdRecursive(
        patients, id, 0, static_cast<int>(patients.size()) - 1);
}

PatientRecord* PatientAlgorithms::binarySearchByIdRecursive(
    std::vector<std::shared_ptr<PatientRecord>> &patients,
    const QString &id,
    int left,
    int right)
{
    // Base case: the search range is empty, so the ID is not in the list.
    if (left > right) {
        return nullptr;
    }

    int mid = left + (right - left) / 2;
    QString currentId = patients[mid]->getPatientId();

    // Base case: the middle record is the one we want.
    if (currentId == id) {
        return patients[mid].get();
    }

    // Recursive case: search only the half that can contain the ID.
    if (currentId < id) {
        return binarySearchByIdRecursive(patients, id, mid + 1, right);
    }

    return binarySearchByIdRecursive(patients, id, left, mid - 1);
}

PatientRecord* PatientAlgorithms::binarySearchByIdIterative(
    std::vector<std::shared_ptr<PatientRecord>> &patients,
    const QString &id)
{
    int left = 0;
    int right = static_cast<int>(patients.size()) - 1;

    while (left <= right) {
        int mid = left + (right - left) / 2;
        QString currentId = patients[mid]->getPatientId();

        if (currentId == id) {
            return patients[mid].get();
        }

        if (currentId < id) {
            left = mid + 1;
        } else {
            right = mid - 1;
        }
    }

    return nullptr;
}

void PatientAlgorithms::insertionSortById(
    std::vector<std::shared_ptr<PatientRecord>> &patients)
{
    int n = static_cast<int>(patients.size());

    for (int i = 1; i < n; ++i) {
        auto key = patients[i];
        int j = i - 1;

        while (j >= 0 &&
               patients[j]->getPatientId() > key->getPatientId()) {
            patients[j + 1] = patients[j];
            --j;
        }

        patients[j + 1] = key;
    }
}

}
