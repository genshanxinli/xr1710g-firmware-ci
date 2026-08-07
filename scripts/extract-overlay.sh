#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP="${TMPDIR:-/tmp}/xr1710g-extract-$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

clone() {
  local repo="$1" branch="$2" dir="$3"
  echo "Cloning $repo $branch"
  git clone --depth 1 --branch "$branch" --single-branch "https://github.com/$repo.git" "$TMP/$dir"
}

allowed_hurryman() {
  case "$1" in
    package/kernel/mt76/*|\
    package/network/config/firewall4/*|\
    package/network/services/hostapd/*|\
    target/linux/airoha/patches-6.18/9990-*|\
    target/linux/airoha/patches-6.18/9999-*|\
    target/linux/generic/hack-6.18/9990-*|\
    target/linux/generic/hack-6.18/9991-*|\
    target/linux/generic/hack-6.18/9992-*) return 0 ;;
  esac
  return 1
}

# hurryman-tree mt76 patches that must NOT be re-extracted: 0013/0014
# (airoha PPE flush series) were dropped per the fanboy production
# stance -- apply-patches.sh removes them and re-importing via refresh
# would silently resurrect them.
HURRYMAN_SKIP_RE="^package/kernel/mt76/patches/001[34]-"

skip_hurryman() {
  # $1 = clone-relative path; 0 = skip (do not extract), 1 = keep.
  case "$1" in
    package/kernel/mt76/patches/*) [[ "$1" =~ $HURRYMAN_SKIP_RE ]] && return 0 ;;
  esac
  return 1
}

allowed_yyh() {
  case "$1" in
    package/firmware/wireless-regdb/*|\
    package/kernel/mac80211/patches/subsys/*|\
    package/kernel/mt76/*|\
    package/network/services/hostapd/*|\
    package/network/utils/iwinfo/*|\
    package/utils/ucode/*|\
    target/linux/airoha/an7581/*|\
    target/linux/airoha/base-files/*|\
    target/linux/airoha/dts/*) return 0 ;;
  esac
  return 1
}

# YYH-tree files that must NOT be re-extracted into overlay/yyh:
#  0005/0047 -- upstreamed (EHT MCS-15 / RRO 3.0), deliberately dropped
#  0006/0007 -- fanboy 0011/0010 carry the same fixes (base supplies them)
#  0013       -- scan.c hunk upstreamed (mt76 50480826); the curated
#                patches/yyh/mt76/patches/0016 cut-down version is canonical
#  602/603    -- fanboy 053 / mtk-0015 already cover these
#  9992       -- renumbered to 9994 (avoid clashing with hurryman mt76 9992)
YYH_SKIP_RE="^package/kernel/mt76/patches/(0005|0006|0007|0013|0047|602|603|9992)-"

skip_yyh() {
  # $1 = clone-relative path; 0 = skip (do not extract), 1 = keep.
  case "$1" in
    package/kernel/mt76/patches/*) [[ "$1" =~ $YYH_SKIP_RE ]] && return 0 ;;
  esac
  return 1
}

copy_new_files() {
  local src="$1" dst="$2" filter="$3" skipfn="$4"
  shift 4
  local count=0 rel skip ex
  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    case "$rel" in
      .git/*|.github/*|.devcontainer/*|.vscode/*) continue ;;
    esac
    skip=0
    for ex in "$@"; do
      if [ -e "$ex/$rel" ]; then
        skip=1
        break
      fi
    done
    if [ "$skip" -eq 1 ]; then
      continue
    fi
    if [ -e "$dst/$rel" ]; then
      continue
    fi
    if ! "$filter" "$rel"; then
      continue
    fi
    if "$skipfn" "$rel"; then
      # skipfn returns 0 when the file must NOT be extracted.
      continue
    fi
    mkdir -p "$dst/$(dirname "$rel")"
    cp -p "$src/$rel" "$dst/$rel"
    count=$((count + 1))
  done < <(cd "$src" && find . -type f -print0)
  echo "$count"
}

clone OpenWRT-fanboy/OpenW1700k ubi2-oc fanboy
clone hurryman2212/OpenW1700k-test offload-oc hurryman
clone YYH2913/openwrt xr1710g-6.18-integration yyh

echo "Extracting hurryman device-relevant new-only files..."
hurryman_count="$(copy_new_files "$TMP/hurryman" "$ROOT/overlay/hurryman" allowed_hurryman skip_hurryman "$TMP/fanboy")"
echo "hurryman overlay files: $hurryman_count"

echo "Extracting YYH device-relevant new-only files..."
yyh_count="$(copy_new_files "$TMP/yyh" "$ROOT/overlay/yyh" allowed_yyh skip_yyh "$TMP/fanboy" "$TMP/hurryman")"
echo "yyh overlay files: $yyh_count"

mkdir -p "$ROOT/docs"
cat > "$ROOT/docs/overlay-refresh.txt" <<EOF
hurryman_new_files=$hurryman_count
yyh_new_files=$yyh_count
refreshed_at=$(date -u +'%Y-%m-%d %H:%M UTC')
EOF
echo "Overlay extraction complete."

