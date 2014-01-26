# $Id$
BUILDERDIR := $(abspath .)/.builder
include $(BUILDERDIR)/proj.mk

 # qemu beaglebone beagleboard
BOARD = beaglebone

ROOTFSDIR ?= $(BUILDDIR)/rootfs
RELEASEDIR ?= $(BUILDDIR)/release

export TOOLCHAIN := $(PROJDIR)/tool/toolchain
export CROSS_COMPILE := arm-none-linux-gnueabi-
export PATH := $(PROJDIR)/tool/bin:$(TOOLCHAIN)/bin:$(PATH)
SHELL := /bin/bash

#------------------------------------
#------------------------------------
tool_TARGET =

all : ;

test :
	@echo "HOST is `$(CC) -dumpmachine`"
	source $(linux_DIR)/scripts/gen_initramfs_list.sh -h

#------------------------------------
# bootloader
#------------------------------------
uboot_DIR = $(PWD)/package/u-boot
uboot_MAKEPARAM += ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)

uboot_qemu_defconfig = versatileqemu_config

uboot_beaglebone_defconfig = am335x_evm_config

uboot_beagleboard_defconfig = omap3_beagle_config

uboot_CONFIG = $(uboot_DIR)/include/config.mk

uboot_defconfig :
	$(MAKE) $(uboot_MAKEPARAM) -C $(uboot_DIR) $(uboot_$(BOARD)_defconfig)

$(uboot_CONFIG) :
	$(MAKE) uboot_config

uboot_config :
	-$(call OVERWRITE1,$(uboot_DIR),config/uboot_$(BOARD),.svn)
	$(MAKE) uboot_defconfig

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
linux_MAKEPARAM += ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)
linux_MAKEPARAM += CONFIG_INITRAMFS_SOURCE="$(CONFIG_INITRAMFS_SOURCE)"
linux_MAKEPARAM += INSTALL_HDR_PATH="$(INSTALL_HDR_PATH)"
# for uImage
linux_MAKEPARAM += LOADADDR=0x80008000

linux_qemu_defconfig = versatile_defconfig

linux_beaglebone_defconfig = omap2plus_defconfig 

linux_beagleboard_defconfig = omap2plus_defconfig

linux_CONFIG = $(linux_DIR)/.config tool/bin/mkimage

linux_defconfig :
	$(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) $(linux_$(BOARD)_defconfig)

$(linux_DIR)/.config :
	$(MAKE) linux_config

linux_config :
	-$(call OVERWRITE1,$(linux_DIR),config/linux_$(BOARD),.svn)
	$(MAKE) linux_oldconfig
	$(MAKE) linux_prepare
	$(MAKE) linux_scripts

$(addprefix linux_,clean distclean) :
	 $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) $(@:linux_%=%)

linux_headers_install : INSTALL_HDR_PATH ?= $(DESTDIR)
linux_headers_install : $(linux_CONFIG)
	$(MKDIR) $(INSTALL_HDR_PATH)
	$(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) $(@:linux_%=%)

linux_uImage : CONFIG_INITRAMFS_SOURCE ?= $(DESTDIR)
linux_uImage : $(linux_CONFIG)
	$(MKDIR) $(CONFIG_INITRAMFS_SOURCE)
	$(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) $(@:linux_%=%)

linux linux_% : $(linux_CONFIG)

$(eval $(call PACKAGE1,linux))

#------------------------------------
# busybox
#------------------------------------
busybox_DIR = $(PWD)/package/busybox
busybox_MAKEPARAM += CROSS_COMPILE=$(CROSS_COMPILE) 
busybox_MAKEPARAM += CONFIG_PREFIX=$(or $(CONFIG_PREFIX),$(DESTDIR))
busybox_MAKEPARAM += EXTRA_CFLAGS="-I$(DESTDIR)/include"

busybox_defconfig :
	$(MAKE) busybox_defconfig 

busybox_CONFIG = $(busybox_DIR)/.config linux_headers_install

$(busybox_DIR)/.config :
	$(MAKE) busybox_config

busybox_config :
	-$(call OVERWRITE1,$(busybox_DIR),config/busybox,.svn)
	$(MAKE) $(busybox_MAKEPARAM) busybox_oldconfig

$(addprefix busybox_,clean distclean) :
	$(MAKE) $(busybox_MAKEPARAM) -C $(busybox_DIR) $(@:busybox_%=%)

busybox_install : $(busybox_CONFIG)
	$(MKDIR) $(or $(CONFIG_PREFIX),$(DESTDIR))
	$(MAKE) $(busybox_MAKEPARAM) -C $(busybox_DIR) $(@:busybox_%=%)

busybox busybox_% : $(busybox_CONFIG) 

$(eval $(call PACKAGE1,busybox))

#------------------------------------
#------------------------------------
qemu_DIR = $(PWD)/package/qemu
qemu_TARGET = i386-softmmu,x86_64-softmmu arm-softmmu

qemu_CONFIG = $(qemu_DIR)/config-host.mak

$(qemu_DIR)/config-host.mak :
	$(MAKE) qemu_config
	
qemu_config :
	cd $(qemu_DIR) && \
	  ./configure --prefix=/ --target-list="$(qemu_TARGET)" 

qemu qemu_% : $(qemu_CONFIG)
	$(MAKE) DESTDIR=$(PWD)/tool -C $(qemu_DIR) $(patsubst qemu,,$(@:qemu_%=%))

#------------------------------------
#------------------------------------
initramfs_rootfs : busybox
	$(MAKE) CONFIG_PREFIX=$(DESTDIR) busybox_install
	-$(call OVERWRITE1,$(ROOTFSDIR),config/initramfs,.svn)
	-$(call OVERWRITE1,$(ROOTFSDIR),$(DESTDIR),.svn */lib/*.a)

initramfs_rootfs_cpio :
	cd $(ROOTFSDIR) && \
	  find . | cpio -o --format=newc > $(RELEASEDIR)/rootfs.img
	cd $(RELEASEDIR) && \
	  gzip -c rootfs.img > rootfs.img.gz
	$(RM) $(RELEASEDIR)/rootfs.img

initramfs_rootfs_img :
	$(MKDIR) $(RELEASEDIR)
	cd $(linux_DIR) && \
	  source scripts/gen_initramfs_list.sh -o $(RELEASEDIR)/initramfs \
	    $(PWD)/config/initramfs_list $(ROOTFSDIR) 
	
initramfs : initramfs_rootfs linux
	$(MAKE) initramfs_rootfs_img
	$(MAKE) linux_uImage # CONFIG_INITRAMFS_SOURCE=$(ROOTFSDIR)
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
