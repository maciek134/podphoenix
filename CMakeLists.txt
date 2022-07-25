project(podbird C CXX)
cmake_minimum_required(VERSION 2.8.12)

# Do not remove this line, its required for the correct functionality of the Ubuntu-SDK
set(UBUNTU_MANIFEST_PATH "manifest.json.in" CACHE INTERNAL "Tells QtCreator location and name of the manifest file")
set (CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

find_package(Qt5Core)
find_package(Qt5Qml)
find_package(Qt5Quick)
# find_package(ubuntu-sdk-libs)

# Automatically create moc files
set(CMAKE_AUTOMOC ON)

# Components PATH
execute_process(
    COMMAND dpkg-architecture -qDEB_HOST_MULTIARCH
    OUTPUT_VARIABLE ARCH_TRIPLET
    OUTPUT_STRIP_TRAILING_WHITESPACE
)


option(INSTALL_TESTS "Install the tests on make install" on)

set(APP_NAME          podbird)
set(APP_ID            "soy.iko.podphoenix")
if(DEFINED ENV{DESKTOP_BUILD})
    set(PODBIRD_DIR "/usr/share/podbird/qml/podbird")
    set(ICON "/usr/share/podbird/podbird.png")
    set(SPLASH "/usr/share/podbird/splash.png")
    set(QT_IMPORTS_DIR "/usr/lib/${ARCH_TRIPLET}/qt5/qml/")
else(DEFINED ENV{DESKTOP_BUILD})
    set(PODBIRD_DIR "share/qml/podbird")
    set(ICON "podbird.png")
    set(SPLASH "splash.png")
    set(QT_IMPORTS_DIR "lib/${ARCH_TRIPLET}")
endif(DEFINED ENV{DESKTOP_BUILD})
set(MAIN_QML          "podbird.qml")

# Set install paths
set(CMAKE_INSTALL_PREFIX /)
if(DEFINED ENV{DESKTOP_BUILD})
    set(DATA_DIR "/usr/share/podbird/")
    set(DESKTOP_DIR "/usr/share/applications/")
else(DEFINED ENV{DESKTOP_BUILD})
    set(DATA_DIR /)
    set(DESKTOP_DIR ${DATA_DIR})
endif(DEFINED ENV{DESKTOP_BUILD})
set(DESKTOP_FILE_NAME "Podbird.desktop")

set(EXEC "qmlscene $@ ${PODBIRD_DIR}/${MAIN_QML}")

# This command figures out the target architecture for use in the manifest file
execute_process(
  COMMAND dpkg-architecture -qDEB_HOST_ARCH
  OUTPUT_VARIABLE CLICK_ARCH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

configure_file(manifest.json.in ${CMAKE_CURRENT_BINARY_DIR}/manifest.json)
if(NOT DEFINED ENV{DESKTOP_BUILD})
    install(FILES ${CMAKE_CURRENT_BINARY_DIR}/manifest.json
            DESTINATION ${CMAKE_INSTALL_PREFIX})
endif(NOT DEFINED ENV{DESKTOP_BUILD})

install(FILES "podbird.png" DESTINATION ${DATA_DIR})
install(FILES "splash.png" DESTINATION ${DATA_DIR})
install(FILES "Podbird.apparmor" DESTINATION ${DATA_DIR})

add_subdirectory(app)
add_subdirectory(backend)
add_subdirectory(po)

add_custom_target("autopilot" chmod +x ${CMAKE_SOURCE_DIR}/app/tests/autopilot/run
                    COMMAND ${CMAKE_SOURCE_DIR}/app/tests/autopilot/run
                    DEPENDS podbirdbackend podbirdbackend-qmldir
                    WORKING_DIRECTORY ./app)

#add_custom_target("check" /usr/bin/qmltestrunner -input ${CMAKE_SOURCE_DIR}/app/tests/unit -import ${CMAKE_BINARY_DIR}/backend
#                    DEPENDS podbirdbackend podbirdbackend-qmldir
#                    WORKING_DIRECTORY ./app)

add_custom_target("run" /usr/bin/qmlscene -I ${CMAKE_BINARY_DIR}/backend  ${CMAKE_SOURCE_DIR}/app/podbird.qml
                    DEPENDS podbirdbackend podbirdbackend-qmldir
                    WORKING_DIRECTORY ./app)

# No op custom target for all not compiled files, so they show up in the QtCreator project tree
add_custom_target("podbird_ClickFiles" ALL SOURCES "Podbird.apparmor" "manifest.json.in")
