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

copy_new_files() {
  local src="$1" dst="$2"
  shift 2
  local count=0 rel skip ex
  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
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
    mkdir -p "$dst/$(dirname "$rel")"
    cp -p "$src/$rel" "$dst/$rel"
    count=$((count + 1))
  done < <(cd "$src" && find . -type f -not -path './.git/*' -not -path './.github/*' -not -path './.devcontainer/*' -not -path './.vscode/*' -print0)
  echo "$count"
}

clone OpenWRT-fanboy/OpenW1700k offload fanboy
clone hurryman2212/OpenW1700k-test offload-oc hurryman
clone YYH2913/openwrt xr1710g-6.18-integration yyh

echo "Extracting hurryman new-only files..."
hurryman_count="$(copy_new_files "$TMP/hurryman" "$ROOT/overlay/hurryman" "$TMP/fanboy")"
echo "hurryman overlay files: $hurryman_count"

echo "Extracting YYH new-only files..."
yyh_count="$(copy_new_files "$TMP/yyh" "$ROOT/overlay/yyh" "$TMP/fanboy" "$TMP/hurryman")"
echo "yyh overlay files: $yyh_count"

mkdir -p "$ROOT/docs"
cat > "$ROOT/docs/overlay-refresh.txt" <<EOF
hurryman_new_files=$hurryman_count
yyh_new_files=$yyh_count
refreshed_at=$(date -u +'%Y-%m-%d %H:%M UTC')
EOF
echo "Overlay extraction complete."

