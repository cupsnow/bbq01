#------------------------------------
#
PROJDIR = $(abspath .)
include $(PROJDIR)/proj.mk

CROSS_COMPILE_PATH1 = $(PROJDIR)/tool/**/bin/arm-*linux-*gcc
CROSS_COMPILE_PATH2 = $(lastword $(wildcard $(CROSS_COMPILE_PATH1)))
CROSS_COMPILE_PATH = $(abspath $(dir $(CROSS_COMPILE_PATH2))..)
CROSS_COMPILE = $(patsubst %gcc,%,$(notdir $(CROSS_COMPILE_PATH2)))

PATH1 = $(PROJDIR)/tool/bin $(CROSS_COMPILE_PATH)/bin 

export PATH := $(subst $(SPACE),:,$(PATH1) $(PATH))

# $(info Makefile *** PATH=$(PATH))

#------------------------------------
#
all:
	@echo "Please select other goals" 

#------------------------------------
#
uboot_DIR = $(PROJDIR)/package/u-boot-2014.07
uboot_MAKEPARAM = CROSS_COMPILE=$(CROSS_COMPILE) -C $(uboot_DIR)

uboot_config:
	$(MAKE) $(uboot_MAKEPARAM) am335x_evm_config

uboot uboot_%:
	if [ ! -e $(uboot_DIR)/include/config.mk ]; then \
	  $(MAKE) uboot_config; \
	fi
	$(MAKE) $(uboot_MAKEPARAM) $(patsubst uboot,,$(@:uboot_%=%))

mkimage_install: $(PROJDIR)/tool/bin/mkimage

$(PROJDIR)/tool/bin/mkimage:
	$(MAKE) uboot_tools
	$(MKDIR) $(PROJDIR)/tool/bin
	$(CP) $(uboot_DIR)/tools/mkimage $(PROJDIR)/tool/bin/

#------------------------------------
#
linux_DIR = $(PROJDIR)/package/linux-3.16.2
linux_MAKEPARAM = CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm LOADADDR=0x80008000
linux_MAKEPARAM += INSTALL_HDR_PATH=$(DESTDIR)/usr
linux_MAKEPARAM += -C $(linux_DIR)

linux_config:
	$(MAKE) $(linux_MAKEPARAM) bbq01_defconfig #multi_v7_defconfig

linux linux_%:
	if [ ! -e $(linux_DIR)/.config ]; then \
	  $(MAKE) linux_config; \
	fi
	$(MAKE) $(linux_MAKEPARAM) $(patsubst linux,,$(@:linux_%=%))

#------------------------------------
#
busybox_DIR = $(PROJDIR)/package/busybox-1.22.1
busybox_MAKEPARAM = CROSS_COMPILE=$(CROSS_COMPILE)
busybox_MAKEPARAM += CONFIG_PREFIX=$(DESTDIR)
busybox_MAKEPARAM += -C $(busybox_DIR)

busybox_config:
	$(MAKE) $(busybox_MAKEPARAM) defconfig

busybox busybox_%:
	if [ ! -e $(busybox_DIR)/.config ]; then \
	  $(MAKE) busybox_config; \
	fi
	$(MAKE) $(busybox_MAKEPARAM) $(patsubst busybox,,$(@:busybox_%=%))

#------------------------------------
#
dist_DIR = $(PROJDIR)/dist
dist:
	$(MAKE) uboot mkimage_install
	$(MAKE) linux_uImage linux_dtbs linux_headers_install
	$(MAKE) initramfs
	$(MAKE) dist2
	$(MAKE) userland

.PHONY: dist

dist2:
	$(MKDIR) $(dist_DIR)/boot
	$(CP) $(uboot_DIR)/u-boot.img $(dist_DIR)/boot/
	$(CP) $(uboot_DIR)/MLO $(dist_DIR)/boot/
	$(CP) $(linux_DIR)/arch/arm/boot/uImage $(dist_DIR)/boot/
	$(CP) $(linux_DIR)/arch/arm/boot/dts/am335x-bone.dtb \
	  $(dist_DIR)/boot/dtb

DEVLIST = $(dist_DIR)/devlist
initramfs:
	echo -n "" > $(DEVLIST)
	echo "dir /dev 0755 0 0" >> $(DEVLIST)
	echo "nod /dev/console 0600 0 0 c 5 1" >> $(DEVLIST)
	
	$(MAKE) busybox_install
	$(MKDIR) $(DESTDIR)/lib
	for i in libc.so.* libc-*.so libm.so.* libm-*.so \
	    ld-*.so.* ld-*.so; do \
	  $(CP) -d $(CROSS_COMPILE_PATH)/arm-none-linux-gnueabi/libc/lib/$$i \
	    $(DESTDIR)/lib; \
	done
	$(CP) -d $(PROJDIR)/prebuilt/common/* $(DESTDIR)/
	$(CP) -d $(PROJDIR)/prebuilt/initramfs/* $(DESTDIR)/
	
	$(MKDIR) $(dist_DIR)/boot
	cd $(linux_DIR) && \
	  bash scripts/gen_initramfs_list.sh \
	    -o $(dist_DIR)/initramfs.cpio.gz \
	    $(DESTDIR) $(DEVLIST)
	mkimage -n 'Initramfs' -A arm -O linux -T ramdisk -C gzip \
	  -d $(dist_DIR)/initramfs.cpio.gz $(dist_DIR)/boot/uInitramfs 

userland:
	$(MAKE) DESTDIR=$(dist_DIR)/userland busybox_install
	$(MKDIR) $(dist_DIR)/userland/lib
	for i in libc.so.* libc-*.so libm.so.* libm-*.so \
	    ld-*.so.* ld-*.so; do \
	  $(CP) -d $(CROSS_COMPILE_PATH)/arm-none-linux-gnueabi/libc/lib/$$i \
	    $(dist_DIR)/userland/lib; \
	done
	$(CP) -d $(PROJDIR)/prebuilt/common/* $(dist_DIR)/userland/
	$(CP) -d $(PROJDIR)/prebuilt/userland/* $(dist_DIR)/userland/

