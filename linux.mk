#------------------------------------
# kernel
#------------------------------------
linux_DIR = $(PWD)/package/linux
linux_DEFCONFIG = versatile_defconfig
linux_MAKEPARAM += ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)

linux_CONFIG = $(linux_DIR)/.config

$(linux_CONFIG) :
	$(MAKE) linux_config

linux_config :
	-$(call OVERWRITE1,$(linux_DIR),config/linux,.svn)
	$(MAKE) linux_oldconfig
	$(MAKE) linux_prepare
	$(MAKE) linux_scripts

$(addprefix linux_,clean distclean) :
	 $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) $(@:linux_%=%)

linux linux_% : $(linux_CONFIG)

$(eval $(call PACKAGE1,linux))
