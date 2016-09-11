#------------------------------------
#
PROJDIR ?= $(abspath $(dir $(firstword $(wildcard $(addsuffix /proj.mk,. ../..)))))
include $(PROJDIR)/proj.mk

PKGDIR = $(PROJDIR)/package

# BB, XM, QEMU, PI2, BBB
PLATFORM = BBBTI

CROSS_COMPILE_PATH = $(abspath $(PROJDIR)/tool/toolchain)
CROSS_COMPILE := $(patsubst %gcc,%,$(notdir $(lastword $(wildcard $(CROSS_COMPILE_PATH)/bin/*gcc))))

EXTRA_PATH = $(PROJDIR)/tool/bin $(CROSS_COMPILE_PATH:%=%/bin)

ifeq ("$(PLATFORM)","PI2")
PLATFORM_CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
else
PLATFORM_CFLAGS = -mcpu=cortex-a8 -mfpu=neon-vfpv4 -mfloat-abi=hard
endif

export PATH := $(subst $(SPACE),:,$(strip $(EXTRA_PATH)) $(PATH))

# PKG_CONFIG_PATH=$(DESTDIR)/lib/pkgconfig
PKG_CONFIG_ENV=PKG_CONFIG=pkg-config PKG_CONFIG_SYSROOT_DIR=$(DESTDIR) PKG_CONFIG_LIBDIR=$(DESTDIR)/lib/pkgconfig

$(info Makefile *** PROJDIR=$(PROJDIR))
$(info Makefile *** CROSS_COMPILE_PATH=$(CROSS_COMPILE_PATH))
$(info Makefile *** CROSS_COMPILE=$(CROSS_COMPILE))
$(info Makefile *** PATH=$(PATH))

#------------------------------------
#
all: ;
#	$(MAKE) uboot

#------------------------------------
#
$(eval $(call PROJ_DIST_CP))

#------------------------------------
#
tool: ;

.PHONY: tool

#------------------------------------
#
uboot_DIR = $(PWD)/package/u-boot
uboot_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) -C $(uboot_DIR)

uboot: uboot_;

uboot_dir:
ifeq ("$(PLATFORM)","BBBTI")
	$(call PROJ_GIT,$(uboot_DIR),$(PKGDIR),git://git.ti.com/ti-u-boot/ti-u-boot.git)
else
	$(call PROJ_WGET,$(uboot_DIR),$(PKGDIR),ftp://ftp.denx.de/pub/u-boot/u-boot-2016.07.tar.bz2)
endif

uboot_config:
ifeq ("$(PLATFORM)","XM")
	$(uboot_MAKE) omap3_beagle_defconfig
else ifeq ("$(PLATFORM)","BBBTI")
	$(uboot_MAKE) am335x_boneblack_defconfig
else ifeq ("$(PLATFORM)","BBB")
	$(uboot_MAKE) am335x_boneblack_defconfig
else
	$(uboot_MAKE) am335x_evm_defconfig
endif

uboot_clean uboot_distclean:
	$(uboot_MAKE) $(patsubst _%,%,$(@:uboot%=%))

uboot%:
	if [ ! -d $(uboot_DIR) ]; then \
	  $(MAKE) uboot_dir; \
	fi
	if [ ! -f $(uboot_DIR)/.config ]; then \
	  $(MAKE) uboot_config; \
	fi
	$(uboot_MAKE) $(patsubst _%,%,$(@:uboot%=%))

CLEAN += uboot

#------------------------------------
#
linux_DIR = $(PWD)/package/linux
linux_MAKEPARAM = CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm \
    INSTALL_HDR_PATH=$(DESTDIR)/usr INSTALL_MOD_PATH=$(DESTDIR) \
    CONFIG_INITRAMFS_SOURCE=$(CONFIG_INITRAMFS_SOURCE) \
    KDIR=$(linux_DIR)

ifeq ("$(PLATFORM)","PI2")
#linux_MAKEPARAM += LOADADDR=0x0C100000
linux_MAKEPARAM += LOADADDR=0x00200000
else ifeq ("$(PLATFORM)","XM")
linux_MAKEPARAM += LOADADDR=0x83000000
else
linux_MAKEPARAM += LOADADDR=0x80008000
endif

linux_MAKE = $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR)

linux: linux_;

linux_dir:
ifeq ("$(PLATFORM)","BBBTI")
	$(call PROJ_GIT,$(linux_DIR),$(PKGDIR),git://git.ti.com/processor-sdk/processor-sdk-linux.git)
else
	$(call PROJ_WGET,$(linux_DIR),$(PKGDIR),https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.7.tar.xz)
endif

linux_config:
ifeq ("$(PLATFORM)","PI2")
#	$(linux_MAKE) bcm2709_defconfig
	$(linux_MAKE) multi_v7_defconfig
else ifeq ("$(PLATFORM)","BBB")
	$(linux_MAKE) multi_v7_defconfig
else ifeq ("$(PLATFORM)","BB")
	$(linux_MAKE) multi_v7_defconfig
else
	$(linux_MAKE) bbq01_defconfig #multi_v7_defconfig
endif

linux_clean linux_distclean linux_mrproper linux_clobber linux_oldconfig:
	$(linux_MAKE) $(patsubst _%,%,$(@:linux%=%))

linux%: tool
	if [ ! -d $(linux_DIR) ]; then \
	  $(MAKE) linux_dir; \
	fi 
	if [ ! -f $(linux_DIR)/.config ]; then \
	  $(MAKE) linux_config; \
	fi
	$(linux_MAKE) $(patsubst _%,%,$(@:linux%=%))

CLEAN += linux

#------------------------------------
#
busybox_DIR = $(PWD)/package/busybox
busybox_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) \
    CONFIG_PREFIX=$(DESTDIR) -C $(busybox_DIR)

busybox: busybox_;

busybox_dir:
	$(call PROJ_WGET,$(busybox_DIR),$(PKGDIR),https://www.busybox.net/downloads/busybox-1.24.1.tar.bz2)

busybox_config:
#	$(MAKE) linux_headers_install
	$(busybox_MAKE) defconfig

busybox_clean busybox_distclean:
	$(busybox_MAKE) $(patsubst _%,%,$(@:busybox%=%))

busybox%:
	if [ ! -d $(busybox_DIR) ]; then \
	  $(MAKE) busybox_dir; \
	fi
	if [ ! -f $(busybox_DIR)/.config ]; then \
	  $(MAKE) busybox_config; \
	fi
	$(busybox_MAKE) $(patsubst _%,%,$(@:busybox%=%))

CLEAN += busybox

#------------------------------------
#
tool: $(PROJDIR)/tool/bin/mkimage

$(PROJDIR)/tool/bin/mkimage:
	$(MAKE) uboot_tools
	$(MKDIR) $(dir $@)
	$(CP) $(uboot_DIR)/tools/mkimage $(dir $@)

#------------------------------------
#
firmware-linux_DIR = $(PROJDIR)/package/firmware-linux

firmware-linux: firmware-linux_;

firmware-linux_dir:
	git clone --depth=1 git://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git $(firmware-linux_DIR); \

firmware-linux%:
	if [ ! -d $(firmware-linux_DIR) ]; then \
	  $(MAKE) firmware-linux_dir; \
	fi

#------------------------------------
# git clone --depth=1 https://github.com/raspberrypi/firmware.git firmware-pi
#
firmware-pi_DIR = $(PWD)/package/firmware-pi
firmware-pi_dir:
	$(MKDIR) $(PKGDIR) $(dir $(firmware-pi_DIR))
	if [ -d $(PKGDIR)/firmware-pi ] ; then \
	  cd $(PKGDIR)/firmware-pi; git pull --depth=1; \
	else \
	  git clone --depth=1 https://github.com/raspberrypi/firmware.git $(PKGDIR)/firmware-pi; \
	fi
	$(RM) $(firmware-pi_DIR)
	ln -sf $(PKGDIR)/firmware-pi $(firmware-pi_DIR)

#------------------------------------
#
devlist_DIR ?= $(PWD)
devlist:
	echo -n "" > $(devlist_DIR)/$@
	echo "dir /dev 0755 0 0" >> $(devlist_DIR)/$@
	echo "nod /dev/console 0600 0 0 c 5 1" >> $(devlist_DIR)/$@

.PHONY: devlist

so1:
	$(MAKE) SRCFILE="ld-*.so.* ld-*.so libpthread.so.* libpthread-*.so" \
	    SRCFILE+="libc.so.* libc-*.so libm.so.* libm-*.so" \
	    SRCDIR=$(CROSS_COMPILE_PATH)/arm-linux-gnueabihf/libc/lib \
	    DESTDIR=$(DESTDIR)/lib dist-cp 

so2:
	$(MAKE) SRCFILE="libgcc_s.so.1 libdl.so.* libdl-*.so librt.so.* librt-*.so" \
	    SRCFILE+="libnss_*.so libnss_*.so.*" \
	    SRCDIR=$(CROSS_COMPILE_PATH)/arm-linux-gnueabihf/libc/lib \
	    DESTDIR=$(DESTDIR)/lib dist-cp

so3:
	$(MAKE) SRCFILE="libutil.so.* libutil-*.so libcrypt.so.* libcrypt-*.so" \
	    SRCFILE+="libresolv.so.* libresolv-*.so" \
	    SRCDIR=$(CROSS_COMPILE_PATH)/arm-linux-gnueabihf/libc/lib \
	    DESTDIR=$(DESTDIR)/lib dist-cp

initramfs_DIR ?= $(PWD)/initramfsroot
initramfs: tool linux_headers_install
	$(MKDIR) $(initramfs_DIR)
	$(MAKE) DESTDIR=$(initramfs_DIR) devlist so1 busybox_install
	$(RSYNC) $(PROJDIR)/prebuilt/common/* $(initramfs_DIR)
	$(RSYNC) $(PROJDIR)/prebuilt/initramfs/* $(initramfs_DIR)
	cd $(linux_DIR) && bash scripts/gen_initramfs_list.sh \
	    -o $(dir $(initramfs_DIR))/initramfs.cpio.gz \
	    $(devlist_DIR)/devlist $(initramfs_DIR)
	mkimage -n 'bbq01 initramfs' -A arm -O linux -T ramdisk -C gzip \
	    -d $(dir $(initramfs_DIR))/initramfs.cpio.gz $@

.PHONY: initramfs

userland_DIR ?= $(PROJDIR)/userland
userland0: tool linux_headers_install
	for i in proc sys dev tmp var/run; do \
	  [ -d $(userland_DIR)/$$i ] || $(MKDIR) $(userland_DIR)/$$i; \
	done
	$(MAKE) DESTDIR=$(userland_DIR) so1 so2 \
	    $(addsuffix _install,busybox)
	$(RSYNC) $(PROJDIR)/prebuilt/common/* $(PROJDIR)/prebuilt/userland/* \
	    $(userland_DIR)
ifeq ("$(PLATFORM)","PI2")
	$(RSYNC) $(PROJDIR)/prebuilt/userland-pi/* \
	    $(userland_DIR)
endif

distdir ?= $(PROJDIR)/dist/$(PLATFORM)
dist: linux_uImage linux_dtbs
	$(MKDIR) $(distdir)
ifeq ("$(PLATFORM)","PI2")
	$(CP) $(linux_DIR)/arch/arm/boot/zImage \
	    $(distdir)/kernel7.img
	$(CP) \
	    $(firmware-pi_DIR)/boot/bootcode.bin \
	    $(firmware-pi_DIR)/boot/start.elf \
	    $(firmware-pi_DIR)/boot/fixup.dat \
	    $(firmware-pi_DIR)/boot/start_x.elf \
	    $(firmware-pi_DIR)/boot/fixup_x.dat \
	    $(PROJDIR)/prebuilt/boot-pi/* \
	    $(linux_DIR)/arch/arm/boot/dts/bcm2836-rpi-2-b.dtb \
	        $(distdir)
	$(CP) $(linux_DIR)/arch/arm/boot/dts/bcm2836-rpi-2-b.dtb \
	    $(distdir)/bcm2709-rpi-2-b.dtb
else ifeq ("$(PLATFORM)","XM")
	$(MAKE) initramfs uboot linux_dtbs
	$(CP) $(uboot_DIR)/u-boot.img $(uboot_DIR)/MLO \
	    $(distdir)/
	$(CP) $(linux_DIR)/arch/arm/boot/dts/omap3-beagle-xm-ab.dtb \
	    $(distdir)/dtb
	$(CP) $(linux_DIR)/arch/arm/boot/uImage \
	    $(distdir)/
	$(CP) initramfs \
	    $(distdir)/initramfs
	mkimage -C none -A arm -T script \
	    -d $(PROJDIR)/package/ubootscr-xm/boot.sh \
	    $(distdir)/boot.scr
else ifeq ("$(PLATFORM)","BBB")
	$(MAKE) initramfs uboot linux_dtbs
	$(CP) $(uboot_DIR)/u-boot.img $(uboot_DIR)/MLO \
	    $(distdir)/
	$(CP) $(linux_DIR)/arch/arm/boot/dts/am335x-boneblack.dtb \
	    $(distdir)/dtb
	$(CP) $(linux_DIR)/arch/arm/boot/uImage \
	    $(distdir)/
	$(CP) initramfs \
	    $(distdir)/initramfs
	mkimage -C none -A arm -T script \
	    -d $(PROJDIR)/package/ubootscr-bbb/boot.sh \
	    $(distdir)/boot.scr
else
	$(MAKE) initramfs uboot linux_dtbs
	$(CP) $(uboot_DIR)/u-boot.img $(uboot_DIR)/MLO \
	    $(distdir)/
	$(CP) $(linux_DIR)/arch/arm/boot/dts/am335x-bone.dtb \
	    $(distdir)/dtb
	$(CP) $(linux_DIR)/arch/arm/boot/uImage \
	    $(distdir)/
	$(CP) initramfs \
	    $(distdir)/initramfs
	mkimage -C none -A arm -T script \
	    -d $(PROJDIR)/package/ubootscr-bbb/boot.sh \
	    $(distdir)/boot.scr
endif

.PHONY: dist

#------------------------------------
#
clean:
	$(MAKE) $(addsuffix _$@,$(CLEAN))

distclean:
	$(MAKE) $(addsuffix _$@,$(CLEAN))
	$(RM) $(initramfs_DIR) initramfs initramfs.cpio.gz

#------------------------------------
#
