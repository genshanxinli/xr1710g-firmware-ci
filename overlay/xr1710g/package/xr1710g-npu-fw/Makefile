include $(TOPDIR)/rules.mk

PKG_NAME:=xr1710g-npu-fw
PKG_RELEASE:=1
PKG_LICENSE:=Proprietary
PKG_LICENSE_FILES:=

# XR1710G NPU firmware — self-built from the Airoha NPU FDK source SDK
# (github.com/hurryman2212/airoha-npu-fdk, fw version 7.7).
#
# The stock linux-firmware blob (20260622-r2) does NOT implement
# WLAN_FUNC_GET_WAIT_RXDESC_BASE (replies 0x0, fw version 0.0); the
# misbehaving firmware DMA-corrupts host memory and the box panics within
# minutes once the NPU node is enabled (observed on-device: fw version 0.0,
# 0x7fffffc0 high-half pointer corruption in wpa_supplicant/grep/awk).
# The FDK 7.7 firmware implements the full command set.
#
# Files are installed to a private path and copied over the
# airoha-en7581-mt7996-npu-firmware files in postinst (OpenWrt does not
# allow two packages to own the same file).

include $(INCLUDE_DIR)/package.mk

define Package/xr1710g-npu-fw
  SECTION:=firmware
  CATEGORY:=Firmware
  TITLE:=XR1710G NPU firmware (FDK 7.7)
  DEPENDS:=kmod-airoha-npu
  PROVIDES:=xr1710g-npu-fw
endef

define Package/xr1710g-npu-fw/description
  NPU firmware 7.7 for XR1710G (AN7581), built from airoha-npu-fdk.
  Replaces the stock 20260622-r2 blob (fw version 0.0, missing
  WLAN_FUNC_GET_WAIT_RXDESC_BASE, DMA-corrupts host memory).
endef

define Build/Compile
endef

define Package/xr1710g-npu-fw/install
	$(INSTALL_DIR) $(1)/usr/lib/xr1710g-npu-fw
	$(INSTALL_DATA) ./files/usr/lib/xr1710g-npu-fw/*.bin \
		$(1)/usr/lib/xr1710g-npu-fw/
endef

define Package/xr1710g-npu-fw/postinst
#!/bin/sh
# overwrite the stock (20260622-r2) NPU firmware with the FDK 7.7 build.
# During image build the target rootfs is $$IPKG_INSTROOT; on a running
# device it is unset (same pattern as xr1710g-mt7996-fw).
if [ -n "$$IPKG_INSTROOT" ]; then
	SRC="$$IPKG_INSTROOT/usr/lib/xr1710g-npu-fw"
	DEST="$$IPKG_INSTROOT/lib/firmware/airoha"
else
	SRC="/usr/lib/xr1710g-npu-fw"
	DEST="/lib/firmware/airoha"
fi
if [ -d "$$SRC" ]; then
	mkdir -p "$$DEST"
	cp -f "$$SRC"/en7581_MT7996_npu_*.bin "$$DEST/" 2>/dev/null
	rm -rf "$$SRC"
	echo "xr1710g-npu-fw: installed FDK 7.7 firmware family"
fi
exit 0
endef

$(eval $(call BuildPackage,xr1710g-npu-fw))
