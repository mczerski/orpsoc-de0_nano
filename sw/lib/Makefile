SW_ROOT=..
include $(SW_ROOT)/Makefile.inc

LIBORPSOC_SRC= lib-utils.c printf.c

%/$(DRIVER_OBJ):
	$(Q)$(MAKE) -C $* $(DRIVER_OBJ)

LIBORPSOC_OBJS=$(LIBORPSOC_SRC:%.c=%.o)

liborpsoc.a: $(LIBORPSOC_OBJS) $(SW_DRIVER_PATHS:%=%/$(DRIVER_OBJ))
	$(Q)$(OR32_AR) cru $@ $^
	$(Q)$(OR32_RANLIB) $@

clean:
	$(Q)rm -f *.a *.o
