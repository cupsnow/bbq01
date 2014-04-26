# $Id$
# BUILDERDIR := $(abspath .)/.builder
# include $(BUILDERDIR)/proj.mk
# 
# SEARCH_COMPILE ?= $(firstword $(wildcard $(PROJDIR)/tool/toolchain/bin/*gcc))
# CROSS_COMPILE ?= $(patsubst %gcc,%,$(notdir $(SEARCH_COMPILE)))
# TOOLCHAIN ?= $(patsubst %/bin/$(CROSS_COMPILE)gcc,%,$(SEARCH_COMPILE))
# 
# MYPATH = $(PROJDIR)/tool/bin:$(TOOLCHAIN)/bin
# 
# export PATH := $(MYPATH)$(PATH:%=:)$(PATH)

#------------------------------------
#
PWD := $(abspath .)
PROJDIR ?= $(PWD)

# temprary output files location
BUILDDIR ?= $(PROJDIR)/build

DESTDIR ?= $(BUILDDIR)/buildtime

# runtime rootfs
ROOTFS ?= $(BUILDDIR)/rootfs

# binary/image/managed data for release
RELEASE ?= $(PROJDIR)/release

#------------------------------------
#
CC = $(CROSS_COMPILE)gcc
C++ = $(CROSS_COMPILE)g++
LD = $(CROSS_COMPILE)ld
AR = $(CROSS_COMPILE)ar
OBJCOPY = $(CROSS_COMPILE)objcopy

INSTALL = install -D
CP = cp -dpR
MKDIR = mkdir -p
RM = rm -rf

#------------------------------------
# @echo -e "color: $(COLOR_RED)red$(COLOR)"
#
_COLOR = \033[$(1)m
COLOR = $(call _COLOR,0)
COLOR_RED = $(call _COLOR,31)
COLOR_GREEN = $(call _COLOR,32)
COLOR_BROWN = $(call _COLOR,33)
COLOR_BLUE = $(call _COLOR,34)
COLOR_MAGENTA = $(call _COLOR,35)
COLOR_CYAN = $(call _COLOR,36)
COLOR_LIGHTGRAY = $(call _COLOR,37)

#------------------------------------
#
CFLAGS = -I$(PWD)/include -I$(PROJDIR)/include -I$(DESTDIR)/include
LDFLAGS = -L$(PWD)/lib -L$(DESTDIR)/lib
ARFLAGS = rcs
DEPSUFFIX = .d
DEPFLAGS = -MM -MF $@$(DEPSUFFIX) -MT $1

#------------------------------------
# provide enough information for callee to find builder
#
MAKEPARAM = BUILDERDIR="$(BUILDERDIR)" PROJDIR="$(PROJDIR)"
MAKEPARAM += DESTDIR="$(DESTDIR)" 

#------------------------------------
# $(info CONCAT,.,1, -> $(call CONCAT,.,1,)) 
# $(info CONCAT,.,1,2,3 -> $(call CONCAT,.,1,2,3)) 
#
CONCAT = $(if $(2),$(if $(3),$(2)$(1)$(call CONCAT,$(1),$(3),$(4),$(5),$(6),$(7),$(8)),$(2)))

#------------------------------------
#
SONAME = $(call CONCAT,.,lib$(or $($(1)_NAME),$(1)).so,$($(1)_MAJOR))
LIBNAME = $(call CONCAT,.,lib$(or $($(1)_NAME),$(1)).so,$($(1)_MAJOR),$($(1)_MINOR),$($(1)_RELEASE))

#------------------------------------
# filter only existed wildcard
FILTER_EXIST = $(foreach in,$(1),$(if $(wildcard $(in)),$(in)))

#------------------------------------
# $(call OVERWRITE,$(linux_DIR),config/linux,.svn)
#
OVERWRITE = rsync -rl --progress
OVERWRITE += $(if $(3),$(foreach ex,$(3),-f "- $(ex)"))
OVERWRITE += $(call FILTER_EXIST,$(addsuffix /.[!.]*,$(2)) $(addsuffix /*,$(2)))
OVERWRITE += $(1)

#------------------------------------
# $(info *** to day passed since epoch: $(EPOCHDAY))
#
EPOCHDAY = $(shell echo $$(( `date +%s` / 86400)))

#------------------------------------
#
HOST = $(shell PATH=$(PATH) && $(or $(1),$(CC)) -dumpmachine)

#------------------------------------
#
OBJFILE = $(patsubst $(1),$(2),$(wildcard $(3)))

define OBJ_C_CPP
$(1)_OBJ_C = $$(call OBJFILE,%.c,%.o,$(2)/*.c)
$(1)_OBJ_CPP = $$(call OBJFILE,%.cpp,%.o,$(2)/*.cpp)
$(1)_OBJ = $$($(1)_OBJ_C) $$($(1)_OBJ_CPP)
endef # OBJFROM_C_CPP

#------------------------------------
#
$(info *** PWD: $(PWD))
$(info *** [$(MAKELEVEL)] MAKECMDGOALS: $(MAKECMDGOALS))
$(info ***)
