######################################################################
####                                                              ####
####  ORPSoCv2 Xilinx simulation Makefile                         ####
####                                                              ####
####  Description                                                 ####
####  ORPSoCv2 Testbenches Makefile, containing rules for         ####
####  configuring and running different tests on the current      ####
####  ORPSoC(v2) design.                                          ####
####                                                              ####
####  To do:                                                      ####
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

# The root path of the whole project
PROJECT_ROOT ?=$(CUR_DIR)/../../../../..

DESIGN_NAME=orpsoc
RTL_TESTBENCH_TOP=$(DESIGN_NAME)_testbench

# Hardset the board name, even though we could probably determine it
FPGA_VENDOR=xilinx
BOARD_NAME=ml501
BOARD_DIR=$(PROJECT_ROOT)/boards/$(FPGA_VENDOR)/$(BOARD_NAME)

# Export BOARD for the software makefiles
BOARD=$(FPGA_VENDOR)/$(BOARD_NAME)
export BOARD

# Paths to other important parts of this test suite
COMMON_RTL_DIR = $(PROJECT_ROOT)/rtl
COMMON_RTL_VERILOG_DIR = $(COMMON_RTL_DIR)/verilog
#COMMON_RTL_VHDL_DIR = $(COMMON_RTL_DIR)/vhdl

BOARD_RTL_DIR=$(BOARD_DIR)/rtl
BOARD_RTL_VERILOG_DIR=$(BOARD_RTL_DIR)/verilog
# Only 1 include path for board builds - their own!
BOARD_RTL_VERILOG_INCLUDE_DIR=$(BOARD_RTL_VERILOG_DIR)/include

BOARD_BENCH_DIR=$(BOARD_DIR)/bench
BOARD_BENCH_VERILOG_DIR=$(BOARD_BENCH_DIR)/verilog
BOARD_BENCH_VERILOG_INCLUDE_DIR=$(BOARD_BENCH_VERILOG_DIR)/include

COMMON_BENCH_DIR=$(PROJECT_ROOT)
COMMON_BENCH_VERILOG_DIR=$(COMMON_BENCH_DIR)/verilog
COMMON_BENCH_VERILOG_INCLUDE_DIR=$(COMMON_BENCH_VERILOG_DIR)/include

# Top level files for DUT and testbench
DUT_TOP=$(BOARD_RTL_VERILOG_DIR)/$(DESIGN_NAME)_top/$(DESIGN_NAME)_top.v
BENCH_TOP=$(BOARD_BENCH_VERILOG_DIR)/$(DESIGN_NAME)_testbench.v

# Software tests we'll run

# Need this for individual test variables to not break
TEST ?= or1200-simple

TESTS ?= or1200-simple or1200-cbasic or1200-dctest or1200-float or1200-mmu or1200-basic or1200-except or1200-tick or1200-ticksyscall uart-simple

# Gets turned into verilog `define
SIM_TYPE=RTL

# Main defines file is from board include path
PROJECT_VERILOG_DEFINES=$(BOARD_RTL_VERILOG_INCLUDE_DIR)/$(DESIGN_NAME)-defines.v

