include ../Makefile.inc

all: $(DESIGN_NAME)_support.a

SUPPORT_MODULES=exceptions int or32-utils \
	 	uart printf or1200-mmu simple-spi

SUPPORT_OBJS=$(shell for mod in $(SUPPORT_MODULES); do echo "$$mod".o; done)

$(DESIGN_NAME)_support.a: $(SUPPORT_OBJS)
	$(Q)$(OR32_AR) cru $@ $^
	$(Q)$(OR32_RANLIB) $@

clean:
	$(Q)rm -f *.a *.o
