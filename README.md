# XR1710G Firmware CI

Builds XR1710G (Econet XR1710G) OpenWrt firmware using a patch overlay on top of
[openwrt-fanboy/OpenW1700k](https://github.com/openwrt-fanboy/OpenW1700k).

## Repository Structure

```
.github/workflows/build.yml   CI workflow (push, workflow_dispatch, v* tags)
apply-patches.sh              Script to apply patches onto an OpenW1700k clone
patches/                      Patch overlay directories:
  010-device-dts/               New DTS file for XR1710G
  020-base-files/               New base-files scripts (uci-defaults, hotplug, sysctl, preinit)
  030-existing-file-patches/    Unified diffs for files that exist in base
  040-kernel-patches-airoha/    YYH2913-only airoha kernel patches
  050-kernel-patches-generic/   YYH2913-only generic kernel patches (bridge flow offload, SOE)
  060-mt76/                     mt76 WiFi driver patches + Makefile bump
  070-hostapd/                  hostapd interface short-circuit + 6GHz no-DFS
  080-wireless-regdb/           US regulatory power limits for XR1710G
  090-luci/                     LuCI application packages
defconfig                     Saved kernel/target configuration
```

## How it Works

1. **CI workflow** clones OpenW1700k at a pinned commit
2. **apply-patches.sh** copies new files and applies unified diffs in numbered order
3. `./scripts/feeds update -a && ./scripts/feeds install -a`
4. `cp defconfig .config && make defconfig`
5. `make -j$(nproc) V=s` produces `sysupgrade.itb`
6. Artifact uploaded on every build; GitHub Release on `v*` tags

## Triggering a Build

- Push to `main` triggers an automatic build
- `workflow_dispatch` via GitHub Actions UI for manual builds
- Push a `v*` tag (e.g., `v1.0.0`) creates a GitHub Release with the firmware attached

## Patch Sources

- **Base:** openwrt-fanboy/OpenW1700k (cleaner patches, closer to upstream)
- **Overlay:** YYH2913/openwrt `xr1710g-6.18-integration` branch (device support, bridge flow offload, SOE, LuCI, WiFi fixes)

## Regenerating defconfig

After adding or removing packages (e.g., new LuCI apps), regenerate:

```bash
cd openwrt
make menuconfig       # select Target Profile: Econet XR1710G UBI
make savedefconfig
cp defconfig ../ci-repo/defconfig
```
