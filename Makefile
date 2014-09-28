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
	$(MAKE) dist

#------------------------------------
#
uboot_DIR = $(PROJDIR)/package/u-boot-2014.07
uboot_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) -C $(uboot_DIR)
# uboot_MAKEPARAM = CROSS_COMPILE=$(CROSS_COMPILE) -C $(uboot_DIR)

uboot_config:
	$(uboot_MAKE) am335x_evm_config

uboot uboot_%:
	if [ ! -e $(uboot_DIR)/include/config.mk ]; then \
	  $(MAKE) uboot_config; \
	fi
	$(uboot_MAKE) $(patsubst uboot,,$(@:uboot_%=%))

mkimage_install: $(PROJDIR)/tool/bin/mkimage

$(PROJDIR)/tool/bin/mkimage:
	$(MAKE) uboot_tools
	$(MKDIR) $(PROJDIR)/tool/bin
	$(CP) $(uboot_DIR)/tools/mkimage $(PROJDIR)/tool/bin/

$(uboot_DIR)/MLO $(uboot_DIR)/u-boot.img:
	$(MAKE) uboot

#------------------------------------
#
linux_DIR = $(PROJDIR)/package/linux-3.16.2
linux_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm LOADADDR=0x80008000
linux_MAKE += INSTALL_HDR_PATH=$(DESTDIR)/usr INSTALL_MOD_PATH=$(DESTDIR)
linux_MAKE += -C $(linux_DIR)

linux_config:
	$(linux_MAKE) bbq01_defconfig #multi_v7_defconfig

linux_uImage: $(PROJDIR)/tool/bin/mkimage

linux linux_%:
	if [ ! -e $(linux_DIR)/.config ]; then \
	  $(MAKE) linux_config; \
	fi
	$(linux_MAKE) $(patsubst linux,,$(@:linux_%=%))

$(DESTDIR)/usr/include/linux:
	$(MAKE) linux_headers_install

$(linux_DIR)/arch/arm/boot/uImage:
	$(MAKE) linux_uImage

$(linux_DIR)/arch/arm/boot/dts/am335x-bone.dtb:
	$(MAKE) linux_dtbs

#------------------------------------
#
busybox_DIR = $(PROJDIR)/package/busybox-1.22.1
busybox_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) CONFIG_PREFIX=$(DESTDIR)
busybox_MAKE += -C $(busybox_DIR)

busybox_config:
	$(busybox_MAKE) defconfig

busybox busybox_%: $(DESTDIR)/usr/include/linux
	if [ ! -e $(busybox_DIR)/.config ]; then \
	  $(MAKE) busybox_config; \
	fi
	$(busybox_MAKE) $(patsubst busybox,,$(@:busybox_%=%))

#------------------------------------
#
libevent_DIR = $(PROJDIR)/package/libevent
libevent_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libevent_DIR) 

libevent_dir:
	cd $(dir $(libevent_DIR)) && \
	  wget https://github.com/downloads/libevent/libevent/libevent-2.0.21-stable.tar.gz && \
	  tar -zxvf libevent-2.0.21-stable.tar.gz && \
	  ln -sf libevent-2.0.21-stable $(notdir $(libevent_DIR))

libevent_makefile:
	cd $(libevent_DIR) && \
	  ./configure --prefix=/ --host=`$(CC) -dumpmachine` \
	    CPPFLAGS="-I$(DESTDIR)/include" \
	    LDFLAGS="-L$(DESTDIR)/lib"

$(addprefix libevent_,clean distclean): ;
	if [ -e $(libevent_DIR)/Makefile ]; then \
	  $(libevent_MAKE) $(patsubst libevent,,$(@:libevent_%=%)); \
	fi

libevent libevent_%:
	if [ ! -d $(libevent_DIR) ]; then \
	  $(MAKE) libevent_dir; \
	fi
	if [ ! -f $(libevent_DIR)/Makefile ]; then \
	  $(MAKE) libevent_makefile; \
	fi
	$(libevent_MAKE) $(patsubst libevent,,$(@:libevent_%=%))

