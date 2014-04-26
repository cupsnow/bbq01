# $Id$
BUILDERDIR := $(abspath .)/.builder
include $(BUILDERDIR)/proj.mk

SEARCH_COMPILE ?= $(firstword $(wildcard $(PROJDIR)/tool/toolchain/bin/*gcc))
CROSS_COMPILE ?= $(patsubst %gcc,%,$(notdir $(SEARCH_COMPILE)))
TOOLCHAIN ?= $(patsubst %/bin/$(CROSS_COMPILE)gcc,%,$(SEARCH_COMPILE))

MYPATH = $(PROJDIR)/tool/bin:$(TOOLCHAIN)/bin
SHELL := /bin/bash

BOARD = qemu

export PATH := $(MYPATH)$(PATH:%=:)$(PATH)

#------------------------------------
#
all : ;

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
linux_MAKEPARAM += INSTALL_HDR_PATH="$(DESTDIR)"
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
busybox_MAKEPARAM += CONFIG_PREFIX="$(DESTDIR)"
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
	$(MAKE) linux_headers_install
	$(MAKE) linux busybox_install
	$(MAKE) initramfs_prebuilt
	$(MAKE) initramfs_rootfs
	$(MAKE) initramfs_uImage

initramfs_prebuilt:
ifneq ("$(wildcard $(PROJDIR)/config/common/prebuilt)","")
	$(CP) $(PROJDIR)/config/common/prebuilt/* $(DESTDIR)
endif # common
ifneq ("$(wildcard $(PROJDIR)/config/$(BOARD)/prebuilt)","")
	$(CP) $(PROJDIR)/config/$(BOARD)/prebuilt/* $(DESTDIR)
endif # board

initramfs_uImage:
	$(MAKE) CONFIG_INITRAMFS_SOURCE="$(PROJDIR)/config/common/initramfs_list $(ROOTFS)" linux_uImage
	
LIBC_SO_PATH = $(TOOLCHAIN)/arm-none-linux-gnueabi/libc/lib
LIBC_SO += ld{-*.so,-*.so.*} 
LIBC_SO += libgcc_s{.so,.so.*}
LIBC_SO += lib{c,crypt,dl,m,rt,util,nsl,pthread,resolv}{-*.so,.so.*}
#LIBC_SO += libmemusage.so libpcprofile.so libSegFault.so
#LIBC_SO += libnss_{compat,db,dns,files,hesiod,nis,nisplus}{-*.so,.so.*}
#LIBC_SO += lib{thread_db,anl,BrokenLocale,cidn}{-*.so,.so.*}
initramfs_rootfs:
	$(MKDIR) $(ROOTFS)/{lib,dev,proc,sys,var,mnt}
	$(CP) $(addprefix $(LIBC_SO_PATH)/,$(LIBC_SO)) $(ROOTFS)/lib
	$(CP) $(DESTDIR)/{etc,bin,sbin,usr} $(ROOTFS)
ifneq ("$(wildcard $(DESTDIR)/init)","")
	$(CP) $(DESTDIR)/init $(ROOTFS)
endif # init
ifneq ("$(wildcard $(DESTDIR)/linuxrc)","")
	$(CP) $(DESTDIR)/linuxrc $(ROOTFS)
endif # init
ifneq ("$(wildcard $(DESTDIR)/lib/*)","")
	$(CP) $(DESTDIR)/lib/*{-*.so,.so.*} $(ROOTFS)/lib
endif # $(DESTDIR)/lib

GETPASS = $(shell openssl passwd -1 -salt xxxxxxxx $(1))
# login,pass,uid,gid,home
PASSWD = $(1):$(2):$(3):$(4):$(1):$(5):/bin/sh
# login,pass
SHADOW = $(1):$(2):$(EPOCHDAY):0:99999::::
passwd:
	@echo '$(call PASSWD,root,x,0,0,/)' > passwd
	@echo '$(call SHADOW,root,$(call GETPASS))' > shadow

#------------------------------------
#
.PHONY: package install release build test tool
