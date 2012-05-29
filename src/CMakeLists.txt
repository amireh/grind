SET(GRIND_SRCS
  main.cpp
  kernel.cpp
  message.cpp
  dispatcher.cpp
  connection.cpp

  log_manager.cpp
  logger.cpp
  log4cpp/file_log_layout.cpp
  log4cpp/syslog_log_layout.cpp

  configurator.cpp
  configurable.cpp
)

ADD_EXECUTABLE(grind ${GRIND_SRCS})
INSTALL(TARGETS grind DESTINATION bin)
