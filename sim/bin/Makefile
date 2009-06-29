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
####	* Arrange verilator make rules so that the whole thing    ####
####	  isn't recompiled when a single SystemC module is 	  ####
####	  updated.						  ####
####	* Test if each software test file gets made properly	  ####
####	  before it's run in whatever model we're using           ####
####  	* Expand software test-suite (uClibc, ecos tests, LTP?)	  ####
####                                                              ####
####  Author(s):                                                  ####
####      - jb, jb@orsoc.se                                       ####
####                                                              ####
####                                                              ####
######################################################################
####                                                              ####
#### Copyright (C) 2009 Authors and OPENCORES.ORG                 ####
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

# Usage: 
#
# 	make rtl-tests
#
#	Run the software tests in the RTL model of the ORPSoC being 
#	simulated with an event-driven simulator like Icarus. Also 
#	possible to use Cadence's Verilog simulators with the 
#	"rtl-nc-tests" target.
#
#	make vlt-tests
#	
#	Run all the software tests in the RTL model which has been
#	converted into a cycle-accurate SystemC model with Verilator.
#
#	make sim-tests
#	
#	Run all the software tests in the architectural simulator
#
#
# Debugging modes:
#	
#	make rtl-debug
#
#	Enable a GDB stub integrated into the simulation via VPI. This will
#	start a simulation, then the GDB server, and allow the user to connect
#	using the OpenRISC GDB port. It should provide the same functionality
#	as GDB to a physical target, although a little slower.
#	It is provided here as an example of how to compile and run an OpenRISC
#	model at RTL level with support for debugging from GDB.
#	UART output from printf() is enabled by default. The model loads with
# 	the dhrystone test running as default, but can be changed by defining
#	VPI_TEST_SW at the command line. Logging of the processor's execution
#	is also disabled by default to speed up simulation.
#	

# Simulation results:
#
# The results and output of the event-driven simulations are in the 
# results path, in parallel to the simulation run and bin paths.

# Specific tests:
#
# To run an individual test, specify it in the variable TESTS when 
# calling make, eg:
#
#	 make rtl-tests TESTS="mmu-nocache mul-idcd-O2"

# UART printf:
#
# It is possible to enable printf to the console via the UART when 
# running the event-driven simulators. To do this define UART_PRINTF=1
# when calling make. The SystemC cycle-acccurate model uses this by
# default.
# Also note when switching between runs with and without UART printf
# enabled, run a clean-sw so the library files are recompiled when
# the tests are run - this is not done automatically.

# VCDs:
#
# VCD (value change dumps, usable in a waveform viewer, such as gtkwave
# to inspect the internals of the system graphically) files can be
# generated by defining a variable VCD, eg. 
#
#	make rtl-tests VCD=1
#
# and a dump file will be created in the simulation results directory, 
# and named according to the test run which generated it. This is 
# possible for both event-driven and cycle-accurate simulations.
# However the cycle-accurate

# NO_SIM_LOGGING:
#
# It is possible to speed up the event-driven simulation slightly by 
# disabling log output of the processor's state to files by defining 
# NO_SIM_LOGGING, eg: 
#
#	make rtl-tests TESTS=except-icdc NO_SIM_LOGGING=1
#

# Cleaning:
# A simple "make clean" cleans everything - software and all temporary
# simulation files and directories. To clean just the software run:
#
#	make clean-sw
#
# and to clean just the temporary simulation files (including VCDs, 
# results logs - everything under, and including, sim/results/, run
#
#	make clean-sim
#

# Note:
# 
# The way each of the test loops is written is probably a bit overly complex
# but this is to save maintaining, and calling, multiple files.
# 

# Model configuration:
#
# Currently, the ORPSoCv2, by default, contains an internal SRAM (configurable
# size - check the defparam in rtl/verilog/orpsoc_top.v), standard OR1200 (check
# the config in rtl/verilog/or1200_defines.v) and UART.
# Switches can be passed to enable certain parts of the design if testing with
# these is desired.
#
# SDRAM and controller
#
# To enable the use of SDRAM, define USE_SDRAM when calling the sim -this
# only has an effect in the event-driven simulators as the external SDRAM model
# is not availble in SystemC format. eg:
#
#	make rtl-tests USE_SDRAM=1
#
# This not only enables SDRAM but also enables the booting from external SPI
# interfaced flash memory. This causes significant increase in the time taken
# for simulation as the program to test is first loaded out of SPI flash memory
# and into SDRAM before it is executed. Although this more closely mimics the
# behaviour of the hardware, for simulation purposes it is purely time-consuming
# however it may be useful to track down any problems with this boot-loading
# process. Therefore, becuase it enables SDRAM memory, it also enables the flash
# memory model and SPI controller inside ORPSoC.
#
# Ethernet
#
# Ethernet is disabled by default. This is due to the fact that it is not
# supported in the verilator/systemC model. Also, there is currently no software
# which tests it in any meaningful way.
#

