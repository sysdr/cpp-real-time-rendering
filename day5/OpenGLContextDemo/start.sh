#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
BIN_DIR="$SCRIPT_DIR/bin"
BUILD_DIR="$SCRIPT_DIR/build"
APP_EXE="$BIN_DIR/OpenGLContextDemo"
METRICS_JSON="$SCRIPT_DIR/metrics.json"
DASHBOARD_PORT="${DASHBOARD_PORT:-8769}"
PID_FILE="$SCRIPT_DIR/.dashboard.pid"
APP_EXIT=1

init_metrics() {
    if [ ! -f "$METRICS_JSON" ]; then
        echo '{"run_count":0,"last_run_ts":"","last_run_status":"","app_runs":0,"demo_executions":0}' > "$METRICS_JSON"
    fi
}
init_metrics

# Build if needed (vcpkg + cmake)
if [ ! -f "$APP_EXE" ]; then
    echo "[start.sh] Building project..."
    VCPKG_ROOT="${VCPKG_ROOT:-}"
    if [ -z "$VCPKG_ROOT" ]; then
        if command -v vcpkg &>/dev/null; then
            VCPKG_ROOT=$(vcpkg --print-vcpkg-root)
        elif [ -x "$SCRIPT_DIR/../vcpkg/vcpkg" ]; then
            VCPKG_ROOT="$SCRIPT_DIR/../vcpkg"
        elif [ -x "$SCRIPT_DIR/vcpkg/vcpkg" ]; then
            VCPKG_ROOT="$SCRIPT_DIR/vcpkg"
        fi
    fi
    if [ -z "$VCPKG_ROOT" ] || [ ! -x "$VCPKG_ROOT/vcpkg" ]; then
        VCPKG_DIR="$SCRIPT_DIR/../vcpkg"
        if [ ! -x "$VCPKG_DIR/vcpkg" ] && command -v git >/dev/null 2>&1; then
            echo "[start.sh] vcpkg not found. Installing vcpkg into $VCPKG_DIR..."
            if [ ! -d "$VCPKG_DIR" ]; then
                git clone https://github.com/microsoft/vcpkg.git "$VCPKG_DIR" 2>/dev/null || { echo "[start.sh] git clone failed. Install: sudo apt-get install -y curl zip unzip tar git"; exit 1; }
            fi
            if [ -f "$VCPKG_DIR/bootstrap-vcpkg.sh" ]; then
                (cd "$VCPKG_DIR" && ./bootstrap-vcpkg.sh) 2>/dev/null || { echo "[start.sh] Bootstrap failed. Install: sudo apt-get install -y curl zip unzip tar"; exit 1; }
            fi
            if [ -x "$VCPKG_DIR/vcpkg" ]; then
                VCPKG_ROOT="$VCPKG_DIR"
                export VCPKG_ROOT
                echo "[start.sh] Installing glfw3 and glad..."
                "$VCPKG_ROOT/vcpkg" install glfw3 glad --triplet x64-linux 2>/dev/null || { echo "[start.sh] vcpkg install failed. You may need: sudo apt-get install -y libxinerama-dev libxcursor-dev xorg-dev libglu1-mesa-dev pkg-config"; exit 1; }
            fi
        fi
        if [ -z "$VCPKG_ROOT" ] || [ ! -x "$VCPKG_ROOT/vcpkg" ]; then
            echo "[start.sh] vcpkg not found. To resolve:"
            echo "  1. Install deps: sudo apt-get install -y curl zip unzip tar git"
            echo "  2. Run ./start.sh again (it will install vcpkg into ../vcpkg)"
            echo "  Or install manually: see IMPLEMENTATION_GUIDE.md"
            echo "  Or set VCPKG_ROOT to your vcpkg install directory."
        fi
    fi
    if [ -n "$VCPKG_ROOT" ] && [ -x "$VCPKG_ROOT/vcpkg" ]; then
        export VCPKG_ROOT
        VCPKG_TC="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
        if cmake -S . -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE="$VCPKG_TC" && cmake --build "$BUILD_DIR" -j "$(nproc 2>/dev/null || echo 2)"; then
            echo "[start.sh] Build succeeded."
        else
            echo "[start.sh] Build failed. Install vcpkg, glfw3, glad (vcpkg install glfw3 glad --triplet x64-linux), then run ./start.sh again."
        fi
    fi
fi

# Run demo if built
# When DISPLAY is unset (e.g. run from dashboard/headless), use xvfb so GLFW can create a window
if [ -f "$APP_EXE" ]; then
    echo "[start.sh] Running OpenGL Context demo..."
    if [ -z "${DISPLAY:-}" ]; then
        if command -v xvfb-run >/dev/null 2>&1; then
            echo "[start.sh] No display; using virtual display (xvfb). Demo runs 5s then exits."
            xvfb-run -a --server-args="-screen 0 800x600x24" timeout 5 "$APP_EXE"
            EXIT=$?
            [ "$EXIT" = 0 ] || [ "$EXIT" = 124 ] && APP_EXIT=0 || APP_EXIT=$EXIT
        else
            echo "[start.sh] DISPLAY not set. Install xvfb for headless/dashboard: sudo apt install xvfb"
            if "$APP_EXE"; then APP_EXIT=0; else APP_EXIT=$?; fi
        fi
    else
        echo "[start.sh] Close the demo window to continue."
        if "$APP_EXE"; then APP_EXIT=0; else APP_EXIT=$?; fi
    fi
else
    echo "[start.sh] App not built; skipping demo run."
fi

# Update metrics so dashboard values are not zero after execution
TS="$(date -Iseconds 2>/dev/null || date)"
[ $APP_EXIT -eq 0 ] && STATUS="ok" || STATUS="error"
[ ! -f "$APP_EXE" ] && STATUS="no_build"
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
