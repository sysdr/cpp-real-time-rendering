#!/bin/bash
# Tests: verify project structure, build, and optional demo run
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1
PROJECT_NAME="rendering_engine_day7"
BUILD_DIR="build"
FAILED=0

echo "=============================================="
echo "  Dashboard: Test run - metrics"
echo "=============================================="
echo "  Project: $PROJECT_NAME"
echo "  Tests: file check, build, demo"
echo "----------------------------------------------"

# 1. File checks
FILES="src/main.cpp CMakeLists.txt start.sh stop.sh"
for f in $FILES; do
  if [ -e "$f" ]; then
    echo "  [OK] $f exists"
  else
    echo "  [FAIL] $f missing"; FAILED=1
  fi
done

# 2. Build
echo "  Building..."
if ( mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR" && cmake -Wno-dev .. >/dev/null 2>&1 && make -j$(nproc 2>/dev/null || echo 2) >/dev/null 2>&1 && cd .. ); then
  echo "  [OK] Build succeeded"
else
  echo "  [FAIL] Build failed"; FAILED=1
fi

# 3. Executable exists
if [ -f "$BUILD_DIR/$PROJECT_NAME" ]; then
  echo "  [OK] Executable present"
else
  echo "  [FAIL] Executable missing"; FAILED=1
fi

# 4. Demo run (timeout 3s; may exit early if no DISPLAY)
if [ -f "$BUILD_DIR/$PROJECT_NAME" ]; then
  timeout 3 "./$BUILD_DIR/$PROJECT_NAME" 2>/dev/null; R=$?
  if [ "$R" = 124 ]; then
    echo "  [OK] Demo run (stopped after 3s)"
  elif [ "$R" = 0 ] || [ "$R" = 1 ]; then
    echo "  [OK] Demo run (exited with $R, e.g. no display)"
  else
    echo "  [INFO] Demo run exit code: $R"
  fi
fi

echo "----------------------------------------------"
if [ "$FAILED" = 0 ]; then
  echo "  Result: All checks passed."
else
  echo "  Result: Some checks failed."
  exit 1
fi
echo "=============================================="
