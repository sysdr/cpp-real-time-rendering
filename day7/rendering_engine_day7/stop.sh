#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
PROJECT_NAME="rendering_engine_day7"
PID_FILE=".rendering_engine_day7.pid"

if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null
        echo "[INFO] Stopped process $PID"
    fi
    rm -f "$PID_FILE"
fi
# Also kill by name in case PID file was missing
pkill -f "$SCRIPT_DIR/build/$PROJECT_NAME" 2>/dev/null && echo "[INFO] Stopped running instance(s)." || true
