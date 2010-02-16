PROJECT_ROOT=../../../../..

MAIN_SW_DIR=$(PROJECT_ROOT)/sw

SUPPORT_SOURCES=uart.c uart.h spr_defs.h support.h
SUPPORT_C_SOURCES=$(shell for src in $(SUPPORT_SOURCES); do echo $$src | grep \.c; done)

# Some extra options, if we're going to compile the software for it to be pulled in by the synthesis tool
ifeq ($(SYNTHESIS), 1)
SW_SYNTHESIS_OPTS=-DSYNTHESIS
VMEM_SYNTHESIS_OPTS=-synfmt
endif


CROSS_PREFIX=or32-elf-
CROSS_CC=$(CROSS_PREFIX)gcc
CROSS_OBJCOPY=$(CROSS_PREFIX)objcopy

APP=memtest

all: clean

.PHONY: $(APP)
$(APP): prepare-sw prepare-links $(APP).vmem


$(APP).vmem: $(APP).bin
	$(MAIN_SW_DIR)/utils/bin2vmem $? $(VMEM_SYNTHESIS_OPTS) > $@

$(APP).bin: $(APP).or32
	$(CROSS_OBJCOPY) -O binary $? $@

$(APP).or32: $(APP)_reset.o $(APP).[cS] $(SUPPORT_C_SOURCES)
	$(CROSS_CC) $? -nostdlib -mhard-mul -g -I../. -O2 $(SW_SYNTHESIS_OPTS) -T$(APP).ld -o $@

$(APP)_reset.o: $(APP)_reset.S
	$(CROSS_CC) -c -o $@ $? -I../.

prepare-links:
	for src in $(SUPPORT_SOURCES); do if [ ! -e $$src ]; then ln -s $(MAIN_SW_DIR)/support/$$src; fi; done

unprepare-links:
	for src in $(SUPPORT_SOURCES); do if [ -e $$src ]; then unlink $$src; fi; done

prepare-sw:
	@$(MAKE) -C $(MAIN_SW_DIR)/utils all

clean: unprepare-links
	@rm -vf *.o *.bin *.or32 *.vmem