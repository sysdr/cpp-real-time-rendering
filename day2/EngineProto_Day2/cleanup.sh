#!/bin/bash
# Stop project and Docker services; remove unused Docker resources and project artifacts.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "[cleanup.sh] Stopping project services..."
PID_FILE="$SCRIPT_DIR/.dashboard.pid"
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE" 2>/dev/null)
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null
        echo "[cleanup.sh] Dashboard server stopped (PID $PID)."
    fi
    rm -f "$PID_FILE"
fi
pkill -f "$SCRIPT_DIR/build/EngineProto" 2>/dev/null || true

echo "[cleanup.sh] Stopping Docker containers..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker compose down 2>/dev/null || true

echo "[cleanup.sh] Removing unused Docker resources (containers, images, volumes, networks)..."
docker container prune -f 2>/dev/null || true
docker image prune -af 2>/dev/null || true
docker volume prune -f 2>/dev/null || true
docker network prune -f 2>/dev/null || true
docker system prune -af --volumes 2>/dev/null || true

echo "[cleanup.sh] Removing project artifacts (node_modules, venv, .pytest_cache, .pyc, istio, vendor, .rr)..."
for d in node_modules venv .venv .pytest_cache istio vendor; do
    if [ -d "$SCRIPT_DIR/$d" ]; then
        rm -rf "$SCRIPT_DIR/$d"
        echo "[cleanup.sh] Removed $SCRIPT_DIR/$d"
    fi
done
find "$SCRIPT_DIR" -maxdepth 4 -name "*.pyc" -delete 2>/dev/null || true
find "$SCRIPT_DIR" -maxdepth 4 -name "*.rr" -delete 2>/dev/null || true

echo "[cleanup.sh] Done."
