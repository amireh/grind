SET(GRIND_SRCS
  #binreloc.c

  main.cpp
  kernel.cpp
  # watcher.cpp
  # message.cpp
  # dispatcher.cpp
  connection.cpp

  log_manager.cpp
  logger.cpp
  log4cpp/file_log_layout.cpp
  log4cpp/syslog_log_layout.cpp

  #configurator.cpp
  #configurable.cpp
  script_engine.cpp
)

ADD_EXECUTABLE(grind ${GRIND_SRCS})
INSTALL(TARGETS grind DESTINATION bin)

ADD_SUBDIRECTORY(bindings/SWIG)
