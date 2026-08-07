#!/bin/bash
# Monitor further-upstream activity relevant to the XR1710G CI tree.
#
# Watches: openwrt/mt76 HEAD, Linux 6.18.x releases, OpenWrt PRs #22397
# (Gemtek XR1710G official support), #22697 (NPU firmware fix), #24571
# (FW_LOADER_USER_HELPER_FALLBACK), #23644 (rtl8261ce phy), #24593 (NPU
# memory + firmware loading), #23141 (npu_binary 1MiB), issue #24079
# (W1700K 1G ports no carrier) and open W1700K-related PRs in
# openwrt/openwrt. Also watches: hurrian/openwrt-w1700k branches
# xr1710g/xr1710g-plus/xr1710g-safe, naoki66/ImmortalWrt-for-Gemtek-XR1710G
# default-branch head, OpenWRT-fanboy/mt76-firmware branch 260806, the
# full branch snapshot of OpenWRT-fanboy/OpenW1700k (main/offload.*/
# ubi2-oc*/ubi2/w1701k/tiger/...), and cmonroe activity (events
# timestamp).
#
# Baseline lives in docs/upstream-monitor.state. On change the script
# rewrites the baseline and prints a digest with suggested actions,
# exiting 1 so the workflow can commit the baseline and open an issue.
# Exit 0 means no changes.
#
# New watchers are best-effort: any query failure degrades to "unknown"
# instead of failing the script. The mt76_head query is the one hard
# dependency (exit 2 when unreachable, preserved from the original).
#
# Usage: monitor-upstream.sh [repo-root]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
STATE="$ROOT/docs/upstream-monitor.state"

MT76_REPO="https://github.com/openwrt/mt76.git"
OW_REPO="openwrt/openwrt"
HURRIAN_REPO="https://github.com/hurrian/openwrt-w1700k.git"
MF_FW_REPO="https://github.com/OpenWRT-fanboy/mt76-firmware.git"
FB_REPO="https://github.com/OpenWRT-fanboy/OpenW1700k.git"

get_mt76_head() {
  # Retry once: CI runners occasionally hit transient network failures.
  local head
  head="$(git ls-remote "$MT76_REPO" HEAD 2>/dev/null | awk '{print $1}')"
  if [ -z "$head" ]; then
    sleep 3
    head="$(git ls-remote "$MT76_REPO" HEAD 2>/dev/null | awk '{print $1}')"
  fi
  echo "$head"
}
get_branch_sha() { git ls-remote "$1" "$2" 2>/dev/null | awk '{print $1}'; }
get_kernel_618() {
  curl -fsSL https://cdn.kernel.org/pub/linux/kernel/v6.x/ 2>/dev/null \
    | grep -oE 'linux-6\.18\.[0-9]+\.tar\.xz' | sort -V | tail -1 \
    | sed 's/linux-//; s/\.tar\.xz//' || echo ""
}
get_pr_state() { gh pr view "$1" --repo "$OW_REPO" --json state -q .state 2>/dev/null || echo "unknown"; }
get_issue_state() { gh issue view "$1" --repo "$OW_REPO" --json state -q .state 2>/dev/null || echo "unknown"; }
get_w1700k_prs() {
  gh api "search/issues?q=repo:$OW_REPO+is:pr+w1700k+is:open&per_page=10" \
    --jq '[.items[].number] | sort | join(",")' 2>/dev/null || echo ""
}
get_branch_head() {
  # $1 = repo URL, $2 = ref (e.g. refs/heads/xr1710g). Failed query or
  # missing ref degrades to "unknown"; never fails the script.
  local sha
  sha="$(git ls-remote "$1" "$2" 2>/dev/null | awk '{print $1}')" || { echo "unknown"; return; }
  [ -n "$sha" ] && echo "$sha" || echo "unknown"
}
get_hurrian_head() { get_branch_head "$HURRIAN_REPO" "refs/heads/$1"; }
get_naoki66_head() {
  # Default-branch head of the ImmortalWrt port (commits?per_page=1).
  local sha
  sha="$(gh api "repos/naoki66/ImmortalWrt-for-Gemtek-XR1710G/commits?per_page=1" --jq '.[0].sha // ""' 2>/dev/null)" || { echo "unknown"; return; }
  [ -n "$sha" ] && echo "$sha" || echo "unknown"
}
get_mf_260806_head() { get_branch_head "$MF_FW_REPO" "refs/heads/260806"; }
get_cmonroe_active() {
  # Recent public activity date (YYYY-MM-DD). Events API is rate-limited
  # without auth; on failure degrade to "unknown".
  local ts
  ts="$(gh api 'users/cmonroe/events?per_page=1' --jq '.[0].created_at // ""' 2>/dev/null)" || { echo "unknown"; return; }
  [ -n "$ts" ] && echo "${ts:0:10}" || echo "unknown"
}
get_fanboy_branches() {
  # Full branch snapshot of OpenWRT-fanboy/OpenW1700k: sorted,
  # comma-separated 分支名=SHA list so an identical tree always renders
  # an identical blob. Failed/empty query degrades to "unknown".
  local out
  out="$(git ls-remote "$FB_REPO" 'refs/heads/*' 2>/dev/null \
    | awk '{sub("refs/heads/","",$2); print $2 "=" $1}' | sort)" || { echo "unknown"; return; }
  [ -n "$out" ] && printf '%s' "$out" | paste -sd, - || echo "unknown"
}

