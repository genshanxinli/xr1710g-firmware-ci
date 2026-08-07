#!/bin/bash
# Apply XR1710G CI overlays to a fanboy ubi2-oc OpenWrt clone.
# Usage: apply-patches.sh <openwrt-clone> [<repo-root>]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLONE="${1:?Usage: apply-patches.sh <openwrt-clone> [<repo-root>]}"
ROOT="${2:-$SCRIPT_DIR}"
OVERLAY="$ROOT/overlay"
PATCHES="$ROOT/patches"
# Data-driven supersede governance list (format documented in supersede.list).
SUPERSEDE_LIST="$ROOT/supersede.list"

if [ ! -d "$CLONE" ]; then
  echo "ERROR: clone directory not found: $CLONE"
  exit 1
fi

copy_overlay() {
  local src="$1" name="$2" rel
  [ -d "$src" ] || return 0
  echo "[copy] $name"
  while IFS= read -r -d '' rel; do
    rel="${rel#./}"
    if [ ! -e "$CLONE/$rel" ]; then
      mkdir -p "$CLONE/$(dirname "$rel")"
      cp -p "$src/$rel" "$CLONE/$rel"
    fi
  done < <(cd "$src" && find . -type f -not -path '*/.git/*' -not -path '*/.github/*' -not -path '*/.devcontainer/*' -not -path '*/.vscode/*' -print0)
}

copy_patch_files() {
  local src="$1" dst="$2" p
  [ -d "$src" ] || return 0
  mkdir -p "$dst"
  for p in "$src"/*.patch; do
    [ -f "$p" ] || continue
    if [ ! -e "$dst/$(basename "$p")" ]; then
      cp -p "$p" "$dst/"
    else
      echo "  skip existing target patch: $(basename "$p")"
    fi
  done
}

remove_conflicting_patch() {
  local dst="$1" reason="$2"
  if [ -f "$CLONE/$dst" ]; then
    rm -f "$CLONE/$dst"
    echo "  removed upstream patch: $dst ($reason)"
  else
    echo "  upstream patch already absent: $dst"
  fi
}

apply_patch_dir() {
  local dir="$1" name="$2" p
  [ -d "$dir" ] || return 0
  echo "[patch] $name"
  while IFS= read -r -d '' p; do
    if ! patch -p1 --batch --forward -d "$CLONE" < "$p" > /tmp/patch-$$.log 2>&1; then
      if grep -qiE "Reversed|previously applied|already exists|Skipping patch|hunk ignored" /tmp/patch-$$.log; then
        echo "  skip already applied: $(basename "$p")"
        # Re-applying onto an already-patched tree can leave stale .rej files;
        # clean them so the final reject check does not false-positive.
        find "$CLONE" -name "*.rej" -delete 2>/dev/null || true
        rm -f /tmp/patch-$$.log
        continue
      fi
      echo "FAILED patch: $p"
      cat /tmp/patch-$$.log
      rm -f /tmp/patch-$$.log
      exit 1
    fi
    rm -f /tmp/patch-$$.log
  done < <(find "$dir" -type f -name '*.patch' -print0 | sort -z)
}

# === data-driven supersede governance ===
# supersede.list format (full spec in supersede.list header):
#   <clone-relative-target> | <reason> | <condition>
# conditions: always | file:<glob-path> | kernel>=X.Y.Z
# optional verify: prefix on the condition -> warn only, never delete.
# Exit codes of supersede_condition_met: 0=met, 1=not met, 2=unknown/malformed.

trim() {
  # Strip leading/trailing whitespace (parameter expansion only, no forks).
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

majmin_of() {
  # "6.18.42" -> "6.18"
  local v="$1"
  local rest="${v#*.}"
  printf '%s.%s' "${v%%.*}" "${rest%%.*}"
}

version_ge() {
  # True iff $1 >= $2 (dotted numeric versions, GNU sort -V).
  [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]
}

get_kernel_version() {
  # Resolve the clone's kernel version for a major.minor pair, e.g. "6.18".
  # Prefers target/linux/generic/kernel-6.18 (OpenWrt layout), falls back to
  # include/kernel-6.18. Prints the version (e.g. 6.18.42), or exits 1 if no
  # version file / no parseable LINUX_VERSION-<maj.min> line.
  local majmin="$1" cand v=""
  for cand in "target/linux/generic/kernel-$majmin" "include/kernel-$majmin"; do
    if [ -f "$CLONE/$cand" ]; then
      v="$(sed -nE "s/^[[:space:]]*LINUX_VERSION-[0-9.]+[[:space:]]*[:+?]?=[[:space:]]*[\"']*([0-9][0-9.]*).*/\1/p" "$CLONE/$cand" | head -n1)"
      [ -n "$v" ] && { echo "$v"; return 0; }
    fi
  done
  return 1
}

