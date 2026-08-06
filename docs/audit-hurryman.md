# Hurryman Upstream Delta Audit

Generated: 2026-08-06

Source: `hurryman2212/OpenW1700k-test`, branch `offload-oc`

Old SHA: `13a6b5474896e0a67581da65aa86be4a7163c4e5`

New SHA: `73c3ab3081432f02d90b0084f63ea8ca4ea8589b`

Method: temporary clone plus exact `git diff --name-status -M <old> <new>`.
The GitHub compare endpoint reports a diverged history (79 ahead, 37 behind),
so its merge-base diff would list paths that are unchanged between the two
pinned trees. The exact old-to-new tree diff reports 403 changed paths and is
used below.

## 1. Changed upstream files intersecting CI scope

Paths under `package/kernel/mt76/`, `target/linux/airoha/`, the mirrored
`target/linux/generic/` series, `tools/elfutils/patches/`, and the network
packages used by the XR1710G build are listed below.

### package/kernel/mt76

```text
M package/kernel/mt76/Makefile
M package/kernel/mt76/patches/0003-wifi-mt76-mt7996-replace-direct-WTBL-access-with-MCU-for-station-statistics.patch
M package/kernel/mt76/patches/0012-wifi-mt76-npu-always-call-check_skb-on-rx.patch
A package/kernel/mt76/patches/0014-wifi-mt76-flush-airoha-PPE-on-generic-sta-removal.patch
D package/kernel/mt76/patches/0014-wifi-mt76-mt7996-skip-DISASSOC-firmware-command-on-STA-remove.patch
R100 package/kernel/mt76/patches/9991-wifi-mt76-mt7996-advertise-eht-to-firmware-rate-control.patch -> package/kernel/mt76/patches/9990-wifi-mt76-mt7996-advertise-eht-to-firmware-rate-control.patch
D package/kernel/mt76/patches/9990-wifi-mt76-mt7996-validate-PS-sync-event-TLVs.patch
R100 package/kernel/mt76/patches/9992-wifi-mt76-mt7996-fill-160mhz-bf-fallback-for-eht-320.patch -> package/kernel/mt76/patches/9991-wifi-mt76-mt7996-fill-160mhz-bf-fallback-for-eht-320.patch
A package/kernel/mt76/patches/9992-wifi-mt76-keep-NPU-RRO-data-on-original-RX-queue.patch
```

### target/linux/airoha

```text
M target/linux/airoha/Makefile
M target/linux/airoha/image/an7583.mk
M target/linux/airoha/patches-6.18/099-08-v6.19-net-airoha-ppe-Flush-PPE-SRAM-table-during-PPE-setup.patch
M target/linux/airoha/patches-6.18/109-02-v6.19-pinctrl-airoha-convert-PHY-LED-GPIO-to-macro.patch
M target/linux/airoha/patches-6.18/109-03-v6.19-pinctrl-airoha-convert-PWM-GPIO-to-macro.patch
M target/linux/airoha/patches-6.18/109-05-v6.19-pinctrl-airoha-add-support-for-Airoha-AN7583-PINs.patch
M target/linux/airoha/patches-6.18/113-v6.19-pinctrl-airoha-Fix-AIROHA_PINCTRL_CONFS_DRIVE_E2.patch
M target/linux/airoha/patches-6.18/114-v6.19-pinctrl-airoha-convert-comma-to-semicolon.patch
M target/linux/airoha/patches-6.18/161-01-v7.2-net-airoha-Introduce-airoha_gdm_dev-struct.patch
M target/linux/airoha/patches-6.18/179-v7.2-pinctrl-airoha-Fix-type-in-.pin_config_group_get-cal.patch
M target/linux/airoha/patches-6.18/180-01-v7.2-pinctrl-Move-Airoha-driver-to-dedicated-directory.patch
M target/linux/airoha/patches-6.18/915-01-net-netfilter-flowtable-Add-the-capability-to-offloa.patch
M target/linux/airoha/patches-6.18/916-02-net-airoha-Implement-HW-GRO-TCP-support.patch
M target/linux/airoha/patches-6.18/930-net-airoha-ppe-flush-stale-PPE-flows-on-FDB-and-STA-events.patch
M target/linux/airoha/patches-6.18/990-01-netfilter-nf_flow_table-invalidate-flows-on-bridge-FDB-roaming.patch
M target/linux/airoha/patches-6.18/990-03-net-airoha-bind-WLAN-bound-flows-on-PPE-driver-L2-cache-miss.patch
M target/linux/airoha/patches-6.18/999-90-diag-wifi-ppe-path.patch
D target/linux/airoha/patches-6.18/109-01-v6.19-pinctrl-airoha-generalize-pins-group-function-confs-.patch
D target/linux/airoha/patches-6.18/112-v6.19-pinctrl-airoha-fix-pinctrl-function-mismatch-issue.patch
D target/linux/airoha/patches-6.18/170-v7.2-net-airoha-Fix-register-index-for-Tx-fwd-counter-con.patch
D target/linux/airoha/patches-6.18/171-v7.2-net-airoha-Fix-debugfs-new-tuple-display-for-IPv4-RO.patch
D target/linux/airoha/patches-6.18/172-v7.2-net-airoha-fix-foe_check_time-allocation-size.patch
D target/linux/airoha/patches-6.18/174-v7.2-net-airoha-Fix-skb-priority-underflow-in-airoha_dev_.patch
D target/linux/airoha/patches-6.18/180-02-v7.2-pinctrl-airoha-an7581-add-missed-gpio32-pin-group.patch
D target/linux/airoha/patches-6.18/180-04-v7.2-pinctrl-airoha-an7581-fix-misprint-in-gpio19-pinconf.patch
A target/linux/airoha/patches-6.18/990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch
A target/linux/airoha/patches-6.18/990-05-airoha-gen-gate-ppe-flush-and-teardown-by-eth.patch
A target/linux/airoha/patches-6.18/999-91-hash-fallback-replace-diag.patch
A target/linux/airoha/patches-6.18/999-92-reuse-stale-flow-cookie.patch
A target/linux/airoha/patches-6.18/999-93-remove-gen-gate.patch
R099 target/linux/airoha/patches-6.18/9999-01-net-airoha-share-hw-gro-state-across-qdma-users.patch -> target/linux/airoha/patches-6.18/9990-net-airoha-share-hw-gro-state-across-qdma-users.patch
```

