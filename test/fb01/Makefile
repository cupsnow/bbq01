include $(PROJDIR)/proj.mk

CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard \
    -I$(DESTDIR)/include -I$(INSTALL_HDR_PATH)/include
LDFLAGS = -L$(DESTDIR)/lib
TFTPROOT = /var/local/ftproot

#------------------------------------
#
all: bin/fb01

#------------------------------------
#
$(eval $(call PROJ_DIST_CP,))

#------------------------------------
#
fb01_OBJS_C = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))
fb01_OBJS = $(fb01_OBJS_C) $(fb01_OBJS_CPP)

bin/fb01: $(fb01_OBJS)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(fb01_OBJS) $(LDFLAGS) -lmoss -pthread

fb01_install: bin/fb01
	$(MAKE) SRCFILE="fb01" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist-cp

fb01_clean fb01_distclean:
	$(RM) bin $(fb01_OBJS) $(addsuffix $(DEP),$(fb01_OBJS))

$(eval $(call PROJ_COMPILE_C,fb01))

#------------------------------------
#
install clean distclean:
	$(MAKE) $(addsuffix _$@,fb01)

