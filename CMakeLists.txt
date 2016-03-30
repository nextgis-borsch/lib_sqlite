
# Modified by Mikhail Gusev, gusevmihs@gmail.com

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(sqlite3 C)
 
# some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

include(GNUInstallDirs)

set(INSTALL_BIN_DIR ${CMAKE_INSTALL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
set(INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
set(INSTALL_INC_DIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

# Options
option(ENABLE_FTS4 "Include the full-text search engine code in SQLite" ON)
if(ENABLE_FTS4)
    add_definitions(-DSQLITE_ENABLE_FTS4)
endif()
option(ENABLE_RTREE "Include the R-Tree extension" ON)
if(ENABLE_RTREE)
    add_definitions(-DSQLITE_ENABLE_RTREE)
endif()
option(ENABLE_COLUMN_METADATA "This enables some extra APIs that are required by some common systems, including Ruby-on-Rails" OFF)
if(ENABLE_COLUMN_METADATA)
    add_definitions(-DSQLITE_ENABLE_COLUMN_METADATA)
endif()
option(ENABLE_JSON1 "Include JSON SQL functions" ON)
if(ENABLE_JSON1)
    add_definitions(-DSQLITE_ENABLE_JSON1)
endif()
# TODO: what else to add from options, especially for GDAL library?
# https://www.sqlite.org/compile.html

#find_package(Threads)
#if (Threads_FOUND)
#    if (CMAKE_USE_PTHREADS_INIT)
#        add_definitions(-D_REENTRANT=1 -DTHREADSAFE=1)
#        set(EXTRA_LIBS ${CMAKE_THREAD_LIBS_INIT})
#    endif()
#else()
#    message(STATUS "threads package not found")
#endif()
#if(NOT WIN32)
#    find_library(DL_LIBRARY
#        NAMES dl
#        PATHS /usr/lib /usr/local/lib
#        )
#    if(NOT DL_LIBRARY)
#        message(STATUS "dl lib not found")
#    else()
#        set(EXTRA_LIBS ${EXTRA_LIBS} ${DL_LIBRARY})
#    endif()
#endif()

if(BUILD_SHARED_LIBS)
    set(LIB_TYPE SHARED)
else()
    set(LIB_TYPE STATIC)
endif()

set(LIB_NAME sqlite3)

# Build
add_library(${LIB_NAME} ${LIB_TYPE} sqlite3.c) 
if(CMAKE_USE_PTHREADS_INIT)
  target_link_libraries(sqlite3 ${EXTRA_LIBS})
endif()

# TODO: build sqlite executable for tests.

# Install 
set(LIB_HHEADERS sqlite3.h)
install(TARGETS ${LIB_NAME} 
        #EXPORT targets
        RUNTIME DESTINATION ${INSTALL_BIN_DIR} # at least for dlls
        ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
        LIBRARY DESTINATION ${INSTALL_LIB_DIR})
install(FILES ${LIB_HHEADERS} DESTINATION ${INSTALL_INC_DIR})

# Other
export(TARGETS ${LIB_NAME} FILE ${LIB_NAME}-exports.cmake EXPORT_LINK_INTERFACE_LIBRARIES)

# Uninstall
#configure_file(${CMAKE_MODULE_PATH}/cmake_uninstall.cmake.in ${CMAKE_BINARY_DIR}/cmake_uninstall.cmake IMMEDIATE @ONLY)
#add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)