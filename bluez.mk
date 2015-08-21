#------------------------------------
#
bluez_default:
	echo "$(COLOR_RED)Please involved from Makefile$(COLOR)"

#------------------------------------
#
libical_DIR = $(PROJDIR)/package/libical
libical_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libical_DIR)/build
libical_CFGENV = CC=$(CC) CXX=$(C++) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"
libical_CFGPARAM = -DCMAKE_INSTALL_PREFIX=/

libical_dir:
	git clone https://github.com/libical/libical.git $(libical_DIR)

libical_clean:
	if [ -e $(libical_DIR)/build/Makefile ]; then \
	  $(libical_MAKE) $(patsubst _%,%,$(@:libical%=%)) \ 
	fi

libical_distclean:
	$(RM) $(libical_DIR)/build

libical_makefile:
	$(MKDIR) $(libical_DIR)/build && cd $(libical_DIR)/build && \
	  $(libical_CFGENV) cmake $(libical_CFGPARAM) ..

libical libical_%:
	if [ ! -e $(libical_DIR)/build/Makefile ]; then \
	  $(MAKE) libical_makefile; \
	fi
	$(libical_MAKE) $(patsubst _%,%,$(@:libical%=%))

#------------------------------------
#
expat_DIR = $(PROJDIR)/package/expat
expat_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(expat_DIR)
expat_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    --with-pic \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

$(addprefix expat_,clean distclean): ;
	if [ -e $(expat_DIR)/Makefile ]; then \
	  $(expat_MAKE) $(patsubst _%,%,$(@:expat%=%)); \
	fi

expat_dir: ;
	wget -O $(dir $(expat_DIR))/expat-2.1.0.tar.gz \
	    http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz
	cd  $(dir $(expat_DIR)) && \
	  tar -zxvf expat-2.1.0.tar.gz && \
	  ln -sf expat-2.1.0 $(notdir $(expat_DIR))

expat_makefile:
	echo "Makefile *** Generate Makefile by configure..."
	cd $(expat_DIR) && $(expat_CFGENV) ./configure $(expat_CFGPARAM)

expat expat_%:
	if [ ! -d $(expat_DIR) ]; then \
	  $(MAKE) expat_dir; \
	fi
	if [ ! -f $(expat_DIR)/Makefile ]; then \
	  $(MAKE) expat_makefile; \
	fi
	$(expat_MAKE) $(patsubst _%,%,$(@:expat%=%))

#------------------------------------
#
ncurses_DIR = $(PROJDIR)/package/ncurses
ncurses_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(ncurses_DIR)
ncurses_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    --without-tests --without-manpages --disable-db-install \
    --with-shared --with-cxx-shared \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

ncurses_dir:
	wget -O $(dir $(ncurses_DIR))/ncurses-6.0.tar.gz \
	    http://ftp.gnu.org/gnu/ncurses/ncurses-6.0.tar.gz
	cd $(dir $(ncurses_DIR)) && \
	    tar -zxvf ncurses-6.0.tar.gz && \
	    ln -sf ncurses-6.0 ncurses

ncurses_clean ncurses_distclean:
	if [ -e $(ncurses_DIR)/Makefile ]; then \
	  $(ncurses_MAKE) $(patsubst _%,%,$(@:ncurses%=%)); \
	fi

ncurses_makefile:
	cd $(ncurses_DIR) && ./configure $(ncurses_CFGPARAM)

ncurses_install-terminfo:
	tic -s -1 -I -e"$(TERMLIST)" $(ncurses_DIR)/misc/terminfo.src > terminfo.tmp
	$(MKDIR) $(DESTDIR)/etc/terminfo
	tic -s -o $(DESTDIR)/etc/terminfo terminfo.tmp

ncurses ncurses_%:
	if [ ! -d $(ncurses_DIR) ]; then \
	  $(MAKE) ncurses_dir; \
	fi
	if [ ! -e $(ncurses_DIR)/Makefile ]; then \
	  $(MAKE) ncurses_makefile; \
	fi
	$(ncurses_MAKE) $(patsubst _%,%,$(@:ncurses%=%))

#------------------------------------
#
libffi_DIR = $(PROJDIR)/package/libffi
libffi_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(libffi_DIR)
libffi_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    --with-pic --includedir=/include \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

