#!/bin/bash
# Freeze the mtimes of all compile-relevant SOURCE TREE files (everything
# OUTSIDE the cached build_dir/staging_dir) to a fixed epoch.
#
# Why: OpenWrt's STAMP_PREPARED name embeds `find_md5`, whose default
# variant hashes "%p%T@\n" — i.e. file mtime, not just content
# (include/depends.mk). The package/kernel source dirs are re-cloned on
# every run, so their mtimes differ between runs and the restored cache's
# `.prepared_<hash>` stamps never match the name make computes — every
# package re-extracts and rebuilds (observed: warm run still 14m55s with
# 258 package rebuilds).
#
# Freezing the source tree to the same fixed epoch on EVERY run (seed and
# warm alike) makes find_md5 stable across runs, so the restored stamps
# match by name. The cached trees are normalized to the SAME epoch by
# builddir-cache.sh normalize_mtimes — equal mtimes mean make treats
# stamps as up-to-date (it rebuilds only when a prereq is strictly newer).
#
# The epoch is SOURCE_DATE_EPOCH (1786062016 = 2026-08-07 12:20:16 UTC):
# identical to what the build already stamps into outputs, so version
# strings stay consistent.
#
# NOTE: must run AFTER Configure/Download (which regenerate .config etc.)
# and BEFORE any make that computes stamp names (preflight, full build).
# It does not touch .git, so `git status` stays clean.
set -euo pipefail

CLONE="${1:?Usage: freeze-source-mtimes.sh <openwrt-clone>}"
FREEZE_EPOCH="${FREEZE_EPOCH:-1786062016}"

# The ENTIRE source tree is frozen, not just the find_md5 inputs:
#   find_md5 inputs: package/ feeds/ tools/ target/ (${CURDIR} +
#                    KERNEL_FILE_DEPENDS, incl. kernel patches/files)
#   Top-level Makefile:81 `$(BUILD_DIR)/.prepared: Makefile` re-touches
#                    staging_dir/target-*/.prepared (a prerequisite of
#                    EVERY package compile, package/Makefile:83) whenever
#                    the top Makefile is newer — a freshly cloned tree
#                    always is, so every warm build re-ran every package's
#                    prepare->configure->built chain despite matching
#                    stamp NAMES.
# .config gets frozen too — safe: STAMP_CONFIGURED embeds confvar (a
# content hash, not mtime), and the kernel's STAMP_CONFIGURED has FORCE
# anyway. Excluded dirs (caches/build outputs) are normalized to the same
# epoch by builddir-cache.sh normalize_mtimes; tmp/ is regenerated each
# build (prepare-tmpinfo) and must stay current.
find "$CLONE" \
  -path "$CLONE/.git" -prune -o \
  -path "$CLONE/build_dir" -prune -o \
  -path "$CLONE/staging_dir" -prune -o \
  -path "$CLONE/dl" -prune -o \
  -path "$CLONE/.ccache" -prune -o \
  -path "$CLONE/tmp" -prune -o \
  -type f -exec touch -d "@$FREEZE_EPOCH" {} + 2>/dev/null || true

echo "freeze-source-mtimes: frozen source tree to epoch $FREEZE_EPOCH (excluding caches/build dirs)"
