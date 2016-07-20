include $(PROJDIR)/proj.mk

CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard \
    -I$(DESTDIR)/include -I$(INSTALL_HDR_PATH)/include \
    -I$(DESTDIR)/include/libdrm \
    -DMESA_EGL_NO_X11_HEADERS
LDFLAGS = -L$(DESTDIR)/lib -ldrm -lexpat -lgbm -lglapi -lEGL
TFTPROOT = /var/local/ftproot

TARGET = eglinfo eglkms

#------------------------------------
#
all: $(addprefix bin/,$(TARGET))

#------------------------------------
#
$(eval $(call PROJ_DIST_CP,))

#------------------------------------
#
eglinfo_OBJS_C = $(PWD)/src/eglinfo.o
eglinfo_OBJS = $(eglinfo_OBJS_C) $(eglinfo_OBJS_CPP)
eglinfo_LDFLAGS = $(LDFLAGS) -lGLESv2

bin/eglinfo: $(eglinfo_OBJS)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(eglinfo_OBJS) $(eglinfo_LDFLAGS) -lmoss -pthread

eglinfo_install: bin/eglinfo
	$(MAKE) SRCFILE="eglinfo" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist-cp

eglinfo_clean eglinfo_distclean:
	$(RM) bin $(eglinfo_OBJS) $(addsuffix $(DEP),$(eglinfo_OBJS))

$(eval $(call PROJ_COMPILE_C,eglinfo))

#------------------------------------
#
eglkms_OBJS_C = $(PWD)/src/eglkms.o
eglkms_OBJS = $(eglkms_OBJS_C) $(eglkms_OBJS_CPP)
eglkms_LDFLAGS = $(LDFLAGS) -lGLESv1_CM

bin/eglkms: $(eglkms_OBJS)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(eglkms_OBJS) $(eglkms_LDFLAGS) -lmoss -pthread

eglkms_install: bin/eglkms
	$(MAKE) SRCFILE="eglkms" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist-cp

eglkms_clean eglkms_distclean:
	$(RM) bin $(eglkms_OBJS) $(addsuffix $(DEP),$(eglkms_OBJS))

$(eval $(call PROJ_COMPILE_C,eglkms))

#------------------------------------
#
install clean distclean:
	$(MAKE) $(addsuffix _$@,$(TARGET))

