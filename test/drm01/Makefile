include $(PROJDIR)/proj.mk

CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard \
    -I$(DESTDIR)/include -I$(INSTALL_HDR_PATH)/include
LDFLAGS = -L$(DESTDIR)/lib
TFTPROOT = /var/local/ftproot

#------------------------------------
#
all: bin/drm01

#------------------------------------
#
$(eval $(call PROJ_DIST_CP,))

#------------------------------------
#
drm01_OBJS_C = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))
drm01_OBJS = $(drm01_OBJS_C) $(drm01_OBJS_CPP)

bin/drm01: $(drm01_OBJS)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(drm01_OBJS) $(LDFLAGS) -lmoss -pthread

drm01_install: bin/drm01
	$(MAKE) SRCFILE="drm01" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist-cp

drm01_clean drm01_distclean:
	$(RM) bin $(drm01_OBJS) $(addsuffix $(DEP),$(drm01_OBJS))

$(eval $(call PROJ_COMPILE_C,drm01))

#------------------------------------
#
install clean distclean:
	$(MAKE) $(addsuffix _$@,drm01)

