include ../support/Makefile.inc

cases = cbasic-nocache-O0 cbasic-nocache-O2 cbasic-ic-O0 cbasic-ic-O2 cbasic-dc-O0 cbasic-dc-O2 cbasic-icdc-O0 cbasic-icdc-O2

common = ../support/except.o ../support/libsupport.a 


all: $(cases)

cbasic-nocache-O0: cbasic-O0.o ../support/reset-nocache.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -T ../support/orp.ld $? -o $@.or32 $(GCC_LIB_OPTS) 
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


cbasic-nocache-O2: cbasic-O2.o ../support/reset-nocache.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32 $(common)
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


cbasic-ic-O0: cbasic-O0.o ../support/reset-ic.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32  $(common)
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


cbasic-ic-O2: cbasic-O2.o ../support/reset-ic.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


cbasic-dc-O0: cbasic-O0.o ../support/reset-dc.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


cbasic-dc-O2: cbasic-O2.o ../support/reset-dc.o  $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


cbasic-icdc-O0: cbasic-O0.o ../support/reset-icdc.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


cbasic-icdc-O2: cbasic-O2.o ../support/reset-icdc.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


cbasic-O0.o: cbasic.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O0 $? -c -o $@

cbasic-O2.o: cbasic.c
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -O2 $? -c -o $@

