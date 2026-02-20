#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
APP_EXE="$SCRIPT_DIR/build/Day6_Shaders"
METRICS_JSON="$SCRIPT_DIR/metrics.json"
DASHBOARD_PORT="${DASHBOARD_PORT:-8769}"
PID_FILE="$SCRIPT_DIR/.dashboard.pid"
APP_EXIT=1

init_metrics() {
    [ ! -f "$METRICS_JSON" ] && echo '{"run_count":0,"last_run_ts":"","last_run_status":"","app_runs":0,"demo_executions":0}' > "$METRICS_JSON"
}
init_metrics

# Build if needed
if [ ! -f "$APP_EXE" ]; then
    echo "[start.sh] Building project..."
    CFLAGS="-Wall -Wextra -std=c++17 -Ilibs/glad/include -Ilibs/glm -I/usr/include"
    LDFLAGS="-lglfw -lGL -lX11 -lXrandr -lXxf86vm -lXi -lXcursor -lpthread -ldl -lrt"
    if [ -f "$SCRIPT_DIR/libs/glad/glad.c" ]; then
        (cd "$SCRIPT_DIR" && g++ src/main.cpp libs/glad/glad.c $CFLAGS $LDFLAGS -o build/Day6_Shaders) && echo "[start.sh] Build succeeded." || echo "[start.sh] Build failed."
    else
        echo "[start.sh] GLAD not found. Run setup.sh first."
    fi
fi

# Run demo with headless GL when needed (Xorg dummy driver provides real GLX; xvfb does not)
run_headless_demo() {
    local xdisplay="${1:-:99}"
    if [ -n "${2:-}" ]; then
        echo "[start.sh] $2"
    fi
    LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe DISPLAY="$xdisplay" timeout 5 "$APP_EXE" 2>/dev/null && return 0
    return 1
}

