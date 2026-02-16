FROM ubuntu:22.04

# Install build essentials and GLFW, GLEW
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    cmake \
    libglfw3-dev \
    libglew-dev \
    libgl-dev \
    xorg-dev \
    mesa-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy source code and CMakeLists.txt
COPY CMakeLists.txt .
COPY src/ ./src/

# Configure and Build
RUN cmake -B build && cmake --build build

# Command to run the application (will be run interactively for GUI)
CMD ["./build/EngineProto"]
