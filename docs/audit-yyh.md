# YYH Upstream Delta Audit

CI repo: D:\Agent\xr1710g_1\xr1710g-firmware-ci
Upstream: YYH2913/openwrt, branch xr1710g-6.18-integration
Old YYH SHA: 2a845ee80c7c52caafe57d518a15b16738eb9ed7
New YYH SHA: 99598e539d47aa9f137baff43f0c2f77becc2e50
Date: 2026-08-06

Method: read-only git comparison plus hash checks of the current CI overlay and patch files against the old and new YYH trees. No CI source, overlay, or patch files were modified for this audit.

## 1. Changed Upstream Files

The YYH SHAs have diverged, so I used both the requested GitHub compare API result and a two-dot `git diff` in a temporary clone. The list below includes old-to-new changes plus files that exist at the new SHA and were newly copied into the CI overlay by the refresh.

Directly relevant upstream paths:

- YYH2913/openwrt:package/kernel/mac80211/patches/subsys/411-mac80211-export-link-sta-capability-limits.patch
- YYH2913/openwrt:package/kernel/mt76/patches/0005-wifi-mt76-mt7996-fix-capability-of-EHT-MCS-15-in-MRU.patch
- YYH2913/openwrt:package/kernel/mt76/patches/0006-wifi-mt76-mt7996-refresh-power-limits-on-txpower-changes.patch
- YYH2913/openwrt:package/kernel/mt76/patches/0007-wifi-mt76-mt7996-enable-firmware-txpower-limit-controls.patch
- YYH2913/openwrt:package/kernel/mt76/patches/0013-wifi-mt76-reset-channel-state-during-scanning.patch
- YYH2913/openwrt:package/kernel/mt76/patches/0047-mtk-mt76-fix-RX-data-queuing-of-RRO-3.0.patch
- YYH2913/openwrt:package/kernel/mt76/patches/0083-mtk-mt76-remove-unnecessary-wcid-asignment.patch
- YYH2913/openwrt:package/kernel/mt76/patches/9992-wifi-mt76-mt7996-validate-PS-sync-event-TLVs.patch
- YYH2913/openwrt:package/kernel/mt76/patches/9993-wifi-mt76-mt7996-pass-operating-mode-to-rate-control.patch
- YYH2913/openwrt:package/network/services/hostapd/patches/602-nl80211-short-circuit-use-existing-iface.patch
- YYH2913/openwrt:package/network/services/hostapd/patches/603-hostapd-6g-band-does-not-require-dfs.patch
- YYH2913/openwrt:package/firmware/wireless-regdb/patches/510-us-regd-6GHz.patch
- YYH2913/openwrt:package/firmware/wireless-regdb/patches/520-w1700k-us-power-limits.patch
- YYH2913/openwrt:package/firmware/wireless-regdb/patches/530-us-6ghz-lab-indoor-sp-override.patch
- YYH2913/openwrt:package/network/utils/iwinfo/patches/101-nl80211-fix-txpowerlist-wiphy-dump.patch
- YYH2913/openwrt:target/linux/airoha/an7581/base-files/etc/uci-defaults/18-xr1710g-firewall-defaults
- YYH2913/openwrt:target/linux/airoha/an7581/base-files/etc/uci-defaults/19-xr1710g-luci-language
- YYH2913/openwrt:target/linux/airoha/an7581/base-files/usr/libexec/platform/packet-steering.sh
- YYH2913/openwrt:target/linux/airoha/an7581/base-files/usr/sbin/xr1710g-net-debug
- YYH2913/openwrt:target/linux/airoha/dts/an7581-xr1710g-ubi.dts
- YYH2913/openwrt:target/linux/airoha/image/an7581.mk
- YYH2913/openwrt:target/linux/airoha/an7581/config-6.18
- YYH2913/openwrt:target/linux/airoha/an7581/base-files/etc/board.d/02_network
- YYH2913/openwrt:target/linux/airoha/an7581/base-files/lib/upgrade/platform.sh
- YYH2913/openwrt:target/linux/airoha/an7581/base-files/etc/init.d/airoha_fan
- YYH2913/openwrt:target/linux/airoha/patches-6.18/922-net-airoha-classify-external-lan-ports-from-DT.patch
- YYH2913/openwrt:package/luci-app-airoha-npu/htdocs/luci-static/resources/view/airoha_npu/status.js
- YYH2913/openwrt:package/luci-app-airoha-npu/root/usr/libexec/rpcd/luci.airoha_npu

Other YYH changes that touch the XR1710G build but have no current CI overlay or patch file are under:

- YYH2913/openwrt:package/network/config/wifi-scripts/... (hostapd.uc, mac80211.sh, and related ucode)
- YYH2913/openwrt:target/linux/airoha/patches-6.18/9990-net-airoha-bind-WLAN-bound-flows-on-PPE-driver-L2-cache-miss.patch
- YYH2913/openwrt:target/linux/airoha/patches-6.18/9999-11-netfilter-flowtable-bind-xfrm-soe-flows.patch

