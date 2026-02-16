#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
BUILD_DIR="$SCRIPT_DIR/build"
FAIL=0
echo "Running tests..."

# Test 1: metrics.json exists and has expected keys (dashboard metrics)
if [ -f "$SCRIPT_DIR/metrics.json" ]; then
    grep -q "run_count" "$SCRIPT_DIR/metrics.json" && grep -q "last_run_ts" "$SCRIPT_DIR/metrics.json" && echo "[PASS] Dashboard metrics file present" || { echo "[FAIL] metrics.json missing keys"; FAIL=1; }
else
    echo "[SKIP] metrics.json not found (run start.sh first)"
fi

# Test 2: app binary if built
if [ -f "$BUILD_DIR/app" ]; then
    OUTPUT=$("$BUILD_DIR/app" 2>&1)
    echo "$OUTPUT" | grep -q "Rendering Engine" && echo "[PASS] App prints welcome message" || { echo "[FAIL] Expected welcome message"; FAIL=1; }
else
    echo "[SKIP] App not built (run setup.sh with cmake/vcpkg, then start.sh)"
fi

[ $FAIL -eq 0 ] && echo "All tests passed." || exit 1
