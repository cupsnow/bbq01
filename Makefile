# $Id$
BUILDERDIR := $(abspath .)/.builder
include $(BUILDERDIR)/proj.mk

ifeq ("$(wildcard config.mk)","")
  $(error Please execute ./configure before build project)
endif
include config.mk

SEARCH_COMPILE ?= $(firstword $(wildcard $(PROJDIR)/tool/toolchain/bin/*gcc))
CROSS_COMPILE ?= $(patsubst %gcc,%,$(notdir $(SEARCH_COMPILE)))
TOOLCHAIN ?= $(patsubst %/bin/$(CROSS_COMPILE)gcc,%,$(SEARCH_COMPILE))

MYPATH = $(PROJDIR)/package/u-boot/tools
MYPATH += $(TOOLCHAIN)/bin
MYPATH += $(PROJDIR)/tool/bin
SHELL := /bin/bash

export PATH := $(subst $(SPACE),:,$(MYPATH))$(PATH:%=:)$(PATH)

#------------------------------------
#
all:
	@echo "Please select other goals" 

#------------------------------------
# bootloader
#
uboot_DIR = $(PWD)/package/u-boot
uboot_MAKEPARAM += CROSS_COMPILE=$(CROSS_COMPILE)

uboot_%: uboot_$(BOARD)_%;

uboot_qemu_defconfig:
	$(uboot_MAKEENV) $(MAKE) $(uboot_MAKEPARAM) -C $(uboot_DIR) \
	  versatileqemu_config

uboot_qemu_config:
	$(call OVERWRITE,$(uboot_DIR),config/qemu/u-boot,.svn)
	$(uboot_MAKEENV) $(MAKE) $(uboot_MAKEPARAM) -C $(uboot_DIR) \
	  versatileqemu_config

uboot_bb_defconfig:
	$(uboot_MAKEENV) $(MAKE) $(uboot_MAKEPARAM) -C $(uboot_DIR) \
	  omap3_beagle_config

uboot_bb_config:
	$(call OVERWRITE,$(uboot_DIR),config/bb/u-boot,.svn)
	$(uboot_MAKEENV) $(MAKE) $(uboot_MAKEPARAM) -C $(uboot_DIR) \
	  omap3_beagle_config

uboot_clean uboot_distclean:
	$(uboot_MAKEENV) $(MAKE) $(uboot_MAKEPARAM) -C $(uboot_DIR) \
	  $(patsubst uboot,,$(@:uboot_%=%))

$(uboot_DIR)/include/config.h:
	$(MAKE) uboot_config

uboot uboot_%: | $(uboot_DIR)/include/config.h
	$(uboot_MAKEENV) $(MAKE) $(uboot_MAKEPARAM) -C $(uboot_DIR) \
	  $(patsubst uboot,,$(@:uboot_%=%))

#------------------------------------
# kernel
#
linux_DIR = $(PWD)/package/linux
linux_MAKEPARAM += ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)
linux_MAKEPARAM += INSTALL_HDR_PATH="$(or $(INSTALL_HDR_PATH),$(DESTDIR))"
linux_MAKEPARAM += INSTALL_MOD_PATH="$(or $(INSTALL_MOD_PATH),$(DESTDIR))"
linux_MAKEPARAM += LOADADDR=$(linux_$(BOARD)_LOADADDR)
linux_MAKEPARAM += CONFIG_INITRAMFS_SOURCE="$(CONFIG_INITRAMFS_SOURCE)"

linux_%: linux_$(BOARD)_%;

linux_qemu_LOADADDR = 0x00010000

linux_qemu_defconfig:
	$(linux_MAKEENV) $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) \
	  versatile_defconfig

linux_qemu_config:
	$(call OVERWRITE,$(linux_DIR),config/qemu/linux,.svn)
	$(MAKE) linux_oldconfig linux_prepare

linux_bb_LOADADDR = 0x80008000

linux_bb_defconfig:
	$(linux_MAKEENV) $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) \
	  omap2plus_defconfig

linux_bb_config:
	$(call OVERWRITE,$(linux_DIR),config/bb/linux,.svn)
	$(MAKE) linux_oldconfig linux_prepare

linux_clean linux_distclean:
	$(linux_MAKEENV) $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) \
	  $(patsubst linux,,$(@:linux_%=%))

$(linux_DIR)/.config:
	$(MAKE) linux_config

linux linux_%: | $(linux_DIR)/.config
	$(linux_MAKEENV) $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) \
	  $(patsubst linux,,$(@:linux_%=%))

#------------------------------------
# busybox
#
busybox_DIR = $(PWD)/package/busybox
busybox_MAKEPARAM += CROSS_COMPILE=$(CROSS_COMPILE)
busybox_MAKEPARAM += CONFIG_PREFIX="$(or $(CONFIG_PREFIX),$(DESTDIR))"
busybox_MAKEPARAM += EXTRA_CFLAGS="-I$(DESTDIR)/include"

busybox_%: busybox_$(BOARD)_%;

busybox_defconfig:
	$(busybox_MAKEENV) $(MAKE) $(busybox_MAKEPARAM) -C $(busybox_DIR) \
	  defconfig

busybox_config:
	$(call OVERWRITE,$(busybox_DIR),config/common/busybox,.svn)
	$(MAKE) busybox_oldconfig busybox_prepare

busybox_clean busybox_distclean:
	$(busybox_MAKEENV) $(MAKE) $(busybox_MAKEPARAM) -C $(busybox_DIR) \
	  $(patsubst busybox,,$(@:busybox_%=%))

$(busybox_DIR)/.config:
	$(MAKE) busybox_config

busybox busybox_%: | $(busybox_DIR)/.config
	$(busybox_MAKEENV) $(MAKE) $(busybox_MAKEPARAM) -C $(busybox_DIR) \
	  $(patsubst busybox,,$(@:busybox_%=%))

#------------------------------------
# initramfs
#
initramfs:
	$(MAKE) linux linux_headers_install uboot
	$(MAKE) busybox
	$(MAKE) busybox_install
	$(MAKE) initramfs_libc
	$(MAKE) initramfs_destdir
	$(MAKE) initramfs_prebuilt
	$(MAKE) initramfs_image

initramfs_LIBC_PATH = $(TOOLCHAIN)/arm-none-linux-gnueabi/libc/lib
initramfs_LIBC += ld{-*.so,-*.so.*} 
initramfs_LIBC += libgcc_s{.so,.so.*}
initramfs_LIBC += lib{c,crypt,dl,m,rt,util,nsl,pthread,resolv}{-*.so,.so.*}
initramfs_libc:
	$(MKDIR) $(INITRAMFS)/{lib,usr/lib}
	$(CP) $(addprefix $(initramfs_LIBC_PATH)/,$(initramfs_LIBC)) $(INITRAMFS)/lib

initramfs_DESTDIR = bin sbin usr etc init linuxrc 
initramfs_DESTDIR += lib/*-*.so lib/*.so.* lib/*.so
initramfs_destdir:
	$(MKDIR) $(INITRAMFS)/{dev,proc,sys,var,mnt,lib}
	$(foreach i,$(initramfs_DESTDIR),$(if $(wildcard $(DESTDIR)/$(i)),$(CP) $(DESTDIR)/$(i) $(INITRAMFS)/$(dir $(i));))

initramfs_PREBUILT = config/common/prebuilt config/$(BOARD)/prebuilt
initramfs_prebuilt:
	$(foreach i,$(initramfs_PREBUILT),$(if $(wildcard $(i)),$(CP) $(i)/* $(INITRAMFS);))

initramfs_IMAGE = $(PROJDIR)/config/common/initramfs_list
initramfs_IMAGE += $(INITRAMFS) 
initramfs_image:
	$(MAKE) CONFIG_INITRAMFS_SOURCE="$(initramfs_IMAGE)" linux_uImage

#------------------------------------
# rootfs
#
rootfs:
	$(MAKE) linux_headers_install
	$(MAKE) busybox
	$(MAKE) busybox_install
	$(MAKE) rootfs_libc
	$(MAKE) rootfs_package
	$(MAKE) rootfs_destdir
	$(MAKE) rootfs_prebuilt
	$(MAKE) rootfs_image

rootfs_libc:
	$(MKDIR) $(ROOTFS)/{lib,usr/lib}
	$(CP) $(addprefix $(initramfs_LIBC_PATH)/,$(initramfs_LIBC)) $(ROOTFS)/lib

rootfs_package: ;

rootfs_DESTDIR = bin sbin usr etc init 
rootfs_DESTDIR += lib/*-*.so lib/*.so.* lib/*.so
rootfs_destdir:
	$(MKDIR) $(ROOTFS)/{dev,proc,sys,var,mnt,lib}
	$(foreach i,$(rootfs_DESTDIR),$(if $(wildcard $(DESTDIR)/$(i)),$(CP) $(DESTDIR)/$(i) $(ROOTFS)/$(dir $(i));))

rootfs_PREBUILT = config/common/prebuilt config/$(BOARD)/prebuilt
rootfs_prebuilt:
	$(foreach i,$(rootfs_PREBUILT),$(if $(wildcard $(i)),$(CP) $(i)/* $(ROOTFS);))

rootfs_image:
	$(MKDIR) $(RELEASE)
	$(RM) $(RELEASE)/rootfs.img
	mksquashfs $(ROOTFS) $(RELEASE)/rootfs.img

#------------------------------------
#
release: release_$(BOARD)

release_bb:
	$(MKDIR) $(RELEASE)
	$(CP) $(linux_DIR)/arch/arm/boot/uImage $(RELEASE)
	$(CP) $(uboot_DIR)/{u-boot.img,MLO} $(RELEASE)

release_qemu:
	$(MKDIR) $(RELEASE)
	$(CP) $(linux_DIR)/arch/arm/boot/uImage $(RELEASE)

#------------------------------------
#
.PHONY: package install release build test tool config
