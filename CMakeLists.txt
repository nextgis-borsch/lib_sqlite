
# Modified by Mikhail Gusev, gusevmihs@gmail.com

cmake_minimum_required(VERSION 2.8.12 FATAL_ERROR)

project(sqlite3 C)

# some init settings
set(CMAKE_COLOR_MAKEFILE ON)
# set path to additional CMake modules
set(CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake ${CMAKE_MODULE_PATH})

if(OSX_FRAMEWORK AND (BUILD_SHARED_LIBS OR BUILD_STATIC_LIBS))
  message(FATAL_ERROR "Only OSX_FRAMEWORK key or any or both BUILD_SHARED_LIBS
                       and BUILD_STATIC_LIBS keys are permitted")
endif()

if(OSX_FRAMEWORK)
  set(INSTALL_BIN_DIR "${CMAKE_INSTALL_PREFIX}/Applications" CACHE INTERNAL "Installation directory for executables" FORCE)
  set(INSTALL_LIB_DIR "${CMAKE_INSTALL_PREFIX}/Library/Frameworks" CACHE INTERNAL "Installation directory for libraries" FORCE)
  set(INSTALL_INC_DIR "${INSTALL_LIB_DIR}/${PROJECT_NAME}.framework/Headers" CACHE INTERNAL "Installation directory for headers" FORCE)
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
endif()

set(AMALGAM_HEADER sqlite3.h)
set(AMALGAM_SOURCE sqlite3.c)

include(util)
set_version(VER_H_MAJOR VER_H_MINOR VER_H_RELEASE ${AMALGAM_HEADER})
set_version(VER_C_MAJOR VER_C_MINOR VER_C_RELEASE ${AMALGAM_SOURCE})
set(SQLITE_HEADER_VERSION "${VER_H_MAJOR}.${VER_H_MINOR}.${VER_H_RELEASE}")
set(SQLITE_SOURCE_VERSION "${VER_C_MAJOR}.${VER_C_MINOR}.${VER_C_RELEASE}")
string(COMPARE NOTEQUAL ${SQLITE_HEADER_VERSION} ${SQLITE_SOURCE_VERSION} NOTEQUAL_VERSIONS)
if(NOTEQUAL_VERSIONS)
    # do this because source and header files have their versions defined twice
    message(FATAL_ERROR "Source and header files have different versions!")
endif()

set(VERSION ${SQLITE_HEADER_VERSION})
report_version(${PROJECT_NAME} ${VERSION})

if(OSX_FRAMEWORK)
    set(FRAMEWORK_VERSION "${VER_H_MAJOR}")
endif()

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
option(ENABLE_COLUMN_METADATA "This enables some extra APIs that are required by some common systems, including Ruby-on-Rails" ON)
if(ENABLE_COLUMN_METADATA)
    add_definitions(-DSQLITE_ENABLE_COLUMN_METADATA)
endif()
option(ENABLE_JSON1 "Include JSON SQL functions" ON)
if(ENABLE_JSON1)
    add_definitions(-DSQLITE_ENABLE_JSON1)
endif()

configure_file(${CMAKE_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in ${CMAKE_BINARY_DIR}/cmake_uninstall.cmake IMMEDIATE @ONLY)

# TODO: what else to add from options, especially for GDAL library?
# https://www.sqlite.org/compile.html

find_package(Threads)
if (Threads_FOUND)
    if (CMAKE_USE_PTHREADS_INIT)
        add_definitions(-D_REENTRANT=1 -DTHREADSAFE=1)
        set(EXTRA_LIBS ${CMAKE_THREAD_LIBS_INIT})
    endif()
else()
    message(STATUS "threads package not found")
endif()
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

set(LIB_NAME ${PROJECT_NAME})
if(BUILD_SHARED_LIBS)
    add_library(${LIB_NAME} SHARED ${AMALGAM_SOURCE})
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

set_target_properties(${LIB_NAME} PROPERTIES
    VERSION ${VERSION}
    SOVERSION ${VER_H_MAJOR})

if(CMAKE_USE_PTHREADS_INIT)
  target_link_libraries(${LIB_NAME} ${EXTRA_LIBS})
endif()

# TODO: do we need set_target_properties() with version here?

# TODO: build sqlite executable for tests.

# Install
if(NOT SKIP_INSTALL_LIBRARIES AND NOT SKIP_INSTALL_ALL )
    install(TARGETS ${LIB_NAME}
        #EXPORT targets
        RUNTIME DESTINATION ${INSTALL_BIN_DIR} # at least for dlls
        ARCHIVE DESTINATION ${INSTALL_LIB_DIR}
        LIBRARY DESTINATION ${INSTALL_LIB_DIR}
        FRAMEWORK DESTINATION ${INSTALL_LIB_DIR})
endif()

if(NOT SKIP_INSTALL_HEADERS AND NOT SKIP_INSTALL_ALL)
    install(FILES ${AMALGAM_HEADER} DESTINATION ${INSTALL_INC_DIR})
endif()

# Other
export(TARGETS ${LIB_NAME} FILE ${LIB_NAME}-exports.cmake)

if (REGISTER_PACKAGE)

    set(EXPORT_PACKAGE_NAME SQLite3)
    set(EXPORT_PACKAGE_NAME_UPPER SQLITE3)
    set(EXPORT_PACKAGE_LIB_NAME ${LIB_NAME})

    export(PACKAGE ${EXPORT_PACKAGE_NAME})

    include(CMakePackageConfigHelpers)
    configure_package_config_file(
        ${CMAKE_SOURCE_DIR}/cmake/PackageConfig.cmake.in
        ${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_PACKAGE_NAME}Config.cmake
        INSTALL_DESTINATION ${INSTALL_LIB_DIR}/cmake
        PATH_VARS INSTALL_INC_DIR )
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${EXPORT_PACKAGE_NAME}ConfigVersion.cmake
        VERSION ${VERSION}
        COMPATIBILITY AnyNewerVersion )
endif()

# Uninstall
add_custom_target(uninstall COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
