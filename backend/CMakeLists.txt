include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
)

set(
    Podbirdbackend_SRCS
    modules/Podbird/backend.cpp
    modules/Podbird/filemanager.cpp
)

add_library(Podbirdbackend MODULE
    ${Podbirdbackend_SRCS}
)

set_target_properties(Podbirdbackend PROPERTIES
         LIBRARY_OUTPUT_DIRECTORY Podbird)

qt5_use_modules(Podbirdbackend Gui Qml Quick)

# Copy qmldir file to build dir for running in QtCreator
add_custom_target(Podbirdbackend-qmldir ALL
    COMMAND cp ${CMAKE_CURRENT_SOURCE_DIR}/modules/Podbird/qmldir ${CMAKE_CURRENT_BINARY_DIR}/Podbird
    DEPENDS ${QMLFILES}
)

# Install plugin file
install(TARGETS Podbirdbackend DESTINATION ${QT_IMPORTS_DIR}/Podbird/)
install(FILES   modules/Podbird/qmldir DESTINATION ${QT_IMPORTS_DIR}/Podbird/)

