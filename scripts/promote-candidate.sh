#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REL="${1:?Usage: promote-candidate.sh <candidate-rel-path>}"
SRC="$ROOT/candidates/$REL"

if [ ! -f "$SRC" ]; then
  echo "ERROR: candidate not found: $SRC" >&2
  exit 1
fi

case "$REL" in
  patches/*)
    DEST="$ROOT/$REL"
    ;;
  *)
    DEST="$ROOT/overlay/$REL"
    ;;
esac

if [ -e "$DEST" ]; then
  echo "ERROR: destination already exists: $DEST" >&2
  exit 1
fi

mkdir -p "$(dirname "$DEST")"
if git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1; then
  git -C "$ROOT" mv "$SRC" "$DEST"
else
  mv "$SRC" "$DEST"
fi
echo "Promoted $REL -> ${DEST#"$ROOT"/}"
