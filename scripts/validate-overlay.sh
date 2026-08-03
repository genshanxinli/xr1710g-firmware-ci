#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP="${TMPDIR:-/tmp}/xr1710g-validate-$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

echo "Cloning fanboy offload base..."
git clone --depth 1 --branch offload --single-branch \
  "https://github.com/OpenWRT-fanboy/OpenW1700k.git" "$TMP/openwrt"

echo "Applying overlay..."
bash "$ROOT/apply-patches.sh" "$TMP/openwrt" "$ROOT"

echo "Verifying key files..."
test -f "$TMP/openwrt/target/linux/airoha/dts/an7581-xr1710g-ubi.dts" \
  || { echo "FAIL: XR1710G DTS missing"; exit 1; }
grep -q "econet_xr1710g" "$TMP/openwrt/target/linux/airoha/image/an7581.mk" \
  || { echo "FAIL: XR1710G device block missing"; exit 1; }
if [ -d "$ROOT/overlay/hurryman/package/luci-app-mlo" ]; then
  test -f "$TMP/openwrt/package/luci-app-mlo/Makefile" \
    || { echo "FAIL: hurryman LuCI app not copied"; exit 1; }
fi
if [ -d "$ROOT/overlay/yyh/target/linux/airoha/patches-6.18" ]; then
  find "$ROOT/overlay/yyh/target/linux/airoha/patches-6.18" -name '*.patch' | grep -q . \
    || { echo "FAIL: YYH kernel patches missing"; exit 1; }
fi
echo "Overlay validation passed."