#------------------------------------
#
libmoss_DIR = $(PROJDIR)/package/libmoss
libmoss_MAKE = $(MAKE) $(MAKEPARAM) -C $(libmoss_DIR)

libmoss_dir:
	cd $(abspath $(libmoss_DIR)/..) && \
	  git clone git@bitbucket.org:joelai/libmoss.git

libmoss_configure:
	if [ -x $(libmoss_DIR)/autogen.sh ]; then \
	  echo "Makefile *** Generate configure by autogen.sh..."; \
	  cd $(libmoss_DIR) && ./autogen.sh; \
	elif [ -e $(libmoss_DIR)/configure.ac ]; then \
	  echo "Makefile *** Generate configure by autoreconf..."; \
	  cd $(libmoss_DIR) && autoreconf -fiv; \
	fi

libmoss_makefile:
	echo "Makefile *** Generate Makefile by configure..."; \
	cd $(libmoss_DIR) && \
	  ./configure \
	    --prefix=/ --host=`$(CC) -dumpmachine` --with-pic \
	    CPPFLAGS="-I$(DESTDIR)/include" \
	    LDFLAGS="-L$(DESTDIR)/lib"

$(addprefix libmoss_,clean distclean): ;
	if [ -e $(libmoss_DIR)/Makefile ]; then \
	  $(libmoss_MAKE) $(patsubst libmoss,,$(@:libmoss_%=%)); \
	fi

libmoss libmoss_%:
	if [ ! -d $(libmoss_DIR) ]; then \
	  $(MAKE) libmoss_dir; \
	fi
	if [ ! -e $(libmoss_DIR)/Makefile ]; then \
	  if [ ! -x $(libmoss_DIR)/configure ]; then \
	    $(MAKE) libmoss_configure; \
	  fi; \
	  if [ -x $(libmoss_DIR)/configure ]; then \
	    $(MAKE) libmoss_makefile; \
	  fi; \
	fi
	$(libmoss_MAKE) $(patsubst libmoss,,$(@:libmoss_%=%))

#------------------------------------
#
web01_DIR = $(PROJDIR)/package/web01
web01_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(web01_DIR)

web01_configure:
	if [ -x $(web01_DIR)/autogen.sh ]; then \
	  echo "Makefile *** Generate configure by autogen.sh..."; \
	  cd $(web01_DIR) && ./autogen.sh; \
	elif [ -e $(web01_DIR)/configure.ac ]; then \
	  echo "Makefile *** Generate configure by autoreconf..."; \
	  cd $(web01_DIR) && autoreconf -fiv; \
	fi

web01_makefile:
	echo "Makefile *** Generate Makefile by configure..."; \
	cd $(web01_DIR) && \
	  ./configure \
	    --prefix=/ --host=`$(CC) -dumpmachine` \
	    CPPFLAGS="-I$(DESTDIR)/include" \
	    LDFLAGS="-L$(DESTDIR)/lib"

$(addprefix web01_,clean distclean): ;
	if [ -e $(web01_DIR)/Makefile ]; then \
	  $(web01_MAKE) $(patsubst web01,,$(@:web01_%=%)); \
	fi

web01 web01_%:
	if [ ! -e $(web01_DIR)/Makefile ]; then \
	  if [ ! -x $(web01_DIR)/configure ]; then \
	    $(MAKE) web01_configure; \
	  fi; \
	  if [ -x $(web01_DIR)/configure ]; then \
	    $(MAKE) web01_makefile; \
	  fi; \
	fi
	$(web01_MAKE) $(patsubst web01,,$(@:web01_%=%))
	
#------------------------------------
#
dist_DIR = $(PROJDIR)/dist
dist:
	$(RM) $(DESTDIR)
	$(MAKE) dist_boot initramfs
	$(RM) $(DESTDIR)
	$(MAKE) userland

.PHONY: dist

