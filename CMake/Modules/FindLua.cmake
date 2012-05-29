#  Find Lua header and library files
#
#  When called, this script tries to define:
#  Lua_INCLUDE_DIR    Header files directory
#  Lua_LIBRARIES      library files (or file when using lua 5.1)
#  Lua_FOUND          defined (true) if lua was found
#  Lua_VERSION        either 5.1 or 5.0 or undefined
#
#  authors: Benjamin Knecht, Reto Grieder
#
# Several changes and additions by Fabian 'x3n' Landau
#                 > www.orxonox.net <

IF (Lua_LIBRARIES AND Lua_INCLUDE_DIR)

  # Already in cache, be silent
  SET(Lua_FOUND TRUE)
  SET(Lua_FIND_QUIETLY TRUE) 
#  MESSAGE(STATUS "Lua was found.")

ELSE (Lua_LIBRARIES AND Lua_INCLUDE_DIR)

  FIND_PATH(Lua_INCLUDE_DIR_51 lua.h
    /usr/include/lua5.1
    /usr/local/include/lua5.1
    ../libs/lua-5.1.3/include)

  FIND_PATH(Lua_INCLUDE_DIR_50 lua.h
    /usr/include/lua50
    /usr/local/include/lua50
    /usr/pack/lua-5.0.3-sd/include)

  FIND_LIBRARY(Lua_LIBRARY_51 NAMES lua5.1 lua PATHS
    /usr/lib
    /usr/local/lib
    ../libs/lua-5.1.3/lib)

  FIND_LIBRARY(Lua_LIBRARY_1_50 NAMES lua50 lua PATHS
    /usr/pack/lua-5.0.3-sd/i686-debian-linux3.1/lib #tardis
    /usr/lib
    /usr/local/lib)

  FIND_LIBRARY(Lua_LIBRARY_2_50 NAMES lualib50 lualib PATHS
    /usr/pack/lua-5.0.3-sd/i686-debian-linux3.1/lib #tardis
    /usr/lib
    /usr/local/lib)


  IF (Lua_INCLUDE_DIR_51 AND Lua_LIBRARY_51)

    # Found newer lua 5.1 libs
    SET(Lua_FOUND TRUE)
    SET(Lua_VERSION "5.1" CACHE STRING "")
    SET(Lua_INCLUDE_DIR ${Lua_INCLUDE_DIR_51} CACHE PATH "")
    SET(Lua_LIBRARIES ${Lua_LIBRARY_51} CACHE FILEPATH "")
    SET(Lua_LIBRARY_NAMES "lua5.1 lua")

  ELSEIF(Lua_INCLUDE_DIR_50 AND Lua_LIBRARY_1_50 AND Lua_LIBRARY_2_50)

    # Found older lua 5.0 libs
    SET(Lua_FOUND TRUE)
    SET(Lua_VERSION "5.0" CACHE STRING "")
    SET(Lua_INCLUDE_DIR ${Lua_INCLUDE_DIR_50} CACHE PATH "")
    SET(Lua_LIBRARIES ${Lua_LIBRARY_1_50} ${Lua_LIBRARY_2_50} CACHE FILEPATH "")
    SET(Lua_LIBRARY_NAMES "lua50 lua, lualib50 lualib")

  ENDIF (Lua_INCLUDE_DIR_51 AND Lua_LIBRARY_51)
	

  IF (Lua_FOUND)
    MESSAGE(STATUS "Lua was found.")
    IF (VERBOSE_FIND)
      MESSAGE (STATUS "  include path: ${Lua_INCLUDE_DIR}")
      MESSAGE (STATUS "  library path: ${Lua_LIBRARIES}")
      MESSAGE (STATUS "  libraries:    ${Lua_LIBRARY_NAMES}")
    ENDIF (VERBOSE_FIND)
  ELSE (Lua_FOUND)
    IF (Lua_INCLUDE_DIR_51 AND NOT Lua_LIBRARY_51)
      MESSAGE(SEND_ERROR "Lua 5.1 library was not found")
    ENDIF (Lua_INCLUDE_DIR_51 AND NOT Lua_LIBRARY_51)
    IF (NOT Lua_INCLUDE_DIR_51 AND Lua_LIBRARY_51)
      MESSAGE(SEND_ERROR "Lua 5.1 include path was not found")
    ENDIF (NOT Lua_INCLUDE_DIR_51 AND Lua_LIBRARY_51)

    IF (Lua_INCLUDE_DIR_50)
      IF (NOT Lua_LIBRARY_1_50)
       MESSAGE(SEND_ERROR "Lua 5.0 library "lua" was not found")
      ENDIF (NOT Lua_LIBRARY_1_50)
      IF (NOT Lua_LIBRARY_2_50)
       MESSAGE(SEND_ERROR "Lua 5.0 library "lualib" was not found")
      ENDIF (NOT Lua_LIBRARY_2_50)
    ENDIF (Lua_INCLUDE_DIR_50)
    IF (NOT Lua_INCLUDE_DIR_50 AND Lua_LIBRARY_1_50 AND Lua_LIBRARY_2_50)
      MESSAGE(SEND_ERROR "Lua 5.0 include path was not found")
    ENDIF (NOT Lua_INCLUDE_DIR_50 AND Lua_LIBRARY_1_50 AND Lua_LIBRARY_2_50)

    MESSAGE(SEND_ERROR "Lua was not found.")
  ENDIF (Lua_FOUND)

ENDIF (Lua_LIBRARIES AND Lua_INCLUDE_DIR)

