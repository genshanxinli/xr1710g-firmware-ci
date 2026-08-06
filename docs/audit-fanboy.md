# Fanboy Upstream Delta Audit

Audit date: 2026-08-06

CI repo: D:\Agent\xr1710g_1\xr1710g-firmware-ci
CI branch: sync/2026-08-06
Upstream repo: OpenWRT-fanboy/OpenW1700k
Upstream branch: offload
Old fanboy SHA: f4c45c64394ec5046dece1a7ef80bb32af2fc6d4
New fanboy SHA: 1fcc93055cabcdf2553977245e03dcb9599e67cd

## Method

`gh api repos/OpenWRT-fanboy/OpenW1700k/compare/{old}...{new}` reports 204
files and status `diverged` (ahead_by 56, behind_by 33). Because the old
SHA is not an ancestor of the new SHA, I treated `git diff old new` in a
temporary clone as the authoritative old-to-new file delta. That direct diff
contains 51 changed paths. This report lists the paths from that delta that
intersect the CI repo or XR1710G support, and separately lists API-reported
paths that overlap current CI files but are identical in old and new.

No CI files other than this report were edited or committed during this audit.

## 1. Changed Upstream Files

The direct old-to-new fanboy delta paths relevant to this CI repo are:

| Upstream path | Status | Why it matters |
|---|---|---|
| tools/elfutils/patches/006-Fix-build-on-aarch64-musl.patch | added | Same aarch64/musl fix carried by the hurryman elfutils overlay and patch |
| target/linux/econet/files/drivers/mtd/nand/en75_bmt.c | modified | XR1710G BMT/NAND driver fix |
| package/network/config/wifi-scripts/files-ucode/usr/share/ucode/wifi/supplicant.uc | modified | Base wifi-scripts change used by the XR1710G image |
| target/linux/generic/pending-6.12/690-net-add-missing-check-for-TCP-fraglist-GRO.patch | removed | Generic kernel cleanup, no CI overlay or patch targets it |
| target/linux/generic/pending-6.18/690-net-add-missing-check-for-TCP-fraglist-GRO.patch | removed | Generic kernel cleanup, no CI overlay or patch targets it |

The remaining direct-delta paths are unrelated to XR1710G support and do not
intersect the CI overlay or patch directories.

The API compare also reports many airoha, mt76, hostapd, mac80211,
wireless-regdb, iwinfo, and LuCI paths that were already present in the old
fanboy SHA. Their old-to-new contents are identical, so they are not new
fanboy deltas, but they do overlap current CI files as described below.

## 2. CI Patch And Overlay Files That Overlap

Concrete overlaps found in the current CI repo:

| Upstream path | CI file |
|---|---|
| tools/elfutils/patches/006-Fix-build-on-aarch64-musl.patch | D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\hurryman\tools\elfutils\patches\014-aarch64-use-sys-uio.patch |
| tools/elfutils/patches/006-Fix-build-on-aarch64-musl.patch | D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\hurryman\003-hurryman-elfutils-aarch64-iovec.patch |
| package/kernel/mt76/patches/0010-enable-firmware-txpower-limit.patch | D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\0007-wifi-mt76-mt7996-enable-firmware-txpower-limit-controls.patch |
| package/kernel/mt76/patches/0011-refresh-power-limits-on-txpower-changes.patch | D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\0006-wifi-mt76-mt7996-refresh-power-limits-on-txpower-changes.patch |
| package/network/services/hostapd/patches/053-nl80211-Avoid-bogus-ENFILE-with-use_existing.patch | D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\network\services\hostapd\patches\602-nl80211-short-circuit-use-existing-iface.patch |
| package/network/services/hostapd/patches/mtk-0015-hostapd-mtk-6G-band-does-not-require-DFS.patch | D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\network\services\hostapd\patches\603-hostapd-6g-band-does-not-require-dfs.patch |
| target/linux/airoha/patches-6.18/990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch | D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\kernel\990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch |

The `apply-patches.sh` file already handles two upstream additions explicitly:

