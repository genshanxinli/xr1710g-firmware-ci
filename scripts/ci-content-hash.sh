#!/bin/bash
# Compute a content hash over everything that affects firmware compile
# output, for use in cache keys. Covers the overlay/patches/candidates
# trees plus defconfig, upstream pinning and the apply layer itself.
#
# The hash changes whenever compile-relevant CI content changes, so ccache
# keys built on it stay accurate; the workflow's restore-keys fallback
# still reuses prior content when it does change.
#
# --kernel mode: hash only kernel-affecting content (phase-2 build_dir
# kernel channel). Classification (conservative — over-inclusion is safe,
# under-inclusion is forbidden):
#   - config files (defconfig, locks, supersede.list, apply-patches.sh): kernel
#   - overlay files: excluded only under overlay/*/package/**; target/** and
#     everything else (incl. base-files under target/linux) counts as kernel
#   - patches:
#       patches/yyh/kernel/**            -> kernel (routed to target/linux)
#       patches/yyh/mt76/**, yyh/regdb/** -> package (routed to package/)
#       root-applied dirs (hurryman, upstream-backports, yyh/apply,
#       xr1710g): kernel unless EVERY touched path starts with package/
#   - candidates/**: excluded (applied only in candidate-prepare, never in
#     the full build)
#
# Usage: ci-content-hash.sh [--kernel] [repo-root]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_ONLY=0
[ "${1:-}" = "--kernel" ] && { KERNEL_ONLY=1; shift; }
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

# patch_is_package_only <abs-path>: 0 = safe to exclude from kernel hash,
# 1 = kernel-affecting (or unclassifiable -> conservative kernel).
patch_is_package_only() {
  local p="$1" path paths
  case "$p" in
    *"/yyh/kernel/"*) return 1 ;;
    *"/yyh/mt76/"*|*"/yyh/regdb/"*) return 0 ;;
  esac
  # Root-applied dirs: classify by touched paths. Patches whose paths are
  # all under package/ are package-only; anything else (or no paths found)
  # counts as kernel-affecting.
  paths="$(grep -hoE '^(\+\+\+|---) [ab]/[^[:space:]]+' "$p" 2>/dev/null \
    | sed -E 's#^(\+\+\+|---) [ab]/##')"
  [ -z "$paths" ] && return 1
  while IFS= read -r path; do
    case "$path" in
      package/*) ;;
      *) return 1 ;;
    esac
  done <<< "$paths"
  return 0
}

# kernel_include <rel-path>: echo 1 if the file belongs in the kernel hash.
kernel_include() {
  local rel="$1"
  case "$rel" in
    overlay/*/package/*) return 1 ;;
    candidates/*) return 1 ;;
    patches/yyh/mt76/*|patches/yyh/regdb/*) return 1 ;;
    patches/*.patch)
      if patch_is_package_only "$ROOT/$rel"; then return 1; fi
      ;;
  esac
  return 0
}

CONFIG_FILES="defconfig supersede.list upstream.lock.json upstreams.yml apply-patches.sh"

if [ "$KERNEL_ONLY" -eq 1 ]; then
  # Kernel-affecting content: config files + overlay (minus package/) +
  # patches (minus package-only). Order-stable iteration.
  HASH="$(hash_files $CONFIG_FILES)"
  while IFS= read -r f; do
    rel="${f#"$ROOT"/}"
    if kernel_include "$rel"; then
      HASH="$HASH$(sha256sum "$f" | cut -d' ' -f1)"
    fi
  done < <(find "$ROOT/overlay" "$ROOT/patches" -type f | sort)
  printf '%s' "$HASH" | sha256sum | cut -c1-16
  exit 0
fi

TREE_HASH="$(hash_tree "$ROOT" overlay)$(hash_tree "$ROOT" patches)$(hash_tree "$ROOT" candidates)"
FILE_HASH="$(hash_files $CONFIG_FILES)"
printf '%s%s' "$TREE_HASH" "$FILE_HASH" | sha256sum | cut -c1-16
