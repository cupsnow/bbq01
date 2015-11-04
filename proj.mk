#------------------------------------
# PROJDIR = $(abspath .)
# include $(PROJDIR)/proj.mk
# 
# CROSS_COMPILE_GCC = $(lastword $(wildcard $(PROJDIR)/tool/**/bin/*gcc))
# CROSS_COMPILE_PATH = $(abspath $(dir $(CROSS_COMPILE_GCC))..)
# CROSS_COMPILE = $(patsubst %gcc,%,$(notdir $(CROSS_COMPILE_GCC)))
# 
# EXTRA_PATH = $(PROJDIR)/tool/bin $(CROSS_COMPILE_PATH)/bin
# 
# export PATH := $(subst $(SPACE),:,$(EXTRA_PATH) $(PATH))
# 
# $(info Makefile *** PATH=$(PATH))
#
PROJDIR ?= $(abspath .)
PWD = $(abspath .)
DESTDIR ?= $(PROJDIR)/obj

EMPTY =# empty
SPACE = $(EMPTY) $(EMPTY)
DEP = $(1).d

#------------------------------------
#
CC = $(CROSS_COMPILE)gcc
C++ = $(CROSS_COMPILE)g++
LD = $(CROSS_COMPILE)ld
AS = $(CROSS_COMPILE)as
AR = $(CROSS_COMPILE)ar
STRIP = $(CROSS_COMPILE)strip
INSTALL = install -D
INSTALL_STRIP = install -D -s --strip-program=$(STRIP)
RM = rm -rf
MKDIR = mkdir -p
CP = cp -R

#------------------------------------
#
MAKEPARAM = PROJDIR="$(PROJDIR)" DESTDIR="$(DESTDIR)" 
DEPFLAGS = -MM -MF $(call DEP,$(1)) -MT $(1)
TOKEN = $(word $(1),$(subst _, ,$(2)))
#CFLAGS = -I$(PWD)/include -I$(DESTDIR)/include
#LDFLAGS = -I$(PWD)/lib -I$(DESTDIR)/lib
#ARFLAGS = rcs

#------------------------------------
# "$(COLOR_RED)red$(COLOR)"
#
_COLOR = \033[$(1)m
COLOR = $(call _COLOR,0)
COLOR_RED = $(call _COLOR,31)
COLOR_GREEN = $(call _COLOR,32)
COLOR_BLUE = $(call _COLOR,34)
COLOR_CYAN = $(call _COLOR,36)
COLOR_YELLOW = $(call _COLOR,33)
COLOR_MAGENTA = $(call _COLOR,35)
COLOR_GRAY = $(call _COLOR,37)

#------------------------------------
#
#$(ex2_OBJS): %.o : %.c
#	$(CC) -c -o $@ $(CFLAGS) $<
#	$(CC) -E $(call DEPFLAGS,$@) $(CFLAGS) $<
#
#-include $(addsuffix $(DEP),$(ex2_OBJS))

#------------------------------------
#
#dist_cp:
#	@[ -d $(DESTDIR) ] || $(MKDIR) $(DESTDIR)
#	@for i in $(SRCFILE); do \
#	  for j in $(SRCDIR)/$$i; do \
#	    if [ -x $$j ] && [ ! -h $$j ] && [ ! -d $$j ]; then \
#	      echo "$(COLOR_GREEN)installing(strip) $$j$(COLOR)"; \
#	      $(INSTALL_STRIP) $$j $(DESTDIR); \
#	    elif [ -e $$j ]; then \
#	      echo "$(COLOR_GREEN)installing(cp) $$j$(COLOR)"; \
#	      $(CP) -d $$j $(DESTDIR)/; \
#	    else \
#	      echo "$(COLOR_RED)missing $$j$(COLOR)"; \
#	    fi; \
#	  done; \
#	done

#------------------------------------
#
#ifeq ("$(KERNELRELEASE)","")
#PWD := $(abspath .)
#KDIR ?= $(lastword $(wildcard $(DESTDIR)/lib/modules/**/build))
#
#all: modules
#
#%:
#	$(MAKE) -C $(KDIR) M=$(PWD) $@
#
##------------------------------------
##
#else
#obj-m := hx711.o
#
#endif

#------------------------------------
#
$(info proj.mk *** MAKELEVEL: $(MAKELEVEL))
# $(info proj.mk *** PROJDIR: $(PROJDIR))
$(info proj.mk *** PWD: $(PWD))
$(info proj.mk *** MAKECMDGOALS: $(MAKECMDGOALS))
# $(info proj.mk *** .VARIABLES: $(.VARIABLES))
# $(info proj.mk *** .INCLUDE_DIRS: $(.INCLUDE_DIRS))
