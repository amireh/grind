#  Find ncurses header and library files
#
#  When called, this script tries to define:
#  ncurses_INCLUDE_DIR    Header files directory
#  ncurses_LIBRARIES      library files (or file when using lua 5.1)
#  ncurses_FOUND          defined (true) if lua was found
#  ncurses_VERSION        either 5.1 or 5.0 or undefined
#
#  authors: Benjamin Knecht, Reto Grieder
#
# Several changes and additions by Fabian 'x3n' Landau
#                 > www.orxonox.net <

IF (ncurses_LIBRARIES AND ncurses_INCLUDE_DIR)

  # Already in cache, be silent
  SET(ncurses_FOUND TRUE)
  SET(ncurses_FIND_QUIETLY TRUE)
  # MESSAGE(STATUS "ncurses was found.")

ELSE ()

  FIND_PATH(ncurses_INCLUDE_DIR
    NAMES ncurses.h curses.h
    PATH_SUFFIXES ncurses
    PATHS /usr/local/include /usr/include)


  FIND_LIBRARY(ncurses_LIBRARY
    NAMES ncurses ncursesw
    PATHS /usr/local/lib /usr/lib)

  IF (ncurses_INCLUDE_DIR AND ncurses_LIBRARY)

    # Found newer lua 5.1 libs
    SET(ncurses_FOUND TRUE)
    SET(ncurses_INCLUDE_DIR ${ncurses_INCLUDE_DIR} CACHE PATH "")
    SET(ncurses_LIBRARIES ${ncurses_LIBRARY} CACHE FILEPATH "")
    SET(ncurses_LIBRARY_NAMES "ncurses ncursesw")

  ENDIF ()

  IF (ncurses_FOUND)
    MESSAGE(STATUS "ncurses was found.")
    IF (VERBOSE_FIND)
      MESSAGE (STATUS "  include path: ${ncurses_INCLUDE_DIR}")
      MESSAGE (STATUS "  library path: ${ncurses_LIBRARIES}")
      MESSAGE (STATUS "  libraries:    ${ncurses_LIBRARY_NAMES}")
    ENDIF (VERBOSE_FIND)
  ELSE ()
    IF (ncurses_INCLUDE_DIR AND NOT ncurses_LIBRARY)
      MESSAGE(SEND_ERROR "ncurses library was not found")
    ENDIF (ncurses_INCLUDE_DIR AND NOT ncurses_LIBRARY)
    IF (NOT ncurses_INCLUDE_DIR AND ncurses_LIBRARY)
      MESSAGE(SEND_ERROR "ncurses include path was not found")
    ENDIF (NOT ncurses_INCLUDE_DIR AND ncurses_LIBRARY)

    MESSAGE(SEND_ERROR "ncurses was not found.")
  ENDIF ()

ENDIF (ncurses_LIBRARIES AND ncurses_INCLUDE_DIR)
