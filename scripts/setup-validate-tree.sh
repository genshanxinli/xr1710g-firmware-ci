#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GLASS_REPO="rchen14b/luci-theme-glass"
GLASS_REF="v1.1.6"

if [ "${1:-}" = "--existing" ]; then
  DEST="${2:?Usage: setup-validate-tree.sh [--existing] <dest-dir> [<repo-root>]}"
  ROOT="${3:-$ROOT}"
else
  DEST="${1:?Usage: setup-validate-tree.sh [--existing] <dest-dir> [<repo-root>]}"
  ROOT="${2:-$ROOT}"
fi

if [ ! -d "$DEST/.git" ]; then
  bash "$ROOT/scripts/clone-base.sh" "$DEST"
fi

bash "$ROOT/apply-patches.sh" "$DEST" "$ROOT"
if [ ! -d "$DEST/package/luci-theme-glass/.git" ]; then
  git clone --depth=1 --branch "$GLASS_REF" \
    "https://github.com/$GLASS_REPO.git" "$DEST/package/luci-theme-glass"
fi
cd "$DEST"
./scripts/feeds update -a
./scripts/feeds install -a
cp "$ROOT/defconfig" .config
make defconfig
echo "Validation tree ready at $DEST"
