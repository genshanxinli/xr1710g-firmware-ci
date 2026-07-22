#!/bin/bash
# apply-patches.sh -- Apply XR1710G CI patches to an OpenW1700k clone
# Usage: apply-patches.sh <path-to-openw1700k-clone> [<path-to-patches-dir>]
#
# The patches dir defaults to the directory containing this script's patches/ subdir.

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLONE="${1:?Usage: apply-patches.sh <path-to-openw1700k-clone> [<patches-dir>]}"
PATCHES="${2:-$SCRIPT_DIR/patches}"

if [ ! -d "$CLONE" ]; then
    echo "ERROR: clone directory not found: $CLONE"
    exit 1
fi

echo "Applying XR1710G patches to $CLONE"
echo "Patch base: $PATCHES"

# ---- Phase 1: New device DTS ----
echo "[010] Installing device DTS..."
if [ -d "$PATCHES/010-device-dts" ]; then
    cp -v "$PATCHES/010-device-dts/"* "$CLONE/target/linux/airoha/dts/"
fi

# ---- Phase 2: New base-files scripts ----
echo "[020] Installing base-files scripts..."
if [ -d "$PATCHES/020-base-files" ]; then
    # an7581-level files (uci-defaults, hotplug.d)
    if [ -d "$PATCHES/020-base-files/etc" ]; then
        cp -rv "$PATCHES/020-base-files/etc"/* "$CLONE/target/linux/airoha/an7581/base-files/etc/"
    fi
    # airoha-global files (sysctl.d, preinit)
    if [ -f "$PATCHES/020-base-files/etc/sysctl.d/13-nf-bridge.conf" ]; then
        cp -v "$PATCHES/020-base-files/etc/sysctl.d/13-nf-bridge.conf" \
            "$CLONE/target/linux/airoha/base-files/etc/sysctl.d/"
    fi
    if [ -f "$PATCHES/020-base-files/lib/preinit/03_create_devmem" ]; then
        cp -v "$PATCHES/020-base-files/lib/preinit/03_create_devmem" \
            "$CLONE/target/linux/airoha/base-files/lib/preinit/"
    fi
    if [ -f "$PATCHES/020-base-files/lib/preinit/04_set_netdev_label" ]; then
        cp -v "$PATCHES/020-base-files/lib/preinit/04_set_netdev_label" \
            "$CLONE/target/linux/airoha/base-files/lib/preinit/"
    fi
fi

# ---- Phase 1 (cont): Patches to existing files ----
echo "[030] Applying patches to existing files..."
if [ -d "$PATCHES/030-existing-file-patches" ]; then
    for p in "$PATCHES/030-existing-file-patches/"*.patch; do
        [ -f "$p" ] || continue
        echo "  Applying $(basename "$p")..."
        patch -p1 -d "$CLONE" < "$p" || exit 1
    done
fi

# ---- Phase 3: Airoha kernel patches ----
echo "[040] Installing airoha kernel patches..."
if [ -d "$PATCHES/040-kernel-patches-airoha" ]; then
    cp -v "$PATCHES/040-kernel-patches-airoha/"*.patch \
        "$CLONE/target/linux/airoha/patches-6.18/"
fi

echo "[050] Installing generic kernel patches..."
if [ -d "$PATCHES/050-kernel-patches-generic" ]; then
    cp -v "$PATCHES/050-kernel-patches-generic/"*.patch \
        "$CLONE/target/linux/generic/pending-6.18/"
fi

# ---- Phase 4: mt76 patches ----
echo "[060] Installing mt76 patches..."
if [ -d "$PATCHES/060-mt76/patches" ]; then
    cp -v "$PATCHES/060-mt76/patches/"*.patch \
        "$CLONE/package/kernel/mt76/patches/"
fi
if [ -f "$PATCHES/060-mt76/Makefile.patch" ]; then
    echo "  Applying Makefile.patch..."
    patch -p1 -d "$CLONE" < "$PATCHES/060-mt76/Makefile.patch" || exit 1
fi

# ---- Phase 5: hostapd + wireless-regdb patches ----
echo "[070] Installing hostapd patches..."
if [ -d "$PATCHES/070-hostapd" ]; then
    cp -v "$PATCHES/070-hostapd/"*.patch \
        "$CLONE/package/network/services/hostapd/patches/"
fi

echo "[080] Installing wireless-regdb patches..."
if [ -d "$PATCHES/080-wireless-regdb" ]; then
    cp -v "$PATCHES/080-wireless-regdb/"*.patch \
        "$CLONE/package/firmware/wireless-regdb/patches/"
fi

# ---- Phase 6: LuCI apps ----
echo "[090] Installing LuCI apps..."
if [ -d "$PATCHES/090-luci" ]; then
    for app in "$PATCHES/090-luci/"*/; do
        [ -d "$app" ] || continue
        appname="$(basename "$app")"
        echo "  Installing $appname..."
        cp -r "$app" "$CLONE/package/$appname"
    done
fi

echo ""
echo "All patches applied successfully."
