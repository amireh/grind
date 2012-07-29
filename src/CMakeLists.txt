SET(GRIND_SRCS
  main.cpp
  kernel.cpp
  connection.cpp
  logger.cpp
  script_engine.cpp
)

ADD_EXECUTABLE(grind ${GRIND_SRCS})
INSTALL(TARGETS grind DESTINATION bin)

ADD_SUBDIRECTORY(bindings/SWIG)