# 
# Event-driven simulation compilation
#
# The way the event-driven simulations are compiled is simply using the 
# configuration script file in this directory, currently called icarus.scr - 
# however it is first processesed to replace the variables, beginning with $'s,
# with the appropriate paths. Instead of naming each file to be compiled, the
# paths to be searched for each module are instead defined ( -y paths), and
# only the toplevel testbench and library source files are explicitly named.
# This simplifies the script, and also requires that the name of each verilog
# source file is the same as the module it contains (a good convention
# regardless.) In addition to the script/command file, defines are passed to
# the compiler via the command line in the EVENT_SIM_FLAGS variable.
# Additionally, a source file, test_define.v, is created with  some defines
# that cannot be passed to the compiled reliably (there are differences between
# the way, for instance, icarus and ncverilog parse strings +define+'d on the
# command line). This file is then included at the appropriate places.
# It is probably not ideal that the entire design be re-compiled for each test,
# but currently the design is small enough so that this doesn't cause a
# significant overhead, unlike the cycle-accurate model compile time.
#

#
# SystemC cycle-accurate model compilation
#
# A new addition to ORPSoC v2 is the cycle-accurate model. The primary enabler
# behind this is verilator, which processes the RTL sources and generates a c++
# description of the system. This c++ description is then compiled with a
# SystemC wrapper. Finally a top-level SystemC testbench instantiates the
# model, as well as any other modules - in this case a reset generation, UART
# decoder, and monitor module are included at the top level. These additional
# modules and models are written in SystemC and compiled all together with the
# cycle-accurate ORPSoC model to create the simulation executable. Finally this
# executable is run and should be a cycle-representation of the system. VCDs
# can be generated if enabled. The compiled mentioned above is all done with
# the GNU c++ compiler, g++.
# The compilation process is a little more tricky than a typical even-driven
# simulator. It proceeds basically by generating the makefiles for compiling
# the design with verilator, running these makes which produces a library
# containing the cycle-accurate ORPSoC design, compiling the additional
# top-level, and testbench, systemC models into a library, and then linking it
# all together into the simulation executable.
# The major advantage of the cycle-accurate model is that it is quicker, in
# terms of simulated cycles/second, when compared with event-driven simulators.
# It is, of course, less accurate in that it cannot model propegation delays.
# However this is usually not an issue for simulating a design which is known
# to synthesize and run OK. It is very useful for running complex software,
# such as the linux kernel and real-time OS applications, which generally
# require long simulation times. 
# Currently the cycle-accurate model being used doesn't contain much more than
# the processor and a UART, however it's exepected in future this will be
# expanded on and more complex software test suites will be implemented to put
# the system through its paces.
#


# Name of
# the directory we're currently in
CUR_DIR=$(shell pwd)

# The root path of the whole project
PROJECT_ROOT=$(CUR_DIR)/../..

# Tests is only defined if it wasn't already defined when make was called
# This is the default list of every test that is currently possible
TESTS ?= basic-nocache cbasic-nocache-O2 dhry-nocache-O2 except-nocache mmu-nocache mul-nocache-O2 syscall-nocache tick-nocache uart-nocache basic-icdc cbasic-icdc-O2 dhry-icdc-O2 except-icdc mmu-icdc mul-icdc-O2 syscall-icdc tick-icdc uart-icdc

# Paths to other important parts of this test suite
SIM_DIR=$(PROJECT_ROOT)/sim
SIM_RUN_DIR=$(SIM_DIR)/run
SIM_BIN_DIR=$(SIM_DIR)/bin
SIM_RESULTS_DIR=$(SIM_DIR)/results
SIM_VLT_DIR=$(SIM_DIR)/vlt
BENCH_DIR=$(PROJECT_ROOT)/bench
BACKEND_DIR=$(PROJECT_ROOT)/backend
BENCH_VERILOG_DIR=$(BENCH_DIR)/verilog
BENCH_SYSC_DIR=$(BENCH_DIR)/sysc
BENCH_SYSC_SRC_DIR=$(BENCH_SYSC_DIR)/src
BENCH_SYSC_INCLUDE_DIR=$(BENCH_SYSC_DIR)/include
RTL_VERILOG_DIR=$(PROJECT_ROOT)/rtl/verilog
SW_DIR=$(PROJECT_ROOT)/sw

