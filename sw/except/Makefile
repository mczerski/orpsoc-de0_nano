include ../support/Makefile.inc
all: except-nocache except-icdc

except-nocache: except_test_s.o except_test.o
	$(OR32_TOOL_PREFIX)-gcc -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div -T../support/orp.ld -o $@.or32 ../support/reset-nocache.o except_test_s.o except_test.o ../support/libsupport.a
	$(OR32_TOOL_PREFIX)-objcopy -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


except-icdc: except_test_s.o except_test.o
	$(OR32_TOOL_PREFIX)-gcc -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div -T../support/orp.ld -o $@.or32 ../support/reset-icdc.o except_test_s.o except_test.o ../support/libsupport.a
	$(OR32_TOOL_PREFIX)-objcopy -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


except_test.o: except_test.c Makefile
	$(OR32_TOOL_PREFIX)-gcc -I../support -g -O2 -c -o except_test.o except_test.c -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div

except_test_s.o: except_test_s.S Makefile
	$(OR32_TOOL_PREFIX)-gcc -I../support -g -c -o except_test_s.o except_test_s.S -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div

except.o: except.S Makefile
	$(OR32_TOOL_PREFIX)-gcc -I../support -g -c -o except.o except.S  -Wall -g $(GCC_OPT) $(GCC_LIB_OPTS) -mhard-div
