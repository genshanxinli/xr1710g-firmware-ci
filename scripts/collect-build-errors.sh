#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG="${1:?Usage: collect-build-errors.sh <build.log> [<report>]}"
REPORT="${2:-$ROOT/docs/build-failures.md}"

if [ ! -f "$LOG" ]; then
  echo "WARNING: build log not found: $LOG" >&2
fi

mkdir -p "$(dirname "$REPORT")"
{
  echo "# Build Failures"
  echo
  echo "Generated: $(date -u +'%Y-%m-%d %H:%M UTC')"
  echo
  echo "Source: $LOG"
  echo
  echo '```'
  if [ -f "$LOG" ]; then
    grep -nE "Hunk #.*FAILED|Patch failed|ERROR: .*failed to build|error:|fatal error|No rule to make target|make\[[0-9]+\]: \*\*\* .*Error [0-9]+" "$LOG" \
      | grep -vE "\(ignored\)|libeu\.manifest|libdwfl\.manifest|libelf\.manifest|libebl\.manifest|libcpu\.manifest|ninja-1\.13\.2/ninja|data-directory/python|write error: Broken pipe" \
      | sort -u | tail -120 || true
  fi
  echo '```'
} > "$REPORT"

echo "Wrote $REPORT"
