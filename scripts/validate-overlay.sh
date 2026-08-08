#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TREE=""
TOOLCHAIN_CACHED=0

while [ $# -gt 0 ]; do
  case "$1" in
    --tree-dir=*) TREE="${1#--tree-dir=}" ;;
    --toolchain-cached) TOOLCHAIN_CACHED=1 ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

if [ -n "$TREE" ]; then
  # Fixed tree dir whose dl/toolchain caches were restored by the calling
  # workflow before this script ran (see sync-upstream.yml).
  [ -d "$TREE" ] || { echo "ERROR: tree dir not found: $TREE" >&2; exit 1; }
  TREE="$(cd "$TREE" && pwd)"
else
  # Legacy mode: throwaway tree, no cache reuse.
  TREE="${TMPDIR:-/tmp}/xr1710g-validate-$$"
  mkdir -p "$TREE"
  trap 'rm -rf "$TREE"' EXIT
fi

echo "Setting up locked fanboy validation tree..."
bash "$ROOT/scripts/setup-validate-tree.sh" "$TREE" "$ROOT"

echo "Preparing host tools..."
cd "$TREE"
make download -j$(nproc)
if [ "$TOOLCHAIN_CACHED" -ne 1 ]; then
  make tools/install toolchain/install -j$(nproc) V=s 2>&1 | tail -30
else
  echo "Toolchain cache hit -- skipping tools/toolchain build."
fi

echo "Running patch preflight (patches already applied by setup-validate-tree)..."
bash "$ROOT/scripts/preflight-validate.sh" "$TREE" --mode=prepare --skip-apply
echo "Overlay validation passed."
