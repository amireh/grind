# Findlog4cpp.cmake
# --
# Find the log4cpp library
#
# This module defines:
#   log4cpp_INCLUDE_DIRS - where to find log4cpp/Category.hh
#   log4cpp_LIBRARIES    - the log4cpp library
#   log4cpp_FOUND        - True if log4cpp was found

Include(FindModule)
FIND_MODULE(log4cpp log4cpp/Category.hh "" "" log4cpp "" "")