The upstream `9999-*` SOE/XFRM series was also renumbered and edited. All 38
tracked old files in the CI overlay are still present alongside the 38 newly
copied files. Upstream rename mapping for the same-logical-patch pairs is:

```text
9999-02-net-add-packet-offload-transmit-callback.patch -> 9999-01-net-add-packet-offload-transmit-callback.patch
9999-03-xfrm-track-packet-offload-managers-per-namespace.patch -> 9999-02-xfrm-track-packet-offload-managers-per-namespace.patch
9999-04-xfrm-add-packet-offload-state-helpers.patch -> 9999-03-xfrm-add-packet-offload-state-helpers.patch
9999-05-xfrm-manage-packet-offload-device-lifetime.patch -> 9999-04-xfrm-manage-packet-offload-device-lifetime.patch
9999-06-xfrm-validate-packet-offload-input-state.patch -> 9999-05-xfrm-validate-packet-offload-input-state.patch
9999-07-xfrm-let-packet-offload-drivers-own-transmit.patch -> 9999-06-xfrm-let-packet-offload-drivers-own-transmit.patch
9999-08-xfrm-notify-packet-offload-managers-of-policy-change.patch -> 9999-07-xfrm-notify-packet-offload-managers-of-policy-change.patch
9999-09-xfrm-harden-packet-offload-state-lifetime.patch -> 9999-08-xfrm-harden-packet-offload-state-lifetime.patch
9999-10-xfrm-preserve-packet-offload-ownership-on-user-updat.patch -> 9999-09-xfrm-preserve-packet-offload-ownership-on-user-updat.patch
9999-18-dt-bindings-net-airoha-add-EN7581-SOE.patch -> 9999-10-dt-bindings-net-airoha-add-EN7581-SOE.patch
9999-19-MAINTAINERS-cover-the-Airoha-EN7581-SOE-binding.patch -> 9999-11-MAINTAINERS-cover-Airoha-EN7581-SOE-binding.patch
9999-20-arm64-dts-airoha-add-EN7581-SOE-node.patch -> 9999-12-arm64-dts-airoha-add-EN7581-SOE-node.patch
9999-21-net-airoha-add-SOE-and-PPE-IPsec-register-definition.patch -> 9999-13-net-airoha-add-SOE-and-PPE-IPsec-register-definition.patch
9999-22-net-airoha-add-the-SOE-driver-interface.patch -> 9999-15-net-airoha-add-SOE-and-PPE-driver-interfaces.patch
9999-11-flow_offload-add-XFRM-action-metadata.patch -> 9999-17-flow_offload-add-XFRM-action-metadata.patch
9999-12-netfilter-flowtable-carry-XFRM-route-metadata.patch -> 9999-18-netfilter-flowtable-carry-XFRM-route-metadata.patch
9999-13-netfilter-flowtable-retain-XFRM-input-state-in-flows.patch -> 9999-19-netfilter-flowtable-retain-XFRM-input-state-in-flows.patch
9999-15-netfilter-flowtable-discover-XFRM-state-for-flow-rou.patch -> 9999-20-netfilter-flowtable-discover-XFRM-state-for-flow-rou.patch
9999-16-netfilter-flowtable-emit-XFRM-hardware-actions.patch -> 9999-21-netfilter-flowtable-emit-XFRM-hardware-actions.patch
9999-14-netfilter-flowtable-keep-XFRM-hardware-flows-off-the.patch -> 9999-22-netfilter-flowtable-keep-XFRM-flows-off-software-pat.patch
9999-17-netfilter-flowtable-admit-authenticated-XFRM-flows.patch -> 9999-23-netfilter-flowtable-admit-authenticated-XFRM-flows.patch
9999-24-net-airoha-add-SOE-XFRM-packet-offload-support.patch -> 9999-26-net-airoha-add-SOE-XFRM-packet-offload-support.patch
9999-25-net-airoha-build-the-SOE-provider.patch -> 9999-27-net-airoha-build-the-SOE-provider.patch
9999-26-net-airoha-add-the-SOE-offload-option.patch -> 9999-28-net-airoha-add-the-SOE-offload-option.patch
9999-31-xfrm-define-shared-state-LAG-offload-operations.patch -> 9999-29-xfrm-define-shared-state-LAG-offload-operations.patch
9999-32-xfrm-add-lower-device-offload-state-helpers.patch -> 9999-30-xfrm-add-lower-device-offload-state-helpers.patch
9999-33-xfrm-clear-lower-device-state-during-offload-teardow.patch -> 9999-31-xfrm-clear-lower-device-state-during-offload-teardow.patch
9999-37-netfilter-flowtable-use-XFRM-offload-transmit-device.patch -> 9999-32-netfilter-flowtable-use-XFRM-offload-transmit-device.patch
9999-34-bonding-add-bookkeeping-for-LAG-XFRM-offload.patch -> 9999-33-bonding-add-LAG-XFRM-offload-bookkeeping.patch
9999-35-bonding-add-shared-state-XFRM-offload-for-LAG-modes.patch -> 9999-34-bonding-add-shared-state-XFRM-offload.patch
9999-36-bonding-update-XFRM-offload-across-mode-changes.patch -> 9999-35-bonding-update-XFRM-offload-across-mode-changes.patch
9999-38-net-airoha-add-shared-state-SOE-bonding-support.patch -> 9999-37-net-airoha-share-SOE-state-across-LAG-devices.patch
```

