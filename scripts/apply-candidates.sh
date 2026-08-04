#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLONE="${1:?Usage: apply-candidates.sh <openwrt-clone> [<report>]}"
REPORT="${2:-$ROOT/docs/candidate-report.md}"
CANDIDATES="$ROOT/candidates"

if [ ! -d "$CANDIDATES" ]; then
  echo "No candidates directory."
  exit 0
fi
if [ ! -d "$CLONE/.git" ]; then
  echo "ERROR: candidates require a git clone: $CLONE" >&2
  exit 1
fi

mkdir -p "$(dirname "$REPORT")"
{
  echo "# Candidate Report"
  echo
  echo "Generated: $(date -u +'%Y-%m-%d %H:%M UTC')"
  echo
} > "$REPORT"

status=0
while IFS= read -r -d '' src; do
  rel="${src#"$CANDIDATES"/}"
  case "$rel" in
    .gitkeep|.*) continue ;;
  esac
  log="${TMPDIR:-/tmp}/xr1710g-candidate-$$.log"
  case "$rel" in
    patches/*)
      if patch -p1 --batch --forward -d "$CLONE" < "$src" > "$log" 2>&1; then
        echo "- PASS $rel" >> "$REPORT"
      elif grep -qiE "Reversed|previously applied" "$log"; then
        echo "- PASS (already applied) $rel" >> "$REPORT"
      else
        echo "- FAIL $rel" >> "$REPORT"
        tail -20 "$log" >> "$REPORT" || true
        status=1
      fi
      ;;
    *)
      if [ -e "$CLONE/$rel" ]; then
        echo "- FAIL (duplicate target) $rel" >> "$REPORT"
        status=1
        continue
      fi
      mkdir -p "$CLONE/$(dirname "$rel")"
      cp -p "$src" "$CLONE/$rel"
      echo "- PASS $rel" >> "$REPORT"
      ;;
  esac
  rm -f "$log"
done < <(find "$CANDIDATES" -type f -print0 | sort -z)

exit "$status"
