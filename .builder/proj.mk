# $Id$
# BUILDER ?= $(abspath .)/.builder
# include $(BUILDER)/proj.mk
#
# export TOOLCHAIN := $(PROJDIR)/tool/buildroot-gcc342
# export CROSS_COMPILE := mipsel-linux-
# export PATH := $(PROJDIR)/tool/bin:$(TOOLCHAIN)/bin:$(PATH)

#------------------------------------
#------------------------------------
PWD := $(abspath .)
PROJDIR ?= $(abspath .)
BUILDDIR ?= $(PROJDIR)/build
DESTDIR ?= $(BUILDDIR)/buildtime

#------------------------------------
#------------------------------------
CC = $(CROSS_COMPILE)gcc
C++ = $(CROSS_COMPILE)g++
LD = $(CROSS_COMPILE)ld
AS = $(CROSS_COMPILE)as
DLLTOOL = $(CROSS_COMPILE)dlltool
RANLIB = $(CROSS_COMPILE)ranlib
NM = $(CROSS_COMPILE)nm
AR = $(CROSS_COMPILE)ar
OBJCOPY = $(CROSS_COMPILE)objcopy
READELF = $(CROSS_COMPILE)readelf
INSTALL = install -D

# recursive and force remove
RM = rm -rf

# also make missing parent directory
MKDIR = mkdir -p

REN = mv

# reserve symbolic link
CP = cp -dpR

# example:
#test_color :
#	@echo -e "default" \
#	  "$(COLOR_RED)red$(COLOR)" \
#	  "$(COLOR_GREEN)green$(COLOR)" \
#	  "$(COLOR_BROWN)brown$(COLOR)" \
#	  "$(COLOR_BLUE)blue$(COLOR)" \
#	  "$(COLOR_MAGENTA)magenta$(COLOR)" \
#	  "$(COLOR_CYAN)cyan$(COLOR)" \
#	  "$(COLOR_LIGHTGRAY)lightgray$(COLOR)"
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
#------------------------------------
CFLAGS = -I$(PWD) -I$(PWD)/include -I$(PROJDIR) -I$(PROJDIR)/include 
CFLAGS += -I$(DESTDIR)/include
CFLAGS += -Wall -fPIC
ifeq ("$(DEBUG)", "1")
CFLAGS += -g3
endif

LDFLAGS = -L$(PWD) -L$(PWD)/lib -L$(PROJDIR) -L$(PROJDIR)/lib 
LDFLAGS += -L$(DESTDIR)/lib
LDFLAGS += -fPIC

ARFLAGS = rcs
OBJDEPFLAGS = -MM -MF $@.d -MT $@
MAKEPARAM = PROJDIR="$(PROJDIR)" DESTDIR="$(DESTDIR)" 
MAKEPARAM += BUILDERDIR="$(BUILDERDIR)"
ifneq ("$(DEBUG)","")
MAKEPARAM += DEBUG="$(DEBUG)"
endif

#------------------------------------
# top Makefile may failed for missing 
#   $(GCC) executable path
# ./configure --host=$(call HOST,gcc)
# ./configure --host=$(call HOST)
# echo build host=$(call HOST,gcc)
#------------------------------------
HOST = $(shell PATH=$(PATH) && $(or $(1),$(CC)) -dumpmachine)

