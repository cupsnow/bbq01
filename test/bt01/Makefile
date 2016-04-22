include $(PROJDIR)/proj.mk

CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard \
    -I$(DESTDIR)/include -I$(INSTALL_HDR_PATH)/include
LDFLAGS = -L$(DESTDIR)/lib
TFTPROOT = /var/local/ftproot

#------------------------------------
#
all: bin/bt01

#------------------------------------
#
$(eval $(call PROJ_DIST_CP,))

#------------------------------------
#
BT01_OBJS_C = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))
BT01_OBJS = $(BT01_OBJS_C) $(BT01_OBJS_CPP)

bin/bt01: $(BT01_OBJS)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(BT01_OBJS) $(LDFLAGS) -lmoss -pthread -lbluetooth

bt01_install: bin/bt01
	$(MAKE) SRCFILE="bt01" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist-cp

bt01_clean bt01_distclean:
	$(RM) bin $(BT01_OBJS) $(addsuffix $(DEP),$(BT01_OBJS))

$(eval $(call PROJ_COMPILE_C,bt01))

#------------------------------------
#
install clean distclean:
	$(MAKE) $(addsuffix _$@,bt01)

