include $(PROJDIR)/proj.mk

CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard \
    -I$(DESTDIR)/include -I$(INSTALL_HDR_PATH)/include \
    -I$(DESTDIR)/include/libdrm \
    -DMESA_EGL_NO_X11_HEADERS
LDFLAGS = -L$(DESTDIR)/lib -lm -ldrm -lexpat -lgbm -lEGL -lGLESv2 -lglapi
TFTPROOT = /var/local/ftproot

#------------------------------------
#
all: bin/drm5

#------------------------------------
#
$(eval $(call PROJ_DIST_CP,))

#------------------------------------
#
drm5_OBJS_C = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))
drm5_OBJS = $(drm5_OBJS_C) $(drm5_OBJS_CPP)

bin/drm5: $(drm5_OBJS)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(drm5_OBJS) $(LDFLAGS) -lmoss -pthread

drm5_install: bin/drm5
	$(MAKE) SRCFILE="drm5" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist-cp

drm5_clean drm5_distclean:
	$(RM) bin $(drm5_OBJS) $(addsuffix $(DEP),$(drm5_OBJS))

$(eval $(call PROJ_COMPILE_C,drm5))

#------------------------------------
#
install clean distclean:
	$(MAKE) $(addsuffix _$@,drm5)

