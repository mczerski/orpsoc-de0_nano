######################################################################
####                                                              ####
####  ORPSoC Xilinx Synthesis Makefile                            ####
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

DESIGN_NAME=orpsoc

SYN_DIR=$(BOARD_DIR)/syn/xst
SYN_RUN_DIR=$(SYN_DIR)/run

# Paths to other important parts of this test suite
COMMON_RTL_DIR = $(PROJECT_ROOT)/rtl
COMMON_RTL_VERILOG_DIR = $(COMMON_RTL_DIR)/verilog
#COMMON_RTL_VHDL_DIR = $(COMMON_RTL_DIR)/vhdl

BOARD_RTL_DIR=$(BOARD_DIR)/rtl
BOARD_RTL_VERILOG_DIR=$(BOARD_RTL_DIR)/verilog
# Only 1 include path for board builds - their own!
BOARD_RTL_VERILOG_INCLUDE_DIR=$(BOARD_RTL_VERILOG_DIR)/include
BOARD_DESIGN_VERILOG_DEFINES=$(BOARD_RTL_VERILOG_INCLUDE_DIR)/$(DESIGN_NAME)-defines.v
#BOARD_RTL_VHDL_DIR = $(BOARD_RTL_DIR)/vhdl

BACKEND_DIR=$(BOARD_DIR)/backend
BACKEND_BIN_DIR=$(BACKEND_DIR)/bin

# Set V=1 when calling make to enable verbose output
# mainly for debugging purposes.
ifeq ($(V), 1)
Q=
else
Q ?=@
endif


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
# Verilog DUT source variables
#
# First we get a list of modules in the RTL path of the board's path.
# Next we check which modules not in the board's RTL path are in the root RTL
# path (modules which can be commonly instantiated, but over which board 
# build-specific versions take precedence.)

# Paths under board/***/rtl/verilog we wish to exclude when getting modules
BOARD_VERILOG_MODULES_EXCLUDE= include
BOARD_VERILOG_MODULES_DIR_LIST=$(shell ls $(BOARD_RTL_VERILOG_DIR))
# Apply exclude to list of modules
BOARD_RTL_VERILOG_MODULES=$(filter-out $(BOARD_VERILOG_MODULES_EXCLUDE),$(BOARD_VERILOG_MODULES_DIR_LIST))

# Rule for debugging this script
print-board-modules:
	$(Q)echo echo; echo "\t### Board verilog modules ###"; echo;
	$(Q)echo $(BOARD_RTL_VERILOG_MODULES)

# Now get list of modules that we don't have a version of in the board path
# List others that cause clahes (ie. source listed, due to utterly pathetic XST
# not supporting ability to specify search paths, and requiring includes but
# not used in this board build, hence its includes are not there and result
# in error.)
COMMON_VERILOG_MODULES_EXCLUDE= include usbhostslave
COMMON_VERILOG_MODULES_EXCLUDE += $(BOARD_RTL_VERILOG_MODULES)

COMMON_RTL_VERILOG_MODULES_DIR_LIST=$(shell ls $(COMMON_RTL_VERILOG_DIR))
COMMON_RTL_VERILOG_MODULES=$(filter-out $(COMMON_VERILOG_MODULES_EXCLUDE), $(COMMON_RTL_VERILOG_MODULES_DIR_LIST))

# Rule for debugging this script
print-common-modules-exclude:
	$(Q)echo echo; echo "\t### Common verilog modules being excluded due to board versions ###"; echo;
	$(Q)echo "$(COMMON_VERILOG_MODULES_EXCLUDE)"

print-common-modules:
	$(Q)echo echo; echo "\t###  Verilog modules from common RTL dir ###"; echo
	$(Q)echo $(COMMON_RTL_VERILOG_MODULES)

