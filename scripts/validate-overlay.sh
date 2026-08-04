#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP="${TMPDIR:-/tmp}/xr1710g-validate-$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

echo "Setting up locked fanboy validation tree..."
bash "$ROOT/scripts/setup-validate-tree.sh" "$TMP/openwrt" "$ROOT"

echo "Preparing host tools..."
cd "$TMP/openwrt"
make download -j$(nproc)
make tools/install toolchain/install -j$(nproc) V=s 2>&1 | tail -30

echo "Running patch preflight..."
bash "$ROOT/scripts/preflight-validate.sh" "$TMP/openwrt" --mode=prepare
echo "Overlay validation passed."
