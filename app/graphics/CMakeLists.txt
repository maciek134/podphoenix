file(GLOB GRAPHIC_FILES *.png *.jpg *.svg)

# Make the files visible in the qtcreator tree
add_custom_target(podphoenix_GRAPHICFiles ALL SOURCES ${GRAPHIC_FILES})

install(FILES ${GRAPHIC_FILES} DESTINATION ${PODBIRD_DIR}/graphics)

