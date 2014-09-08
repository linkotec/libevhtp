cmake_minimum_required(VERSION 2.8)
project(reason)

set(PROJECT_MAJOR_VERSION 1)
set(PROJECT_MINOR_VERSION 2)
set(PROJECT_PATCH_VERSION 9)

set (PROJECT_VERSION ${PROJECT_MAJOR_VERSION}.${PROJECT_MINOR_VERSION}.${PROJECT_PATCH_VERSION})
set (CMAKE_MODULE_PATH ${PROJECT_SOURCE_DIR}/CMakeModules)

INCLUDE (CheckFunctionExists)
INCLUDE (CheckIncludeFiles)
INCLUDE (CheckTypeSize)
INCLUDE (CheckCCompilerFlag)

CHECK_FUNCTION_EXISTS(getopt  HAVE_GETOPT)
CHECK_FUNCTION_EXISTS(strndup HAVE_STRNDUP)
CHECK_FUNCTION_EXISTS(strnlen HAVE_STRNLEN)

CHECK_INCLUDE_FILE(inttypes.h HAVE_INTTYPES_H)
CHECK_INCLUDE_FILE(strings.h HAVE_STRINGS_H)
CHECK_INCLUDE_FILE(string.h HAVE_STRING_H)
CHECK_INCLUDE_FILE(stdlib.h HAVE_STDLIB_H)
CHECK_INCLUDE_FILE(stdint.h HAVE_STDINT_H)
CHECK_INCLUDE_FILE(unistd.h HAVE_UNISTD_H)
CHECK_INCLUDE_FILE(memory.h HAVE_MEMORY_H)
CHECK_INCLUDE_FILE(stdarg.h HAVE_STDARG_PROTOTYPES)
CHECK_INCLUDE_FILE(sys/queue.h HAVE_SYS_QUEUE)
CHECK_INCLUDE_FILE(sys/un.h HAVE_SYS_UN)

CHECK_TYPE_SIZE("int" SIZEOF_INT)
CHECK_TYPE_SIZE("long" SIZEOF_LONG)
CHECK_TYPE_SIZE("short" SIZEOF_SHORT)

check_c_compiler_flag(-fvisibility=hidden EVHTP_HAS_VISIBILITY_HIDDEN)

if (EVHTP_HAS_VISIBILITY_HIDDEN)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fvisibility=hidden")
    add_definitions(-DEVHTP_HAS_VISIBILITY_HIDDEN)
endif()

if (NOT HAVE_SYS_QUEUE)
	CONFIGURE_FILE(${CMAKE_CURRENT_SOURCE_DIR}/compat/sys/queue.h.in ${CMAKE_CURRENT_BINARY_DIR}/compat/sys/queue.h)
endif(NOT HAVE_SYS_QUEUE)

# -DEVHTP_DISABLE_SSL:STRING=ON
OPTION(EVHTP_DISABLE_SSL       "Disable ssl support"      OFF)

# -DEVHTP_DISABLE_EVTHR:STRING=ON
OPTION(EVHTP_DISABLE_EVTHR     "Disable evthread support" OFF)

# -DEVHTP_DISABLE_REGEX:STRING=ON
OPTION(EVHTP_DISABLE_REGEX     "Disable regex support"    OFF)

# -DEVHTP_BUILD_SHARED:STRING=ON
OPTION(EVHTP_BUILD_SHARED      "Build shared library too" OFF)

# -DEVHTP_USE_DEFER_ACCEPT:STRING=ON
OPTION(EVHTP_USE_DEFER_ACCEPT  "Enable TCP_DEFER_ACCEPT"  OFF)

if (EVHTP_USE_DEFER_ACCEPT)
	set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUSE_DEFER_ACCEPT")
endif(EVHTP_USE_DEFER_ACCEPT)

SET(CMAKE_INCLUDE_CURRENT_DIR ON)

include(BaseConfig)

message("Build Type: ${CMAKE_BUILD_TYPE}")
message("Std CFLAGS: ${CMAKE_C_FLAGS}")
message("Dbg CFLAGS: ${CMAKE_C_FLAGS_DEBUG}")
message("Rel CFLAGS: ${CMAKE_C_FLAGS_RELEASE}")

