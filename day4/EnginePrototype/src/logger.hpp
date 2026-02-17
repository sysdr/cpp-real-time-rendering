#ifndef LOGGER_HPP
#define LOGGER_HPP

#include <string>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <thread>
#include <fstream>
#include <chrono>
#include <iostream>
#include <iomanip>

enum class LogLevel {
    DEBUG,
    INFO,
    WARN,
    ERROR,
    FATAL
};

struct LogMessage {
    LogLevel level;
    std::string message;
    std::chrono::system_clock::time_point timestamp;
};

class Logger {
public:
    static Logger& getInstance();
    Logger(const Logger&) = delete;
    Logger& operator=(const Logger&) = delete;
    Logger(Logger&&) = delete;
    Logger& operator=(Logger&&) = delete;

    void init(const std::string& filename);
    void log(LogLevel level, const std::string& message);
    void shutdown();

private:
    Logger();
    ~Logger();
    void processLogMessages();
    std::string logLevelToString(LogLevel level);

    std::queue<LogMessage> m_messages;
    std::mutex m_mutex;
    std::condition_variable m_cv;
    std::thread m_logThread;
    bool m_running;
    std::ofstream m_logFile;
};

#endif // LOGGER_HPP