## 2. CI Patch And Overlay Files That Overlap

Hash-checked overlay files that are exact copies of the new YYH tree:

- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mac80211\patches\subsys\411-mac80211-export-link-sta-capability-limits.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\0005-wifi-mt76-mt7996-fix-capability-of-EHT-MCS-15-in-MRU.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\0006-wifi-mt76-mt7996-refresh-power-limits-on-txpower-changes.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\0007-wifi-mt76-mt7996-enable-firmware-txpower-limit-controls.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\0013-wifi-mt76-reset-channel-state-during-scanning.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\0047-mtk-mt76-fix-RX-data-queuing-of-RRO-3.0.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\0083-mtk-mt76-remove-unnecessary-wcid-asignment.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\9992-wifi-mt76-mt7996-validate-PS-sync-event-TLVs.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\kernel\mt76\patches\9993-wifi-mt76-mt7996-pass-operating-mode-to-rate-control.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\network\services\hostapd\patches\602-nl80211-short-circuit-use-existing-iface.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\network\services\hostapd\patches\603-hostapd-6g-band-does-not-require-dfs.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\firmware\wireless-regdb\patches\510-us-regd-6GHz.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\firmware\wireless-regdb\patches\530-us-6ghz-lab-indoor-sp-override.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\network\utils\iwinfo\patches\101-nl80211-fix-txpowerlist-wiphy-dump.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\target\linux\airoha\an7581\base-files\etc\uci-defaults\18-xr1710g-firewall-defaults
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\target\linux\airoha\an7581\base-files\etc\uci-defaults\19-xr1710g-luci-language
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\target\linux\airoha\an7581\base-files\usr\libexec\platform\packet-steering.sh
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\target\linux\airoha\an7581\base-files\usr\sbin\xr1710g-net-debug

Overlay files that differ from the current YYH tree:

- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\package\firmware\wireless-regdb\patches\520-w1700k-us-power-limits.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\target\linux\airoha\dts\an7581-xr1710g-ubi.dts

Curated patches that overlap the same upstream paths:

- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\mt76\patches\0016-wifi-mt76-reset-channel-state-during-scanning.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\kernel\330-net-airoha-use-device_set_node-helper-to-setup-GDM-node.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\kernel\621-net-pcs-airoha-AN7581-add-global-digital-reset-for.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\kernel\921-net-airoha-npu-fix-firmware-loading-issue.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\kernel\922-net-airoha-classify-external-lan-ports-from-DT.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\kernel\940-01-net-airoha-periodic-CDM-FWD-CFG-kick-to-prevent-RXHWF-stall.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\kernel\990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\apply\status.js.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\apply\rpcd.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\apply\mt76-Makefile.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\xr1710g\config-6.18.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\xr1710g\an7581.mk.patch

Overlay duplicates that can be shadowed by apply order:

- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\hurryman\package\kernel\mt76\patches\9990-wifi-mt76-mt7996-advertise-eht-to-firmware-rate-control.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\hurryman\package\kernel\mt76\patches\9991-wifi-mt76-mt7996-advertise-eht-to-firmware-rate-control.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\hurryman\package\kernel\mt76\patches\9991-wifi-mt76-mt7996-fill-160mhz-bf-fallback-for-eht-320.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\hurryman\package\kernel\mt76\patches\9992-wifi-mt76-mt7996-fill-160mhz-bf-fallback-for-eht-320.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\hurryman\package\kernel\mt76\patches\9992-wifi-mt76-keep-NPU-RRO-data-on-original-RX-queue.patch
- D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\xr1710g\target\linux\airoha\dts\an7581-xr1710g-ubi.dts

## 3. Concrete Duplicate And Conflict Risks

1. YYH mt76 9992/9993 are shadowed by hurryman mt76 files. `apply-patches.sh` copies `overlay/hurryman` before `overlay/yyh` and only copies files when absent. Because hurryman already provides `9992-wifi-mt76-keep-NPU-RRO-data-on-original-RX-queue.patch` and `9993-wifi-mt76-distinguish-flowtable-callbacks.patch`, the YYH `9992-wifi-mt76-mt7996-validate-PS-sync-event-TLVs.patch` and `9993-wifi-mt76-mt7996-pass-operating-mode-to-rate-control.patch` will not be copied into the mt76 patch queue. The YYH PS-sync and operating-mode fixes are effectively dead in the current CI layout.

2. The hurryman mt76 directory itself contains duplicate old/new patch names. The new tree has `9990-advertise`, `9991-fill`, `9992-keep`, `9993-distinguish`; the tracked CI tree still has `9991-advertise`, `9992-fill`, `9993-distinguish`. Copying the overlay creates both `9990-advertise` and `9991-advertise`, and both `9991-fill` and `9992-fill`, so the mt76 patch series can apply the same change twice or fail with reversed/duplicate hunks.

