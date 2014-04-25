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
#

#------------------------------------
#
PWD := $(abspath .)
PROJDIR ?= $(PWD)
BUILDDIR ?= $(PROJDIR)/build
DESTDIR ?= $(BUILDDIR)/buildtime
ROOTFS ?= $(BUILDDIR)/rootfs
RELEASE ?= $(PROJDIR)/release

#------------------------------------
#
CC = $(CROSS_COMPILE)gcc
C++ = $(CROSS_COMPILE)g++
LD = $(CROSS_COMPILE)ld
AR = $(CROSS_COMPILE)ar

CP = cp -dpR
MKDIR = mkdir -p

CFLAGS =
LDFLAGS =
ARFLAGS = rcs


#------------------------------------
# $(call OVERWRITE,$(linux_DIR),config/linux,.svn)
#
OVERWRITE = rsync -rl --progress $(if $(3),$(foreach ex,$(3),-f "- $(ex)")) $(addsuffix /.[!.]*,$(2)) $(addsuffix /*,$(2)) $(1)

#------------------------------------
#
$(info *** PWD: $(PWD))
$(info *** MAKECMDGOALS: $(MAKECMDGOALS))
$(info ***)
