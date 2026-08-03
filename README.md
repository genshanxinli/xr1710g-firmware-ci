# XR1710G Firmware CI

Pure CI repository for building Econet/Gemtek XR1710G OpenWrt firmware.

## Base and Overlay Priority

1. `OpenWRT-fanboy/OpenW1700k` `offload` HEAD is cloned as the base.
2. `hurryman2212/OpenW1700k-test` `offload-oc` contributes new-only files and curated adaptation patches.
3. `YYH2913/openwrt` `xr1710g-6.18-integration` contributes new-only files, XR1710G support, and curated fixes.
4. Conflict priority is fanboy > hurryman > YYH2913.

The repo stores static overlays under `overlay/` and curated unified diffs under `patches/`.
`apply-patches.sh` copies new-only files without overwriting, then applies patches in priority order.

## Repository Structure

```
.github/workflows/build.yml          Manual firmware build workflow
.github/workflows/sync-upstream.yml  Upstream tracking PR/issue workflow
apply-patches.sh                     Applies overlays to an OpenWrt clone
overlay/hurryman/                    New-only files from offload-oc
overlay/yyh/                         New-only files from YYH integration
overlay/xr1710g/                     XR1710G DTS and base-files
patches/hurryman/                    Curated hurryman adaptation patches
patches/yyh/                         Curated YYH adaptation patches
patches/xr1710g/                     XR1710G device/image patches
defconfig                            XR1710G full-feature configuration
upstreams.yml                        Tracked upstream repos and refs
upstream.lock.json                   Last known upstream SHAs
PLAN.md                              Local implementation plan, gitignored
KANBAN.md                            Local kanban board, gitignored
```

## Build

The full firmware build is manual only:

```yaml
on:
  workflow_dispatch:
```

Run `XR1710G Firmware CI` from the GitHub Actions UI. Every run uploads artifacts.
To create a GitHub Release, run the same workflow from a `v*` tag.

Local overlay validation:

```bash
git clone --depth 1 --branch offload https://github.com/OpenWRT-fanboy/OpenW1700k.git openwrt
bash apply-patches.sh openwrt "$PWD"
```

## Upstream Tracking

`sync-upstream.yml` runs every 6 hours and checks `upstream.lock.json` against:

- fanboy `offload`
- hurryman `offload-oc`
- YYH `xr1710g-6.18-integration`

When an upstream SHA changes, it refreshes overlays and the lock file.
If the refreshed overlay applies cleanly, it opens or updates the `upstream-sync` PR.
If it conflicts, it creates an issue with `docs/upstream-changes.md`.

Refresh manually:

```bash
bash scripts/check-upstream.sh
bash scripts/refresh-upstream.sh
bash scripts/validate-overlay.sh
```