3. `patches\yyh\mt76\patches\0016-wifi-mt76-reset-channel-state-during-scanning.patch` duplicates the new YYH `0013-wifi-mt76-reset-channel-state-during-scanning.patch`. Both modify the same `mac80211.c` channel-state guard. With `0013` and `0016` both present in the mt76 package patch queue, the second patch is likely to be rejected as reversed or already applied.

4. The XR1710G DTS is stale and shadowed. `D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\target\linux\airoha\dts\an7581-xr1710g-ubi.dts` matches old YYH `6a45b51...`, while new YYH is `3c6985a...` and adds PCIe register/reset topology, PCIe2 PERST ordering, and link-speed settings. The `overlay\xr1710g` DTS copy is also not the new YYH file, and it is skipped at apply time because the YYH overlay already created that path.

5. `patches\xr1710g\config-6.18.patch` is stale. Applying it to the locked fanboy base produces blob `71972ff...`, while current YYH config is `08829331...`. The current YYH config adds `CONFIG_NET_AIROHA=y`, `CONFIG_NET_AIROHA_NPU=y`, `CONFIG_NET_DSA_MT7530=y`, and sound config, and removes several PSTORE options.

6. `patches\xr1710g\an7581.mk.patch` is stale. Its result matches old YYH `c0ed58c...`, while new YYH is `c8395b5...`. New YYH adds `ip-bridge`, `ip-full`, `iperf3`, `mdio-tools`, `phytool`, `tcpdump`, `kmod-airoha-net-debug`, several `luci-i18n-*-zh-cn` packages, `luci-theme-glass`, and changes `wpad-mbedtls` to `wpad-basic-mbedtls`.

7. `patches\yyh\apply\status.js.patch` and `patches\yyh\apply\rpcd.patch` reproduce old YYH state. Applying them to fanboy base yields old YYH blobs `b6fdb3e...` and `035dd6e...`; new YYH blobs are `6eb0b60...` and `f3df637...`. New YYH contains substantially larger LuCI NPU fixes, including newer status rendering and rpcd hardware-probe protection.

8. `patches\yyh\kernel\990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch` is dead because the fanboy base already contains a file with that exact name. `copy_patch_files` skips existing targets, so the CI copy is never installed. The local copy is also older than the fanboy version, which already includes a re-entrancy guard.

9. `patches\yyh\kernel\922-net-airoha-classify-external-lan-ports-from-DT.patch` matches old YYH but not new YYH. New YYH only adds an `Assisted-by` metadata line, so this is a low-risk refresh issue.

10. `overlay\yyh\package\firmware\wireless-regdb\patches\520-w1700k-us-power-limits.patch` differs from both old and new YYH. The local copy has a different base `db.txt` context and extends UNII-3 through 5895 MHz. This may be an intentional local customization, but it should be documented and re-verified against the fanboy base.

## 4. Recommended Actions

1. Reconcile mt76 patch numbering before building. Keep one hurryman series (`9990-advertise`, `9991-fill`, `9992-keep`, `9993-distinguish`) and remove the old tracked copies `9991-advertise` and `9992-fill`. Then renumber YYH `9992` and `9993` to non-colliding numbers if they are still needed, or drop them if the hurryman series supersedes them.

2. Remove `D:\Agent\xr1710g_1\xr1710g-firmware-ci\patches\yyh\mt76\patches\0016-wifi-mt76-reset-channel-state-during-scanning.patch` once the new YYH `0013` overlay is used.

3. Update `D:\Agent\xr1710g_1\xr1710g-firmware-ci\overlay\yyh\target\linux\airoha\dts\an7581-xr1710g-ubi.dts` to new YYH `3c6985a...`, and remove or reconcile the shadowed `overlay\xr1710g` DTS copy.

4. Regenerate `patches\xr1710g\config-6.18.patch` and `patches\xr1710g\an7581.mk.patch` from the new YYH tree, or move the resulting files into `overlay\yyh` if they should become new-only files.

5. Replace `patches\yyh\apply\status.js.patch` and `patches\yyh\apply\rpcd.patch` with the full new YYH versions, or add the new YYH files to the overlay and remove the patches.

6. Delete or update `patches\yyh\kernel\990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch` after confirming the fanboy base version is the intended behavior.

7. Refresh `patches\yyh\kernel\922-net-airoha-classify-external-lan-ports-from-DT.patch` from new YYH, and verify the intentional `520` wireless-regdb divergence.

8. Decide whether the upstream `package/network/config/wifi-scripts` changes need to be represented in the CI build. They currently have no overlay or patch, but they include txpower and EHT beamforming behavior that is relevant to the XR1710G Wi-Fi profile.

9. After reconciliation, run the existing validation path (`bash scripts/validate-overlay.sh` or the equivalent CI preflight) before committing anything. This audit was read-only and did not run a build.
