######################################################################
####                                                              ####
#### Common software makefile for inclusion by others             ####
####                                                              ####
######################################################################
####                                                              ####
#### Copyright (C) 2010 Authors and OPENCORES.ORG                 ####
####                                                              ####
#### This source file may be used and distributed without         ####
#### restriction provided that this copyright statement is not    ####
#### removed from the file and that any derivative work contains  ####
#### the original copyright notice and the associated disclaimer. ####
####                                                              ####
#### This source file is free software; you can redistribute it   ####
#### and/or modify it under the terms of the GNU Lesser General   ####
#### Public License as published by the Free Software Foundation; ####
#### either version 2.1 of the License, or (at your option) any   ####
#### later version.                                               ####
####                                                              ####
#### This source is distributed in the hope that it will be       ####
#### useful, but WITHOUT ANY WARRANTY; without even the implied   ####
#### warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ####
#### PURPOSE.  See the GNU Lesser General Public License for more ####
#### details.                                                     ####
####                                                              ####
#### You should have received a copy of the GNU Lesser General    ####
#### Public License along with this source; if not, download it   ####
#### from http://www.opencores.org/lgpl.shtml                     ####
####                                                              ####
######################################################################

DESIGN_NAME=orpsoc

OR32_TOOL_PREFIX=or32-elf-

OR32_LD=$(OR32_TOOL_PREFIX)ld
OR32_AS=$(OR32_TOOL_PREFIX)as
OR32_CC=$(OR32_TOOL_PREFIX)gcc
OR32_AR=$(OR32_TOOL_PREFIX)ar
OR32_RANLIB=$(OR32_TOOL_PREFIX)ranlib
OR32_OBJDUMP=$(OR32_TOOL_PREFIX)objdump
OR32_OBJCOPY=$(OR32_TOOL_PREFIX)objcopy

# SW_ROOT should be set by whatever is running this

# Special case for CPU drivers
CPU_DRIVER ?=$(SW_ROOT)/drivers/or1200

# Rest of drivers, check if we have any that we should use board-specific 
# versions of.
# Expecting BOARD_SPECIFIC_DRIVERS and BOARD_PATH to be set
COMMON_SW_DRIVERS=$(shell ls $(SW_ROOT)/drivers )
COMMON_SW_DRIVERS_EXCLUDE_BOARD_DRIVERS_CMD=$(shell for driver in $(BOARD_SPECIFIC_DRIVERS); do echo -n "grep -v $$driver"; done)
COMMON_SW_DRIVERS_WITHOUT_BOARD_DRIVERS=$(shell echo $(COMMON_SW_DRIVERS) $(COMMON_SW_DRIVERS_EXCLUDE_BOARD_DRIVERS_CMD))

# Add paths to the common drivers
SW_DRIVER_PATHS=$(shell for driver in $(COMMON_SW_DRIVERS_WITHOUT_BOARD_DRIVERS); do echo $(SW_ROOT)/drivers/$$driver; done)
# If anything in BOARD_SPECIFIC_DRIVERS, add it to SW_DRIVER_PATHS
# It's expected BOARD_PATH points to the board's path and the heirarchy of
# sw/drivers exists
SW_DRIVER_PATHS += $(shell for driver in $(BOARD_SPECIFIC_DRIVERS); do echo $(BOARD_PATH)/sw/drivers/$$driver; done)

# Now assemble all of the include paths for the drivers, prefix with -I for GCC
DRIVER_INCLUDE_PATHS=$(shell for driverpath in $(SW_DRIVER_PATHS); do echo "-I$$driverpath/include"; done)

# If BOARD_PATH isn't set, then we're not compiling for a board, so use the
# generic board.h include path, otherwise, use that board's
ifeq ($(BOARD_PATH),)
DRIVER_INCLUDE_PATHS +=-I$(SW_ROOT)/board/include
else
DRIVER_INCLUDE_PATHS +=-I$(BOARD_PATH)/sw/board/include
endif

VECTORS_OBJ ?=$(CPU_DRIVER)/crt0.o
ORPSOC_LIB ?=$(SW_ROOT)/lib/liborpsoc.a
SUPPORT_LIBS ?=$(ORPSOC_LIB)

# All driver compilations will generate an object file of this name to be
# included into the liborpsoc library
DRIVER_OBJ=compiled.o

# Machine flags - uncomment one or create custom combination of flags
# All software div, mul and FPU
#MACH_FLAGS ?=-msoft-mul -msoft-div -msoft-float
# FPGA default - only hardware multiply
#MACH_FLAGS ?=-mhard-mul -msoft-div -msoft-float
# All hardware flags
#MARCH_FLAGS ?=-mhard-mul -mhard-div -mhard-float
# Hardware integer arith, soft float
MARCH_FLAGS ?=-mhard-mul -mhard-div -msoft-float

OR32_CFLAGS ?=-g -nostdlib -O2 $(MARCH_FLAGS) \
		$(DRIVER_INCLUDE_PATHS) \
		-I$(SW_ROOT)/lib/include

OR32_LDFLAGS ?=-lgcc -T$(CPU_DRIVER)/link.ld -e 256
OR32_ARFLAGS ?=-r
# RTL_VERILOG_INCLUDE_PATH _MUST_ be set!
# Backup one - default, but may be wrong!
RTL_VERILOG_INCLUDE_PATH ?= $(SW_ROOT)/../rtl/verilog/include