ICARUS=iverilog
ICARUS_VVP=vvp
ICARUS_COMMAND_FILE=icarus.scr
VLT_COMMAND_FILE=verilator.scr
SIM_SUCCESS_MESSAGE=deaddead

ARCH_SIM_EXE=or32-elf-sim
ARCH_SIM_CFG_FILE=or1ksim-orpsocv2.cfg

# If USE_SDRAM is defined we'll add it to the simulator's defines on the 
# command line becuase it's used by many different modules and it's easier 
# to do it this way than make them all include a file.
ifdef USE_SDRAM
EVENT_SIM_FLAGS += "-D USE_SDRAM=$(USE_SDRAM)"
endif

# Enable ethernet if defined on the command line
ifdef USE_ETHERNET
EVENT_SIM_FLAGS += "-D USE_ETHERNET=$(USE_ETHERNET)"
endif

SIM_FLASH_MEM_FILE="flash.in"
FLASH_MEM_FILE_SUFFIX="-twobyte-sizefirst.hex"
SIM_SRAM_MEM_FILE="sram.vmem"

TESTS_PASSED=0
TESTS_PERFORMED=0;

################################################################################
# Event-driven simulator build rules (Icarus, NCSim)
################################################################################

.PHONY: prepare_rtl
prepare_rtl:
	@cd $(RTL_VERILOG_DIR)/components/wb_sdram_ctrl && perl fizzim.pl -encoding onehot -terse < wb_sdram_ctrl_fsm.fzm > wb_sdram_ctrl_fsm.v
	@cd $(RTL_VERILOG_DIR) && sed '/defparam/!s/\([a-zA-Z0-9_]\)\.//g' intercon.vm > intercon.v


ifdef UART_PRINTF
TEST_SW_MAKE_OPTS=UART_PRINTF=1
endif

.PHONY: prepare_sw
prepare_sw:
	@$(MAKE) -C $(SW_DIR)/support all $(TEST_SW_MAKE_OPTS)
	@$(MAKE) -C $(SW_DIR)/utils all

# A rule with UART_PRINTF hard defined ... used by verilator make sw
prepare_sw_uart_printf:
	@$(MAKE) -C $(SW_DIR)/support all UART_PRINTF=1 $(TEST_SW_MAKE_OPTS)
	@$(MAKE) -C $(SW_DIR)/utils all

prepare_dirs:
	@if [ ! -d $(SIM_RESULTS_DIR) ]; then mkdir -p $(SIM_RESULTS_DIR); fi

