#!/bin/bash
# Compute a content hash over everything that affects firmware compile
# output, for use in cache keys. Covers the overlay/patches/candidates
# trees plus defconfig, upstream pinning and the apply layer itself.
#
# The hash changes whenever compile-relevant CI content changes, so ccache
# keys built on it stay accurate; the workflow's restore-keys fallback
# still reuses prior content when it does change.
#
# Usage: ci-content-hash.sh [repo-root]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
ROOT="$(cd "$ROOT" && pwd)"

hash_tree() {
  # $1 = root dir; $2 = relative dir (may not exist). Paths are stripped so
  # the hash is independent of checkout location. Missing dirs hash empty.
  local root="$1" dir="$2"
  if [ ! -d "$root/$dir" ]; then
    return 0
  fi
  find "$root/$dir" -type f ! -path '*/.git/*' -print0 \
    | sort -z \
    | xargs -0 -r sha256sum \
    | awk '{print $1}' \
    | sha256sum \
    | cut -d' ' -f1
}

hash_files() {
  # sha256 of the listed files relative to $ROOT; missing files are skipped.
  local f hash=""
  for f in "$@"; do
    [ -f "$ROOT/$f" ] || continue
    hash="$hash$(sha256sum "$ROOT/$f" | cut -d' ' -f1)"
  done
  printf '%s' "$hash" | sha256sum | cut -d' ' -f1
}

TREE_HASH="$(hash_tree "$ROOT" overlay)$(hash_tree "$ROOT" patches)$(hash_tree "$ROOT" candidates)"
FILE_HASH="$(hash_files defconfig supersede.list upstream.lock.json upstreams.yml apply-patches.sh)"
printf '%s%s' "$TREE_HASH" "$FILE_HASH" | sha256sum | cut -c1-16
