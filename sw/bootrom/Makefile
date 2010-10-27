# Makefile for bootROM Verilog
SW_ROOT=..
include $(SW_ROOT)/Makefile.inc


all: bootrom.v

%.v: %.bin $(SW_ROOT)/utils/bin2vlogarray
	$(Q)$(SW_ROOT)/utils/bin2vlogarray < $< > $@

%.dis: %.o
	$(Q)$(OR32_OBJDUMP) -d $< > $@

%.bin: %.o
	$(Q)$(OR32_OBJCOPY) -O binary $< $@

$(SW_ROOT)/utils/bin2vlogarray:
	$(Q)$(MAKE) -C $(SW_ROOT)/utils bin2vlogarray

clean:
	$(Q)rm -f *.o *.bin *.hex *.in *.dis *.v

