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
	$(MAKE) linux_headers_install uboot # linux
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
initramfs_LIBC2_PATH = $(TOOLCHAIN)/arm-none-linux-gnueabi/libc/usr/lib
initramfs_LIBC2 += libstdc++{.so,.so.*} 
initramfs_libc:
	$(MKDIR) $(INITRAMFS)/lib
	$(CP) $(addprefix $(initramfs_LIBC_PATH)/,$(initramfs_LIBC)) $(INITRAMFS)/lib

initramfs_DESTDIR = bin sbin usr
initramfs_DESTDIR += lib/*-*.so lib/*.so.* lib/*.so
initramfs_destdir:
	$(foreach i,$(initramfs_DESTDIR),$(if $(wildcard $(DESTDIR)/$(i)),$(CP) $(DESTDIR)/$(i) $(INITRAMFS)/$(dir $(i));))

initramfs_PREBUILT = prebuilt/common prebuilt/initramfs config/$(BOARD)/prebuilt/initramfs
initramfs_prebuilt:
	$(foreach i,$(initramfs_PREBUILT),$(if $(wildcard $(i)),$(CP) $(i)/* $(INITRAMFS);))

ifneq ("$(wildcard $(PROJDIR)/config/$(BOARD)/initramfs_list)","")
initramfs_IMAGE += $(PROJDIR)/config/$(BOARD)/initramfs_list
endif
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
	$(MKDIR) $(ROOTFS)/lib
	$(CP) $(addprefix $(initramfs_LIBC_PATH)/,$(initramfs_LIBC)) $(ROOTFS)/lib
	$(CP) $(addprefix $(initramfs_LIBC2_PATH)/,$(initramfs_LIBC2)) $(ROOTFS)/lib

rootfs_package: ;

rootfs_DESTDIR = bin sbin usr etc
rootfs_DESTDIR += lib/*-*.so lib/*.so.* lib/*.so
rootfs_destdir:
	$(MKDIR) $(ROOTFS)/{dev,proc,sys,lib,var,mnt,tmp}
	$(foreach i,$(rootfs_DESTDIR),$(if $(wildcard $(DESTDIR)/$(i)),$(CP) $(DESTDIR)/$(i) $(ROOTFS)/$(dir $(i));))

rootfs_PREBUILT = prebuilt/common prebuilt/rootfs config/$(BOARD)/prebuilt/rootfs
rootfs_prebuilt:
	$(foreach i,$(rootfs_PREBUILT),$(if $(wildcard $(i)),$(CP) $(i)/* $(ROOTFS);))

rootfs_image:
	$(MKDIR) $(RELEASE)
	$(RM) $(RELEASE)/rootfs.img
	mksquashfs $(ROOTFS) $(RELEASE)/rootfs.img

#------------------------------------
#
libevent_DIR = package/libevent
libevent_MAKEPARAM = DESTDIR=$(DESTDIR)

libevent_clean libevent_distclean: ;
ifneq ("$(wildcard $(libevent_DIR)/Makefile)","")
	$(libevent_MAKEENV) $(MAKE) $(libevent_MAKEPARAM) \
	  -C $(libevent_DIR) $(patsubst libevent,,$(@:libevent_%=%))
endif

libevent_config:
	cd $(libevent_DIR) && \
	  ./configure --host=$(HOST) --prefix=/

$(libevent_DIR)/Makefile:
	$(MAKE) libevent_config
	
libevent libevent_%: | $(libevent_DIR)/Makefile
	$(libevent_MAKEENV) $(MAKE) $(libevent_MAKEPARAM) \
	  -C $(libevent_DIR) $(patsubst libevent,,$(@:libevent_%=%))

$(DESTDIR)/lib/libevent.so:
	$(MAKE) libevent_install
 
rootfs_package: libevent_install

#------------------------------------
#
directfb_DIR = package/directfb
directfb_MAKEPARAM = DESTDIR=$(DESTDIR)

directfb_clean directfb_distclean: ;
ifneq ("$(wildcard $(directfb_DIR)/Makefile)","")
	$(directfb_MAKEENV) $(MAKE) $(directfb_MAKEPARAM) \
	  -C $(directfb_DIR) $(patsubst directfb,,$(@:directfb_%=%))
endif

directfb_config:
	cd $(directfb_DIR) && \
	  ./configure --host=$(HOST) --prefix=/ \
	    --disable-multi-kernel --disable-x11 --with-gfxdrivers=none \
	    --with-inputdrivers=keyboard,linuxinput,ps2mouse
	    

$(directfb_DIR)/Makefile:
	$(MAKE) directfb_config
	
directfb directfb_%: | $(directfb_DIR)/Makefile
	$(directfb_MAKEENV) $(MAKE) $(directfb_MAKEPARAM) \
	  -C $(directfb_DIR) $(patsubst directfb,,$(@:directfb_%=%))

$(DESTDIR)/lib/directfb.so:
	$(MAKE) directfb_install
 
rootfs_package: directfb_install

#------------------------------------
#
sample01_DIR = package/sample01
sample01_MAKEPARAM = $(MAKEPARAM)

sample01 sample01_%: $(DESTDIR)/lib/libevent.so
	$(MAKE) $(sample01_MAKEPARAM) \
	  -C $(sample01_DIR) $(patsubst sample01,,$(@:sample01_%=%))

rootfs_package: sample01_install

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
