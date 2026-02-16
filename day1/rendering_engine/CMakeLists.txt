cmake_minimum_required(VERSION 3.15)
project(RenderingEngine CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/.vcpkg-root/scripts/buildsystems/vcpkg.cmake")
    message(STATUS "Using vcpkg toolchain file from project root.")
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_CURRENT_SOURCE_DIR}/.vcpkg-root/scripts/buildsystems/vcpkg.cmake" CACHE STRING "Vcpkg toolchain file")
endif()

# Prefer vcpkg spdlog; otherwise use FetchContent (no vcpkg/zip required)
find_package(spdlog CONFIG QUIET)
if(NOT spdlog_FOUND)
    message(STATUS "spdlog not found via vcpkg; using FetchContent.")
    include(FetchContent)
    FetchContent_Declare(spdlog
        GIT_REPOSITORY https://github.com/gabime/spdlog
        GIT_TAG v1.13.0
    )
    FetchContent_MakeAvailable(spdlog)
endif()

add_executable(app src/main.cpp)
target_link_libraries(app PRIVATE spdlog::spdlog)
