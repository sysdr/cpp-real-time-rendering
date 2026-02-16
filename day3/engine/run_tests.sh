#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
BUILD_DIR="$SCRIPT_DIR/build"
FAIL=0
echo "Running tests..."

# Test 1: metrics.json exists and has expected keys
if [ -f "$SCRIPT_DIR/metrics.json" ]; then
    grep -q "run_count" "$SCRIPT_DIR/metrics.json" && grep -q "last_run_ts" "$SCRIPT_DIR/metrics.json" && echo "[PASS] Dashboard metrics file present" || { echo "[FAIL] metrics.json missing keys"; FAIL=1; }
else
    echo "[SKIP] metrics.json not found (run start.sh first)"
fi

# Test 2: app binary if built — run with timeout; expect METRICS/FPS in output
if [ -f "$BUILD_DIR/GameLoopApp" ]; then
    OUTPUT=$(timeout 8 "$BUILD_DIR/GameLoopApp" 2>&1 || true)
    echo "$OUTPUT" | grep -qE "\[METRICS\]|FPS:|High-Precision Game Loop" && echo "[PASS] App prints expected metrics" || { echo "[FAIL] Expected [METRICS]/FPS/High-Precision in output"; FAIL=1; }
else
    echo "[SKIP] App not built (run setup.sh, then start.sh)"
fi

[ $FAIL -eq 0 ] && echo "All tests passed." || exit 1