supersede_condition_met() {
  # Note: prefix-removal tests are used instead of case/[[ ]] patterns,
  # because `>` in a case pattern or unquoted in [[ ]] is parsed as a
  # redirection/conditional operator by bash.
  local cond="$1" spec f kver majmin cur
  if [ "$cond" = "always" ]; then
    return 0
  elif [ "${cond#file:}" != "$cond" ]; then
    spec="${cond#file:}"
    [ -n "$spec" ] || return 2
    # Glob-aware existence check: the unquoted expansion matches any
    # file/dir; with no match the literal pattern stays and fails [ -e ],
    # so one loop covers both plain paths and globs.
    for f in "$CLONE"/$spec; do
      [ -e "$f" ] && return 0
    done
    return 1
  elif [ "${cond#kernel>=}" != "$cond" ]; then
    kver="${cond#kernel>=}"
    [[ "$kver" =~ ^[0-9]+(\.[0-9]+)+$ ]] || return 2
    majmin="$(majmin_of "$kver")"
    cur="$(get_kernel_version "$majmin")" || return 1
    version_ge "$cur" "$kver" || return 1
    return 0
  else
    return 2
  fi
}

resolve_superseded_patches() {
  local list="$1" line target desc cond full_cond extra verify_mode=0
  if [ ! -f "$list" ]; then
    echo "WARNING: supersede list not found: $list (skipping governance pass)"
    return 0
  fi
  echo "[supersede] resolving $list"
  while IFS= read -r line || [ -n "$line" ]; do
    line="$(trim "$line")"
    [ -n "$line" ] || continue
    case "$line" in \#*) continue ;; esac
    IFS='|' read -r target desc cond <<<"$line"
    target="$(trim "$target")"; desc="$(trim "$desc")"; cond="$(trim "$cond")"
    if [ -z "$target" ] || [ -z "$desc" ] || [ -z "$cond" ]; then
      echo "FAIL: malformed supersede entry (need: target | reason | condition): $line"
      exit 1
    fi
    full_cond="$cond"
    case "$cond" in
      verify:*) verify_mode=1; cond="${cond#verify:}" ;;
      *) verify_mode=0 ;;
    esac
    # Defense in depth: supersede.list is repo-internal, but reject
    # path traversal / absolute targets so a bad entry can never rm
    # outside $CLONE.
    case "$target" in
      *..*|/*) echo "FAIL: supersede target escapes clone root: $target"; exit 1 ;;
    esac
    if supersede_condition_met "$cond"; then
      if [ "$verify_mode" -eq 1 ]; then
        echo "  [verify] would remove superseded patch: $target ($desc; condition: $full_cond) (dry-run, not deleting)"
      elif [ -f "$CLONE/$target" ]; then
        rm -f "$CLONE/$target"
        echo "  removed superseded patch: $target ($desc)"
      elif [ -e "$ROOT/$target" ]; then
        echo "  superseded patch already absent in clone: $target (note: file exists under repo ROOT — targets must be CLONE-relative paths)"
      else
        echo "  superseded patch already absent: $target"
      fi
    elif [ "$?" -eq 2 ]; then
      echo "FAIL: unknown or malformed supersede condition \"$full_cond\" in entry: $target"
      exit 1
    else
      extra=""
      if [ "${cond#kernel>=}" != "$cond" ]; then
        local kver="${cond#kernel>=}" majmin cur=""
        if [[ "$kver" =~ ^[0-9]+(\.[0-9]+)+$ ]]; then
          majmin="$(majmin_of "$kver")"
          cur="$(get_kernel_version "$majmin" || true)"
          extra=" (clone $majmin: ${cur:-unknown})"
        fi
      fi
      echo "  keep: $target ($full_cond not met$extra)"
    fi
  done < "$list"
}

echo "Applying XR1710G overlays to $CLONE"
# Drop stale reject files from reused validation trees before applying overlays.
find "$CLONE" -name "*.rej" -delete
remove_conflicting_patch "package/firmware/wireless-regdb/patches/555-w1700k-fix.patch" "YYH 520/530 carry the same fixes"
remove_conflicting_patch "package/network/utils/iwinfo/patches/999-fix-txpower-list.patch" "YYH 101 carries the same txpower fix"
# Upstream-merged in kernel 6.18.42 (see overlay/upstream-backports pin bump).
remove_conflicting_patch "target/linux/generic/backport-6.18/625-v7.0-ppp-enable-TX-scatter-gather.patch" "merged upstream in 6.18.42"
remove_conflicting_patch "target/linux/generic/pending-6.18/303-powerpc-85xx-Add-fsl-ifc-to-common-device-ids.patch" "merged upstream in 6.18.42"
# Upstream-merged in kernel 6.18.42 (see overlay/upstream-backports pin bump).
remove_conflicting_patch "target/linux/generic/backport-6.18/625-v7.0-ppp-enable-TX-scatter-gather.patch" "merged upstream in 6.18.42"
remove_conflicting_patch "target/linux/generic/pending-6.18/303-powerpc-85xx-Add-fsl-ifc-to-common-device-ids.patch" "merged upstream in 6.18.42"
# Dropped experimental PPE-flow series (fanboy production stance):
# offload.08.06/ubi2-oc-auto abandoned 999-90..93 / 990-04/05 / 930 and
# replaced the symptom fix with mt76 0015 (avoid stale NPU wcid reuse).
remove_conflicting_patch "target/linux/airoha/patches-6.18/930-net-airoha-ppe-flush-stale-PPE-flows-on-FDB-and-STA-events.patch" "experimental series dropped (see upstream-backports 0022)"
remove_conflicting_patch "target/linux/airoha/patches-6.18/990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch" "experimental series dropped"
remove_conflicting_patch "target/linux/airoha/patches-6.18/990-05-airoha-gen-gate-ppe-flush-and-teardown-by-eth.patch" "experimental series dropped"
remove_conflicting_patch "target/linux/airoha/patches-6.18/999-90-diag-wifi-ppe-path.patch" "experimental series dropped"
remove_conflicting_patch "target/linux/airoha/patches-6.18/999-91-hash-fallback-replace-diag.patch" "experimental series dropped"
remove_conflicting_patch "target/linux/airoha/patches-6.18/999-92-reuse-stale-flow-cookie.patch" "experimental series dropped"
remove_conflicting_patch "target/linux/airoha/patches-6.18/999-93-remove-gen-gate.patch" "experimental series dropped"
remove_conflicting_patch "package/kernel/mt76/patches/0013-wifi-mt76-mt7996-flush-airoha-PPE-flows-on-STA-link-remove.patch" "experimental series dropped"
remove_conflicting_patch "package/kernel/mt76/patches/0014-wifi-mt76-flush-airoha-PPE-on-generic-sta-removal.patch" "experimental series dropped"
copy_overlay "$OVERLAY/hurryman" "hurryman new-only files"
copy_overlay "$OVERLAY/upstream-backports" "upstream backports"
apply_patch_dir "$PATCHES/hurryman" "hurryman adaptation patches"
apply_patch_dir "$PATCHES/upstream-backports" "upstream backport adaptations"
copy_overlay "$OVERLAY/yyh" "yyh new-only files"
copy_patch_files "$PATCHES/yyh/kernel" "$CLONE/target/linux/airoha/patches-6.18"
copy_patch_files "$PATCHES/yyh/regdb" "$CLONE/package/firmware/wireless-regdb/patches"
copy_patch_files "$PATCHES/yyh/mt76/patches" "$CLONE/package/kernel/mt76/patches"
# Data-driven supersede governance: runs after all copies (entries may target
# files produced by copy_patch_files, e.g. YYH kernel patches) and before the
# apply passes (future entries may target patch dirs this script applies).
resolve_superseded_patches "$SUPERSEDE_LIST"
apply_patch_dir "$PATCHES/yyh/apply" "yyh package patches"
copy_overlay "$OVERLAY/xr1710g" "xr1710g new files"
apply_patch_dir "$PATCHES/xr1710g" "xr1710g adaptation patches"

echo "Verifying key files..."
test -f "$CLONE/target/linux/airoha/dts/an7581-xr1710g-ubi.dts" \
  || { echo "FAIL: XR1710G DTS missing"; exit 1; }
grep -q "econet_xr1710g" "$CLONE/target/linux/airoha/image/an7581.mk" \
  || { echo "FAIL: XR1710G device block missing"; exit 1; }
if find "$CLONE" -name '*.rej' | grep -q .; then
  echo "FAIL: patch reject files remain after apply:"
  find "$CLONE" -name '*.rej'
  exit 1
fi
ls "$CLONE"/target/linux/airoha/patches-6.18/330-* \
   "$CLONE"/target/linux/airoha/patches-6.18/921-* >/dev/null 2>&1 \
  || { echo "FAIL: YYH kernel patch files missing"; exit 1; }
# hostapd ENFILE fix must stay present in the base tree (pr-22908 / 053);
# assert on the helper name rather than the patch file so a base rebase
# that drops it fails loudly instead of silently losing the fix.
grep -q "nl80211_use_existing_iface" "$CLONE/package/network/services/hostapd/patches/053-nl80211-Avoid-bogus-ENFILE-with-use_existing.patch" 2>/dev/null \
  || { echo "FAIL: hostapd ENFILE fix (053) missing from base tree"; exit 1; }
echo "All patches applied successfully."
