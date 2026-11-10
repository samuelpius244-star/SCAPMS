
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QCoreApplication>
#include <QObject>

#include "patientstore.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // Create the backend that manages patients,
    // appointments, waiting queue, searching and reports.
    PatientStore patientStore;

    // Create the QML engine.
    QQmlApplicationEngine engine;

    // Make PatientStore accessible to Main.qml
    // through the name "patientStore".
    engine.rootContext()->setContextProperty(
        "patientStore",
        &patientStore
        );

    // Exit if the QML interface cannot be created.
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() {
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection
        );

    // Load the main QML interface.
    engine.loadFromModule("SCAPMS_Project", "Main");

    return app.exec();
}
