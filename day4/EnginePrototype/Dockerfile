FROM gcc:11.2.0
WORKDIR /app
COPY src/ /app/src/
RUN g++ src/main.cpp src/logger.cpp -o /app/bin/engine_prototype -std=c++17 -pthread -Wall -Wextra -pedantic
RUN mkdir -p /app/logs
CMD ["/app/bin/engine_prototype"]
