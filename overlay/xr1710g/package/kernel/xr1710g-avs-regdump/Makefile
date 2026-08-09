include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

# XR1710G AVS register dump (FIX-02 verification helper).
# The module source lives in the kernel tree (patches/yyh/kernel/943);
# this package exposes it so the .ko gets packaged into the image.
# Load on device: insmod kmod-xr1710g-avs-regdump ; dmesg | grep avs_regdump

define KernelPackage/xr1710g-avs-regdump
  SUBMENU:=Other modules
  TITLE:=XR1710G AVS register dump (FIX-02 verify)
  DEPENDS:=@TARGET_airoha
  KCONFIG:=CONFIG_XR1710G_AVS_REGDUMP=m
  FILES:=$(LINUX_DIR)/drivers/misc/avs_regdump.ko
endef

define KernelPackage/xr1710g-avs-regdump/description
  Read-only dump of the AVS voltage control registers
  (RG_AVS_OUT_EN 0x1fa202a0, RG_DATA_AVS_DAC 0x1fa202e0).
endef

$(eval $(call KernelPackage,xr1710g-avs-regdump))
