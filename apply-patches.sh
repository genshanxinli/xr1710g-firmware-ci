#!/bin/bash
# Apply XR1710G CI overlays to a fanboy offload OpenWrt clone.
# Usage: apply-patches.sh <openwrt-clone> [<repo-root>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLONE="${1:?Usage: apply-patches.sh <openwrt-clone> [<repo-root>]}"
ROOT="${2:-$SCRIPT_DIR}"
OVERLAY="$ROOT/overlay"
PATCHES="$ROOT/patches"

if [ ! -d "$CLONE" ]; then
  echo "ERROR: clone directory not found: $CLONE"
  exit 1
fi

copy_overlay() {
  local src="$1" name="$2" rel
  [ -d "$src" ] || return 0
  echo "[copy] $name"
  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    if [ ! -e "$CLONE/$rel" ]; then
      mkdir -p "$CLONE/$(dirname "$rel")"
      cp -p "$src/$rel" "$CLONE/$rel"
    fi
  done < <(cd "$src" && find . -type f -not -path '*/.git/*' -not -path '*/.github/*' -not -path '*/.devcontainer/*' -not -path '*/.vscode/*' -print0)
}

copy_patch_files() {
  local src="$1" dst="$2" p
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  for p in "$src"/*.patch; do
    [ -f "$p" ] || continue
    if [ ! -e "$dst/$(basename "$p")" ]; then
      cp -p "$p" "$dst/"
    else
      echo "  skip existing target patch: $(basename "$p")"
    fi
  done
}

remove_conflicting_patch() {
  local dst="$1" reason="$2"
  if [ -f "$CLONE/$dst" ]; then
    rm -f "$CLONE/$dst"
    echo "  removed upstream patch: $dst ($reason)"
  else
    echo "  upstream patch already absent: $dst"
  fi
}

apply_patch_dir() {
  local dir="$1" name="$2" p
  [ -d "$dir" ] || return 0
  echo "[patch] $name"
  while IFS= read -r -d '' p; do
    if ! patch -p1 --batch --forward -d "$CLONE" < "$p" > /tmp/patch-$$.log 2>&1; then
      if grep -qiE "Reversed|previously applied|already exists|Skipping patch|hunk ignored" /tmp/patch-$$.log; then
        echo "  skip already applied: $(basename "$p")"
        rm -f /tmp/patch-$$.log
        continue
      fi
      echo "FAILED patch: $p"
      cat /tmp/patch-$$.log
      rm -f /tmp/patch-$$.log
      exit 1
    fi
    rm -f /tmp/patch-$$.log
  done < <(find "$dir" -type f -name '*.patch' -print0 | sort -z)
}

echo "Applying XR1710G overlays to $CLONE"
# Drop stale reject files from reused validation trees before applying overlays.
find "$CLONE" -name "*.rej" -delete
remove_conflicting_patch "package/firmware/wireless-regdb/patches/555-w1700k-fix.patch" "YYH 520/530 carry the same fixes"
remove_conflicting_patch "package/network/utils/iwinfo/patches/999-fix-txpower-list.patch" "YYH 101 carries the same txpower fix"
copy_overlay "$OVERLAY/hurryman" "hurryman new-only files"
apply_patch_dir "$PATCHES/hurryman" "hurryman adaptation patches"
copy_overlay "$OVERLAY/yyh" "yyh new-only files"
copy_patch_files "$PATCHES/yyh/kernel" "$CLONE/target/linux/airoha/patches-6.18"
copy_patch_files "$PATCHES/yyh/regdb" "$CLONE/package/firmware/wireless-regdb/patches"
copy_patch_files "$PATCHES/yyh/mt76/patches" "$CLONE/package/kernel/mt76/patches"
apply_patch_dir "$PATCHES/yyh/apply" "yyh package patches"
copy_overlay "$OVERLAY/xr1710g" "xr1710g new files"
apply_patch_dir "$PATCHES/xr1710g" "xr1710g adaptation patches"

echo "Verifying key files..."
test -f "$CLONE/target/linux/airoha/dts/an7581-xr1710g-ubi.dts" \
  || { echo "FAIL: XR1710G DTS missing"; exit 1; }
grep -q "econet_xr1710g" "$CLONE/target/linux/airoha/image/an7581.mk" \
  || { echo "FAIL: XR1710G device block missing"; exit 1; }
if find "$CLONE" -name '*.rej' | grep -q .; then
  echo "FAIL: patch reject files remain after apply:"
  find "$CLONE" -name '*.rej'
  exit 1
fi
ls "$CLONE"/target/linux/airoha/patches-6.18/330-* \
   "$CLONE"/target/linux/airoha/patches-6.18/921-* >/dev/null 2>&1 \
  || { echo "FAIL: YYH kernel patch files missing"; exit 1; }
echo "All patches applied successfully."