# Rough guide to how these tests work:
# First, the couple of custom, required, software tools under sw/utils are 
# compiled, and then the software library files.
# Next the few verilog files that need preperation are taken care of.
# The test begins by starting a loop in bash using on the strings defined in 
# TESTS. Each one corresponds to a certain module of software for the OpenRISC 
# that is included in this test suite. Under the sw/ path is a set of paths, 
# and all except the support/ and utils/ paths contain code which is run to 
# test the OR1k used in this test suite. For each of these software modules, 
# it is possible that different tests are done using the same module. These 
# tests can vary by either using different levels of optimisation during 
# compilation, and/or by having the OR1k's caches enabled or disabled.
# Each test has a unique name, and under the $(SIM_RESULTS_DIR), which is 
# usually just ../results, log files, and optionally VCD files, are created for
# inspection later and are named according to the test. Inspect the file 
# bench/verilog/or1200_monitor.v to find out in detail what each log consists 
# of.
# For each test, a few things occur. First the software that will run inside 
# the simulated OR1k system is compiled, converted to a format which can be 
# read
# into the flash memory model via $readmemh() and linked to the sim/run 
# directory as $(SIM_FLASH_MEM_FILE), which currently is flash.in. Next a 
# compilation script for icarus is generated, containing a list of all the
# RTL files and include directories. Next, an include file for the verilog 
# testbench is generated, containing a string of the name of the current 
# test, path to the results directory (for VCD generation) and any other 
# things which might vary from test to test. This is not done by +define 
# lines in the icarus script because of string handling incosistencies 
# between different simulators and shells.
# Once all the files are generated, icarus is called to compile the rtl 
# design, and then run it. Each of the tested software modules have code which
# will trigger the simulation to be stopped by use of the l.nop instruction 
# with an immediate value of 1. When the simulation finishes, the simulation 
# executable exits and the log of the simulation is inspected for the expected
# output. Currently, the string "deaddead" indicates that the software 
# completed successfully. This is counted as the ORPSoC "passing" the test. In
# fact, whether the system did the right thing or not requires more 
# inspection, but roughly this is a good indicator that nothing major went 
# wrong.
# Once the current test is finished, the next begins with the compilation of its
# software and linking of the resulting hex file to the run path, etc.
# Main RAM setup - (RTL simulation with Icarus/NCSim only!):
# Define USE_SDRAM to enable the external SDRAM, otherwise the simulation
# defaults to an internal SRAM. Eg. $ make rtl-tests USE_SDRAM=1 VCD=1
# Verilator defaults to internal memories
rtl-tests: prepare_sw_uart_printf prepare_rtl prepare_dirs
	@echo
	@echo "Beginning loop that will complete the following tests: $(TESTS)"
	@echo
	@for TEST in $(TESTS); do \
		echo "################################################################################"; \
		echo; \
		echo "\t#### Current test: $$TEST ####"; echo; \
		echo "\t#### Compiling software ####"; echo; \
		CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $$TEST | cut -d "-" -f 1`; \
		$(MAKE) -C $$CURRENT_TEST_SW_DIR $$TEST $(TEST_SW_MAKE_OPTS); \
		rm -f $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
		rm -f $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		ln -s $$CURRENT_TEST_SW_DIR/$$TEST$(FLASH_MEM_FILE_SUFFIX) $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
		ln -s $$CURRENT_TEST_SW_DIR/$$TEST.vmem $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		sed < $(SIM_BIN_DIR)/$(ICARUS_COMMAND_FILE) > $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated \
			-e s!\$$BENCH_DIR!$(BENCH_VERILOG_DIR)!              \
			-e s!\$$RTL_DIR!$(RTL_VERILOG_DIR)!                  \
			-e s!\$$BACKEND_DIR!$(BACKEND_DIR)!                  \
			-e \\!^//.*\$$!d -e \\!^\$$!d ; \
		echo "+define+TEST_DEFINE_FILE=\"test_define.v\"" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; \
		if [ ! -z $$VCD ]; \
			then echo "+define+VCD" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; \
		fi; \
		if [ ! -z $$UART_PRINTF ]; \
			then echo "+define+UART_PRINTF" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; \
		fi; \
		echo "\`define TEST_NAME_STRING \"$$TEST\"" > $(SIM_RUN_DIR)/test_define.v; \
		echo "\`define TEST_RESULTS_DIR \"$(SIM_RESULTS_DIR)/\" " >> $(SIM_RUN_DIR)/test_define.v; \
		if [ -z $$NO_SIM_LOGGING ]; then \
			echo "\`define OR1200_DISPLAY_ARCH_STATE" >> $(SIM_RUN_DIR)/test_define.v; \
		fi; \
		echo ; \
		echo "\t#### Compiling RTL ####"; \
		rm -f $(SIM_RUN_DIR)/a.out; \
		$(ICARUS) -sorpsoc_testbench -c $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated $(EVENT_SIM_FLAGS); \
		echo; \
		echo "\t#### Beginning simulation ####"; \
		time -p $(ICARUS_VVP) -l $(SIM_RESULTS_DIR)/$$TEST-vvp-out.log a.out ; \
		if [ $$? -gt 0 ]; then exit $$?; fi; \
		TEST_RESULT=`cat $(SIM_RESULTS_DIR)/$$TEST-general.log | grep report | grep $(SIM_SUCCESS_MESSAGE) -c`; \
		echo; echo "\t####"; \
		if [ $$TEST_RESULT -gt 0 ]; then \
			echo "\t#### Test $$TEST PASSED ####";TESTS_PASSED=`expr $$TESTS_PASSED + 1`;\
		else    echo "\t#### Test $$TEST FAILED ####";\
		fi; \
		echo "\t####"; echo; \
		TESTS_PERFORMED=`expr $$TESTS_PERFORMED + 1`;\
	done; \
	echo "Test results: "$$TESTS_PASSED" out of "$$TESTS_PERFORMED" tests passed"; echo



# Use NCSIM instead of icarus
rtl-nc-tests: prepare_sw prepare_rtl prepare_dirs
	@echo
	@echo "Beginning loop that will complete the following tests: $(TESTS)"
	@echo
	@for TEST in $(TESTS); do \
		echo "################################################################################"; \
		echo; \
		echo "\t#### Current test: $$TEST ####"; echo; \
		echo "\t#### Compiling software ####"; echo; \
		CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $$TEST | cut -d "-" -f 1`; \
		$(MAKE) -C $$CURRENT_TEST_SW_DIR $$TEST; \
		rm -f $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
		rm -f $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		ln -s $$CURRENT_TEST_SW_DIR/$$TEST_twobyte_sizefirst.hex $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
		ln -s $$CURRENT_TEST_SW_DIR/$$TEST_fourbyte.hex $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		sed < $(SIM_BIN_DIR)/$(ICARUS_COMMAND_FILE) > $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated \
			-e s!\$$BENCH_DIR!$(BENCH_VERILOG_DIR)!              \
			-e s!\$$RTL_DIR!$(RTL_VERILOG_DIR)!                  \
			-e s!\$$BACKEND_DIR!$(BACKEND_DIR)!                  \
			-e \\!^//.*\$$!d -e \\!^\$$!d ; \
		echo "+define+TEST_DEFINE_FILE=\"test_define.v\"" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; \
		if [ ! -z $$VCD ]; \
			then echo "+define+VCD" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; \
			echo "+access+r" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; \
		fi; \
		if [ ! -z $$UART_PRINTF ]; \
			then echo "+define+UART_PRINTF" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; \
		fi; \
		if [ ! -z $$USE_SDRAM ]; then \
			echo "\`define USE_SDRAM" >> $(SIM_RUN_DIR)/test_define.v; \
		fi; \
		echo "+nocopyright" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; \
		echo "+nowarn+MACRDF" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; \
		echo "\`define TEST_NAME_STRING \"$$TEST\"" > $(SIM_RUN_DIR)/test_define.v; \
		echo "\`define TEST_RESULTS_DIR \"$(SIM_RESULTS_DIR)/\" " >> $(SIM_RUN_DIR)/test_define.v; \
		if [ -z $$NO_SIM_LOGGING ]; then \
			echo "\`define OR1200_DISPLAY_ARCH_STATE" >> $(SIM_RUN_DIR)/test_define.v; \
		fi; \
		echo ; \
		echo "\t#### Beginning simulation ####"; \
		time -p ncverilog -f $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated -Q -l $(SIM_RESULTS_DIR)/$$TEST-ius-out.log $(EVENT_SIM_FLAGS); \
		if [ $$? -gt 0 ]; then exit $$?; fi; \
		TEST_RESULT=`cat $(SIM_RESULTS_DIR)/$$TEST-general.log | grep report | grep $(SIM_SUCCESS_MESSAGE) -c`; \
		echo; echo "\t####"; \
		if [ $$TEST_RESULT -gt 0 ]; then \
			echo "\t#### Test $$TEST PASSED ####";TESTS_PASSED=`expr $$TESTS_PASSED + 1`;\
		else    echo "\t#### Test $$TEST FAILED ####";\
		fi; \
		echo "\t####"; echo; \
		TESTS_PERFORMED=`expr $$TESTS_PERFORMED + 1`;\
	done; \
	echo "Test results: "$$TESTS_PASSED" out of "$$TESTS_PERFORMED" tests passed"; echo