if(NOT LIBEVENT_INCLUDE_DIRS)
    find_package(LibEvent2 REQUIRED)
    set(LIBEVHTP_EXTERNAL_INCLUDE_DIRS ${LIBEVENT2_INCLUDE_DIRS})
    set(LIBEVHTP_EXTERNAL_LIBS ${LIBEVENT2_LIBRARIES})

    if(NOT LIBEVENT2_BUILD_WITH_OPENSSL)
        set(EVHTP_DISABLE_SSL ON)
    endif()
else()
    set(LIBEVHTP_EXTERNAL_INCLUDE_DIRS ${LIBEVENT_INCLUDE_DIRS})
    set(LIBEVHTP_EXTERNAL_LIBS event)
    
    if(EVENT__DISABLE_OPENSSL)
        set(EVHTP_DISABLE_SSL ON)
    endif()
endif()

if(NOT EVHTP_DISABLE_SSL)
    find_package(OpenSSL)
    
    if(OPENSSL_FOUND)
        list(APPEND LIBEVHTP_EXTERNAL_INCLUDE_DIRS ${OPENSSL_INCLUDE_DIR})
        list(APPEND LIBEVHTP_EXTERNAL_LIBS ${OPENSSL_LIBRARIES})
    else()
        set(EVHTP_DISABLE_SSL ON)
    endif()
endif()

if(NOT EVHTP_DISABLE_REGEX)
    find_package(Oniguruma)

    if(ONIGURUMA_FOUND)
        message("-- Using system libonig")
        
        list(APPEND LIBEVHTP_EXTERNAL_INCLUDE_DIRS ${ONIGURUMA_INCLUDE_DIRS})
        list(APPEND LIBEVHTP_EXTERNAL_LIBS ${ONIGURUMA_LIBRARIES})
    else()
       add_subdirectory(oniguruma)
        
       list(APPEND LIBEVHTP_EXTERNAL_INCLUDE_DIRS
            ${CMAKE_CURRENT_BINARY_DIR}/oniguruma
            ${CMAKE_CURRENT_SOURCE_DIR}/oniguruma
        )
        
        list(APPEND LIBEVHTP_EXTERNAL_LIBS libonig)
    endif()
endif()

include_directories(
	${CMAKE_CURRENT_BINARY_DIR}/compat
	${CMAKE_CURRENT_SOURCE_DIR}/htparse
	${CMAKE_CURRENT_SOURCE_DIR}/evthr
	${CMAKE_CURRENT_SOURCE_DIR}
	${LIBEVHTP_EXTERNAL_INCLUDE_DIRS}
)

if (NOT ${LIBEVENT_PTHREADS_FOUND})
	set(EVHTP_DISABLE_EVTHR ON)
endif(NOT ${LIBEVENT_PTHREADS_FOUND})

set(LIBEVHTP_SOURCES evhtp.c htparse/htparse.c)

if (NOT EVHTP_DISABLE_EVTHR)
	set (LIBEVHTP_EXTERNAL_LIBS ${LIBEVHTP_EXTERNAL_LIBS} pthread)
	set (LIBEVHTP_SOURCES ${LIBEVHTP_SOURCES} evthr/evthr.c)
endif(NOT EVHTP_DISABLE_EVTHR)

