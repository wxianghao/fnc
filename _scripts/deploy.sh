#!/usr/bin/env bash
# Deploy _site/ to the gh-pages branch via ghp-import.
# Run via: pixi run deploy
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SITE_DIR="$REPO_ROOT/_site"

if [[ ! -d "$SITE_DIR" ]]; then
    echo "Error: _site/ not found. Run 'pixi run build' first."
    exit 1
fi

cd "$REPO_ROOT"
ghp-import -n -p -c "fncbook.com" "$SITE_DIR"
echo "Deployed to gh-pages."
