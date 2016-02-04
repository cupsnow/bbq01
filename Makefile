#------------------------------------
#
PROJDIR = $(abspath .)
include $(PROJDIR)/proj.mk

# BB, XM, QEMU, PI2
PLATFORM = PI2

CROSS_COMPILE_PATH = $(abspath $(PROJDIR)/tool/toolchain)
CROSS_COMPILE := $(patsubst %gcc,%,$(notdir $(lastword $(wildcard $(CROSS_COMPILE_PATH)/bin/*gcc))))

EXTRA_PATH = $(PROJDIR)/tool/bin $(CROSS_COMPILE_PATH:%=%/bin)

ifeq ("$(PLATFORM)","PI2")
PLATFORM_CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
endif

export PATH := $(subst $(SPACE),:,$(strip $(EXTRA_PATH)) $(PATH))

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

.PHONY: env.sh

#------------------------------------
#
tool: ;

.PHONY: tool

#------------------------------------
#
uboot_DIR = $(PROJDIR)/package/u-boot-2014.07
uboot_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) -C $(uboot_DIR)

uboot: uboot_;

uboot_config:
ifeq ("$(PLATFORM)","XM")
	$(uboot_MAKE) omap3_beagle_config
else
	$(uboot_MAKE) am335x_evm_config
endif

uboot_clean uboot_distclean:
	$(uboot_MAKE) $(patsubst _%,%,$(@:uboot%=%))

uboot%:
	if [ ! -f $(uboot_DIR)/include/config.mk ]; then \
	  $(MAKE) uboot_config; \
	fi
	$(uboot_MAKE) $(patsubst _%,%,$(@:uboot%=%))

CLEAN += uboot

#------------------------------------
#
ifeq ("$(PLATFORM)","PI2")
linux_DIR = $(PROJDIR)/package/linux-pi
else
linux_DIR = $(PROJDIR)/package/linux-3.16.2
endif

linux_MAKEPARAM = CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm \
    INSTALL_HDR_PATH=$(DESTDIR)/usr INSTALL_MOD_PATH=$(DESTDIR) \
    CONFIG_INITRAMFS_SOURCE=$(CONFIG_INITRAMFS_SOURCE) \
    KDIR=$(linux_DIR)

ifeq ("$(PLATFORM)","PI2")
else
linux_MAKEPARAM += LOADADDR=0x80008000
endif

linux_MAKE = $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR)

linux: linux_;

linux_dir:
ifeq ("$(PLATFORM)","PI2")
	if [ -d $(linux_DIR) ] ; then \
	  cd $(linux_DIR); git pull --depth=1; \
	else \
	  git clone --depth=1 https://github.com/raspberrypi/linux $(linux_DIR); \
	fi
else
endif

linux_config:
ifeq ("$(PLATFORM)","PI2")
	$(linux_MAKE) bcm2709_defconfig
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
hx711-drv_DIR = $(PROJDIR)/package/hx711-drv-pi

hx711-drv: hx711-drv_;

hx711-drv%:
	$(MAKE) DESTDIR=$(DESTDIR) $(linux_MAKEPARAM) \
	    -C $(hx711-drv_DIR) $(patsubst _%,%,$(@:hx711-drv%=%))

CLEAN += hx711-drv

#------------------------------------
#
busybox_DIR = $(PROJDIR)/package/busybox
busybox_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) \
    CONFIG_PREFIX=$(DESTDIR) -C $(busybox_DIR)

busybox: busybox_;

busybox_dir:
	cd $(dir $(busybox_DIR)) && \
	  wget http://busybox.net/downloads/busybox-1.24.1.tar.bz2 && \
	  tar -jxvf busybox-1.24.1.tar.bz2 && \
	  ln -sf busybox-1.24.1 $(busybox_DIR)

busybox_config:
#	$(MAKE) linux_headers_install
	$(busybox_MAKE) defconfig

busybox_clean busybox_distclean:
	$(busybox_MAKE) $(patsubst _%,%,$(@:busybox%=%))

busybox%:
	if [ ! -f $(busybox_DIR)/.config ]; then \
	  $(MAKE) busybox_config; \
	fi
	$(busybox_MAKE) $(patsubst _%,%,$(@:busybox%=%))

CLEAN += busybox

#------------------------------------
#
zlib_DIR = $(PROJDIR)/package/zlib
zlib_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(zlib_DIR)
zlib_CFGENV = prefix= CROSS_PREFIX=$(CROSS_COMPILE) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"
zlib_CFGPARAM =

zlib: zlib_;

zlib_dir:
	cd $(dir $(zlib_DIR)) && \
	  wget http://zlib.net/zlib-1.2.8.tar.xz && \
	  tar -Jxvf zlib-1.2.8.tar.xz && \
	  ln -sf zlib-1.2.8 $(zlib_DIR)

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
openssl_DIR = $(PROJDIR)/package/openssl
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
	cd $(dir $(openssl_DIR)) && \
	  wget https://www.openssl.org/source/openssl-1.0.2f.tar.gz && \
	  tar -zxvf openssl-1.0.2f.tar.gz && \
	  ln -sf openssl-1.0.2f $(openssl_DIR)
	$(openssl_MAKE) clean

openssl_clean openssl_distclean:
	if [ -e $(openssl_DIR)/Makefile ]; then \
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
bzip2_DIR = $(PROJDIR)/package/bzip2
bzip2_MAKE = $(MAKE) DESTDIR=$(DESTDIR) CC=$(CC) AR=$(AR) RANLIB=$(RANLIB) \
    CFLAGS+="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS+="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
    PREFIX=$(DESTDIR) -C $(bzip2_DIR)

bzip2: bzip2_;

bzip2_dir:
	cd $(dir $(bzip2_DIR)) && \
	  wget "http://www.bzip.org/1.0.6/bzip2-1.0.6.tar.gz" && \
	  tar -zxvf bzip2-1.0.6.tar.gz && \
	  ln -sf bzip2-1.0.6 $(bzip2_DIR)

bzip2%:
	if [ ! -d $(bzip2_DIR) ]; then \
	  $(MAKE) bzip2_dir; \
	fi
	$(bzip2_MAKE) $(patsubst _%,%,$(@:bzip2%=%))

#------------------------------------
#
json-c_DIR = $(PROJDIR)/package/json-c
json-c_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(json-c_DIR)
json-c_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes \
    --with-pic \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

json-c: json-c_;

json-c_dir:
	git clone --depth=1 https://github.com/json-c/json-c.git $(json-c_DIR)
	cd $(dir $(json-c_DIR)) && \
	  tar -jcvf json-c.tar.bz2 $(notdir $(json-c_DIR))

json-c_clean:
	if [ -e $(json-c_DIR)/Makefile ]; then \
	  $(json-c_MAKE) $(patsubst _%,%,$(@:json-c%=%)); \
	fi

json-c_distclean:
	$(RM) $(json-c_DIR)
	cd $(dir $(json-c_DIR)) && \
	  tar -jxvf json-c.tar.bz2

json-c_configure:
	cd $(json-c_DIR) && \
	  ./autogen.sh;

json-c_makefile:
	cd $(json-c_DIR) && \
	  $(json-c_CFGENV) ./configure $(json-c_CFGPARAM)

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
libmoss_DIR = $(PROJDIR)/package/libmoss
libmoss_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libmoss_DIR)
libmoss_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libmoss: libmoss_;

libmoss_dir:
	if [ ! -d $(libmoss_DIR) ]; then \
	  cd $(abspath $(libmoss_DIR)/..) && \
	      git clone git@bitbucket.org:joelai/libmoss.git; \
	else \
	  cd $(abspath $(libmoss_DIR)) && git pull; \
	fi

libmoss_clean libmoss_distclean:
	if [ -e $(libmoss_DIR)/Makefile ]; then \
	  $(libmoss_MAKE) $(patsubst _%,%,$(@:libmoss%=%)); \
	fi

libmoss_configure:
	cd $(libmoss_DIR) && ./autogen.sh

libmoss_makefile:
	cd $(libmoss_DIR) && ./configure $(libmoss_CFGPARAM)

libmoss%:
	if [ ! -d $(libmoss_DIR) ]; then \
	  $(MAKE) libmoss_dir; \
	fi
	if [ ! -x $(libmoss_DIR)/configure ]; then \
	  $(MAKE) libmoss_configure; \
	fi
	if [ -x $(libmoss_DIR)/configure ]; then \
	  $(MAKE) libmoss_makefile; \
	fi
	$(libmoss_MAKE) $(patsubst _%,%,$(@:libmoss%=%))

CLEAN += libmoss

#------------------------------------
#
iperf_DIR = $(PROJDIR)/package/iperf
iperf_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(iperf_DIR)
iperf_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    CPPFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

iperf: iperf_;

iperf_dir:
	cd $(dir $(iperf_DIR)) && \
	  wget https://iperf.fr/download/iperf_3.1/iperf-3.1-source.tar.gz && \
	  tar -zxvf iperf-3.1-source.tar.gz && \
	  ln -sf iperf-3.1 $(iperf_DIR)

iperf_clean iperf_distclean:
	if [ -f $(iperf_DIR)/Makefile ]; then \
	  $(iperf_MAKE) $(patsubst _%,%,$(@:iperf%=%)); \
	fi

iperf_makefile:
	cd $(iperf_DIR) && $(iperf_CFGENV) ./configure $(iperf_CFGPARAM)

iperf%:
	if [ ! -d $(iperf_DIR) ]; then \
	  $(MAKE) iperf_dir; \
	fi
	if [ ! -e $(iperf_DIR)/Makefile ]; then \
	  $(MAKE) iperf_makefile; \
	fi
	$(iperf_MAKE) $(patsubst _%,%,$(@:iperf%=%))

#------------------------------------
#
curl_DIR = $(PROJDIR)/package/curl
curl_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(curl_DIR)
curl_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` --with-ssl \
    CFLAGS="$(PLATFORM_CFLAGS)" CPPFLAGS="-I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

curl: curl_;

curl_dir:
	cd $(dir $(curl_DIR)) && \
	  wget http://curl.haxx.se/download/curl-7.43.0.tar.bz2 && \
	  tar -jxvf curl-7.43.0.tar.bz2 && \
	  ln -sf curl-7.43.0 $(curl_DIR) && \
	  $(RM) $(curl_DIR)/Makefile

curl_clean curl_distclean:
	if [ -e $(curl_DIR)/Makefile ]; then \
	  $(curl_MAKE) $(patsubst _%,%,$(@:curl%=%)); \
	fi

curl_makefile:
	cd $(curl_DIR) && $(curl_CFGENV) ./configure $(curl_CFGPARAM)

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
#
socat_DIR = $(PROJDIR)/package/socat
socat_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(socat_DIR)
socat_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    CPPFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

socat: socat_;

socat_dir:
	cd $(dir $(socat_DIR)) && \
	  wget http://www.dest-unreach.org/socat/download/socat-2.0.0-b8.tar.bz2 && \
	  tar -jxvf socat-2.0.0-b8.tar.bz2 && \
	  ln -sf socat-2.0.0-b8 $(socat_DIR)

socat_clean socat_distclean:
	if [ -f $(socat_DIR)/Makefile ]; then \
	  $(socat_MAKE) $(patsubst _%,%,$(@:socat%=%)); \
	fi

socat_makefile:
	cd $(socat_DIR) && $(socat_CFGENV) ./configure $(socat_CFGPARAM)

socat%:
	if [ ! -d $(socat_DIR) ]; then \
	  $(MAKE) socat_dir; \
	fi
	if [ ! -e $(socat_DIR)/Makefile ]; then \
	  $(MAKE) socat_makefile; \
	fi
	$(socat_MAKE) $(patsubst _%,%,$(@:socat%=%))

#------------------------------------
#
libevent_DIR = $(PROJDIR)/package/libevent
libevent_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libevent_DIR)
libevent_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libevent: libevent_;

libevent_dir:
	wget -O $(dir $(libevent_DIR))/libevent-2.0.22-stable.tar.gz \
	    https://sourceforge.net/projects/levent/files/libevent/libevent-2.0/libevent-2.0.22-stable.tar.gz
	cd $(dir $(libevent_DIR)) && \
	  tar -zxvf libevent-2.0.22-stable.tar.gz && \
	  ln -sf libevent-2.0.22-stable $(notdir $(libevent_DIR))

libevent_clean libevent_distclean:
	if [ -e $(libevent_DIR)/Makefile ]; then \
	  $(libevent_MAKE) $(patsubst _%,%,$(@:libevent%=%)); \
	fi

libevent_makefile:
	cd $(libevent_DIR) && ./configure $(libevent_CFGPARAM)

libevent%:
	if [ ! -d $(libevent_DIR) ]; then \
	  $(MAKE) libevent_dir; \
	fi
	if [ ! -e $(libevent_DIR)/Makefile ]; then \
	  $(MAKE) libevent_makefile; \
	fi
	$(libevent_MAKE) $(patsubst _%,%,$(@:libevent%=%))

CLEAN += libevent

#------------------------------------
#
libnl_DIR = $(PROJDIR)/package/libnl
libnl_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libnl_DIR)
libnl_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) --disable-cli \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libnl: libnl_;

libnl_dir:
	wget -O $(dir $(libnl_DIR))/libnl-3.2.25.tar.gz \
	    "http://www.infradead.org/~tgr/libnl/files/libnl-3.2.25.tar.gz"
	cd $(dir $(libnl_DIR)) && \
	  tar -zxvf libnl-3.2.25.tar.gz && \
	  ln -sf libnl-3.2.25 $(notdir $(libnl_DIR))

libnl_clean libnl_distclean:
	if [ -e $(libnl_DIR)/Makefile ]; then \
	  $(libnl_MAKE) $(patsubst _%,%,$(@:libnl%=%)); \
	fi

libnl_makefile:
	cd $(libnl_DIR) && ./configure $(libnl_CFGPARAM)

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
x264_DIR = $(PROJDIR)/package/x264
x264_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(x264_DIR)
x264_CFGENV = CC=$(CC) LD=$(LD)
x264_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    $(addprefix --enable-,pic shared static) \
    $(addprefix --disable-,opencl avs swscale lavf ffms gpac lsmash) \
    --extra-cflags="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    --extra-ldflags="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

x264: x264_;

x264_dir:
	git clone --depth=1 git://git.videolan.org/x264.git $(x264_DIR)

x264_clean x264_distclean:
	if [ -e $(x264_DIR)/config.mak ]; then \
	  $(x264_MAKE) $(patsubst _%,%,$(@:x264%=%)); \
	fi

x264_makefile:
	cd $(x264_DIR) && $(x264_CFGENV) ./configure $(x264_CFGPARAM)

x264%:
	if [ ! -d $(x264_DIR) ]; then \
	  $(MAKE) x264_dir; \
	fi
	if [ ! -e $(x264_DIR)/config.mak ]; then \
	  $(MAKE) x264_makefile; \
	fi
	$(x264_MAKE) $(patsubst _%,%,$(@:x264%=%))

CLEAN += x264

#------------------------------------
#
libjpeg-turbo_DIR = $(PROJDIR)/package/libjpeg-turbo
libjpeg-turbo_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libjpeg-turbo_DIR)
libjpeg-turbo_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libjpeg-turbo: libjpeg-turbo_;

libjpeg-turbo_dir:
	wget -O $(dir $(libjpeg-turbo_DIR))/libjpeg-turbo-1.4.1.tar.gz \
	    http://downloads.sourceforge.net/project/libjpeg-turbo/1.4.1/libjpeg-turbo-1.4.1.tar.gz
	cd $(dir $(libjpeg-turbo_DIR)) && \
	  tar -zxvf libjpeg-turbo-1.4.1.tar.gz && \
	  ln -sf libjpeg-turbo-1.4.1 $(notdir $(libjpeg-turbo_DIR))

$(addprefix libjpeg-turbo_,clean distclean): ;
	if [ -e $(libjpeg-turbo_DIR)/Makefile ]; then \
	  $(libjpeg-turbo_MAKE) $(patsubst _%,%,$(@:libjpeg-turbo%=%)); \
	fi

libjpeg-turbo_makefile:
	cd $(libjpeg-turbo_DIR) && ./configure $(libjpeg-turbo_CFGPARAM)

libjpeg-turbo%:
	if [ ! -d $(libjpeg-turbo_DIR) ]; then \
	  $(MAKE) libjpeg-turbo_dir; \
	fi
	if [ ! -e $(libjpeg-turbo_DIR)/Makefile ]; then \
	  $(MAKE) libjpeg-turbo_makefile; \
	fi
	$(libjpeg-turbo_MAKE) $(patsubst _%,%,$(@:libjpeg-turbo%=%))

CLEAN += libjpeg-turbo

#------------------------------------
#
ffmpeg_DIR = $(PROJDIR)/package/ffmpeg
ffmpeg_CFGENV = PKG_CONFIG_LIBDIR=$(DESTDIR)/lib/pkgconfig
ffmpeg_CFGPARAM = --prefix=/ \
    --extra-cflags="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    --extra-ldflags="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"
ffmpeg_CFGPARAM += \
    $(addprefix --enable-,pic runtime-cpudetect hardcoded-tables memalign-hack) \
    $(addprefix --enable-,pthreads network)

ifeq ("$(PLATFORM)","PI2")
ffmpeg_CFGPARAM += --enable-cross-compile --target-os=linux \
    --cross_prefix=$(CROSS_COMPILE) --arch=vfpv3 --cpu=cortex-a7
else ifeq ("$(PLATFORM)","ANDROID")
ffmpeg_CFGPARAM += --enable-cross-compile --target-os=linux \
    --cross_prefix=$(CROSS_COMPILE) --arch=arm --cpu=armv5 \
    --pkg-config=pkg-config
else
endif

ffmpeg_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(ffmpeg_DIR)

ffmpeg: ffmpeg_;

ffmpeg_dir:
	git clone --depth=1 git://source.ffmpeg.org/ffmpeg.git $(ffmpeg_DIR)

ffmpeg_help:
	cd $(ffmpeg_DIR) && \
	  ./configure --help > $(PROJDIR)/ffmpeg.help && \
	  for i in decoders encoders hwaccels demuxers muxers parsers \
	      protocols bsfs indevs outdevs filters; do \
	    ./configure --list-$${i} > $(PROJDIR)/ffmpeg-$${i}.help; \
	  done

ffmpeg_clean ffmpeg_distclean:
	if [ -e $(ffmpeg_DIR)/config.mak ]; then \
	  $(ffmpeg_MAKE) $(patsubst _%,%,$(@:ffmpeg%=%)); \
	fi

ffmpeg_makefile:
	cd $(ffmpeg_DIR) && ./configure $(ffmpeg_CFGPARAM)

ffmpeg%:
	if [ ! -d $(ffmpeg_DIR) ]; then \
	  $(MAKE) ffmpeg_dir; \
	fi
	if [ ! -e $(ffmpeg_DIR)/config.mak ]; then \
	  $(MAKE) ffmpeg_makefile; \
	fi
	$(ffmpeg_MAKE) $(patsubst _%,%,$(@:ffmpeg%=%))

CLEAN += ffmpeg

#------------------------------------
#
wpa-supplicant_DIR = $(PROJDIR)/package/wpa_supplicant
wpa-supplicant_MAKE = $(MAKE) DESTDIR=$(DESTDIR) LIBDIR=/lib/ BINDIR=/usr/sbin/ \
    EXTRA_CFLAGS+="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS+="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
    CONFIG_LIBNL32=1 LIBNL_INC="$(DESTDIR)/include/libnl3" \
    CC=$(CC) -C $(wpa-supplicant_DIR)/wpa_supplicant

wpa-supplicant: wpa-supplicant_;

wpa-supplicant_dir:
	wget -O $(dir $(wpa-supplicant_DIR))/wpa_supplicant-2.4.tar.gz \
	    http://w1.fi/releases/wpa_supplicant-2.4.tar.gz
	cd $(dir $(wpa-supplicant_DIR)) && \
	  tar -zxvf wpa_supplicant-2.4.tar.gz && \
	  ln -sf wpa_supplicant-2.4 $(notdir $(wpa-supplicant_DIR))

wpa-supplicant_clean:
	$(wpa-supplicant_MAKE) clean

wpa-supplicant_distclean:
	$(wpa-supplicant_MAKE) clean
	$(RM) $(wpa-supplicant_DIR)/wpa_supplicant/.config

wpa-supplicant_makefile:
	$(CP) $(wpa-supplicant_DIR)/wpa_supplicant/defconfig \
	    $(wpa-supplicant_DIR)/wpa_supplicant/.config

wpa-supplicant%:
	if [ ! -d $(wpa-supplicant_DIR) ]; then \
	  $(MAKE) wpa-supplicant_dir; \
	fi
	if [ ! -e $(wpa-supplicant_DIR)/wpa_supplicant/.config ]; then \
	  $(MAKE) wpa-supplicant_makefile; \
	fi
	$(wpa-supplicant_MAKE) \
	    $(patsubst _%,%,$(@:wpa-supplicant%=%))

CLEAN += wpa-supplicant

#------------------------------------
#
include bluez.mk

#------------------------------------
#
webme_DIR = $(PROJDIR)/package/webme
webme_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(webme_DIR)
webme_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    --with-pic --with-debug \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

webme: webme_;

$(addprefix webme_,clean distclean): ;
	if [ -e $(webme_DIR)/Makefile ]; then \
	  $(webme_MAKE) $(patsubst _%,%,$(@:webme%=%)); \
	fi

webme_dir: ;
#	wget -O $(dir $(webme_DIR))/webme1-1.1.tar.bz2 \
#	  http://www.intra2net.com/en/developer/webme/download/webme1-1.1.tar.bz2
#	cd  $(dir $(webme_DIR)) && \
#	  tar -jxvf webme1-1.1.tar.bz2 && \
#	  ln -sf webme1-1.1 $(notdir $(webme_DIR))

webme_configure:
	cd $(webme_DIR) && autoreconf -fiv

webme_makefile:
	cd $(webme_DIR) && $(webme_CFGENV) ./configure $(webme_CFGPARAM)

webme%:
	if [ ! -d $(webme_DIR) ]; then \
	  $(MAKE) webme_dir; \
	fi
	if [ ! -x $(webme_DIR)/configure ]; then \
	  $(MAKE) webme_configure; \
	fi
	if [ -x $(webme_DIR)/configure ]; then \
	  $(MAKE) webme_makefile; \
	fi
	$(webme_MAKE) $(patsubst _%,%,$(@:webme%=%))

CLEAN += webme

#------------------------------------
#
v4l2info_DIR = $(PROJDIR)/package/v4l2info

v4l2info: v4l2info_;

v4l2info%:
	$(MAKE) PREFIX=/usr DESTDIR=$(DESTDIR) CROSS_COMPILE=$(CROSS_COMPILE) \
	    EXTRA_CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    EXTRA_LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	    -C $(v4l2info_DIR) $(patsubst _%,%,$(@:v4l2info%=%))

CLEAN += v4l2info

#------------------------------------
#
fbinfo_DIR = $(PROJDIR)/package/fbinfo

fbinfo: fbinfo_;

fbinfo%:
	$(MAKE) PREFIX=/usr DESTDIR=$(DESTDIR) CROSS_COMPILE=$(CROSS_COMPILE) \
	    EXTRA_CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    EXTRA_LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	    -C $(fbinfo_DIR) $(patsubst _%,%,$(@:fbinfo%=%))

CLEAN += fbinfo

#------------------------------------
#
gpioctl-pi_DIR = $(PROJDIR)/package/gpioctl-pi

gpioctl-pi: gpioctl-pi_;

gpioctl-pi%:
	$(MAKE) PREFIX=/usr DESTDIR=$(DESTDIR) CROSS_COMPILE=$(CROSS_COMPILE) \
	    EXTRA_CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    EXTRA_LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	    -C $(gpioctl-pi_DIR) $(patsubst _%,%,$(@:gpioctl-pi%=%))

CLEAN += gpioctl-pi

#------------------------------------
#
tool: $(PROJDIR)/tool/bin/mkimage

$(PROJDIR)/tool/bin/mkimage:
	$(MAKE) uboot_tools
	$(MKDIR) $(dir $@)
	$(CP) $(uboot_DIR)/tools/mkimage $(dir $@)

#------------------------------------
#
python_DIR = $(PROJDIR)/package/python
python_MAKE = $(MAKE) DESTDIR=$(DESTDIR) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
    -C $(python_DIR)
python_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    --build=`gcc -dumpmachine` --disable-ipv6 ac_cv_file__dev_ptmx=yes \
    ac_cv_file__dev_ptc=no \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

python: python_;

$(addprefix python_,clean distclean): ;
	if [ -e $(python_DIR)/Makefile ]; then \
	  $(python_MAKE) $(patsubst _%,%,$(@:python%=%)); \
	fi

python_dir: ;
	cd $(dir $(python_DIR)) && \
	  wget https://www.python.org/ftp/python/3.5.1/Python-3.5.1.tar.xz && \
	  tar -Jxvf Python-3.5.1.tar.xz && \
	  ln -sf Python-3.5.1 $(notdir $(python_DIR))

python_makefile:
	$(CP) $(PROJDIR)/config/python/Makefile.pre.in $(python_DIR)/
	cd $(python_DIR) && \
	  $(python_CFGENV) ./configure $(python_CFGPARAM)

python-host = $(PROJDIR)/tool/bin/python $(PROJDIR)/tool/bin/pgen \
    $(PROJDIR)/tool/bin/_freeze_importlib

python-host: $(python-host);

$(python-host):
	if [ ! -d $(python_DIR) ]; then \
	  $(MAKE) python_dir; \
	fi
	if [ -e $(python_DIR)/Makefile ]; then \
	  $(MAKE) -C $(python_DIR) distclean; \
	fi
	cd $(python_DIR) && ./configure --prefix=
	$(MAKE) DESTDIR=$(PWD)/tool -C $(python_DIR) Parser/pgen \
	    Programs/_freeze_importlib install
	$(MAKE) CROSS_COMPILE= SRCFILE="pgen" SRCDIR="$(python_DIR)/Parser" \
	    DESTDIR=$(PROJDIR)/tool/bin dist-cp
	$(MAKE) CROSS_COMPILE= SRCDIR="$(python_DIR)/Programs" \
	    SRCFILE="_freeze_importlib _testembed" \
	    DESTDIR=$(PROJDIR)/tool/bin dist-cp
	ln -sf python3 $(PROJDIR)/tool/bin/python
	$(MAKE) -C $(python_DIR) distclean

python%: $(python-host)
	echo "in python"
	if [ ! -d $(python_DIR) ]; then \
	  $(MAKE) python_dir; \
	fi
	if [ ! -f $(python_DIR)/Makefile ]; then \
	  $(MAKE) python_makefile; \
	fi
	$(python_MAKE) PGEN=$(PWD)/tool/bin/pgen \
	    PFRZIMP=$(PWD)/tool/bin/_freeze_importlib \
	    $(patsubst _%,%,$(@:python%=%))

CLEAN += python

#------------------------------------
# git clone --depth=1 https://github.com/raspberrypi/firmware.git firmware-pi
#
firmware-pi_DIR = $(PROJDIR)/package/firmware-pi
firmware-pi_dir: ;
	if [ -d $(firmware-pi_DIR) ] ; then \
	  cd $(firmware-pi_DIR); git pull --depth=1; \
	else \
	  git clone --depth=1 https://github.com/raspberrypi/firmware.git $(firmware-pi_DIR); \
	fi

#------------------------------------
#
devlist:
	echo -n "" > $@
	echo "dir /dev 0755 0 0" >> $@
	echo "nod /dev/console 0600 0 0 c 5 1" >> $@

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

prebuilt:
	$(MKDIR) $(DESTDIR)
	$(RSYNC) $(PROJDIR)/prebuilt/common/* $(PREBUILT) $(DESTDIR)

.PHONY: prebuilt

initramfs_DIR ?= $(PROJDIR)/.initramfs
initramfs: tool
	$(MAKE) linux_headers_install
	$(MAKE) busybox
	$(MAKE) PREBUILT=$(PROJDIR)/prebuilt/initramfs/* \
	    DESTDIR=$(initramfs_DIR) \
	    devlist so1 prebuilt busybox_install
	cd $(linux_DIR) && bash scripts/gen_initramfs_list.sh \
	    -o $(PROJDIR)/initramfs.cpio.gz \
	    $(PROJDIR)/devlist $(initramfs_DIR)
	mkimage -n 'bbq01 initramfs' -A arm -O linux -T ramdisk -C gzip \
	    -d $(PROJDIR)/initramfs.cpio.gz $(PROJDIR)/initramfs

.PHONY: initramfs

userland_DIR ?= $(PROJDIR)/userland
userland-bt: tool
	for i in proc sys dev tmp var/run var/lib; do \
	  [ -d $(PROJDIR)/userland/$$i ] || $(MKDIR) $(PROJDIR)/userland/$$i; \
	done
	$(MAKE) zlib_install expat_install libical_install ncurses_install \
	    libffi_install
	$(MAKE) SRCFILE="libz.so libz.so.* libexpat.so libexpat.so.*" \
	    SRCFILE+="libical.so libical.so.* libical_cxx.so libical_cxx.so.*" \
	    SRCFILE+="libicalss.so libicalss.so.* libicalss_cxx.so libicalss_cxx.so.*" \
	    SRCFILE+="libicalvcal.so libicalvcal.so.*" \
	    SRCFILE+="libform.so libform.so.* libmenu.so libmenu.so.* libpanel.so libpanel.so.*" \
	    SRCFILE+="libncurses.so libncurses.so.* libncurses++.so libncurses++.so.*" \
	    SRCFILE+="libffi.so libffi.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist-cp
	$(MAKE) TERMLIST="ansi, linux, vt100, vt102, vt220, xterm" \
	    DESTDIR=$(PROJDIR)/userland ncurses_install-terminfo
	$(MAKE) readline_install glib_install dbus_install
	$(MAKE) SRCFILE="libreadline.so libreadline.so.* libhistory.so libhistory.so.*" \
	    SRCFILE+="libgio-*.so libgio-*.so.* libglib-*.so libglib-*.so.*" \
	    SRCFILE+="libgmodule-*.so libgmodule-*.so.* libgobject-*.so libgobject-*.so.*" \
	    SRCFILE+="libgthread-*.so libgthread-*.so.*" \
	    SRCFILE+="libdbus-*.so libdbus-*.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist-cp
	$(MAKE) SRCFILE="dbus-daemon dbus-send" \
	    SRCDIR=$(DESTDIR)/bin DESTDIR=$(PROJDIR)/userland/bin \
	    dist-cp
	$(MAKE) bluez_install
	$(MAKE) SRCFILE="libbluetooth.so libbluetooth.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist-cp
	$(MAKE) SRCFILE="bluetoothd" \
	    SRCDIR=$(DESTDIR)/libexec/bluetooth DESTDIR=$(PROJDIR)/userland/bin \
	    dist-cp
	$(MAKE) SRCFILE="hciconfig hcitool bluetoothctl" \
	    SRCDIR=$(DESTDIR)/bin DESTDIR=$(PROJDIR)/userland/bin \
	    dist-cp

userland: tool linux_headers_install
	for i in proc sys dev tmp var/run; do \
	  [ -d $(userland_DIR)/$$i ] || $(MKDIR) $(userland_DIR)/$$i; \
	done
	$(MAKE) $(addsuffix _install,zlib bzip2 json-c libmoss iperf)
	$(MAKE) $(addsuffix _install,openssl)
	$(MAKE) $(addsuffix _install,curl socat)
	$(MAKE) SRCFILE="libz.so libz.so.* libcurl.so libcurl.so.*" \
	    SRCDIR=$(DESTDIR)/lib \
	    DESTDIR=$(userland_DIR)/lib dist-cp

#	$(MAKE) DESTDIR=$(userland_DIR) \
#	    so1 so2 busybox_install linux_modules_install
#ifeq ("$(PLATFORM)","PI2")
#	$(MAKE) DESTDIR=$(userland_DIR) \
#	    PREBUILT="$(PROJDIR)/prebuilt/userland/* $(PROJDIR)/prebuilt/userland-pi/*" \
#	    prebuilt
#	$(MAKE) hx711-drv
#	$(MAKE) DESTDIR=$(userland_DIR) hx711-drv_modules_install
#else
#	$(MAKE) DESTDIR=$(userland_DIR) \
#	    PREBUILT="$(PROJDIR)/prebuilt/userland/*" prebuilt
#endif
#	$(MAKE) zlib_install libmoss_install
#	$(MAKE) SRCFILE="libz.so libz.so.* libmoss.so libmoss.so.*" \
#	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(userland_DIR)/lib \
#	    dist-cp
#	$(MAKE) libnl_install
#	$(MAKE) SRCFILE="libnl-*.so libnl-*.so.*" \
#	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(userland_DIR)/lib \
#	    dist-cp
#	$(MAKE) openssl_install
#	$(MAKE) SRCFILE="openssl" \
#	    SRCDIR=$(DESTDIR)/usr DESTDIR=$(userland_DIR)/usr \
#	    dist-cp
#	$(MAKE) SRCFILE="openssl" \
#	    SRCDIR=$(DESTDIR)/bin DESTDIR=$(userland_DIR)/bin \
#	    dist-cp
#	$(MAKE) curl_install
#	$(MAKE) SRCFILE="libcurl.so libcurl.so.*" \
#	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(userland_DIR)/lib \
#	    dist-cp
#	$(MAKE) SRCFILE="curl" \
#	    SRCDIR=$(DESTDIR)/bin DESTDIR=$(userland_DIR)/bin \
#	    dist-cp
#	$(MAKE) libevent_install libjpeg-turbo_install json-c_install \
#	    x264_install v4l2info_install
#	$(MAKE) SRCFILE="libevent.so libevent-*.so.*" \
#	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(userland_DIR)/lib \
#	    dist-cp
#	$(MAKE) SRCFILE="libturbojpeg.so libturbojpeg.so.*" \
#	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(userland_DIR)/lib \
#	    dist-cp
#	$(MAKE) SRCFILE="libjson-c.so libjson-c.so.*" \
#	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(userland_DIR)/lib \
#	    dist-cp
#	$(MAKE) SRCFILE="libx264.so libx264.so.*" \
#	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(userland_DIR)/lib \
#	    dist-cp
#	$(MAKE) SRCFILE="v4l2info" \
#	    SRCDIR=$(DESTDIR)/usr/bin DESTDIR=$(userland_DIR)/usr/bin \
#	    dist-cp
#ifeq ("$(PLATFORM)","PI2")
#	$(MAKE) gpioctl-pi_install
#	$(MAKE) SRCFILE="gpioctl" \
#	    SRCDIR=$(DESTDIR)/usr/bin DESTDIR=$(userland_DIR)/usr/bin \
#	    dist-cp
#else
#endif
#	$(MAKE) wpa-supplicant_install
#	$(MAKE) SRCFILE="wpa_*" \
#	    SRCDIR=$(DESTDIR)/usr/sbin DESTDIR=$(userland_DIR)/usr/sbin \
#	    dist-cp
#	$(MAKE) userland-bt

.PHONY: userland

dist: linux
	$(RM) dist userland $(DESTDIR) 
ifeq ("$(PLATFORM)","PI2")
	$(MAKE) linux_uImage
else
	$(MAKE) initramfs uboot linux_uImage linux_dtbs
endif
	$(RM) $(DESTDIR)
	$(MAKE) userland
ifeq ("$(PLATFORM)","PI2")
	$(MKDIR) $(PROJDIR)/dist/pi2
	$(CP) $(linux_DIR)/arch/arm/boot/zImage \
	    $(PROJDIR)/dist/pi2/kernel.img
	$(CP) $(linux_DIR)/arch/arm/boot/dts/bcm2709-rpi-2-b.dtb \
	    $(firmware-pi_DIR)/boot/bootcode.bin \
	    $(firmware-pi_DIR)/boot/start.elf \
	    $(firmware-pi_DIR)/boot/fixup.dat \
	    $(firmware-pi_DIR)/boot/start_x.elf \
	    $(firmware-pi_DIR)/boot/fixup_x.dat \
	    $(PROJDIR)/prebuilt/boot-pi/* \
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
test_DIR = $(call TOKEN,1,$(1))/$(call TOKEN,2,$(1))
test_TARGET_FILTER = $(call TOKEN,1,$(1))_$(call TOKEN,2,$(1))
test_TARGET = $(patsubst $(call test_TARGET_FILTER,$(1)),,$(1:$(call test_TARGET_FILTER,$(1))_%=%))

test_%:
	$(MAKE) DESTDIR=$(DESTDIR) PROJDIR=$(PROJDIR) $(linux_MAKEPARAM) \
	    -C $(PROJDIR)/$(call test_DIR,$@) $(call test_TARGET,$@)

#------------------------------------
#
clean:
	$(MAKE) $(addsuffix _$@,$(CLEAN))

distclean:
	$(MAKE) $(addsuffix _$@,$(CLEAN))
	$(RM) dist obj userland devlist initramfs initramfs.cpio.gz \
	  terminfo.tmp

#------------------------------------
#
