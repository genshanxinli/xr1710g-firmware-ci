#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLONE="${1:?Usage: preflight-validate.sh <openwrt-clone> [--mode=prepare|compile] [--skip-apply]}"
MODE="prepare"
SKIP_APPLY=0
REPORT="$ROOT/docs/preflight-report.md"

while [ $# -gt 1 ]; do
  case "$1" in
    --mode=*) MODE="${1#--mode=}" ;;
    --skip-apply) SKIP_APPLY=1 ;;
    --report=*) REPORT="${1#--report=}" ;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 2 ;;
  esac
  shift
done

case "$MODE" in
  prepare|compile) ;;
  *) echo "ERROR: mode must be prepare or compile" >&2; exit 2 ;;
esac

if [ ! -d "$CLONE/.git" ]; then
  echo "ERROR: preflight requires a git clone: $CLONE" >&2
  exit 1
fi
if [ ! -f "$CLONE/.config" ]; then
  echo "ERROR: clone is not configured: $CLONE/.config missing" >&2
  exit 1
fi

if [ "$SKIP_APPLY" -ne 1 ]; then
  bash "$ROOT/apply-patches.sh" "$CLONE" "$ROOT"
fi

if find "$CLONE" -name '*.rej' | grep -q .; then
  echo "ERROR: patch reject files remain after apply" >&2
  find "$CLONE" -name '*.rej' >&2
  exit 1
fi

nearest_make_target() {
  local path="$1" dir
  dir="$(dirname "$path")"
  while [ "$dir" != "." ] && [ "$dir" != "/" ]; do
    if [ -f "$CLONE/$dir/Makefile" ]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

targets=""
while IFS= read -r line; do
  path="$(printf '%s' "$line" | cut -c4-)"
  case "$path" in
    target/*)
      targets="$targets target/linux"
      ;;
    package/*|tools/*)
      t="$(nearest_make_target "$path" || true)"
      if [ -n "$t" ]; then
        targets="$targets $t"
      else
        echo "WARNING: no make target for changed path: $path"
      fi
      ;;
    feeds/*)
      t="$(nearest_make_target "$path" || true)"
      if [ -n "$t" ]; then
        targets="$targets package/${t#feeds/}"
      else
        echo "WARNING: no make target for changed path: $path"
      fi
      ;;
  esac
done < <(git -C "$CLONE" status --porcelain -- target package tools)

unique_targets=""
for t in $targets; do
  case " $unique_targets " in
    *" $t "*) ;;
    *) unique_targets="$unique_targets $t" ;;
  esac
done

mkdir -p "$(dirname "$REPORT")"
{
  echo "# Preflight Report"
  echo
  echo "Mode: $MODE"
  echo "Generated: $(date -u +'%Y-%m-%d %H:%M UTC')"
  echo
  echo "Targets:${unique_targets:- none}"
  echo
} > "$REPORT"

if [ -z "$unique_targets" ]; then
  echo "No changed OpenWrt targets to validate." >> "$REPORT"
  exit 0
fi

TMP="${TMPDIR:-/tmp}/xr1710g-preflight-$$"
mkdir -p "$TMP"
trap 'rm -rf "$TMP"' EXIT

status=0
for t in $unique_targets; do
  log="$TMP/$(printf '%s' "$t" | tr '/' '-').log"
  if ( cd "$CLONE" && make -k "$t/$MODE" V=s ) > "$log" 2>&1; then
    echo "- PASS $t/$MODE" >> "$REPORT"
  else
    echo "- FAIL $t/$MODE" >> "$REPORT"
    grep -nE "Hunk #.*FAILED|Patch failed|ERROR: .*failed to build|error:|fatal error|No rule to make target|No such file|make\[[0-9]+\]: \*\*\* .*Error [0-9]+" "$log" | tail -30 >> "$REPORT" || true
    status=1
  fi
done

exit "$status"
