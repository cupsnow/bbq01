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
libffi_DIR = $(PWD)/package/libffi
libffi_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libffi_DIR)
libffi_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    --with-pic \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libffi: libffi_;

libffi_dir:
	$(call PROJ_WGET,$(libffi_DIR),$(PKGDIR),ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz)

$(addprefix libffi_,clean distclean): ;
	if [ -e $(libffi_DIR)/Makefile ]; then \
	  $(libffi_MAKE) $(patsubst _%,%,$(@:libffi%=%)); \
	fi

libffi_makefile:
	cd $(libffi_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    --with-pic \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libffi%:
	if [ ! -d $(libffi_DIR) ]; then \
	  $(MAKE) libffi_dir; \
	fi
	if [ ! -f $(libffi_DIR)/Makefile ]; then \
	  $(MAKE) libffi_makefile; \
	fi
	$(libffi_MAKE) $(patsubst _%,%,$(@:libffi%=%))

CLEAN += libffi

#------------------------------------
# dependent: libffi zlib
#
glib_DIR = $(PWD)/package/glib
glib_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(glib_DIR)

glib: glib_;

glib_dir:
	$(call PROJ_WGET,$(glib_DIR),$(PKGDIR),http://ftp.gnome.org/pub/gnome/sources/glib/2.46/glib-2.46.2.tar.xz)

$(addprefix glib_,clean distclean): ;
	if [ -e $(glib_DIR)/Makefile ]; then \
	  $(glib_MAKE) $(patsubst _%,%,$(@:glib%=%)); \
	fi

glib_makefile:
	cd $(glib_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    --with-pic --enable-static --cache-file=$(glib_CFGCACHE) \
	    glib_cv_stack_grows=no glib_cv_uscore=yes \
	    ac_cv_func_posix_getpwuid_r=yes ac_cv_func_posix_getgrgid_r=yes \
	    LIBFFI_CFLAGS="-I$(dir $(wildcard $(DESTDIR)/lib/libffi-*/include/ffi.h))" \
	    LIBFFI_LIBS="-L$(DESTDIR)/lib -lffi" \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib -lffi"

glib%:
	if [ ! -d $(glib_DIR) ]; then \
	  $(MAKE) glib_dir; \
	fi
	if [ ! -f $(glib_DIR)/Makefile ]; then \
	  $(MAKE) glib_makefile; \
	fi
	$(glib_MAKE) $(patsubst _%,%,$(@:glib%=%))

CLEAN += glib

#------------------------------------
# dependent: expat
#
dbus_DIR = $(PWD)/package/dbus
dbus_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(dbus_DIR)
dbus_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    --with-pic --enable-abstract-sockets \
    $(addprefix --disable-,tests) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

dbus: dbus_;

dbus_dir:
	$(call PROJ_WGET,$(dbus_DIR),$(PKGDIR),http://dbus.freedesktop.org/releases/dbus/dbus-1.11.0.tar.gz)

$(addprefix dbus_,clean distclean): ;
	if [ -e $(dbus_DIR)/Makefile ]; then \
	  $(dbus_MAKE) $(patsubst _%,%,$(@:dbus%=%)); \
	fi

dbus_makefile:
	cd $(dbus_DIR) && ./configure --prefix= --host=`$(CC) -dumpmachine` \
	    --with-pic --enable-abstract-sockets \
	    $(addprefix --disable-,tests) \
	    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

dbus%:
	if [ ! -d $(dbus_DIR) ]; then \
	  $(MAKE) dbus_dir; \
	fi
	if [ ! -f $(dbus_DIR)/Makefile ]; then \
	  $(MAKE) dbus_makefile; \
	fi
	$(dbus_MAKE) $(patsubst _%,%,$(@:dbus%=%))

CLEAN += dbus

#------------------------------------
# dependent: glib libxml2
#
libical_DIR = $(PWD)/package/libical
libical_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libical_DIR)/build

libical: libical_;

libical_dir:
	$(call PROJ_GIT,$(libical_DIR),$(PKGDIR),https://github.com/libical/libical.git)

libical_clean:
	if [ -e $(libical_DIR)/build/Makefile ]; then \
	  $(libical_MAKE) $(patsubst _%,%,$(@:libical%=%)); \
	fi

libical_distclean:
	$(RM) $(libical_DIR)/build

libical_makefile:
	$(MKDIR) $(libical_DIR)/build && cd $(libical_DIR)/build && \
	  CC=$(CC) CXX=$(C++) \
	      CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
	      LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib" \
	      LIBS="-lxml2 -lffi" \
	      $(PKG_CONFIG_ENV) \
	      cmake -DCMAKE_INSTALL_PREFIX=/ ..

libical%:
	if [ ! -d $(libical_DIR) ]; then \
	  $(MAKE) libical_dir; \
	fi
	if [ ! -e $(libical_DIR)/build/Makefile ]; then \
	  $(MAKE) libical_makefile; \
	fi
	$(libical_MAKE) $(patsubst _%,%,$(@:libical%=%))

CLEAN += libical

#------------------------------------
# dependent: glib readline, libical, dbus
#
bluez_DIR = $(PWD)/package/bluez
bluez_MAKE = $(MAKE) DESTDIR=$(DESTDIR) V=1 -C $(bluez_DIR)
bluez_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    --with-pic $(addprefix --enable-,static threads pie) \
    $(addprefix --disable-,test udev cups systemd) \
    --enable-library \
    --with-dbusconfdir=/etc \
    --with-dbussystembusdir=/share/dbus-1/system-services \
    --with-dbussessionbusdir=/share/dbus-1/services \
    GLIB_CFLAGS="-I$(DESTDIR)/include/glib-2.0 -I$(DESTDIR)/lib/glib-2.0/include" \
    GLIB_LIBS="-L$(DESTDIR)/lib -lglib-2.0" \
    GTHREAD_CFLAGS="-I$(DESTDIR)/include/glib-2.0" \
    GTHREAD_LIBS="-L$(DESTDIR)/lib -lgthread-2.0" \
    DBUS_CFLAGS="-I$(DESTDIR)/include/dbus-1.0 -I$(DESTDIR)/lib/dbus-1.0/include" \
    DBUS_LIBS="-L$(DESTDIR)/lib -ldbus-1" \
    ICAL_CFLAGS="-I$(DESTDIR)/include" \
    ICAL_LIBS="-L$(DESTDIR)/lib -lical -licalss -licalvcal -lpthread" \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib -lncurses"

bluez: bluez_;

bluez_dir:
	cd $(dir $(bluez_DIR)) && \
	  wget http://www.kernel.org/pub/linux/bluetooth/bluez-5.37.tar.xz && \
	  tar -Jxvf bluez-5.37.tar.xz && \
	  ln -sf bluez-5.37 $(bluez_DIR)

$(addprefix bluez_,clean distclean): ;
	if [ -e $(bluez_DIR)/Makefile ]; then \
	  $(bluez_MAKE) $(patsubst _%,%,$(@:bluez%=%)); \
	fi

bluez_makefile:
	cd $(bluez_DIR) && ./configure $(bluez_CFGPARAM)

bluez%:
	if [ ! -d $(bluez_DIR) ]; then \
	  $(MAKE) bluez_dir; \
	fi
	if [ ! -e $(bluez_DIR)/Makefile ]; then \
	  $(MAKE) bluez_makefile; \
	fi
	$(bluez_MAKE) $(patsubst _%,%,$(@:bluez%=%))
	if [ "$(patsubst _%,%,$(@:bluez%=%))" = "install" ]; then \
	  [ -d $(DESTDIR)/etc/bluetooth ] || $(MKDIR) $(DESTDIR)/etc/bluetooth; \
	  $(CP) $(bluez_DIR)/src/main.conf $(DESTDIR)/etc/bluetooth/; \
	fi

CLEAN += bluez

#------------------------------------
#
distclean clean:
	$(MAKE) $(addsuffix _$@,$(CLEAN))

#------------------------------------
#
