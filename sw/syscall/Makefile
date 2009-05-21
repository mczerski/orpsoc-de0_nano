include ../support/Makefile.inc
all: syscall-nocache syscall-icdc
## We define a special syscall vector for this test - no need to include
## the support library's except vectors
common = ../support/libsupport.a

syscall-nocache: syscall.o ../support/reset-nocache.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32 $(common)
	$(OR32_TOOL_PREFIX)-objcopy -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


syscall-icdc: syscall.o ../support/reset-icdc.o
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) $(GCC_LIB_OPTS) -T ../support/orp.ld $? -o $@.or32 $(common)
	$(OR32_TOOL_PREFIX)-objcopy -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


syscall.o: syscall.S
	$(OR32_TOOL_PREFIX)-gcc -O0 $(GCC_OPT) $? -I../support -c -o $@

