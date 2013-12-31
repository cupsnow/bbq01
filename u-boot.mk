#------------------------------------
# bootloader
#------------------------------------
uboot_DIR = $(PWD)/package/u-boot
uboot_DEFCONFIG = versatilepb_config
uboot_MAKEPARAM += CROSS_COMPILE=$(CROSS_COMPILE)

uboot_CONFIG = $(uboot_DIR)/include/config.mk

$(uboot_CONFIG) :
	$(MAKE) uboot_config

uboot_config :
	-$(call OVERWRITE1,$(uboot_DIR),config/uboot,.svn)
	$(MAKE) uboot_$(uboot_DEFCONFIG)

$(addprefix uboot_,clean distclean) :
	 $(MAKE) $(uboot_MAKEPARAM) -C $(uboot_DIR) $(@:uboot_%=%)

uboot uboot_% : $(uboot_CONFIG)

$(eval $(call PACKAGE1,uboot))
