cmake_minimum_required(VERSION 3.10)
project(EngineProto_Day2 CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find GLFW, GLEW, OpenGL
find_package(glfw3 CONFIG REQUIRED)
find_package(GLEW REQUIRED)
find_package(OpenGL REQUIRED)

# Add our executable
add_executable(EngineProto src/main.cpp)

# Link GLFW, GLEW, OpenGL (GLEW is libGLEW.so on Ubuntu/Debian)
target_link_libraries(EngineProto PRIVATE glfw GLEW OpenGL::GL)
