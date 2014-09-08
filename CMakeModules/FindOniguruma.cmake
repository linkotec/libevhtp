# - Try to find Oniguruma
# Once done this will define
#
# ONIGURUMA_FOUND - System has Oniguruma
# ONIGURUMA_INCLUDE_DIRS - The Oniguruma include directories
# ONIGURUMA_LIBRARIES - The libraries needed to use Oniguruma

# look for the header file
find_path(ONIGURUMA_INCLUDE_DIR NAMES oniguruma.h
    DOC "The Oniguruma include directory")

# look for the library
find_library(ONIGURUMA_LIBRARY NAMES onig
    DOC "The Oniguruma library")

# handle the QUIETLY and REQUIRED arguments and set ONIGURUMA_FOUND to TRUE
# if all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ONIGURUMA DEFAULT_MSG
    ONIGURUMA_INCLUDE_DIR ONIGURUMA_LIBRARY)

if(ONIGURUMA_FOUND)
    SET(ONIGURUMA_INCLUDE_DIRS ${ONIGURUMA_INCLUDE_DIR})
    SET(ONIGURUMA_LIBRARIES ${ONIGURUMA_LIBRARY})
endif()

mark_as_advanced(ONIGURUMA_INCLUDE_DIR ONIGURUMA_LIBRARY)