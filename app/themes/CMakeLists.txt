file(GLOB THEME_FILES *.qml)

# Make the files visible in the qtcreator tree
add_custom_target(podphoenix_THEMEFiles ALL SOURCES ${THEME_FILES})

install(FILES ${THEME_FILES} DESTINATION ${PODBIRD_DIR}/themes)

