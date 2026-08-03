#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib-upstreams.sh"

if [ "${1:-}" = "--check" ]; then
  exec "$SCRIPT_DIR/check-upstream.sh"
fi

echo "Refreshing upstream overlays..."
bash "$SCRIPT_DIR/extract-overlay.sh"

for name in fanboy hurryman yyh; do
  sha="$(upstream_sha "$name")"
  if [ -z "$sha" ]; then
    echo "ERROR: could not resolve $name" >&2
    exit 2
  fi
  write_lock "$name" "$sha"
  echo "lock $name=$sha"
done

echo "Upstream lock and overlays refreshed."