echo "monitor-upstream: querying further-upstream state..."
MT76_HEAD="$(get_mt76_head)"
KERNEL_618="$(get_kernel_618)"
P22397="$(get_pr_state 22397)"
P22697="$(get_pr_state 22697)"
P24571="$(get_pr_state 24571)"
I24079="$(get_issue_state 24079)"
W1700K="$(get_w1700k_prs)"
H_XR1710G="$(get_hurrian_head xr1710g)"
H_XR1710G_PLUS="$(get_hurrian_head xr1710g-plus)"
H_XR1710G_SAFE="$(get_hurrian_head xr1710g-safe)"
NAOKI66="$(get_naoki66_head)"
P23644="$(get_pr_state 23644)"
P24593="$(get_pr_state 24593)"
P23141="$(get_pr_state 23141)"
MF_260806="$(get_mf_260806_head)"
FANBOY_BRANCHES="$(get_fanboy_branches)"
FB_COUNT="$(printf '%s' "$FANBOY_BRANCHES" | tr ',' '\n' | grep -c . || true)"
CMONROE="$(get_cmonroe_active)"
FANBOY_AUTO="$(get_branch_sha "https://github.com/OpenWRT-fanboy/OpenW1700k.git" "refs/heads/ubi2-oc-auto")"

if [ -z "$MT76_HEAD" ]; then echo "ERROR: could not query mt76 HEAD" >&2; exit 2; fi

new_state() {
  printf 'mt76_head=%s\nkernel_618=%s\npr_22397=%s\npr_22697=%s\npr_24571=%s\nissue_24079=%s\nw1700k_prs=%s\n' \
    "$MT76_HEAD" "$KERNEL_618" "$P22397" "$P22697" "$P24571" "$I24079" "$W1700K"
  printf 'hurrian_xr1710g=%s\nhurrian_xr1710g_plus=%s\nhurrian_xr1710g_safe=%s\nnaoki66_head=%s\n' \
    "$H_XR1710G" "$H_XR1710G_PLUS" "$H_XR1710G_SAFE" "$NAOKI66"
  printf 'pr_23644=%s\npr_24593=%s\npr_23141=%s\nmf_260806=%s\nfanboy_branches=%s\ncmonroe_active=%s\nfanboy_auto=%s\n' \
    "$P23644" "$P24593" "$P23141" "$MF_260806" "$FANBOY_BRANCHES" "$CMONROE" "$FANBOY_AUTO"
}

old_state() {
  if [ -f "$STATE" ]; then cat "$STATE"; else echo ""; fi
}

field() {
  # Pure-bash parse: pipefail + command substitution makes pipelines
  # fail hard on no-match (grep exits 1), so avoid pipes here.
  local line
  while IFS= read -r line; do
    case "$line" in
      "$2="*) echo "${line#*=}"; return 0 ;;
    esac
  done <<< "$1"
  return 0
}

