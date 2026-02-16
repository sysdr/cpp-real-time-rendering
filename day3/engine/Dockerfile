FROM gcc:11.4.0
WORKDIR /app
COPY src/ ./src/
RUN apt-get update && apt-get install -y cmake && rm -rf /var/lib/apt/lists/*
RUN mkdir build && cmake -S src -B build && cmake --build build
CMD ["./build/GameLoopApp"]
