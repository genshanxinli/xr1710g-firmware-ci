#!/bin/bash
# Phase-2 build_dir/target incremental caching helpers.
#
# Two channels, both exact-key only (NO restore-keys fallback — restoring a
# stale tree would be a wrong-build accident, unlike content-addressed
# ccache where a miss is the worst case):
#   tb  kernel channel : build_dir/target-*/linux-* (objtree + source +
#                        Module.symvers + stamps), keyed on kernel_hash
#   tp  package channel: build_dir/target-*/package-*, */root-* +
#                        staging_dir/target-*, keyed on full hash
# .ci-meta (markers + artifact fingerprints) lives inside build_dir/target-*
# and is included in BOTH channel path lists so each channel can validate
# itself after restore.
#
# Subcommands:
#   dl-hash <dl-dir>                      content hash of dl/ (key binding,
#                                         guards same-version republish)
#   prepare-save <openwrt-dir> <kernel-hash> <full-hash>
#                                         write markers + regenerate
#                                         per-channel artifact fingerprints
#   validate <openwrt-dir> <kernel-hash> <full-hash> <tb-hit> <tp-hit>
#                                         verify restored markers and
#                                         fingerprints; wipe channels on
#                                         mismatch (cold rebuild), warn loudly
#   kernel-fingerprint <itb> <full-hash> <base-sha>
#                         extract kernel-1 sub-image sha256 from a FIT image
#                         + compare against the previous run's fingerprint
#                         artifact (canary; skipped when the base SHA
#                         differs — a base change legitimately changes the
#                         kernel), write current to /tmp/kernel-fingerprint.txt
#
# Usage: builddir-cache.sh <subcommand> [args...]
set -euo pipefail

CMD="${1:?Usage: builddir-cache.sh <subcommand> [args...]}"
shift

dl_hash() {
  local dl="${1:?dl-hash <dl-dir>}"
  if [ ! -d "$dl" ]; then
    sha256sum /dev/null | cut -d' ' -f1
    return 0
  fi
  find "$dl" -type f -print0 | sort -z | xargs -0 -r sha256sum \
    | awk '{print $1}' | sha256sum | cut -c1-16
}

meta_dir() {
  # $1 = openwrt dir; prints the .ci-meta dir if present
  ls -d "$1"/build_dir/target-*/.ci-meta 2>/dev/null | head -1 || true
}

kernel_artifacts() {
  # $1 = openwrt dir; prints sorted sha256 lines of kernel compile products
  ( cd "$1" && find build_dir/target-*/linux-* -type f \
      \( -name '*.o' -o -name '*.ko' -o -name '*.so*' -o -name '*.a' \) -print0 \
    | sort -z | xargs -0 -r sha256sum )
}

package_artifacts() {
  # $1 = openwrt dir; prints sorted sha256 lines of package compile products
  ( cd "$1" && find build_dir/target-*/package-* staging_dir/target-* -type f \
      \( -name '*.o' -o -name '*.ko' -o -name '*.so*' -o -name '*.a' \) -print0 \
    | sort -z | xargs -0 -r sha256sum )
}

prepare_save() {
  local clone="${1:?prepare-save <openwrt-dir> <kernel-hash> <full-hash>}"
  local khash="${2:?}" fhash="${3:?}"
  local meta
  meta="$(meta_dir "$clone")"
  [ -n "$meta" ] || { echo "builddir-cache: no build_dir/target-*/.ci-meta — nothing to mark"; return 0; }
  printf '%s\n' "$khash" > "$meta/kernel-hash"
  printf '%s\n' "$fhash" > "$meta/full-hash"
  kernel_artifacts "$clone" > "$meta/kernel.sha256"
  package_artifacts "$clone" > "$meta/package.sha256"
  echo "builddir-cache: markers + fingerprints written ($(wc -l < "$meta/kernel.sha256") kernel, $(wc -l < "$meta/package.sha256") package artifacts)"
}

wipe_channels() {
  local clone="$1" why="$2"
  echo "::warning::builddir-cache validation FAILED ($why) — wiping build_dir/target-* + staging_dir/target-* (cold rebuild)"
  rm -rf "$clone"/build_dir/target-* "$clone"/staging_dir/target-*
}

validate() {
  local clone="${1:?validate <openwrt-dir> <kernel-hash> <full-hash> <tb-hit> <tp-hit>}"
  local khash="${2:?}" fhash="${3:?}" tb_hit="${4:-false}" tp_hit="${5:-false}"
  local meta bad=0
  meta="$(meta_dir "$clone")"

  if [ "$tb_hit" = "true" ]; then
    if [ -z "$meta" ] || [ ! -f "$meta/kernel-hash" ] \
       || [ "$(cat "$meta/kernel-hash")" != "$khash" ]; then
      bad=1; wipe_channels "$clone" "kernel marker mismatch"
    elif ! diff -q <(kernel_artifacts "$clone") "$meta/kernel.sha256" >/dev/null 2>&1; then
      bad=1; wipe_channels "$clone" "kernel artifact fingerprint mismatch"
    else
      echo "builddir-cache: kernel channel validated OK"
    fi
  fi

  if [ "$tp_hit" = "true" ] && [ "$bad" -eq 0 ]; then
    if [ -z "$meta" ] || [ ! -f "$meta/full-hash" ] \
       || [ "$(cat "$meta/full-hash")" != "$fhash" ]; then
      wipe_channels "$clone" "package marker mismatch"
    elif ! diff -q <(package_artifacts "$clone") "$meta/package.sha256" >/dev/null 2>&1; then
      wipe_channels "$clone" "package artifact fingerprint mismatch"
    else
      echo "builddir-cache: package channel validated OK"
    fi
  fi
}

