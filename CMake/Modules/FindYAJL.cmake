# FindYAJL.cmake
# --
# Find the YAJL library
#
# This module defines:
#   YAJL_INCLUDE_DIRS - where to find yajl/yajl_common.h
#   YAJL_LIBRARIES    - the yajl library
#   YAJL_FOUND        - True if YAJL was found

Include(FindModule)
FIND_MODULE(YAJL yajl/yajl_common.h "" "" yajl "" "")
