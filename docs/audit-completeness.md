# Upstream Sync Completeness Audit

Audit target: `D:/Agent/xr1710g_1/xr1710g-firmware-ci`
Branch: `sync/2026-08-06`
Final commit: `6ea8fea747599782209003e31a6b167192dfc2da`

## Verdict

INCOMPLETE

The final tree contains most of the pinned upstream reconciliation, but six
allowed or XR1710G-relevant YYH changes and one hurryman mt76 update are still
missing from the CI tree.

## 1. Lockfile

PASS

`D:/Agent/xr1710g_1/xr1710g-firmware-ci/upstream.lock.json` pins:

- fanboy: `1fcc93055cabcdf2553977245e03dcb9599e67cd`
- hurryman: `73c3ab3081432f02d90b0084f63ea8ca4ea8589b`
- YYH: `99598e539d47aa9f137baff43f0c2f77becc2e50`

All three match the task SHAs exactly.

## 2. Allowlist Enumeration

The filter rules in `scripts/extract-overlay.sh` were applied to the recursive
Git trees of all three pinned SHAs.

### Hurryman

- Allowed blobs: 147
- Already exact in fanboy: 101
- Fanboy-absent and represented in `overlay/hurryman/`: 45
- Fanboy-different and unrepresented: 1

The one missing hurryman file is:

`package/kernel/mt76/patches/0012-wifi-mt76-npu-always-call-check_skb-on-rx.patch`

The fanboy base has an older version of this patch. Hurryman updated the same
path to check only unbound RX packets. The CI apply tree still contains the
fanboy version.

### YYH

- Allowed blobs: 215
- Already exact in fanboy: 141
- Fanboy-absent or fanboy-different: 74
- Represented exactly by overlay or patch: 60
- Unrepresented or intentionally divergent: 14

The remaining YYH items are classified in the gap table below.

## 3. Key Reconciliation Outcomes

### PASS

- Hurryman `target/linux/airoha/patches-6.18/9990-*` and `9999-*` series:
  every final overlay blob matches the hurryman tree blob.
- Hurryman mt76 `9990/9991/9992/9993` series: all match the hurryman tree.
- Hurryman generic hack `9990/9991`: all match the hurryman tree.
- Hurryman elfutils: the old CI `014` overlay and adaptation patch are gone;
  fanboy `tools/elfutils/patches/006-Fix-build-on-aarch64-musl.patch` carries
  the same build fix and is present in the applied fanboy tree.
- YYH mt76 `0005/0013/0047/0083`: exact overlay copies are present.
- YYH mt76 `9992/9993` content is present as renumbered `9994/9995`; the
  renumber avoids collision with hurryman `9992/9993`.
- YYH mac80211 `411`: exact overlay copy is present.
- YYH hostapd `602/603`: intentionally omitted; fanboy `053` and `mtk-0015`
  carry the equivalent fixes.
- YYH DTS `an7581-xr1710g-ubi.dts`: exact overlay copy is present.
- YYH `an7581.mk`, `modules.mk`, `status.js`, and `rpcd`: regenerated patches
  applied to a clean fanboy clone produce the exact new YYH blobs.
- YYH kernel `922`: the local patch now matches the new YYH blob exactly.
- YYH base-files scripts under `target/linux/airoha/an7581/base-files/`:
  exact overlay copies are present.

### CONFIG-6.18 NOTE

`patches/xr1710g/config-6.18.patch` regenerates the YYH config except for the
CPU governor. The applied blob is `19bfc614b27e...`; YYH is `08829331cd3d...`.
The only diff is that hurryman `001-hurryman-overclock-200mhz.patch` switches
the default governor to performance. This is an intentional hurryman overlay,
not a YYH completeness failure.

## 4. Applied Verification

`apply-patches.sh` was run against a clean temporary clone of fanboy
`1fcc93055cabcdf2553977245e03dcb9599e67cd` at:

`C:/Users/l1nxi/AppData/Local/Temp/audit-apply/openwrt`

Result:

- `apply-patches.sh` exited `0`.
- Reject files after apply: `0`.
- The script removed fanboy `555-w1700k-fix.patch` and
  `999-fix-txpower-list.patch` as expected.

Applied blob checks:

| File | Applied blob | YYH blob | Result |
|---|---|---|---|
| `target/linux/airoha/image/an7581.mk` | `c8395b5c9c3a` | `c8395b5c9c3a` | PASS |
| `target/linux/airoha/modules.mk` | `ded7b8069f6d` | `ded7b8069f6d` | PASS |
| `package/luci-app-airoha-npu/.../status.js` | `6eb0b60d3916` | `6eb0b60d3916` | PASS |
| `package/luci-app-airoha-npu/.../luci.airoha_npu` | `f3df63757ba1` | `f3df63757ba1` | PASS |
| `target/linux/airoha/dts/an7581-xr1710g-ubi.dts` | `3c6985aa6503` | `3c6985aa6503` | PASS |
| `target/linux/airoha/an7581/config-6.18` | `19bfc614b27e` | `08829331cd3d` | Intentional governor override |

