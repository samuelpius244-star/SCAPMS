cmake_minimum_required(VERSION 3.16)

project(SCAPMS VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.10)

# Content of downloaded design from Figma to Qt or similar
if (EXISTS "${CMAKE_CURRENT_LIST_DIR}/importedcontent/CMakeLists.txt")
    add_subdirectory(${CMAKE_CURRENT_LIST_DIR}/importedcontent)
endif()

qt_add_executable(appSCAPMS
    main.cpp
    patientstore.h
    patientstore.cpp
    patientrecord.h
    patientrecord.cpp
    generalpatient.h
    generalpatient.cpp
    emergencypatient.h
    emergencypatient.cpp
    followuppatient.h
    followuppatient.cpp
    appointable.h
    appointment.h
    appointment.cpp
    clinicdatabase.h
    clinicdatabase.cpp
    clinicoperations.h
    clinicoperations.cpp
    patientalgorithms.h
    patientalgorithms.cpp
    patientcache.h
    patientcache.cpp
)

qt_add_qml_module(appSCAPMS
    URI SCAPMS_Project
    QML_FILES
        Main.qml
        SOURCES patientstore.h patientstore.cpp
        SOURCES patientrecord.h
        SOURCES patientrecord.cpp
        SOURCES generalpatient.h
        SOURCES generalpatient.cpp
        SOURCES emergencypatient.h
        SOURCES emergencypatient.cpp
        SOURCES followuppatient.h
        SOURCES followuppatient.cpp
        SOURCES appointable.h
        SOURCES appointment.h
        SOURCES appointment.cpp
        SOURCES clinicdatabase.h
        SOURCES clinicdatabase.cpp
        SOURCES clinicoperations.h
        SOURCES clinicoperations.cpp
        SOURCES patientalgorithms.h
        SOURCES patientalgorithms.cpp
        SOURCES patientcache.h
        SOURCES patientcache.cpp
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appSCAPMS PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appSCAPMS
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appSCAPMS
    PRIVATE Qt6::Quick
)

install(TARGETS appSCAPMS
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