- D:\Agent\xr1710g_1\xr1710g-firmware-ci\apply-patches.sh removes
  package/firmware/wireless-regdb/patches/555-w1700k-fix.patch before applying
  the YYH wireless-regdb overlays at 510, 520, and 530.
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\apply-patches.sh removes
  package/network/utils/iwinfo/patches/999-fix-txpower-list.patch before
  applying D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\network\utils\iwinfo\patches\101-nl80211-fix-txpowerlist-wiphy-dump.patch.

Existing CI patches that still appear necessary are:

- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\apply\mt76-Makefile.patch
  because the new fanboy mt76 Makefile still has PKG_RELEASE=1.
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\apply\luci-airoha-npu-Makefile.patch,
  D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\apply\status.js.patch,
  and D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\apply\rpcd.patch
  because the new fanboy luci-app-airoha-npu tree does not contain the CI fixes.
- The existing target/linux/airoha config, DTS, image, 916-02, and 940
  adaptation patches in D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\xr1710g
  and D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\hurryman remain targeted at
  paths that are identical in old and new fanboy; they need revalidation but
  are not new delta conflicts.

## 3. Concrete Duplicate And Conflict Risks

- The elfutils 006 patch in new fanboy and CI hurryman 014 patch modify the
  same two backend files. Both would be installed into
  tools/elfutils/patches in the build tree, so the build patch machinery
  would apply a duplicate fix. Drop the hurryman overlay and adaptation
  patch once the new base is used.
- The upstream mt76 0010/0011 patches and CI yyh 0007/0006 patches target the
  same mt7996 txpower code. Leaving both in place risks reversed patch
  failures and behavior drift. The upstream 0011 version is also newer than
  the CI 0006 version; it updates global txpower handling while the CI copy
  keeps the older cached-power behavior.
- The upstream hostapd 053 and mtk-0015 patches overlap CI yyh 602 and 603.
  The hostapd hunks are effectively the same fixes, so both copies will not
  apply cleanly in one package tree. Keep the upstream copies and remove the
  CI overlay copies.
- The CI kernel patch 990-04 has the same basename as the new fanboy patch in
  target/linux/airoha/patches-6.18. `apply-patches.sh` copies new-only
  patches with `cp -p` only when the target file is absent, so the CI copy is
  silently skipped. The upstream 990-04 is also newer and includes an extra
  re-entrancy guard, so the CI copy is stale.
- The worktree already contains stale or superseded mt76 reset-channel patch
  copies: D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\0013-wifi-mt76-reset-channel-state-during-scanning.patch
  and D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\mt76\patches\0016-wifi-mt76-reset-channel-state-during-scanning.patch.
  The 0016 copy is the trimmed version that matches the current upstream mt76
  scan.c state.

## 4. Recommended Actions

1. After moving the lock to the new fanboy SHA, remove or stop applying the
   duplicate CI elfutils files:
   D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\hurryman\tools\elfutils\patches\014-aarch64-use-sys-uio.patch
   and D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\hurryman\003-hurryman-elfutils-aarch64-iovec.patch.
2. Remove the duplicate mt76 overlay patches 0006 and 0007 under
   D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches.
3. Remove the duplicate hostapd overlay patches 602 and 603 under
   D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\network\services\hostapd\patches.
4. Remove D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\kernel\990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch
   and rely on the fanboy base patch with the same basename.
5. Update D:\Agent\xr1710g_1\xr1710g-firmware-ci\scripts\extract-overlay.sh
   so a future refresh does not re-add the dropped hurryman elfutils or YYH
   duplicate patches.
6. Keep the hardcoded `remove_conflicting_patch` entries for wireless-regdb
   555 and iwinfo 999 in D:\Agent\xr1710g_1\xr1710g-firmware-ci\apply-patches.sh.
7. Re-run D:\Agent\xr1710g_1\xr1710g-firmware-ci\scripts\validate-overlay.sh
   or the preflight workflow against the new SHA after the cleanup.

Current `git status --short` already shows modified
D:\Agent\xr1710g_1\xr1710g-firmware-ci\docs\overlay-refresh.txt,
D:\Agent\xr1710g_1\xr1710g-firmware-ci\docs\upstream-changes.md, and
D:\Agent\xr1710g_1\xr1710g-firmware-ci\upstream.lock.json, plus many
untracked overlay refresh files. This audit did not modify those files.
