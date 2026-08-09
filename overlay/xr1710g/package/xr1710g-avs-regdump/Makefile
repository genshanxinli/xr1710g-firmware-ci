include $(TOPDIR)/rules.mk

PKG_NAME:=xr1710g-avs-regdump
PKG_RELEASE:=1
PKG_LICENSE:=GPL-2.0

# FIX-02 verification helper: in-kernel ioremap read of the AVS voltage
# control registers (0x1fa202a0 RG_AVS_OUT_EN, 0x1fa202e0 RG_DATA_AVS_DAC).
# STRICT_DEVMEM blocks /dev/mem user access, so a tiny module is the only
# way to verify the 941/942 boost actually took effect on the running box.

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define KernelPackage/xr1710g-avs-regdump
  SUBMENU:=Other modules
  TITLE:=XR1710G AVS register dump (FIX-02 verify)
  DEPENDS:=@TARGET_airoha
  FILES:=$(PKG_BUILD_DIR)/avs_regdump.ko
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) ./src/avs_regdump.c $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C "$(LINUX_DIR)" \
		M="$(PKG_BUILD_DIR)" \
		ARCH="$(LINUX_KARCH)" \
		CROSS_COMPILE="$(TARGET_CROSS)" \
		KCFLAGS="-DMODULE" \
		modules
endef

define KernelPackage/xr1710g-avs-regdump/install
	$(INSTALL_DIR) $(1)/lib/modules/$(LINUX_VERSION)/extra
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/avs_regdump.ko $(1)/lib/modules/$(LINUX_VERSION)/extra/
endef

$(eval $(call KernelPackage,xr1710g-avs-regdump))
