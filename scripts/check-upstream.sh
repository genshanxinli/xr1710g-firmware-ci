#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib-upstreams.sh"

changed=0
report="$ROOT/docs/upstream-changes.md"
mkdir -p "$ROOT/docs"
: > "$report"
{
  echo "# Upstream Tracking Report"
  echo
  echo "Generated: $(date -u +'%Y-%m-%d %H:%M UTC')"
  echo
  echo "| Source | Old SHA | New SHA |"
  echo "|---|---|---|"
} > "$report"

for name in fanboy hurryman yyh; do
  old="$(lock_sha "$name")"
  new="$(upstream_sha "$name")"
  if [ -z "$new" ]; then
    echo "ERROR: could not resolve $name" >&2
    exit 2
  fi
  if [ "$name" = "fanboy" ]; then
    # Tracked ref (ubi2-oc-auto) intentionally diverges from the pinned build
    # base (1fcc930): report only, never trigger auto-refresh for fanboy.
    echo "| $name | $old | $new (tracked, pinned base $old) |" >> "$report"
    echo "TRACKED fanboy base=$old tracked=$new"
    continue
  fi
  if [ "$old" != "$new" ]; then
    changed=1
    echo "| $name | $old | $new |" >> "$report"
    echo "CHANGED $name $old -> $new"
  else
    echo "| $name | $old | $new |" >> "$report"
  fi
done

if [ "$changed" -eq 1 ]; then
  echo "Upstream changes detected." >&2
  exit 1
fi
echo "No upstream changes."
