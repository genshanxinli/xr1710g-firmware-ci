# Patch Apply Dry Run Audit

Generated: 2026-08-06 02:11 UTC

- Branch: `sync/2026-08-06`
- Fanboy base: `1fcc93055cabcdf2553977245e03dcb9599e67cd`
- Temp clone: `/tmp/tmp.qQ13rRkV9R/openwrt`
- Temp clone (Windows): `C:\Users\l1nxi\AppData\Local\Temp\tmp.qQ13rRkV9R\openwrt`
- Full log: `/tmp/tmp.qQ13rRkV9R/apply-dryrun.log`
- Result: `apply-patches.sh` exited `0`
- Remaining `.rej` files: `0`

## Command Log

```text
TMPDIR=/tmp/tmp.qQ13rRkV9R
start=2026-08-06T02:11:22Z
From https://github.com/OpenWRT-fanboy/OpenW1700k
 * branch            1fcc93055cabcdf2553977245e03dcb9599e67cd -> FETCH_HEAD
Cloned fanboy offload 1fcc93055cabcdf2553977245e03dcb9599e67cd
clone_exit=0
Applying XR1710G overlays to /tmp/tmp.qQ13rRkV9R/openwrt
  removed upstream patch: package/firmware/wireless-regdb/patches/555-w1700k-fix.patch (YYH 520/530 carry the same fixes)
  removed upstream patch: package/network/utils/iwinfo/patches/999-fix-txpower-list.patch (YYH 101 carries the same txpower fix)
[copy] hurryman new-only files
[patch] hurryman adaptation patches
  skip already applied: 002-hurryman-airoha-enable-lro-by-default.patch
  skip already applied: 003-hurryman-elfutils-aarch64-iovec.patch
[copy] yyh new-only files
  skip existing target patch: 990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch
[patch] yyh package patches
[copy] xr1710g new files
[patch] xr1710g adaptation patches
Verifying key files...
All patches applied successfully.
apply_exit=0
end=2026-08-06T02:11:46Z
```

## Skipped / Removed Patches

- Removed upstream: `package/firmware/wireless-regdb/patches/555-w1700k-fix.patch`
- Removed upstream: `package/network/utils/iwinfo/patches/999-fix-txpower-list.patch`
- Skipped already applied: `002-hurryman-airoha-enable-lro-by-default.patch`
- Skipped already applied: `003-hurryman-elfutils-aarch64-iovec.patch`
- Skipped existing target patch: `990-04-netfilter-nf_flow_table-add-teardown-by-eth-vendor-notifier.patch`

## Duplicate Numeric Patch Files

Definition: multiple `*.patch` files in the same target directory with the same leading numeric order token (for example `0010`, `9991`, or `9999-12`). These are files OpenWrt itself would both apply.

### Overlay-Introduced Duplicate Groups (45)

