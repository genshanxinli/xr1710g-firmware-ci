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

# find_md5 inputs (include/depends.mk / include/kernel-build.mk):
#   ${CURDIR}        -> package/ feeds/ (real files behind package/feeds symlinks)
#   KERNEL_FILE_DEPENDS -> target/linux (patches/files dirs)
#   tools/*          -> host tools use ${CURDIR} too (host-build.mk)
# .config is deliberately NOT frozen: its mtime must stay NEWER than the
# stamps so make keeps seeing an up-to-date config (confvar guards the
# content side). Everything else make compares is inside the cached trees.
find "$CLONE"/package "$CLONE"/feeds "$CLONE"/tools "$CLONE"/target \
  -type f -exec touch -d "@$FREEZE_EPOCH" {} + 2>/dev/null || true

echo "freeze-source-mtimes: frozen package/ feeds/ tools/ target/ to epoch $FREEZE_EPOCH"
