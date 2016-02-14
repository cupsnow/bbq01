include $(PROJDIR)/proj.mk

#CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard
CFLAGS += -I$(DESTDIR)/include
LDFLAGS = -L$(DESTDIR)/lib
TFTPROOT = /var/local/ftproot

#------------------------------------
#
all: con2fbmap

#------------------------------------
#
$(eval $(call PROJ_DIST_CP,))

#------------------------------------
#
con2fbmap_OBJ_C = $(patsubst %.c,%.o,$(wildcard $(PWD)/*.c))
con2fbmap_OBJ = $(con2fbmap_OBJ_C) $(con2fbmap_OBJ_CPP)

con2fbmap: $(con2fbmap_OBJ)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(con2fbmap_OBJ) $(LDFLAGS) -lmoss -pthread

con2fbmap_install: bin/con2fbmap
	$(MAKE) SRCFILE="con2fbmap" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist-cp

con2fbmap_clean con2fbmap_distclean:
	$(RM) con2fbmap $(con2fbmap_OBJ) $(addsuffix $(DEP),$(con2fbmap_OBJ))

$(eval $(call PROJ_COMPILE_C,con2fbmap))

.PHONY: con2fbmap

#------------------------------------
#
install clean distclean:
	$(MAKE) $(addsuffix _$@,con2fbmap)

