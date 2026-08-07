#!/bin/bash
# Keep the GitHub Actions cache under control. GitHub enforces a hard
# 10 GB per-repo limit and evicts LRU entries past it, which silently
# deleted the active base's ccache (observed 49% hit rate and 18 min
# toolchain rebuilds as a result).
#
# Policy per key prefix:
#   ccache-      keep the newest $KEEP_CCACHE entries (default 3)
#   toolchain-   keep the newest $KEEP_TOOLCHAIN entries (default 3:
#                rebuilding a toolchain costs ~18 min, so tolerate extra
#                generations to cover base-SHA transitions)
#   dl-          keep the newest $KEEP_DL entries (default 2)
#   feeds-       keep the newest $KEEP_FEEDS entries (default 2)
#
# Two guards against cross-branch damage (GitHub scopes caches to the
# creating branch + the default branch, so a run on one branch cannot
# see entries created on another):
#   - entries accessed within $PROTECT_HOURS (default 48) are never
#     deleted, even if they exceed the keep counts (another branch is
#     actively using them).
#
# Requires gh CLI (preinstalled on runners) and a GITHUB_TOKEN with
# actions:write. Set DRY_RUN=1 to print deletions without performing them.
#
# Usage: prune-caches.sh
set -euo pipefail
GH_TOKEN="${GH_TOKEN:?prune-caches.sh requires GH_TOKEN (github.token)}"
REPO="${GITHUB_REPOSITORY:?prune-caches.sh requires GITHUB_REPOSITORY}"
KEEP_CCACHE="${KEEP_CCACHE:-3}"
KEEP_TOOLCHAIN="${KEEP_TOOLCHAIN:-3}"
KEEP_DL="${KEEP_DL:-2}"
KEEP_FEEDS="${KEEP_FEEDS:-2}"
PROTECT_HOURS="${PROTECT_HOURS:-48}"

entries() {
  gh api --paginate "repos/$REPO/actions/caches?per_page=100" \
    --jq '.actions_caches[] | [.id, .key, .created_at, .last_accessed_at] | @tsv'
}

NOW="$(date -u +%s)"

# keep <prefix> <count> <entries-tsv>: print ids to KEEP, delete the rest,
# skipping entries accessed within PROTECT_HOURS.
prune_prefix() {
  local prefix="$1" keep="$2"
  local all keep_ids id key created accessed
  all="$(entries | awk -F'\t' -v p="$prefix" 'index($2,p)==1 {print}')"
  [ -z "$all" ] && return 0
  # Newest `keep` entries by created_at are the default survivors.
  keep_ids="$(printf '%s\n' "$all" | sort -k3 -r | head -n "$keep" | cut -f1)"
  while IFS=$'\t' read -r id key created accessed; do
    if printf '%s\n' "$keep_ids" | grep -qx "$id"; then
      continue
    fi
    # Active entries (recently accessed by any branch) are protected.
    if [ -n "$accessed" ] && [ "$accessed" != "-" ]; then
      local t age
      # On parse failure treat as active (protect) rather than deleting.
      t="$(date -u -d "$accessed" +%s 2>/dev/null || echo "$NOW")"
      age=$(( NOW - t ))
      if [ "$age" -le $((PROTECT_HOURS * 3600)) ]; then
        echo "prune: keep $key (accessed $accessed, within ${PROTECT_HOURS}h)"
        continue
      fi
    fi
    echo "prune: delete $key (id=$id, created $created)"
    if [ "${DRY_RUN:-0}" = "1" ]; then
      echo "prune: DRY_RUN, not deleting"
    else
      gh api -X DELETE "repos/$REPO/actions/caches/$id" \
        || echo "prune: WARN failed to delete $id"
    fi
  done <<< "$all"
}

prune_prefix "ccache-" "$KEEP_CCACHE"
prune_prefix "toolchain-" "$KEEP_TOOLCHAIN"
prune_prefix "dl-" "$KEEP_DL"
prune_prefix "feeds-" "$KEEP_FEEDS"
