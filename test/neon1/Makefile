include $(PROJDIR)/proj.mk

CFLAGS = -mcpu=cortex-a7 -mfpu=neon-vfpv4 -mfloat-abi=hard \
    -I$(DESTDIR)/include
LDFLAGS = -L$(DESTDIR)/lib
TFTPROOT = /var/local/ftproot

#------------------------------------
#
all: bin/neon1

#------------------------------------
#
neon1_OBJS_C = $(patsubst %.c,%.o,$(wildcard $(PWD)/src/*.c))
neon1_OBJS = $(neon1_OBJS_C) $(neon1_OBJS_CPP)

bin/neon1: $(neon1_OBJS)
	$(MKDIR) $(dir $@)
	$(CC) -o $@ $(neon1_OBJS) $(LDFLAGS) -lmoss -pthread

neon1_install: bin/neon1
	$(MAKE) SRCFILE="neon1" \
	    SRCDIR=$(PWD)/bin DESTDIR=$(TFTPROOT) dist_cp

neon1_clean neon1_distclean:
	$(RM) bin $(neon1_OBJS) $(addsuffix $(DEP),$(neon1_OBJS))

$(neon1_OBJS_C): %.o : %.c
	$(CC) -c -o $@ $(CFLAGS) $<
	$(CC) -E $(call DEPFLAGS,$@) $(CFLAGS) $<

-include $(addsuffix $(DEP),$(neon1_OBJS))

#------------------------------------
#
dist_cp:
	@[ -d $(DESTDIR) ] || $(MKDIR) $(DESTDIR)
	@for i in $(SRCFILE); do \
	  for j in $(SRCDIR)/$$i; do \
	    if [ -x $$j ] && [ ! -h $$j ] && [ ! -d $$j ]; then \
	      echo "$(COLOR_GREEN)installing(strip) $$j$(COLOR)"; \
	      $(INSTALL_STRIP) $$j $(DESTDIR); \
	    elif [ -e $$j ]; then \
	      echo "$(COLOR_GREEN)installing(cp) $$j$(COLOR)"; \
	      $(CP) -d $$j $(DESTDIR)/; \
	    else \
	      echo "$(COLOR_RED)missing $$j$(COLOR)"; \
	    fi; \
	  done; \
	done

#------------------------------------
#
install clean distclean:
	$(MAKE) $(addsuffix _$@,neon1)