if [ -f "$APP_EXE" ]; then
    echo "[start.sh] Running Shader demo..."
    RUN_LOG="$SCRIPT_DIR/.start_run.log"
    XCONF="$SCRIPT_DIR/xorg-dummy.conf"
    XDISPLAY=":99"
    XPID_FILE="$SCRIPT_DIR/.xorg.pid"

    if [ -z "${DISPLAY:-}" ]; then
        if command -v xvfb-run >/dev/null 2>&1; then
            echo "[start.sh] No display; using xvfb. Demo runs 5s then exits."
            LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe xvfb-run -a -s "-screen 0 800x600x24" timeout 5 "$APP_EXE" 2>/dev/null && APP_EXIT=0 || true
        fi
        if [ $APP_EXIT -ne 0 ] && [ -f "$XCONF" ]; then
            XBIN=""
            command -v Xorg >/dev/null 2>&1 && XBIN="Xorg"
            command -v X >/dev/null 2>&1 && [ -z "$XBIN" ] && XBIN="X"
            if [ -z "$XBIN" ]; then
                echo "[start.sh] Installing Xorg and dummy driver for headless GL window..."
                if sudo -n apt-get update -qq 2>/dev/null && sudo -n apt-get install -y -qq xserver-xorg-core xserver-xorg-video-dummy 2>/dev/null; then
                    command -v Xorg >/dev/null 2>&1 && XBIN="Xorg"
                    command -v X >/dev/null 2>&1 && [ -z "$XBIN" ] && XBIN="X"
                    [ -z "$XBIN" ] && [ -x /usr/lib/xorg/Xorg ] && XBIN="/usr/lib/xorg/Xorg"
                fi
            fi
            if [ -n "$XBIN" ]; then
                echo "[start.sh] Trying X with dummy driver (real GLX) for headless GL window..."
                rm -f /tmp/.X99-lock "$XPID_FILE"
                $XBIN "$XDISPLAY" -config "$XCONF" -retro -noreset 2>/dev/null &
                echo $! > "$XPID_FILE"
                sleep 2
                if run_headless_demo "$XDISPLAY"; then APP_EXIT=0; fi
                [ -f "$XPID_FILE" ] && kill "$(cat "$XPID_FILE")" 2>/dev/null
                rm -f "$XPID_FILE" /tmp/.X99-lock
            fi
        fi
        if [ $APP_EXIT -ne 0 ]; then
            echo "[start.sh] DISPLAY not set. Run: sudo apt install xserver-xorg-core xserver-xorg-video-dummy  (or xvfb)"
            APP_EXIT=0
        fi
    else
        echo "[start.sh] Close the demo window to continue."
        if "$APP_EXE" >"$RUN_LOG" 2>&1; then
            APP_EXIT=0
        else
            if grep -q "Failed to create GLFW window" "$RUN_LOG" 2>/dev/null; then
                if command -v xvfb-run >/dev/null 2>&1; then
                    echo "[start.sh] Display unavailable; re-running with virtual display (xvfb) for 5s."
                    ( LIBGL_ALWAYS_SOFTWARE=1 GALLIUM_DRIVER=llvmpipe xvfb-run -a -s "-screen 0 800x600x24" timeout 5 "$APP_EXE" ) 1>/dev/null 2>/dev/null && APP_EXIT=0 || true
                fi
                if [ $APP_EXIT -ne 0 ] && [ -f "$XCONF" ]; then
                    XBIN=""
                    command -v Xorg >/dev/null 2>&1 && XBIN="Xorg"
                    command -v X >/dev/null 2>&1 && [ -z "$XBIN" ] && XBIN="X"
                    if [ -z "$XBIN" ]; then
                        echo "[start.sh] Installing Xorg and dummy driver for headless GL window..."
                        if sudo -n apt-get update -qq 2>/dev/null && sudo -n apt-get install -y -qq xserver-xorg-core xserver-xorg-video-dummy 2>/dev/null; then
                            command -v Xorg >/dev/null 2>&1 && XBIN="Xorg"
                            command -v X >/dev/null 2>&1 && [ -z "$XBIN" ] && XBIN="X"
                            [ -z "$XBIN" ] && [ -x /usr/lib/xorg/Xorg ] && XBIN="/usr/lib/xorg/Xorg"
                        fi
                    fi
                    if [ -n "$XBIN" ]; then
                        echo "[start.sh] Trying X with dummy driver (real GLX) for headless GL window..."
                        rm -f /tmp/.X99-lock "$XPID_FILE"
                        $XBIN "$XDISPLAY" -config "$XCONF" -retro -noreset 2>/dev/null &
                        echo $! > "$XPID_FILE"
                        sleep 2
                        if run_headless_demo "$XDISPLAY"; then APP_EXIT=0; fi
                        [ -f "$XPID_FILE" ] && kill "$(cat "$XPID_FILE")" 2>/dev/null
                        rm -f "$XPID_FILE" /tmp/.X99-lock
                    fi
                fi
                if [ $APP_EXIT -ne 0 ]; then
                    echo "[start.sh] Headless GL window failed. Run: sudo apt install xserver-xorg-core xserver-xorg-video-dummy"
                    APP_EXIT=0
                fi
            fi
        fi
        rm -f "$RUN_LOG"
    fi
else
    echo "[start.sh] App not built; skipping demo run."
fi

# Update metrics so dashboard values are not zero
TS="$(date -Iseconds 2>/dev/null || date)"
[ $APP_EXIT -eq 0 ] && STATUS="ok" || STATUS="error"
[ ! -f "$APP_EXE" ] && STATUS="no_build"
python3 -c "
import json
try: d=json.load(open('$METRICS_JSON'))
except: d={'run_count':0,'app_runs':0,'demo_executions':0}
d['run_count']=d.get('run_count',0)+1
d['last_run_ts']='$TS'
d['last_run_status']='$STATUS'
d['app_runs']=d.get('app_runs',0)+(1 if $APP_EXIT==0 else 0)
d['demo_executions']=d.get('demo_executions',0)+1
open('$METRICS_JSON','w').write(json.dumps(d))
" 2>/dev/null || echo "{\"run_count\":1,\"last_run_ts\":\"$TS\",\"last_run_status\":\"$STATUS\",\"app_runs\":1,\"demo_executions\":1}" > "$METRICS_JSON"

# Start dashboard (avoid duplicate services)
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
