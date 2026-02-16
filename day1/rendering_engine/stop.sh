#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE="$SCRIPT_DIR/.dashboard.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null
        echo "[stop.sh] Dashboard server stopped (PID $PID)."
    fi
    rm -f "$PID_FILE"
fi
# Optional: kill any running app from this project
pkill -f "$SCRIPT_DIR/build/app" 2>/dev/null || true
echo "[stop.sh] Cleanup done."
