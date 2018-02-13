################################################################################
# Project:  CMake4GDAL
# Purpose:  CMake build scripts
# Author:   Mikhail Gusev, gusevmihs@gmail.com
################################################################################
# Copyright (C) 2016-2018, NextGIS <info@nextgis.com>
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

function(set_version major minor release filename)
    file(READ ${filename} FILE_CONTENTS)
    string(REGEX MATCH "SQLITE_VERSION_NUMBER[ \t]+([0-9]+)"
      VERSION_NUMBER ${FILE_CONTENTS})
    string(REGEX MATCH "([0-9]+)"
      VERSION_NUMBER ${VERSION_NUMBER})
    math(EXPR VERSION_MAJOR "${VERSION_NUMBER} / 1000000")
    math(EXPR VERSION_MINOR "(${VERSION_NUMBER} - ${VERSION_MAJOR} * 1000000) / 1000")
    math(EXPR VERSION_RELEASE "(${VERSION_NUMBER} - ${VERSION_MAJOR} * 1000000 - ${VERSION_MINOR} * 1000)")
    set(${major} ${VERSION_MAJOR} PARENT_SCOPE)
    set(${minor} ${VERSION_MINOR} PARENT_SCOPE)
    set(${release} ${VERSION_RELEASE} PARENT_SCOPE)

    # Store version string in file for installer needs
    file(TIMESTAMP ${CMAKE_SOURCE_DIR}/sqlite3.h VERSION_DATETIME "%Y-%m-%d %H:%M:%S" UTC)
    set(VERSION ${VERSION_MAJOR}.${VERSION_MINOR}.${VERSION_RELEASE})
    get_cpack_filename(${VERSION} PROJECT_CPACK_FILENAME)
    file(WRITE ${CMAKE_BINARY_DIR}/version.str "${VERSION}\n${VERSION_DATETIME}\n${PROJECT_CPACK_FILENAME}")

endfunction()

function(report_version name ver)
    string(ASCII 27 Esc)
    set(BoldYellow  "${Esc}[1;33m")
    set(ColourReset "${Esc}[m")
    message(STATUS "${BoldYellow}${name} version ${ver}${ColourReset}")
endfunction()


function(get_cpack_filename ver name)
    get_compiler_version(COMPILER)
    if(BUILD_STATIC_LIBS)
        set(STATIC_PREFIX "static-")
    endif()

    if(BUILD_SHARED_LIBS OR OSX_FRAMEWORK)
        set(${name} ${PROJECT_NAME}-${STATIC_PREFIX}${ver}-${COMPILER} PARENT_SCOPE)
    else()
        set(${name} ${PROJECT_NAME}-${STATIC_PREFIX}${ver}-STATIC-${COMPILER} PARENT_SCOPE)
    endif()
endfunction()

function(get_compiler_version ver)
    ## Limit compiler version to 2 or 1 digits
    string(REPLACE "." ";" VERSION_LIST ${CMAKE_C_COMPILER_VERSION})
    list(LENGTH VERSION_LIST VERSION_LIST_LEN)
    if(VERSION_LIST_LEN GREATER 2 OR VERSION_LIST_LEN EQUAL 2)
        list(GET VERSION_LIST 0 COMPILER_VERSION_MAJOR)
        list(GET VERSION_LIST 1 COMPILER_VERSION_MINOR)
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${COMPILER_VERSION_MAJOR}.${COMPILER_VERSION_MINOR})
    else()
        set(COMPILER ${CMAKE_C_COMPILER_ID}-${CMAKE_C_COMPILER_VERSION})
    endif()

    if(WIN32)
        if(CMAKE_CL_64)
            set(COMPILER "${COMPILER}-64bit")
        endif()
    endif()

    set(${ver} ${COMPILER} PARENT_SCOPE)
endfunction()
