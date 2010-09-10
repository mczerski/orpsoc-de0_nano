######################################################################
####                                                              ####
####  ORPSoCv2 Testbenches Makefile                               ####
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
PROJECT_ROOT ?=$(CUR_DIR)/../..

# Need this for individual test variables to not break
TEST ?= or1200-simple

TESTS ?= or1200-simple or1200-cbasic or1200-dctest or1200-float or1200-mmu or1200asm-basic or1200asm-except or1200asm-mac or1200asm-linkregtest or1200asm-tick or1200asm-ticksyscall uart-simple

DESIGN_NAME=orpsoc
RTL_TESTBENCH_TOP=$(DESIGN_NAME)_testbench

# Gets turned into verilog `define
SIM_TYPE=RTL

# Paths to other important parts of this test suite
RTL_DIR = $(PROJECT_ROOT)/rtl
RTL_VERILOG_DIR = $(RTL_DIR)/verilog
RTL_VERILOG_INCLUDE_DIR = $(RTL_VERILOG_DIR)/include
#RTL_VHDL_DIR = $(RTL_DIR)/vhdl

PROJECT_VERILOG_DEFINES=$(RTL_VERILOG_INCLUDE_DIR)/$(DESIGN_NAME)-defines.v
# Detect technology to use for the simulation
DESIGN_DEFINES=$(shell cat $(PROJECT_VERILOG_DEFINES) | sed s://.*::g | sed s:\`:\#:g | sed 's:^[ ]*::' | awk '{print};/^\#define/{printf "_%s=%s\n",$$2,$$2}' | grep -v PERIOD | cpp -P | sed s:^_::g | sed s:=$$::g )

# Rule to look at what defines are being extracted from main file
print-defines:
	@echo echo; echo "\t### Design defines ###"; echo
	@echo "\tParsing "$(PROJECT_VERILOG_DEFINES)" and exporting:"
	@echo $(DESIGN_DEFINES)


# Simulation directories
SIM_DIR ?=$(PROJECT_ROOT)/sim
RTL_SIM_DIR=$(SIM_DIR)
RTL_SIM_RUN_DIR=$(RTL_SIM_DIR)/run
RTL_SIM_BIN_DIR=$(RTL_SIM_DIR)/bin
RTL_SIM_SRC_DIR=$(RTL_SIM_DIR)/src
RTL_SIM_RESULTS_DIR=$(RTL_SIM_DIR)/out

# Testbench paths
BENCH_DIR=$(PROJECT_ROOT)/bench
BENCH_VERILOG_DIR=$(BENCH_DIR)/verilog
#BENCH_VHDL_DIR=$(BENCH_DIR)/vhdl

# System software dir
SW_DIR=$(PROJECT_ROOT)/sw
# BootROM code, which generates a verilog array select values
BOOTROM_FILE=bootrom.v
BOOTROM_SW_DIR=$(SW_DIR)/bootrom
BOOTROM_SRC=$(shell ls $(BOOTROM_SW_DIR)/* | grep -v $(BOOTROM_FILE))
BOOTROM_VERILOG=$(BOOTROM_SW_DIR)/$(BOOTROM_FILE)
$(BOOTROM_VERILOG): $(BOOTROM_SRC)
	$(Q)echo; echo "\t### Generating bootup ROM ###"; echo
	$(Q)$(MAKE) -C $(BOOTROM_SW_DIR) $(BOOTROM_FILE)

# Suffix of file to check after each test for the string
TEST_OUT_FILE_SUFFIX=-general.log
TEST_OK_STRING=8000000d

# Dynamically generated verilog file defining configuration for various things
TEST_DEFINES_VLG=test-defines.v
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

# Icarus variables
ICARUS_COMPILE=iverilog
ICARUS_RUN=vvp
ICARUS_SCRIPT=icarus.scr
ICARUS_SIM_EXE=vlogsim.elf
ICARUS=icarus

#Default simulator is Icarus Verilog
# Set SIMULATOR=modelsim to use Modelsim
# Set SIMULATOR=ncverilog to use Cadence's NC-Verilog - TODO
# Set SIMULATOR=icarus to use Icarus Verilog (Default)

SIMULATOR ?= $(ICARUS)


# VPI debugging interface variables
VPI_SRC_C_DIR=$(BENCH_VERILOG_DIR)/vpi/c
VPI_SRCS=$(shell ls $(VPI_SRC_C_DIR)/*.[ch])

# Modelsim VPI compile variables
MODELTECH_VPILIB=msim_jp_vpi.sl
# Icarus VPI compile target
ICARUS_VPILIB=jp_vpi



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
# Modelsim VPI settings
ifeq ($(VPI), 1)
VPI_LIBS=$(VPI_SRC_C_DIR)/$(MODELTECH_VPILIB)
VSIM_ARGS += -pli $(VPI_SRC_C_DIR)/$(MODELTECH_VPILIB)
endif
# Rule to make the VPI library for modelsim
$(VPI_SRC_C_DIR)/$(MODELTECH_VPILIB): $(VPI_SRCS)
	$(MAKE) -C $(VPI_SRC_C_DIR) $(MODELTECH_VPILIB)



#
# Icarus Verilog-specific settings
#

# Rule to make the VPI library for Icarus
$(VPI_SRC_C_DIR)/$(ICARUS_VPILIB): $(VPI_SRCS)
	$(MAKE) -C $(VPI_SRC_C_DIR) $(ICARUS_VPILIB)


#
# Verilog DUT source variables
#
# A list of paths under rtl/verilog we wish to exclude for module searching
VERILOG_MODULES_EXCLUDE=  include components
VERILOG_MODULES_EXCLUDE_LIST_E=$(shell for exclude in $(VERILOG_MODULES_EXCLUDE); do echo "-e $$exclude"; done)
RTL_VERILOG_MODULES=$(shell ls $(RTL_VERILOG_DIR) | grep -v $(VERILOG_MODULES_EXCLUDE_LIST_E) )
# Specific files to exclude, currently none.
#VERILOG_EXCLUDE=
#VERILOG_EXCLUDE_LIST_E=$(shell for exclude in $(VERILOG_EXCLUDE); do echo "-e $$exclude"; done)
# List of verilog source files, minus excluded files
#RTL_VERILOG_SRC=$(shell for module in $(RTL_VERILOG_MODULES); do if [ -d $(RTL_VERILOG_DIR)/$$module ]; then ls $(RTL_VERILOG_DIR)/$$module/*.v | grep -v $(VERILOG_EXCLUDE_LIST_E); fi; done)
# List of verilog source files, ignoring excludes
RTL_VERILOG_SRC=$(shell for module in $(RTL_VERILOG_MODULES); do if [ -d $(RTL_VERILOG_DIR)/$$module ]; then ls $(RTL_VERILOG_DIR)/$$module/*.v; fi; done)



# List of verilog includes
RTL_VERILOG_INCLUDES=$(shell ls $(RTL_VERILOG_INCLUDE_DIR)/*.*)

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


# Testbench verilog source
BENCH_VERILOG_SRC=$(shell ls $(BENCH_VERILOG_DIR)/*.v | grep -v define)

# Testbench source subdirectory detection
BENCH_VERILOG_SRC_SUBDIRS=$(shell for file in `ls $(BENCH_VERILOG_DIR)`; do if [ -d $(BENCH_VERILOG_DIR)/$$file ]; then echo $(BENCH_VERILOG_DIR)/$$file; fi; done)

# Compile script generation rules:

modelsim_dut.scr: rtl $(RTL_VERILOG_SRC) $(RTL_VERILOG_INCLUDES) $(BOOTROM_VERILOG)
	$(Q)echo "+incdir+"$(RTL_VERILOG_INCLUDE_DIR) > $@;
	$(Q)echo "+incdir+"$(RTL_SIM_SRC_DIR) >> $@;
	$(Q)echo "+incdir+"$(BOOTROM_SW_DIR) >> $@;
	$(Q)echo "+incdir+"$(BENCH_VERILOG_DIR) >> $@;
	$(Q)echo "+libext+.v" >> $@;
	$(Q)for module in $(RTL_VERILOG_MODULES); do if [ -d $(RTL_VERILOG_DIR)/$$module ]; then echo "-y " $(RTL_VERILOG_DIR)/$$module >> $@; fi; done
	$(Q)echo >> $@

modelsim_bench.scr: $(BENCH_VERILOG_SRC)
	$(Q)echo "+incdir+"$(BENCH_VERILOG_DIR) > $@;
	$(Q)for path in $(BENCH_VERILOG_SRC_SUBDIRS); do echo "+incdir+"$$path >> $@; done
	$(Q)for path in $(BENCH_VERILOG_SRC_SUBDIRS); do echo "-y "$$path >> $@; done
	$(Q)echo "+incdir+"$(RTL_VERILOG_INCLUDE_DIR) >> $@;
	$(Q)echo "+incdir+"$(RTL_SIM_SRC_DIR) >> $@;
	$(Q)echo "+libext+.v" >> $@;
	$(Q)echo "-y" $(RTL_SIM_SRC_DIR) >> $@;
	$(Q)for vsrc in $(BENCH_VERILOG_SRC); do echo $$vsrc >> $@; done
	$(Q)echo >> $@

# Compile DUT into "work" library
DUT_TOP=$(RTL_VERILOG_DIR)/$(DESIGN_NAME)_top/$(DESIGN_NAME)_top.v
work: modelsim_dut.scr #$(RTL_VHDL_SRC)
	$(Q)if [ ! -e $@ ]; then vlib $@; fi
#	$(Q)echo; echo "\t### Compiling VHDL design library ###"; echo
#	$(Q)vcom -93 $(QUIET) $(RTL_VHDL_SRC)
	$(Q)echo; echo "\t### Compiling Verilog design library ###"; echo
	$(Q)vlog $(QUIET) -f $< $(DUT_TOP)

# Single compile rule
.PHONY : $(MODELSIM)
$(MODELSIM): modelsim_bench.scr $(TEST_DEFINES_VLG) $(VPI_LIBS) work
	$(Q)echo; echo "\t### Compiling testbench ###"; echo
	$(Q)vlog $(QUIET) -nologo -incr $(BENCH_VERILOG_SRC) -f $<
	$(Q)vopt $(QUIET) $(RTL_TESTBENCH_TOP) $(VOPT_ARGS) -o tb
	$(Q)echo; echo "\t### Launching simulation ###"; echo
	$(Q)vsim $(VSIM_ARGS) tb


#
# Icarus Verilog simulator build and run rules
#
.PHONY: $(ICARUS_SCRIPT)
$(ICARUS_SCRIPT):  $(RTL_VERILOG_SRC) $(RTL_VERILOG_INCLUDES) $(BOOTROM_VERILOG) $(BENCH_VERILOG_SRC)
	$(Q)echo "# Icarus Verilog simulation script" > $@
	$(Q)echo "# Auto generated. Any alterations will be written over!" >> $@
	$(Q)echo "+incdir+"$(RTL_VERILOG_INCLUDE_DIR) > $@;
	$(Q)echo "+incdir+"$(RTL_SIM_SRC_DIR) >> $@;
	$(Q)echo "+incdir+"$(BENCH_VERILOG_DIR) >> $@;
	$(Q)echo "+incdir+"$(BOOTROM_SW_DIR) >> $@;        
	$(Q)for path in $(BENCH_VERILOG_SRC_SUBDIRS); do echo "+incdir+"$$path >> $@; done
	$(Q)for path in $(BENCH_VERILOG_SRC_SUBDIRS); do echo "-y "$$path >> $@; done
	$(Q)for module in $(RTL_VERILOG_MODULES); do echo "-y " $(RTL_VERILOG_DIR)/$$module >> $@; done
	$(Q)echo "-y" $(RTL_SIM_SRC_DIR) >> $@;
	$(Q)for vsrc in $(BENCH_VERILOG_SRC); do echo $$vsrc >> $@; done
	$(Q) echo >> $@

# Icarus design compilation rule
$(ICARUS_SIM_EXE): $(ICARUS_SCRIPT) $(TEST_DEFINES_VLG) 
	$(Q)echo; echo "\t### Compiling ###"; echo
	$(Q) $(ICARUS_COMPILE) -s$(RTL_TESTBENCH_TOP) -c $< -o $@

# Icarus simulation run rule
$(ICARUS): $(ICARUS_SIM_EXE) $(ICARUS_VPI_LIB)
	$(Q)echo; echo "\t### Launching simulation ###"; echo
	$(Q) $(ICARUS_RUN) $(ICARUS_VPI_ARGS) -l ../out/$(ICARUS_RUN).log $<



.PHONY: rtl-test
rtl-test: clean-sim-test-sw sw clean-test-defines $(TEST_DEFINES_VLG) \
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
.PHONY: rtl-tests
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


# Test defines.v file, called recursively, .PHONY to force its generation
.PHONY: $(TEST_DEFINES_VLG)
$(TEST_DEFINES_VLG):
	$(Q)echo "\`define "$(SIM_TYPE)"_SIM" > $@
	$(Q)echo "\`define SIMULATOR_"`echo $(SIMULATOR) | tr  "[:lower:]" "[:upper:]"` > $@
	$(Q)echo "\`define TEST_NAME_STRING \""$(TEST)"\"" >> $@
	$(Q)if [ ! -z $$VCD ]; \
		then echo "\`define VCD" >> $@; \
	fi
	$(Q)if [ ! -z $$VCD_DELAY ]; \
		then echo "\`define VCD_DELAY "$$VCD_DELAY >> $@; \
	fi
	$(Q)if [ ! -z $$VCD_DEPTH ]; \
		then echo "\`define VCD_DEPTH "$$VCD_DEPTH >> $@; \
	fi
	$(Q)if [ ! -z $$VCD_DELAY_INSNS ]; \
		then echo "\`define VCD_DELAY_INSNS "$$VCD_DELAY_INSNS >> $@; \
	fi
	$(Q)if [ ! -z $$END_TIME ]; \
		then echo "\`define END_TIME "$$END_TIME >> $@; \
	fi
	$(Q)if [ ! -z $$END_INSNS ]; \
		then echo "\`define END_INSNS "$$END_INSNS >> $@; \
	fi
	$(Q)if [ ! -z $$PRELOAD_RAM ]; \
		then echo "\`define PRELOAD_RAM "$$END_TIME >> $@; \
	fi
	$(Q)if [ -z $$NO_SIM_LOGGING ]; \
		then echo "\`define OR1200_DISPLAY_ARCH_STATE" >> $@; \
	fi
	$(Q)if [ ! -z $$VPI ]; \
		then echo "\`define VPI_DEBUG" >> $@; \
	fi
	$(Q)if [ ! -z $$SIM_QUIET ]; \
		then echo "\`define SIM_QUIET" >> $@; \
	fi


#	$(Q)for module in $(GATELEVEL_MODULES); do echo "\`define "$$module"_IS_GATELEVEL " >> $@; done
# More possible test defines go here


# Software make rules (called recursively)
TEST_SW_DIR=$(SW_DIR)/$(shell echo $(TEST) | cut -d "-" -f 1)

# Set PRELOAD_RAM=1 to preload the system memory, avoiding lengthy SPI FLASH 
# bootloader process.
#ifeq ($(PRELOAD_RAM), 1)
SIM_SW_IMAGE ?=sram.vmem
#else
#SIM_SW_IMAGE ?=flash.in
#endif

.PHONY : sw
sw: $(SIM_SW_IMAGE)

flash.in: $(TEST_SW_DIR)/$(TEST).flashin
	$(Q)if [ -L $@ ]; then unlink $@; fi
	$(Q)ln -s $< $@

sram.vmem: $(TEST_SW_DIR)/$(TEST).vmem
	$(Q)if [ -L $@ ]; then unlink $@; fi
	$(Q)ln -s $< $@

.PHONY: $(TEST_SW_DIR)/$(TEST).flashin
$(TEST_SW_DIR)/$(TEST).flashin:
	$(Q) echo; echo "\t### Compiling software ###"; echo;
	$(Q)$(MAKE) -C $(TEST_SW_DIR) $(TEST).flashin

.PHONY: $(TEST_SW_DIR)/$(TEST).vmem
$(TEST_SW_DIR)/$(TEST).vmem:
	$(Q) echo; echo "\t### Compiling software ###"; echo;
	$(Q)$(MAKE) -C $(TEST_SW_DIR) $(TEST).vmem

#
# Cleaning rules
#
clean: clean-sim clean-sim-test-sw clean-bootrom clean-out clean-sw

clean-sim:
	$(Q) echo; echo "\t### Cleaning simulation run directory ###"; echo;
	$(Q)rm -rf *.* lib_* work transcript check-test-log
	$(Q) if [ -e $(VPI_SRC_C_DIR) ]; then $(MAKE) -C $(VPI_SRC_C_DIR) clean; fi

clean-bootrom:
	$(MAKE) -C $(BOOTROM_SW_DIR) clean

clean-out:
	$(Q)rm -rf $(RTL_SIM_RESULTS_DIR)/*.*

clean-test-defines:
	$(Q)rm -f $(TEST_DEFINES_VLG)

clean-sim-test-sw:
	$(Q)if [ -e $(SIM_SW_IMAGE) ]; then unlink $(SIM_SW_IMAGE); fi

clean-sw:
	$(Q) echo; echo "\t### Cleaning simulation sw directories ###"; echo;
	$(Q) $(MAKE) -C $(SW_DIR)/support distclean

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