# --- canary ---------------------------------------------------------------

kernel_fingerprint() {
  local itb="${1:?kernel-fingerprint <itb> <full-hash> <base-sha>}"
  local fhash="${2:?}" base="${3:-}" cur_sha prev_file art_id prev_sha prev_hash prev_base repo py
  repo="${GITHUB_REPOSITORY:-}"
  py="$(command -v python3 2>/dev/null || command -v python 2>/dev/null)"
  [ -n "$py" ] || { echo "kernel-fingerprint: no python interpreter — canary skipped"; return 0; }
  cur_out="$("$py" - "$itb" <<'PYEOF'
import struct, sys
path = sys.argv[1]
data = open(path, 'rb').read()
magic, totalsize, off_struct, off_strings, off_memrsv, version = struct.unpack('>IIIIII', data[:24])
sb = data[off_struct:totalsize]
strs = data[off_strings:off_strings+1024]
props = {}
stack = ['']
i = 0
while i < len(sb):
    tok = struct.unpack('>I', sb[i:i+4])[0]
    i += 4
    if tok == 1:
        end = sb.index(b'\0', i)
        stack.append(sb[i:end].decode('ascii', 'replace'))
        i = (end + 4) & ~3
    elif tok == 2:
        stack.pop()
    elif tok == 3:
        plen, nameoff = struct.unpack('>II', sb[i:i+8])
        i += 8
        val = sb[i:i+plen]
        i = (i + plen + 3) & ~3
        end = strs.find(b'\0', nameoff)
        props[tuple(stack) + (strs[nameoff:end].decode('ascii', 'replace'),)] = val
    elif tok == 9:
        break

def u32(key):
    v = props.get(key)
    return struct.unpack('>I', v[:4])[0] if v and len(v) >= 4 else None

# Locate the kernel-1 image node dynamically (the FIT root may carry an
# extra unnamed node level, so a hardcoded path is fragile).
node = None
for k in props:
    if k[-1] == 'data-position' and 'kernel-1' in k:
        node = k[:-1]
        break
if node is None:
    sys.exit('kernel-1 sub-image not found in FIT')
pos, size = u32(node + ('data-position',)), u32(node + ('data-size',))
import hashlib
print(hashlib.sha256(data[pos:pos+size]).hexdigest())
PYEOF
)"
  # cur_out holds the python output (kernel-1 sub-image sha256, no trailing
  # newline after stripping).
  cur_sha="$(printf '%s' "$cur_out")"
  echo "kernel_sha256=$cur_sha" > /tmp/kernel-fingerprint.txt
  echo "full_hash=$fhash" >> /tmp/kernel-fingerprint.txt
  echo "base=$base" >> /tmp/kernel-fingerprint.txt

  if [ -z "$repo" ]; then
    echo "kernel-fingerprint: GITHUB_REPOSITORY unset — no canary compare"
    return 0
  fi
  # Fetch the previous run's fingerprint artifact (newest first).
  prev_file="$(mktemp)"
  trap 'rm -f "$prev_file"' RETURN
  if ! gh api "repos/$repo/actions/artifacts?name=kernel-fingerprint&per_page=1" \
      --jq '.artifacts[0].id // empty' > "$prev_file" 2>/dev/null; then
    echo "kernel-fingerprint: cannot query previous artifact (network?) — canary skipped"
    return 0
  fi
  local art_id
  art_id="$(cat "$prev_file")"
  [ -n "$art_id" ] || { echo "kernel-fingerprint: no previous artifact — canary baseline set"; return 0; }
  if ! gh api "repos/$repo/actions/artifacts/$art_id/zip" > "$prev_file.zip" 2>/dev/null \
     || ! unzip -p "$prev_file.zip" kernel-fingerprint.txt > "$prev_file.txt" 2>/dev/null; then
    echo "kernel-fingerprint: cannot download previous artifact — canary skipped"
    rm -f "$prev_file.zip" "$prev_file.txt"
    return 0
  fi
  prev_sha="$(sed -n 's/^kernel_sha256=//p' "$prev_file.txt" | head -1)"
  prev_hash="$(sed -n 's/^full_hash=//p' "$prev_file.txt" | head -1)"
  prev_base="$(sed -n 's/^base=//p' "$prev_file.txt" | head -1)"
  rm -f "$prev_file.zip" "$prev_file.txt"

  if [ -n "$prev_base" ] && [ "$prev_base" != "$base" ]; then
    echo "kernel-fingerprint: base changed ($prev_base -> $base) — canary compare skipped"
  elif [ -n "$prev_sha" ] && [ "$prev_sha" != "$cur_sha" ] && [ "$prev_hash" = "$fhash" ]; then
    echo "::warning::CANARY: kernel image CHANGED but inputs unchanged (full_hash same) — cache blind spot?"
  elif [ -n "$prev_sha" ] && [ "$prev_sha" = "$cur_sha" ] && [ -n "$prev_hash" ] && [ "$prev_hash" != "$fhash" ]; then
    echo "::warning::CANARY: inputs CHANGED but kernel image identical — classification under-invalidation?"
  fi
  echo "kernel-fingerprint: kernel=$cur_sha full=$fhash base=$base (prev kernel=$prev_sha full=$prev_hash base=$prev_base)"
}

case "$CMD" in
  dl-hash) dl_hash "$@" ;;
  prepare-save) prepare_save "$@" ;;
  validate) validate "$@" ;;
  kernel-fingerprint) kernel_fingerprint "$@" ;;
  *) echo "ERROR: unknown subcommand: $CMD" >&2; exit 2 ;;
esac
