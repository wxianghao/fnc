#!/usr/bin/env bash
# Build all four MyST sites and assemble into _site/.
# Run via: pixi run build
# Requires myst on PATH (provided by pixi environment).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Building language sites..."
for lang in julia matlab python; do
    echo "  [$lang]"
    (cd "$REPO_ROOT/separate/$lang" && BASE_URL="/$lang" myst build --execute --execute-parallel 4 --html)
done

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
