CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

IF(DEFINED CMAKE_BUILD_TYPE)
  SET(CMAKE_BUILD_TYPE ${CMAKE_BUILD_TYPE} CACHE STRING "Choose the type of build, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel.")
ELSE()
  SET(CMAKE_BUILD_TYPE RelWithDebInfo CACHE STRING "Choose the type of build, options are: None(CMAKE_CXX_FLAGS or CMAKE_C_FLAGS used) Debug Release RelWithDebInfo MinSizeRel.")
ENDIF()

INCLUDE (CheckIncludeFileCXX)
INCLUDE (CMakeDependentOption)

PROJECT(grind)

ADD_DEFINITIONS("-DBOOST_REGEX_MATCH_EXTRA")
LIST(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/CMake/Modules )

FIND_PACKAGE(Boost 1.46 COMPONENTS filesystem thread date_time system regex REQUIRED)
FIND_PACKAGE(Lua REQUIRED)

INCLUDE_DIRECTORIES (include ${Boost_INCLUDE_DIRS} ${Lua_INCLUDE_DIR} )
LINK_LIBRARIES      ( ${Boost_LIBRARIES} pthread ${Lua_LIBRARIES})

SET(LIBRARY_OUTPUT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/lib")
SET(EXECUTABLE_OUTPUT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/bin")

ADD_SUBDIRECTORY(src)

# Install the default configuration and examples
INSTALL(DIRECTORY share/grind DESTINATION share)

# Install the configuration file to /etc only if it's not there
IF(NOT EXISTS /etc/grind/config.lua)
  INSTALL(FILES share/grind/config.lua DESTINATION /etc/grind)
ENDIF()

# Install the helpers and rename them
SET(HELPERS_DIR ${CMAKE_CURRENT_SOURCE_DIR}/test/unit)

  # 1. API tester
  CONFIGURE_FILE(${HELPERS_DIR}/api_test.lua ${CMAKE_BINARY_DIR}/grind-api COPYONLY)
  INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/grind-api DESTINATION bin)
  # 2. grind tester
  CONFIGURE_FILE(${HELPERS_DIR}/handling.lua ${CMAKE_BINARY_DIR}/grind-test COPYONLY)
  INSTALL(PROGRAMS ${CMAKE_BINARY_DIR}/grind-test DESTINATION bin)
