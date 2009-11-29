
include ../support/Makefile.inc
all: fpu-nocache
common = ../support/except.o ../support/libsupport.a

fpu-nocache: fpu.o ../support/reset-nocache.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32 $(common)
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


%.o: %.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_LIB_OPTS) -mhard-mul -mhard-float -O0 $? -c -o $@

