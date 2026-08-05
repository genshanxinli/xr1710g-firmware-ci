#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib-upstreams.sh"

DEST="${1:?Usage: clone-base.sh <dest-dir>}"

if [ -e "$DEST" ] && [ -n "$(ls -A "$DEST" 2>/dev/null)" ]; then
  echo "ERROR: destination is not empty: $DEST" >&2
  exit 1
fi

REPO="$(upstream_key fanboy_repo)"
SHA="$(lock_sha fanboy)"
mkdir -p "$DEST"
git init -q "$DEST"
git -C "$DEST" remote add origin "https://github.com/$REPO.git"
GIT_TERMINAL_PROMPT=0 git -C "$DEST" fetch --depth 1 origin "$SHA"
git -C "$DEST" checkout -q -b offload FETCH_HEAD
echo "Cloned fanboy offload $SHA"