################################################################################
# RTL simulation in Icarus with GDB stub via VPI for debugging
################################################################################
# This compiles a version of the system which starts up the dhrystone nocache
# test, and launches the simulator with a VPI module that provides a GDB stub
# allowing the OpenRISC compatible GDB to connect and debug the system.
# The launched test can be changed by defining VPI_TEST_SW on the make line
VPI_DIR=$(BENCH_VERILOG_DIR)/vpi
VPI_C_DIR=$(VPI_DIR)/c
VPI_VERILOG_DIR=$(VPI_DIR)/verilog
VPI_LIB_NAME=jp_vpi
ICARUS_VPI_OPTS=-M$(VPI_C_DIR) -m$(VPI_LIB_NAME)
VPI_TEST_SW ?= dhry-nocache-O2

prepare_vpi:
## Build the VPI library
	$(MAKE) -C $(VPI_C_DIR) $(VPI_LIB_NAME)

clean_vpi:
	$(MAKE) -C $(VPI_C_DIR) clean

rtl-debug: prepare_sw_uart_printf prepare_rtl prepare_vpi prepare_dirs
## Prepare the software for the test
	@echo "\t#### Compiling software ####"; echo; \
	CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $(VPI_TEST_SW) | cut -d "-" -f 1`; \
	$(MAKE) -C $$CURRENT_TEST_SW_DIR $(VPI_TEST_SW) $(TEST_SW_MAKE_OPTS); \
	rm -f $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
	rm -f $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
	ln -s $$CURRENT_TEST_SW_DIR/$(VPI_TEST_SW)$(FLASH_MEM_FILE_SUFFIX) $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
	ln -s $$CURRENT_TEST_SW_DIR/$(VPI_TEST_SW).vmem $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE)
## Generate the icarus script we'll compile with
	@sed < $(SIM_BIN_DIR)/$(ICARUS_COMMAND_FILE) > $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated \
		-e s!\$$BENCH_DIR!$(BENCH_VERILOG_DIR)!              \
		-e s!\$$RTL_DIR!$(RTL_VERILOG_DIR)!                  \
		-e s!\$$BACKEND_DIR!$(BACKEND_DIR)!                  \
		-e \\!^//.*\$$!d -e \\!^\$$!d 
## Add a couple of extra defines to the icarus compile script
	@echo "+define+TEST_DEFINE_FILE=\"test_define.v\"" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated
## The define that enables the VPI debug module
	@echo "+define+VPI_DEBUG_ENABLE" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated
	@if [ ! -z $$VCD ];then echo "+define+VCD" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated;fi
## Unless NO_UART_PRINTF=1 we use printf via the UART
	@if [ -z $$NO_UART_PRINTF ];then echo "+define+UART_PRINTF" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; fi
	@echo "\`define TEST_NAME_STRING \"$(VPI_TEST_SW)-vpi\"" > $(SIM_RUN_DIR)/test_define.v
	@echo "\`define TEST_RESULTS_DIR \"$(SIM_RESULTS_DIR)/\" " >> $(SIM_RUN_DIR)/test_define.v
	@if [ -z $$NO_SIM_LOGGING ]; then echo "\`define OR1200_DISPLAY_ARCH_STATE" >> $(SIM_RUN_DIR)/test_define.v; fi
	@echo
	@echo "\t#### Compiling RTL ####"
	@rm -f $(SIM_RUN_DIR)/a.out
	@$(ICARUS) -sorpsoc_testbench -c $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated $(EVENT_SIM_FLAGS)
	@echo
	@echo "\t#### Beginning simulation with VPI debug module enabled ####"; echo
	@$(ICARUS_VVP) $(ICARUS_VPI_OPTS) -l $(SIM_RESULTS_DIR)/$(VPI_TEST_SW)-vvp-out.log a.out

################################################################################
# Verilator model build rules
################################################################################


SYSC_LIB_ARCH_DIR=$(shell ls $$SYSTEMC | grep "lib-")


# List of System C models - use this list to link the sources into the Verilator
# build directory
SYSC_MODELS=OrpsocAccess TraceSC

ifdef VCD
VLT_FLAGS +=-trace
endif

# Only need the trace target if we are tracing
ifneq (,$(findstring -trace, $(VLT_FLAGS)))
VLT_TRACEOBJ = SpTraceVcdC
endif

# This is the list of extra models we'll issue make commands for
# Included is the SystemPerl trace model
SYSC_MODELS_BUILD=$(SYSC_MODELS) $(VLT_TRACEOBJ)

prepare_vlt: prepare_rtl vlt_model_links $(SIM_VLT_DIR)/Vorpsoc_top

$(SIM_VLT_DIR)/Vorpsoc_top: $(SIM_VLT_DIR)/libVorpsoc_top.a $(SIM_VLT_DIR)/OrpsocMain.o
# Final linking of the simulation executable. Order of libraries here is important!
	@echo; echo "\tGenerating simulation executable"; echo
	cd $(SIM_VLT_DIR) && g++ -I$(BENCH_SYSC_INCLUDE_DIR) -I$(SIM_VLT_DIR) -I$(VERILATOR_ROOT)/include -I$(SYSTEMC)/include -o Vorpsoc_top -L. -L$(BENCH_SYSC_SRC_DIR) -L$(SYSTEMC)/$(SYSC_LIB_ARCH_DIR) OrpsocMain.o -lVorpsoc_top -lmodules -lsystemc

$(SIM_VLT_DIR)/OrpsocMain.o:
# Now compile the top level systemC "testbench" module
	@echo; echo "\tCompiling top level SystemC testbench"; echo
	cd $(SIM_VLT_DIR) && g++ -I$(BENCH_SYSC_INCLUDE_DIR) -I$(SIM_VLT_DIR) -I$(VERILATOR_ROOT)/include -I$(SYSTEMC)/include -c $(BENCH_SYSC_SRC_DIR)/OrpsocMain.cpp

$(SIM_VLT_DIR)/libVorpsoc_top.a: $(SIM_VLT_DIR)/Vorpsoc_top__ALL.a vlt_modules_compile $(SIM_VLT_DIR)/verilated.o
# Now archive all of the libraries from verilator witht he other modules we might have
	@echo; echo "\tArchiving libraries into libVorpsoc_top.a"; echo
	@cd $(SIM_VLT_DIR) && \
	cp Vorpsoc_top__ALL.a libVorpsoc_top.a && \
	ar rcs libVorpsoc_top.a verilated.o; \
	for SYSCMODEL in $(SYSC_MODELS_BUILD); do \
		ar rcs libVorpsoc_top.a $$SYSCMODEL.o; \
	done

$(SIM_VLT_DIR)/verilated.o:
	@echo; echo "\tCompiling verilated.o"; echo
	@cd $(SIM_VLT_DIR) && \
	$(MAKE) -f Vorpsoc_top.mk verilated.o

.PHONY: vlt_modules_compile
vlt_modules_compile:
# Compile the module files
	@echo; echo "\tCompiling SystemC models"
	@cd $(SIM_VLT_DIR) && \
	for SYSCMODEL in $(SYSC_MODELS_BUILD); do \
		echo;echo "\t$$SYSCMODEL"; echo; \
		$(MAKE) -f Vorpsoc_top.mk $$SYSCMODEL.o; \
	done

$(SIM_VLT_DIR)/Vorpsoc_top__ALL.a: $(SIM_VLT_DIR)/Vorpsoc_top.mk
	@echo; echo "\tCompiling main design"; echo
	@cd $(SIM_VLT_DIR) && \
	$(MAKE) -f Vorpsoc_top.mk Vorpsoc_top__ALL.a

$(SIM_VLT_DIR)/Vorpsoc_top.mk: $(SIM_VLT_DIR)/$(VLT_COMMAND_FILE).generated $(SIM_VLT_DIR)/libmodules.a 
# Now call verilator to generate the .mk files
	@echo; echo "\tGenerating makefiles with Verilator"; echo
	cd $(SIM_VLT_DIR) && \
	verilator -language 1364-2001 -Wno-lint --top-module orpsoc_top -Mdir . -sc $(VLT_FLAGS) -I$(BENCH_SYSC_INCLUDE_DIR) -I$(BENCH_SYSC_SRC_DIR) -f $(VLT_COMMAND_FILE).generated

# SystemC modules library
$(SIM_VLT_DIR)/libmodules.a:
	@echo; echo "\tCompiling SystemC modules"; echo
	@$(MAKE) -C $(BENCH_SYSC_SRC_DIR) -f $(BENCH_SYSC_SRC_DIR)/Modules.make


# Verilator command script
# Generate the compile script to give Verilator
$(SIM_VLT_DIR)/$(VLT_COMMAND_FILE).generated:
	@echo; echo "\tGenerating verilator compile script"; echo
	@sed < $(SIM_BIN_DIR)/$(VLT_COMMAND_FILE) > $(SIM_VLT_DIR)/$(VLT_COMMAND_FILE).generated \
		-e s!\$$BENCH_DIR!$(BENCH_VERILOG_DIR)!              \
		-e s!\$$RTL_DIR!$(RTL_VERILOG_DIR)!                  \
		-e s!\$$BACKEND_DIR!$(BACKEND_DIR)!                  \
		-e \\!^//.*\$$!d -e \\!^\$$!d;

.PHONY: vlt_model_links
vlt_model_links:
# Link all the required system C model files into the verilator work dir
	@echo; echo "\tLinking SystemC model source to verilator build path"; echo
	@if [ ! -d $(SIM_VLT_DIR) ]; then mkdir $(SIM_VLT_DIR); fi
	@cd $(SIM_VLT_DIR) && \
	for SYSCMODEL in $(SYSC_MODELS); do \
		if [ ! -e $$SYSCMODEL.cpp ]; then \
			ln -s $(BENCH_SYSC_SRC_DIR)/$$SYSCMODEL.cpp .; \
			ln -s $(BENCH_SYSC_INCLUDE_DIR)/$$SYSCMODEL.h .; \
		fi; \
	done


################################################################################
# Verilator test loop
################################################################################

# Verilator defaults to internal memories
vlt-tests: prepare_sw_uart_printf prepare_rtl prepare_dirs prepare_vlt
	@echo
	@echo "Beginning loop that will complete the following tests: $(TESTS)"
	@echo
	@for TEST in $(TESTS); do \
		echo "################################################################################"; \
		echo; \
		echo "\t#### Current test: $$TEST ####"; echo; \
		echo "\t#### Compiling software ####"; echo; \
		CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $$TEST | cut -d "-" -f 1`; \
		$(MAKE) -C $$CURRENT_TEST_SW_DIR $$TEST $(TEST_SW_MAKE_OPTS) UART_PRINTF=1; \
		rm -f $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		ln -s $$CURRENT_TEST_SW_DIR/$$TEST.vmem $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		echo "\t#### Beginning simulation ####"; \
		time -p $(SIM_VLT_DIR)/Vorpsoc_top $$TEST; \
		if [ $$? -gt 0 ]; then exit $$?; fi; \
		TEST_RESULT=1; \
		echo; echo "\t####"; \
		if [ $$TEST_RESULT -gt 0 ]; then \
			echo "\t#### Test $$TEST PASSED ####";TESTS_PASSED=`expr $$TESTS_PASSED + 1`;\
		else    echo "\t#### Test $$TEST FAILED ####";\
		fi; \
		echo "\t####"; echo; \
		TESTS_PERFORMED=`expr $$TESTS_PERFORMED + 1`;\
	done; \
	echo "Test results: "$$TESTS_PASSED" out of "$$TESTS_PERFORMED" tests passed"; echo



