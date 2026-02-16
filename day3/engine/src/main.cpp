#include <iostream>
#include <chrono>
#include <thread>
#include <iomanip>

void run_high_precision_loop() {
    using namespace std::chrono;

    constexpr nanoseconds fixed_timestep{16ms};
    nanoseconds accumulator{0ns};
    auto current_time = high_resolution_clock::now();
    double game_logic_position = 0.0;
    double previous_game_logic_position = 0.0;
    auto start_loop_time = current_time;
    constexpr nanoseconds demo_duration{5s};

    long long frame_count = 0;
    long long update_count = 0;
    auto last_report_time = current_time;
    bool is_paused = false;
    int pause_trigger_updates = 100;
    int resume_trigger_updates = 150;
    int current_total_updates = 0;

    std::cout << "----------------------------------------------------------------------------------" << std::endl;
    std::cout << "High-Precision Game Loop: Fixed Update (16ms) and Variable Render with Interpolation" << std::endl;
    std::cout << "----------------------------------------------------------------------------------" << std::endl;

    while (current_time - start_loop_time < demo_duration) {
        auto new_time = high_resolution_clock::now();
        auto frame_time = new_time - current_time;
        current_time = new_time;
        if (frame_time > 250ms) frame_time = 250ms;
        accumulator += frame_time;
        previous_game_logic_position = game_logic_position;

        if (current_total_updates >= pause_trigger_updates && current_total_updates < resume_trigger_updates && !is_paused) {
            is_paused = true;
            std::cout << "\n[PAUSE] Game logic paused at " << current_total_updates << " updates. Rendering continues.\n" << std::endl;
        } else if (current_total_updates >= resume_trigger_updates && is_paused) {
            is_paused = false;
            std::cout << "\n[RESUME] Game logic resumed at " << current_total_updates << " updates.\n" << std::endl;
        }

        if (!is_paused) {
            while (accumulator >= fixed_timestep) {
                game_logic_position += 0.1;
                accumulator -= fixed_timestep;
                update_count++;
                current_total_updates++;
            }
        }
        if (update_count == 0) previous_game_logic_position = game_logic_position;

        double alpha = static_cast<double>(accumulator.count()) / fixed_timestep.count();
        double render_position = previous_game_logic_position + (game_logic_position - previous_game_logic_position) * alpha;
        (void)render_position;
        frame_count++;

        if (current_time - last_report_time >= 1s) {
            std::cout << "----------------------------------------------------------------------------------" << std::endl;
            std::cout << "[METRICS] FPS: " << frame_count << ", UPS: " << update_count
                      << " (Total Updates: " << current_total_updates << ", State: " << (is_paused ? "PAUSED" : "RUNNING") << ")" << std::endl;
            std::cout << "----------------------------------------------------------------------------------" << std::endl;
            frame_count = 0;
            update_count = 0;
            last_report_time = current_time;
        }
        std::this_thread::sleep_for(1ms);
    }
}

int main() {
    std::cout << "Initializing Engine..." << std::endl;
    run_high_precision_loop();
    std::cout << "Engine Shutting Down." << std::endl;
    return 0;
}
