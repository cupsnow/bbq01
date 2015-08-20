#------------------------------------
#
PROJDIR = $(abspath .)
include $(PROJDIR)/proj.mk

# BB, XM, QEMU, PI2
PLATFORM = PI2

CROSS_COMPILE_PATH = $(abspath $(PROJDIR)/tool/toolchain)
CROSS_COMPILE := $(patsubst %gcc,%,$(notdir $(lastword $(wildcard $(CROSS_COMPILE_PATH)/bin/*gcc))))

EXTRA_PATH = $(PROJDIR)/tool/bin $(CROSS_COMPILE_PATH:%=%/bin)

# codesourcery
#PLATFORM_CFLAGS = -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=softfp \
#  -mtune=cortex-a7

# PI2 linaro
PLATFORM_CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard

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
env.sh: ;
	$(RM) $@; touch $@ && chmod +x $@ 
	echo "#!/bin/sh" >> $@
	echo "export CROSS_COMPILE="'"'"$(CROSS_COMPILE)"'"' >> $@
	echo "export PATH="'"'"$(PATH)"'"' >> $@
	echo "export PLATFORM_CFLAGS="'"'"$(PLATFORM_CFLAGS)"'"' >> $@
	echo "export PLATFORM="'"'"$(PLATFORM)"'"' >> $@

.PHONY: env.sh
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
	$(uboot_MAKE) $(patsubst _%,%,$(@:uboot%=%))

uboot uboot_%:
	if [ ! -f $(uboot_DIR)/include/config.mk ]; then \
	  $(MAKE) uboot_config; \
	fi
	$(uboot_MAKE) $(patsubst _%,%,$(@:uboot%=%))

#------------------------------------
#
ifeq ("$(PLATFORM)","PI2")
linux_DIR = $(PROJDIR)/package/linux-pi
else
linux_DIR = $(PROJDIR)/package/linux-3.16.2
endif

linux_MAKEPARAM = CROSS_COMPILE=$(CROSS_COMPILE) ARCH=arm \
    INSTALL_HDR_PATH=$(DESTDIR)/usr INSTALL_MOD_PATH=$(DESTDIR) \
    KDIR=$(linux_DIR)

linux_MAKE = $(MAKE) $(linux_MAKEPARAM) -C $(linux_DIR)

ifeq ("$(PLATFORM)","PI2")
else
linux_MAKE += LOADADDR=0x80008000
endif

linux_dir: ;
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
	$(linux_MAKE) $(patsubst _%,,$(@:linux%=%))

linux linux_%: tool
	if [ ! -f $(linux_DIR)/.config ]; then \
	  $(MAKE) linux_config; \
	fi
	$(linux_MAKE) $(patsubst _%,,$(@:linux%=%))

#------------------------------------
#
hx711-drv_DIR = $(PROJDIR)/package/hx711-drv-pi

hx711-drv hx711-drv%:
	$(MAKE) $(MAKEPARAM) $(linux_MAKEPARAM) \
	    -C $(hx711-drv_DIR) $(patsubst _%,%,$(@:hx711-drv%=%))

#------------------------------------
#
busybox_DIR = $(PROJDIR)/package/busybox-1.22.1
busybox_MAKE = $(MAKE) CROSS_COMPILE=$(CROSS_COMPILE) \
    CONFIG_PREFIX=$(DESTDIR) -C $(busybox_DIR)

busybox_config:
#	$(MAKE) linux_headers_install
	$(busybox_MAKE) defconfig

busybox_clean busybox_distclean:
	$(busybox_MAKE) $(patsubst _%,%,$(@:busybox%=%))

busybox busybox_%:
	if [ ! -f $(busybox_DIR)/.config ]; then \
	  $(MAKE) busybox_config; \
	fi
	$(busybox_MAKE) $(patsubst _%,%,$(@:busybox%=%))

#------------------------------------
#
zlib_DIR = $(PROJDIR)/package/zlib
zlib_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(zlib_DIR)
zlib_CFGENV = prefix= CC=$(CROSS_COMPILE)gcc \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"
zlib_CFGPARAM =

zlib_dir:
	wget -O $(dir $(zlib_DIR))/zlib-1.2.8.tar.xz \
	    "http://zlib.net/zlib-1.2.8.tar.xz"
	cd $(dir $(zlib_DIR)) && \
	  tar -Jxvf zlib-1.2.8.tar.xz && \
	  ln -sf zlib-1.2.8 $(notdir $(zlib_DIR))

zlib_clean zlib_distclean:
	if [ -e $(zlib_DIR)/Makefile ]; then \
	  $(zlib_MAKE) $(patsubst _%,,$(@:zlib%=%)); \
	fi

zlib_makefile:
	echo "Makefile *** Generate Makefile by configure..."
	cd $(zlib_DIR) && \
	  $(zlib_CFGENV) ./configure $(zlib_CFGPARAM)

zlib zlib_%:
	if [ ! -d $(zlib_DIR) ]; then \
	  $(MAKE) zlib_dir; \
	fi
	if [ ! -e $(zlib_DIR)/configure.log ]; then \
	  $(MAKE) zlib_makefile; \
	fi
	$(zlib_MAKE) $(patsubst _%,,$(@:zlib%=%))

#------------------------------------
# ac_cv_func_malloc_0_nonnull=yes ac_cv_func_realloc_0_nonnull=yes
#
json-c_DIR = $(PROJDIR)/package/json-c
json-c_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(json-c_DIR)
json-c_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

json-c_dir:
	git clone --depth=1 https://github.com/json-c/json-c.git $(json-c_DIR)

json-c_clean json-c_distclean:
	if [ -e $(json-c_DIR)/Makefile ]; then \
	  $(json-c_MAKE) $(patsubst _%,%,$(@:json-c%=%)); \
	fi

json-c_configure:
	cd $(json-c_DIR) && ./autogen.sh;

json-c_makefile:
	cd $(json-c_DIR) && $(json-c_CFGENV) ./configure $(json-c_CFGPARAM)

json-c json-c_%:
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

#------------------------------------
#
libevent_DIR = $(PROJDIR)/package/libevent
libevent_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libevent_DIR)
libevent_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

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

libevent libevent_%:
	if [ ! -d $(libevent_DIR) ]; then \
	  $(MAKE) libevent_dir; \
	fi
	if [ ! -e $(libevent_DIR)/Makefile ]; then \
	  $(MAKE) libevent_makefile; \
	fi
	$(libevent_MAKE) $(patsubst _%,%,$(@:libevent%=%))

#------------------------------------
#
libnl_DIR = $(PROJDIR)/package/libnl
libnl_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libnl_DIR)
libnl_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) --disable-cli \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

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

libnl libnl_%:
	if [ ! -d $(libnl_DIR) ]; then \
	  $(MAKE) libnl_dir; \
	fi
	if [ ! -e $(libnl_DIR)/Makefile ]; then \
	  $(MAKE) libnl_makefile; \
	fi
	$(libnl_MAKE) $(patsubst _%,%,$(@:libnl%=%))

#------------------------------------
#
x264_DIR = $(PROJDIR)/package/x264
x264_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(x264_DIR)
x264_CFGENV = CC=$(CC) LD=$(LD)
x264_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    $(addprefix --enable-,pic shared static) \
    $(addprefix --disable-,opencl avs swscale lavf ffms gpac lsmash) \
    --extra-cflags="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    --extra-ldflags="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

x264_dir:
	git clone --depth=1 git://git.videolan.org/x264.git $(x264_DIR)

x264_clean x264_distclean:
	if [ -e $(x264_DIR)/config.mak ]; then \
	  $(x264_MAKE) $(patsubst _%,%,$(@:x264%=%)); \
	fi

x264_makefile:
	cd $(x264_DIR) && $(x264_CFGENV) ./configure $(x264_CFGPARAM)

x264 x264_%:
	if [ ! -d $(x264_DIR) ]; then \
	  $(MAKE) x264_dir; \
	fi
	if [ ! -e $(x264_DIR)/config.mak ]; then \
	  $(MAKE) x264_makefile; \
	fi
	$(x264_MAKE) $(patsubst _%,%,$(@:x264%=%))

#------------------------------------
#
libjpeg-turbo_DIR = $(PROJDIR)/package/libjpeg-turbo
libjpeg-turbo_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libjpeg-turbo_DIR)
libjpeg-turbo_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

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

libjpeg-turbo libjpeg-turbo_%:
	if [ ! -d $(libjpeg-turbo_DIR) ]; then \
	  $(MAKE) libjpeg-turbo_dir; \
	fi
	if [ ! -e $(libjpeg-turbo_DIR)/Makefile ]; then \
	  $(MAKE) libjpeg-turbo_makefile; \
	fi
	$(libjpeg-turbo_MAKE) $(patsubst _%,%,$(@:libjpeg-turbo%=%))

#------------------------------------
#
ffmpeg_DIR = $(PROJDIR)/package/ffmpeg
ffmpeg_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(ffmpeg_DIR)
ffmpeg_CFGPARAM = --prefix= --disable-all \
    --extra-cflags="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    --extra-ldflags="-L$(DESTDIR)/lib"
ifeq ("$(PLATFORM)","PI2")
ffmpeg_CFGPARAM += --enable-cross-compile --target-os=linux \
    --cross_prefix=$(CROSS_COMPILE) --arch=vfpv3 --cpu=cortex-a7
endif
ffmpeg_CFGPARAM += $(addprefix --enable-protocol=,file) \
    $(addprefix --enable-decoder=,h264 h264_vdpau mjpeg) \
    $(addprefix --enable-decoder=,mpeg4 mpeg4_vdpau) \
    $(addprefix --enable-decoder=,pcm_alaw pcm_mulaw adpcm_g726) \
    $(addprefix --enable-hwaccel=,h264_vaapi) \
    $(addprefix --enable-muxer=,avi mp4 matroska) \
    $(addprefix --enable-demuxer=,avi mov) \
    $(addprefix --enable-,pic runtime-cpudetect hardcoded-tables) \
    $(addprefix --enable-,gpl version3 memalign-hack) \
    $(addprefix --enable-,avutil avcodec swscale avformat pthreads) \
    $(addprefix --enable-,ffmpeg ffprobe)

ffmpeg_dir:
	git clone --depth=1 git://source.ffmpeg.org/ffmpeg.git $(ffmpeg_DIR)

ffmpeg_clean ffmpeg_distclean:
	if [ -e $(ffmpeg_DIR)/config.mak ]; then \
	  $(ffmpeg_MAKE) $(patsubst _%,%,$(@:ffmpeg%=%)); \
	fi

ffmpeg_makefile:
	cd $(ffmpeg_DIR) && ./configure $(ffmpeg_CFGPARAM)

ffmpeg ffmpeg_%:
	if [ ! -d $(ffmpeg_DIR) ]; then \
	  $(MAKE) ffmpeg_dir; \
	fi
	if [ ! -e $(ffmpeg_DIR)/config.mak ]; then \
	  $(MAKE) ffmpeg_makefile; \
	fi
	$(ffmpeg_MAKE) $(patsubst _%,%,$(@:ffmpeg%=%))

#------------------------------------
#
mpg123_DIR = $(PROJDIR)/package/mpg123
mpg123_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(mpg123_DIR)
mpg123_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    --with-cpu=arm_fpu --disable-id3v2 --disable-icy \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

mpg123_dir:
	wget -O $(dir $(mpg123_DIR))/mpg123-1.22.1.tar.bz2 \
	    http://downloads.sourceforge.net/project/mpg123/mpg123/1.22.1/mpg123-1.22.1.tar.bz2
	cd $(dir $(mpg123_DIR)) && \
	  tar -jxvf mpg123-1.22.1.tar.bz2 && \
	  ln -sf mpg123-1.22.1 $(notdir $(mpg123_DIR))

mpg123_clean mpg123_distclean:
	if [ -e $(mpg123_DIR)/Makefile ]; then \
	  $(mpg123_MAKE) $(patsubst _%,%,$(@:mpg123%=%)); \
	fi

mpg123_makefile:
	cd $(mpg123_DIR) && ./configure $(mpg123_CFGPARAM)

mpg123 mpg123_%:
	if [ ! -d $(mpg123_DIR) ]; then \
	  $(MAKE) mpg123_dir; \
	fi
	if [ ! -e $(mpg123_DIR)/Makefile ]; then \
	  $(MAKE) mpg123_makefile; \
	fi
	$(mpg123_MAKE) $(patsubst _%,%,$(@:mpg123%=%))

#------------------------------------
#
openssl_DIR = $(PROJDIR)/package/openssl
openssl_MAKE = $(MAKE) INSTALL_PREFIX=$(DESTDIR) \
    CFLAG="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    EX_LIBS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
    -C $(openssl_DIR)
openssl_CFGPARAM = threads shared zlib-dynamic no-rc5 no-idea enable-deprecated \
    --prefix=/ --openssldir=/usr/openssl \
    linux-armv4:$(CC):"$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC"

openssl_dir:
	wget -O $(dir $(openssl_DIR))/openssl-1.0.2-latest.tar.gz \
	    https://www.openssl.org/source/openssl-1.0.2-latest.tar.gz
	cd $(dir $(openssl_DIR)) && \
	  tar -zxvf openssl-1.0.2-latest.tar.gz && \
	  ln -sf openssl-1.0.2c $(notdir $(openssl_DIR))

openssl_clean openssl_distclean:
	if [ -e $(openssl_DIR)/Makefile ]; then \
	  $(openssl_MAKE) clean; \
	fi

openssl_makefile:
	cd $(openssl_DIR) && $(openssl_CFGENV) ./Configure $(openssl_CFGPARAM)

openssl openssl_%:
	if [ ! -d $(openssl_DIR) ]; then \
	  $(MAKE) openssl_dir; \
	fi
	if [ ! -e $(openssl_DIR)/Makefile.bak ]; then \
	  $(MAKE) openssl_makefile; \
	fi
	$(openssl_MAKE) $(patsubst openssl,,$(@:openssl_%=%))

#------------------------------------
#
wpa-supplicant_DIR = $(PROJDIR)/package/wpa_supplicant
wpa-supplicant_MAKE = $(MAKE) DESTDIR=$(DESTDIR) LIBDIR=/lib/ BINDIR=/usr/sbin/ \
    EXTRA_CFLAGS+="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS+="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
    CONFIG_LIBNL32=1 LIBNL_INC="$(DESTDIR)/include/libnl3" \
    CC=$(CC) -C $(wpa-supplicant_DIR)/wpa_supplicant

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

wpa-supplicant wpa-supplicant_%:
	if [ ! -d $(wpa-supplicant_DIR) ]; then \
	  $(MAKE) wpa-supplicant_dir; \
	fi
	if [ ! -e $(wpa-supplicant_DIR)/wpa_supplicant/.config ]; then \
	  $(MAKE) wpa-supplicant_makefile; \
	fi
	$(wpa-supplicant_MAKE) \
	    $(patsubst wpa-supplicant,,$(@:wpa-supplicant_%=%))

#------------------------------------
#
curl_DIR = $(PROJDIR)/package/curl
curl_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(curl_DIR)
curl_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) --with-ssl \
    CFLAGS="$(PLATFORM_CFLAGS)" CPPFLAGS="-I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

curl_dir:
	cd $(dir $(curl_DIR)) && \
	    wget http://curl.haxx.se/download/curl-7.43.0.tar.bz2
	cd $(dir $(curl_DIR)) && \
	  tar -jxvf curl-7.43.0.tar.bz2 && \
	  ln -sf curl-7.43.0 $(notdir $(curl_DIR))

curl_clean curl_distclean:
	if [ -e $(curl_DIR)/Makefile ]; then \
	  $(curl_MAKE) $(patsubst _%,%,$(@:curl%=%)); \
	fi

curl_makefile:
	cd $(curl_DIR) && $(curl_CFGENV) ./configure $(curl_CFGPARAM)

curl curl_%:
	if [ ! -d $(curl_DIR) ]; then \
	  $(MAKE) curl_dir; \
	fi
	if [ ! -e $(curl_DIR)/Makefile ]; then \
	  $(MAKE) curl_makefile; \
	fi
	$(curl_MAKE) $(patsubst _%,%,$(@:curl%=%))

#------------------------------------
#
sox_DIR = $(PROJDIR)/package/sox
sox_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(sox_DIR)
sox_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

sox_dir:
	git clone --depth=1 git://git.code.sf.net/p/sox/code $(sox_DIR)

sox_clean sox_distclean:
	if [ -e $(sox_DIR)/Makefile ]; then \
	  $(sox_MAKE) $(patsubst _%,%,$(@:sox%=%)); \
	fi

sox_configure:
	cd $(sox_DIR) && autoreconf -fiv

sox_makefile:
	echo "Makefile *** Generate Makefile by configure..."
	cd $(sox_DIR) && ./configure $(sox_CFGPARAM)

sox sox_%:
	if [ ! -d $(sox_DIR) ]; then \
	  $(MAKE) sox_dir; \
	fi
	if [ ! -x $(sox_DIR)/configure ]; then \
	  $(MAKE) sox_configure; \
	fi
	if [ ! -e $(sox_DIR)/Makefile ]; then \
	  $(MAKE) sox_makefile; \
	fi
	$(sox_MAKE) $(patsubst _%,%,$(@:sox%=%))

#------------------------------------
#
include bluez.mk

#------------------------------------
#
libmoss_DIR = $(PROJDIR)/package/libmoss
libmoss_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libmoss_DIR)
libmoss_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libmoss_clean libmoss_distclean:
	if [ -e $(libmoss_DIR)/Makefile ]; then \
	  $(libmoss_MAKE) $(patsubst _%,,$(@:libmoss%=%)); \
	fi

libmoss_dir:
	if [ ! -d $(libmoss_DIR) ]; then \
	  cd $(abspath $(libmoss_DIR)/..) && \
	      git clone git@bitbucket.org:joelai/libmoss.git; \
	else \
	  cd $(abspath $(libmoss_DIR)) && git pull; \
	fi

libmoss_configure:
	cd $(libmoss_DIR) && ./autogen.sh

libmoss_makefile:
	cd $(libmoss_DIR) && ./configure $(libmoss_CFGPARAM)

libmoss libmoss_%:
	if [ ! -d $(libmoss_DIR) ]; then \
	  $(MAKE) libmoss_dir; \
	fi
	if [ ! -x $(libmoss_DIR)/configure ]; then \
	  $(MAKE) libmoss_configure; \
	fi
	if [ -x $(libmoss_DIR)/configure ]; then \
	  $(MAKE) libmoss_makefile; \
	fi
	$(libmoss_MAKE) $(patsubst _%,,$(@:libmoss%=%))

#------------------------------------
#
webme_DIR = $(PROJDIR)/package/webme
webme_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(webme_DIR)
webme_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    --with-pic --with-debug \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

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

webme webme_%:
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

#------------------------------------
#
v4l2info_DIR = $(PROJDIR)/package/v4l2info

v4l2info v4l2info_%:
	$(MAKE) PREFIX=/usr DESTDIR=$(DESTDIR) CROSS_COMPILE=$(CROSS_COMPILE) \
	    EXTRA_CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    EXTRA_LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	    -C $(v4l2info_DIR) $(patsubst _%,%,$(@:v4l2info%=%))

#------------------------------------
#
fbinfo_DIR = $(PROJDIR)/package/fbinfo

fbinfo fbinfo_%:
	$(MAKE) PREFIX=/usr DESTDIR=$(DESTDIR) CROSS_COMPILE=$(CROSS_COMPILE) \
	    EXTRA_CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    EXTRA_LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	    -C $(fbinfo_DIR) $(patsubst _%,%,$(@:fbinfo%=%))

#------------------------------------
#
gpioctl-pi_DIR = $(PROJDIR)/package/gpioctl-pi

gpioctl-pi gpioctl-pi_%:
	$(MAKE) PREFIX=/usr DESTDIR=$(DESTDIR) CROSS_COMPILE=$(CROSS_COMPILE) \
	    EXTRA_CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    EXTRA_LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	    -C $(gpioctl-pi_DIR) $(patsubst _%,%,$(@:gpioctl-pi%=%))

#------------------------------------
#
tool: $(PROJDIR)/tool/bin/mkimage

$(PROJDIR)/tool/bin/mkimage:
	$(MAKE) uboot_tools
	$(MKDIR) $(dir $@)
	$(CP) $(uboot_DIR)/tools/mkimage $(dir $@)

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
dist_cp:
	@[ -d $(DESTDIR) ] || $(MKDIR) $(DESTDIR)
	@for i in $(SRCFILE); do \
	  for j in $(SRCDIR)/$$i; do \
	    if [ -x $$j ] && [ ! -h $$j ] && [ ! -d $$j ]; then \
	      echo "$(COLOR_GREEN)installing(strip) $$j$(COLOR)"; \
	      $(INSTALL_STRIP) $$j $(DESTDIR); \
	    elif [ -e $$j ]; then \
	      echo "$(COLOR_GREEN)installing(cp) $$j$(COLOR)"; \
	      $(CP) -d $$j $(DESTDIR)/; \
	    else \
	      echo "$(COLOR_RED)missing $$j$(COLOR)"; \
	    fi; \
	  done; \
	done

#------------------------------------
#
devlist:
	$(MKDIR) $(dir $(DEVLIST))
	echo -n "" > $(DEVLIST)
	echo "dir /dev 0755 0 0" >> $(DEVLIST)
	echo "nod /dev/console 0600 0 0 c 5 1" >> $(DEVLIST)

.PHONY: devlist

so1:
	$(MAKE) SRCFILE="ld-*.so.* ld-*.so libpthread.so.* libpthread-*.so" \
	    SRCDIR=$(CROSS_COMPILE_PATH)/arm-linux-gnueabihf/libc/lib \
	    DESTDIR=$(DESTDIR)/lib dist_cp 
	$(MAKE) SRCFILE="libc.so.* libc-*.so libm.so.* libm-*.so" \
	    SRCDIR=$(CROSS_COMPILE_PATH)/arm-linux-gnueabihf/libc/lib \
	    DESTDIR=$(DESTDIR)/lib dist_cp 

so2:
	$(MAKE) SRCFILE="libgcc_s.so.1 libdl.so.* libdl-*.so librt.so.* librt-*.so" \
	    SRCDIR=$(CROSS_COMPILE_PATH)/arm-linux-gnueabihf/libc/lib \
	    DESTDIR=$(DESTDIR)/lib dist_cp
	$(MAKE) SRCFILE="libnss_*.so libnss_*.so.*" \
	    SRCDIR=$(CROSS_COMPILE_PATH)/arm-linux-gnueabihf/libc/lib \
	    DESTDIR=$(DESTDIR)/lib dist_cp

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

dist-bt%:
	$(MAKE) zlib$(@:dist-bt%=%) expat$(@:dist-bt%=%) \
	    libical$(@:dist-bt%=%) ncurses$(@:dist-bt%=%) libffi$(@:dist-bt%=%)
	$(MAKE) readline$(@:dist-bt%=%) glib$(@:dist-bt%=%) \
	    dbus$(@:dist-bt%=%)
	$(MAKE) bluez$(@:dist-bt%=%)

userland: tool
	$(MAKE) linux_headers_install
	$(MAKE) busybox
	for i in proc sys dev tmp var/run; do \
	  [ -d $(PROJDIR)/userland/$$i ] || $(MKDIR) $(PROJDIR)/userland/$$i; \
	done
	$(MAKE) DESTDIR=$(PROJDIR)/userland \
	    so1 so2 busybox_install linux_modules_install
ifeq ("$(PLATFORM)","PI2")
	$(MAKE) DESTDIR=$(PROJDIR)/userland \
	    PREBUILT="$(PROJDIR)/prebuilt/userland/* $(PROJDIR)/prebuilt/userland-pi/*" \
	    prebuilt
	$(MAKE) hx711-drv
	$(MAKE) DESTDIR=$(PROJDIR)/userland hx711-drv_modules_install
else
	$(MAKE) DESTDIR=$(PROJDIR)/userland \
	    PREBUILT="$(PROJDIR)/prebuilt/userland/*" prebuilt
endif
	$(MAKE) zlib_install libmoss_install libnl_install openssl_install
	$(MAKE) SRCFILE="libz.so libz.so.* libmoss.so libmoss.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist_cp
	$(MAKE) SRCFILE="libnl-*.so libnl-*.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist_cp
	$(MAKE) SRCFILE="openssl" \
	    SRCDIR=$(DESTDIR)/usr DESTDIR=$(PROJDIR)/userland/usr \
	    dist_cp
	$(MAKE) SRCFILE="openssl" \
	    SRCDIR=$(DESTDIR)/bin DESTDIR=$(PROJDIR)/userland/bin \
	    dist_cp
	$(MAKE) curl_install
	$(MAKE) SRCFILE="libcurl.so libcurl.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist_cp
	$(MAKE) SRCFILE="curl" \
	    SRCDIR=$(DESTDIR)/bin DESTDIR=$(PROJDIR)/userland/bin \
	    dist_cp
	$(MAKE) libevent_install libjpeg-turbo_install json-c_install \
	    x264_install mpg123_install v4l2info_install
	$(MAKE) SRCFILE="libevent.so libevent-*.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist_cp
	$(MAKE) SRCFILE="libturbojpeg.so libturbojpeg.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist_cp
	$(MAKE) SRCFILE="libjson-c.so libjson-c.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist_cp
	$(MAKE) SRCFILE="libx264.so libx264.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist_cp
	$(MAKE) SRCFILE="libmpg123.so libmpg123.so.*" \
	    SRCDIR=$(DESTDIR)/lib DESTDIR=$(PROJDIR)/userland/lib \
	    dist_cp
	$(MAKE) SRCFILE="mpg123" \
	    SRCDIR=$(DESTDIR)/bin DESTDIR=$(PROJDIR)/userland/bin \
	    dist_cp
	$(MAKE) SRCFILE="v4l2info" \
	    SRCDIR=$(DESTDIR)/usr/bin DESTDIR=$(PROJDIR)/userland/usr/bin \
	    dist_cp
ifeq ("$(PLATFORM)","PI2")
	$(MAKE) gpioctl-pi_install
	$(MAKE) SRCFILE="gpioctl" \
	    SRCDIR=$(DESTDIR)/usr/bin DESTDIR=$(PROJDIR)/userland/usr/bin \
	    dist_cp
else
endif
	$(MAKE) wpa-supplicant_install
	$(MAKE) SRCFILE="wpa_*" \
	    SRCDIR=$(DESTDIR)/usr/sbin DESTDIR=$(PROJDIR)/userland/usr/sbin \
	    dist_cp

.PHONY: userland

dist:
	$(RM) userland obj dist
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
	$(MAKE) $(MAKEPARAM) $(linux_MAKEPARAM) \
	    -C $(PROJDIR)/$(call test_DIR,$@) $(call test_TARGET,$@)

#------------------------------------
#
install: ;
	

#------------------------------------
#

