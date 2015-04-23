#------------------------------------
#
PWD = $(abspath .)

#override CROSS_COMPILE_PATH := $(HOME)/02_dev/cam/ocarina/tool/buildroot-gcc342
#override CROSS_COMPILE := $(patsubst %gcc,%,$(notdir $(lastword $(wildcard $(CROSS_COMPILE_PATH)/bin/*gcc))))
#export PATH := $(CROSS_COMPILE_PATH)/bin:$(PATH)
#EXTRA_CFLAGS = -I$(HOME)/02_dev/cam/ocarina/runtime/include -g
#EXTRA_LDFLAGS = -L$(HOME)/02_dev/cam/ocarina/runtime/lib

$(info v4l2info Makefile *** CROSS_COMPILE_PATH=$(CROSS_COMPILE_PATH))
$(info v4l2info Makefile *** CROSS_COMPILE=$(CROSS_COMPILE))
$(info v4l2info Makefile *** PATH=$(PATH))

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
v4l2info_OBJ = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))

v4l2info_CFLAGS = $(EXTRA_CFLAGS) -I$(DESTDIR)/include -pthread
v4l2info_LDFLAGS = $(EXTRA_LDFLAGS) -L$(DESTDIR)/lib
v4l2info_LDFLAGS += -Wl,-Bstatic -lm -Wl,-Bdynamic

bin/v4l2info: $(v4l2info_OBJ)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(v4l2info_OBJ) $(v4l2info_LDFLAGS)

$(v4l2info_OBJ): %.o : %.c
	$(CC) -c -o $@ $(v4l2info_CFLAGS) $<
	$(CC) -E $(call DEPFLAGS,$@) $(v4l2info_CFLAGS) $<
-include $(addsuffix $(DEP),$(v4l2info_OBJ))

install: bin/v4l2info
	$(MKDIR) $(DESTDIR)/bin
	$(INSTALL_STRIP) bin/v4l2info $(DESTDIR)/bin/

clean distclean:
	$(RM) bin $(v4l2info_OBJ) $(addsuffix $(DEP),$(v4l2info_OBJ))

.PHONY: install distclean clean