# List of verilog source files (only .v files!)
# Board RTL modules first
VERILOG_SRC_PATHS=$(addprefix $(BOARD_RTL_VERILOG_DIR)/,$(BOARD_RTL_VERILOG_MODULES))
VERILOG_SRC_PATHS +=$(addprefix $(COMMON_RTL_VERILOG_DIR)/,$(COMMON_RTL_VERILOG_MODULES))
RTL_VERILOG_SRC=$(shell for modulepath in $(VERILOG_SRC_PATHS); do \
	if [ -d $$modulepath ]; then \
		ls $$modulepath/*.v; \
	fi; done)

# List of verilog includes from board RTL path - only for rule sensitivity
RTL_VERILOG_INCLUDES=$(shell ls $(BOARD_RTL_VERILOG_INCLUDE_DIR)/*.*)

#
# VHDL DUT source variables
#
# VHDL modules
#RTL_VHDL_MODULES=$(shell ls $(RTL_VHDL_DIR))
# VHDL sources
#RTL_VHDL_SRC=$(shell for module in $(RTL_VHDL_MODULES); do if [ -d $(RTL_VHDL_DIR)/$$module ]; then ls $(RTL_VHDL_DIR)/$$module/*.vhd; fi; done)


#
# Dynamically created files included by different parts of the defines
#

BOARD_SW_DIR=$(BOARD_DIR)/sw

# BootROM code, which generates a verilog array select values
BOOTROM_FILE=bootrom.v
BOARD_BOOTROM_SW_DIR=$(BOARD_SW_DIR)/bootrom
BOOTROM_VERILOG=$(BOARD_BOOTROM_SW_DIR)/$(BOOTROM_FILE)
# Export BOARD_PATH for the software makefiles
BOARD_PATH=$(BOARD_DIR)
export BOARD_PATH
bootrom: $(BOOTROM_VERILOG)
$(BOOTROM_VERILOG):
	$(MAKE) -C $(BOARD_BOOTROM_SW_DIR) $(BOOTROM_FILE)

TIMESCALE_FILE=timescale.v
SYNDIR_TIMESCALE_FILE=$(SYN_RUN_DIR)/$(TIMESCALE_FILE)
$(SYNDIR_TIMESCALE_FILE):
	$(Q)echo "" > $@

SYN_VERILOG_DEFINES=synthesis-defines.v
SYNDIR_SYN_VERILOG_DEFINES=$(SYN_RUN_DIR)/$(SYN_VERILOG_DEFINES)
$(SYNDIR_SYN_VERILOG_DEFINES):
	$(Q)echo "\`define SYNTHESIS" > $@
	$(Q)echo "\`define XILINX" >> $@
	$(Q)echo "" >> $@

GENERATED_DEFINES = $(BOOTROM_VERILOG)
GENERATED_DEFINES += $(SYNDIR_TIMESCALE_FILE)
GENERATED_DEFINES += $(SYNDIR_SYN_VERILOG_DEFINES)


FPGA_PART ?=xc5vlx50-ff676-1
OPT_MODE ?=Speed
OPT_LEVEL ?=2


XILINX_FLAGS ?=-intstyle silent
XILINX_XST_FLAGS ?= -power NO -glob_opt AllClockNets -write_timing_constraints NO -cross_clock_analysis NO -slice_utilization_ratio 100 -bram_utilization_ratio 100 -dsp_utilization_ratio 100 -safe_implementation No -fsm_style lut -ram_extract Yes -ram_style Auto -rom_extract Yes -rom_style Auto -auto_bram_packing NO -mux_extract YES -mux_style Auto -decoder_extract YES -priority_extract YES -shreg_extract YES -shift_extract YES -xor_collapse YES -resource_sharing YES -async_to_sync NO -use_dsp48 auto -iobuf YES -max_fanout 100000 -bufg 32 -register_duplication YES -equivalent_register_removal YES -register_balancing No -slice_packing YES -optimize_primitives NO -use_clock_enable Auto -use_sync_set Auto -use_sync_reset Auto -iob Auto -slice_utilization_ratio_maxmargin 5

XCF_FILE=$(DESIGN_NAME).xcf
XST_FILE=$(DESIGN_NAME).xst
PRJ_FILE=$(DESIGN_NAME).prj
NGC_FILE=$(DESIGN_NAME).ngc
NETLIST_FILE=$(DESIGN_NAME).v

XST_PRJ_FILE_SRC_DECLARE=verilog work

print-config:
	$(Q)echo; echo "\t### Synthesis make configuration ###"; echo
	$(Q)echo "\tFPGA_PART="$(FPGA_PART)
	$(Q)echo "\tOPT_MODE="$(OPT_MODE)
	$(Q)echo "\tOTP_LEVEL="$(OPT_LEVEL)
	$(Q)echo "\tXILINX_XST_FLAGS="$(XILINX_XST_FLAGS)
	$(Q)echo

all: $(NGC_FILE)

# Generate the .xst file
# See this page for information on options:
# http://www.xilinx.com/itp/xilinx4/data/docs/xst/command_line5.html
$(XST_FILE):
	$(Q)echo; echo "\t#### Generating XST file ####"; echo
	$(Q)echo "# XST Script for ORPSoC Synthesis" > $@
	$(Q)echo "# This file is autogenerated - any changes will be overwritten" >> $@
	$(Q)echo "# See the Makefile in syn/xst/bin to make changes" >> $@
	$(Q)echo "run" >> $@
	$(Q)echo "-ifn "$(PRJ_FILE) >> $@
	$(Q)echo "-ifmt mixed" >> $@
	$(Q)echo "-top "$(DESIGN_NAME)"_top" >> $@
	$(Q)echo "-ofmt NGC" >> $@
	$(Q)echo "-ofn "$(NGC_FILE) >> $@
	$(Q)echo "-p "$(FPGA_PART) >> $@
	$(Q)echo "-opt_level "$(OPT_LEVEL) >> $@
	$(Q)echo "-opt_mode "$(OPT_MODE) >> $@
	$(Q)echo "-uc "$(XCF_FILE) >> $@
#	$(Q)echo "elaborate " >> $@
#	$(Q)echo -n "-vlgpath \"" >> $@
# option missing from XST - wtf?!	$(Q)for vlogpath in $(VERILOG_SRC_PATHS); do \
		echo -n $$vlogpath" "; done >> $@
#	$(Q)echo "\"" >> $@
	$(Q)echo "-vlgincdir { "$(BOARD_RTL_VERILOG_INCLUDE_DIR)" "$(BOARD_BOOTROM_SW_DIR) " }" >> $@
	$(Q)echo >> $@

# Generate Xilinx project (.prj) file
$(PRJ_FILE): $(RTL_VERILOG_SRC)
	$(Q)echo; echo "\t#### Generating Xilinx PRJ file ####";
#	$(Q)echo "# Autogenerated XST .prj file" > $@
#	$(Q)echo "# Any changes will be written over." >> $@
	$(Q)for file in $(RTL_VERILOG_SRC); do \
		echo $(XST_PRJ_FILE_SRC_DECLARE) $$file >> $@ ; \
	done
	$(Q)echo >> $@
	$(Q)echo

# Constraints file
$(XCF_FILE):
	$(Q)echo; echo "\t#### Generating Xilinx PRJ file ####"; echo
	$(Q)echo "# Autogenerated XST .prj file" > $@
	$(Q)echo "#" >> $@
	$(Q)echo "# Not much here, XST is smart enough to determine clocks through DCMs" >> $@
	$(Q)echo "#" >> $@
	$(Q)echo "# TODO: Potentially use the other XTAL for DDR RAM clocking" >> $@
	$(Q)echo "#" >> $@
	$(Q)echo "# 200MHz diff. XTAL used as main system clock" >> $@
	$(Q)echo "NET \"sys_clk_in_p\" TNM_NET = \"sys_clk_in_p_grp\";" >> $@
	$(Q)echo "NET \"sys_clk_in_n\" TNM_NET = \"sys_clk_in_n_grp\";" >> $@
	$(Q)echo "TIMESPEC \"TS_sys_clk_in_p_grp\" = PERIOD \"sys_clk_in_p_grp\" 5 ns HIGH 50 %;" >> $@
	$(Q)echo "TIMESPEC \"TS_sys_clk_in_n_grp\" = PERIOD \"sys_clk_in_n_grp\" 5 ns LOW 50 %;" >> $@
	$(Q)echo "# 100 MHz user clock" >> $@
	$(Q)echo "#NET \"sys_clk_in\" TNM_NET = \"sys_clk_in_grp\";" >> $@
	$(Q)echo "#TIMESPEC \"TS_sys_clk_in\" = PERIOD \"sys_clk_in_grp\" 10 ns HIGH 50%;" >> $@
	$(Q)echo "# Ignore the reset logic" >> $@
	$(Q)echo "NET rst_n_pad_i* TIG;" >> $@
	$(Q)echo "# SSRAM multicylce constraints:" >> $@
	$(Q)echo "# Define the two clock domains as timespecs" >> $@
	$(Q)echo "#NET dcm0_clkdv TNM_NET=\"wb_clk\";" >> $@
	$(Q)echo "#TIMESPEC \"TS_wb_clk\" = PERIOD \"wb_clk\" 20 ns HIGH 10;" >> $@
	$(Q)echo "#NET dcm0_clk0 TNM_NET = \"ssram_clk200\";" >> $@
	$(Q)echo "#TIMESPEC \"TS_ssram_clk200\" = PERIOD \"ssram_clk200\" \"TS_wb_clk\" / 4;" >> $@
	$(Q)echo "# Now define their relationship - logic should be configured so that there's" >> $@
	$(Q)echo "# 1 WB cycle at all times before anything is sampled across domains" >> $@
	$(Q)echo "#TIMESPEC \"TS_wb_clk_ssram_clk200\" = from \"wb_clk\" TO \"ssram_clk200\" 15 ns;" >> $@
	$(Q)echo "#TIMESPEC \"TS_ssram_clk200_wb_clk\" = from \"ssram_clk200\" TO \"wb_clk\" 20 ns;" >> $@

# XST command
$(NGC_FILE): $(PRJ_FILE) $(XST_FILE) $(XCF_FILE) $(GENERATED_DEFINES)
	$(Q)echo; echo "\t#### Running XST ####"; echo;
	$(Q)(. $(XILINX_SETTINGS_SCRIPT) ; xst -ifn $(XST_FILE) $(XILINX_FLAGS) $(XST_FLAGS) )
	$(Q)echo

# Netlist generation command
$(NETLIST_FILE): $(NGC_FILE)
	$(Q)echo; echo "\t#### Generating verilog netlist ####"; echo;
	$(Q)(. $(XILINX_SETTINGS_SCRIPT) ; \
	netgen -sim -aka -dir . -ofmt verilog $< -w $@ )	


clean:
	$(Q)rm -rf *.* xst

clean-sw:
	$(MAKE) -C $(PROJECT_ROOT)/sw/lib clean-all

clean-all: clean-sw clean


.PRECIOUS : $(NGC_FILE) $(XST_FILE) $(XCF_FILE)