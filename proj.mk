#------------------------------------
# PROJDIR = $(abspath ..)
# PROJDIR = $(abspath $(call my-dir)/..)
# 
# ADB_PATH = $(shell bash -c "type -P adb")
# ifneq ("$(ADB_PATH)","")
# SDK_PATH = $(abspath $(dir $(ADB_PATH))..)
# else
# SDK_PATH = /home/joelai/07_sw/android-sdk
# endif
# 
# NDK_BUILD_PATH = $(shell bash -c "type -P ndk-build")
# ifneq ("$(NDK_BUILD_PATH)","")
# NDK_PATH = $(abspath $(dir $(NDK_BUILD_PATH)))
# else
# NDK_PATH = /home/joelai/07_sw/android-ndk
# endif
# 
# ANDPROJ_TARGET = android-8
#
# CROSS_COMPILE_GCC = $(lastword $(wildcard $(NDK_PATH)/*/*/*/linux-x86_64/bin/arm-linux-*-gcc))
# CROSS_COMPILE_PATH = $(abspath $(dir $(CROSS_COMPILE_GCC))..)
# CROSS_COMPILE = $(patsubst %gcc,%,$(notdir $(CROSS_COMPILE_GCC)))
# SYSROOT = $(NDK_PATH)/platforms/$(ANDPROJ_TARGET)/arch-arm
# 
# include $(PROJDIR:%=%/)/jni/proj.mk
# 
# EXTRA_PATH = $(NDK_PATH) $(CROSS_COMPILE_PATH)/bin
# export PATH := $(subst $(SPACE),:,$(EXTRA_PATH) $(PATH))
# 
# PLATFORM = ANDROID
# PLATFORM_CFLAGS = -isysroot $(SYSROOT) #-mfloat-abi=softfp -mfpu=neon
# PLATFORM_LDFLAGS = --sysroot $(SYSROOT)
# 
# $(info Makefile *** PATH: $(PATH))
#
PROJDIR ?= $(abspath .)
PWD = $(abspath .)
DESTDIR ?= $(PROJDIR)/obj

EMPTY =# empty
SPACE = $(EMPTY) $(EMPTY)

#------------------------------------
#
CC = $(CROSS_COMPILE)gcc
C++ = $(CROSS_COMPILE)g++
LD = $(CROSS_COMPILE)ld
AS = $(CROSS_COMPILE)as
AR = $(CROSS_COMPILE)ar
RANLIB = $(CROSS_COMPILE)ranlib
STRIP = $(CROSS_COMPILE)strip
INSTALL = install -D
INSTALL_STRIP = install -D -s --strip-program=$(STRIP)
RM = rm -rf
MKDIR = mkdir -p
CP = cp -R
RSYNC = rsync -rlv --progress -f "- .svn"

DEP = $(1).d
DEPFLAGS = -MM -MF $(call DEP,$(1)) -MT $(1)
TOKEN = $(word $(1),$(subst _, ,$(2)))

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
# $(eval $(call ANDPROJ_PREBUILT_STATIC,<name>,<lib path>,<header path>))
#
#define ANDPROJ_PREBUILT_STATIC
#LOCAL_PATH := $$(ANDPROJ_LOCAL_PATH)
#include $$(CLEAR_VARS)
#LOCAL_MODULE := $(1)
#LOCAL_SRC_FILES := $(2)
#LOCAL_EXPORT_C_INCLUDES := $(3)
#include $$(PREBUILT_STATIC_LIBRARY)
#endef
#
#define ANDPROJ_PREBUILT_SHARED
#LOCAL_PATH := $$(ANDPROJ_LOCAL_PATH)
#include $$(CLEAR_VARS)
#LOCAL_MODULE := $(1)
#LOCAL_SRC_FILES := $(2)
#LOCAL_EXPORT_C_INCLUDES := $(3)
#include $$(PREBUILT_SHARED_LIBRARY)
#endef

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
#	      $(RSYNC) -d $$j $(DESTDIR)/; \
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
#else
#obj-m := hx711.o
#
#endif

#------------------------------------
#
$(info proj.mk *** MAKELEVEL: $(MAKELEVEL))
# $(info proj.mk *** PROJDIR: $(PROJDIR))
# $(info proj.mk *** SYSROOT: $(SYSROOT))
$(info proj.mk *** PWD: $(PWD))
$(info proj.mk *** MAKECMDGOALS: $(MAKECMDGOALS))
# $(info proj.mk *** .VARIABLES: $(.VARIABLES))
# $(info proj.mk *** .INCLUDE_DIRS: $(.INCLUDE_DIRS))
