#------------------------------------
# PROJDIR = $(abspath .)
# include $(PROJDIR)/.builder/proj.mk
#
# CROSS_COMPILE_PATH1 = $(PROJDIR)/tool/**/bin/arm-*linux-*gcc
# CROSS_COMPILE_PATH2 = $(lastword $(wildcard $(CROSS_COMPILE_PATH1)))
# CROSS_COMPILE_PATH = $(abspath $(dir $(CROSS_COMPILE_PATH2))..)
# CROSS_COMPILE = $(patsubst %gcc,%,$(notdir $(CROSS_COMPILE_PATH2)))
#
# PATH1 = $(PROJDIR)/tool/bin $(CROSS_COMPILE_PATH)/bin 
#
# export PATH := $(subst $(SPACE),:,$(PATH1) $(PATH))
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
INSTALL = install -D
RM = rm -rf
MKDIR = mkdir -p
CP = cp -R

#------------------------------------
#
MAKEPARAM = PROJDIR="$(PROJDIR)" DESTDIR="$(DESTDIR)" 
DEPFLAGS = -MM -MF $(call DEP,$(1)) -MT $(1)
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
$(info proj.mk *** MAKELEVEL=$(MAKELEVEL))
$(info proj.mk *** PWD=$(PWD))
# $(info proj.mk *** .VARIABLES=$(.VARIABLES))
# $(info proj.mk *** .INCLUDE_DIRS=$(.INCLUDE_DIRS))
$(info proj.mk *** MAKECMDGOALS=$(MAKECMDGOALS))
