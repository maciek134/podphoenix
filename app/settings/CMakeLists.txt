file(GLOB SETTING_FILES *.qml)

# Make the files visible in the qtcreator tree
add_custom_target(podphoenix_SETTINGFiles ALL SOURCES ${SETTING_FILES})

install(FILES ${SETTING_FILES} DESTINATION ${PODBIRD_DIR}/settings)

