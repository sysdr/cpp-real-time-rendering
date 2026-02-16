#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
BUILD_DIR="$SCRIPT_DIR/build"
VCPKG_ROOT="$SCRIPT_DIR/.vcpkg-root"
DEPS_DIR="$SCRIPT_DIR/deps"
METRICS_JSON="$SCRIPT_DIR/metrics.json"
DASHBOARD_PORT="${DASHBOARD_PORT:-8765}"
PID_FILE="$SCRIPT_DIR/.dashboard.pid"
APP_EXIT=1

# Ensure metrics file exists
init_metrics() {
    if [ ! -f "$METRICS_JSON" ]; then
        echo '{"run_count":0,"last_run_ts":"","last_run_status":"","app_runs":0,"demo_executions":0}' > "$METRICS_JSON"
    fi
}

# Build if needed: try vcpkg+cmake, then cmake+FetchContent, then g++ fallback (no cmake required)
if [ ! -f "$BUILD_DIR/app" ]; then
    echo "[start.sh] Building project..."
    mkdir -p "$BUILD_DIR"
    BUILT=false

    # 1) Try cmake with vcpkg if available
    if [ -f "$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" ] && command -v cmake >/dev/null 2>&1; then
        if cmake -B "$BUILD_DIR" -S "$SCRIPT_DIR" -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" && \
           cmake --build "$BUILD_DIR" -j$(nproc 2>/dev/null || echo 2); then
            BUILT=true
        fi
    fi

    # 2) Try cmake without vcpkg (FetchContent for spdlog)
    if [ "$BUILT" = false ] && command -v cmake >/dev/null 2>&1; then
        rm -rf "$BUILD_DIR/CMakeCache.txt" "$BUILD_DIR/CMakeFiles" 2>/dev/null
        if cmake -B "$BUILD_DIR" -S "$SCRIPT_DIR" && \
           cmake --build "$BUILD_DIR" -j$(nproc 2>/dev/null || echo 2); then
            BUILT=true
        fi
    fi

    # 3) g++ fallback when cmake not installed: use header-only spdlog
    if [ "$BUILT" = false ] && command -v g++ >/dev/null 2>&1; then
        echo "[start.sh] cmake not available; trying g++ fallback with spdlog..."
        if [ ! -d "$DEPS_DIR/spdlog/include" ]; then
            mkdir -p "$DEPS_DIR"
            if command -v git >/dev/null 2>&1; then
                git clone --depth 1 https://github.com/gabime/spdlog.git "$DEPS_DIR/spdlog" 2>/dev/null || true
            fi
        fi
        if [ -d "$DEPS_DIR/spdlog/include" ]; then
            if g++ -I"$DEPS_DIR/spdlog/include" -DSPDLOG_HEADER_ONLY -std=c++17 -pthread -o "$BUILD_DIR/app" src/main.cpp 2>/dev/null; then
                BUILT=true
                echo "[start.sh] Build succeeded (g++ fallback)."
            fi
        fi
    fi

    if [ "$BUILT" = true ]; then
        echo "[start.sh] Build succeeded."
    else
        echo "[start.sh] Build failed. Install cmake (or ensure g++ and git for fallback), then run ./start.sh again."
    fi
fi

# Run app (demo) if built
if [ -f "$BUILD_DIR/app" ]; then
    echo "[start.sh] Running application (demo)..."
    if "$BUILD_DIR/app"; then
        APP_EXIT=0
    else
        APP_EXIT=$?
    fi
else
    echo "[start.sh] App not built; skipping demo run."
fi

# Update metrics so dashboard values are not zero after execution
init_metrics
TS="$(date -Iseconds 2>/dev/null || date)"
if [ $APP_EXIT -eq 0 ]; then STATUS="ok"; else STATUS="error"; fi
[ ! -f "$BUILD_DIR/app" ] && STATUS="no_build"
RUN_COUNT=$(python3 -c "
import json
try: d=json.load(open('$METRICS_JSON'))
except: d={'run_count':0,'app_runs':0,'demo_executions':0}
d['run_count']=d.get('run_count',0)+1
d['last_run_ts']='$TS'
d['last_run_status']='$STATUS'
d['app_runs']=d.get('app_runs',0)+(1 if $APP_EXIT==0 else 0)
d['demo_executions']=d.get('demo_executions',0)+1
print(json.dumps(d))
" 2>/dev/null)
if [ -n "$RUN_COUNT" ]; then
    echo "$RUN_COUNT" > "$METRICS_JSON"
else
    echo "{\"run_count\":1,\"last_run_ts\":\"$TS\",\"last_run_status\":\"$STATUS\",\"app_runs\":1,\"demo_executions\":1}" > "$METRICS_JSON"
fi

# Start dashboard server if not already running (avoid duplicate services)
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "[start.sh] Dashboard already running at http://localhost:$DASHBOARD_PORT"
else
    rm -f "$PID_FILE"
    export DASHBOARD_PORT DASHBOARD_BIND=127.0.0.1
    python3 "$SCRIPT_DIR/server.py" >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    echo "[start.sh] Dashboard at http://localhost:$DASHBOARD_PORT"
fi
echo "[start.sh] Done. Open http://localhost:$DASHBOARD_PORT/dashboard.html for metrics."