```text
package/kernel/mt76/patches 0010: 0010-enable-firmware-txpower-limit.patch | 0010-wifi-mt76-mt7996-fix-DL-OFDMA-fail-after-sta-reconne.patch
package/kernel/mt76/patches 0013: 0013-wifi-mt76-mt7996-flush-airoha-PPE-flows-on-STA-link-remove.patch | 0013-wifi-mt76-reset-channel-state-during-scanning.patch
package/kernel/mt76/patches 0014: 0014-wifi-mt76-flush-airoha-PPE-on-generic-sta-removal.patch | 0014-wifi-mt76-mt7996-skip-DISASSOC-firmware-command-on-STA-remove.patch
package/kernel/mt76/patches 9991: 9991-wifi-mt76-mt7996-advertise-eht-to-firmware-rate-control.patch | 9991-wifi-mt76-mt7996-fill-160mhz-bf-fallback-for-eht-320.patch
package/kernel/mt76/patches 9992: 9992-wifi-mt76-keep-NPU-RRO-data-on-original-RX-queue.patch | 9992-wifi-mt76-mt7996-fill-160mhz-bf-fallback-for-eht-320.patch | 9992-wifi-mt76-mt7996-validate-PS-sync-event-TLVs.patch
package/kernel/mt76/patches 9993: 9993-wifi-mt76-distinguish-flowtable-callbacks.patch | 9993-wifi-mt76-mt7996-pass-operating-mode-to-rate-control.patch
target/linux/airoha/patches-6.18 9999-01: 9999-01-net-add-packet-offload-transmit-callback.patch | 9999-01-net-airoha-share-hw-gro-state-across-qdma-users.patch
target/linux/airoha/patches-6.18 9999-02: 9999-02-net-add-packet-offload-transmit-callback.patch | 9999-02-xfrm-track-packet-offload-managers-per-namespace.patch
target/linux/airoha/patches-6.18 9999-03: 9999-03-xfrm-add-packet-offload-state-helpers.patch | 9999-03-xfrm-track-packet-offload-managers-per-namespace.patch
target/linux/airoha/patches-6.18 9999-04: 9999-04-xfrm-add-packet-offload-state-helpers.patch | 9999-04-xfrm-manage-packet-offload-device-lifetime.patch
target/linux/airoha/patches-6.18 9999-05: 9999-05-xfrm-manage-packet-offload-device-lifetime.patch | 9999-05-xfrm-validate-packet-offload-input-state.patch
target/linux/airoha/patches-6.18 9999-06: 9999-06-xfrm-let-packet-offload-drivers-own-transmit.patch | 9999-06-xfrm-validate-packet-offload-input-state.patch
target/linux/airoha/patches-6.18 9999-07: 9999-07-xfrm-let-packet-offload-drivers-own-transmit.patch | 9999-07-xfrm-notify-packet-offload-managers-of-policy-change.patch
target/linux/airoha/patches-6.18 9999-08: 9999-08-xfrm-harden-packet-offload-state-lifetime.patch | 9999-08-xfrm-notify-packet-offload-managers-of-policy-change.patch
target/linux/airoha/patches-6.18 9999-09: 9999-09-xfrm-harden-packet-offload-state-lifetime.patch | 9999-09-xfrm-preserve-packet-offload-ownership-on-user-updat.patch
target/linux/airoha/patches-6.18 9999-10: 9999-10-dt-bindings-net-airoha-add-EN7581-SOE.patch | 9999-10-xfrm-preserve-packet-offload-ownership-on-user-updat.patch
target/linux/airoha/patches-6.18 9999-11: 9999-11-flow_offload-add-XFRM-action-metadata.patch | 9999-11-MAINTAINERS-cover-Airoha-EN7581-SOE-binding.patch
target/linux/airoha/patches-6.18 9999-12: 9999-12-arm64-dts-airoha-add-EN7581-SOE-node.patch | 9999-12-netfilter-flowtable-carry-XFRM-route-metadata.patch
target/linux/airoha/patches-6.18 9999-13: 9999-13-net-airoha-add-SOE-and-PPE-IPsec-register-definition.patch | 9999-13-netfilter-flowtable-retain-XFRM-input-state-in-flows.patch
target/linux/airoha/patches-6.18 9999-14: 9999-14-net-airoha-add-SOE-state-and-datapath-metadata.patch | 9999-14-netfilter-flowtable-keep-XFRM-hardware-flows-off-the.patch
target/linux/airoha/patches-6.18 9999-15: 9999-15-net-airoha-add-SOE-and-PPE-driver-interfaces.patch | 9999-15-netfilter-flowtable-discover-XFRM-state-for-flow-rou.patch
target/linux/airoha/patches-6.18 9999-16: 9999-16-net-airoha-integrate-SOE-with-the-Ethernet-datapath.patch | 9999-16-netfilter-flowtable-emit-XFRM-hardware-actions.patch
target/linux/airoha/patches-6.18 9999-17: 9999-17-flow_offload-add-XFRM-action-metadata.patch | 9999-17-netfilter-flowtable-admit-authenticated-XFRM-flows.patch
target/linux/airoha/patches-6.18 9999-18: 9999-18-dt-bindings-net-airoha-add-EN7581-SOE.patch | 9999-18-netfilter-flowtable-carry-XFRM-route-metadata.patch
target/linux/airoha/patches-6.18 9999-19: 9999-19-MAINTAINERS-cover-the-Airoha-EN7581-SOE-binding.patch | 9999-19-netfilter-flowtable-retain-XFRM-input-state-in-flows.patch
target/linux/airoha/patches-6.18 9999-20: 9999-20-arm64-dts-airoha-add-EN7581-SOE-node.patch | 9999-20-netfilter-flowtable-discover-XFRM-state-for-flow-rou.patch
target/linux/airoha/patches-6.18 9999-21: 9999-21-net-airoha-add-SOE-and-PPE-IPsec-register-definition.patch | 9999-21-netfilter-flowtable-emit-XFRM-hardware-actions.patch
target/linux/airoha/patches-6.18 9999-22: 9999-22-net-airoha-add-the-SOE-driver-interface.patch | 9999-22-netfilter-flowtable-keep-XFRM-flows-off-software-pat.patch
target/linux/airoha/patches-6.18 9999-23: 9999-23-net-airoha-add-flowtable-aware-SOE-Ethernet-and-PPE-.patch | 9999-23-netfilter-flowtable-admit-authenticated-XFRM-flows.patch
target/linux/airoha/patches-6.18 9999-24: 9999-24-net-airoha-add-SOE-XFRM-packet-offload-support.patch | 9999-24-net-airoha-pass-flowtable-context-through-offload-AP.patch
target/linux/airoha/patches-6.18 9999-25: 9999-25-net-airoha-add-autonomous-SOE-XFRM-flow-offload.patch | 9999-25-net-airoha-build-the-SOE-provider.patch
target/linux/airoha/patches-6.18 9999-26: 9999-26-net-airoha-add-SOE-XFRM-packet-offload-support.patch | 9999-26-net-airoha-add-the-SOE-offload-option.patch
target/linux/airoha/patches-6.18 9999-27: 9999-27-net-airoha-build-the-SOE-provider.patch | 9999-27-net-airoha-compose-soe-and-openwrt-feature-hooks.patch
target/linux/airoha/patches-6.18 9999-28: 9999-28-net-airoha-add-the-SOE-offload-option.patch | 9999-28-net-airoha-keep-openwrt-lro-clear-of-soe-rx-rings.patch
target/linux/airoha/patches-6.18 9999-29: 9999-29-net-airoha-integrate-soe-with-openwrt-ppe-ownership.patch | 9999-29-xfrm-define-shared-state-LAG-offload-operations.patch
target/linux/airoha/patches-6.18 9999-30: 9999-30-net-airoha-tear-down-flowtable-flows-when-flushing.patch | 9999-30-xfrm-add-lower-device-offload-state-helpers.patch
target/linux/airoha/patches-6.18 9999-31: 9999-31-xfrm-clear-lower-device-state-during-offload-teardow.patch | 9999-31-xfrm-define-shared-state-LAG-offload-operations.patch
target/linux/airoha/patches-6.18 9999-32: 9999-32-netfilter-flowtable-use-XFRM-offload-transmit-device.patch | 9999-32-xfrm-add-lower-device-offload-state-helpers.patch
target/linux/airoha/patches-6.18 9999-33: 9999-33-bonding-add-LAG-XFRM-offload-bookkeeping.patch | 9999-33-xfrm-clear-lower-device-state-during-offload-teardow.patch
target/linux/airoha/patches-6.18 9999-34: 9999-34-bonding-add-bookkeeping-for-LAG-XFRM-offload.patch | 9999-34-bonding-add-shared-state-XFRM-offload.patch
target/linux/airoha/patches-6.18 9999-35: 9999-35-bonding-add-shared-state-XFRM-offload-for-LAG-modes.patch | 9999-35-bonding-update-XFRM-offload-across-mode-changes.patch
target/linux/airoha/patches-6.18 9999-36: 9999-36-bonding-update-XFRM-offload-across-mode-changes.patch | 9999-36-net-airoha-extend-SOE-interface-for-shared-LAG-state.patch
target/linux/airoha/patches-6.18 9999-37: 9999-37-net-airoha-share-SOE-state-across-LAG-devices.patch | 9999-37-netfilter-flowtable-use-XFRM-offload-transmit-device.patch
target/linux/airoha/patches-6.18 9999-38: 9999-38-net-airoha-add-shared-state-SOE-bonding-support.patch | 9999-38-net-airoha-resolve-SOE-PPE-flows-through-LAG-lowers.patch
target/linux/generic/hack-6.18 9991: 9991-bonding-expose-selected-slave-through-forward-path.patch | 9991-netfilter-flowtable-preserve-LAG-output-device-in-path-walk.patch
```

