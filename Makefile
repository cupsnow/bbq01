# $Id$
BUILDER ?= $(abspath .)/.builder
include $(BUILDER)/proj.mk

export TOOLCHAIN := $(PROJDIR)/tool/toolchain
export CROSS_COMPILE := arm-none-linux-gnueabi-
export PATH := $(PROJDIR)/tool/bin:$(TOOLCHAIN)/bin:$(PATH)

#------------------------------------
#------------------------------------
all : ;

test :
	@echo "HOST is `$(CC) -dumpmachine`"

#------------------------------------
# bootloader
#------------------------------------
include u-boot.mk

#------------------------------------
# kernel
#------------------------------------
include linux.mk

#------------------------------------
#------------------------------------
distclean :


clean :

#------------------------------------
#------------------------------------
.PHONY : 
