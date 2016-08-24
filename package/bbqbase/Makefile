#------------------------------------
#
PROJDIR ?= $(abspath $(dir $(firstword $(wildcard $(addsuffix /proj.mk,. ../..)))))
include $(PROJDIR)/proj.mk

PKGDIR = $(PROJDIR)/package
WGET = wget -N

# BB, XM, QEMU, PI2, BBB
PLATFORM = PI2

CROSS_COMPILE_PATH = $(abspath $(PROJDIR)/tool/toolchain)
CROSS_COMPILE := $(patsubst %gcc,%,$(notdir $(lastword $(wildcard $(CROSS_COMPILE_PATH)/bin/*gcc))))

EXTRA_PATH = $(PROJDIR)/tool/bin $(CROSS_COMPILE_PATH:%=%/bin)

ifeq ("$(PLATFORM)","PI2")
PLATFORM_CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
else ifeq ("$(PLATFORM)","BBB")
PLATFORM_CFLAGS = -mcpu=cortex-a8 -mfpu=neon-vfpv4 -mfloat-abi=hard
else ifeq ("$(PLATFORM)","BB")
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
env.sh: ;
	$(RM) $@; touch $@ && chmod +x $@ 
	echo "#!/bin/sh" >> $@
	echo "export PLATFORM="'"'"$(PLATFORM)"'"' >> $@
	echo "export PATH="'"'"$(PATH)"'"' >> $@
	echo "export CROSS_COMPILE="'"'"$(CROSS_COMPILE)"'"' >> $@
	echo "export CC="'"'"$(CC)"'"' >> $@
	echo "export LD="'"'"$(LD)"'"' >> $@
	echo "export PLATFORM_CFLAGS="'"'"$(PLATFORM_CFLAGS)"'"' >> $@
	echo "export PLATFORM_LDFLAGS="'"'"$(PLATFORM_LDFLAGS)"'"' >> $@
	echo "export PKG_CONFIG_SYSROOT_DIR=$(DESTDIR)" >> $@
	echo "export PKG_CONFIG_PATH=${PKG_CONFIG_SYSROOT_DIR}/lib/pkgconfig" >> $@

.PHONY: env.sh

#------------------------------------
#
tool: ;

.PHONY: tool


#------------------------------------
#
zlib_DIR = $(PWD)/package/zlib
zlib_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(zlib_DIR)
zlib_CFGENV = prefix= CROSS_PREFIX=$(CROSS_COMPILE) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"
zlib_CFGPARAM =

zlib: zlib_;

zlib_dir:
	$(MKDIR) $(PKGDIR) $(dir $(zlib_DIR))
	cd $(PKGDIR) && \
	  $(WGET) http://zlib.net/zlib-1.2.8.tar.xz && \
	  tar -Jxvf zlib-1.2.8.tar.xz
	$(RM) $(zlib_DIR)
	ln -sf $(PKGDIR)/zlib-1.2.8 $(zlib_DIR)
	$(zlib_MAKE) distclean

zlib_clean:
	if [ -e $(zlib_DIR)/configure.log ]; then \
	  $(zlib_MAKE) $(patsubst _%,%,$(@:zlib%=%)); \
	fi

zlib_distclean:
	if [ -e $(zlib_DIR)/Makefile ]; then \
	  $(zlib_MAKE) $(patsubst _%,%,$(@:zlib%=%)); \
	fi

zlib_makefile:
	echo "Makefile *** Generate Makefile by configure..."
	cd $(zlib_DIR) && \
	  $(zlib_CFGENV) ./configure $(zlib_CFGPARAM)

zlib%:
	if [ ! -d $(zlib_DIR) ]; then \
	  $(MAKE) zlib_dir; \
	fi
	if [ ! -e $(zlib_DIR)/configure.log ]; then \
	  $(MAKE) zlib_makefile; \
	fi
	$(zlib_MAKE) $(patsubst _%,%,$(@:zlib%=%))

CLEAN += zlib

#------------------------------------
#
openssl_DIR = $(PWD)/package/openssl
openssl_MAKE = $(MAKE) -j1 INSTALL_PREFIX=$(DESTDIR) \
    CFLAG="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    EX_LIBS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
    CC=$(CC) -C $(openssl_DIR)
openssl_INSTALL = $(MAKE) -j1 INSTALL_PREFIX=$(DESTDIR) \
    CC=$(CC) -C $(openssl_DIR)
openssl_CFGENV = CC=$(CC)
openssl_CFGPARAM = threads shared zlib-dynamic enable-deprecated \
    --prefix=/ --openssldir=/usr/openssl \
    linux-generic32
#    linux-armv4:$(CC):"$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC"

openssl: openssl_;

openssl_dir:
	$(MKDIR) $(PKGDIR) $(dir $(openssl_DIR))
	cd $(PKGDIR) && \
	  $(WGET) https://www.openssl.org/source/openssl-1.0.2h.tar.gz && \
	  tar -zxvf openssl-1.0.2h.tar.gz
	ln -sf $(PKGDIR)/openssl-1.0.2h $(openssl_DIR)
	$(openssl_MAKE) clean

openssl_clean openssl_distclean:
	if [ -e $(openssl_DIR)/include/openssl ]; then \
	  $(openssl_MAKE) clean; \
	fi

openssl_makefile:
	cd $(openssl_DIR) && \
	  $(openssl_CFGENV) ./Configure $(openssl_CFGPARAM)

openssl_install:
	if [ ! -e $(openssl_DIR)/libcrypto.so ]; then \
	  $(MAKE) openssl; \
	fi
	$(openssl_INSTALL) $(patsubst _%,%,$(@:openssl%=%))

openssl%:
	if [ ! -d $(openssl_DIR) ]; then \
	  $(MAKE) openssl_dir; \
	fi
	if [ ! -e $(openssl_DIR)/include/openssl ]; then \
	  $(MAKE) openssl_makefile; \
	fi
	$(openssl_MAKE) $(patsubst _%,%,$(@:openssl%=%))

CLEAN += openssl

#------------------------------------
#
wireless-tools_DIR = $(PWD)/package/wireless-tools
wireless-tools_MAKE = $(MAKE) PREFIX=$(DESTDIR) CC=$(CC) AR=$(AR) \
    RANLIB=$(RANLIB) BUILD_STATIC=1 -C $(wireless-tools_DIR)

wireless-tools: wireless-tools_

wireless-tools_dir:
	$(MKDIR) $(PKGDIR) $(dir $(wireless-tools_DIR))
	cd $(PKGDIR) && \
	  $(WGET) http://www.labs.hpe.com/personal/Jean_Tourrilhes/Linux/wireless_tools.29.tar.gz && \
	  tar -zxvf wireless_tools.29.tar.gz
	ln -sf $(PKGDIR)/wireless_tools.29 $(wireless-tools_DIR)

wireless-tools%:
	if [ ! -d $(wireless-tools_DIR) ]; then \
	  $(MAKE) wireless-tools_dir; \
	fi
	$(wireless-tools_MAKE) $(patsubst _%,%,$(@:wireless-tools%=%))

#------------------------------------
#
clean:
	$(MAKE) $(addsuffix _$@,$(CLEAN))

distclean:
	$(MAKE) $(addsuffix _$@,$(CLEAN))
#	$(RM) $(DESTDIR)

#------------------------------------
#