## 5. Duplicate And Conflict Audit

The applied build tree was checked for:

- Duplicate `Subject:` lines in the same patch directory.
- Exact same-file hunk ranges across different patches.
- Cross-source overlapping hunks in CI-relevant directories.

Result: PASS. No CI-introduced duplicate-subject or overlapping-hunk pair was
found. The remaining numeric prefix collisions in `package/kernel/mt76/patches`
(`0010`, `0013`) are different subjects and do not overlap in the audited
target hunks. Pre-existing upstream numeric collisions outside the CI overlay
scope were not treated as CI gaps.

## 6. Three-Upstream Fix Audit

- Fanboy BMT/NAND `en75_bmt.c`: PASS. The applied fanboy tree contains the
  pinned fanboy blob `14dfe055ef9f...`.
- Fanboy wifi-scripts `supplicant.uc`: PASS. It is present from the fanboy base
  and matches the YYH tree at that path.
- YYH wifi-scripts: FAIL. Three YYH changes are absent:
  `mac80211.sh`, `wireless.wifi-device.json`, and `hostapd.uc`.
- Hurryman added/deleted files: FAIL. The updated hurryman mt76 `0012` patch is
  absent because the same path already exists in fanboy and the overlay copy
  rule does not replace it.

## 7. Exact Gaps

The following are the exact gaps that must be fixed before the sync branch can
be considered complete:

1. `package/kernel/mt76/patches/0012-wifi-mt76-npu-always-call-check_skb-on-rx.patch`
   - Hurryman blob: `92dd77ec45ad...`
   - Fanboy blob in final applied tree: `277a59e34c7d...`
   - Classification: real hurryman gap.
2. `package/kernel/mt76/patches/0003-wifi-mt76-mt7996-replace-direct-WTBL-access-with-MCU-for-station-statistics.patch`
   - YYH blob: `bd5d62417ce5...`
   - Fanboy blob in final applied tree: `5e63f742fe5c...`
   - Classification: real YYH gap.
3. `package/network/services/hostapd/Config.in`
   - YYH adds `DRIVER_11AC_SUPPORT`, `DRIVER_11AX_SUPPORT`, and
     `DRIVER_11BE_SUPPORT` defaults for `econet_xr1710g-ubi` and the other
     Airoha devices.
   - Final applied tree still has the fanboy `default n` only.
   - Classification: real YYH gap.
4. `package/network/config/wifi-scripts/files-ucode/lib/netifd/wireless/mac80211.sh`
   - YYH has the string-interpolation fix for `txpower_retry_delay`.
   - Final applied tree keeps the fanboy version.
   - Classification: real YYH gap.
5. `package/network/config/wifi-scripts/files-ucode/usr/share/schema/wireless.wifi-device.json`
   - YYH adds `eht_mu_beamformer`, `eht_su_beamformee`, and
     `eht_su_beamformer` schema entries.
   - Classification: real YYH gap.
6. `package/network/config/wifi-scripts/files-ucode/usr/share/ucode/wifi/hostapd.uc`
   - YYH sets default EHT beamforming values before masking against hardware
     capabilities.
   - Classification: real YYH gap.
7. `package/network/utils/iwinfo/Makefile`
   - YYH bumps `PKG_RELEASE` to `2` for the new `101` txpower patch.
   - Final applied tree keeps `PKG_RELEASE=1`.
   - Classification: minor real YYH gap; the patch itself is applied, but the
     package release is not bumped.

## 8. Non-Gap Classifications

The following missing allowed files were checked and are not counted as gaps:

- YYH `0006/0007` mt76 txpower patches: superseded by newer fanboy
  `0011-refresh-power-limits-on-txpower-changes.patch` and
  `0010-enable-firmware-txpower-limit.patch`.
- YYH `9990/9991` mt76 patches: superseded by hurryman `9990/9991` with the
  same subjects and fanboy-compatible contexts.
- YYH hostapd `370`: superseded by the fanboy hostapd patch series that
  includes `053` and the matching `370`.
- YYH hostapd `602/603`: superseded by fanboy `053` and `mtk-0015`.
- YYH `target/linux/airoha/an7581/target.mk`: not applied because fanboy is the
  base priority for the same file; no immediate build blocker identified.
- YYH DTS changes for `an7581-nokia-valyrian.dts`,
  `an7581-w1700k-ubi.dts`, and `an7583.dtsi`: not XR1710G-specific.
- YYH `an7581.dtsi`: intentionally overridden by hurryman
  `001-hurryman-overclock-200mhz.patch`.
- YYH `520-w1700k-us-power-limits.patch`: intentional local customization is
  documented in the patch itself.

## Final

Status: INCOMPLETE

The branch is close, and the reconciliation work already fixed the major stale
overlay and duplicate-series issues. Before this sync can be considered
complete, the seven exact gaps above need CI-side representation: the hurryman
`0012` update, the YYH `0003` update, YYH hostapd `Config.in`, the three YYH
wifi-scripts changes, and the YYH iwinfo `PKG_RELEASE` bump.
