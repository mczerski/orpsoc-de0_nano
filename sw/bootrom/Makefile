# Makefile for bootROM Verilog

include ../Makefile.inc


all: bootrom.v

%.v: %.bin ../utils/bin2vlogarray
	$(Q)../utils/bin2vlogarray < $< > $@

%.dis: %.o
	$(Q)$(OR32_OBJDUMP) -d $< > $@

%.bin: %.o
	$(Q)$(OR32_OBJCOPY) -O binary $< $@

../utils/bin2vlogarray:
	$(Q)$(MAKE) -C ../utils bin2vlogarray

clean:
	$(Q)rm -f *.o *.bin *.hex *.in *.dis *.v

