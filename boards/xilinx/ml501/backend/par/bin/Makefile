######################################################################
####                                                              ####
####  ORPSoC Xilinx backend Makefile                              ####
####                                                              ####
####  Author(s):                                                  ####
####      - Julius Baxter, julius@opencores.org                   ####
####                                                              ####
####                                                              ####
######################################################################
####                                                              ####
#### Copyright (C) 2009,2010 Authors and OPENCORES.ORG            ####
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

# Name of the directory we're currently in
CUR_DIR=$(shell pwd)

# The root path of the board build
BOARD_DIR ?=$(CUR_DIR)/../../..
PROJECT_ROOT=$(BOARD_DIR)/../../..

SYN_DIR=$(BOARD_DIR)/syn/xst
SYN_RUN_DIR=$(SYN_DIR)/run

BOARD_BACKEND_DIR=$(BOARD_DIR)/backend/bin

DESIGN_NAME=orpsoc
BOARD_NAME=ml501

# Set V=1 when calling make to enable verbose output
# mainly for debugging purposes.
ifeq ($(V), 1)
Q=
else
Q ?=@
endif

BOARD_RTL_DIR=$(BOARD_DIR)/rtl
BOARD_RTL_VERILOG_DIR=$(BOARD_RTL_DIR)/verilog
# Only 1 include path for board builds - their own!
BOARD_RTL_VERILOG_INCLUDE_DIR=$(BOARD_RTL_VERILOG_DIR)/include
BOARD_DESIGN_VERILOG_DEFINES=$(BOARD_RTL_VERILOG_INCLUDE_DIR)/$(DESIGN_NAME)-defines.v

DEFINES_FILE_CUTOFF=$(shell grep -n "end of included module defines" $(BOARD_DESIGN_VERILOG_DEFINES) | cut -d ':' -f 1)
DESIGN_DEFINES=$(shell cat $(BOARD_DESIGN_VERILOG_DEFINES) | sed s://.*::g | sed s:\`:\#:g | sed 's:^[ ]*::' | awk '{print};/^\#define/{printf "_%s=%s\n",$$2,$$2}' | grep -v PERIOD | cpp -P | sed s:^_::g | sed s:=$$::g )

# Rule to look at what defines are being extracted from main file
print-defines:
	@echo; echo "\t### Design defines ###"; echo
	@echo "\tParsing "$(BOARD_DESIGN_VERILOG_DEFINES)" and exporting:"
	@echo $(DESIGN_DEFINES)


# Backend tool path
# Check that the XILINX_PATH variable is set
ifeq ($(XILINX_PATH),)
$(error XILINX_PATH environment variable not set. Set it and rerun)
endif
XILINX_SETTINGS_SCRIPT=$(XILINX_PATH)/settings32.sh
XILINX_SETTINGS_SCRIPT_EXISTS=$(shell if [ -e $(XILINX_SETTINGS_SCRIPT) ]; then echo 1; else echo 0; fi)
ifeq ($(XILINX_SETTINGS_SCRIPT_EXISTS),0)
$(error XILINX_PATH variable not set correctly. Cannot find $$XILINX_PATH/settings32.sh)
endif


#
# Options for Xilinx PAR tools
#
FPGA_PART=xc5vlx50-ff676-1
XILINX_FLAGS=-intstyle silent
XILINX_MAP_FLAGS=-logic_opt off
XILINX_AREA_TARGET = speed
TIMING_REPORT_OPTIONS = -u 1000 -e 1000
SPI_FLASH_SIZE_KBYTES ?=2048
SPI_BOOTLOADER_SW_OFFSET_HEX ?=1c0000

print-config:
	$(Q)echo; echo "\t### Backend make configuration ###"; echo
	$(Q)echo "\tFPGA_PART="$(FPGA_PART)
	$(Q)echo "\tXILINX_FLAGS="$(XILINX_FLAGS)
	$(Q)echo "\tXILINX_MAP_FLAGS="$(XILINX_MAP_FLAGS)
	$(Q)echo "\tXILINX_AREA_TARGET="$(XILINX_AREA_TARGET)
	$(Q)echo "\tTIMING_REPORT_OPTIONS="$(TIMING_REPORT_OPTIONS)
	$(Q)echo "\tSPI_FLASH_SIZE_KBYTES="$(SPI_FLASH_SIZE_KBYTES)
	$(Q)echo "\tSPI_BOOTLOADER_SW_OFFSET_HEX="$(SPI_BOOTLOADER_SW_OFFSET_HEX)



NGC_FILE=$(SYN_RUN_DIR)/$(DESIGN_NAME).ngc
NGD_FILE=$(DESIGN_NAME).ngd
UCF_FILE=../bin/$(BOARD_NAME).ucf
MAPPED_NCD=$(DESIGN_NAME)_mapped.ncd
PARRED_NCD=$(DESIGN_NAME).ncd
PCF_FILE=$(DESIGN_NAME).pcf
BIT_FILE=$(DESIGN_NAME).bit
BIT_FILE_FOR_SPI=$(DESIGN_NAME)_spiboot.bit
BATCH_FILE=$(DESIGN_NAME).batch
MCS_FILE=$(DESIGN_NAME).mcs

$(NGC_FILE):
	$(Q)$(MAKE) -C $(SYN_RUN_DIR) $(DESIGN_NAME).ngc

$(NGD_FILE): $(UCF_FILE) $(NGC_FILE)
	@echo; echo "\t#### Running NGDBuild ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
	ngdbuild -p $(FPGA_PART) -sd $(BOARD_BACKEND_DIR) -uc $(UCF_FILE) \
	$(NGC_FILE) $@ )

