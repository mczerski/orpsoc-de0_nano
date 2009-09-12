include Makefile.inc

all: libsupport.a reset-nocache.o reset-ic.o reset-dc.o reset-icdc.o

libsupport.a: support.o int.o except.o uart.o vfnprintf.o time.o
	$(OR32_TOOL_PREFIX)-ar cru libsupport.a $?
	$(OR32_TOOL_PREFIX)-ranlib libsupport.a

# A generic rule for c
%.o: %.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O2 -c -o $@ $?
# A generic rule for assembly files
%.o: %.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O2 -c -o $@ $?
# Rules for each specific reset type we want
reset-nocache.o: reset.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O2 -c -DIC=0 -DDC=0 -o $@ $?

reset-dc.o: reset.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O2 -c -DIC=0 -DDC=1 -o $@ $?

reset-ic.o: reset.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O2 -c -DIC=1 -DDC=0 -o $@ $?

reset-icdc.o: reset.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O2 -c -DIC=1 -DDC=1 -o $@ $?

