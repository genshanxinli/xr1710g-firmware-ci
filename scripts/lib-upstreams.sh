#!/bin/bash
# Shared helpers for reading upstreams.yml and upstream.lock.json.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
UPSTREAM_FILE="$ROOT/upstreams.yml"
LOCK_FILE="$ROOT/upstream.lock.json"

upstream_key() {
  awk -v key="$1" '$1==key":" { sub(/^[^:]*:[[:space:]]*/, ""); print; exit }' "$UPSTREAM_FILE"
}

upstream_sha() {
  local repo ref
  repo="$(upstream_key "$1_repo")"
  ref="$(upstream_key "$1_ref")"
  git ls-remote "https://github.com/$repo.git" "$ref" | awk '{print $1}'
}

lock_sha() {
  python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$LOCK_FILE" "$1"
}

write_lock() {
  python3 - "$LOCK_FILE" "$1" "$2" <<'PY'
import json, sys
path, key, sha = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(path, encoding='utf-8'))
data[key] = sha
data['updated_at'] = '2026-08-03T00:00:00Z'
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')
PY
}
