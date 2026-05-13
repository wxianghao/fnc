#!/usr/bin/env bash
# Build, deploy, and tag a versioned release.
# Usage: pixi run release [VERSION]
# VERSION defaults to YYYY.MM.DD if omitted.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-$(date '+%Y.%m.%d')}"
TAG="v$VERSION"

if git -C "$REPO_ROOT" rev-parse "$TAG" >/dev/null 2>&1; then
    echo "Error: tag $TAG already exists."
    exit 1
fi

if ! git -C "$REPO_ROOT" diff-index --quiet HEAD --; then
    echo "Warning: there are uncommitted changes."
    read -rp "Continue anyway? [y/N] " reply
    [[ $reply =~ ^[Yy]$ ]] || exit 1
fi

echo "==> Building..."
bash "$REPO_ROOT/_scripts/build-all.sh"

echo "==> Deploying..."
bash "$REPO_ROOT/_scripts/deploy.sh"

echo "==> Tagging $TAG..."
git -C "$REPO_ROOT" tag -a "$TAG" -m "Release $VERSION"
git -C "$REPO_ROOT" push origin "$TAG"

echo ""
echo "Released $TAG."
echo "To create a GitHub Release with archive: gh release create $TAG --generate-notes"
