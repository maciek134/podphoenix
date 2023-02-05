include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)

set(
    Podphoenixbackend_SRCS
    modules/Podphoenix/backend.cpp
    modules/Podphoenix/filemanager.cpp
)

add_library(Podphoenixbackend MODULE
    ${Podphoenixbackend_SRCS}
)

set_target_properties(Podphoenixbackend PROPERTIES
         LIBRARY_OUTPUT_DIRECTORY Podphoenix)

# qt5_use_modules(Podphoenixbackend Gui Qml Quick)
target_link_libraries(Podphoenixbackend Qt5::Qml Qt5::Gui Qt5::Quick)

# Copy qmldir file to build dir for running in QtCreator
add_custom_target(Podphoenixbackend-qmldir ALL
    COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/modules/Podphoenix/qmldir ${CMAKE_CURRENT_BINARY_DIR}/Podphoenix
    DEPENDS ${QMLFILES}
)

# Install plugin file
install(TARGETS Podphoenixbackend DESTINATION ${QT_IMPORTS_DIR}/Podphoenix/)
install(FILES   modules/Podphoenix/qmldir DESTINATION ${QT_IMPORTS_DIR}/Podphoenix/)
