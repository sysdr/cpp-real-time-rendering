#!/bin/bash
# Stop project and Docker services; remove unused Docker resources and project artifacts.
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "[cleanup.sh] Stopping project services..."
if [ -x "$SCRIPT_DIR/stop.sh" ]; then
    "$SCRIPT_DIR/stop.sh" 2>/dev/null || true
fi
pkill -f "$SCRIPT_DIR/bin/OpenGLContextDemo" 2>/dev/null || true

echo "[cleanup.sh] Stopping Docker containers..."
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    docker stop $(docker ps -aq) 2>/dev/null || true
    docker compose down 2>/dev/null || true
    echo "[cleanup.sh] Removing unused Docker resources (containers, images, volumes, networks)..."
    docker container prune -f 2>/dev/null || true
    docker image prune -af 2>/dev/null || true
    docker volume prune -f 2>/dev/null || true
    docker network prune -f 2>/dev/null || true
    docker system prune -af --volumes 2>/dev/null || true
else
    echo "[cleanup.sh] Docker not available or not running; skipping container/resource cleanup."
fi

echo "[cleanup.sh] Removing project artifacts (node_modules, venv, .pytest_cache, .pyc, Istio, vendor, .rr)..."
for d in node_modules venv .venv .pytest_cache Istio istio vendor; do
    if [ -d "$SCRIPT_DIR/$d" ]; then
        rm -rf "$SCRIPT_DIR/$d"
        echo "[cleanup.sh] Removed $SCRIPT_DIR/$d"
    fi
done
find "$SCRIPT_DIR" -maxdepth 5 -name "*.pyc" -delete 2>/dev/null || true
find "$SCRIPT_DIR" -maxdepth 5 -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$SCRIPT_DIR" -maxdepth 5 -name "*.rr" -delete 2>/dev/null || true

echo "[cleanup.sh] Done."
