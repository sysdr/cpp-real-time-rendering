#include <iostream>
#include <spdlog/spdlog.h>

int main() {
    spdlog::info("Welcome to the Rendering Engine! Day 1 Environment Setup Complete.");
    spdlog::warn("This is a warning message using spdlog.");
    spdlog::error("An error might occur in future lessons, but not today!");
    std::cout << "Standard C++ output also works." << std::endl;
    return 0;
}
