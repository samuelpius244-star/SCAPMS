
#ifndef PATIENTALGORITHMS_H
#define PATIENTALGORITHMS_H

#include "patientrecord.h"
#include <vector>
#include <memory>

namespace scapms {

class PatientAlgorithms
{
public:
    static void selectionSortByName(
        std::vector<std::shared_ptr<PatientRecord>> &patients);

    static void insertionSortByAge(
        std::vector<std::shared_ptr<PatientRecord>> &patients);
    static void insertionSortById(
        std::vector<std::shared_ptr<PatientRecord>> &patients);

    // Public entry point: binary search on a list sorted by ID.
    // It starts the recursive search over the whole list.
    static PatientRecord* binarySearchById(
        std::vector<std::shared_ptr<PatientRecord>> &patients,
        const QString &id);

    // Recursive binary search: each call searches patients[left..right]
    // and calls itself on the left or right half.
    static PatientRecord* binarySearchByIdRecursive(
        std::vector<std::shared_ptr<PatientRecord>> &patients,
        const QString &id,
        int left,
        int right);

    // Original loop-based version, kept for comparison.
    static PatientRecord* binarySearchByIdIterative(
        std::vector<std::shared_ptr<PatientRecord>> &patients,
        const QString &id);
};

}

#endif
