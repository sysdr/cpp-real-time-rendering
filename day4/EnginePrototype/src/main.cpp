#include "logger.hpp"
#include <vector>
#include <numeric>
#include <random>
#include <chrono>

void workerFunction(int id) {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<> distrib(100, 500);
    Logger& logger = Logger::getInstance();
    for (int i = 0; i < 5; ++i) {
        LogLevel level = static_cast<LogLevel>(id % 5);
        std::string msg = "Worker " + std::to_string(id) + " logging message " + std::to_string(i);
        logger.log(level, msg);
        std::this_thread::sleep_for(std::chrono::milliseconds(distrib(gen)));
    }
    logger.log(LogLevel::INFO, "Worker " + std::to_string(id) + " finished.");
}

int main() {
    Logger& logger = Logger::getInstance();
    logger.init("logs/engine.log");
    logger.log(LogLevel::INFO, "Main thread: Starting engine initialization.");
    const int numWorkers = 5;
    std::vector<std::thread> workers;
    for (int i = 0; i < numWorkers; ++i) workers.emplace_back(workerFunction, i + 1);
    logger.log(LogLevel::INFO, "Main thread: All worker threads launched.");
    for (int i = 0; i < 3; ++i) {
        logger.log(LogLevel::DEBUG, "Main thread: Performing some background task " + std::to_string(i));
        std::this_thread::sleep_for(std::chrono::milliseconds(150));
    }
    for (std::thread& worker : workers) { if (worker.joinable()) worker.join(); }
    logger.log(LogLevel::INFO, "Main thread: All worker threads joined. Shutting down logger.");
    logger.shutdown();
    std::cout << "\n--- Demo Complete ---" << std::endl;
    std::cout << "Check console output and 'logs/engine.log' for verification." << std::endl;
    return 0;
}
