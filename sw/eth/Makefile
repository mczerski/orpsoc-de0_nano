include ../support/Makefile.inc


# We use our own except here, containing interrupt handler vector
common = except.o ../support/libsupport.a 


all: eth-basic eth-int

eth-basic: eth-basic.o ../support/reset-nocache.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -T ../support/orp.ld $? -o $@.or32 $(GCC_LIB_OPTS) 
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem

eth-int: eth-int.o ../support/reset-nocache.o $(common)
	$(OR32_TOOL_PREFIX)-gcc $(GCC_OPT) -T ../support/orp.ld $? -o $@.or32 $(GCC_LIB_OPTS) 
	$(OR32_TOOL_PREFIX)-objcopy  -O binary $@.or32 $@.bin
	../utils/bin2hex $@.bin 1 -size_word > $@$(FLASH_MEM_HEX_FILE_SUFFIX).hex
	../utils/bin2vmem $@.bin > $@.vmem


%.o: %.c
	$(OR32_TOOL_PREFIX)-gcc -DRTLSIM -I ../support $(GCC_OPT) -O2 -g -c -Wall $< -o $@

%.o: %.S
	$(OR32_TOOL_PREFIX)-gcc -DRTLSIM -I ../support $(GCC_OPT) -O2 -g -c -Wall $< -o $@
