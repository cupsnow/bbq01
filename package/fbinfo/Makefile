#------------------------------------
#
PWD = $(abspath .)

#override CROSS_COMPILE_PATH := $(HOME)/02_dev/cam/ocarina/tool/buildroot-gcc342
#override CROSS_COMPILE := $(patsubst %gcc,%,$(notdir $(lastword $(wildcard $(CROSS_COMPILE_PATH)/bin/*gcc))))
#export PATH := $(CROSS_COMPILE_PATH)/bin:$(PATH)
#EXTRA_CFLAGS = -I$(HOME)/02_dev/cam/ocarina/runtime/include -g
#EXTRA_LDFLAGS = -L$(HOME)/02_dev/cam/ocarina/runtime/lib

$(info fbinfo Makefile *** CROSS_COMPILE_PATH=$(CROSS_COMPILE_PATH))
$(info fbinfo Makefile *** CROSS_COMPILE=$(CROSS_COMPILE))
$(info fbinfo Makefile *** PATH=$(PATH))

CC = $(CROSS_COMPILE)gcc
STRIP = $(CROSS_COMPILE)strip
INSTALL = install -D
INSTALL_STRIP = install -D -s --strip-program=$(STRIP)
RM = rm -rf
MKDIR = mkdir -p
CP = cp -dpR

DEP = $(1).d
DEPFLAGS = -MM -MF $(call DEP,$(1)) -MT $(1)

#------------------------------------
#
fbinfo_OBJ = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))

fbinfo_CFLAGS = $(EXTRA_CFLAGS) -I$(DESTDIR)/include -pthread
fbinfo_LDFLAGS = $(EXTRA_LDFLAGS) -L$(DESTDIR)/lib
fbinfo_LDFLAGS += -Wl,-Bstatic -lm -lmoss -Wl,-Bdynamic

bin/fbinfo: $(fbinfo_OBJ)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(fbinfo_OBJ) $(fbinfo_LDFLAGS)

$(fbinfo_OBJ): %.o : %.c
	$(CC) -c -o $@ $(fbinfo_CFLAGS) $<
	$(CC) -E $(call DEPFLAGS,$@) $(fbinfo_CFLAGS) $<
-include $(addsuffix $(DEP),$(fbinfo_OBJ))

install: bin/fbinfo
	$(MKDIR) $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_STRIP) bin/fbinfo $(DESTDIR)$(PREFIX)/bin/

clean distclean:
	$(RM) bin $(fbinfo_OBJ) $(addsuffix $(DEP),$(fbinfo_OBJ))

.PHONY: install distclean clean
