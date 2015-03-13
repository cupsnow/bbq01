#------------------------------------
#
PROJDIR = $(abspath .)
include $(PROJDIR)/proj.mk

CROSS_COMPILE_GCC = $(lastword $(wildcard $(PROJDIR)/tool/**/bin/*gcc))
CROSS_COMPILE_PATH = $(abspath $(dir $(CROSS_COMPILE_GCC))..)
CROSS_COMPILE = $(patsubst %gcc,%,$(notdir $(CROSS_COMPILE_GCC)))

EXTRA_PATH = $(PROJDIR)/tool/bin $(CROSS_COMPILE_PATH)/bin

export PATH := $(subst $(SPACE),:,$(EXTRA_PATH) $(PATH))

# BB, XM, QEMU, PI2
PLATFORM = PI2

#------------------------------------
#
all: ;
#	$(MAKE) uboot

#------------------------------------
#
tool: ;

.PHONY: tool

#------------------------------------
#
uboot_DIR = $(PROJDIR)/package/u-boot-2014.07
uboot_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) -C $(uboot_DIR)

uboot_config:
ifeq ("$(PLATFORM)","XM")
	$(uboot_MAKE) omap3_beagle_config
else
	$(uboot_MAKE) am335x_evm_config
endif

uboot_clean uboot_distclean:
	$(uboot_MAKE) $(patsubst uboot,,$(@:uboot_%=%))

uboot uboot_%:
	if [ ! -f $(uboot_DIR)/include/config.mk ]; then \
	  $(MAKE) uboot_config; \
	fi
	$(uboot_MAKE) $(patsubst uboot,,$(@:uboot_%=%))

#------------------------------------
#
ifeq ("$(PLATFORM)","PI2")
# git clone --depth=1 https://github.com/raspberrypi/linux linux-pi
linux_DIR = $(PROJDIR)/package/linux-pi
else
linux_DIR = $(PROJDIR)/package/linux-3.16.2
endif

linux_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm \
  INSTALL_HDR_PATH=$(DESTDIR)/usr INSTALL_MOD_PATH=$(DESTDIR) \
  -C $(linux_DIR)
ifeq ("$(PLATFORM)","PI2")
else
linux_MAKE += LOADADDR=0x80008000
endif

linux_config:
ifeq ("$(PLATFORM)","PI2")
	$(linux_MAKE) bcm2709_defconfig
else
	$(linux_MAKE) bbq01_defconfig #multi_v7_defconfig
endif

linux_clean linux_distclean linux_mrproper linux_clobber:
	$(linux_MAKE) $(patsubst linux,,$(@:linux_%=%))

linux linux_%: tool
	if [ ! -f $(linux_DIR)/.config ]; then \
	  $(MAKE) linux_config; \
	fi
	$(linux_MAKE) $(patsubst linux,,$(@:linux_%=%))

#------------------------------------
#
busybox_DIR = $(PROJDIR)/package/busybox-1.22.1
busybox_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) \
  CONFIG_PREFIX=$(DESTDIR) -C $(busybox_DIR)

busybox_config:
#	$(MAKE) linux_headers_install
	$(busybox_MAKE) defconfig

busybox_clean busybox_distclean:
	$(busybox_MAKE) $(patsubst busybox,,$(@:busybox_%=%))

busybox busybox_%:
	if [ ! -f $(busybox_DIR)/.config ]; then \
	  $(MAKE) busybox_config; \
	fi
	$(busybox_MAKE) $(patsubst busybox,,$(@:busybox_%=%))

#------------------------------------
#
tool: $(PROJDIR)/tool/bin/mkimage

$(PROJDIR)/tool/bin/mkimage:
	$(MAKE) uboot_tools
	$(MKDIR) $(dir $@)
	$(CP) $(uboot_DIR)/tools/mkimage $(dir $@)

#------------------------------------
#
# git clone --depth=1 https://github.com/raspberrypi/firmware.git pi-firmware
pi-firmware_DIR = $(PROJDIR)/package/pi-firmware

devlist:
	$(MKDIR) $(dir $(DEVLIST))
	echo -n "" > $(DEVLIST)
	echo "dir /dev 0755 0 0" >> $(DEVLIST)
	echo "nod /dev/console 0600 0 0 c 5 1" >> $(DEVLIST)

.PHONY: devlist

so1:
	$(MKDIR) $(DESTDIR)/lib
	for i in ld-*.so.* ld-*.so libpthread.so.* libpthread-*.so \
	    libc.so.* libc-*.so libm.so.* libm-*.so; do \
	  $(CP) -d $(CROSS_COMPILE_PATH)/arm-none-linux-gnueabi/libc/lib/$$i \
	    $(DESTDIR)/lib; \
	done

so2:
	$(MKDIR) $(DESTDIR)/lib
	for i in libgcc_s.so.1; do \
	  $(CP) -d $(CROSS_COMPILE_PATH)/arm-none-linux-gnueabi/libc/lib/$$i \
	    $(DESTDIR)/lib/; \
	done

prebuilt:
	$(MKDIR) $(DESTDIR)
	$(CP) -d $(PROJDIR)/prebuilt/common/* $(PREBUILT) $(DESTDIR)

.PHONY: prebuilt

initramfs: tool
	$(MAKE) linux_headers_install
	$(MAKE) busybox
	$(MAKE) DEVLIST=$(PROJDIR)/devlist DESTDIR=$(PROJDIR)/.initramfs \
	  PREBUILT=$(PROJDIR)/prebuilt/initramfs/* \
	  devlist so1 prebuilt busybox_install
	cd $(linux_DIR) && bash scripts/gen_initramfs_list.sh \
	  -o $(PROJDIR)/initramfs.cpio.gz \
	  $(PROJDIR)/.initramfs $(PROJDIR)/devlist
	mkimage -n 'bbq01 initramfs' -A arm -O linux -T ramdisk -C gzip \
	  -d $(PROJDIR)/initramfs.cpio.gz $(PROJDIR)/initramfs

.PHONY: initramfs

userland: tool
	$(MAKE) linux_headers_install
	$(MAKE) busybox
	for i in proc sys dev tmp var/run; do \
	  [ -d $(PROJDIR)/userland/$$i ] || \
	    $(MKDIR) $(PROJDIR)/userland/$$i; \
	done
	$(MAKE) DESTDIR=$(PROJDIR)/userland \
	  so1 so2 busybox_install linux_modules_install
ifeq ("$(PLATFORM)","PI2")
	$(MAKE) DESTDIR=$(PROJDIR)/userland \
	  PREBUILT="$(PROJDIR)/prebuilt/userland/* $(PROJDIR)/prebuilt/userland-pi/*" \
	  prebuilt
else
	$(MAKE) DESTDIR=$(PROJDIR)/userland \
	  PREBUILT="$(PROJDIR)/prebuilt/userland/*" prebuilt
endif

.PHONY: userland

dist:
ifeq ("$(PLATFORM)","PI2")
	$(MAKE) linux_uImage
else
	$(RM) $(DESTDIR)
	$(MAKE) initramfs uboot linux_uImage linux_dtbs
endif
	$(RM) $(DESTDIR)
	$(MAKE) userland
ifeq ("$(PLATFORM)","PI2")
	$(MKDIR) $(PROJDIR)/dist/pi2
	$(CP) $(linux_DIR)/arch/arm/boot/zImage \
	  $(PROJDIR)/dist/pi2/kernel.img
	$(CP) $(linux_DIR)/arch/arm/boot/dts/bcm2709-rpi-2-b.dtb \
	  $(pi-firmware_DIR)/boot/bootcode.bin \
	  $(pi-firmware_DIR)/boot/start.elf \
	  $(PROJDIR)/dist/pi2/
else ifeq ("$(PLATFORM)","XM")
	$(MKDIR) $(PROJDIR)/dist/beagleboard
	$(CP) $(uboot_DIR)/u-boot.img $(uboot_DIR)/MLO \
	  $(PROJDIR)/dist/beagleboard
	$(CP) $(linux_DIR)/arch/arm/boot/dts/omap3-beagle-xm.dtb \
	  $(PROJDIR)/dist/beagleboard/dtb
else
	$(MKDIR) $(PROJDIR)/dist/beaglebone
	$(CP) $(uboot_DIR)/u-boot.img $(uboot_DIR)/MLO \
	  $(PROJDIR)/dist/beaglebone
	$(CP) $(linux_DIR)/arch/arm/boot/dts/am335x-bone.dtb \
	  $(PROJDIR)/dist/beaglebone/dtb
endif
ifeq ("$(PLATFORM)","PI2")
else
	$(CP) $(linux_DIR)/arch/arm/boot/uImage $(PROJDIR)/initramfs \
	  $(PROJDIR)/dist
endif

.PHONY: dist

#------------------------------------
#
gpioctl_DIR = $(PROJDIR)/package/gpioctl
gpioctl_MAKE = $(MAKE) $(MAKEPARAM) CROSS_COMPILE=$(CROSS_COMPILE) \
  -C $(gpioctl_DIR)

gpioctl gpioctl_%:
	$(gpioctl_MAKE) $(patsubst gpioctl,,$(@:gpioctl_%=%))

	