#This target uses Xilinx tools to perform Mapping
$(MAPPED_NCD): $(NGD_FILE)
	@echo; echo "\t#### Mapping ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
        export XIL_MAP_NO_DSP_AUTOREG=1 && \
        export XIL_MAP_ALLOW_ANY_DLL_INPUT=1 && \
	map -p $(FPGA_PART) -detail -pr b -cm ${XILINX_AREA_TARGET} \
	-timing -ol high -w $(XILINX_FLAGS) -o $@ -xe n $(NGD_FILE) $(PCF_FILE))

#This target uses Xilinx tools to Place & Route the design
$(PARRED_NCD): $(MAPPED_NCD)
	@echo; echo "\t#### PAR'ing ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
	par -w -pl high -rl high $(XILINX_FLAGS) $< $@ $(PCD_FILE) )

#This target uses Xilinx tools to generate a bitstream for download
$(BIT_FILE): $(PARRED_NCD)
	@echo; echo "\t#### Generating .bit file ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
	bitgen -w $(XILINX_FLAGS) -g StartUpClk:JtagClk $< $@ )

$(BIT_FILE_FOR_SPI): $(PARRED_NCD)
	@echo; echo "\t#### Generating .bit file for SPI load ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
	bitgen -w $(XILINX_FLAGS) -g StartUpClk:CClk $< $@ )
ifeq ($(BOOTLOADER_BIN),)
$(MCS_FILE): $(BIT_FILE_FOR_SPI)
	@echo; echo "\t#### Generating .mcs file for SPI load ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
	promgen -spi -p mcs -o $@ -s $(SPI_FLASH_SIZE_KBYTES) -u 0 $< )
else
$(MCS_FILE): $(BIT_FILE_FOR_SPI)
	@echo; echo "\t#### Generating .mcs file for SPI load ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
	promgen -spi -p mcs -o $@ -s $(SPI_FLASH_SIZE_KBYTES) -u 0 $< \
	-data_file up $(SPI_BOOTLOADER_SW_OFFSET_HEX) $(BOOTLOADER_BIN) \
	 )
endif

#this target downloads the bitstream to the target fpga
download: $(BIT_FILE) $(BATCH_FILE)
	$(Q)( . ${XILINX_PATH}/settings32.sh && \
	impact -batch $(BATCH_FILE) )

#This target uses netgen to make a simulation netlist
netlist: $(PARRED_NCD)
	@echo; echo "\t#### Generating netlist ####";
	$(Q)(. $(XILINX_SETTINGS_SCRIPT) && \
	netgen -ofmt verilog -sim -dir netlist -pcf $(PCF_FILE) $<)

#This one uses TRCE to make a timing report
timingreport: $(PARRED_NCD)
	@echo; echo "\t#### Generating timing report ####";
	$(Q)(. $(XILINX_SETTINGS_SCRIPT) && \
	trce $(TIMING_REPORT_OPTIONS) $< )


clean:
	$(Q)rm -rf *.*

clean-syn:
	$(Q)$(MAKE) -C $(SYN_RUN_DIR) distclean

distclean: clean-syn clean

.PRECIOUS : $(PARRED_NCD) $(MAPPED_NCD) $(NGC_FILE) $(NGD_FILE) $(BIT_FILE) $(BIT_FILE_FOR_SPI)
