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

include $(INCLUDE_DIR)/package.mk

define Package/xr1710g-mt7996-fw
  SECTION:=firmware
  CATEGORY:=Firmware
  TITLE:=XR1710G MT7996 WiFi firmware (2026-07-21 family)
  DEPENDS:=
  PROVIDES:=xr1710g-mt7996-fw
endef

define Package/xr1710g-mt7996-fw/description
  MT7996 WiFi firmware family 2026-07-21 for XR1710G (AN7581+MT7996).
  Replaces the stock 2026-03-11 family (WM MCU timeout loop after ~31 min).
endef

define Build/Compile
endef

define Package/xr1710g-mt7996-fw/install
	$(INSTALL_DIR) $(1)/lib/firmware/mediatek/mt7996
	$(INSTALL_DATA) ./files/lib/firmware/mediatek/mt7996/mt7996_rom_patch.bin \
		$(1)/lib/firmware/mediatek/mt7996/
	$(INSTALL_DATA) ./files/lib/firmware/mediatek/mt7996/mt7996_wm.bin \
		$(1)/lib/firmware/mediatek/mt7996/
	$(INSTALL_DATA) ./files/lib/firmware/mediatek/mt7996/mt7996_dsp.bin \
		$(1)/lib/firmware/mediatek/mt7996/
	$(INSTALL_DATA) ./files/lib/firmware/mediatek/mt7996/mt7996_wa.bin \
		$(1)/lib/firmware/mediatek/mt7996/
endef

$(eval $(call BuildPackage,xr1710g-mt7996-fw))
