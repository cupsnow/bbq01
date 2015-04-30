#------------------------------------
#
PWD = $(abspath .)

#override CROSS_COMPILE_PATH := $(HOME)/02_dev/cam/ocarina/tool/buildroot-gcc342
#override CROSS_COMPILE := $(patsubst %gcc,%,$(notdir $(lastword $(wildcard $(CROSS_COMPILE_PATH)/bin/*gcc))))
#export PATH := $(CROSS_COMPILE_PATH)/bin:$(PATH)
#EXTRA_CFLAGS = -I$(HOME)/02_dev/cam/ocarina/runtime/include -g
#EXTRA_LDFLAGS = -L$(HOME)/02_dev/cam/ocarina/runtime/lib

$(info gpioctl Makefile *** CROSS_COMPILE_PATH=$(CROSS_COMPILE_PATH))
$(info gpioctl Makefile *** CROSS_COMPILE=$(CROSS_COMPILE))
$(info gpioctl Makefile *** PATH=$(PATH))

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
gpioctl_OBJ = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))

gpioctl_CFLAGS = $(EXTRA_CFLAGS) -I$(DESTDIR)/include -pthread
gpioctl_LDFLAGS = $(EXTRA_LDFLAGS) -L$(DESTDIR)/lib
gpioctl_LDFLAGS += -Wl,-Bstatic -lm -Wl,-Bdynamic

bin/gpioctl: $(gpioctl_OBJ)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(gpioctl_OBJ) $(gpioctl_LDFLAGS)

$(gpioctl_OBJ): %.o : %.c
	$(CC) -c -o $@ $(gpioctl_CFLAGS) $<
	$(CC) -E $(call DEPFLAGS,$@) $(gpioctl_CFLAGS) $<
-include $(addsuffix $(DEP),$(gpioctl_OBJ))

install: bin/gpioctl
	$(MKDIR) $(DESTDIR)$(PREFIX)/bin
	$(INSTALL_STRIP) bin/gpioctl $(DESTDIR)$(PREFIX)/bin/

clean distclean:
	$(RM) bin $(gpioctl_OBJ) $(addsuffix $(DEP),$(gpioctl_OBJ))

.PHONY: install distclean clean