Upstream also added new `9999-14`, `9999-16`, `9999-24`, `9999-25`,
`9999-36`, and `9999-38` files, and deleted old `9999-23`, `9999-27`,
`9999-28`, `9999-29`, and `9999-30` files.

### target/linux/generic, tools/elfutils, and network packages

```text
R100 target/linux/generic/hack-6.18/9991-bonding-expose-selected-slave-through-forward-path.patch -> target/linux/generic/hack-6.18/9990-bonding-expose-selected-slave-through-forward-path.patch
A target/linux/generic/hack-6.18/9991-netfilter-flowtable-preserve-LAG-output-device-in-path-walk.patch
R053 target/linux/generic/hack-6.18/9992-netfilter-flowtable-preserve-LAG-output-device-in-path-walk.patch -> target/linux/generic/pending-6.18/675-07-netfilter-flowtable-use-hardware-path-device-for-direct-redirect.patch
A target/linux/generic/pending-6.18/675-06-net-add-flow-aware-forward-path-discovery.patch
M target/linux/generic/pending-6.18/675-03-nft_flow_offload-add-bridging-support.patch
A target/linux/generic/pending-6.18/675-08-netfilter-nft_flow_offload-fix-bridge-vlan-encap.patch
R100 tools/elfutils/patches/014-aarch64-use-sys-uio.patch -> tools/elfutils/patches/999-aarch64-use-sys-uio.patch
M package/kernel/linux/modules/crypto.mk
M package/kernel/linux/modules/netdevices.mk
M package/kernel/linux/modules/netfilter.mk
M package/kernel/linux/modules/sound.mk
M package/network/config/bridge-flow-offload/files/usr/share/bridge-flow-offload/apply-rules.sh
M package/network/config/wifi-scripts/files-ucode/usr/share/ucode/wifi/supplicant.uc
M package/network/config/wifi-scripts/files/lib/netifd/wireless.uc
M package/network/services/hostapd/files/hostapd.uc
M package/network/services/hostapd/files/wpa_supplicant.uc
M package/network/services/ppp/Makefile
M package/network/services/ppp/patches/310-precompile_filter.patch
M package/network/services/ppp/patches/500-add-pptp-plugin.patch
```

