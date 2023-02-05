file(GLOB COMPONENTS_FILES *.qml)

# Make the files visible in the qtcreator tree
add_custom_target(podphoenix_components_QMlFiles ALL SOURCES ${COMPONENTS_FILES})

install(FILES ${COMPONENTS_FILES} DESTINATION ${PODBIRD_DIR}/components)

