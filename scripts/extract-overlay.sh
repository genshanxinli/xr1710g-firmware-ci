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
    target/linux/airoha/*|\
    target/linux/generic/hack-6.18/9991-*|\
    target/linux/generic/hack-6.18/9992-*|\
    tools/elfutils/patches/014-*) return 0 ;;
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
    target/linux/airoha/*|\
    target/linux/generic/pending-6.18/9993-*|\
    target/linux/generic/pending-6.18/9999-*) return 0 ;;
  esac
  return 1
}

copy_new_files() {
  local src="$1" dst="$2" filter="$3"
  shift 3
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
    mkdir -p "$dst/$(dirname "$rel")"
    cp -p "$src/$rel" "$dst/$rel"
    count=$((count + 1))
  done < <(cd "$src" && find . -type f -print0)
  echo "$count"
}

clone OpenWRT-fanboy/OpenW1700k offload fanboy
clone hurryman2212/OpenW1700k-test offload-oc hurryman
clone YYH2913/openwrt xr1710g-6.18-integration yyh

echo "Extracting hurryman device-relevant new-only files..."
hurryman_count="$(copy_new_files "$TMP/hurryman" "$ROOT/overlay/hurryman" allowed_hurryman "$TMP/fanboy")"
echo "hurryman overlay files: $hurryman_count"

echo "Extracting YYH device-relevant new-only files..."
yyh_count="$(copy_new_files "$TMP/yyh" "$ROOT/overlay/yyh" allowed_yyh "$TMP/fanboy" "$TMP/hurryman")"
echo "yyh overlay files: $yyh_count"

mkdir -p "$ROOT/docs"
cat > "$ROOT/docs/overlay-refresh.txt" <<EOF
hurryman_new_files=$hurryman_count
yyh_new_files=$yyh_count
refreshed_at=$(date -u +'%Y-%m-%d %H:%M UTC')
EOF
echo "Overlay extraction complete."

