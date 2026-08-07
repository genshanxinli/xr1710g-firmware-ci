#!/bin/bash
# Capture CI performance metrics (ccache stats, disk, tree sizes) into a
# markdown report. Appends to the output file and to GITHUB_STEP_SUMMARY
# when present. Run once before the build (phase=pre-build) and once after
# (phase=post-build) with the same output file to get both snapshots.
#
# Usage: ci-metrics.sh <openwrt-dir> <output-md> [phase]
set -euo pipefail
CLONE="${1:?Usage: ci-metrics.sh <openwrt-dir> <output-md> [phase]}"
OUT="${2:?Usage: ci-metrics.sh <openwrt-dir> <output-md> [phase]}"
PHASE="${3:-build}"

CCACHE_BIN="$(command -v ccache 2>/dev/null || echo "$CLONE/staging_dir/host/bin/ccache")"
SECTION="${TMPDIR:-/tmp}/ci-metrics-section-$$"
trap 'rm -f "$SECTION"' EXIT

{
  echo
  echo "## CI Metrics ($PHASE)"
  echo
  echo "- Timestamp: $(date -u +'%Y-%m-%d %H:%M UTC')"
  echo "- Commit: ${GITHUB_SHA:-unknown} (${GITHUB_REF_NAME:-unknown})"
  echo
  echo "### ccache"
  echo '```'
  if [ -x "$CCACHE_BIN" ]; then
    "$CCACHE_BIN" -s 2>/dev/null || true
  else
    echo "ccache binary not found (expected at staging_dir/host/bin/ccache)"
  fi
  echo '```'
  echo "### Disk"
  echo '```'
  df -h / | tail -1
  echo '```'
  echo "### Tree sizes"
  echo '```'
  du -sh "$CLONE/build_dir" "$CLONE/staging_dir" "$CLONE/dl" "$CLONE/.ccache" 2>/dev/null || true
  echo '```'
} > "$SECTION"

cat "$SECTION" >> "$OUT"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  cat "$SECTION" >> "$GITHUB_STEP_SUMMARY"
fi
