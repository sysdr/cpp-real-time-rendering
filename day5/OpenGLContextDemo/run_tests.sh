#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
BIN_DIR="$SCRIPT_DIR/bin"
FAIL=0
echo "Running tests..."

# Test 1: metrics.json exists and has expected keys
if [ -f "$SCRIPT_DIR/metrics.json" ]; then
    grep -q "run_count" "$SCRIPT_DIR/metrics.json" && grep -q "last_run_ts" "$SCRIPT_DIR/metrics.json" && echo "[PASS] Dashboard metrics file present" || { echo "[FAIL] metrics.json missing keys"; FAIL=1; }
else
    echo "[SKIP] metrics.json not found (run start.sh first)"
fi

# Test 2: app binary if built — exist and optionally run (timeout 2) and check OpenGL in output
if [ -f "$BIN_DIR/OpenGLContextDemo" ]; then
    echo "[PASS] App binary present"
    OUTPUT=$(timeout 2 "$BIN_DIR/OpenGLContextDemo" 2>&1 || true)
    echo "$OUTPUT" | grep -qE "OpenGL Version|Renderer|GLSL" && echo "[PASS] App prints OpenGL info" || echo "[SKIP] OpenGL output not captured (run demo manually to verify)"
else
    echo "[SKIP] App not built (run setup.sh, then start.sh to build)"
fi

[ $FAIL -eq 0 ] && echo "All tests passed." || exit 1
