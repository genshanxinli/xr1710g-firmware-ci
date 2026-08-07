#!/bin/bash
# Monitor further-upstream activity relevant to the XR1710G CI tree.
#
# Watches: openwrt/mt76 HEAD, Linux 6.18.x releases, OpenWrt PRs #22397
# (Gemtek XR1710G official support), #22697 (NPU firmware fix), #24571
# (FW_LOADER_USER_HELPER_FALLBACK), issue #24079 (W1700K 1G ports no
# carrier) and open W1700K-related PRs in openwrt/openwrt.
#
# Baseline lives in docs/upstream-monitor.state. On change the script
# rewrites the baseline and prints a digest with suggested actions,
# exiting 1 so the workflow can commit the baseline and open an issue.
# Exit 0 means no changes.
#
# Usage: monitor-upstream.sh [repo-root]
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
STATE="$ROOT/docs/upstream-monitor.state"

MT76_REPO="https://github.com/openwrt/mt76.git"
OW_REPO="openwrt/openwrt"

get_mt76_head() { git ls-remote "$MT76_REPO" HEAD 2>/dev/null | awk '{print $1}'; }
get_kernel_618() {
  curl -fsSL https://cdn.kernel.org/pub/linux/kernel/v6.x/ 2>/dev/null \
    | grep -oE 'linux-6\.18\.[0-9]+\.tar\.xz' | sort -V | tail -1 \
    | sed 's/linux-//; s/\.tar\.xz//' || echo ""
}
get_pr_state() { gh pr view "$1" --repo "$OW_REPO" --json state -q .state 2>/dev/null || echo "unknown"; }
get_issue_state() { gh issue view "$1" --repo "$OW_REPO" --json state -q .state 2>/dev/null || echo "unknown"; }
get_branch_sha() { git ls-remote "$1" "$2" 2>/dev/null | awk '{print $1}'; }
get_w1700k_prs() {
  gh api "search/issues?q=repo:$OW_REPO+is:pr+w1700k+is:open&per_page=10" \
    --jq '[.items[].number] | sort | join(",")' 2>/dev/null || echo ""
}

echo "monitor-upstream: querying further-upstream state..."
MT76_HEAD="$(get_mt76_head)"
KERNEL_618="$(get_kernel_618)"
P22397="$(get_pr_state 22397)"
P22697="$(get_pr_state 22697)"
P24571="$(get_pr_state 24571)"
P24593="$(get_pr_state 24593)"
I24079="$(get_issue_state 24079)"
W1700K="$(get_w1700k_prs)"
FANBOY_AUTO="$(get_branch_sha "https://github.com/OpenWRT-fanboy/OpenW1700k.git" "refs/heads/ubi2-oc-auto")"

if [ -z "$MT76_HEAD" ]; then echo "ERROR: could not query mt76 HEAD" >&2; exit 2; fi

new_state() {
  printf 'mt76_head=%s\nkernel_618=%s\npr_22397=%s\npr_22697=%s\npr_24571=%s\npr_24593=%s\nissue_24079=%s\nw1700k_prs=%s\nfanboy_auto=%s\n' \
    "$MT76_HEAD" "$KERNEL_618" "$P22397" "$P22697" "$P24571" "$P24593" "$I24079" "$W1700K" "$FANBOY_AUTO"
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

OLD="$(old_state)"
NEW="$(new_state)"

if [ -n "$OLD" ] && [ "$OLD" = "$NEW" ]; then
  echo "no changes (mt76=$MT76_HEAD kernel=$KERNEL_618 pr=$P22397/$P22697/$P24571 issue=$I24079)"
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
    printf '  %-12s %s -> %s\n' "$key" "${oldval:-<none>}" "$newval"
    changed=1
  fi
done <<< "$NEW"

echo "--- suggested actions ---"
[ "$P22397" != "open" ] && echo "  #22397 (XR1710G official support): now $P22397 -> if merged, run three-way alignment (official vs fanboy vs ours), rework overlay on official base"
[ "$P22697" != "open" ] && echo "  #22697 (NPU firmware fix): now $P22697 -> check patches/yyh/kernel/921-net-airoha-npu-fix-firmware-loading-issue.patch for duplication"
[ "$P24571" != "open" ] && echo "  #24571 (FW_LOADER_USER_HELPER_FALLBACK): now $P24571 -> evaluate overlap with yyh 921 NPU patch; verify NPU probe on device"
[ "$P24593" != "open" ] && echo "  #24593 (NPU Wi-Fi memory only on WiFi board): now $P24593 -> evaluate NPU memory/offload impact"
[ "$I24079" != "open" ] && echo "  #24079 (W1700K 1G ports no carrier): now $I24079 -> mirror upstream fix into runtime validation checklist (1G carrier test)"
[ "$MT76_HEAD" != "$(field "$OLD" mt76_head)" ] && echo "  mt76 advanced to $MT76_HEAD -> wait for fanboy bump, then re-verify 22-patch sequence incl. upstream-backports"
[ "$KERNEL_618" != "$(field "$OLD" kernel_618)" ] && echo "  kernel $KERNEL_618 released -> pre-verify 205-patch kernel sequence on new tarball"
[ "$FANBOY_AUTO" != "$(field "$OLD" fanboy_auto)" ] && echo "  fanboy ubi2-oc-auto advanced to $FANBOY_AUTO -> evaluate migration (ubi2 layout, 9 dropped experimental patches, mt76 0015)"
echo "--- end digest ---"

mkdir -p "$ROOT/docs"
new_state > "$STATE"
exit 1
