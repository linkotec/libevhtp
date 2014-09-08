# - Try to find the LibEvent2
# Once done this will define
#
# LIBEVENT2_FOUND - System has LibEvent2
# LIBEVENT2_INCLUDE_DIRS - The LibEvent2 include directories
# LIBEVENT2_LIBRARIES - The libraries needed to use LibEvent2

# look for the header file
find_path(LIBEVENT2_INCLUDE_DIR NAMES event2/event.h
    DOC "The LibEvent2 include directory")

# look for the library
find_library(LIBEVENT2_LIBRARY NAMES event
    DOC "The LibEvent2 library")

# handle the QUIETLY and REQUIRED arguments and set ONIGURUMA_FOUND to TRUE
# if all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LIBEVENT2 DEFAULT_MSG
    LIBEVENT2_INCLUDE_DIR LIBEVENT2_LIBRARY)

if(LIBEVENT2_FOUND)
    set(LIBEVENT2_INCLUDE_DIRS ${LIBEVENT2_INCLUDE_DIR})
    set(LIBEVENT2_LIBRARIES ${LIBEVENT2_LIBRARY})
        
    # check if libevent2 was build with OpenSSL
    include(CheckSymbolExists)
    check_symbol_exists(EVENT__HAVE_OPENSSL
        "${LIBEVENT2_INCLUDE_DIR}/event2/event-config.h"
        LIBEVENT2_BUILD_WITH_OPENSSL)
endif()

mark_as_advanced(LIBEVENT2_INCLUDE_DIR LIBEVENT2_LIBRARY)