fb_lines() {
  # $1 = comma-separated 分支名=SHA blob, $2 = grep -E branch-name pattern.
  # Prints matching 分支名=SHA lines; no-match exits 0 (pipefail-safe).
  printf '%s' "$1" | tr ',' '\n' | grep -E "$2" || true
}
fb_field() {
  # $1 = comma-separated 分支名=SHA blob, $2 = branch name; old SHA or "".
  field "$(printf '%s' "$1" | tr ',' '\n')" "$2"
}
fb_pattern_changed() {
  # $1 = grep -E branch-name pattern; true when any matching branch moved.
  [ "$(fb_lines "$(field "$OLD" fanboy_branches)" "$1")" != "$(fb_lines "$FANBOY_BRANCHES" "$1")" ]
}
fanboy_branches_diff() {
  # $1 = old blob, $2 = new blob. Lists moved branches individually,
  # including newly added (<none> -> sha) and deleted (sha -> <deleted>).
  local old_blob="$1" new_blob="$2" entry branch oldsha newsha seen=","
  [ "$old_blob" = "unknown" ] && old_blob=""
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    branch="${entry%%=*}"; newsha="${entry#*=}"
    seen="$seen$branch,"
    if [ -z "$old_blob" ]; then
      printf '  %-20s %s -> %s\n' "fb/$branch" "<none>" "$newsha"
    else
      oldsha="$(fb_field "$old_blob" "$branch")"
      if [ -z "$oldsha" ]; then
        printf '  %-20s %s -> %s\n' "fb/$branch" "<none>" "$newsha"
      elif [ "$oldsha" != "$newsha" ]; then
        printf '  %-20s %s -> %s\n' "fb/$branch" "$oldsha" "$newsha"
      fi
    fi
  done <<< "$(printf '%s' "$new_blob" | tr ',' '\n')"
  while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    branch="${entry%%=*}"
    case "$seen" in
      *",$branch,"*) ;;
      *) printf '  %-20s %s -> %s\n' "fb/$branch" "${entry#*=}" "<deleted>" ;;
    esac
  done <<< "$(printf '%s' "$old_blob" | tr ',' '\n')"
}

OLD="$(old_state)"
NEW="$(new_state)"

if [ -n "$OLD" ] && [ "$OLD" = "$NEW" ]; then
  echo "no changes (mt76=$MT76_HEAD kernel=$KERNEL_618 pr=$P22397/$P22697/$P24571/$P23644/$P24593/$P23141 issue=$I24079 hurrian=$H_XR1710G naoki66=$NAOKI66 fanboy=${FB_COUNT}b)"
  exit 0
fi

echo "--- upstream monitor digest ---"
[ -z "$OLD" ] && echo "initial baseline"
changed=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  key="${line%%=*}"; newval="${line#*=}"
  oldval="$(field "$OLD" "$key")"
  if [ -z "$OLD" ] || [ "$oldval" != "$newval" ]; then
    if [ "$key" = "fanboy_branches" ] && [ "$newval" != "unknown" ] && [ -n "$newval" ]; then
      fanboy_branches_diff "$oldval" "$newval"
    else
      printf '  %-20s %s -> %s\n' "$key" "${oldval:-<none>}" "$newval"
    fi
    changed=1
  fi
done <<< "$NEW"

