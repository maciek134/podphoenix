file(GLOB WELCOMEWIZARD_QML_JS_FILES *.qml *.js)

# Make the files visible in the qtcreator tree
add_custom_target(podphoenix_welcomewizard_QMlFiles ALL SOURCES ${WELCOMEWIZARD_QML_JS_FILES})

install(FILES ${WELCOMEWIZARD_QML_JS_FILES} DESTINATION ${PODBIRD_DIR}/welcomewizard)