dist_boot: $(uboot_DIR)/MLO
dist_boot: $(uboot_DIR)/u-boot.img
dist_boot: $(linux_DIR)/arch/arm/boot/uImage
dist_boot: $(linux_DIR)/arch/arm/boot/dts/am335x-bone.dtb
	$(MKDIR) $(dist_DIR)/boot
	$(CP) $(uboot_DIR)/u-boot.img $(dist_DIR)/boot/
	$(CP) $(uboot_DIR)/MLO $(dist_DIR)/boot/
	$(CP) $(linux_DIR)/arch/arm/boot/uImage $(dist_DIR)/boot/
	$(CP) $(linux_DIR)/arch/arm/boot/dts/am335x-bone.dtb \
	  $(dist_DIR)/boot/dtb

DEVLIST = $(dist_DIR)/devlist
INITRAMFS = $(dist_DIR)/initramfs
initramfs:
	# generate device list
	echo -n "" > $(DEVLIST)
	echo "dir /dev 0755 0 0" >> $(DEVLIST)
	echo "nod /dev/console 0600 0 0 c 5 1" >> $(DEVLIST)
	# install package
	$(MAKE) S=$(DESTDIR) DESTDIR=$(INITRAMFS) dist_busybox 
	# install prebuilt
	$(CP) -d $(PROJDIR)/prebuilt/common/* $(INITRAMFS)/
	$(CP) -d $(PROJDIR)/prebuilt/initramfs/* $(INITRAMFS)/
	# generate initramfs
	$(MKDIR) $(dist_DIR)/boot
	cd $(linux_DIR) && \
	  bash scripts/gen_initramfs_list.sh -o $(INITRAMFS).cpio.gz \
	    $(INITRAMFS) $(DEVLIST)
	mkimage -n 'Initramfs' -A arm -O linux -T ramdisk -C gzip \
	  -d $(INITRAMFS).cpio.gz $(dist_DIR)/boot/uInitramfs

.PHONY: initramfs

USERLAND = $(dist_DIR)/userland
userland:
	# install package
	$(MAKE) userland_package
	$(MAKE) S=$(DESTDIR) DESTDIR=$(USERLAND) dist_busybox dist_web01 \
	  linux_modules_install
	# install prebuilt
	$(CP) -d $(PROJDIR)/prebuilt/common/* $(USERLAND)/
	$(CP) -d $(PROJDIR)/prebuilt/userland/* $(USERLAND)/

.PHONY: userland

dist_busybox: dist_so1 busybox_install

dist_so1:
	$(MKDIR) $(DESTDIR)/lib
	for i in ld-*.so.* ld-*.so libpthread.so.* libpthread-*.so \
	    libc.so.* libc-*.so libm.so.* libm-*.so; do \
	  $(CP) -d $(CROSS_COMPILE_PATH)/arm-none-linux-gnueabi/libc/lib/$$i \
	    $(DESTDIR)/lib/; \
	done

dist_gcc_s:
	$(MKDIR) $(DESTDIR)/lib
	for i in libgcc_s.so.1; do \
	  $(CP) -d $(CROSS_COMPILE_PATH)/arm-none-linux-gnueabi/libc/lib/$$i \
	    $(DESTDIR)/lib/; \
	done

userland_package:
	$(MAKE) libevent_install libmoss_install 
	$(MAKE) web01_install

dist_libevent: dist_gcc_s dist_so1
	$(MKDIR) $(DESTDIR)/lib
	for i in libevent.so libevent-2.0.so.* \
	    libevent_core.so libevent_core-2.0.so.* \
	    libevent_extra.so libevent_extra-2.0.so.* \
	    libevent_pthreads.so libevent_pthreads-2.0.so.*; do \
	  $(CP) -d $(S)/lib/$$i $(DESTDIR)/lib/; \
	done

dist_libmoss: dist_gcc_s dist_so1
	$(MKDIR) $(DESTDIR)/lib
	for i in libmoss.so libmoss.so.*; do \
	  $(CP) -d $(S)/lib/$$i $(DESTDIR)/lib/; \
	done

dist_web01: dist_libevent dist_libmoss
	$(MKDIR) $(DESTDIR)/bin
	for i in web01; do \
	  $(CP) -d $(S)/bin/$$i $(DESTDIR)/bin/; \
	done