The exact diff also has broad `target/linux/generic/` churn in other hack,
backport, and pending files. Those are not vendored by the current CI overlay
or `patches/` directories, so they are treated as build-wide churn rather than
overlay duplication.

## 2. CI patch/overlay files that overlap

All CI paths below are absolute under
`D:/Agent/xr1710g_1/xr1710g-firmware-ci/`.

### Hurryman mt76

- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/package/kernel/mt76/patches/9991-wifi-mt76-mt7996-advertise-eht-to-firmware-rate-control.patch`
  duplicates the newly added
  `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/package/kernel/mt76/patches/9990-wifi-mt76-mt7996-advertise-eht-to-firmware-rate-control.patch`.
- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/package/kernel/mt76/patches/9992-wifi-mt76-mt7996-fill-160mhz-bf-fallback-for-eht-320.patch`
  duplicates the newly added
  `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/package/kernel/mt76/patches/9991-wifi-mt76-mt7996-fill-160mhz-bf-fallback-for-eht-320.patch`.
- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/package/kernel/mt76/patches/0014-wifi-mt76-mt7996-skip-DISASSOC-firmware-command-on-STA-remove.patch`
  is stale; upstream replaced it with
  `package/kernel/mt76/patches/0014-wifi-mt76-flush-airoha-PPE-on-generic-sta-removal.patch`,
  which is missing from the current overlay.

The two old mt76 files listed above differ from the corresponding old upstream
blobs, so they may carry CI-specific hunk line adjustments. Those adjustments
need to be ported onto the new numbered files before the old files are deleted.

### Hurryman SOE/XFRM 9999 series

Base directory:
`D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/target/linux/airoha/patches-6.18/`

All 38 tracked old `9999-*` files are still present alongside the 38 newly
copied files. The upstream rename mapping in Section 1 identifies the
same-logical-patch pairs. The old files are stale copies of the old upstream
series; keeping both means every SOE/XFRM patch number is duplicated in the
target patch directory.

The old file that should become `9990-net-airoha-share-hw-gro-state-across-qdma-users.patch`
is still named
`9999-01-net-airoha-share-hw-gro-state-across-qdma-users.patch`, and the new
`9990-*` file is missing. Upstream deleted these old files, which remain as
stale CI overlay files:

```text
9999-23-net-airoha-add-flowtable-aware-SOE-Ethernet-and-PPE-.patch
9999-27-net-airoha-compose-soe-and-openwrt-feature-hooks.patch
9999-28-net-airoha-keep-openwrt-lro-clear-of-soe-rx-rings.patch
9999-29-net-airoha-integrate-soe-with-openwrt-ppe-ownership.patch
9999-30-net-airoha-tear-down-flowtable-flows-when-flushing.patch
```

Current overlay content differs from the old upstream blob for these tracked
files, so they should be reviewed for local adaptations before replacement:

```text
9999-08-xfrm-notify-packet-offload-managers-of-policy-change.patch
9999-15-netfilter-flowtable-discover-XFRM-state-for-flow-rou.patch
9999-17-netfilter-flowtable-admit-authenticated-XFRM-flows.patch
9999-23-net-airoha-add-flowtable-aware-SOE-Ethernet-and-PPE-.patch
9999-29-net-airoha-integrate-soe-with-openwrt-ppe-ownership.patch
```

### Hurryman generic and elfutils

- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/target/linux/generic/hack-6.18/9991-bonding-expose-selected-slave-through-forward-path.patch`
  is stale; upstream renamed it to `9990-*`, and the new `9990-*` file is not
  present.
- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/target/linux/generic/hack-6.18/9992-netfilter-flowtable-preserve-LAG-output-device-in-path-walk.patch`
  is stale; upstream moved this logic to
  `target/linux/generic/pending-6.18/675-07-*`.
- The new
  `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/target/linux/generic/hack-6.18/9991-netfilter-flowtable-preserve-LAG-output-device-in-path-walk.patch`
  is present and should be kept after the old files are removed.
- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/hurryman/tools/elfutils/patches/014-aarch64-use-sys-uio.patch`
  is stale; upstream renamed it to `tools/elfutils/patches/999-*`, and the new
  file is not present.

### Curated patch files

- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/patches/hurryman/002-hurryman-airoha-enable-lro-by-default.patch`
  still targets the old
  `9999-01-net-airoha-share-hw-gro-state-across-qdma-users.patch` path and the
  old `916-02` hunk. It must be rebased onto the new `9990-*` file and the new
  upstream `916-02` content.
- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/patches/hurryman/003-hurryman-elfutils-aarch64-iovec.patch`
  still targets
  `tools/elfutils/patches/014-aarch64-use-sys-uio.patch`; it must be rebased to
  `tools/elfutils/patches/999-aarch64-use-sys-uio.patch`.
- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/patches/yyh/kernel/990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch`
  overlaps the new upstream
  `target/linux/airoha/patches-6.18/990-04-*` file. The current YYH patch is an
  older variant; the new upstream patch adds a re-entrancy guard and updated
  context.
- `D:/Agent/xr1710g_1/xr1710g-firmware-ci/patches/yyh/mt76/patches/0016-wifi-mt76-reset-channel-state-during-scanning.patch`
  duplicates the same logical change as the newly added
  `D:/Agent/xr1710g_1/xr1710g-firmware-ci/overlay/yyh/package/kernel/mt76/patches/0013-wifi-mt76-reset-channel-state-during-scanning.patch`.

## 3. Concrete duplicate/conflict risks

1. OpenWrt sorts patch files by filename. The old and new `9999-*` SOE/XFRM
   series share the same numeric range, so both versions of the same logical
   patch are interleaved and may be applied twice. Similar patches can be
   skipped as "already applied" or fail as conflicting hunks depending on
   content drift.
2. The renamed `9990-*` and elfutils `999-*` files are not copied by the
   current `scripts/extract-overlay.sh` allowlist, so the old paths remain and
   the new paths are missing. Curated patches `002` and `003` still reference
   the old paths.
3. The old mt76 `9991`/`9992` files were locally adapted with different hunk
   line numbers. Replacing them with the raw new upstream files without
   porting those context adjustments could make the mt76 patch set fail against
   the fanboy tree.
4. Upstream removed several old SOE/OpenWrt glue patches. Those old files still
   exist in the overlay and can re-enable removed behavior on top of the new
   SOE series.
5. Upstream added `0014-flush-airoha-PPE-on-generic-sta-removal.patch`, but the
   current overlay still has the removed `0014-skip-DISASSOC` file and no
   replacement, so the refresh is incomplete for the mt76 directory.
6. `patches/yyh/kernel/990-04` is older than the new upstream `990-04`. If the
   new upstream file is later added, both variants target the same notifier
   hook and can double-register or conflict.
7. `patches/yyh/mt76/patches/0016` and the new
   `overlay/yyh/.../0013` file modify the same channel-state reset logic with
   different context, creating another duplicate patch pair.
8. `docs/overlay-refresh.txt` currently records `hurryman_new_files=0`, but the
   worktree contains 42 untracked new hurryman overlay files. The refresh
   accounting is unreliable and should not be trusted until the extraction
   logic is fixed.

## 4. Recommended actions

1. Change overlay extraction to mirror allowed upstream directories instead of
   only copying absent files: delete files removed upstream, rename moved
   files, and update files modified upstream.
2. Extend the hurryman allowlist to include
   `target/linux/airoha/patches-6.18/9990-*`,
   `target/linux/generic/hack-6.18/9990-*`, and
   `tools/elfutils/patches/999-*`, and make sure new mt76 files such as
   `0014-*` are copied.
3. For SOE/XFRM: remove the 38 old `9999-*` files, keep the 38 new `9999-*`
   files, add the new `9990-net-airoha-share-*` file, and port any local
   adaptations from the five old files listed in Section 2.
4. For mt76: remove old `9991-*` and `9992-*` duplicates, remove
   `0014-skip-DISASSOC`, add new `9990-*`, `9991-*`, `9992-*`, and
   `0014-flush-airoha-PPE-on-generic-sta-removal`, preserving local hunk
   adjustments where needed.
5. For generic/elfutils: remove stale `9991-bonding`, `9992-flowtable`, and
   `014-elfutils` overlay files; add new `9990-bonding`, `9991-flowtable`, and
   `999-elfutils` files; account for the old flowtable patch moving to
   `pending-6.18/675-07`.
6. Rebase `patches/hurryman/002` and `003` onto the new paths and upstream
   content.
7. Reconcile `patches/yyh/kernel/990-04` with the new upstream `990-04`, and
   keep only one of `patches/yyh/mt76/patches/0016` or
   `overlay/yyh/package/kernel/mt76/patches/0013`.
8. After cleanup, run the CI preflight and update `docs/overlay-refresh.txt`
   with the actual refreshed file count.
