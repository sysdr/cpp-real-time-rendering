#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
PROJECT_NAME="rendering_engine_day7"
BUILD_DIR="build"
PID_FILE=".rendering_engine_day7.pid"

# Check for and stop duplicate service
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "[INFO] Stopping existing instance (PID $OLD_PID)..."
        kill "$OLD_PID" 2>/dev/null
        sleep 1
    fi
    rm -f "$PID_FILE"
fi
RUNNING=$(pgrep -f "$(pwd)/$BUILD_DIR/$PROJECT_NAME" 2>/dev/null || true)
if [ -n "$RUNNING" ]; then
    echo "[WARN] Another instance may be running (PIDs: $RUNNING). Stopping..."
    echo "$RUNNING" | xargs -r kill 2>/dev/null
    sleep 1
fi

# Build if executable missing
if [ ! -f "$BUILD_DIR/$PROJECT_NAME" ]; then
    echo "[INFO] Building project..."
    mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR" && cmake .. && make -j$(nproc 2>/dev/null || echo 2) && cd .. || exit 1
fi

EXEC="$(pwd)/$BUILD_DIR/$PROJECT_NAME"
if [ ! -f "$EXEC" ]; then
    echo "[ERROR] Executable not found: $EXEC"
    exit 1
fi
echo "[INFO] Starting rendering application..."
"$EXEC" &
echo $! > "$PID_FILE"
PID=$(cat "$PID_FILE")
echo "----------------------------------------------"
echo "  Dashboard: Application started"
echo "  PID: $PID  |  Executable: $EXEC"
echo "  Use stop.sh to stop."
echo "----------------------------------------------"
