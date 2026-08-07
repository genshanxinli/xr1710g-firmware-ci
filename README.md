# XR1710G Firmware CI

Pure CI repository for building Econet/Gemtek XR1710G OpenWrt firmware.

## Base and Overlay Priority

1. `OpenWRT-fanboy/OpenW1700k` at the SHA pinned in `upstream.lock.json` is the base.
2. `hurryman2212/OpenW1700k-test` `offload-oc` contributes new-only files and curated adaptation patches.
3. `YYH2913/openwrt` `xr1710g-6.18-integration` contributes new-only files, XR1710G support, and curated fixes.
4. Conflict priority is fanboy > hurryman > YYH2913.

The repo stores static overlays under `overlay/` and curated unified diffs under `patches/`.
`apply-patches.sh` copies new-only files without overwriting, then applies patches in priority order.

## Repository Structure

```
.github/workflows/build.yml             Manual firmware build workflow
.github/workflows/validate-patches.yml  Patch preflight and candidate validation
.github/workflows/sync-upstream.yml     Upstream tracking PR/issue workflow
apply-patches.sh                        Applies overlays to an OpenWrt clone
candidates/                             Candidate patches awaiting manual promotion
overlay/hurryman/                       New-only files from offload-oc
overlay/yyh/                            New-only files from YYH integration
overlay/xr1710g/                        XR1710G DTS and base-files
patches/hurryman/                       Curated hurryman adaptation patches
patches/yyh/                            Curated YYH adaptation patches
patches/xr1710g/                        XR1710G device/image patches
scripts/clone-base.sh                   Clone the locked fanboy base SHA
scripts/preflight-validate.sh           Apply patches and run prepare/compile checks
scripts/setup-validate-tree.sh          Build a configured validation OpenWrt tree
scripts/apply-candidates.sh             Apply candidates/ in validation clones
scripts/collect-build-errors.sh         Aggregate full-build failures
defconfig                               XR1710G full-feature configuration
upstreams.yml                           Tracked upstream repos and refs
upstream.lock.json                      Last known upstream SHAs
PLAN.md                                 Local implementation plan, gitignored
KANBAN.md                               Local kanban board, gitignored
```

Most hurryman changes are vendored as new files under `overlay/hurryman/`, including the SOE/XFRM and mt76 kernel patch series. `patches/hurryman/` only holds curated diffs that modify files already present in the fanboy base, so it intentionally contains fewer files.

## Patch Validation

`validate-patches.yml` runs on push/PR:

- `baseline-prepare` is the required patch application gate.
- `candidate-prepare` runs only when `candidates/**` changes or is manually requested.
- Candidate failures are report-only and never block the required baseline check.
- `workflow_dispatch` accepts `mode=compile` for a deeper manual audit.

Local validation:

```bash
bash scripts/validate-overlay.sh
```

Candidate layout mirrors OpenWrt target paths, for example `candidates/package/kernel/mt76/patches/`. Promote a green candidate with:

```bash
bash scripts/promote-candidate.sh package/kernel/mt76/patches/999-example.patch
```

## Build

The full firmware build is manual only:

```yaml
on:
  workflow_dispatch:
```

Run `XR1710G Firmware CI` from the GitHub Actions UI. Every run uploads artifacts.
To create a GitHub Release, run the same workflow from a `v*` tag.

## Upstream Tracking

`sync-upstream.yml` runs every 6 hours and checks `upstream.lock.json` against:

- fanboy `ubi2-oc`
- hurryman `offload-oc`
- YYH `xr1710g-6.18-integration`

When an upstream SHA changes, it refreshes overlays and the lock file.
If the refreshed overlay passes preflight, it opens or updates the `upstream-sync` PR.
If it conflicts, it creates an issue with the upstream change report and preflight report.

Refresh manually:

```bash
bash scripts/check-upstream.sh
bash scripts/refresh-upstream.sh
bash scripts/validate-overlay.sh
```
