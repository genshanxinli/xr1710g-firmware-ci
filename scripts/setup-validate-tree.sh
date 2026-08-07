#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GLASS_REPO="rchen14b/luci-theme-glass"
GLASS_REF="v1.1.6"

SKIP_FEEDS_UPDATE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --existing) shift ;;
    --skip-feeds-update) SKIP_FEEDS_UPDATE=1; shift ;;
    -*) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
    *) break ;;
  esac
done
DEST="${1:?Usage: setup-validate-tree.sh [--existing] [--skip-feeds-update] <dest-dir> [<repo-root>]}"
ROOT="${2:-$ROOT}"

# Normalize so cp/make still see the CI repo after cd into the OpenWrt tree.
ROOT="$(cd "$ROOT" && pwd)"

if [ ! -d "$DEST/.git" ]; then
  bash "$ROOT/scripts/clone-base.sh" "$DEST"
fi

bash "$ROOT/apply-patches.sh" "$DEST" "$ROOT"
if [ ! -d "$DEST/package/luci-theme-glass/.git" ]; then
  git clone --depth=1 --branch "$GLASS_REF" \
    "https://github.com/$GLASS_REPO.git" "$DEST/package/luci-theme-glass"
fi
cd "$DEST"
# Skip the network feeds fetch when the feeds dir was restored from an
# exact cache hit (same base SHA); install is still required because the
# package/feeds symlinks are not part of the cached path.
if [ "$SKIP_FEEDS_UPDATE" -ne 1 ]; then
  ./scripts/feeds update -a
fi
./scripts/feeds install -a
cp "$ROOT/defconfig" .config
make defconfig
echo "Validation tree ready at $DEST"
