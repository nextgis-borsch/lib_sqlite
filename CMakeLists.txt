################################################################################
# Project:  CMake4GDAL
# Purpose:  CMake build scripts
# Author:   Mikhail Gusev, gusevmihs@gmail.com
################################################################################
# Copyright (C) 2018, NextGIS <info@nextgis.com>
# Copyright (C) 2016, Mikhail Gusev
# Copyright (C) 2018, Dmitry Baryshnikov <dmitry.baryshnikov@nextgis.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
################################################################################

# Modified by Mikhail Gusev, gusevmihs@gmail.com

cmake_minimum_required(VERSION 3.16.3 FATAL_ERROR)

project(sqlite3)

if(NOT DEFINED PACKAGE_VENDOR)
    set(PACKAGE_VENDOR NextGIS)
endif()

if(NOT DEFINED PACKAGE_BUGREPORT)
    set(PACKAGE_BUGREPORT info@nextgis.com)
endif()

# some init settings
set(CMAKE_COLOR_MAKEFILE ON)

if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

if(OSX_FRAMEWORK)
    set(INSTALL_BIN_DIR "bin" CACHE INTERNAL "Installation directory for executables" FORCE)
    set(INSTALL_LIB_DIR "Library/Frameworks" CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_CMAKECONF_DIR ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Resources/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
    set(INSTALL_INC_DIR ${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Headers CACHE INTERNAL "Installation directory for headers" FORCE)
    set(SKIP_INSTALL_HEADERS ON)
    set(SKIP_INSTALL_EXECUTABLES ON)
    set(SKIP_INSTALL_FILES ON)
    set(SKIP_INSTALL_EXPORT ON)
    set(CMAKE_MACOSX_RPATH ON)
else()
    include(GNUInstallDirs)

    set(INSTALL_BIN_DIR ${CMAKE_INSTALL_BINDIR} CACHE INTERNAL "Installation directory for executables" FORCE)
    set(INSTALL_LIB_DIR ${CMAKE_INSTALL_LIBDIR} CACHE INTERNAL "Installation directory for libraries" FORCE)
    set(INSTALL_INC_DIR ${CMAKE_INSTALL_INCLUDEDIR} CACHE INTERNAL "Installation directory for headers" FORCE)
    set(INSTALL_PKGCONFIG_DIR "${INSTALL_LIB_DIR}/pkgconfig" CACHE INTERNAL "Installation directory for pkgconfig (.pc) files" FORCE)
    set(INSTALL_CMAKECONF_DIR ${CMAKE_INSTALL_DATADIR}/${PROJECT_NAME}/CMake CACHE INTERNAL "Installation directory for cmake config files" FORCE)
endif()


set(PACKAGE_NAME ${PROJECT_NAME})
string(TOUPPER ${PACKAGE_NAME} PACKAGE_UPPER_NAME)

set(AMALGAM_HEADER sqlite3.h sqlite3ext.h)
set(AMALGAM_SOURCE sqlite3.c)

include(${CMAKE_CURRENT_LIST_DIR}/cmake/util.cmake)
set_version(VER_H_MAJOR VER_H_MINOR VER_H_RELEASE ${AMALGAM_HEADER})
set_version(VER_C_MAJOR VER_C_MINOR VER_C_RELEASE ${AMALGAM_SOURCE})
set(SQLITE_HEADER_VERSION "${VER_H_MAJOR}.${VER_H_MINOR}.${VER_H_RELEASE}")
set(SQLITE_SOURCE_VERSION "${VER_C_MAJOR}.${VER_C_MINOR}.${VER_C_RELEASE}")
string(COMPARE NOTEQUAL ${SQLITE_HEADER_VERSION} ${SQLITE_SOURCE_VERSION} NOTEQUAL_VERSIONS)
if(NOTEQUAL_VERSIONS)
    # do this because source and header files have their versions defined twice
    message(FATAL_ERROR "Source and header files have different versions!")
endif()

include(${CMAKE_CURRENT_LIST_DIR}/cmake/borsch/cmake/version.cmake)

set(VERSION ${SQLITE_HEADER_VERSION})
set(RESOURCE_VERSION "${VER_H_MAJOR},${VER_H_MINOR},${VER_H_RELEASE},0")
report_version(${PROJECT_NAME} ${VERSION})

if(OSX_FRAMEWORK)
    set(FRAMEWORK_VERSION "${VER_H_MAJOR}")
endif()

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

if(WIN32)
    set(AMALGAM_SOURCE ${AMALGAM_SOURCE} sqlite3.rc)
    add_definitions(-DUSE_FULLWARN=0
        -DUSE_RUNTIME_CHECKS=0
        -DUSE_CRT_DLL=1
        "-DSQLITE_CDECL=__cdecl"
        "-DSQLITE_APICALL=__stdcall"
        "-DSQLITE_CALLBACK=__stdcall"
        "-DSQLITE_SYSAPI=__stdcall"
        -D_CRT_SECURE_NO_DEPRECATE
        -D_CRT_SECURE_NO_WARNINGS
        -D_CRT_NONSTDC_NO_DEPRECATE
        -D_CRT_NONSTDC_NO_WARNINGS
        -DSQLITE_THREADSAFE=1
        -DSQLITE_THREAD_OVERRIDE_LOCK=-1
        -DSQLITE_TEMP_STORE=1
        -DSQLITE_MAX_TRIGGER_DEPTH=100
        -DSQLITE_OS_WIN=1
        -DRC_VERONLY)
endif()

if(CMAKE_BUILD_TYPE STREQUAL "Debug" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    add_definitions(-DDEBUG -D_DEBUG -DDEBUG_UNUSED)
else()
    add_definitions(-DNDEBUG -DDEBUG=0)
endif()

# Options
if(WIN32)
    option(ENABLE_FTS3 "Include the full-text search engine code in SQLite" ON)
    if(ENABLE_FTS3)
        add_definitions(-DSQLITE_ENABLE_FTS3=1)
    endif()
    # TODO: for Win10 - FTS4
    # Also -DSQLITE_SYSTEM_MALLOC=1 -DSQLITE_OMIT_LOCALTIME=1
else()
    option(ENABLE_FTS5 "Include the full-text search engine code in SQLite" ON)
    if(ENABLE_FTS5)
        add_definitions(-DSQLITE_ENABLE_FTS5=1)
    endif()
endif()
option(ENABLE_RTREE "Include the R-Tree extension" ON)
if(ENABLE_RTREE)
    add_definitions(-DSQLITE_ENABLE_RTREE=1)
endif()
option(ENABLE_COLUMN_METADATA "This enables some extra APIs that are required by some common systems, including Ruby-on-Rails" ON)
if(ENABLE_COLUMN_METADATA)
    add_definitions(-DSQLITE_ENABLE_COLUMN_METADATA=1)
endif()
option(ENABLE_JSON1 "Include JSON SQL functions" ON)
if(ENABLE_JSON1)
    add_definitions(-DSQLITE_ENABLE_JSON1)
endif()
option(SQLITE_ENABLE_EXPLAIN_COMMENTS "Enable explain comments" ON)
if(SQLITE_ENABLE_EXPLAIN_COMMENTS)
    add_definitions(-DSQLITE_ENABLE_EXPLAIN_COMMENTS)
endif()
option(SQLITE_SESSION "Enable sessions" OFF)
if(SQLITE_SESSION)
    add_definitions(-DSQLITE_ENABLE_SESSION=1 -DSQLITE_ENABLE_PREUPDATE_HOOK=1)
endif()
if(ENABLE_RTREE AND ENABLE_JSON1)
    option(ENABLE_GEOPOLY "Include GeoJSON SQL functions" ON)
    if(ENABLE_GEOPOLY)
        add_definitions(-DSQLITE_ENABLE_GEOPOLY)
    endif()
endif()

configure_file(${CMAKE_SOURCE_DIR}/cmake/sqlite3rc.h.cmake.in ${CMAKE_BINARY_DIR}/sqlite3rc.h IMMEDIATE @ONLY)

find_package(Threads)
if (Threads_FOUND)
    if (CMAKE_USE_PTHREADS_INIT)
        add_definitions(-D_REENTRANT=1 -DTHREADSAFE=1)
        set(EXTRA_LIBS ${CMAKE_THREAD_LIBS_INIT})
    endif()
else()
    message(STATUS "threads package not found")
endif()

set(LIB_NAME ${PROJECT_NAME})
if(BUILD_SHARED_LIBS)
    add_library(${LIB_NAME} SHARED ${AMALGAM_SOURCE})
    if(MSVC)
        set_target_properties(${LIB_NAME} PROPERTIES IMPORT_SUFFIX "_i.lib")
    endif()
elseif(OSX_FRAMEWORK)
    add_library(${LIB_NAME} SHARED ${AMALGAM_SOURCE} ${AMALGAM_HEADER})
    set_target_properties(${LIB_NAME} PROPERTIES
      FRAMEWORK TRUE
      FRAMEWORK_VERSION ${FRAMEWORK_VERSION}
      MACOSX_FRAMEWORK_SHORT_VERSION_STRING ${VERSION}
      MACOSX_FRAMEWORK_BUNDLE_VERSION ${VERSION}
      MACOSX_FRAMEWORK_IDENTIFIER org.sqlite.sqlite3
      XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
      PUBLIC_HEADER "${AMALGAM_HEADER}")
else()
    add_library(${LIB_NAME} STATIC ${AMALGAM_SOURCE})
    if(CMAKE_COMPILER_IS_GNUCC OR CMAKE_COMPILER_IS_GNUCXX)
        set( CMAKE_CXX_FLAGS "-fpic ${CMAKE_CXX_FLAGS}" )
        set( CMAKE_C_FLAGS   "-fpic ${CMAKE_C_FLAGS}" )
    endif()
endif()

# Add path to includes to build-tree export
target_include_directories(${LIB_NAME} PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
)

if(WIN32)
    target_compile_definitions(${LIB_NAME}
        INTERFACE 
            "-DSQLITE_API=__declspec(dllimport)"
        PRIVATE
            "-DSQLITE_API=__declspec(dllexport)"
    )
endif()

set_target_properties(${LIB_NAME} PROPERTIES
    VERSION ${VERSION}
    SOVERSION ${VER_H_MAJOR})

if(CMAKE_USE_PTHREADS_INIT)
  target_link_libraries(${LIB_NAME} ${EXTRA_LIBS})
endif()


if(MSVC)
    set_property(TARGET ${LIB_NAME} APPEND PROPERTY
        INTERFACE_COMPILE_DEFINITIONS
            "SQLITE_API=__declspec(dllimport)"
    )
elseif(CMAKE_COMPILER_IS_GNUCC)
    set_property(TARGET ${LIB_NAME} APPEND PROPERTY
        INTERFACE_COMPILE_DEFINITIONS
            "SQLITE_API=__attribute__((dllimport))"
    )
endif()

set(TARGETS ${LIB_NAME})

option(BUILD_APPS "Build sqlite3 command line utility" ON)
if(BUILD_APPS)
    # Build sqlite executable for tests.
    add_executable(sqlite_app shell.c ${AMALGAM_HEADER})
    target_link_libraries(sqlite_app ${LIB_NAME})
    if(OSX_FRAMEWORK)
        set_target_properties(sqlite_app PROPERTIES INSTALL_RPATH "@executable_path/../../Library/Frameworks")
    endif()
    set_target_properties(sqlite_app PROPERTIES OUTPUT_NAME ${PROJECT_NAME})

    set(TARGETS ${TARGETS} sqlite_app)
endif()

# Testing ======================================================================
option(BUILD_TESTING "Build the testing tree." OFF)
if(BUILD_TESTING)
    include(CTest)
    add_test(sqlite_app ${PROJECT_NAME} -version)
endif()

# Installing and packaging =====================================================

include(${CMAKE_CURRENT_LIST_DIR}/cmake/borsch/cmake/packaging.cmake)
create_borsch_package(${PACKAGE_NAME} 
    VENDOR ${PACKAGE_VENDOR}
    VERSION ${VERSION}
    TARGETS ${LIB_NAME}
    HEADERS ${AMALGAM_HEADER}
)