if (NOT ${CMAKE_BUILD_TYPE} STREQUAL "Debug")
  set (CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DNDEBUG")
endif (NOT ${CMAKE_BUILD_TYPE} STREQUAL "Debug")

IF (WIN32)
	if (MSVC)
		set (SYS_LIBS ws2_32)
		add_definitions(-D_CRT_SECURE_NO_WARNINGS)
		add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
	else()
		ADD_DEFINITIONS(-DWIN32)
		ADD_DEFINITIONS(-march=i486)
		find_library (LIB_WS32 ws2_32)
		set (SYS_LIBS ${SYS_LIBS} ${LIB_WS32})
	endif()
ELSE ()
	if (NOT ${CMAKE_SYSTEM_NAME} STREQUAL "FreeBSD")
		find_library (LIB_DL dl)
		set (SYS_LIBS ${LIB_DL})
	endif()

	if (NOT APPLE)
		find_library (LIB_RT rt)
		set (SYS_LIBS ${SYS_LIBS} ${LIB_RT})
	endif()

ENDIF (WIN32)

add_custom_target(examples)

if (EVHTP_BUILD_SHARED)
	set (EVHTP_LIBTYPE SHARED)
else()
	set (EVHTP_LIBTYPE STATIC)
endif()

configure_file(
	${CMAKE_CURRENT_SOURCE_DIR}/evhtp-config.h.in
	${CMAKE_CURRENT_BINARY_DIR}/evhtp-config.h)

add_library(libevhtp ${EVHTP_LIBTYPE} ${LIBEVHTP_SOURCES})

set_target_properties(libevhtp PROPERTIES OUTPUT_NAME "evhtp")
target_link_libraries(libevhtp ${LIBEVHTP_EXTERNAL_LIBS})

if (HAVE_GETOPT)
	add_executable(test EXCLUDE_FROM_ALL examples/test.c)
else()
	add_executable(test EXCLUDE_FROM_ALL compat/getopt.c examples/test.c)
endif()

add_executable(test_basic EXCLUDE_FROM_ALL examples/test_basic.c)
add_executable(test_vhost EXCLUDE_FROM_ALL examples/test_vhost.c)
add_executable(test_client EXCLUDE_FROM_ALL examples/test_client.c)
add_executable(test_query EXCLUDE_FROM_ALL examples/test_query.c)

if (NOT EVHTP_DISABLE_EVTHR)
	add_executable(test_proxy EXCLUDE_FROM_ALL examples/test_proxy.c)
	target_link_libraries(test_proxy libevhtp ${LIBEVHTP_EXTERNAL_LIBS} ${SYS_LIBS})
endif()

target_link_libraries(test libevhtp ${LIBEVHTP_EXTERNAL_LIBS} ${SYS_LIBS})
target_link_libraries(test_basic libevhtp ${LIBEVHTP_EXTERNAL_LIBS} ${SYS_LIBS})
target_link_libraries(test_vhost libevhtp ${LIBEVHTP_EXTERNAL_LIBS} ${SYS_LIBS})
target_link_libraries(test_client libevhtp ${LIBEVHTP_EXTERNAL_LIBS} ${SYS_LIBS})
target_link_libraries(test_query libevhtp ${LIBEVHTP_EXTERNAL_LIBS} ${SYS_LIBS})

add_dependencies(examples test test_basic test_vhost test_client test_proxy test_query)

if (NOT LIB_INSTALL_DIR)
  set (LIB_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lib")
endif (NOT LIB_INSTALL_DIR)

if(NOT INCLUDE_INSTALL_DIR)
	set(INCLUDE_INSTALL_DIR ${CMAKE_INSTALL_PREFIX}/include)
endif()

install (TARGETS libevhtp DESTINATION ${LIB_INSTALL_DIR})
install (FILES evhtp.h DESTINATION ${INCLUDE_INSTALL_DIR})
install (FILES htparse/htparse.h DESTINATION ${INCLUDE_INSTALL_DIR})
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/evhtp-config.h DESTINATION ${INCLUDE_INSTALL_DIR})

if (NOT EVHTP_DISABLE_EVTHR)
	install (FILES evthr/evthr.h DESTINATION ${INCLUDE_INSTALL_DIR})
endif()

if (NOT EVHTP_DISABLE_REGEX)
	if (NOT ONIGURUMA_FOUND)
		install (FILES oniguruma/onigposix.h DESTINATION ${INCLUDE_INSTALL_DIR})
	endif()
endif()

IF (WIN32)
   install (FILES compat/sys/queue.h DESTINATION ${INCLUDE_INSTALL_DIR}/sys)
ENDIF (WIN32)

configure_file(
	${CMAKE_CURRENT_SOURCE_DIR}/evhtp.pc.in
	${CMAKE_CURRENT_BINARY_DIR}/evhtp.pc @ONLY)