DESIGN_VERILOG_DEFINES=$(RTL_VERILOG_INCLUDE_PATH)/$(DESIGN_NAME)-defines.v
DESIGN_PROCESSED_VERILOG_DEFINES=$(SW_ROOT)/lib/include/$(DESIGN_NAME)-defines.h

OR1200_VERILOG_DEFINES=$(RTL_VERILOG_INCLUDE_PATH)/or1200_defines.v
OR1200_PROCESSED_VERILOG_DEFINES=$(SW_ROOT)/lib/include/or1200-defines.h

PROCESSED_DEFINES=$(DESIGN_PROCESSED_VERILOG_DEFINES) $(OR1200_PROCESSED_VERILOG_DEFINES) 

ELF_DEPENDS+= $(SUPPORT_LIBS) $(VECTORS_OBJ)

# Set V=1 when calling make to enable verbose output
# mainly for debugging purposes.
ifeq ($(V), 1)
Q=
else
Q ?=@
endif

# Our local utilities
UTILS_BIN2HEX=$(SW_ROOT)/utils/bin2hex
$(UTILS_BIN2HEX):
	$(Q)$(MAKE) -C $(SW_ROOT)/utils bin2hex

UTILS_BIN2VMEM=$(SW_ROOT)/utils/bin2vmem
$(UTILS_BIN2VMEM):
	$(Q)$(MAKE) -C $(SW_ROOT)/utils bin2vmem

# Rule to generate C header file from Verilog file with `defines in it
$(DESIGN_PROCESSED_VERILOG_DEFINES): $(DESIGN_VERILOG_DEFINES)
	$(Q)echo; echo "\t### Creating software defines header from verilog defines ###";
	$(Q)echo "//This file is autogenerated from "$<" do not change!" > $@
	$(Q)echo "#ifndef _"$(DESIGN_NAME)"_DEFINES_H_" >> $@
	$(Q)echo "#define _"$(DESIGN_NAME)"_DEFINES_H_" >> $@
	$(Q)cat $< | sed s://.*::g | sed 's/'\`'/'#'/g' >> $@
	$(Q)echo "#endif" >> $@
	$(Q)echo; echo >> $@

# This works (doesn't error), but for now we have to remove all of the numbers
# in verilog format, eg. 8'b0010_0000 or 32'h0000_0f00, or 32'd256 etc. as it's
# not so straight forward to convert these
$(OR1200_PROCESSED_VERILOG_DEFINES): $(OR1200_VERILOG_DEFINES)
	$(Q)echo; echo "\t### Creating OR1200 software defines header from verilog defines ###";
	$(Q)echo "//This file is autogenerated from "$<" do not change!" > $@
	$(Q)echo "#ifndef _OR1200_DEFINES_H_" >> $@
	$(Q)echo "#define _OR1200_DEFINES_H_" >> $@
	$(Q)cat $< | sed s://.*::g | grep -v \'[dhb] | sed 's/'\`'/'#'/g' >> $@
	$(Q)echo "#endif" >> $@
	$(Q)echo; echo >> $@

# Default make
%.flashin: %.bin $(UTILS_BIN2HEX)
	$(Q)$(UTILS_BIN2HEX) $< 1  -size_word > $@

%.vmem: %.bin $(UTILS_BIN2VMEM)
	$(Q)$(UTILS_BIN2VMEM) $< > $@

%.elf: %.c $(ELF_DEPENDS)
	$(Q)$(OR32_CC) $^ $(OR32_CFLAGS) $(OR32_LDFLAGS) -o $@

%.elf: %.S $(ELF_DEPENDS)
	$(Q)$(OR32_CC) $^ $(OR32_CFLAGS) $(OR32_LDFLAGS) -o $@

%.o: %.S
	$(Q)$(OR32_CC) $(OR32_CFLAGS) -c $< -o $@

%.o: %.c
	$(Q)$(OR32_CC) $(OR32_CFLAGS) -c $< -o $@

COMPILE_SRCS_BASENAMES=$(basename $(COMPILE_SRCS))
COMPILE_OBJS=$(COMPILE_SRCS_BASENAMES:%=%.o)

$(DRIVER_OBJ): $(COMPILE_OBJS)
	$(Q)$(OR32_LD) $(OR32_ARFLAGS) $^ -o $@

# Rule to make all necessary driver objects

$(ORPSOC_LIB): $(PROCESSED_DEFINES)
	$(Q)echo; echo "\t### Building software support library ###"; echo
	$(Q)$(MAKE) -C $(SW_ROOT)/lib liborpsoc.a

$(VECTORS_OBJ):
	$(Q)$(MAKE) -C $(CPU_DRIVER) crt0.o

# This relies on the local clean rule of each makefile
clean-all: distclean

clean-support:
	$(Q)$(MAKE) -C ../support clean

# List of software directories, exclude include/
SWDIRS=$(shell ls ../ | grep -v include)

distclean:
	$(Q)for dir in $(SWDIRS); do if [ -d ../$$dir ]; then $(MAKE) -C ../$$dir clean; fi; done
	$(Q)for dir in $(SW_DRIVER_PATHS); do $(MAKE) -C $$dir clean; done
	$(Q)rm -f $(PROCESSED_DEFINES)
