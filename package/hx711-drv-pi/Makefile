#------------------------------------
#
ifeq ("$(KERNELRELEASE)","")
PWD := $(abspath .)
KDIR ?= $(lastword $(wildcard $(DESTDIR)/lib/modules/**/build))

all: modules

distclean: clean;

%:
	$(MAKE) -C $(KDIR) M=$(PWD) $@

#------------------------------------
#
else
obj-m := hx711.o

endif
