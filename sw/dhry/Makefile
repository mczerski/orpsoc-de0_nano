include ../support/Makefile.inc
#ADDED BY ME
cases = dhry-nocache-O0 dhry-nocache-O2 dhry-icdc-O2
#common = ../support/libsupport.a
common =  ../support/except.o ../support/libsupport.a

NUM_RUNS ?= 10
GCC_OPT += -g
all: $(cases)

dhry-nocache-O0: dhry-O0.o ../support/reset-nocache.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32
	$(OR32_TOOL_PREFIX)-objcopy -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


dhry-nocache-O2: dhry-O2.o ../support/reset-nocache.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32
	$(OR32_TOOL_PREFIX)-objcopy -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


dhry-icdc-O2: dhry-O2.o ../support/reset-icdc.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32
	$(OR32_TOOL_PREFIX)-objcopy -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


dhry-O0.o: dhry.c
	$(OR32_TOOL_PREFIX)-gcc -DNUM_RUNS=$(NUM_RUNS) -I../support -O0 $(GCC_OPT) $? -mhard-div -c -o $@

dhry-O2.o: dhry.c
	$(OR32_TOOL_PREFIX)-gcc -DNUM_RUNS=$(NUM_RUNS) -I../support -O2 $(GCC_OPT) $? -mhard-div -c -o $@
