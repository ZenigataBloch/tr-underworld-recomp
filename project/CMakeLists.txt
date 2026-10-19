# tru - ReXGlue Recompiled Project
#
# SDK boilerplate lives in generated/rexglue.cmake.

cmake_minimum_required(VERSION 3.25)
project(tru LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(generated/rexglue.cmake)

# Sources
set(TRU_SOURCES
    src/main.cpp
)

if(WIN32)
    add_executable(tru WIN32 ${TRU_SOURCES})
else()
    add_executable(tru ${TRU_SOURCES})
endif()

rexglue_setup_target(tru GPU_PLUGINS xenos)
