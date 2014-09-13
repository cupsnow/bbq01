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

dist2:
	$(MKDIR) $(dist_DIR)/boot
	$(CP) $(uboot_DIR)/u-boot.img $(dist_DIR)/boot/
	$(CP) $(uboot_DIR)/MLO $(dist_DIR)/boot/
	$(CP) $(linux_DIR)/arch/arm/boot/uImage $(dist_DIR)/boot/
	$(CP) $(linux_DIR)/arch/arm/boot/dts/am335x-bone.dtb \
	  $(dist_DIR)/boot/dtb

devlist = $(PROJDIR)/devlist
initramfs:
	echo -n "" > $(devlist)
	echo "dir /dev 0755 0 0" >> $(devlist)
	echo "nod /dev/console 0600 0 0 c 5 1" >> $(devlist)
	
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
	    $(DESTDIR) $(devlist)
	mkimage -n 'Initramfs' -A arm -O linux -T ramdisk -C gzip \
	  -d $(dist_DIR)/initramfs.cpio.gz $(dist_DIR)/boot/uInitramfs 

##------------------------------------
## kernel
##
#linux_DIR = $(PWD)/package/linux
#linux_MAKEPARAM += ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)
#linux_MAKEPARAM += INSTALL_HDR_PATH="$(or $(INSTALL_HDR_PATH),$(DESTDIR))"
#linux_MAKEPARAM += INSTALL_MOD_PATH="$(or $(INSTALL_MOD_PATH),$(DESTDIR))"
#linux_MAKEPARAM += LOADADDR=$(linux_$(BOARD)_LOADADDR)
#linux_MAKEPARAM += CONFIG_INITRAMFS_SOURCE="$(CONFIG_INITRAMFS_SOURCE)"
#
#linux_%: linux_$(BOARD)_%;
#
#linux_qemu_LOADADDR = 0x00010000
#
#linux_qemu_defconfig:
#	$(linux_MAKEENV) $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) \
#	  versatile_defconfig
#
#linux_qemu_config:
#	$(RSYNC) -f "- .svn" config/qemu/linux/. $(linux_DIR)
#	$(MAKE) linux_oldconfig linux_prepare
#
#linux_bb_LOADADDR = 0x80008000
#
#linux_bb_defconfig:
#	$(linux_MAKEENV) $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) \
#	  omap2plus_defconfig
#
#linux_bb_config:
#	$(RSYNC) -f "- .svn" config/bb/linux/. $(linux_DIR)
#	$(MAKE) linux_oldconfig linux_prepare
#
#linux_clean linux_distclean:
#	$(linux_MAKEENV) $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) \
#	  $(patsubst linux,,$(@:linux_%=%))
#
#$(linux_DIR)/.config:
#	$(MAKE) linux_config
#
#linux linux_%: | $(linux_DIR)/.config
#	$(linux_MAKEENV) $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR) \
#	  $(patsubst linux,,$(@:linux_%=%))
#
##------------------------------------
## busybox
##
#busybox_DIR = $(PWD)/package/busybox
#busybox_MAKEPARAM += CROSS_COMPILE=$(CROSS_COMPILE)
#busybox_MAKEPARAM += CONFIG_PREFIX="$(or $(CONFIG_PREFIX),$(DESTDIR))"
#busybox_MAKEPARAM += EXTRA_CFLAGS="-I$(DESTDIR)/include"
#
#busybox_%: busybox_$(BOARD)_%;
#
#busybox_defconfig:
#	$(busybox_MAKEENV) $(MAKE) $(busybox_MAKEPARAM) -C $(busybox_DIR) \
#	  defconfig
#
#busybox_config:
#	$(RSYNC) -f "- .svn" config/busybox/. $(busybox_DIR)
#	$(MAKE) busybox_oldconfig busybox_prepare
#
#busybox_clean busybox_distclean:
#	$(busybox_MAKEENV) $(MAKE) $(busybox_MAKEPARAM) -C $(busybox_DIR) \
#	  $(patsubst busybox,,$(@:busybox_%=%))
#
#$(busybox_DIR)/.config:
#	$(MAKE) busybox_config
#
#busybox busybox_%: | $(busybox_DIR)/.config
#	$(busybox_MAKEENV) $(MAKE) $(busybox_MAKEPARAM) -C $(busybox_DIR) \
#	  $(patsubst busybox,,$(@:busybox_%=%))
#
##------------------------------------
## initramfs
##
#initramfs:
#	$(MAKE) linux_headers_install uboot # linux
#	# $(MAKE) busybox
#	$(MAKE) busybox_install
#	$(MAKE) initramfs_libc
#	$(MAKE) initramfs_prebuilt
#	$(MAKE) initramfs_runtime
#	$(MAKE) initramfs_image
#
#initramfs_LIBC_PATH = $(TOOLCHAIN)/$(HOST)/libc/lib
#initramfs_LIBC += {ld-*,libgcc_s}.so{,.*}
#initramfs_LIBC += lib{c,crypt,dl,m,rt,util,nsl,pthread,resolv}{-*.so,.so.*}
#initramfs_LIBC++_PATH = $(TOOLCHAIN)/$(HOST)/libc/usr/lib
#initramfs_LIBC++ += libstdc++.so{,.*} 
#initramfs_libc:
#	$(MKDIR) $(DESTDIR)/lib
#	for i in $(addprefix $(initramfs_LIBC_PATH)/,$(initramfs_LIBC)); do \
#	  if [ -d $$i ]; then \
#	    $(RSYNC) -f "- .svn" $$i/. $(DESTDIR)/lib; \
#	  else \
#	    $(RSYNC) -f "- .svn" $$i $(DESTDIR)/lib; \
#	  fi; \
#	done
#
#initramfs_PREBUILT = config/$(BOARD)/prebuilt/initramfs 
#initramfs_PREBUILT += prebuilt/common prebuilt/initramfs
#initramfs_prebuilt:
#	$(MKDIR) $(DESTDIR)
#	for i in $(initramfs_PREBUILT); do \
#	  [ ! -e $$i ] && echo "ignore missing prebuilt: $$i"; \
#	  [ ! -e $$i ] && continue; \
#	  if [ -d $$i ]; then \
#	    $(RSYNC) -f "- .svn" $$i/. $(DESTDIR); \
#	  else \
#	    $(RSYNC) -f "- .svn" $$i $(DESTDIR); \
#	  fi; \
#	done
#
#initramfs_RUNTIME = bin etc init lib sbin usr www
#initramfs_RUNTIME_STRIP = bin lib sbin usr/bin usr/lib usr/sbin
#initramfs_runtime:
#	$(MKDIR) $(INITRAMFS)
#	for i in $(addprefix $(DESTDIR)/,$(initramfs_RUNTIME)); do \
#	  [ ! -e $$i ] && echo "ignore missing destdir: $$i"; \
#	  [ ! -e $$i ] && continue; \
#	  $(RSYNC) -f "- .svn" $$i $(INITRAMFS); \
#	done
#	for i in $(addprefix $(INITRAMFS)/,$(initramfs_RUNTIME_STRIP)); do \
#	  [ ! -e $$i ] && echo "ignore missing strip: $$i"; \
#	  [ ! -e $$i ] && continue; \
#	  for j in `find $$i`; do \
#	    file_type=`file $$j`; \
#	    if [ -n "`echo "$$file_type" | grep 'ar archive'`" ]; then \
#	      echo "remove ar archive: $$j"; \
#	      $(RM) $$j; \
#	    elif [ -n "`echo "$$file_type" | grep 'not stripped'`" ]; then \
#	      echo "strip: $$j"; \
#	      $(STRIP) -g $$j; \
#	    fi; \
#	  done \
#	done
#
#initramfs_IMAGE = $(INITRAMFS) 
#ifneq ("$(wildcard $(PROJDIR)/config/$(BOARD)/initramfs_list)","")
#initramfs_IMAGE += $(PROJDIR)/config/$(BOARD)/initramfs_list
#endif
#initramfs_image:
#	$(MAKE) CONFIG_INITRAMFS_SOURCE="$(initramfs_IMAGE)" linux_uImage
#
##------------------------------------
## rootfs
##
#rootfs:
#	$(MAKE) linux_headers_install
#	# $(MAKE) busybox
#	$(MAKE) busybox_install
#	$(MAKE) rootfs_libc
#	$(MAKE) rootfs_package
#	$(MAKE) rootfs_prebuilt
#	$(MAKE) rootfs_runtime
#	$(MAKE) rootfs_image
#
#rootfs_libc:
#	$(MKDIR) $(DESTDIR)/lib
#	for i in $(addprefix $(initramfs_LIBC_PATH)/,$(initramfs_LIBC)) \
#	    $(addprefix $(initramfs_LIBC++_PATH)/,$(initramfs_LIBC++)); do \
#	  if [ -d $$i ]; then \
#	    $(RSYNC) -f "- .svn" $$i/. $(DESTDIR)/lib; \
#	  else \
#	    $(RSYNC) -f "- .svn" $$i $(DESTDIR)/lib; \
#	  fi; \
#	done
#
#rootfs_package: ;
#
#rootfs_PREBUILT = config/$(BOARD)/prebuilt/rootfs 
#rootfs_PREBUILT += prebuilt/common prebuilt/rootfs
#rootfs_prebuilt:
#	$(MKDIR) $(DESTDIR)
#	for i in $(rootfs_PREBUILT); do \
#	  [ ! -e $$i ] && echo "ignore missing prebuilt: $$i"; \
#	  [ ! -e $$i ] && continue; \
#	  if [ -d $$i ]; then \
#	    $(RSYNC) -f "- .svn" $$i/. $(DESTDIR); \
#	  else \
#	    $(RSYNC) -f "- .svn" $$i $(DESTDIR); \
#	  fi; \
#	done
#
#rootfs_RUNTIME = bin dev etc lib linuxrc mnt proc sbin sys tmp usr var www
#rootfs_RUNTIME_STRIP = bin lib linuxrc sbin usr/bin usr/lib usr/sbin
#rootfs_runtime:
#	$(MKDIR) $(ROOTFS)
#	for i in $(addprefix $(DESTDIR)/,$(rootfs_RUNTIME)); do \
#	  [ ! -e $$i ] && echo "ignore missing destdir: $$i"; \
#	  [ ! -e $$i ] && continue; \
#	  $(RSYNC) -f "- .svn" $$i $(ROOTFS); \
#	done
#	for i in $(addprefix $(ROOTFS)/,$(rootfs_RUNTIME_STRIP)); do \
#	  [ ! -e $$i ] && echo "ignore missing strip: $$i"; \
#	  [ ! -e $$i ] && continue; \
#	  for j in `find $$i`; do \
#	    file_type=`file $$j`; \
#	    if [ -n "`echo "$$file_type" | grep 'ar archive'`" ]; then \
#	      echo "remove ar archive: $$j"; \
#	      $(RM) $$j; \
#	    elif [ -n "`echo "$$file_type" | grep 'not stripped'`" ]; then \
#	      echo "strip: $$j"; \
#	      $(STRIP) -g $$j; \
#	    fi; \
#	  done \
#	done
#
#rootfs_IMAGE = $(ROOTFS)
#rootfs_image:
#	$(MKDIR) $(RELEASE)
#	$(RM) $(RELEASE)/rootfs.img
#	mksquashfs $(rootfs_IMAGE) $(RELEASE)/rootfs.img
#
##------------------------------------
##
#libevent_DIR = package/libevent
#libevent_MAKEPARAM = DESTDIR=$(DESTDIR)
#
#libevent_clean libevent_distclean: ;
#ifneq ("$(wildcard $(libevent_DIR)/Makefile)","")
#	$(libevent_MAKEENV) $(MAKE) $(libevent_MAKEPARAM) \
#	  -C $(libevent_DIR) $(patsubst libevent,,$(@:libevent_%=%))
#endif
#
#libevent_config:
#	cd $(libevent_DIR) && \
#	  ./configure --host=$(HOST) --prefix=/
#
#$(libevent_DIR)/Makefile:
#	$(MAKE) libevent_config
#	
#libevent libevent_%: | $(libevent_DIR)/Makefile
#	$(libevent_MAKEENV) $(MAKE) $(libevent_MAKEPARAM) \
#	  -C $(libevent_DIR) $(patsubst libevent,,$(@:libevent_%=%))
#
#$(DESTDIR)/lib/libevent.so:
#	$(MAKE) libevent_install
# 
#rootfs_package: libevent_install
#
##------------------------------------
##
#directfb_DIR = package/directfb
#directfb_MAKEPARAM = DESTDIR=$(DESTDIR)
#
#directfb_clean directfb_distclean: ;
#ifneq ("$(wildcard $(directfb_DIR)/Makefile)","")
#	$(directfb_MAKEENV) $(MAKE) $(directfb_MAKEPARAM) \
#	  -C $(directfb_DIR) $(patsubst directfb,,$(@:directfb_%=%))
#endif
#
#directfb_config:
#	cd $(directfb_DIR) && \
#	  ./configure --host=$(HOST) --prefix=/ \
#	    --disable-multi-kernel --disable-x11 --with-gfxdrivers=none \
#	    --with-inputdrivers=keyboard,linuxinput,ps2mouse
#	    
#
#$(directfb_DIR)/Makefile:
#	$(MAKE) directfb_config
#	
#directfb directfb_%: | $(directfb_DIR)/Makefile
#	$(directfb_MAKEENV) $(MAKE) $(directfb_MAKEPARAM) \
#	  -C $(directfb_DIR) $(patsubst directfb,,$(@:directfb_%=%))
#
#$(DESTDIR)/lib/libdirect.so:
#	$(MAKE) directfb_install
# 
##rootfs_package: directfb_install
#
##------------------------------------
##
#rsync_DIR = package/rsync
#rsync_MAKEPARAM = DESTDIR=$(DESTDIR)
#
#rsync_clean rsync_distclean: ;
#ifneq ("$(wildcard $(rsync_DIR)/Makefile)","")
#	$(rsync_MAKEENV) $(MAKE) $(rsync_MAKEPARAM) \
#	  -C $(rsync_DIR) $(patsubst rsync,,$(@:rsync_%=%))
#endif
#
#rsync_config:
#	cd $(rsync_DIR) && \
#	  ./configure --host=$(HOST) --prefix=/
#
#$(rsync_DIR)/Makefile:
#	$(MAKE) rsync_config
#	
#rsync rsync_%: | $(rsync_DIR)/Makefile
#	$(rsync_MAKEENV) $(MAKE) $(rsync_MAKEPARAM) \
#	  -C $(rsync_DIR) $(patsubst rsync,,$(@:rsync_%=%))
#
#$(DESTDIR)/bin/rsync:
#	$(MAKE) rsync_install
# 
#rootfs_package: rsync_install
#
##------------------------------------
##
#sample01_DIR = package/sample01
#sample01_MAKEPARAM = $(MAKEPARAM)
#
#sample01 sample01_%: $(DESTDIR)/lib/libevent.so # $(DESTDIR)/lib/libdirect.so
#	$(MAKE) $(sample01_MAKEPARAM) \
#	  -C $(sample01_DIR) $(patsubst sample01,,$(@:sample01_%=%))
#
#rootfs_package: sample01_install
#
##------------------------------------
##
#release: release_$(BOARD)
#
#release_bb:
#	$(MKDIR) $(RELEASE)
#	$(CP) $(linux_DIR)/arch/arm/boot/uImage $(RELEASE)
#	$(CP) $(uboot_DIR)/{u-boot.img,MLO} $(RELEASE)
#
#release_qemu:
#	$(MKDIR) $(RELEASE)
#	$(CP) $(linux_DIR)/arch/arm/boot/uImage $(RELEASE)

#------------------------------------
#
.PHONY: dist initramfs
