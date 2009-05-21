include ../support/Makefile.inc
all: mmu-nocache mmu-icdc

mmu-nocache: mmu_asm.o mmu.o except.o
	$(OR32_TOOL_PREFIX)-gcc -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div -T../support/orp.ld -o $@.or32 ../support/reset-nocache.o except.o mmu_asm.o mmu.o ../support/libsupport.a 
	$(OR32_TOOL_PREFIX)-objcopy -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


mmu-icdc: mmu_asm.o mmu.o except.o
	$(OR32_TOOL_PREFIX)-gcc -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div -T../support/orp.ld -o $@.or32 ../support/reset-icdc.o except.o mmu_asm.o mmu.o ../support/libsupport.a 
	$(OR32_TOOL_PREFIX)-objcopy -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


mmu.o: mmu.c Makefile
	$(OR32_TOOL_PREFIX)-gcc -O2 -I../support -c -o mmu.o mmu.c -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div

mmu_asm.o: mmu_asm.S Makefile
	$(OR32_TOOL_PREFIX)-gcc -I../support -c -o mmu_asm.o mmu_asm.S -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div

except.o: except.S Makefile
	$(OR32_TOOL_PREFIX)-gcc -I../support -c -o except.o except.S  -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div

