
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

ApplicationWindow {
    id: window

    visible: true
    width: 1100
    height: 720
    minimumWidth: 800
    minimumHeight: 550
    title: "SCAPMS | Smart Clinic Management"
    color: "#f4f6f9"

    property string currentPage: "Dashboard"
    property string searchText: ""
    property string message: ""
    property string billingPatientFilter: ""
    property int billingRefreshKey: 0
    property string lastSearchAlgorithm: "None"
    property string lastSearchResult: "No search performed yet."
    property int lastSearchComparisons: 0

    Component.onCompleted: {
        if (patientStore.loadData()) {
            console.log("SCAPMS data loaded successfully.")
        } else {
            console.log("No saved data found yet.")
        }
    }

    // ---------------- GENERAL FUNCTIONS ----------------

    function filteredPatients() {
        var result = []
        var query = searchText.toLowerCase().trim()
        var records = patientStore.patients

        for (var i = 0; i < records.length; i++) {
            var p = records[i]
            var patientName = String(p.name || "").toLowerCase()
            var patientId = String(p.patientId || "").toLowerCase()

            if (query === "" ||
                patientName.indexOf(query) !== -1 ||
                patientId.indexOf(query) !== -1) {
                result.push(p)
            }
        }

        return result
    }

    function sortPatientsByName() {
        patientStore.sortPatientsByName()
        window.message = "Patients sorted alphabetically by name."
    }

    function sortPatientsByAge() {
        patientStore.sortPatientsByAge()
        window.message = "Patients sorted by age."
    }

    function searchPatientById() {
        var id = window.searchText.trim()

        window.lastSearchAlgorithm = "Linear Search"
        window.lastSearchComparisons = 0

        if (id === "") {
            window.lastSearchResult = "Enter a patient ID to search."
            window.message = window.lastSearchResult
            return
        }

        // The C++ backend checks the recent-patient cache first and
        // then performs a linear search of the patient list.
        var result = patientStore.searchPatientById(id)

        window.lastSearchComparisons = result.comparisons

        if (result.source === "recent-patient cache") {
            window.lastSearchAlgorithm = "Linear Search (cache hit)"
        }

        if (result.found) {
            window.lastSearchResult =
                "FOUND: " + result.name + " (" + result.patientId + ")"

            window.message = "Linear search: " + window.lastSearchResult
            window.searchText = result.patientId
        } else {
            window.lastSearchResult = "NOT FOUND: " + id
            window.message = "Linear search: Patient ID not found."
        }
    }

    function binarySearchPatientById() {
        var id = window.searchText.trim()

        window.lastSearchAlgorithm = "Binary Search"
        window.lastSearchComparisons = 0

        if (id === "") {
            window.lastSearchResult = "Enter a patient ID to search."
            window.message = window.lastSearchResult
            return
        }

        var result = patientStore.binarySearchPatientById(id)

        if (result.found) {
            window.lastSearchResult =
                "FOUND: " + result.name + " (" + result.patientId + ")"

            window.message = "Binary search: " + window.lastSearchResult
            window.searchText = result.patientId
        } else {
            window.lastSearchResult = "NOT FOUND: " + id
            window.message = "Binary search: Patient ID not found."
        }
    }
    function countPatientType(typeName) {
        var total = 0
        var records = patientStore.patients

        for (var i = 0; i < records.length; i++) {
            if (String(records[i].patientType || "").toLowerCase() ===
                typeName.toLowerCase()) {
                total++
            }
        }

        return total
    }

    function countAppointmentStatus(statusName) {
        var total = 0
        var records = patientStore.appointments

        for (var i = 0; i < records.length; i++) {
            if (String(records[i].status || "").toLowerCase() ===
                statusName.toLowerCase()) {
                total++
            }
        }

        return total
    }

    function patientNameById(patientId) {
        var records = patientStore.patients

        for (var i = 0; i < records.length; i++) {
            if (String(records[i].patientId) === String(patientId)) {
                return records[i].name || "Unknown patient"
            }
        }

        return "Unknown patient"
    }

    function filteredBillingHistory() {
        var refresh = billingRefreshKey
        var id = billingPatientFilter.trim()

        return patientStore.getPatientBillingHistory(id)
    }

    function billingTotal(fieldName) {
        var records = filteredBillingHistory()
        var total = 0

        for (var i = 0; i < records.length; i++) {
            total += Number(records[i][fieldName] || 0)
        }

        return total
    }

    function formatNaira(amount) {
        return "₦" + Number(amount || 0).toLocaleString(
            Qt.locale(), "f", 2)
    }

    function generateClinicReport() {
        var patients = patientStore.patients
        var appointments = patientStore.appointments
        var bills = patientStore.billingRecords

        var totalCharges = 0
        var totalPaid = 0
        var outstanding = 0

        for (var i = 0; i < bills.length; i++) {
            totalCharges += Number(bills[i].total || 0)
            totalPaid += Number(bills[i].amountPaid || 0)
            outstanding += Number(bills[i].balance || 0)
        }

        var report = "SCAPMS CLINIC SUMMARY REPORT\n"
        report += "Generated: " + new Date().toLocaleString() + "\n"
        report += "--------------------------------\n\n"

        report += "PATIENT SUMMARY\n"
        report += "Total Patients: " + patients.length + "\n"
        report += "General: " + countPatientType("General") + "\n"
        report += "Emergency: " + countPatientType("Emergency") + "\n"
        report += "Follow-Up: " + countPatientType("Follow-Up") + "\n\n"

        report += "APPOINTMENT SUMMARY\n"
        report += "Total Appointments: " + appointments.length + "\n"
        report += "Scheduled: " + countAppointmentStatus("Scheduled") + "\n"
        report += "Completed: " + countAppointmentStatus("Completed") + "\n"
        report += "Cancelled: " + countAppointmentStatus("Cancelled") + "\n\n"

        report += "WAITING QUEUE\n"
        report += "Patients Waiting: " + patientStore.waitingQueue.length + "\n\n"

        report += "BILLING SUMMARY\n"
        report += "Total Charges: " + formatNaira(totalCharges) + "\n"
        report += "Payments Received: " + formatNaira(totalPaid) + "\n"
        report += "Outstanding Balance: " + formatNaira(outstanding) + "\n"

        return report
    }

    function todayDateString() {
        var now = new Date()
        var year = now.getFullYear()
        var month = String(now.getMonth() + 1).padStart(2, "0")
        var day = String(now.getDate()).padStart(2, "0")

        return year + "-" + month + "-" + day
    }

    function countTodayAppointments(statusFilter) {
        var records = patientStore.appointments || []
        var today = todayDateString()
        var count = 0

        for (var i = 0; i < records.length; i++) {
            var appointment = records[i]

            if (String(appointment.date).slice(0, 10) === today) {
                if (statusFilter === "" ||
                        String(appointment.status).toLowerCase() ===
                        statusFilter.toLowerCase()) {
                    count++
                }
            }
        }

        return count
    }

    // ---------------- MAIN LAYOUT ----------------

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------------- SIDEBAR ----------------

        Rectangle {
            Layout.preferredWidth: 215
            Layout.fillHeight: true
            color: "#172554"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Label {
                    text: "SCAPMS"
                    color: "white"
                    font.pixelSize: 27
                    font.bold: true
                }

                Label {
                    text: "Smart Clinic Management"
                    color: "#bfdbfe"
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#334155"
                }

                Repeater {
                    model: [
                        "Dashboard",
                        "Patients",
                        "Appointments",
                        "Waiting Queue",
                        "Reports",
                        "Billing",
                        "Prescriptions"
                    ]

                    delegate: Button {
                        Layout.fillWidth: true
                        text: modelData

                        contentItem: Text {
                            text: parent.text
                            color: "white"
                            leftPadding: 10
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                        }

                        background: Rectangle {
                            radius: 6
                            color: window.currentPage === modelData
                                   ? "#2563eb" : "transparent"
                        }

                        onClicked: {
                            window.currentPage = modelData

                            if (modelData === "Dashboard") {
                                window.message = "Clinic overview and quick actions."
                            } else if (modelData === "Patients") {
                                window.message = "Register, search and manage patient records."
                            } else if (modelData === "Appointments") {
                                window.message = "Schedule and manage appointments."
                            } else if (modelData === "Waiting Queue") {
                                window.message = "Manage patients waiting to be seen."
                            } else if (modelData === "Reports") {
                                window.message = "Summary of clinic records."
                            } else if (modelData === "Billing") {
                                window.message =
                                    "Create bills, record payments and review patient billing history."
                            } else if (modelData === "Prescriptions") {
                                window.message = "Prescriptions require a prescription data backend."
                            }
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Button {
                    Layout.fillWidth: true
                    text: "Save All Data"

                    onClicked: {
                        if (patientStore.saveData()) {
                            window.message =
                                "Clinic data saved successfully."
                        } else {
                            window.message =
                                "Could not save data. Please try again."
                        }
                    }
                }

                Label {
                    text: "Software Engineering Project"
                    color: "#94a3b8"
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        // ---------------- PAGE CONTENT ----------------

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 20
            spacing: 12

            Label {
                Layout.fillWidth: true
                text: window.currentPage === "Patients"
                      ? "Patient Management"
                      : window.currentPage

                font.pixelSize: 27
                font.bold: true
                color: "#172554"
            }

            Label {
                Layout.fillWidth: true
                text: window.message
                color: "#64748b"
                wrapMode: Text.WordWrap
            }

            // ---------------- DASHBOARD ----------------
            GridLayout {
                Layout.fillWidth: true
                visible: window.currentPage === "Dashboard"
                columns: 2
                rowSpacing: 12
                columnSpacing: 12

                Repeater {
                    model: [
                        {
                            title: "Today's Appointments",
                            status: "",
                            icon: "calendar"
                        },
                        {
                            title: "Scheduled",
                            status: "Scheduled",
                            icon: "clock"
                        },
                        {
                            title: "Completed",
                            status: "Completed",
                            icon: "check"
                        },
                        {
                            title: "Cancelled",
                            status: "Cancelled",
                            icon: "close"
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.preferredHeight: 110

                        radius: 12
                        color: "#ffffff"
                        border.color: "#e2e8f0"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            Label {
                                text: modelData.title
                                color: "#64748b"
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                            }

                            Label {
                                text: String(
                                    window.countTodayAppointments(modelData.status)
                                )
                                color: "#172554"
                                font.pixelSize: 28
                                font.bold: true
                            }
                        }
                    }
                }
            }

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: window.currentPage === "Dashboard"
                clip: true
                contentWidth: width
                contentHeight: dashboardContent.implicitHeight

                ColumnLayout {
                    id: dashboardContent
                    width: parent.width
                    spacing: 16

                    Label {
                        text: "Clinic Overview"
                        font.pixelSize: 20
                        font.bold: true
                        color: "#172554"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width >= 650 ? 2 : 1
                        columnSpacing: 12
                        rowSpacing: 12

                        Repeater {
                            model: [
                                {
                                    title: "Registered Patients",
                                    value: patientStore.patients.length,
                                    description: "Patient records"
                                },
                                {
                                    title: "Appointments",
                                    value: patientStore.appointments.length,
                                    description: "All appointment records"
                                },
                                {
                                    title: "Waiting Queue",
                                    value: patientStore.waitingQueue.length,
                                    description: "Patients waiting"
                                },
                                {
                                    title: "Emergency Patients",
                                    value: window.countPatientType("Emergency"),
                                    description: "Registered emergency cases"
                                }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 115
                                radius: 12
                                color: "white"
                                border.color: "#e2e8f0"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 16
                                    spacing: 5

                                    Label {
                                        text: modelData.title
                                        color: "#64748b"
                                        font.pixelSize: 14
                                    }

                                    Label {
                                        text: String(modelData.value)
                                        color: "#1d4ed8"
                                        font.pixelSize: 29
                                        font.bold: true
                                    }

                                    Label {
                                        text: modelData.description
                                        color: "#64748b"
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        text: "Quick Actions"
                        font.pixelSize: 20
                        font.bold: true
                        color: "#172554"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width >= 650 ? 2 : 1
                        columnSpacing: 10
                        rowSpacing: 10

                        Button {
                            Layout.fillWidth: true
                            text: "Register Patient"
                            onClicked: {
                                window.currentPage = "Patients"
                                window.message = "Enter the patient's details below."
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Schedule Appointment"
                            onClicked: {
                                window.currentPage = "Appointments"
                                window.message = "Enter the appointment details."
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Open Waiting Queue"
                            onClicked: {
                                window.currentPage = "Waiting Queue"
                                window.message = "Manage the waiting queue."
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "View Reports"
                            onClicked: {
                                window.currentPage = "Reports"
                                window.message = "Clinic summary report."
                            }
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "Reminder: save your data before closing the application."
                        color: "#92400e"
                        wrapMode: Text.WordWrap
                    }
                }
            }

            // ---------------- PATIENTS PAGE ----------------

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 0
                visible: window.currentPage === "Patients"
                spacing: 2

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: patientForm.implicitHeight + 28
                    radius: 12
                    color: "white"
                    border.color: "#e2e8f0"

                    ColumnLayout {
                        id: patientForm
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2

                        Label {
                            text: "Register New Patient"
                            font.pixelSize: 19
                            font.bold: true
                            color: "#172554"
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: width >= 600 ? 2 : 1
                            columnSpacing: 10
                            rowSpacing: 8

                            TextField {
                                id: nameInput
                                Layout.fillWidth: true
                                placeholderText: "Full name"
                            }

                            TextField {
                                id: ageInput
                                Layout.fillWidth: true
                                placeholderText: "Age (1-120)"
                                validator: IntValidator {
                                    bottom: 1
                                    top: 120
                                }
                                inputMethodHints: Qt.ImhDigitsOnly
                            }

                            ComboBox {
                                id: genderInput
                                Layout.fillWidth: true
                                model: ["Male", "Female", "Other"]
                            }

                            ComboBox {
                                id: patientTypeInput
                                Layout.fillWidth: true
                                model: ["General", "Emergency", "Follow-Up"]
                            }

                            TextField {
                                id: phoneInput
                                Layout.fillWidth: true
                                placeholderText: "Phone number"
                            }

                            TextField {
                                id: addressInput
                                Layout.fillWidth: true
                                placeholderText: "Address"
                            }
                        }

                        Button {
                            text: "Register Patient"

                            onClicked: {
                                if (nameInput.text.trim() === "" ||
                                    ageInput.text === "" ||
                                    phoneInput.text.trim() === "" ||
                                    addressInput.text.trim() === "") {
                                    window.message = "Please complete all fields."
                                } else {
                                    var success = patientStore.addPatient(
                                        nameInput.text.trim(),
                                        parseInt(ageInput.text),
                                        genderInput.currentText,
                                        phoneInput.text.trim(),
                                        addressInput.text.trim(),
                                        patientTypeInput.currentText
                                    )

                                    if (success) {
                                        window.message = "Patient registered successfully."
                                        nameInput.clear()
                                        ageInput.clear()
                                        phoneInput.clear()
                                        addressInput.clear()
                                        genderInput.currentIndex = 0
                                        patientTypeInput.currentIndex = 0
                                    } else {
                                        window.message = "Invalid patient details."
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    TextField {
                        Layout.fillWidth: true
                        placeholderText: "Filter by name or ID; enter ID for search"
                        text: window.searchText
                        onTextChanged: window.searchText = text
                        onAccepted: window.searchPatientById()
                    }

                    Button {
                        text: "Linear Search"
                        onClicked: window.searchPatientById()
                    }

                    Button {
                        text: "Binary Search"
                        onClicked: window.binarySearchPatientById()
                    }

                    Button {
                        text: "Clear"
                        onClicked: {
                            window.searchText = ""
                            window.message = ""
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: searchDemo.implicitHeight + 24

                    radius: 10
                    color: "white"
                    border.color: "#cbd5e1"

                    ColumnLayout {
                        id: searchDemo

                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 6

                        Label {
                            text: "Search Algorithm Demonstration"
                            font.pixelSize: 17
                            font.bold: true
                            color: "#172554"
                        }

                        Label {
                            text: "Algorithm: " + window.lastSearchAlgorithm
                            color: "#334155"
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Result: " + window.lastSearchResult
                            color: window.lastSearchResult.indexOf("FOUND:") === 0
                                   ? "#15803d" : "#64748b"
                            wrapMode: Text.WordWrap
                        }

                        Label {
                            text: "Comparisons: " +
                                  (window.lastSearchAlgorithm === "Linear Search"
                                   ? String(window.lastSearchComparisons)
                                   : "Not measured")
                            color: "#334155"
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Linear search examines records one by one. Binary search requires records ordered by patient ID."
                            color: "#64748b"
                            wrapMode: Text.WordWrap
                            font.pixelSize: 12
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Label {
                        text: "Sort by:"
                        color: "#334155"
                    }

                    ComboBox {
                        id: sortChoice
                        model: ["Name", "Age"]
                    }

                    Button {
                        text: "Sort"
                        onClicked: {
                            if (sortChoice.currentText === "Name") {
                                window.sortPatientsByName()
                            } else {
                                window.sortPatientsByAge()
                            }
                        }
                    }

                    Button {
                        text: "Undo Delete"
                        onClicked: {
                            var success = patientStore.undoLastDeletion()
                            window.message = success
                                ? "Last deleted patient restored."
                                : "No deleted patient available to restore."
                        }
                    }

                    Button {
                        text: "Load Data"
                        onClicked: {
                            if (patientStore.loadData()) {
                                window.message = "Saved data loaded."
                            } else {
                                window.message = "Could not load saved data."
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 240
                    Layout.preferredHeight: 320
                    radius: 12
                    color: "white"
                    border.color: "#e2e8f0"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 5

                        Label {
                            text: "Registered Patients (" +
                                  patientStore.patients.length + ")"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#172554"
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Label {
                                Layout.preferredWidth: 90
                                text: "Patient ID"
                                font.bold: true
                            }
                            Label {
                                Layout.fillWidth: true
                                text: "Name"
                                font.bold: true
                            }
                            Label {
                                Layout.preferredWidth: 45
                                text: "Age"
                                font.bold: true
                            }
                            Label {
                                Layout.preferredWidth: 90
                                text: "Gender"
                                font.bold: true
                            }
                            Label {
                                Layout.preferredWidth: 110
                                text: "Type"
                                font.bold: true
                            }
                            Label {
                                Layout.preferredWidth: 75
                                text: "Action"
                                font.bold: true
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: "#e2e8f0"
                        }

                        ListView {
                            id: patientList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 2
                            model: window.filteredPatients()

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: patientList.width
                                height: 34
                                radius: 5
                                color: index % 2 === 0 ? "#f8fafc" : "white"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 5

                                    Label {
                                        Layout.preferredWidth: 90
                                        text: modelData.patientId
                                        font.pixelSize: 11
                                    }
                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        Layout.preferredWidth: 45
                                        text: String(modelData.age)
                                    }
                                    Label {
                                        Layout.preferredWidth: 90
                                        text: modelData.gender
                                        elide: Text.ElideRight
                                    }
                                    Label {
                                        Layout.preferredWidth: 110
                                        text: modelData.patientType || "General"
                                        elide: Text.ElideRight
                                    }
                                    Button {
                                        Layout.preferredWidth: 65
                                        Layout.preferredHeight: 28
                                        text: "Delete"
                                        onClicked: {
                                            patientStore.removePatient(modelData.patientId)
                                            window.message = "Patient record deleted."
                                        }
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: patientList.count === 0
                                text: window.searchText.trim() === ""
                                      ? "No patients registered yet."
                                      : "No matching patients found."
                                color: "#64748b"
                            }
                        }
                    }
                }
            }

            // ---------------- APPOINTMENTS PAGE ----------------

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: window.currentPage === "Appointments"
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: appointmentForm.implicitHeight + 28
                    radius: 12
                    color: "white"
                    border.color: "#e2e8f0"

                    ColumnLayout {
                        id: appointmentForm
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Label {
                            text: "Schedule an Appointment"
                            font.pixelSize: 19
                            font.bold: true
                            color: "#172554"
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: width >= 650 ? 3 : 1
                            columnSpacing: 8
                            rowSpacing: 8

                            TextField {
                                id: appointmentPatientId
                                Layout.fillWidth: true
                                placeholderText: "Patient ID"
                            }
                            TextField {
                                id: appointmentDate
                                Layout.fillWidth: true
                                placeholderText: "Date (YYYY-MM-DD)"
                            }
                            TextField {
                                id: appointmentTime
                                Layout.fillWidth: true
                                placeholderText: "Time (HH:MM)"
                            }
                        }

                        Button {
                            text: "Schedule Appointment"


                            onClicked: {
                                var id = appointmentPatientId.text.trim()
                                var date = appointmentDate.text.trim()
                                var time = appointmentTime.text.trim()

                                console.log("Schedule clicked")
                                console.log("Patient ID:", id)
                                console.log("Date:", date)
                                console.log("Time:", time)

                                if (id === "" || date === "" || time === "") {
                                    window.message = "Enter a patient ID, date and time."
                                } else {
                                    var success = patientStore.scheduleAppointment(
                                        id,
                                        date,
                                        time
                                    )

                                    console.log("Scheduling result:", success)
                                    console.log(
                                        "Appointments after scheduling:",
                                        patientStore.appointments.length
                                    )

                                    if (success) {
                                        window.message = "Appointment scheduled successfully."
                                        appointmentPatientId.clear()
                                        appointmentDate.clear()
                                        appointmentTime.clear()
                                    } else {
                                        window.message =
                                            "Could not schedule appointment. Check the patient ID, date, time and duplicates."
                                    }
                                }
                            }

                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: "white"
                    border.color: "#e2e8f0"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label {
                            text: "Appointments (" +
                                  patientStore.appointments.length + ")"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#172554"
                        }

                        ListView {
                            id: appointmentList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 5
                            model: patientStore.appointments

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: appointmentList.width
                                height: 65
                                radius: 6
                                color: index % 2 === 0 ? "#f8fafc" : "white"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 3

                                        Label {
                                            text: (modelData.patientName ||
                                                   "Unknown patient") +
                                                  " (" + modelData.patientId + ")"
                                            font.bold: true
                                            elide: Text.ElideRight
                                        }

                                        Label {
                                            text: modelData.date + " at " +
                                                  modelData.time + " — " +
                                                  modelData.status
                                            color: "#64748b"
                                            font.pixelSize: 12
                                        }
                                    }

                                    Button {
                                        text: "Cancel"
                                        enabled: modelData.status === "Scheduled"

                                        onClicked: {
                                            var success = patientStore.cancelAppointment(
                                                modelData.patientId,
                                                modelData.date,
                                                modelData.time
                                            )

                                            window.message = success
                                                ? "Appointment cancelled."
                                                : "Could not cancel appointment."
                                        }
                                    }
                                    Button {
                                        text: "Complete"

                                        visible: modelData.status === "Scheduled"

                                        onClicked: {
                                            var success = patientStore.completeAppointment(
                                                modelData.patientId,
                                                modelData.date,
                                                modelData.time
                                            )

                                            if (success) {
                                                console.log("Appointment marked as Completed")
                                            } else {
                                                console.log("Could not complete this appointment")
                                            }
                                        }
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: appointmentList.count === 0
                                text: "No appointments scheduled yet."
                                color: "#64748b"
                            }
                        }
                    }
                }
            }

            // ---------------- WAITING QUEUE PAGE ----------------

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: window.currentPage === "Waiting Queue"
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: queueControls.implicitHeight + 28
                    radius: 12
                    color: "white"
                    border.color: "#e2e8f0"

                    ColumnLayout {
                        id: queueControls
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 10

                        Label {
                            text: "Patient Waiting Queue"
                            font.pixelSize: 20
                            font.bold: true
                            color: "#172554"
                        }

                        Label {
                            Layout.fillWidth: true
                            text: "Patients are called in the order they joined the queue."
                            color: "#64748b"
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: queuePatientId
                                Layout.fillWidth: true
                                placeholderText: "Enter registered patient ID"
                                onAccepted: addQueuePatientButton.clicked()
                            }

                            Button {
                                id: addQueuePatientButton
                                text: "Add to Queue"

                                onClicked: {
                                    var id = queuePatientId.text.trim()

                                    if (id === "") {
                                        window.message = "Enter a patient ID."
                                    } else if (patientStore.addToWaitingQueue(id)) {
                                        window.message = "Patient added to the waiting queue."
                                        queuePatientId.clear()
                                    } else {
                                        window.message =
                                            "Could not add patient. Check the ID and queue status."
                                    }
                                }
                            }

                            Button {
                                text: "Call Next"

                                onClicked: {
                                    var result = patientStore.callNextPatient()

                                    if (result.found) {
                                        window.message = "Now calling: " +
                                            result.name + " (" +
                                            result.patientId + "), " +
                                            result.patientType + " patient."
                                    } else {
                                        window.message = result.message
                                    }
                                }
                            }
                        }

                        Label {
                            text: "Patients waiting: " +
                                  patientStore.waitingQueue.length
                            font.bold: true
                            color: "#172554"
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 12
                    color: "white"
                    border.color: "#e2e8f0"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Label {
                            text: "Queue Order"
                            font.pixelSize: 18
                            font.bold: true
                            color: "#172554"
                        }

                        ListView {
                            id: waitingQueueList
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            spacing: 4
                            model: patientStore.waitingQueue

                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: waitingQueueList.width
                                height: 52
                                radius: 5
                                color: index % 2 === 0 ? "#f8fafc" : "white"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 10

                                    Label {
                                        Layout.preferredWidth: 55
                                        text: "#" + String(index + 1)
                                        font.bold: true
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Label {
                                            text: modelData.name || "Unknown patient"
                                            font.bold: true
                                        }

                                        Label {
                                            text: (modelData.patientId || "") +
                                                  " • " +
                                                  (modelData.patientType || "General")
                                            color: modelData.patientType === "Emergency"
                                                   ? "#b91c1c" : "#64748b"
                                            font.pixelSize: 12
                                        }
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: waitingQueueList.count === 0
                                text: "No patients are currently waiting."
                                color: "#64748b"
                            }
                        }
                    }
                }
            }

            // ---------------- REPORTS PAGE ----------------

            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: window.currentPage === "Reports"
                clip: true
                contentWidth: width
                contentHeight: reportContent.implicitHeight

                ColumnLayout {
                    id: reportContent
                    width: parent.width
                    spacing: 14

                    Label {
                        text: "Clinic Summary Report"
                        font.pixelSize: 20
                        font.bold: true
                        color: "#172554"
                    }

                    Label {
                        text: "Patient categories"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#334155"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width >= 600 ? 3 : 1
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: [
                                {
                                    title: "General Patients",
                                    value: window.countPatientType("General")
                                },
                                {
                                    title: "Emergency Patients",
                                    value: window.countPatientType("Emergency")
                                },
                                {
                                    title: "Follow-Up Patients",
                                    value: window.countPatientType("Follow-Up")
                                }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 95
                                radius: 10
                                color: "white"
                                border.color: "#e2e8f0"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 6

                                    Label {
                                        text: modelData.title
                                        color: "#64748b"
                                        wrapMode: Text.WordWrap
                                    }

                                    Label {
                                        text: String(modelData.value)
                                        font.pixelSize: 25
                                        font.bold: true
                                        color: "#1d4ed8"
                                    }
                                }
                            }
                        }
                    }

                    Label {
                        text: "Appointment Summary"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#334155"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: width >= 600 ? 2 : 1
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: [
                                {
                                    title: "Scheduled",
                                    value: window.countAppointmentStatus("Scheduled")
                                },
                                {
                                    title: "Cancelled",
                                    value: window.countAppointmentStatus("Cancelled")
                                }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 85
                                radius: 10
                                color: "white"
                                border.color: "#e2e8f0"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 5

                                    Label {
                                        text: modelData.title + " appointments"
                                        color: "#64748b"
                                    }

                                    Label {
                                        text: String(modelData.value)
                                        font.pixelSize: 24
                                        font.bold: true
                                        color: "#172554"
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: reportTotals.implicitHeight + 24
                        radius: 10
                        color: "white"
                        border.color: "#e2e8f0"

                        ColumnLayout {
                            id: reportTotals
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            Label {
                                text: "Overall Totals"
                                font.pixelSize: 17
                                font.bold: true
                                color: "#172554"
                            }

                            Button {
                                text: "Generate Report"
                                Layout.fillWidth: true

                                onClicked: {
                                    generatedReport.text = window.generateClinicReport()
                                    window.message = "Clinic report generated successfully."
                                }
                            }

                            TextArea {
                                id: generatedReport
                                Layout.fillWidth: true
                                Layout.preferredHeight: 300
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                selectByMouse: true
                                placeholderText: "Click Generate Report to create a summary of clinic records."
                                color: "#172554"
                                background: Rectangle {
                                    color: "#f8fafc"
                                    radius: 8
                                    border.color: "#cbd5e1"
                                }
                            }


                            Label {
                                text: "Total registered patients: " +
                                      patientStore.patients.length
                            }

                            Label {
                                text: "Total appointment records: " +
                                      patientStore.appointments.length
                            }

                            Label {
                                text: "Patients currently waiting: " +
                                      patientStore.waitingQueue.length
                            }

                            Button {
                                text: "Save Data"
                                onClicked: {
                                    window.message = patientStore.saveData()
                                        ? "Report data saved successfully."
                                        : "Could not save data."
                                }
                            }
                        }
                    }
                }
            }

            // ---------------- BILLING PLACEHOLDER ----------------



            Rectangle {
                id: billingPage

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: window.currentPage === "Billing"

                radius: 12
                color: "white"
                border.color: "#e2e8f0"

                property real calculatedTotal:
                    (Number(quantityInput.text) || 0) *
                    (Number(unitPriceInput.text) || 0)

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 20
                    clip: true

                    ColumnLayout {
                        width: billingPage.width - 64
                        spacing: 16

                        Label {
                            text: "Billing Management"
                            font.pixelSize: 24
                            font.bold: true
                            color: "#172554"
                        }

                        Label {
                            text: "Create patient bills and record payments."
                            color: "#64748b"
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: billForm.implicitHeight + 32
                            radius: 10
                            color: "#f8fafc"
                            border.color: "#e2e8f0"

                            ColumnLayout {
                                id: billForm
                                anchors.fill: parent
                                anchors.margins: 16
                                spacing: 10

                                Label {
                                    text: "Create New Bill"
                                    font.pixelSize: 18
                                    font.bold: true
                                }

                                TextField {
                                    id: billPatientId
                                    Layout.fillWidth: true
                                    placeholderText: "Patient ID (e.g. PAT0001)"
                                }

                                TextField {
                                    id: serviceInput
                                    Layout.fillWidth: true
                                    placeholderText: "Service or treatment description"
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    TextField {
                                        id: quantityInput
                                        Layout.fillWidth: true
                                        placeholderText: "Quantity"
                                        text: "1"
                                        validator: IntValidator {
                                            bottom: 1
                                            top: 1000000
                                        }
                                    }

                                    TextField {
                                        id: unitPriceInput
                                        Layout.fillWidth: true
                                        placeholderText: "Unit price (₦)"
                                        validator: DoubleValidator {
                                            bottom: 0
                                            decimals: 2
                                            notation: DoubleValidator.StandardNotation
                                        }
                                    }
                                }

                                Label {
                                    text: "Total: ₦" +
                                          billingPage.calculatedTotal.toLocaleString(
                                              Qt.locale(), "f", 2)
                                    font.pixelSize: 18
                                    font.bold: true
                                    color: "#172554"
                                }

                                Button {
                                    text: "Create Bill"
                                    Layout.fillWidth: true

                                    onClicked: {
                                        var quantity = Number(quantityInput.text)
                                        var price = Number(unitPriceInput.text)

                                        if (patientStore.createBill(
                                                billPatientId.text,
                                                serviceInput.text,
                                                quantity,
                                                price)) {
                                            billingMessage.text =
                                                "Bill created successfully."
                                            billingMessage.color = "#15803d"

                                            billPatientId.clear()
                                            serviceInput.clear()
                                            quantityInput.text = "1"
                                            unitPriceInput.clear()
                                        } else {
                                            billingMessage.text =
                                                "Could not create bill. Check the patient ID, service, quantity and price."
                                            billingMessage.color = "#b91c1c"
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            id: billingMessage
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            color: "#64748b"
                        }


                        Label {
                            text: "Patient Billing History"
                            font.pixelSize: 20
                            font.bold: true
                            color: "#172554"
                        }

                        TextField {
                            id: billingFilterInput
                            Layout.fillWidth: true
                            placeholderText: "Filter billing history by patient ID (e.g. PAT0001)"
                            text: window.billingPatientFilter

                            onTextChanged: {
                                window.billingPatientFilter = text
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                text: "All Patients"

                                onClicked: {
                                    billingFilterInput.clear()
                                    window.billingPatientFilter = ""
                                }
                            }

                            Button {
                                text: "Refresh History"

                                onClicked: {
                                    window.billingRefreshKey++
                                    window.message = "Billing history refreshed."
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: width >= 650 ? 3 : 1
                            columnSpacing: 10
                            rowSpacing: 10

                            Repeater {
                                model: [
                                    {
                                        title: "Total Charges",
                                        value: window.billingTotal("total"),
                                        description: "Bills issued"
                                    },
                                    {
                                        title: "Payments Received",
                                        value: window.billingTotal("amountPaid"),
                                        description: "Amount collected"
                                    },
                                    {
                                        title: "Outstanding Balance",
                                        value: window.billingTotal("balance"),
                                        description: "Amount still owed"
                                    }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 105
                                    radius: 10
                                    color: "white"
                                    border.color: "#e2e8f0"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 5

                                        Label {
                                            text: modelData.title
                                            color: "#64748b"
                                            font.pixelSize: 13
                                            wrapMode: Text.WordWrap
                                        }

                                        Label {
                                            text: window.formatNaira(modelData.value)
                                            color: "#1d4ed8"
                                            font.pixelSize: 21
                                            font.bold: true
                                            wrapMode: Text.WrapAnywhere
                                        }

                                        Label {
                                            text: modelData.description
                                            color: "#64748b"
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            text: billingFilterInput.text.trim() === ""
                                  ? "All Patient Bills"
                                  : "Bills for " + billingFilterInput.text.trim()
                            font.pixelSize: 17
                            font.bold: true
                            color: "#172554"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 5
                            color: "#eaf0f8"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Label {
                                    Layout.preferredWidth: 95
                                    text: "Bill / Patient"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: "Service"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                Label {
                                    Layout.preferredWidth: 100
                                    text: "Total / Paid"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                Label {
                                    Layout.preferredWidth: 95
                                    text: "Balance"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                Label {
                                    Layout.preferredWidth: 90
                                    text: "Status"
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }
                        }

                        ListView {
                            id: billingHistoryList

                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.max(
                                120, Math.min(contentHeight, 420))
                            clip: true
                            spacing: 6

                            model: window.filteredBillingHistory()

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: billingHistoryList.width
                                height: 150
                                radius: 8
                                color: index % 2 === 0 ? "#f8fafc" : "white"
                                border.color: "#e2e8f0"

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3

                                            Label {
                                                text: modelData.billId || "Unknown bill"
                                                font.bold: true
                                                color: "#172554"
                                            }

                                            Label {
                                                text: (modelData.patientId || "") + " — " +
                                                      window.patientNameById(modelData.patientId)
                                                color: "#64748b"
                                                font.pixelSize: 11
                                                wrapMode: Text.WordWrap
                                            }
                                        }

                                        Label {
                                            text: modelData.status || "Unpaid"
                                            color: modelData.status === "Paid"
                                                   ? "#15803d"
                                                   : modelData.status === "Partially Paid"
                                                     ? "#1d4ed8" : "#b45309"
                                            font.bold: true
                                            font.pixelSize: 11
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: modelData.service || "Unspecified service"
                                        font.pixelSize: 13
                                        color: "#334155"
                                        wrapMode: Text.WordWrap
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Label {
                                            Layout.fillWidth: true
                                            text: "Total\n" +
                                                  window.formatNaira(modelData.total)
                                            font.pixelSize: 11
                                            wrapMode: Text.WordWrap
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: "Paid\n" +
                                                  window.formatNaira(modelData.amountPaid)
                                            font.pixelSize: 11
                                            color: "#15803d"
                                            wrapMode: Text.WordWrap
                                        }

                                        Label {
                                            Layout.fillWidth: true
                                            text: "Balance\n" +
                                                  window.formatNaira(modelData.balance)
                                            font.pixelSize: 11
                                            font.bold: true
                                            color: Number(modelData.balance) > 0
                                                   ? "#b91c1c" : "#15803d"
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6

                                        TextField {
                                            id: paymentInput
                                            Layout.fillWidth: true
                                            placeholderText: "Payment amount (₦)"
                                            validator: DoubleValidator {
                                                bottom: 0.01
                                                decimals: 2
                                                notation: DoubleValidator.StandardNotation
                                            }
                                        }

                                        Button {
                                            text: "Record Payment"
                                            enabled: Number(modelData.balance) > 0

                                            onClicked: {
                                                var amount = Number(paymentInput.text)

                                                if (!isFinite(amount) || amount <= 0) {
                                                    billingMessage.text =
                                                        "Enter a valid payment amount."
                                                    billingMessage.color = "#b91c1c"
                                                } else if (patientStore.recordPayment(
                                                               modelData.billId, amount)) {
                                                    billingMessage.text =
                                                        "Payment recorded successfully."
                                                    billingMessage.color = "#15803d"

                                                    paymentInput.clear()
                                                    window.billingRefreshKey++
                                                } else {
                                                    billingMessage.text =
                                                        "Payment failed. Check the amount and balance."
                                                    billingMessage.color = "#b91c1c"
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Label {
                                anchors.centerIn: parent
                                visible: billingHistoryList.count === 0
                                text: billingFilterInput.text.trim() === ""
                                      ? "No bills have been created yet."
                                      : "No bills found for this patient ID."
                                color: "#64748b"
                                wrapMode: Text.WordWrap
                            }
                        }



                        Label {
                            text: "Patient Billing History"
                            font.pixelSize: 20
                            font.bold: true
                            color: "#172554"
                        }

                        TextField {
                            Layout.fillWidth: true
                            placeholderText: "Filter billing history by patient ID (e.g. PAT0001)"
                            text: window.billingPatientFilter

                            onTextChanged: {
                                window.billingPatientFilter = text
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Button {
                                text: "All Patients"

                                onClicked: {
                                    billingFilterInput.clear()
                                    window.billingPatientFilter = ""
                                }
                            }

                            Button {
                                text: "Refresh History"

                                onClicked: {
                                    window.billingRefreshKey++
                                    window.message = "Billing history refreshed."
                                }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: width >= 650 ? 3 : 1
                            columnSpacing: 10
                            rowSpacing: 10

                            Repeater {
                                model: [
                                    {
                                        title: "Total Charges",
                                        value: window.billingTotal("total"),
                                        description: "Bills issued"
                                    },
                                    {
                                        title: "Payments Received",
                                        value: window.billingTotal("amountPaid"),
                                        description: "Amount collected"
                                    },
                                    {
                                        title: "Outstanding Balance",
                                        value: window.billingTotal("balance"),
                                        description: "Amount still owed"
                                    }
                                ]

                                delegate: Rectangle {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 105
                                    radius: 10
                                    color: "white"
                                    border.color: "#e2e8f0"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 5

                                        Label {
                                            text: modelData.title
                                            color: "#64748b"
                                            font.pixelSize: 13
                                            wrapMode: Text.WordWrap
                                        }

                                        Label {
                                            text: window.formatNaira(modelData.value)
                                            color: "#1d4ed8"
                                            font.pixelSize: 21
                                            font.bold: true
                                            wrapMode: Text.WrapAnywhere
                                        }

                                        Label {
                                            text: modelData.description
                                            color: "#64748b"
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }
                        }

                        Label {
                            text: billingFilterInput.text.trim() === ""
                                  ? "All Patient Bills"
                                  : "Bills for " + billingFilterInput.text.trim()
                            font.pixelSize: 17
                            font.bold: true
                            color: "#172554"
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: 5
                            color: "#eaf0f8"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 6

                                Label {
                                    Layout.preferredWidth: 95
                                    text: "Bill / Patient"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                Label {
                                    Layout.fillWidth: true
                                    text: "Service"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                Label {
                                    Layout.preferredWidth: 100
                                    text: "Total / Paid"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                Label {
                                    Layout.preferredWidth: 95
                                    text: "Balance"
                                    font.bold: true
                                    font.pixelSize: 11
                                }

                                Label {
                                    Layout.preferredWidth: 90
                                    text: "Status"
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }
                        }


                            Label {
                                anchors.centerIn: parent
                                visible: billingHistoryList.count === 0
                                text: billingFilterInput.text.trim() === ""
                                      ? "No bills have been created yet."
                                      : "No bills found for this patient ID."
                                color: "#64748b"
                                wrapMode: Text.WordWrap
                            }
                        }

                    }
                }
            }



            // ---------------- PRESCRIPTIONS PLACEHOLDER ----------------

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: window.currentPage === "Prescriptions"
                radius: 12
                color: "white"
                border.color: "#e2e8f0"

                ColumnLayout {
                    anchors.centerIn: parent
                    width: parent.width - 48
                    spacing: 12

                    Label {
                        Layout.fillWidth: true
                        text: "Prescriptions Module"
                        font.pixelSize: 22
                        font.bold: true
                        color: "#172554"
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Label {
                        Layout.fillWidth: true
                        text: "This section is a placeholder. To complete prescriptions, the C++ backend must store medication details, dosage, instructions and the linked patient record."
                        color: "#64748b"
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

