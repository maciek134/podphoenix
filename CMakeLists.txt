project(podphoenix C CXX)
cmake_minimum_required(VERSION 2.8.12)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_CXX_FLAGS "-Wall -Wextra")
set(CMAKE_CXX_FLAGS_DEBUG "-g")
set(CMAKE_CXX_FLAGS_RELEASE "-O3")

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

set(APP_NAME          Podphoenix)
set(APP_ID            "soy.iko.podphoenix")
if(DEFINED ENV{DESKTOP_BUILD})
    set(PODBIRD_DIR "/usr/share/podphoenix/qml/podphoenix")
    set(ICON "/usr/share/podphoenix/logo.png")
    set(SPLASH "/usr/share/podphoenix/splash.png")
    set(QT_IMPORTS_DIR "/usr/lib/${ARCH_TRIPLET}/qt5/qml/")
else(DEFINED ENV{DESKTOP_BUILD})
    set(PODBIRD_DIR "share/qml/podphoenix")
    set(ICON "logo.png")
    set(SPLASH "splash.png")
    set(QT_IMPORTS_DIR "lib/${ARCH_TRIPLET}")
endif(DEFINED ENV{DESKTOP_BUILD})
set(MAIN_QML          "podphoenix.qml")

# Set install paths
set(CMAKE_INSTALL_PREFIX /)
if(DEFINED ENV{DESKTOP_BUILD})
    set(DATA_DIR "/usr/share/podphoenix/")
    set(DESKTOP_DIR "/usr/share/applications/")
else(DEFINED ENV{DESKTOP_BUILD})
    set(DATA_DIR /)
    set(DESKTOP_DIR ${DATA_DIR})
endif(DEFINED ENV{DESKTOP_BUILD})
set(DESKTOP_FILE_NAME "Podphoenix.desktop")

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

install(FILES "logo.png" DESTINATION ${DATA_DIR})
install(FILES "splash.png" DESTINATION ${DATA_DIR})
install(FILES "Podphoenix.apparmor" DESTINATION ${DATA_DIR})

add_subdirectory(app)
add_subdirectory(backend)
add_subdirectory(po)

add_custom_target("autopilot" chmod +x ${CMAKE_SOURCE_DIR}/app/tests/autopilot/run
                    COMMAND ${CMAKE_SOURCE_DIR}/app/tests/autopilot/run
                    DEPENDS podphoenixbackend podphoenixbackend-qmldir
                    WORKING_DIRECTORY ./app)

#add_custom_target("check" /usr/bin/qmltestrunner -input ${CMAKE_SOURCE_DIR}/app/tests/unit -import ${CMAKE_BINARY_DIR}/backend
#                    DEPENDS podphoenixbackend podphoenixbackend-qmldir
#                    WORKING_DIRECTORY ./app)

add_custom_target("run" /usr/bin/qmlscene -I ${CMAKE_BINARY_DIR}/backend  ${CMAKE_SOURCE_DIR}/app/podphoenix.qml
                    DEPENDS podphoenixbackend podphoenixbackend-qmldir
                    WORKING_DIRECTORY ./app)

# No op custom target for all not compiled files, so they show up in the QtCreator project tree
add_custom_target("podphoenix_ClickFiles" ALL SOURCES "Podphoenix.apparmor" "manifest.json.in")
