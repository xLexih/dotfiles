cmake_minimum_required(VERSION 3.16)

project(MyApp VERSION 1.0.0 LANGUAGES CXX)

# --- THE FIX IS HERE ---
set(QT_QML_GENERATE_QMLLS_INI ON)
# -----------------------

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup()

qt_add_executable(MyApp
    main.cpp
)

qt_add_qml_module(MyApp
    URI MyApp
    VERSION 1.0
    QML_FILES
        Main.qml
)