libffi_dir: ;
	wget -O $(dir $(libffi_DIR))/libffi-3.2.1.tar.gz \
	    ftp://sourceware.org/pub/libffi/libffi-3.2.1.tar.gz
	cd  $(dir $(libffi_DIR)) && \
	  tar -zxvf libffi-3.2.1.tar.gz && \
	  ln -sf libffi-3.2.1 $(notdir $(libffi_DIR))

$(addprefix libffi_,clean distclean): ;
	if [ -e $(libffi_DIR)/Makefile ]; then \
	  $(libffi_MAKE) $(patsubst _%,%,$(@:libffi%=%)); \
	fi

libffi_makefile:
	echo "Makefile *** Generate Makefile by configure..."
	cd $(libffi_DIR) && $(libffi_CFGENV) ./configure $(libffi_CFGPARAM)

libffi libffi_%:
	if [ ! -d $(libffi_DIR) ]; then \
	  $(MAKE) libffi_dir; \
	fi
	if [ ! -f $(libffi_DIR)/Makefile ]; then \
	  $(MAKE) libffi_makefile; \
	fi
	$(libffi_MAKE) $(patsubst _%,%,$(@:libffi%=%))
	if [ "$(patsubst _%,%,$(@:libffi%=%))" = "install" ]; then \
	  if [ -d $(DESTDIR)/lib/libffi-*/include ]; then \
	    $(MKDIR) $(DESTDIR)/include; \
	    mv $(DESTDIR)/lib/libffi-*/include/* $(DESTDIR)/include/; \
	    $(RM) `dirname $(DESTDIR)/lib/libffi-*/include`; \
	  fi; \
	fi

#------------------------------------
# dependent: expat
#
dbus_DIR = $(PROJDIR)/package/dbus
dbus_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(dbus_DIR)
dbus_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    --with-pic --enable-abstract-sockets \
    $(addprefix --disable-,tests xml-docs doxygen-docs) \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

dbus_dir: ;
	wget -O $(dir $(dbus_DIR))/dbus-1.8.20.tar.gz \
	    http://dbus.freedesktop.org/releases/dbus/dbus-1.8.20.tar.gz
	cd  $(dir $(dbus_DIR)) && \
	  tar -zxvf dbus-1.8.20.tar.gz && \
	  ln -sf dbus-1.8.20 $(notdir $(dbus_DIR))

$(addprefix dbus_,clean distclean): ;
	if [ -e $(dbus_DIR)/Makefile ]; then \
	  $(dbus_MAKE) $(patsubst _%,%,$(@:dbus%=%)); \
	fi

dbus_makefile:
	echo "Makefile *** Generate Makefile by configure..."
	cd $(dbus_DIR) && $(dbus_CFGENV) ./configure $(dbus_CFGPARAM)

dbus dbus_%:
	if [ ! -d $(dbus_DIR) ]; then \
	  $(MAKE) dbus_dir; \
	fi
	if [ ! -f $(dbus_DIR)/Makefile ]; then \
	  $(MAKE) dbus_makefile; \
	fi
	$(dbus_MAKE) $(patsubst _%,%,$(@:dbus%=%))

#------------------------------------
# dependency: ncurses
#
readline_DIR = $(PROJDIR)/package/readline
readline_MAKE = $(MAKE) DESTDIR=$(DESTDIR) SHLIB_LIBS=-lncurses -C $(readline_DIR)
readline_CFGPARAM = --prefix= --host=`$(CC) -dumpmachine` \
    bash_cv_wcwidth_broken=yes \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include -fPIC" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

readline_dir:
	wget -O $(dir $(readline_DIR))/readline-6.3.tar.gz \
	    ftp://ftp.cwru.edu/pub/bash/readline-6.3.tar.gz
	cd $(dir $(readline_DIR)) && \
	    tar -zxvf readline-6.3.tar.gz && \
	    ln -sf readline-6.3 readline

readline_clean readline_distclean:
	if [ -e $(readline_DIR)/Makefile ]; then \
	  $(readline_MAKE) $(patsubst _%,%,$(@:readline%=%)); \
	fi

readline_makefile:
	echo "Makefile *** Generate Makefile by configure..."
	cd $(readline_DIR) && ./configure $(readline_CFGPARAM)

readline readline_%:
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

#------------------------------------
# dependent: libffi zlib
#
glib_DIR = $(PROJDIR)/package/glib
glib_MAKE = $(MAKE) DESTDIR=$(DESTDIR) -C $(glib_DIR)
glib_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    --with-pic --enable-static --cache-file=$(glib_CFGCACHE) \
    glib_cv_stack_grows=no glib_cv_uscore=yes \
    ac_cv_func_posix_getpwuid_r=yes ac_cv_func_posix_getgrgid_r=yes \
    LIBFFI_CFLAGS="-I$(DESTDIR)/include" \
    LIBFFI_LIBS="-L$(DESTDIR)/lib -lffi" \
    CFLAGS="$(PLATFORM_CFLAGS) -I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib"

glib_dir: ;
	wget -O $(dir $(glib_DIR))/glib-2.44.1.tar.xz \
	    https://download.gnome.org/sources/glib/2.44/glib-2.44.1.tar.xz
	cd  $(dir $(glib_DIR)) && \
	  tar -Jxvf glib-2.44.1.tar.xz && \
	  ln -sf glib-2.44.1 $(notdir $(glib_DIR))

$(addprefix glib_,clean distclean): ;
	if [ -e $(glib_DIR)/Makefile ]; then \
	  $(glib_MAKE) $(patsubst _%,%,$(@:glib%=%)); \
	fi

glib_makefile:
	echo "Makefile *** Generate Makefile by configure..."
	cd $(glib_DIR) && $(glib_CFGENV) ./configure $(glib_CFGPARAM)

glib glib_%:
	if [ ! -d $(glib_DIR) ]; then \
	  $(MAKE) glib_dir; \
	fi
	if [ ! -f $(glib_DIR)/Makefile ]; then \
	  $(MAKE) glib_makefile; \
	fi
	$(glib_MAKE) $(patsubst _%,%,$(@:glib%=%))

#------------------------------------
# dependent: readline, libical, dbus, glib
#

bluez_DIR = $(PROJDIR)/package/bluez
bluez_MAKE = $(MAKE) DESTDIR=$(DESTDIR) V=1 -C $(bluez_DIR)
bluez_CFGPARAM = --prefix= --host=$(shell PATH=$(PATH) $(CC) -dumpmachine) \
    --with-pic $(addprefix --enable-,static library threads pie) \
    $(addprefix --disable-,udev cups systemd) \
    --with-dbusconfdir=/etc \
    --with-dbussystembusdir=/share/dbus-1/system-services \
    --with-dbussessionbusdir=/share/dbus-1/services \
    DBUS_CFLAGS="-I$(DESTDIR)/include/dbus-1.0 -I$(DESTDIR)/lib/dbus-1.0/include" \
    DBUS_LIBS="-L$(DESTDIR)/lib -ldbus-1" \
    ICAL_CFLAGS="-I$(DESTDIR)/include" \
    ICAL_LIBS="-L$(DESTDIR)/lib -lical -licalss -licalvcal -lpthread" \
    CFLAGS="$(PLATFORM_CFLAGS)" CPPFLAGS="-I$(DESTDIR)/include" \
    LDFLAGS="$(PLATFORM_LDFLAGS) -L$(DESTDIR)/lib -lncurses"

bluez_dir:
	wget -O $(dir $(bluez_DIR))/bluez-5.33.tar.xz \
	    http://www.kernel.org/pub/linux/bluetooth/bluez-5.33.tar.xz
	cd  $(dir $(bluez_DIR)) && \
	  tar -Jxvf bluez-5.33.tar.xz && \
	  ln -sf bluez-5.33 $(notdir $(bluez_DIR))

$(addprefix bluez_,clean distclean): ;
	if [ -e $(bluez_DIR)/Makefile ]; then \
	  $(bluez_MAKE) $(patsubst _%,%,$(@:bluez%=%)); \
	fi

bluez_makefile:
	cd $(bluez_DIR) && ./configure $(bluez_CFGPARAM)

bluez bluez_%:
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

#------------------------------------
#

