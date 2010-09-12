.PHONY: dhry.vmem 
.PHONY: dhry.bin 

include ../Makefile.inc

NUM_RUNS ?= 10

OR32_CFLAGS += -DNUM_RUNS=$(NUM_RUNS)


# Have our specific make rules here, so each time we run it gets compiled.
# This is useful as the NUM_RUNS variable can change from build to build.

.PHONY: dhry.vmem
dhry.vmem: dhry.bin $(UTILS_BIN2VMEM)
	$(Q)$(UTILS_BIN2VMEM) $< > $@

.PHONY: dhry.bin
dhry.bin: dhry.elf
	$(Q)$(OR32_OBJCOPY) -O binary $< $@

.PHONY: dhry.elf
dhry.elf: dhry.c $(ELF_DEPENDS)
	$(Q)$(OR32_CC) $^ $(OR32_CFLAGS) $(OR32_LDFLAGS) -o $@

%.dis: %.elf
	$(Q)$(OR32_OBJDUMP) -d $< > $@

%.bin: %.elf
	$(Q)$(OR32_OBJCOPY) -O binary $< $@

clean:
	$(Q)rm -f *.elf *.bin *.vmem *.flashin *.dis

