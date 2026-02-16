#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
BUILD_DIR="$SCRIPT_DIR/build"
METRICS_JSON="$SCRIPT_DIR/metrics.json"
DASHBOARD_PORT="${DASHBOARD_PORT:-8766}"
PID_FILE="$SCRIPT_DIR/.dashboard.pid"
APP_EXIT=1

init_metrics() {
    if [ ! -f "$METRICS_JSON" ]; then
        echo '{"run_count":0,"last_run_ts":"","last_run_status":"","app_runs":0,"demo_executions":0}' > "$METRICS_JSON"
    fi
}

# Build if needed
if [ ! -f "$BUILD_DIR/EngineProto" ]; then
    echo "[start.sh] Building project..."
    mkdir -p "$BUILD_DIR"
    BUILT=false
    if command -v cmake >/dev/null 2>&1; then
        if (cd "$BUILD_DIR" && cmake .. && cmake --build .); then
            BUILT=true
        fi
    fi
    [ "$BUILT" = true ] && echo "[start.sh] Build succeeded." || echo "[start.sh] Build failed. Install cmake, libglfw3-dev, libglew-dev, then run ./start.sh again."
fi

# Run app (demo) if built - user closes window to continue
if [ -f "$BUILD_DIR/EngineProto" ]; then
    echo "[start.sh] Running application (demo)... Close the window or press ESC to continue."
    if "$BUILD_DIR/EngineProto"; then
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
[ $APP_EXIT -eq 0 ] && STATUS="ok" || STATUS="error"
[ ! -f "$BUILD_DIR/EngineProto" ] && STATUS="no_build"
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