################################################################################
# Architectural simulator test loop
################################################################################

# Verilator defaults to internal memories
sim-tests: prepare_sw_uart_printf
	@if [ ! -d $(SIM_RESULTS_DIR) ]; then mkdir -p $(SIM_RESULTS_DIR); fi
	@echo
	@echo "Beginning loop that will complete the following tests: $(TESTS)"
	@echo
	@for TEST in $(TESTS); do \
		echo "################################################################################"; \
		echo; \
		echo "\t#### Current test: $$TEST ####"; echo; \
		echo "\t#### Compiling software ####"; echo; \
		CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $$TEST | cut -d "-" -f 1`; \
		$(MAKE) -C $$CURRENT_TEST_SW_DIR $$TEST $(TEST_SW_MAKE_OPTS) UART_PRINTF=1; \
		rm -f $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		ln -s $$CURRENT_TEST_SW_DIR/$$TEST.or32 $(SIM_RUN_DIR)/.; \
		echo;echo "\t#### Launching architectural simulator ####"; \
		time -p $(ARCH_SIM_EXE) --nosrv -f $(SIM_BIN_DIR)/$(ARCH_SIM_CFG_FILE) $$TEST.or32 > $(SIM_RESULTS_DIR)/$$TEST-or1ksim.log 2>&1; \
		if [ $$? -gt 0 ]; then exit $$?; fi; \
		if [ `tail -n 10 $(SIM_RESULTS_DIR)/$$TEST-or1ksim.log | grep -c $(SIM_SUCCESS_MESSAGE)` -gt 0 ]; then \
			TEST_RESULT=1; \
		fi; \
		echo; echo "\t####"; \
		if [ $$TEST_RESULT -gt 0 ]; then \
			echo "\t#### Test $$TEST PASSED ####";TESTS_PASSED=`expr $$TESTS_PASSED + 1`;\
		else    echo "\t#### Test $$TEST FAILED ####";\
		fi; \
		echo "\t####"; echo; \
		TESTS_PERFORMED=`expr $$TESTS_PERFORMED + 1`;\
		unlink $(SIM_RUN_DIR)/$$TEST.or32; \
	done; \
	echo "Test results: "$$TESTS_PASSED" out of "$$TESTS_PERFORMED" tests passed"; echo



################################################################################
# Cleaning rules
################################################################################

clean: clean-sw clean-sim clean-sysc clean-rtl clean_vpi

clean-sw:
	@for TEST in $(TESTS); do \
		echo "Current test: $$TEST"; \
		CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $$TEST | cut -d "-" -f 1`; \
		echo "Current test sw directory: " $$CURRENT_TEST_SW_DIR; \
		$(MAKE) -C $$CURRENT_TEST_SW_DIR clean; \
	done
	$(MAKE) -C $(SW_DIR)/support clean
	$(MAKE) -C $(SW_DIR)/utils clean

clean-sim:
	rm -rf $(SIM_RESULTS_DIR) $(SIM_RUN_DIR)/*.* $(SIM_VLT_DIR)

clean-sysc:
# Clean away dependency files generated by verilator
	$(MAKE) -C $(BENCH_SYSC_SRC_DIR) -f $(BENCH_SYSC_SRC_DIR)/Modules.make clean

clean-rtl:
# Clean away temporary verilog source files
	rm -f $(RTL_VERILOG_DIR)/intercon.v
	rm -f $(RTL_VERILOG_DIR)/components/wb_sdram_ctrl/wb_sdram_ctrl_fsm.v