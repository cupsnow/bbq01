#------------------------------------
#
PROJDIR ?= $(abspath $(dir $(firstword $(wildcard $(addsuffix /proj.mk,. ../..)))))
include $(PROJDIR)/proj.mk

PKGDIR = $(PROJDIR)/package

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
tool: ;

.PHONY: tool

#------------------------------------
#
zlib_DIR = $(PWD)/package/zlib
zlib_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(zlib_DIR)

zlib: zlib_;

zlib_dir:
	$(call PROJ_WGET,$(zlib_DIR),$(PKGDIR),http://zlib.net/zlib-1.2.8.tar.xz)
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
	cd $(zlib_DIR) && prefix= CROSS_PREFIX=$(CROSS_COMPILE) \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	    ./configure

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
bzip2_DIR = $(PWD)/package/bzip2
bzip2_MAKE = $(MAKE) DESTDIR=$(DESTDIR) CC=$(CC) AR=$(AR) RANLIB=$(RANLIB) \
    CFLAGS+="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS+="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
    PREFIX=$(DESTDIR) -C $(bzip2_DIR)

bzip2: bzip2_;

bzip2_dir:
	$(call PROJ_WGET,$(bzip2_DIR),$(PKGDIR),http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz)

bzip2%:
	if [ ! -d $(bzip2_DIR) ]; then \
	  $(MAKE) bzip2_dir; \
	fi
	$(bzip2_MAKE) $(patsubst _%,%,$(@:bzip2%=%))

CLEAN += bzip2

#------------------------------------
#
expat_DIR = $(PWD)/package/expat
expat_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(expat_DIR)

expat: expat_;

$(addprefix expat_,clean distclean): ;
	if [ -e $(expat_DIR)/Makefile ]; then \
	  $(expat_MAKE) $(patsubst _%,%,$(@:expat%=%)); \
	fi

expat_dir:
	$(call PROJ_WGET,$(expat_DIR),$(PKGDIR),http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz)

expat_makefile:
	cd $(expat_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    --with-pic \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

expat%:
	if [ ! -d $(expat_DIR) ]; then \
	  $(MAKE) expat_dir; \
	fi
	if [ ! -f $(expat_DIR)/Makefile ]; then \
	  $(MAKE) expat_makefile; \
	fi
	$(expat_MAKE) $(patsubst _%,%,$(@:expat%=%))

CLEAN += expat

#------------------------------------
#
libxml_DIR = $(PWD)/package/libxml
libxml_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libxml_DIR)

libxml: libxml_;

libxml_dir:
	$(call PROJ_WGET,$(libxml_DIR),$(PKGDIR),ftp://xmlsoft.org/libxml2/libxml2-2.9.4.tar.gz)

libxml_clean:
	if [ -e $(libxml_DIR)/build/Makefile ]; then \
	  $(libxml_MAKE) $(patsubst _%,%,$(@:libxml%=%)); \
	fi

libxml_distclean:
	$(RM) $(libxml_DIR)/build

libxml_makefile:
	cd $(libxml_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    --without-python \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libxml%:
	if [ ! -d $(libxml_DIR) ]; then \
	  $(MAKE) libxml_dir; \
	fi
	if [ ! -e $(libxml_DIR)/Makefile ]; then \
	  $(MAKE) libxml_makefile; \
	fi
	$(libxml_MAKE) $(patsubst _%,%,$(@:libxml%=%))

CLEAN += libxml

#------------------------------------
# dependent: failed on gcc 5.0
#
ncurses_DIR = $(PWD)/package/ncurses
ncurses_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(ncurses_DIR)
#ncurses_TERMINFODIR = /etc/terminfo

ncurses: ncurses_;

ncurses_dir:
	$(call PROJ_WGET,$(ncurses_DIR),$(PKGDIR),http://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz)

ncurses_clean ncurses_distclean:
	if [ -e $(ncurses_DIR)/Makefile ]; then \
	  $(ncurses_MAKE) $(patsubst _%,%,$(@:ncurses%=%)); \
	fi

ncurses_makefile:
	cd $(ncurses_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    --without-tests --with-shared --with-cxx-shared \
	    $(ncurses_TERMINFODIR:%=--with-default-terminfo-dir=%) \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

ncurses%:
	if [ ! -d $(ncurses_DIR) ]; then \
	  $(MAKE) ncurses_dir; \
	fi
	if [ ! -e $(ncurses_DIR)/Makefile ]; then \
	  $(MAKE) ncurses_makefile; \
	fi
	$(ncurses_MAKE) $(patsubst _%,%,$(@:ncurses%=%))

CLEAN += ncurses

#------------------------------------
# dependency: ncurses
# ftp://ftp.cwru.edu/pub/bash/readline-6.3.tar.gz
#
readline_DIR = $(PWD)/package/readline
readline_MAKE = $(MAKE) DESTDIR=$(DESTDIR) SHLIB_LIBS=-lncurses -C $(readline_DIR)
readline_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    bash_cv_wcwidth_broken=yes \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

readline: readline_;

readline_dir:
	$(call PROJ_WGET,$(readline_DIR),$(PKGDIR),http://ftp.gnu.org/gnu/readline/readline-6.3.tar.gz)

readline_clean readline_distclean:
	if [ -e $(readline_DIR)/Makefile ]; then \
	  $(readline_MAKE) $(patsubst _%,%,$(@:readline%=%)); \
	fi

readline_makefile:
	cd $(readline_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    bash_cv_wcwidth_broken=yes \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

readline%:
	if [ ! -d $(readline_DIR) ]; then \
	  $(MAKE) readline_dir; \
	fi
	if [ ! -e $(readline_DIR)/Makefile ]; then \
	  $(MAKE) readline_makefile; \
	fi
	$(readline_MAKE) $(patsubst _%,%,$(@:readline%=%))
	if [ "$(patsubst _%,%,$(@:readline%=%))" = "install" ]; then \
	  for i in libhistory.old libhistory.so.6.3.old \
	      libreadline.old libreadline.so.6.3.old; do \
	    $(RM) $(DESTDIR)/lib/$$i; \
	  done; \
	fi

CLEAN += readline

#------------------------------------
#
json-c_DIR = $(PWD)/package/json-c
json-c_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(json-c_DIR)
json-c_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes \
    --with-pic \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

json-c: json-c_;

json-c_dir:
	$(call PROJ_GIT,$(json-c_DIR),$(PKGDIR),https://github.com/json-c/json-c.git)

json-c_distclean json-c_clean:
	if [ -e $(json-c_DIR)/Makefile ]; then \
	  $(json-c_MAKE) $(patsubst _%,%,$(@:json-c%=%)); \
	fi

json-c_configure:
	cd $(json-c_DIR) && \
	  ./autogen.sh;

json-c_makefile:
	cd $(json-c_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes \
	    --with-pic \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

json-c%:
	if [ ! -d $(json-c_DIR) ]; then \
	  $(MAKE) json-c_dir; \
	fi
	if [ ! -x $(json-c_DIR)/configure ]; then \
	  $(MAKE) json-c_configure; \
	fi
	if [ ! -e $(json-c_DIR)/Makefile ]; then \
	  $(MAKE) json-c_makefile; \
	fi
	$(json-c_MAKE) $(patsubst _%,%,$(@:json-c%=%))

CLEAN += json-c

#------------------------------------
#
libnl_DIR = $(PWD)/package/libnl
libnl_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libnl_DIR)
libnl_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` --disable-cli \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libnl: libnl_;

libnl_dir:
	$(call PROJ_WGET,$(libnl_DIR),$(PKGDIR),http://www.infradead.org/~tgr/libnl/files/libnl-3.2.25.tar.gz)

libnl_clean libnl_distclean:
	if [ -e $(libnl_DIR)/Makefile ]; then \
	  $(libnl_MAKE) $(patsubst _%,%,$(@:libnl%=%)); \
	fi

libnl_makefile:
	cd $(libnl_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` --disable-cli \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libnl%:
	if [ ! -d $(libnl_DIR) ]; then \
	  $(MAKE) libnl_dir; \
	fi
	if [ ! -e $(libnl_DIR)/Makefile ]; then \
	  $(MAKE) libnl_makefile; \
	fi
	$(libnl_MAKE) $(patsubst _%,%,$(@:libnl%=%))

CLEAN += libnl

#------------------------------------
#
openssl_DIR = $(PWD)/package/openssl
openssl_MAKE = $(MAKE) -j1 INSTALL_PREFIX=$(DESTDIR) \
    CFLAG="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    EX_LIBS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
    CC=$(CC) -C $(openssl_DIR)

openssl: openssl_;

openssl_dir:
	$(call PROJ_WGET,$(openssl_DIR),$(PKGDIR),https://www.openssl.org/source/openssl-1.0.2h.tar.gz)
	$(openssl_MAKE) clean

openssl_clean openssl_distclean:
	if [ -e $(openssl_DIR)/include/openssl ]; then \
	  $(openssl_MAKE) clean; \
	fi

openssl_makefile:
	cd $(openssl_DIR) && CC=$(CC) ./Configure threads shared zlib-dynamic \
	    enable-deprecated --prefix=/ --openssldir=/usr/openssl linux-generic32

openssl_install:
	if [ ! -e $(openssl_DIR)/libcrypto.so ]; then \
	  $(MAKE) openssl; \
	fi
	$(MAKE) -j1 INSTALL_PREFIX=$(DESTDIR) CC=$(CC) -C $(openssl_DIR) \
	    $(patsubst _%,%,$(@:openssl%=%))

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
	$(call PROJ_WGET,$(wireless-tools_DIR),$(PKGDIR),http://www.labs.hpe.com/personal/Jean_Tourrilhes/Linux/wireless_tools.29.tar.gz)

wireless-tools%:
	if [ ! -d $(wireless-tools_DIR) ]; then \
	  $(MAKE) wireless-tools_dir; \
	fi
	$(wireless-tools_MAKE) $(patsubst _%,%,$(@:wireless-tools%=%))

CLEAN += wireless-tools

#------------------------------------
#
iperf_DIR = $(PWD)/package/iperf
iperf_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(iperf_DIR)

iperf: iperf_;

iperf_dir:
	$(call PROJ_WGET_EXTRACT,$(PKGDIR),https://iperf.fr/download/source/iperf-3.1.2-source.tar.gz)
	$(MKDIR) $(dir $(iperf_DIR)) && \
	  $(RM) $(iperf_DIR) && ln -sf $(PKGDIR)/iperf-3.1.2 $(iperf_DIR)

iperf_clean iperf_distclean:
	if [ -f $(iperf_DIR)/Makefile ]; then \
	  $(iperf_MAKE) $(patsubst _%,%,$(@:iperf%=%)); \
	fi

iperf_makefile:
	cd $(iperf_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    CPPFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

iperf%:
	if [ ! -d $(iperf_DIR) ]; then \
	  $(MAKE) iperf_dir; \
	fi
	if [ ! -e $(iperf_DIR)/Makefile ]; then \
	  $(MAKE) iperf_makefile; \
	fi
	$(iperf_MAKE) $(patsubst _%,%,$(@:iperf%=%))

CLEAN += iperf

#------------------------------------
# dependent: openssl
#
curl_DIR = $(PWD)/package/curl
curl_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(curl_DIR)

curl: curl_;

curl_dir:
	$(call PROJ_WGET,$(curl_DIR),$(PKGDIR),https://curl.haxx.se/download/curl-7.49.0.tar.bz2)
	$(RM) $(curl_DIR)/Makefile

curl_clean curl_distclean:
	if [ -e $(curl_DIR)/Makefile ]; then \
	  $(curl_MAKE) $(patsubst _%,%,$(@:curl%=%)); \
	fi

curl_makefile:
	cd $(curl_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    --with-ssl \
	    CFLAGS="$(PLATFORM_CFLAGS)" CPPFLAGS="-I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	    LIBS="-lcrypto -lssl"

curl%:
	if [ ! -d $(curl_DIR) ]; then \
	  $(MAKE) curl_dir; \
	fi
	if [ ! -e $(curl_DIR)/Makefile ]; then \
	  $(MAKE) curl_makefile; \
	fi
	$(curl_MAKE) $(patsubst _%,%,$(@:curl%=%))

CLEAN += curl

#------------------------------------
# dependent: zlib, openssl
#
openssh_DIR = $(PWD)/package/openssh
openssh_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(openssh_DIR)

openssh: openssh_;

openssh_dir:
	$(call PROJ_GIT,$(openssh_DIR),$(PKGDIR),git://anongit.mindrot.org/openssh.git)

openssh_clean openssh_distclean:
	if [ -f $(openssh_DIR)/Makefile ]; then \
	  $(openssh_MAKE) $(patsubst _%,%,$(@:openssh%=%)); \
	fi

openssh_makefile:
	if [ ! -e $(openssh_DIR)/configure ]; then \
	  cd $(openssh_DIR) && autoreconf -fiv; \
	fi
	cd $(openssh_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    --disable-strip --disable-etc-default-login \
	    CPPFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

openssh%:
	if [ ! -d $(openssh_DIR) ]; then \
	  $(MAKE) openssh_dir; \
	fi
	if [ ! -e $(openssh_DIR)/Makefile ]; then \
	  $(MAKE) openssh_makefile; \
	fi
	$(openssh_MAKE) $(patsubst _%,%,$(@:openssh%=%))

CLEAN += openssh

#------------------------------------
# dependent: openssl
#
socat_DIR = $(PWD)/package/socat
socat_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(socat_DIR)

socat: socat_;

socat_dir:
	$(call PROJ_WGET,$(socat_DIR),$(PKGDIR),http://www.dest-unreach.org/socat/download/socat-2.0.0-b8.tar.bz2)

socat_clean socat_distclean:
	if [ -f $(socat_DIR)/Makefile ]; then \
	  $(socat_MAKE) $(patsubst _%,%,$(@:socat%=%)); \
	fi

socat_makefile:
	cd $(socat_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    CPPFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

socat%:
	if [ ! -d $(socat_DIR) ]; then \
	  $(MAKE) socat_dir; \
	fi
	if [ ! -e $(socat_DIR)/Makefile ]; then \
	  $(MAKE) socat_makefile; \
	fi
	$(socat_MAKE) $(patsubst _%,%,$(@:socat%=%))

CLEAN += socat

#------------------------------------
# dependent: openssl libnl
#
wpa-supplicant_DIR = $(PWD)/package/wpa-supplicant
wpa-supplicant_MAKE = PKG_CONFIG_PATH=$(DESTDIR)/lib/pkgconfig PKG_CONFIG_SYSROOT_DIR=$(DESTDIR) \
    $(MAKE) CC=$(CC) DESTDIR=$(DESTDIR) BINDIR=/sbin LIBDIR=/lib INCDIR=/include \
    EXTRA_CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	CONFIG_LIBNL32=y CONFIG_LIBNL3_ROUTE=y CONFIG_WPS=1 CONFIG_SMARTCARD=n V=1 \
    -C $(wpa-supplicant_DIR)/wpa_supplicant

wpa-supplicant: wpa-supplicant_;

wpa-supplicant_dir:
	$(call PROJ_WGET,$(wpa-supplicant_DIR),$(PKGDIR),https://w1.fi/releases/wpa_supplicant-2.5.tar.gz)

wpa-supplicant%:
	if [ ! -d $(wpa-supplicant_DIR) ]; then \
	  $(MAKE) wpa-supplicant_dir; \
	fi
	if [ ! -e $(wpa-supplicant_DIR)/wpa_supplicant/.config ]; then \
	  cp $(wpa-supplicant_DIR)/wpa_supplicant/defconfig $(wpa-supplicant_DIR)/wpa_supplicant/.config; \
	fi
	$(wpa-supplicant_MAKE) $(patsubst _%,%,$(@:wpa-supplicant%=%))

CLEAN += wpa-supplicant

#------------------------------------
#
mbedtls_DIR = $(PWD)/package/mbedtls
mbedtls_MAKE = $(MAKE) DESTDIR=$(DESTDIR) CC=$(CC) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fomit-frame-pointer" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
    -C $(mbedtls_DIR)

mbedtls_dir:
	$(call PROJ_WGET_EXTRACT,$(PKGDIR),https://tls.mbed.org/download/mbedtls-2.3.0-apache.tgz)
	$(MKDIR) $(dir $(mbedtls_DIR)) && \
	  $(RM) $(mbedtls_DIR) && ln -sf $(PKGDIR)/mbedtls-2.3.0 $(mbedtls_DIR)

mbedtls: mbedtls_;

mbedtls%:
	if [ ! -d $(mbedtls_DIR) ]; then \
	  $(MAKE) mbedtls_dir; \
	fi
	$(mbedtls_MAKE) $(patsubst _%,%,$(@:mbedtls%=%))

#------------------------------------
#
distclean clean:
	$(MAKE) $(addsuffix _$@,$(CLEAN))

#------------------------------------
#
