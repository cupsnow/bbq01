include $(PROJDIR)/proj.mk

CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard \
    -I$(DESTDIR)/include -I$(INSTALL_HDR_PATH)/include \
    -I$(DESTDIR)/include/libdrm \
    -DMESA_EGL_NO_X11_HEADERS
LDFLAGS = -L$(DESTDIR)/lib -ldrm -lexpat -lgbm -lEGL -lGLESv2 -lglapi
TFTPROOT = /var/local/ftproot

#------------------------------------
#
all: bin/drm3

#------------------------------------
#
$(eval $(call PROJ_DIST_CP,))

#------------------------------------
#
drm3_OBJS_C = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))
drm3_OBJS = $(drm3_OBJS_C) $(drm3_OBJS_CPP)

bin/drm3: $(drm3_OBJS)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(drm3_OBJS) $(LDFLAGS) -lmoss -pthread

drm3_install: bin/drm3
	$(MAKE) SRCFILE="drm3" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist-cp

drm3_clean drm3_distclean:
	$(RM) bin $(drm3_OBJS) $(addsuffix $(DEP),$(drm3_OBJS))

$(eval $(call PROJ_COMPILE_C,drm3))

#------------------------------------
#
install clean distclean:
	$(MAKE) $(addsuffix _$@,drm3)

