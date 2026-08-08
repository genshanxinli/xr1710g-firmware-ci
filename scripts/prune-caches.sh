#!/bin/bash
# Keep the GitHub Actions cache under control. GitHub enforces a hard
# 10 GB per-repo limit and evicts LRU entries past it, which silently
# deleted the active base's ccache (observed 49% hit rate and 18 min
# toolchain rebuilds as a result).
#
# Policy:
#   - only entries scoped to the CURRENT run's ref or the default branch
#     (refs/heads/main) are touched; other refs' entries are left to
#     GitHub's own 7-day inactivity GC, so a run on one branch can never
#     delete a cache another branch is using;
#   - within that set, per key prefix keep the newest N:
#       ccache-      $KEEP_CCACHE (default 3)
#       toolchain-   $KEEP_TOOLCHAIN (default 3: rebuilding a toolchain
#                    costs ~18 min, so tolerate extra generations to
#                    cover base-SHA transitions)
#       dl-          $KEEP_DL (default 2)
#       feeds-       $KEEP_FEEDS (default 2)
#   - entries accessed within $PROTECT_HOURS (default 48) are never
#     deleted even if they exceed the keep counts;
#   - entries with no recorded access are treated as active (protected)
#     rather than deleted.
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

CURRENT_REF="${GITHUB_REF:?prune-caches.sh requires GITHUB_REF (github.ref)}"
DEFAULT_REF="refs/heads/${DEFAULT_BRANCH:-main}"

entries() {
  gh api --paginate "repos/$REPO/actions/caches?per_page=100" \
    --jq '.actions_caches[] | [.id, .key, .created_at, .last_accessed_at, .ref] | @tsv'
}

NOW="$(date -u +%s)"

# keep <prefix> <count>: print ids to keep, delete the rest among entries
# scoped to the current ref or the default branch.
prune_prefix() {
  local prefix="$1" keep="$2"
  local all keep_ids id key created accessed ref
  # ref filter: only entries this run's scope can actually see/use.
  all="$(entries | awk -F'\t' -v p="$prefix" -v r="$CURRENT_REF" -v d="$DEFAULT_REF" \
    'index($2,p)==1 && ($5==r || $5==d) {print}')"
  [ -z "$all" ] && return 0
  # Newest `keep` entries by created_at are the default survivors.
  keep_ids="$(printf '%s\n' "$all" | sort -k3 -r | head -n "$keep" | cut -f1)"
  while IFS=$'\t' read -r id key created accessed ref; do
    if printf '%s\n' "$keep_ids" | grep -qx "$id"; then
      continue
    fi
    # Active entries (recently accessed, or access unknown) are protected.
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
    echo "prune: delete $key (id=$id, ref=$ref, created $created)"
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
# Phase-2 build_dir channels: old generations are useless after a hash
# change (cold rebuild), so one generation each is enough.
prune_prefix "tb-" 1
prune_prefix "tp-" 1
