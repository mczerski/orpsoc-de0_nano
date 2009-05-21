
include ../support/Makefile.inc
all: basic-nocache basic-icdc basic-ic basic-dc
common = ../support/except.o ../support/libsupport.a

basic-nocache: basic.o ../support/reset-nocache.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32 $(common)
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem

basic-icdc: basic.o ../support/reset-icdc.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32 $(common)
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem

basic-ic: basic.o ../support/reset-ic.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32 $(common)
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem

basic-dc: basic.o ../support/reset-dc.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32 $(common)
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem

basic.o: basic.S
	$(OR32_TOOL_PREFIX)-gcc $(GCC_LIB_OPTS) -mhard-mul -O0 $? -c -o $@

