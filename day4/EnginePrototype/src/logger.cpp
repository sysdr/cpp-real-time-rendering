#include "logger.hpp"
#include <sstream>

Logger& Logger::getInstance() {
    static Logger instance;
    return instance;
}

Logger::Logger() : m_running(false) {}

Logger::~Logger() {
    if (m_running) shutdown();
}

void Logger::init(const std::string& filename) {
    if (m_running) { std::cerr << "Logger already initialized." << std::endl; return; }
    m_logFile.open(filename, std::ios::app);
    if (!m_logFile.is_open()) { std::cerr << "Failed to open log file: " << filename << std::endl; return; }
    m_running = true;
    m_logThread = std::thread(&Logger::processLogMessages, this);
    std::cout << "[INFO] Logger initialized to file: " << filename << std::endl;
}

void Logger::log(LogLevel level, const std::string& message) {
    if (!m_running) { std::cerr << "[ERROR] Attempted to log before Logger was initialized or after shutdown: " << message << std::endl; return; }
    LogMessage msg;
    msg.level = level;
    msg.message = message;
    msg.timestamp = std::chrono::system_clock::now();
    { std::lock_guard<std::mutex> lock(m_mutex); m_messages.push(msg); }
    m_cv.notify_one();
}

void Logger::shutdown() {
    if (!m_running) { std::cout << "[INFO] Logger already shut down or not initialized." << std::endl; return; }
    m_running = false;
    m_cv.notify_all();
    if (m_logThread.joinable()) m_logThread.join();
    if (m_logFile.is_open()) m_logFile.close();
    std::cout << "[INFO] Logger shut down." << std::endl;
}

void Logger::processLogMessages() {
    while (m_running || !m_messages.empty()) {
        std::unique_lock<std::mutex> lock(m_mutex);
        m_cv.wait(lock, [this]{ return !m_messages.empty() || !m_running; });
        if (!m_running && m_messages.empty()) break;
        while (!m_messages.empty()) {
            LogMessage msg = m_messages.front();
            m_messages.pop();
            lock.unlock();
            std::time_t time = std::chrono::system_clock::to_time_t(msg.timestamp);
            std::stringstream ss;
            ss << std::put_time(std::localtime(&time), "%Y-%m-%d %H:%M:%S") << " [" << logLevelToString(msg.level) << "] " << msg.message;
            std::string formattedMessage = ss.str();
            std::cout << formattedMessage << std::endl;
            m_logFile << formattedMessage << std::endl;
            m_logFile.flush();
            lock.lock();
        }
    }
}

std::string Logger::logLevelToString(LogLevel level) {
    switch (level) {
        case LogLevel::DEBUG: return "DEBUG";
        case LogLevel::INFO:  return "INFO";
        case LogLevel::WARN:  return "WARN";
        case LogLevel::ERROR: return "ERROR";
        case LogLevel::FATAL: return "FATAL";
        default:              return "UNKNOWN";
    }
}
