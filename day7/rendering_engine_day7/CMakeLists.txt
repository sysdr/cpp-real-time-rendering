cmake_minimum_required(VERSION 3.10)
project(rendering_engine_day7 CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)

# Prefer GLVND for OpenGL (suppress CMP0072 warning)
if(POLICY CMP0072)
  cmake_policy(SET CMP0072 NEW)
  set(OpenGL_GL_PREFERENCE GLVND)
endif()

# Find GLFW
find_package(glfw3 3.3 REQUIRED)
# Find GLEW
find_package(GLEW REQUIRED)
# OpenGL (required on Linux for GL)
find_package(OpenGL REQUIRED)

add_executable(rendering_engine_day7 src/main.cpp)
# Link: glfw (from Findglfw3), GLEW and OpenGL via imported targets
target_link_libraries(rendering_engine_day7 PRIVATE glfw GLEW::GLEW OpenGL::GL)
target_include_directories(rendering_engine_day7 PRIVATE ${GLEW_INCLUDE_DIRS})
