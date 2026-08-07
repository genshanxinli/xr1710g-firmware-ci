#!/bin/bash
# Keep the GitHub Actions cache under control. GitHub enforces a hard
# 10 GB per-repo limit and evicts LRU entries past it, which silently
# deleted the active branch's ccache (observed 49% hit rate and 18 min
# toolchain rebuilds as a result).
#
# Policy per key prefix:
#   ccache-      keep the newest $KEEP_CCACHE entries (default 2)
#   toolchain-   keep the newest $KEEP_TOOLCHAIN entries (default 2:
#                rebuilding a toolchain costs ~18 min, so tolerate one
#                extra generation to cover base-SHA transitions and
#                long-lived feature branches)
#   dl-          keep the newest 1
#   feeds-       keep the newest 1
#
# Requires gh CLI (preinstalled on runners) and a GITHUB_TOKEN with
# actions:write. Set DRY_RUN=1 to print deletions without performing them.
#
# Usage: prune-caches.sh
set -euo pipefail
GH_TOKEN="${GH_TOKEN:?prune-caches.sh requires GH_TOKEN (github.token)}"
REPO="${GITHUB_REPOSITORY:?prune-caches.sh requires GITHUB_REPOSITORY}"
KEEP_CCACHE="${KEEP_CCACHE:-2}"
KEEP_TOOLCHAIN="${KEEP_TOOLCHAIN:-2}"

entries() {
  gh api --paginate "repos/$REPO/actions/caches?per_page=100" \
    --jq '.actions_caches[] | [.id, .key, .created_at] | @tsv'
}

prune_prefix() {
  local prefix="$1" keep="$2"
  local all keep_ids id key created
  all="$(entries | awk -F'\t' -v p="$prefix" 'index($2,p)==1 {print}')"
  [ -z "$all" ] && return 0
  # Newest `keep` entries by created_at survive; the rest are deleted.
  keep_ids="$(printf '%s\n' "$all" | sort -k3 -r | head -n "$keep" | cut -f1)"
  while IFS=$'\t' read -r id key created; do
    if ! printf '%s\n' "$keep_ids" | grep -qx "$id"; then
      echo "prune: delete $key (id=$id)"
      if [ "${DRY_RUN:-0}" = "1" ]; then
        echo "prune: DRY_RUN, not deleting"
      else
        gh api -X DELETE "repos/$REPO/actions/caches/$id" \
          || echo "prune: WARN failed to delete $id"
      fi
    fi
  done <<< "$all"
}

prune_prefix "ccache-" "$KEEP_CCACHE"
prune_prefix "toolchain-" "$KEEP_TOOLCHAIN"
prune_prefix "dl-" 1
prune_prefix "feeds-" 1