#------------------------------------
# OBJ_C = $(call OBJFROM,$(DIR)/src,.c)
# OBJ_CPP = $(call OBJFROM,$(DIR)/src,.cpp)
#------------------------------------
OBJFROM = $(patsubst %$(2),%.o,$(wildcard $(1)/*$(2)))

#------------------------------------
# $(eval $(call OBJFROM_C_CPP,name))
#------------------------------------
define OBJFROM_C_CPP
$(1)_OBJ_C = $$(call OBJFROM,$$($(1)_DIR)/src,.c)
$(1)_OBJ_CPP = $$(call OBJFROM,$$($(1)_DIR)/src,.cpp)
$(1)_OBJ = $$($(1)_OBJ_C) $$($(1)_OBJ_CPP)
endef # OBJFROM_C_CPP

#------------------------------------
# do something when file exist and other thing when missing
# ex:
#   $(info check existance: $(call IF_EXIST,tmp,exist,missing))
# tmp_found :
# 	@echo "target: $@"
#
# test : $(call IF_EXIST,tmp,tmp_found)
# 	@echo "HOST is `$(CC) -dumpmachine`"
#------------------------------------
IF_EXIST = $(if $(wildcard $(1)),$(2),$(3))

#------------------------------------
# VERSION = $(call CONCAT,.,$(MAJOR),$(MINOR),$(RELEASE)) 
#------------------------------------
CONCAT = $(if $(2),$(if $(3),$(2)$(1)$(call concat,$(1),$(3),$(4),$(5),$(6),$(7),$(8)),$(2)))

#------------------------------------
# $(call OBJDEP,name)
# $(call SONAME,name)
# $(call LIBNAME,name)
#------------------------------------
OBJDEP = $(addsuffix .d,$($(1)_OBJ))
SONAME = $(call CONCAT,.,lib$(or $($(1)_NAME),$(1)).so,$($(1)_MAJOR))
LIBNAME = $(call CONCAT,.,lib$(or $($(1)_NAME),$(1)).so,$($(1)_MAJOR),$($(1)_MINOR),$($(1)_RELEASE))

#------------------------------------
# $(eval $(call COMPILE_C,proj))
# $(eval $(call COMPILE_CPP,proj))
# $(eval $(call LINK_CPP,proj))
#------------------------------------
define COMPILE_C
$$($(1)_OBJ_C) : %.o : %.c
	$(CC) -c -o $$@ $$(or $$($(1)_CFLAGS),$$(CFLAGS)) $$<
	$(CC) $$(or $$($(1)_CFLAGS),$$(CFLAGS)) $$(OBJDEPFLAGS) $$<
-include $$(addsuffix .d,$$($(1)_OBJ_C))
endef # COMPILE_C

define COMPILE_CPP
$$($(1)_OBJ_CPP) : %.o : %.cpp
	$(C++) -c -o $$@ $$(or $$($(1)_CFLAGS),$$(CFLAGS)) $$<
	$(C++) $$(or $$($(1)_CFLAGS),$$(CFLAGS)) $$(OBJDEPFLAGS) $$<
-include $$(addsuffix .d,$$($(1)_OBJ_CPP))
endef # COMPILE_CPP

define LINK_C
$$($(1)_EXE) $(1) : $$($(1)_OBJ)
	-$(MKDIR) $$($(1)_DIR)/bin
	$(CC) -o $$($(1)_DIR)/bin/$$(or $$($(1)_EXE),$(1)) $$($(1)_OBJ_C) \
	  $$(or $$($(1)_LDFLAGS),$$(LDFLAGS))
endef

define LINK_CPP
$$($(1)_EXE) $(1) : $$($(1)_OBJ)
	-$(MKDIR) $$($(1)_DIR)/bin
	$(C++) -o $$($(1)_DIR)/bin/$$(or $$($(1)_EXE),$(1)) $$($(1)_OBJ) \
	  $$(or $$($(1)_LDFLAGS),$$(LDFLAGS))
endef


define SO_C
lib$(1)_so $$(or $$($(1)_SO),$(call SONAME,$(1))) : $$($(1)_OBJ)
	-$(MKDIR) $$($(1)_DIR)/lib
	$(CC) -o $$($(1)_DIR)/lib/$$(or $$($(1)_SO),$(call LIBNAME,$(1))) \
	  -shared -Wl,-soname,$(call SONAME,$(1)) $$($(1)_OBJ) \
	  $$(or $$($(1)_LDFLAGS),$$(LDFLAGS))
endef

define SO_CPP
lib$(1)_so $$(or $$($(1)_SO),$(call SONAME,$(1))) : $$($(1)_OBJ)
	-$(MKDIR) $$($(1)_DIR)/lib
	$(C++) -o $$($(1)_DIR)/lib/$$(or $$($(1)_SO),$(call LIBNAME,$(1))) \
	  -shared -Wl,-soname,$(call SONAME,$(1)) $$($(1)_OBJ) \
	  $$(or $$($(1)_LDFLAGS),$$(LDFLAGS))
endef

define LIB_A
lib$(1)_a $$(or $$($(1)_A),lib$(1).a) : $$($(1)_OBJ)
	-$(MKDIR) $$($(1)_DIR)/lib
	$(AR) $$(or $$($(1)_ARFLAGS),$(ARFLAGS),rcs) $$($(1)_DIR)/lib/$$(or $$($(1)_A),lib$(1).a) $$($(1)_OBJ)
endef

#------------------------------------
# name_DIR = $(PWD)/package/name
# name_MAKEENV = "CONCURRENCY_LEVEL=2 PP=1"
# name_MAKEPARAM = $(MAKEPARAM) C=2"
# $(eval $(call PACKAGE1,name))
# name name_install : $(name_DIR)/Makefile
# all : name_install
#------------------------------------
define PACKAGE1
$(1) $(1)_% :
	$$($(1)_MAKEENV) $(MAKE) $$(or $$($(1)_MAKEPARAM),$$(MAKEPARAM)) \
	  -C $$(or $$($(1)_DIR),$(1)) $$(patsubst $(1),,$$(@:$(1)_%=%))
endef # PACKAGE1

#------------------------------------
# ex: $(call OVERWRITE1,$(linux_DIR),config/linux,.svn)
#------------------------------------
define OVERWRITE1
rsync -rlv --progress $(and $(3),$(foreach it,$(3),-f "- $(it)")) $(addsuffix /.[!.]*,$(2)) $(addsuffix /*,$(2)) $(1)
endef

#------------------------------------
# only the specified target may pass if Makefile is missing 
# ex: $(eval $(call DISTCLEAN1,name,distclean))
#------------------------------------
define DISTCLEAN1
$(1)_do_$(or $(2),distclean) :
	$$($(1)_MAKEENV) $(MAKE) $$(or $$($(1)_MAKEPARAM),$$(MAKEPARAM)) \
	  -C $$(or $$($(1)_DIR),$(1)) $$(@:$(1)_do_%=%)

$(1)_$(or $(2),distclean) : $$(if $$(wildcard $$(or $$($(1)_DIR),$(1))/Makefile),$(1)_do_$(or $(2),distclean)) ;

endef

#------------------------------------
# only the specified TARGETS may pass when the included file is missing
# ex: $(eval $(call INCLUDE_EX,$(KERNEL_DIR)/.config,clean distclean))
#------------------------------------
define INCLUDE_EX
include $$(or $$(wildcard $(1)),$$(and $$(filter-out $(2),$$(MAKECMDGOALS)),$(1)))
endef # INCLUDE_EX

#------------------------------------
#------------------------------------
$(info ------------------------------>)
$(info MAKELEVEL=$(MAKELEVEL))
# $(info CURDIR=$(CURDIR))
$(info PWD=$(PWD))
$(info HOST=$(call HOST))
$(info .INCLUDE_DIRS=$(.INCLUDE_DIRS))
$(info MAKECMDGOALS=$(MAKECMDGOALS))
$(info <------------------------------)
