include $(PROJDIR)/proj.mk

CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard \
    -I$(DESTDIR)/include -I$(INSTALL_HDR_PATH)/include \
    -I$(DESTDIR)/include/libdrm
LDFLAGS = -L$(DESTDIR)/lib -ldrm -lexpat -lgbm -lglapi -lEGL -lGLESv2
TFTPROOT = /var/local/ftproot

#------------------------------------
#
all: bin/drm2

#------------------------------------
#
$(eval $(call PROJ_DIST_CP,))

#------------------------------------
#
drm2_OBJS_C = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))
drm2_OBJS = $(drm2_OBJS_C) $(drm2_OBJS_CPP)

bin/drm2: $(drm2_OBJS)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(drm2_OBJS) $(LDFLAGS) -lmoss -pthread

drm2_install: bin/drm2
	$(MAKE) SRCFILE="drm2" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist-cp

drm2_clean drm2_distclean:
	$(RM) bin $(drm2_OBJS) $(addsuffix $(DEP),$(drm2_OBJS))

$(eval $(call PROJ_COMPILE_C,drm2))

#------------------------------------
#
install clean distclean:
	$(MAKE) $(addsuffix _$@,drm2)