# Detect technology to use for the simulation
DESIGN_DEFINES=$(shell cat $(PROJECT_VERILOG_DEFINES) | sed s://.*::g | sed s:\`:\#:g | sed 's:^[ ]*::' | awk '{print};/^\#define/{printf "_%s=%s\n",$$2,$$2}' | grep -v PERIOD | cpp -P | sed s:^_::g | sed s:=$$::g )

# Rule to look at what defines are being extracted from main file
print-defines:
	@echo echo; echo "\t### Design defines ###"; echo;
	@echo "\tParsing "$(PROJECT_VERILOG_DEFINES)" and exporting:"
	@echo $(DESIGN_DEFINES)

print-tests:
	@echo; echo; echo "\t### Software tests to be run ###"; echo;
	@echo $(TESTS)
	@echo

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


# Simulation directories
SIM_DIR ?=$(BOARD_DIR)/sim
RTL_SIM_DIR=$(SIM_DIR)
RTL_SIM_RUN_DIR=$(RTL_SIM_DIR)/run
RTL_SIM_BIN_DIR=$(RTL_SIM_DIR)/bin
RTL_SIM_RESULTS_DIR=$(RTL_SIM_DIR)/out

# Testbench paths
BOARD_BENCH_DIR=$(BOARD_DIR)/bench
BOARD_BENCH_VERILOG_DIR=$(BOARD_BENCH_DIR)/verilog
COMMON_BENCH_DIR=$(PROJECT_ROOT)/bench
COMMON_BENCH_VERILOG_DIR=$(COMMON_BENCH_DIR)/verilog

#BENCH_VHDL_DIR=$(BENCH_DIR)/vhdl
# No SystemC or Verilator support for this build
#BENCH_SYSC_DIR=$(BENCH_DIR)/sysc
#BENCH_SYSC_SRC_DIR=$(BENCH_SYSC_DIR)/src
#BENCH_SYSC_INCLUDE_DIR=$(BENCH_SYSC_DIR)/include

# Backend directories
# This one is the board build's backend dir.
BOARD_BACKEND_DIR=$(BOARD_DIR)/backend
BOARD_BACKEND_VERILOG_DIR=$(BOARD_BACKEND_DIR)/rtl/verilog
TECHNOLOGY_BACKEND_DIR=$(BOARD_DIR)/../backend
# This path is for the technology library
#TECHNOLOGY_BACKEND_VERILOG_DIR=$(TECHNOLOGY_BACKEND_DIR)/rtl/verilog
# Depends on the XILINX_PATH variable - we check above if it's set properly.
TECHNOLOGY_BACKEND_VERILOG_DIR=$(XILINX_PATH)/verilog

# Synthesis directory for board
BOARD_SYN_DIR=$(BOARD_DIR)/syn/synplify
BOARD_SYN_OUT_DIR=$(BOARD_SYN_DIR)/out

# System software dir
COMMON_SW_DIR=$(PROJECT_ROOT)/sw
BOARD_SW_DIR=$(BOARD_DIR)/sw

# BootROM code, which generates a verilog array select values
BOOTROM_FILE=bootrom.v
BOARD_BOOTROM_SW_DIR=$(BOARD_SW_DIR)/bootrom
BOOTROM_SRC=$(shell ls $(BOARD_BOOTROM_SW_DIR)/* | grep -v $(BOOTROM_FILE))
BOOTROM_VERILOG=$(BOARD_BOOTROM_SW_DIR)/$(BOOTROM_FILE)

.phony: $(BOOTROM_VERILOG)
bootrom: $(BOOTROM_VERILOG)

$(BOOTROM_VERILOG): $(BOOTROM_SRC)
	$(Q)echo; echo "\t### Generating bootup ROM ###"; echo
	$(Q)$(MAKE) -C $(BOARD_BOOTROM_SW_DIR) $(BOOTROM_FILE)

# Suffix of file to check after each test for the string
TEST_OUT_FILE_SUFFIX=-general.log
TEST_OK_STRING=8000000d

# Dynamically generated verilog file defining configuration for various things
# Rule actually generating this is found in definesgen.inc file.
TEST_DEFINES_VLG=test-defines.v
.PHONY: $(TEST_DEFINES_VLG)
# Set V=1 when calling make to enable verbose output
# mainly for debugging purposes.
ifeq ($(V), 1)
Q=
QUIET=
else
Q ?=@
QUIET=-quiet
endif

# Modelsim variables
MGC_VSIM=vsim
MGC_VLOG_COMP=vlog
MGC_VHDL_COMP=vcom
MODELSIM=modelsim

# Default simulator is Modelsim here as we're using the ProASIC3 
# libraries which are not compilable with Icarus.
# Set SIMULATOR=modelsim to use Modelsim (Default)
# Set SIMULATOR=ncverilog to use Cadence's NC-Verilog - TODO
# Set SIMULATOR=icarus to use Icarus Verilog (Not supported for this board)

SIMULATOR ?= $(MODELSIM)

#
# Modelsim-specific settings
#
VOPT_ARGS=$(QUIET) -suppress 2241
# If VCD dump is desired, tell Modelsim not to optimise
# away everything.
ifeq ($(VCD), 1)
#VOPT_ARGS=-voptargs="+acc=rnp"
VOPT_ARGS=+acc=rnpqv
endif
# VSIM commands
# Suppressed warnings - 3009: Failed to open $readmemh() file
# Suppressed warnings - 3009: Module 'blah' does not have a `timescale directive in effect, but previous modules do.
# Suppressed warnings - 8598: Non-positive replication multiplier inside concat. Replication will be ignored
VSIM_ARGS=  -suppress 7 -suppress 3009 -suppress 8598 -c $(QUIET) -do "set StdArithNoWarnings 1; run -all; exit"

# VPI debugging interface variables
VPI_SRC_C_DIR=$(COMMON_BENCH_VERILOG_DIR)/vpi/c
VPI_SRC_VERILOG_DIR=vpi/verilog
VPI_SRCS=$(shell ls $(VPI_SRC_C_DIR)/*.[ch])

# Modelsim VPI compile variables
MODELTECH_VPILIB=msim_jp_vpi.sl


# Modelsim VPI settings
ifeq ($(VPI), 1)
VPI_LIBS=$(VPI_SRC_C_DIR)/$(MODELTECH_VPILIB)
VSIM_ARGS += -pli $(VPI_SRC_C_DIR)/$(MODELTECH_VPILIB)
endif
# Rule to make the VPI library for modelsim
$(VPI_SRC_C_DIR)/$(MODELTECH_VPILIB): $(VPI_SRCS)
	$(MAKE) -C $(VPI_SRC_C_DIR) $(MODELTECH_VPILIB)

#
# Verilog DUT source variables
#

# First consider any modules we'll use gatelevel descriptions of.
# These will have to be set on the command line
GATELEVEL_MODULES ?=

# First we get a list of modules in the RTL path of the board's path.
# Next we check which modules not in the board's RTL path are in the root RTL
# path (modules which can be commonly instantiated, but over which board 
# build-specific versions take precedence.)

# Paths under board/***/rtl/verilog we wish to exclude when getting modules
BOARD_VERILOG_MODULES_EXCLUDE= include $(GATELEVEL_MODULES)
BOARD_VERILOG_MODULES_DIR_LIST=$(shell ls $(BOARD_RTL_VERILOG_DIR))
# Apply exclude to list of modules
BOARD_RTL_VERILOG_MODULES=$(filter-out $(BOARD_VERILOG_MODULES_EXCLUDE),$(BOARD_VERILOG_MODULES_DIR_LIST))

# Rule for debugging this script
print-board-modules:
	@echo echo; echo "\t### Board verilog modules ###"; echo
	@echo $(BOARD_RTL_VERILOG_MODULES)

# Now get list of modules that we don't have a version of in the board path
COMMON_VERILOG_MODULES_EXCLUDE= include
COMMON_VERILOG_MODULES_EXCLUDE += $(BOARD_RTL_VERILOG_MODULES)
COMMON_VERILOG_MODULES_EXCLUDE += $(GATELEVEL_MODULES)

COMMON_RTL_VERILOG_MODULES_DIR_LIST=$(shell ls $(COMMON_RTL_VERILOG_DIR))
COMMON_RTL_VERILOG_MODULES=$(filter-out $(COMMON_VERILOG_MODULES_EXCLUDE), $(COMMON_RTL_VERILOG_MODULES_DIR_LIST))


# Add these to exclude their RTL directories from being included in scripts



# Rule for debugging this script
print-common-modules-exclude:
	@echo echo; echo "\t### Common verilog modules being excluded due to board versions ###"; echo
	@echo "$(COMMON_VERILOG_MODULES_EXCLUDE)"

print-common-modules:
	@echo echo; echo "\t###  Verilog modules from common RTL dir ###"; echo
	@echo $(COMMON_RTL_VERILOG_MODULES)

# List of verilog source files (only .v files!)
# Board RTL modules first
RTL_VERILOG_SRC=$(shell for module in $(BOARD_RTL_VERILOG_MODULES); do if [ -d $(BOARD_RTL_VERILOG_DIR)/$$module ]; then ls $(BOARD_RTL_VERILOG_DIR)/$$module/*.v; fi; done)
# Common RTL module source
RTL_VERILOG_SRC +=$(shell for module in $(COMMON_RTL_VERILOG_MODULES); do if [ -d $(COMMON_RTL_VERILOG_DIR)/$$module ]; then ls $(COMMON_RTL_VERILOG_DIR)/$$module/*.v; fi; done)

# List of verilog includes from board RTL path - only for rule sensitivity
RTL_VERILOG_INCLUDES=$(shell ls $(BOARD_RTL_VERILOG_INCLUDE_DIR)/*.*)

print-verilog-src:
	@echo echo; echo "\t### Verilog source ###"; echo
	@echo $(RTL_VERILOG_SRC)

# Rules to make RTL we might need
# Expects modules, if they need making, to have their top verilog file to
# correspond to their module name, and the directory should have a make file
# and rule which works for this command.
# Add name of module to this list, currently only does verilog ones.
# Rule 'rtl' is called just before generating DUT modelsim compilation script
RTL_TO_CHECK=
rtl:
	$(Q)for module in $(RTL_TO_CHECK); do \
		$(MAKE) -C $(RTL_VERILOG_DIR)/$$module $$module.v; \
	done

#
# VHDL DUT source variables
#
# VHDL modules
#RTL_VHDL_MODULES=$(shell ls $(RTL_VHDL_DIR))
# VHDL sources
#RTL_VHDL_SRC=$(shell for module in $(RTL_VHDL_MODULES); do if [ -d $(RTL_VHDL_DIR)/$$module ]; then ls $(RTL_VHDL_DIR)/$$module/*.vhd; fi; done)
#print-vhdl-src:
#	@echo echo; echo "\t### VHDL modules and source ###"; echo
#	@echo "modules: "; echo $(RTL_VHDL_MODULES); echo
#	@echo "source: "$(RTL_VHDL_SRC)

#
# Testbench source
#
BOARD_BENCH_VERILOG_SRC=$(shell ls $(BOARD_BENCH_VERILOG_DIR)/*.v | grep -v $(DESIGN_NAME)_testbench )
BOARD_BENCH_VERILOG_SRC_FILES=$(notdir $(BOARD_BENCH_VERILOG_SRC))

# Now only take the source from the common path that we don't already have in
# our board's
COMMON_BENCH_VERILOG_DIR_LS=$(shell ls $(COMMON_BENCH_VERILOG_DIR)/*.v)
COMMON_BENCH_VERILOG_SRC_FILES=$(notdir $(COMMON_BENCH_VERILOG_DIR_LS))
COMMON_BENCH_VERILOG_SRC_FILTERED=$(filter-out $(BOARD_BENCH_VERILOG_SRC_FILES) $(DESIGN_NAME)_testbench.v,$(COMMON_BENCH_VERILOG_SRC_FILES))
COMMON_BENCH_VERILOG_SRC=$(addprefix $(COMMON_BENCH_VERILOG_DIR)/, $(COMMON_BENCH_VERILOG_SRC_FILTERED))

print-board-bench-src:
	$(Q)echo "\tBoard bench verilog source"; \
	echo $(BOARD_BENCH_VERILOG_SRC)

print-common-bench-src:
	$(Q)echo "\Common bench verilog source"; \
	echo $(COMMON_BENCH_VERILOG_SRC)

# Testbench source subdirectory detection (exclude include, we always use 
# board bench include directory!)
BOARD_BENCH_VERILOG_SUBDIRS=$(shell cd $(BOARD_BENCH_VERILOG_DIR) && ls -d */ | grep -v include)
COMMON_BENCH_VERILOG_SUBDIRS=$(shell cd $(COMMON_BENCH_VERILOG_DIR) && ls -d */ | grep -v include)

# Get rid of ones we have a copy of locally
COMMON_BENCH_VERILOG_SUBDIRS_EXCLUDE_BOARDS=$(filter-out $(BOARD_BENCH_VERILOG_SUBDIRS),$(COMMON_BENCH_VERILOG_SUBDIRS))

# Construct list of paths we will want to include
BENCH_VERILOG_SUBDIRS=$(addprefix $(COMMON_BENCH_VERILOG_DIR)/,$(COMMON_BENCH_VERILOG_SUBDIRS_EXCLUDE_BOARDS))
BENCH_VERILOG_SUBDIRS += $(addprefix $(BOARD_BENCH_VERILOG_DIR)/,$(BOARD_BENCH_VERILOG_SUBDIRS))

# Finally, add include path from local bench path
BENCH_VERILOG_SUBDIRS += $(BOARD_BENCH_VERILOG_DIR)/include

ifeq ($(VPI), 1)
# Manually add the VPI bench verilog path
COMMON_BENCH_VERILOG_SUBDIRS += $(VPI_SRC_VERILOG_DIR)
endif

print-board-bench-subdirs:
	$(Q)echo "\tBoard bench subdirectories"; \
	echo $(BOARD_BENCH_VERILOG_SUBDIRS)

print-common-bench-subdirs:
	$(Q)echo "\tCommon bench subdirectories"; \
	echo $(COMMON_BENCH_VERILOG_SUBDIRS)

print-bench-subdirs:
	$(Q)echo "\tBench subdirectories"; \
	echo $(BENCH_VERILOG_SUBDIRS)


# Backend technology library files
# We don't do this for the board backend stuff - that should all be properly 
# named, and so we only need to pass the "-y" option for that path.
BOARD_BACKEND_VERILOG_SRC=$(shell ls $(BOARD_BACKEND_VERILOG_DIR)/*.v )

#
# Compile script generation rules:
#

# Modelsim library compilation rules
#	$(Q)echo "-y " $(BOARD_BACKEND_VERILOG_DIR) >> $@;
# DUT compile script
modelsim_dut.scr: rtl $(RTL_VERILOG_SRC) $(RTL_VERILOG_INCLUDES) $(BOOTROM_VERILOG)
	$(Q)echo "+incdir+"$(BOARD_RTL_VERILOG_INCLUDE_DIR) > $@;
	$(Q)echo "+incdir+"$(BOARD_BOOTROM_SW_DIR) >> $@;
	$(Q)echo "+incdir+"$(BOARD_BENCH_VERILOG_INCLUDE_DIR) >> $@;
	$(Q)echo "+libext+.v" >> $@;
	$(Q)for module in $(BOARD_RTL_VERILOG_MODULES); do if [ -d $(BOARD_RTL_VERILOG_DIR)/$$module ]; then echo "-y " $(BOARD_RTL_VERILOG_DIR)/$$module >> $@; fi; done
	$(Q)for module in $(COMMON_RTL_VERILOG_MODULES); do if [ -d $(COMMON_RTL_VERILOG_DIR)/$$module ]; then echo "-y " $(COMMON_RTL_VERILOG_DIR)/$$module >> $@; fi; done
	$(Q)echo "-y "$(TECHNOLOGY_BACKEND_VERILOG_DIR)"/src/unisims" >> $@;
	$(Q)echo "-y "$(TECHNOLOGY_BACKEND_VERILOG_DIR)"/src/XilinxCoreLib" >> $@;
	$(Q)if [ ! -z "$$GATELEVEL_MODULES" ]; \
		then echo "-y " $(BOARD_SYN_OUT_DIR) >> $@; \
		echo "+libext+.vm" >> $@; \
	fi
	$(Q)echo >> $@

modelsim_bench.scr: $(BOARD_BENCH_VERILOG_SRC) $(COMMON_BENCH_VERILOG_SRC)
	$(Q)echo "+incdir+"$(BOARD_BENCH_VERILOG_INCLUDE_DIR) > $@;
	$(Q)echo "+incdir+"$(COMMON_BENCH_VERILOG_INCLUDE_DIR) >> $@;
	$(Q)for path in $(BENCH_VERILOG_SUBDIRS); do echo "+incdir+"$$path >> $@; done
	$(Q)for path in $(BENCH_VERILOG_SUBDIRS); do echo "-y "$$path >> $@; done
	$(Q)echo "+incdir+"$(BOARD_RTL_VERILOG_INCLUDE_DIR) >> $@;
	$(Q)echo "+libext+.v" >> $@;
	$(Q)echo "+incdir+"$(TECHNOLOGY_BACKEND_VERILOG_DIR)"/src" >> $@;
	$(Q)for vsrc in $(BOARD_BENCH_VERILOG_SRC); do echo $$vsrc >> $@; done
	$(Q)for vsrc in $(COMMON_BENCH_VERILOG_SRC); do echo $$vsrc >> $@; done
	$(Q)echo >> $@

# Modelsim library compilation rules

# Compile DUT into "work" library
work: modelsim_dut.scr
	$(Q)if [ ! -e $@ ]; then vlib $@; fi
	$(Q)echo; echo "\t### Compiling Verilog design library ###"; echo
	$(Q)vlog $(QUIET) -f $< $(DUT_TOP)
#	$(Q)echo; echo "\t### Compiling VHDL design library ###"; echo
#	$(Q)vcom -93 $(QUIET) $(RTL_VHDL_SRC)

# Single compile rule
.PHONY : $(MODELSIM)
$(MODELSIM): modelsim_bench.scr $(TEST_DEFINES_VLG) $(VPI_LIBS) work
	$(Q)echo; echo "\t### Compiling Xilinx support libs, user design & testbench ###"; echo
	$(Q)vlog $(QUIET) -nologo -incr $(BENCH_TOP) -f $<
	$(Q)vopt $(QUIET) glbl $(RTL_TESTBENCH_TOP) $(VOPT_ARGS) -o tb
	$(Q)echo; echo "\t### Launching simulation ###"; echo
	$(Q)vsim $(VSIM_ARGS) tb


.PHONY: rtl-test
rtl-test: clean-sim-test-sw sw-vmem clean-test-defines $(TEST_DEFINES_VLG) \
	$(SIMULATOR)

# Run an RTL test followed by checking of generated results
rtl-test-with-check: rtl-test
	$(Q)$(MAKE) check-test-log; \
	if [ $$? -ne 0 ]; then \
		echo; echo "\t### "$(TEST)" test FAIL ###"; echo; \
	else \
		echo; echo "\t### "$(TEST)" test OK ###"; echo; \
	fi

# Do check, don't print anything out
rtl-test-with-check-no-print: rtl-test check-test-log

# Main RTL test loop
rtl-tests:
	$(Q)for test in $(TESTS); do \
		export TEST=$$test; \
		$(MAKE) rtl-test-with-check-no-print; \
		if [ $$? -ne 0 ]; then break; fi; \
		echo; echo "\t### $$test test OK ###"; echo; \
	done


.PHONY: check-test-log
check-test-log:
	$(Q)echo "#!/bin/bash" > $@
	$(Q)echo "function check-test-log { if [ \`grep -c -i "$(TEST_OK_STRING)" "$(RTL_SIM_RESULTS_DIR)"/"$(TEST)$(TEST_OUT_FILE_SUFFIX)"\` -gt 0 ]; then return 0; else return 1; fi; }" >> $@
	$(Q)echo "check-test-log" >> $@
	$(Q)chmod +x $@
	$(Q) echo; echo "\t### Checking simulation results for "$(TEST)" test ###"; echo;
	$(Q)./$@

# Include the test-defines.v generation rule
include $(PROJECT_ROOT)/sim/bin/definesgen.inc

#
# Software make rules (called recursively)
#

# Path for the current test
# First check for a local copy of the test. If it doesn't exist then we
# default to the software tests in the root directory
TEST_MODULE=$(shell echo $(TEST) | cut -d "-" -f 1)
BOARD_SW_TEST_DIR=$(BOARD_SW_DIR)/tests/$(TEST_MODULE)/sim
COMMON_SW_TEST_DIR=$(COMMON_SW_DIR)/tests/$(TEST_MODULE)/sim
# Do this by testing for the file's existence 
TEST_SW_DIR=$(shell if [ -e $(BOARD_SW_TEST_DIR)/$(TEST).[cS] ]; then echo $(BOARD_SW_TEST_DIR); else echo $(COMMON_SW_TEST_DIR); fi)

print-test-sw-dir:
	@echo; echo "\tTest software is in the following path"; echo;
	@echo $(BOARD_SW_DIR); echo;
	@echo $(BOARD_SW_TEST_DIR); echo;
	@echo $(TEST_SW_DIR); echo;

print-sw-tests:
	$(Q) $(MAKE) -C $(COMMON_SW_DIR)/lib print-sw-tests
	$(Q) $(MAKE) -C $(COMMON_SW_DIR)/lib print-sw-tests-subdirs


# Name of the image the RAM model will attempt to load via Verilog $readmemh
# system function.

# Set PRELOAD_RAM=1 to preload the system memory - be sure the bootROM program
# chosen in board.h is the one booting from the reset vector.
ifeq ($(PRELOAD_RAM), 1)
SIM_DIR_VMEM_IMAGE ?=sram.vmem
else
SIM_DIR_VMEM_IMAGE ?=flash.in
endif

# Ability to bypass all stuffing around involved with generating software and
# directly specify an ELF
ifeq ($(USER_ELF),)
ELF_FILE=$(TEST_SW_DIR)/$(TEST).elf
else
ELF_FILE=$(USER_ELF)
ELF_FILE_NOTDIR=$(notdir $(USER_ELF))
ELF_FILE_NOTDIR_BASENAME=$(basename $(ELF_FILE_NOTDIR))
endif


# Rules allowing user to specify a pre-existing VMEM file to load into the 
# simulation, instead of compiling a test.
ifeq ($(USER_VMEM),)


ifeq ($(PRELOAD_RAM), 1)
VMEM_FILE ?= $(TEST_SW_DIR)/$(TEST).vmem
else
VMEM_FILE ?= $(TEST_SW_DIR)/$(TEST).flashin
endif
.PHONY: $(VMEM_FILE)


# If USER_ELF was specified, then we need a slightly different way of
# generating the VMEM file from it than a usual test
ifeq ($(USER_ELF),)
$(SIM_DIR_VMEM_IMAGE): $(VMEM_FILE)
	$(Q)if [ -L $@ ]; then unlink $@; fi
	$(Q)if [ -e $@ ]; then rm $@; fi
	$(Q)ln -s $< $@
else # !($(USER_ELF),) - USER_ELF set on command line
$(SIM_DIR_VMEM_IMAGE): $(USER_ELF)
	$(Q)$(MAKE) -C $(COMMON_SW_DIR)/lib \
	USER_ELF_BIN=`pwd`/$(ELF_FILE_NOTDIR_BASENAME).bin \
	USER_ELF_VMEM=`pwd`/$(ELF_FILE_NOTDIR_BASENAME).vmem \
	gen-user-elf-vmem
	$(Q)cp -v $(ELF_FILE_NOTDIR_BASENAME).vmem $@

TEST=$(ELF_FILE_NOTDIR_BASENAME)
endif

else # !($(USER_VMEM),) - USER_VMEM set on command line
VMEM_FILE=$(USER_VMEM)
USER_VMEM_NOTDIR=$(notdir $(USER_VMEM))
TEST=$(basename $(USER_VMEM_NOTDIR))

$(SIM_DIR_VMEM_IMAGE): $(VMEM_FILE)
	cp -v $< $@

endif


# Amount to pad the image we'll load into the SPI flash for ML501 sims
HEX_IMAGE_PADDING ?=0x1c0000

.PHONY : sw-vmem sw-elf
sw-vmem: $(SIM_DIR_VMEM_IMAGE)

.PHONY: $(TEST_SW_DIR)/$(TEST).flashin
$(TEST_SW_DIR)/$(TEST).flashin:
	$(Q) echo; echo "\t### Compiling software ###"; echo;
	$(Q)$(MAKE) -C $(TEST_SW_DIR) $(TEST).flashin \
		HEX_IMAGE_PADDING=$(HEX_IMAGE_PADDING)

.PHONY: $(TEST_SW_DIR)/$(TEST).vmem
$(TEST_SW_DIR)/$(TEST).vmem:
	$(Q) echo; echo "\t### Compiling software ###"; echo;
	$(Q)$(MAKE) -C $(TEST_SW_DIR) $(TEST).vmem

# Create test software disassembly

sw-dis: $(TEST_SW_DIR)/$(TEST).dis
	$(Q)cp -v $< .

$(TEST_SW_DIR)/$(TEST).dis:
	$(Q)$(MAKE) -C $(TEST_SW_DIR) $(TEST).dis

#
# Cleaning rules
#
clean: clean-sim clean-sim-test-sw clean-bootrom clean-out clean-sw

clean-sim:
	$(Q) echo; echo "\t### Cleaning simulation run directory ###"; echo;
	$(Q)rm -rf *.* lib_* work transcript check-test-log
	$(Q) if [ -e $(VPI_SRC_C_DIR) ]; then $(MAKE) -C $(VPI_SRC_C_DIR) clean; fi

clean-bootrom:
	$(MAKE) -C $(BOARD_BOOTROM_SW_DIR) clean

clean-out:
	$(Q)rm -rf $(RTL_SIM_RESULTS_DIR)/*.*

clean-test-defines:
	$(Q)rm -f $(TEST_DEFINES_VLG)

clean-sim-test-sw:
	$(Q)if [ -L $(SIM_DIR_VMEM_IMAGE) ]; then unlink $(SIM_DIR_VMEM_IMAGE); fi

clean-sw:
	$(Q) echo; echo "\t### Cleaning simulation sw directories ###"; echo;
	$(Q) $(MAKE) -C $(COMMON_SW_DIR)/lib distclean

clean-rtl:
	$(Q) echo; echo "\t### Cleaning generated verilog RTL ###"; echo;
	for module in $(RTL_TO_CHECK); do \
		$(MAKE) -C $(RTL_VERILOG_DIR)/$$module clean; \
	done

# Removes any checked out RTL
distclean: clean
	$(Q) echo; echo "\t### Cleaning generated verilog RTL ###"; echo;
	$(Q)for module in $(RTL_TO_CHECK); do \
		$(MAKE) -C $(RTL_VERILOG_DIR)/$$module distclean; \
	done
