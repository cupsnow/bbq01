# $Id$
BUILDERDIR := $(abspath .)/.builder
include $(BUILDERDIR)/proj.mk

ROOTFSDIR ?= $(BUILDDIR)/rootfs
RELEASEDIR ?= $(BUILDDIR)/release

export TOOLCHAIN := $(PROJDIR)/tool/toolchain
export CROSS_COMPILE := arm-none-linux-gnueabi-
export PATH := $(PROJDIR)/tool/bin:$(TOOLCHAIN)/bin:$(PATH)

#------------------------------------
#------------------------------------
tool_TARGET =

all : ;

test :
	@echo "HOST is `$(CC) -dumpmachine`"

#------------------------------------
# bootloader
#------------------------------------
uboot_DIR = $(PWD)/package/u-boot
uboot_DEFCONFIG = versatileqemu_config
uboot_MAKEPARAM += ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)

uboot_defconfig :
	$(MAKE) uboot_$(uboot_DEFCONFIG)

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

tool/bin/mkimage : uboot_tools
	$(MKDIR) $(PWD)/tool/bin/
	$(INSTALL) $(uboot_DIR)/tools/mkimage $(PWD)/tool/bin/ 

tool_TARGET += tool/bin/mkimage

#------------------------------------
# kernel
#------------------------------------
linux_DIR = $(PWD)/package/linux
linux_DEFCONFIG = versatile_defconfig
linux_MAKEPARAM += ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)
linux_MAKEPARAM += CONFIG_INITRAMFS_SOURCE=$(CONFIG_INITRAMFS_SOURCE)

linux_defconfig :
	$(MAKE) linux_$(linux_DEFCONFIG) 

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

#------------------------------------
# busybox
#------------------------------------
busybox_DIR = $(PWD)/package/busybox
busybox_DEFCONFIG = defconfig
busybox_MAKEPARAM += CROSS_COMPILE=$(CROSS_COMPILE) 
busybox_MAKEPARAM += CONFIG_PREFIX=$(CONFIG_PREFIX)

busybox_defconfig :
	$(MAKE) busybox_$(busybox_DEFCONFIG) 

busybox_CONFIG = $(busybox_DIR)/.config

$(busybox_CONFIG) :
	$(MAKE) busybox_config

busybox_config :
	-$(call OVERWRITE1,$(busybox_DIR),config/busybox,.svn)
	$(MAKE) $(busybox_MAKEPARAM) busybox_oldconfig

$(addprefix busybox_,clean distclean) :
	$(MAKE) $(busybox_MAKEPARAM) -C $(busybox_DIR) $(@:busybox_%=%)

busybox busybox_% : $(busybox_CONFIG) 

$(eval $(call PACKAGE1,busybox))

#------------------------------------
#------------------------------------
initramfs_rootfs :
	-$(call OVERWRITE1,$(ROOTFSDIR),$(DESTDIR),.svn */lib/*.a)
	cd $(ROOTFSDIR) && \
	  find . | cpio -o --format=newc > $(RELEASEDIR)/rootfs.img
	cd $(RELEASEDIR) && \
	  gzip -c rootfs.img > rootfs.img.gz

initramfs : linux busybox
	$(MAKE) CONFIG_PREFIX=$(DESTDIR) busybox_install
	$(MAKE) initramfs_rootfs
	$(MAKE) CONFIG_INITRAMFS_SOURCE=$(ROOTFSDIR) linux_uImage
	$(MKDIR) $(RELEASEDIR)
	$(CP) $(linux_DIR)/arch/arm/boot/uImage $(RELEASEDIR)
	$(CP) $(uboot_DIR)/u-boot.bin $(RELEASEDIR)

#------------------------------------
#------------------------------------
tool : $(tool_TARGET)

#------------------------------------
#------------------------------------
distclean :


clean :

#------------------------------------
#------------------------------------
.PHONY : tool
