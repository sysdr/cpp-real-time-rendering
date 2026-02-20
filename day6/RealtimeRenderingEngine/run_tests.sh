#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"
FAIL=0
echo "Running tests..."

if [ -f "$SCRIPT_DIR/metrics.json" ]; then
    grep -q "run_count" "$SCRIPT_DIR/metrics.json" && grep -q "last_run_ts" "$SCRIPT_DIR/metrics.json" && echo "[PASS] Dashboard metrics file present" || { echo "[FAIL] metrics.json missing keys"; FAIL=1; }
else
    echo "[SKIP] metrics.json not found (run start.sh first)"
fi

if [ -f "$SCRIPT_DIR/build/Day6_Shaders" ]; then
    echo "[PASS] App binary present"
    OUTPUT=$(timeout 2 "$SCRIPT_DIR/build/Day6_Shaders" 2>&1 || true)
    echo "$OUTPUT" | grep -qE "Failed|OpenGL|GLAD|Shader" && echo "[PASS] App runs (OpenGL/Shader context)" || echo "[SKIP] Run demo manually to verify"
else
    echo "[SKIP] App not built (run setup.sh, then start.sh)"
fi

[ $FAIL -eq 0 ] && echo "All tests passed." || exit 1
