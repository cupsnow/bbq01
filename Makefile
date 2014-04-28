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

MYPATH = $(PROJDIR)/package/u-boot/tools:$(PROJDIR)/tool/bin:$(TOOLCHAIN)/bin
SHELL := /bin/bash

export PATH := $(MYPATH)$(PATH:%=:)$(PATH)

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
#
rootfs:
	$(MAKE) linux_headers_install 
	$(MAKE) uboot linux busybox
	$(MAKE) rootfs_package
	$(MAKE) rootfs_rootfs
	$(MAKE) rootfs_prebuilt

rootfs_package: $(ROOTFS_PACKAGE) ;

LIBC_SO_PATH = $(TOOLCHAIN)/arm-none-linux-gnueabi/libc/lib
LIBC_SO += ld{-*.so,-*.so.*} 
LIBC_SO += libgcc_s{.so,.so.*}
LIBC_SO += lib{c,crypt,dl,m,rt,util,nsl,pthread,resolv}{-*.so,.so.*}
#LIBC_SO += libmemusage.so libpcprofile.so libSegFault.so
#LIBC_SO += libnss_{compat,db,dns,files,hesiod,nis,nisplus}{-*.so,.so.*}
#LIBC_SO += lib{thread_db,anl,BrokenLocale,cidn}{-*.so,.so.*}

rootfs_rootfs:
	$(MKDIR) $(ROOTFSDIR)/{lib,dev,proc,sys,var,mnt}
	$(MAKE) CONFIG_PREFIX=$(ROOTFSDIR) busybox_install
	$(CP) $(addprefix $(LIBC_SO_PATH)/,$(LIBC_SO)) $(ROOTFSDIR)/lib
	$(if $(wildcard $(DESTDIR)/bin),$(CP) $(DESTDIR)/bin $(ROOTFSDIR))
	$(if $(wildcard $(DESTDIR)/sbin),$(CP) $(DESTDIR)/sbin $(ROOTFSDIR))
	$(if $(wildcard $(DESTDIR)/usr),$(CP) $(DESTDIR)/usr $(ROOTFSDIR))
	$(if $(wildcard $(DESTDIR)/etc),$(CP) $(DESTDIR)/etc $(ROOTFSDIR))
	$(if $(wildcard $(DESTDIR)/init),$(CP) $(DESTDIR)/init $(ROOTFSDIR))
	$(if $(wildcard $(DESTDIR)/linuxrc),$(CP) $(DESTDIR)/linuxrc $(ROOTFSDIR))
ifneq ("$(wildcard $(DESTDIR)/lib/*{-*.so,.so.*})","")
	$(CP) $(DESTDIR)/lib/*{-*.so,.so.*} $(ROOTFSDIR)/lib
endif

rootfs_prebuilt:
	$(MKDIR) $(or $(ROOTFSDIR),$(DESTDIR))
ifneq ("$(wildcard $(PROJDIR)/config/common/prebuilt)","")
	$(CP) $(PROJDIR)/config/common/prebuilt/* $(ROOTFSDIR)
endif # common
ifneq ("$(wildcard $(PROJDIR)/config/$(BOARD)/prebuilt)","")
	$(CP) $(PROJDIR)/config/$(BOARD)/prebuilt/* $(ROOTFSDIR)
endif # board

#------------------------------------
# initramfs
#
initramfs:
	$(MAKE) ROOTFSDIR=$(INITRAMFS) rootfs
	$(MAKE) initramfs_image


initramfs_SRC = $(PROJDIR)/config/common/initramfs_list
initramfs_SRC += $(INITRAMFS) 

initramfs_image:
	$(MAKE) CONFIG_INITRAMFS_SOURCE="$(initramfs_SRC)" linux_uImage

#------------------------------------
# work
#
work:
	$(MAKE) ROOTFSDIR=$(ROOTFS) ROOTFS_PACKAGE=work_package rootfs
	$(MAKE) wrok_image

work_package:


wrok_image:


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
