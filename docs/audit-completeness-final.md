# Upstream Sync Final Completeness Audit

Audit target: `D:/Agent/xr1710g_1/xr1710g-firmware-ci`
Branch: `sync/2026-08-06`
Commit: `dbd4a3d`

Generated: 2026-08-06

## Verdict

COMPLETE

All seven gaps from the prior completeness audit are fixed in the CI tree and
in a fresh applied tree built from the locked fanboy SHA. No remaining real
upstream completeness gap was found. The remaining YYH files that do not byte-
match upstream are the same intentional or superseded classifications from the
prior audit, not new gaps.

## 1. Lockfile

PASS

`upstream.lock.json` pins:

- fanboy: `1fcc93055cabcdf2553977245e03dcb9599e67cd`
- hurryman: `73c3ab3081432f02d90b0084f63ea8ca4ea8589b`
- YYH: `99598e539d47aa9f137baff43f0c2f77becc2e50`

All three match the task SHAs exactly.

## 2. Apply Run

PASS

Literal command:

```bash
bash apply-patches.sh <temp-fanboy-clone> .
```

- Fanboy base SHA: `1fcc93055cabcdf2553977245e03dcb9599e67cd`
- Temp clone for the literal run: `C:/Users/l1nxi/AppData/Local/Temp/audit-final-20260806033110/fanboy-dot`
- Literal run exit code: `0`
- Remaining `.rej` files: `0`

A second clean clone (`fanboy-lf`) was used for exact blob and enumeration
comparisons, using a raw LF export of the CI tree as the apply root so Windows
autocrlf did not distort content hashes. That run also exited `0` with no
rejects.

The script removed the stale fanboy mt76 `0012` and `0003` patches before
copying the newer hurryman/YYH overlay versions, then applied all remaining
overlays and curated patches without rejects.

## 3. Prior Exact Gaps

PASS

| Gap | Upstream/expected blob | Applied blob |
|---|---|---|
| Hurryman mt76 `0012` | `92dd77ec45ad1d89c1349125eb995061c96ef8ef` | `92dd77ec45ad1d89c1349125eb995061c96ef8ef` |
| YYH mt76 `0003` | `bd5d62417ce5cdf187bf50f716cb2117901dcf0b` | `bd5d62417ce5cdf187bf50f716cb2117901dcf0b` |
| `package/network/services/hostapd/Config.in` | `7d8a094efbf89245715cece7e94c010ac0974ba4` | `7d8a094efbf89245715cece7e94c010ac0974ba4` |
| wifi-scripts `mac80211.sh` | `a42aeaf1f398d3dec8abadcba5d2967b4fb07e6d` | `a42aeaf1f398d3dec8abadcba5d2967b4fb07e6d` |
| wifi-scripts `wireless.wifi-device.json` | `ba175cbf54eebf2ac8a5951025d6c425c113f99c` | `ba175cbf54eebf2ac8a5951025d6c425c113f99c` |
| wifi-scripts `hostapd.uc` | `98f44e016852f3b7bdb4b3998d410296d907ae5a` | `98f44e016852f3b7bdb4b3998d410296d907ae5a` |
| `package/network/utils/iwinfo/Makefile` | `c3750fa8de308b2ac695ae7a6fa4c81d99a3e55e` | `c3750fa8de308b2ac695ae7a6fa4c81d99a3e55e` |

The two mt76 patch files also match their exact upstream blobs in
`overlay/hurryman/` and `overlay/yyh/` respectively.

## 4. Allowlist Enumeration

The allowlist rules from `scripts/extract-overlay.sh` were applied to the Git
trees of all three pinned SHAs.

### Hurryman

- Allowed blobs: `147`
- Already exact in fanboy: `101`
- Fanboy-absent or fanboy-different: `46`
- Exact in final applied tree: `46`
- Remaining real gaps: `0`

### YYH

- Allowed blobs: `215`
- Already exact in fanboy: `141`
- Fanboy-absent or fanboy-different: `74`
- Exact in final applied tree: `57`
- Remaining real gaps: `0`

The 17 remaining raw allowlist-path mismatches are the prior intentional or
superseded classifications:

- YYH mt76 `0006`/`0007` txpower patches: superseded by newer fanboy patches.
- YYH mt76 `9990`/`9991`: superseded by hurryman patches with the same
  subjects and fanboy-compatible contexts.
- YYH mt76 `9992`/`9993`: present as renumbered `9994`/`9995`; content matches
  exactly.
- YYH hostapd `370`: fanboy carries the same radio-mask logic.
- YYH hostapd `602`/`603`: fanboy `053` and `mtk-0015` carry the equivalent
  changes.
- YYH regdb `520`: intentional local customization.
- YYH mt76 `Makefile`: intentional fanboy source version plus the existing
  `kmod-airoha-eth` dependency fix; `PKG_RELEASE` is already `3`.
- YYH `config-6.18`: intentional hurryman CPU governor override.
- YYH `target.mk`: fanboy is the base priority for that file.
- YYH `an7581.dtsi`: intentional hurryman overclock overlay.
- YYH non-XR1710G DTS paths (`an7581-nokia-valyrian.dts`,
  `an7581-w1700k-ubi.dts`, `an7583.dtsi`): not XR1710G-specific.

## 5. Duplicate And Conflict Audit

PASS

- Duplicate `Subject:` lines in the same CI-relevant patch directory: `0`.
- CI-introduced exact same-file overlapping-hunk pair that reaches the build
  tree: `0`.
- Remaining numeric prefix collisions reach the tree only as different,
  non-overlapping patches: mt76 `0010` and `0013`, plus pre-existing upstream
  airoha `179`.

The apply run is the executable conflict gate and passed with zero rejects.

## Final

Status: COMPLETE

No remaining exact gaps from the prior audit. The applied tree contains the
hurryman `0012` update, the YYH `0003` update, YYH hostapd `Config.in`, all
three YYH wifi-scripts paths, and the YYH iwinfo `PKG_RELEASE` bump.
