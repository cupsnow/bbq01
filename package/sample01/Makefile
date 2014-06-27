BUILDERDIR := $(abspath .)/.builder
include $(BUILDERDIR)/proj.mk

SEARCH_COMPILE ?= $(firstword $(wildcard $(PROJDIR)/tool/toolchain/bin/*gcc))
CROSS_COMPILE ?= $(patsubst %gcc,%,$(notdir $(SEARCH_COMPILE)))
TOOLCHAIN ?= $(patsubst %/bin/$(CROSS_COMPILE)gcc,%,$(SEARCH_COMPILE))

NAME = sample01
WITH_FB = 1
WITH_EV = 1
# WITH_DFB = 1

SRC_C = src/main.c
SRC_CPP = 
CFLAGS := $(CFLAGS)
LDFLAGS := $(LDFLAGS)

ifneq ("$(WITH_FB)","")
SRC_C += src/fb.c
CFLAGS += -DWITH_FB=$(WITH_FB)
endif

ifneq ("$(WITH_EV)","")
SRC_C += src/ev.c
CFLAGS += -DWITH_EV=$(WITH_EV)
endif

ifneq ("$(WITH_DFB)","")
SRC_C += src/dfb.c
CFLAGS += -DWITH_DFB=$(WITH_DFB) $(shell $(DESTDIR)/bin/directfb-config --cflags --prefix=$(DESTDIR))
LDFLAGS += $(shell $(DESTDIR)/bin/directfb-config --libs --prefix=$(DESTDIR))
endif

OBJ_C = $(patsubst %.c,%.o,$(wildcard $(SRC_C)))
OBJ_CPP = $(patsubst %.cpp,%.o,$(wildcard $(SRC_CPP)))
OBJ = $(OBJ_C) $(OBJ_CPP)

all: bin/$(NAME)

bin/$(NAME): $(OBJ)
	$(MKDIR) bin
	$(if $(OBJ_CPP),$(C++),$(CC)) -o $@ $(LDFLAGS) $(OBJ)

$(OBJ_C): %.o : %.c
	$(CC) -c -o $@ $(CFLAGS) $<
	$(CC) -E $(CFLAGS) $(call DEPFLAGS,$@) $<

-include $(addsuffix $(DEPSUFFIX),$(OBJ_C))

$(OBJ_CPP): %.o : %.cpp
	$(C++) -c -o $@ $(CFLAGS) $<
	$(CC) -E $(CFLAGS) $(DEPFLAGS) $<

-include $(addsuffix $(DEPSUFFIX),$(OBJ_C))

install: all
	$(INSTALL) -t $(DESTDIR)/bin bin/$(NAME)  

distclean clean:
	$(RM) $(OBJ) bin

.PHONY: install