echo "--- suggested actions ---"
[ "$P22397" != "OPEN" ] && echo "  #22397 (XR1710G official support): now $P22397 -> if merged, run three-way alignment (official vs fanboy vs ours), rework overlay on official base"
[ "$P22697" != "OPEN" ] && echo "  #22697 (NPU firmware fix): now $P22697 -> check patches/yyh/kernel/921-net-airoha-npu-fix-firmware-loading-issue.patch for duplication"
[ "$P24571" != "OPEN" ] && echo "  #24571 (FW_LOADER_USER_HELPER_FALLBACK): now $P24571 -> evaluate overlap with yyh 921 NPU patch; verify NPU probe on device"
[ "$I24079" != "OPEN" ] && echo "  #24079 (W1700K 1G ports no carrier): now $I24079 -> mirror upstream fix into runtime validation checklist (1G carrier test)"
[ "$MT76_HEAD" != "$(field "$OLD" mt76_head)" ] && echo "  mt76 advanced to $MT76_HEAD -> wait for fanboy bump, then re-verify 22-patch sequence incl. upstream-backports"
[ "$KERNEL_618" != "$(field "$OLD" kernel_618)" ] && echo "  kernel $KERNEL_618 released -> pre-verify 205-patch kernel sequence on new tarball"
hurrian_action() {
  # $1 = state key, $2 = branch display name, $3 = current sha.
  # if-based so the function always returns 0 under set -e.
  if [ "$3" != "unknown" ] && [ "$3" != "$(field "$OLD" "$1")" ]; then
    echo "  hurrian $2 advanced to $3 -> compare against YYH xr1710g-6.18-integration, check for XR1710G-specific fixes not yet absorbed"
  fi
}
hurrian_action hurrian_xr1710g xr1710g "$H_XR1710G"
hurrian_action hurrian_xr1710g_plus xr1710g-plus "$H_XR1710G_PLUS"
hurrian_action hurrian_xr1710g_safe xr1710g-safe "$H_XR1710G_SAFE"
[ "$NAOKI66" != "unknown" ] && [ "$NAOKI66" != "$(field "$OLD" naoki66_head)" ] \
  && echo "  naoki66 advanced to $NAOKI66 -> check ImmortalWrt-based fixes (esp. mt76/LuCI Chinese apps) for backport candidates"
[ "$P23644" = "MERGED" ] && echo "  #23644 (rtl8261ce phy): MERGED -> RTL8261CE now in tree: re-evaluate kmod-phy-rtl8261ce inclusion for HW2.0 units"
[ "$P24593" = "MERGED" ] && echo "  #24593 (NPU memory + firmware loading): MERGED -> supersede.list: drop patches/yyh/kernel/921-* (upstream duplicate); verify local dts includes an7581-npu-mt7996.dtsi"
[ "$P23141" = "MERGED" ] && echo "  #23141 (npu_binary 1MiB): MERGED -> absorb npu_binary 10->1MiB memory win"
[ "$MF_260806" != "unknown" ] && [ "$MF_260806" != "$(field "$OLD" mf_260806)" ] \
  && echo "  mt76-firmware 260806 advanced to $MF_260806 -> mt76-firmware firmware branch updated: re-evaluate enabling (D4 follow-up)"
# fanboy branch line: any HEAD movement in the tracked line fires an action.
# if-based (not a trailing && compound) so set -e never aborts mid-digest.
if [ "$FANBOY_BRANCHES" != "unknown" ] && [ "$FANBOY_BRANCHES" != "$(field "$OLD" fanboy_branches)" ]; then
  fb_pattern_changed '^(offload|ubi2-oc)' && echo "  fanboy offload/ubi2-oc line advanced -> evaluate absorbing upstream work or switching baseline (currently locked to ubi2-oc)"
  fb_pattern_changed '^main=' && echo "  fanboy main advanced -> plain openwrt master mirror, expect periodic drift (no dedicated action)"
  fb_pattern_changed '^(offload|ubi2-oc)' || fb_pattern_changed '^main=' || echo "  fanboy peripheral branches (w1701k/tiger/snapshot/ubi2/...) moved -> low priority, monitor only"
fi
[ "$CMONROE" != "unknown" ] && [ "$CMONROE" != "$(field "$OLD" cmonroe_active)" ] \
  && echo "  cmonroe active again ($CMONROE) -> check target-airoha for new pushes/XR1710G config hints"
[ "$FANBOY_AUTO" != "$(field "$OLD" fanboy_auto)" ] && echo "  fanboy ubi2-oc-auto advanced to $FANBOY_AUTO -> evaluate migration (ubi2 layout, 9 dropped experimental patches, mt76 0015)"
echo "--- end digest ---"

mkdir -p "$ROOT/docs"
new_state > "$STATE"
exit 1
