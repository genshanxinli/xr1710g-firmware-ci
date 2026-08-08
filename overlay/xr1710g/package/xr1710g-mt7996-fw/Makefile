include $(TOPDIR)/rules.mk

PKG_NAME:=xr1710g-mt7996-fw
PKG_RELEASE:=1
PKG_LICENSE:=Proprietary
PKG_LICENSE_FILES:=

# MT7996 WiFi firmware family 2026-07-21 (fanboy mt76-firmware 260806).
# Replaces the mt76-tree 2026-03-11 family which goes into a WM MCU
# initialization timeout loop ~31 min after boot (root cause R3):
#   Timeout for initializing firmware -> chip full reset failed (43s cycle)
#   -> WiFi completely dead (no beacon, station dump hangs, iwinfo D-state).
# The 2026-07-21 family fixes it with zero driver changes.
# Verified on-device: 3x AP-ENABLED, beacon visible at 99% signal,
# 0 firmware-init timeouts for 3h+.
#
# The files are installed to a private path and copied over the
# kmod-mt7996-firmware files in postinst (package file conflicts are not
# allowed in OpenWrt for files owned by another package).

include $(INCLUDE_DIR)/package.mk

define Package/xr1710g-mt7996-fw
  SECTION:=firmware
  CATEGORY:=Firmware
  TITLE:=XR1710G MT7996 WiFi firmware (2026-07-21 family)
  DEPENDS:=kmod-mt7996-firmware
  PROVIDES:=xr1710g-mt7996-fw
endef

define Package/xr1710g-mt7996-fw/description
  MT7996 WiFi firmware family 2026-07-21 for XR1710G (AN7581+MT7996).
  Replaces the stock 2026-03-11 family (WM MCU timeout loop after ~31 min).
  Overwrites kmod-mt7996-firmware files at postinst time.
endef

define Build/Compile
endef

define Package/xr1710g-mt7996-fw/install
	$(INSTALL_DIR) $(1)/usr/lib/xr1710g-fw
	$(INSTALL_DATA) ./files/usr/lib/xr1710g-fw/*.bin \
		$(1)/usr/lib/xr1710g-fw/
endef

define Package/xr1710g-mt7996-fw/postinst
#!/bin/sh
# overwrite the stock (2026-03-11) MT7996 firmware with the 2026-07-21 family
if [ -d /usr/lib/xr1710g-fw ]; then
	cp -f /usr/lib/xr1710g-fw/mt7996_*.bin /lib/firmware/mediatek/mt7996/ 2>/dev/null
	rm -rf /usr/lib/xr1710g-fw
	echo "xr1710g-mt7996-fw: installed 2026-07-21 firmware family"
fi
exit 0
endef

$(eval $(call BuildPackage,xr1710g-mt7996-fw))