### Pre-Existing Upstream Duplicate Groups (19)

```text
package/boot/uboot-mediatek/patches 445: 445-add-cudy_tr3000-v1.patch | 445-add-netis-nx31.patch | 445-add-netis-nx32u.patch
package/boot/uboot-mediatek/patches 448: 448-add-comfast_cf-wr632ax-ubi.patch | 448-add-comfast_cf-wr632ax.patch
package/boot/uboot-mediatek/patches 461: 461-add-asus-zenwifi-bt8.patch | 461-add-netis-nx30v2.patch
package/boot/uboot-mediatek/patches 468: 468-add-cudy_m3000-v1.patch | 468-add-cudy_m3000-v2-yt8821.patch | 468-add-cudy_wr3000e-v1.patch | 468-add-cudy_wr3000h-v1.patch | 468-add-cudy_wr3000p-v1.patch | 468-add-cudy_wr3000s-v1.patch
package/kernel/lantiq/ltq-vmmc/patches 602: 602-fix-compilation-warning-int-conversion.patch | 602-remove-ABS.patch
package/network/utils/iproute2/patches 140: 140-allow_pfifo_fast.patch | 140-keep_libmnl_optional.patch
target/linux/airoha/patches-6.18 179: 179-v7.2-net-airoha-fix-BQL-underflow-in-shared-QDMA-TX-ring.patch | 179-v7.2-pinctrl-airoha-Fix-type-in-.pin_config_group_get-cal.patch
target/linux/generic/backport-6.12 626-16: 626-16-v6.17-net-pse-pd-Add-support-for-budget-evaluation-strategies.patch | 626-16b-v6.17-regulator-Add-support-for-power-budget.patch
target/linux/generic/backport-6.12 630: 630-v6.13-net-usb-qmi_wwan-add-Quectel-RG255C.patch | 630-v6.14-PM-sleep-wakeirq-Introduce-device-managed-variant-of.patch
target/linux/generic/backport-6.12 650: 650-v6.13-net-phylink-allow-mac_select_pcs-to-remove-a-PCS.patch | 650-v7.2-net-pppoe-implement-GRO-GSO-support.patch
target/linux/generic/backport-6.12 784-02: 784-02-v6.18-net-phy-realtek-Avoid-PHYCR2-access-if-PHYCR2-not-pr.patch | 784-02-v6.18-net-phy-realtek-fix-RTL8211F-wake-on-lan-support.patch
target/linux/generic/backport-6.12 784-03: 784-03-v6.18-net-phy-realtek-fix-rtl8221b-vm-cg-name.patch | 784-03-v6.18-net-phy-realtek-support-for-TRIGGER_NETDEV_LINK-on-R.patch
target/linux/generic/backport-6.18 785: 785-v7.0-01-dt-bindings-phy-rename-transmit-amplitude.yaml-to-ph.patch | 785-v7.0-02-dt-bindings-phy-common-props-create-a-reusable-proto.patch | 785-v7.0-03-dt-bindings-phy-common-props-ensure-protocol-names-a.patch | 785-v7.0-04-dt-bindings-phy-common-props-RX-and-TX-lane-polarity.patch | 785-v7.0-05-phy-add-phy_get_rx_polarity-and-phy_get_tx_polarity.patch | 785-v7.0-06-dt-bindings-net-airoha-en8811h-deprecate-airoha-pnsw.patch | 785-v7.0-07-net-phy-air_en8811h-deprecate-airoha-pnswap-rx-and-a.patch | 785-v7.0-08-dt-bindings-net-pcs-mediatek-sgmiisys-deprecate-medi.patch | 785-v7.0-09-net-pcs-pcs-mtk-lynxi-pass-SGMIISYS-OF-node-to-PCS.patch | 785-v7.0-10-net-pcs-pcs-mtk-lynxi-deprecate-mediatek-pnswap.patch | 785-v7.0-11-phy-enter-drivers-phy-Makefile-even-without-CONFIG_G.patch
target/linux/generic/pending-6.18 895-00: 895-00-net-pse-pd-fix-out-of-bounds-bitmap-access-in-pse_isr-on-32-bit.patch | 895-00a-net-pse-pd-disable-IRQ-before-freeing-PI-data-in-unregister.patch | 895-00b-net-pse-pd-guard-against-freed-PI-data-on-regulator-disable.patch
target/linux/kirkwood/patches-6.12 109: 109-dns325-add-fan-label-and-update-partitions.patch | 109-pogoplug_v4.patch
target/linux/kirkwood/patches-6.18 109: 109-dns325-add-fan-label-and-update-partitions.patch | 109-pogoplug_v4.patch
target/linux/microchipsw/patches-6.18 116: 116-mmc-sdhci-of-at91-add-sama7g5-required-quirks.patch | 116-mmc-sdhci-of-at91-add-soc-data-field-quirks2.patch
target/linux/octeon/patches-6.18 100: 100-mips_image_cmdline_hack.patch | 100-ubnt_edgerouter2_support.patch
tools/7z/patches 7: 7-zip-flags.patch | 7-zip-musl.patch
```
