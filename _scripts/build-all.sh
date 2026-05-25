#!/usr/bin/env bash
# Build all four MyST sites and assemble into _site/.
# Run via: pixi run build
# Requires myst on PATH (provided by pixi environment).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Kill orphaned MATLAB processes and crash reporters left by kernel teardown.
cleanup_matlab() {
    pkill -f "MathWorksCrashReporter" 2>/dev/null || true
    pkill -f "CrashDialog" 2>/dev/null || true
    pkill -f "MATLAB_maca64" 2>/dev/null || true
}
trap cleanup_matlab EXIT INT TERM

# Continuously kill crash reporter windows in the background during MATLAB build.
suppress_crash_reporters() {
    while true; do
        pkill -9 -f "MathWorksCrashReporter" 2>/dev/null || true
        pkill -9 -f "CrashDialog" 2>/dev/null || true
        sleep 2
    done
}

echo "==> Building language sites..."
for lang in julia python; do
    echo "  [$lang]"
    (cd "$REPO_ROOT/separate/$lang" && BASE_URL="/$lang" myst build --execute --execute-parallel 4 --html)
done
lang=matlab
echo "  [$lang]"
suppress_crash_reporters &
SUPPRESS_PID=$!
(cd "$REPO_ROOT/separate/$lang" && BASE_URL="/$lang" myst build --execute --execute-parallel 1 --html)
kill "$SUPPRESS_PID" 2>/dev/null || true
wait "$SUPPRESS_PID" 2>/dev/null || true
cleanup_matlab

echo "==> Building main site..."
(cd "$REPO_ROOT" && myst build --execute --execute-parallel 4 --html)

echo "==> Assembling _site/..."
rm -rf "$REPO_ROOT/_site"
mkdir -p "$REPO_ROOT/_site"
cp -r "$REPO_ROOT/_build/html/." "$REPO_ROOT/_site/"
for lang in julia matlab python; do
    mkdir -p "$REPO_ROOT/_site/$lang"
    cp -r "$REPO_ROOT/separate/$lang/_build/html/." "$REPO_ROOT/_site/$lang/"
done

echo "Done. Output in _site/"
