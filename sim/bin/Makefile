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
####	* Test if each software test file gets made properly	  ####
####	  before it's run in whatever model we're using           ####
####  	* Expand software test-suite (uClibc, ecos tests, LTP?)	  ####
####                                                              ####
####  Author(s):                                                  ####
####      - Julius Baxter, julius.baxter@orsoc.se                 ####
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

# Usage: 
#
# 	make rtl-tests
#
#	Run the software tests in the RTL model of the ORPSoC being 
#	simulated with an event-driven simulator like Icarus. It's also 
#	possible to use Modelsim's vsim and Cadence's Verilog simulators.
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
# behind this is verilator, which processes the RTL source and generates a c++
# description of the system. This c++ description is then compiled, with a
# SystemC wrapper. Finally a top-level SystemC testbench instantiates the
# model, and other useful modules - in this case a reset generation, UART
# decoder, and monitor module are included at the top level. These additional
# modules and models are written in SystemC. Finally, everything is linked with
# the cycle-accurate ORPSoC model to create the simulation executable. This
# executable is the cycle-representation of the system. 
#
# Run the resulting executable with the -h switch for usage.
#
# The compilation is all done with the GNU c++ compiler, g++.
#
# The compilation process is a little more complicated than the event-driven
# simulator. It proceeds basically by generating the makefiles for compiling
# the design with verilator, running these makes which produces a library
# containing the cycle-accurate ORPSoC design, compiling the additional
# top-level, and testbench, systemC models into a library, and then linking it
# all together into the simulation executable.
#
# The major advantage of the cycle-accurate model is that it is quicker, in
# terms of simulated cycles/second, when compared with event-driven simulators.
# It is, of course, less accurate in that it cannot model propegation delays.
# However this is usually not an issue for simulating a design which is known
# to synthesize and run OK. It is very useful for running complex software,
# such as the linux kernel and real-time OS applications, which generally
# result in long simulation times. 
#
# Currently the cycle-accurate model being used doesn't contain much more than
# the processor and a UART, however it's exepected in future this will be
# expanded on and more complex software test suites will be implemented to put
# the system through its paces.
#
# 
# 

# Name of the directory we're currently in
CUR_DIR=$(shell pwd)

# The root path of the whole project
PROJECT_ROOT ?=$(CUR_DIR)/../..

# Tests is only defined if it wasn't already defined when make was called
# This is the default list of every test that is currently possible

TESTS ?= or1200-simple or1200-cbasic or1200-dctest or1200-float or1200-mmu or1200asm-basic or1200asm-except or1200asm-linkregtest or1200asm-tick or1200asm-ticksyscall uart-simple
#basic-nocache cbasic-nocache-O2 dhry-nocache-O2 except-nocache mmu-nocache mul-nocache-O2 syscall-nocache tick-nocache uart-nocache basic-icdc cbasic-icdc-O2 dhry-icdc-O2 except-icdc mmu-icdc mul-icdc-O2 syscall-icdc tick-icdc uart-icdc

# Paths to other important parts of this test suite
SIM_DIR ?=$(PROJECT_ROOT)/sim
SIM_RUN_DIR=$(SIM_DIR)/run
SIM_BIN_DIR=$(SIM_DIR)/bin
SIM_RESULTS_DIR=$(SIM_DIR)/results
SIM_VLT_DIR=$(SIM_DIR)/vlt
BENCH_DIR=$(PROJECT_ROOT)/bench
BACKEND_DIR ?=$(PROJECT_ROOT)/backend
BENCH_VERILOG_DIR=$(BENCH_DIR)/verilog
BENCH_TOP_VERILOG_DIR ?= $(BENCH_DIR)/verilog
BENCH_SYSC_DIR=$(BENCH_DIR)/sysc
BENCH_SYSC_SRC_DIR=$(BENCH_SYSC_DIR)/src
BENCH_SYSC_INCLUDE_DIR=$(BENCH_SYSC_DIR)/include
RTL_VERILOG_DIR=$(PROJECT_ROOT)/rtl/verilog
SW_DIR=$(PROJECT_ROOT)/sw

ICARUS=iverilog
ICARUS_VVP=vvp
VSIM_COMP=vlog
VSIM=vsim
NCVERILOG=ncverilog
SILOS=silos
ICARUS_COMMAND_FILE=icarus.scr
VLT_COMMAND_FILE=verilator.scr
SIM_SUCCESS_MESSAGE=8000000d
MGC_COMMAND_FILE=modelsim.scr

ARCH_SIM_EXE=or32-elf-sim
ARCH_SIM_CFG_FILE=or1ksim-orpsocv2.cfg

# Set V=1 when calling make to enable verbose output
# mainly for debugging purposes.
ifeq ($(V), 1)
Q=
else
Q=@
endif

# If USE_SDRAM is defined we'll add it to the simulator's defines on the 
# command line becuase it's used by many different modules and it's easier 
# to do it this way than make them all include a file.
ifdef USE_SDRAM
EVENT_SIM_FLAGS +=USE_SDRAM=$(USE_SDRAM)
endif

# Enable ethernet if defined on the command line
ifdef USE_ETHERNET
EVENT_SIM_FLAGS +=USE_ETHERNET=$(USE_ETHERNET) USE_ETHERNET_IO=$(USE_ETHERNET)
# Extra tests we do if ethernet is enabled
TESTS += eth-basic eth-int
endif

DASH_D_EVENT_SIM_FLAGS=$(shell for flag in $(EVENT_SIM_FLAGS); do echo "-D "$$flag; done)
PLUS_DEFINE_EVENT_SIM_FLAGS=$(shell for flag in $(EVENT_SIM_FLAGS); do echo "+define+"$$flag; done)

#Default simulator is Icarus Verilog
# Set SIMULATOR=vsim to use Modelsim
# Set SIMULATOR=ncverilog to use Cadence's NC-Verilog
SIMULATOR ?= $(ICARUS)

# Set the command file to use, simulator dependent
ifeq ($(SIMULATOR), $(ICARUS))
# Icarus Verilog Simulator
SIM_COMMANDFILE=$(ICARUS_COMMAND_FILE)
endif

ifeq ($(SIMULATOR), $(VSIM))
# Modelsim has own command file (it's a little more stupid than Icarus & NC)
SIM_COMMANDFILE=$(MGC_COMMAND_FILE)
endif

ifeq ($(SIMULATOR), $(NCVERILOG))
# NCVerilog uses same command file as Icarus
SIM_COMMANDFILE=$(ICARUS_COMMAND_FILE)
endif

ifeq ($(SIMULATOR), $(SILOS))
# SILOS uses same command file as Icarus (this should be default)
SIM_COMMANDFILE=$(ICARUS_COMMAND_FILE)
endif


GENERATED_COMMANDFILE=$(SIM_COMMANDFILE).generated

# When Modelsim is selected as simulator, we compile
# the ORPSoC system into one library called orpsoc and
# then simply re-compile the testbench and or1200_monitor
# whenever we run the simulation, so just that part is
# recompiled for every test, instead of the whole thing.
MGC_ORPSOC_LIB=orpsoc
MGC_ORPSOC_LIB_DIR=$(SIM_RUN_DIR)/$(MGC_ORPSOC_LIB)

# If VCD dump is desired, tell Modelsim not to optimise
# away everything.
ifeq ($(VCD), 1)
VOPT_ARGS=-voptargs="+acc=rnp"
endif

# RTL testbench toplevel name
RTL_TESTBENCH_TOP ?= orpsoc_testbench

# Simulation compile and run commands, depending on your 
# simulator. 

# Icarus Verilog
ifeq ($(SIMULATOR), $(ICARUS))
# Icarus Verilog Simulator compile and run commands
SIM_COMMANDCOMPILE=rm -f $(SIM_RUN_DIR)/rtlsim.elf; $(ICARUS) -s$(RTL_TESTBENCH_TOP) -c $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE) -o rtlsim.elf $(DASH_D_EVENT_SIM_FLAGS)
# Icarus Verilog run command
SIM_COMMANDRUN=$(ICARUS_VVP) -l $(SIM_RESULTS_DIR)/$$TEST-vvp-out.log rtlsim.elf
endif

# Modelsim
ifeq ($(SIMULATOR), $(VSIM))
# Line to compile the orpsoc design into a modelsim library.
SIM_COMMANDCOMPILE=if [ ! -e work ]; then vlib work; vlib $(MGC_ORPSOC_LIB); vlog -work $(MGC_ORPSOC_LIB) -f $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE) $(PLUS_DEFINE_EVENT_SIM_FLAGS); fi
# Final modelsim compile, done each time, pulling in or1200 
# monitor and the new test_defines.v file:
VSIM_COMPILE_TB=vlog +incdir+. +incdir+$(BENCH_VERILOG_DIR) -y $(BENCH_VERILOG_DIR) +libext+.v +incdir+$(BENCH_TOP_VERILOG_DIR) +incdir+$(RTL_VERILOG_DIR) +define+TEST_DEFINE_FILE $(PLUS_DEFINE_EVENT_SIM_FLAGS) $(BENCH_TOP_VERILOG_DIR)/$(RTL_TESTBENCH_TOP).v
# Simulation run command:
SIM_COMMANDRUN=$(VSIM_COMPILE_TB); $(VSIM) -c -quiet +nowarnTFMPC -L $(MGC_ORPSOC_LIB) $(VOPT_ARGS) -do "run -all; exit" $(RTL_TESTBENCH_TOP) 
endif

# NCVerilog
ifeq ($(SIMULATOR), $(NCVERILOG))
SIM_COMMANDCOMPILE=echo
SIM_COMMANDRUN=$(NCVERILOG) -f $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE) -Q -l $(SIM_RESULTS_DIR)/$$TEST-$(NCVERILOG)-out.log $(EVENT_SIM_FLAGS)
endif

# Silos
ifeq ($(SIMULATOR), $(SILOS))
SIM_COMMANDCOMPILE=echo
SIM_COMMANDRUN=$(SILOS) -b -w +width_mistmatches -f $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE) -l $(SIM_RESULTS_DIR)/$$TEST-$(SILOS)-out.log $(EVENT_SIM_FLAGS)
endif


# Names of memory files used in simulation
SIM_FLASH_MEM_FILE="flash.in"
FLASH_MEM_FILE_SUFFIX="-twobyte-sizefirst.hex"
SIM_SRAM_MEM_FILE="sram.vmem"

TESTS_PASSED=0
TESTS_PERFORMED=0;

################################################################################
# Event-driven simulator build rules
################################################################################

$(RTL_VERILOG_DIR)/components/wb_sdram_ctrl/wb_sdram_ctrl_fsm.v:
	@cd $(RTL_VERILOG_DIR)/components/wb_sdram_ctrl && perl fizzim.pl -encoding onehot -terse < wb_sdram_ctrl_fsm.fzm > wb_sdram_ctrl_fsm.v	

.PHONY: prepare-rtl
prepare-rtl: $(RTL_VERILOG_DIR)/components/wb_sdram_ctrl/wb_sdram_ctrl_fsm.v

$(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE): $(SIM_BIN_DIR)/$(SIM_COMMANDFILE)
	$(Q)sed < $(SIM_BIN_DIR)/$(SIM_COMMANDFILE) > $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE) \
		-e s!\$$BENCH_DIR!$(BENCH_VERILOG_DIR)!              \
		-e s!\$$RTL_DIR!$(RTL_VERILOG_DIR)!                  \
		-e s!\$$BACKEND_DIR!$(BACKEND_DIR)!                  \
		-e \\!^//.*\$$!d -e \\!^\$$!d ; \
	echo "+define+TEST_DEFINE_FILE=\"test_define.v\"" >> $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE); \
	if [ ! -z $$VCD ]; \
		then echo "+define+VCD" >> $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE); \
		if [ $(SIMULATOR) = $(NCVERILOG) ]; \
			then echo "+access+r" >> $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE); \
		fi; \
	fi; \
	if [ ! -z $$UART_PRINTF ]; \
		then echo "+define+UART_PRINTF" >> $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE); \
	fi; \
	if [ $(SIMULATOR) = $(NCVERILOG) ]; \
		then echo "+nocopyright" >> $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE); \
		echo "+nowarn+MACRDF" >> $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE); \
	fi

ifdef UART_PRINTF
TEST_SW_MAKE_OPTS="UART_PRINTF=1"
endif

.PHONY: prepare-sw
prepare-sw:
	$(Q)$(MAKE) -C $(SW_DIR)/support all $(TEST_SW_MAKE_OPTS)
	$(Q)$(MAKE) -C $(SW_DIR)/utils all

# A rule with UART_PRINTF hard defined ... used by verilator make sw
prepare-sw-uart-printf:
	$(Q)$(MAKE) -C $(SW_DIR)/support all UART_PRINTF=1 $(TEST_SW_MAKE_OPTS)
	$(Q)$(MAKE) -C $(SW_DIR)/utils all

prepare-dirs:
	$(Q)if [ ! -d $(SIM_RESULTS_DIR) ]; then mkdir -p $(SIM_RESULTS_DIR); fi

#
# Rough guide to how event driven simulation test loop works:
#
# 1. Compile software support programs.
# 2. Generate RTL compilation script file
# 3. For each test listed in $(TESTS), loop and 
#	a) Compile software
#       b) Create appropriate image to be loaded into sim
# 	c) Create a verilog file to be included by top level
#	d) Compile the RTL design
#       e) Run the RTL design in the chosen simulator
#       f) Check the output (files in ../results)
#
# Default setup is: 
#	* Event-driven simulation with Icarus Verilog
#	* Internal SRAM memory, preloaded with application
#	* Ethernet disabled
#	* VCD generation disabled
#	* printf() via UART disabled
#	* Logging enabled
#
# Options:
#	SIMULATOR=vsim
#		Use Mentor Graphics Modelsim simulator
#	SIMULATOR=ncverilog
#		Use Cadence's NC-Verilog
#	USE_SDRAM=1	
#		Enable use of SDRAM - changes boot sequence and takes
#		a lot longer due to application being loaded out of
#		external FLASH memory and into SDRAM before execution
#		from the SDRAM.
#	VCD=1
#		Enable VCD generation. These files are output to
#		../results
#	USE_ETHERNET=1
#		Turns on ethernet core inclusion. There are currently
#		some tests, but not included by default. Check the sw
#		directory
#	UART_PRINTF=1
#		Make the software use the UART core to print out 
#		printf() calls.
#	NO_SIM_LOGGING=1
#		Turn off generation of logging files in the ../results
#		directory.
#
rtl-tests: $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE) prepare-sw prepare-rtl prepare-dirs
	@echo
	@echo "Beginning loop that will complete the following tests: $(TESTS)"
	@echo
	$(Q)for TEST in $(TESTS); do \
		echo "################################################################################"; \
		echo; \
		echo "\t#### Current test: $$TEST ####"; echo; \
		echo "\t#### Compiling software ####"; echo; \
		CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $$TEST | cut -d "-" -f 1`; \
		$(MAKE) -C $$CURRENT_TEST_SW_DIR $$TEST.vmem $(TEST_SW_MAKE_OPTS); \
		rm -f $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
		rm -f $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		ln -s $$CURRENT_TEST_SW_DIR/$$TEST$(FLASH_MEM_FILE_SUFFIX) $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
		ln -s $$CURRENT_TEST_SW_DIR/$$TEST.vmem $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		echo "\`define TEST_NAME_STRING \"$$TEST\"" > $(SIM_RUN_DIR)/test_define.v; \
		echo "\`define TEST_RESULTS_DIR \"$(SIM_RESULTS_DIR)/\" " >> $(SIM_RUN_DIR)/test_define.v; \
		if [ ! -z $$VCD ]; \
			then echo "\`define VCD" >> $(SIM_RUN_DIR)/test_define.v; \
		fi; \
		if [ ! -z $$UART_PRINTF ]; \
			then echo "\`define UART_PRINTF" >> $(SIM_RUN_DIR)/test_define.v; \
		fi; \
		if echo $$TEST | grep -q -i ^eth; then \
			echo "\`define ENABLE_ETH_STIM" >> $(SIM_RUN_DIR)/test_define.v; \
			echo "\`define ETH_PHY_VERBOSE" >> $(SIM_RUN_DIR)/test_define.v; \
		fi; \
		if [ -z $$NO_SIM_LOGGING ]; then \
			echo "\`define OR1200_DISPLAY_ARCH_STATE" >> $(SIM_RUN_DIR)/test_define.v; \
		fi; \
		echo ; \
		echo "\t#### Compiling RTL ####"; \
		$(SIM_COMMANDCOMPILE); \
		echo; \
		echo "\t#### Beginning simulation ####"; \
		time -p $(SIM_COMMANDRUN) ; \
		if [ "$$SIMULATOR" != "$$SILOS" ]; then if [ $$? -gt 0 ]; then exit $$?; fi; fi; \
		TEST_RESULT=`cat $(SIM_RESULTS_DIR)/$$TEST-general.log | grep $(SIM_SUCCESS_MESSAGE) -c`; \
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

prepare-vpi:
## Build the VPI library
	$(MAKE) -C $(VPI_C_DIR) $(VPI_LIB_NAME)

clean-vpi:
	$(MAKE) -C $(VPI_C_DIR) clean

rtl-debug: prepare-sw-uart-printf prepare-rtl prepare-vpi prepare-dirs
## Prepare the software for the test
	@echo "\t#### Compiling software ####"; echo; \
	CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $(VPI_TEST_SW) | cut -d "-" -f 1`; \
	$(MAKE) -C $$CURRENT_TEST_SW_DIR $(VPI_TEST_SW) $(TEST_SW_MAKE_OPTS); \
	rm -f $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
	rm -f $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
	ln -s $$CURRENT_TEST_SW_DIR/$(VPI_TEST_SW)$(FLASH_MEM_FILE_SUFFIX) $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
	ln -s $$CURRENT_TEST_SW_DIR/$(VPI_TEST_SW).vmem $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE)
## Generate the icarus script we'll compile with
	$(Q)sed < $(SIM_BIN_DIR)/$(ICARUS_COMMAND_FILE) > $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated \
		-e s!\$$BENCH_DIR!$(BENCH_VERILOG_DIR)!              \
		-e s!\$$RTL_DIR!$(RTL_VERILOG_DIR)!                  \
		-e s!\$$BACKEND_DIR!$(BACKEND_DIR)!                  \
		-e \\!^//.*\$$!d -e \\!^\$$!d 
## Add a couple of extra defines to the icarus compile script
	$(Q)echo "+define+TEST_DEFINE_FILE=\"test_define.v\"" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated
## The define that enables the VPI debug module
	$(Q)echo "+define+VPI_DEBUG_ENABLE" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated
	$(Q)if [ ! -z $$VCD ];then echo "+define+VCD" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated;fi
## Unless NO_UART_PRINTF=1 we use printf via the UART
	$(Q)if [ -z $$NO_UART_PRINTF ];then echo "+define+UART_PRINTF" >> $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated; fi
	$(Q)echo "\`define TEST_NAME_STRING \"$(VPI_TEST_SW)-vpi\"" > $(SIM_RUN_DIR)/test_define.v
	$(Q)echo "\`define TEST_RESULTS_DIR \"$(SIM_RESULTS_DIR)/\" " >> $(SIM_RUN_DIR)/test_define.v
	$(Q)if [ -z $$NO_SIM_LOGGING ]; then echo "\`define OR1200_DISPLAY_ARCH_STATE" >> $(SIM_RUN_DIR)/test_define.v; fi
	@echo
	@echo "\t#### Compiling RTL ####"
	$(Q)rm -f $(SIM_RUN_DIR)/rtlsim.elf
	$(Q)$(ICARUS) -s$(RTL_TESTBENCH_TOP) -c $(SIM_RUN_DIR)/$(ICARUS_COMMAND_FILE).generated -o rtlsim.elf $(EVENT_SIM_FLAGS)
	@echo
	@echo "\t#### Beginning simulation with VPI debug module enabled ####"; echo
	$(Q)$(ICARUS_VVP) $(ICARUS_VPI_OPTS) -l $(SIM_RESULTS_DIR)/$(VPI_TEST_SW)-vvp-out.log rtlsim.elf

################################################################################
# Verilator model build rules
################################################################################


SYSC_LIB_ARCH_DIR=$(shell ls $$SYSTEMC | grep "lib-")


# List of System C models - use this list to link the sources into the Verilator
# build directory
SYSC_MODELS=OrpsocAccess MemoryLoad

ifdef VLT_DEBUG
VLT_DEBUG_COMPILE_FLAGS = -g
# Enabling the following generates a TON of debugging
# when running verilator. Not so helpful.
#VLT_DEBUG_OPTIONS = --debug --dump-tree
VLT_SYSC_DEBUG_DEFINE = VLT_DEBUG=1
endif

# If set on the command line we build the cycle accurate model which will generate verilator-specific profiling information. This is useful for checking the efficiency of the model - not really useful for checking code or the function of the model.
ifdef VLT_ORPSOC_PROFILING
VLT_CPPFLAGS +=-pg
VLT_DEBUG_OPTIONS +=-profile-cfuncs
else
VLT_CPPFLAGS +=-fprofile-use -Wcoverage-mismatch
#VLT_CPPFLAGS=-Wall
endif

# Set VLT_IN_GDB=1 when making if going to run the cycle accurate model executable in GDB to check suspect behavior. This also removes optimisation.
ifdef VLT_IN_GDB
VLT_CPPFLAGS +=-g -O0 
else
# The default optimisation flag applied to all of the cycle accurate model files
VLT_CPPFLAGS +=-O3
endif

ifdef VLT_DO_PROFILING
VLT_CPPFLAGS +=-ftest-coverage -fprofile-arcs -fprofile-generate 
endif

# VCD Enabled by default when building, enable it at runtime
#ifdef VCD
VLT_FLAGS +=-trace
TRACE_FLAGS=-DVM_TRACE=1 -I${SYSTEMPERL}/src
#endif

# Only need the trace target if we are tracing
#ifneq (,$(findstring -trace, $(VLT_FLAGS)))
VLT_TRACEOBJ = verilated_vcd_c
#endif

# This is the list of extra models we'll issue make commands for
# Included is the SystemPerl trace model
SYSC_MODELS_BUILD=$(SYSC_MODELS) $(VLT_TRACEOBJ)

prepare-vlt: prepare-rtl vlt-model-links $(SIM_VLT_DIR)/Vorpsoc_top
	@echo;echo "\tCycle-accurate model compiled successfully"
	@echo;echo "\tRun the executable with the -h option for usage instructions:";echo
	$(SIM_VLT_DIR)/Vorpsoc_top -h
	@echo;echo

$(SIM_VLT_DIR)/Vorpsoc_top: $(SIM_VLT_DIR)/libVorpsoc_top.a $(SIM_VLT_DIR)/OrpsocMain.o
# Final linking of the simulation executable. Order of libraries here is important!
	@echo; echo "\tGenerating simulation executable"; echo
	cd $(SIM_VLT_DIR) && g++ $(VLT_DEBUG_COMPILE_FLAGS) $(VLT_CPPFLAGS) -I$(BENCH_SYSC_INCLUDE_DIR) -I$(SIM_VLT_DIR) -I$(VERILATOR_ROOT)/include -I$(SYSTEMC)/include -o Vorpsoc_top -L. -L$(BENCH_SYSC_SRC_DIR) -L$(SYSTEMC)/$(SYSC_LIB_ARCH_DIR) OrpsocMain.o -lVorpsoc_top -lmodules -lsystemc

# Now compile the top level systemC "testbench" module from the systemC source path
$(SIM_VLT_DIR)/OrpsocMain.o: $(BENCH_SYSC_SRC_DIR)/OrpsocMain.cpp
	@echo; echo "\tCompiling top level SystemC testbench"; echo
	cd $(SIM_VLT_DIR) && g++ $(VLT_DEBUG_COMPILE_FLAGS) $(VLT_CPPFLAGS) $(TRACE_FLAGS) -I$(BENCH_SYSC_INCLUDE_DIR) -I$(SIM_VLT_DIR) -I$(VERILATOR_ROOT)/include -I$(SYSTEMC)/include -c $(BENCH_SYSC_SRC_DIR)/OrpsocMain.cpp 

$(SIM_VLT_DIR)/libVorpsoc_top.a: $(SIM_VLT_DIR)/Vorpsoc_top__ALL.a vlt-modules-compile $(SIM_VLT_DIR)/verilated.o
# Now archive all of the libraries from verilator witht he other modules we might have
	@echo; echo "\tArchiving libraries into libVorpsoc_top.a"; echo
	$(Q)cd $(SIM_VLT_DIR) && \
	cp Vorpsoc_top__ALL.a libVorpsoc_top.a && \
	ar rcs libVorpsoc_top.a verilated.o; \
	for SYSCMODEL in $(SYSC_MODELS_BUILD); do \
		ar rcs libVorpsoc_top.a $$SYSCMODEL.o; \
	done

$(SIM_VLT_DIR)/verilated.o:
	@echo; echo "\tCompiling verilated.o"; echo
	$(Q)cd $(SIM_VLT_DIR) && \
	export CXXFLAGS=$(VLT_DEBUG_COMPILE_FLAGS); \
	export USER_CPPFLAGS="$(VLT_CPPFLAGS)"; \
	export USER_LDDFLAGS="$(VLT_CPPFLAGS)"; \
	$(MAKE) -f Vorpsoc_top.mk verilated.o

.PHONY: vlt-modules-compile
vlt-modules-compile:
# Compile the module files
	@echo; echo "\tCompiling SystemC models"
	$(Q)cd $(SIM_VLT_DIR) && \
	for SYSCMODEL in $(SYSC_MODELS_BUILD); do \
		echo;echo "\t$$SYSCMODEL"; echo; \
		export CXXFLAGS=$(VLT_DEBUG_COMPILE_FLAGS); \
		export USER_CPPFLAGS="$(VLT_CPPFLAGS) -I$(BENCH_SYSC_INCLUDE_DIR)"; \
		export USER_LDDFLAGS="$(VLT_CPPFLAGS)"; \
		 $(MAKE) -f Vorpsoc_top.mk $$SYSCMODEL.o; \
	done	

$(SIM_VLT_DIR)/Vorpsoc_top__ALL.a: $(SIM_VLT_DIR)/Vorpsoc_top.mk
	@echo; echo "\tCompiling main design"; echo
	$(Q)cd $(SIM_VLT_DIR) && \
	export USER_CPPFLAGS="$(VLT_CPPFLAGS)"; \
	export USER_LDDFLAGS="$(VLT_CPPFLAGS)"; \
	$(MAKE) -f Vorpsoc_top.mk Vorpsoc_top__ALL.a

$(SIM_VLT_DIR)/Vorpsoc_top.mk: $(SIM_VLT_DIR)/$(VLT_COMMAND_FILE).generated $(SIM_VLT_DIR)/libmodules.a 
# Now call verilator to generate the .mk files
	@echo; echo "\tGenerating makefiles with Verilator"; echo
	cd $(SIM_VLT_DIR) && \
	verilator -language 1364-2001 -Wno-lint --top-module orpsoc_top $(VLT_DEBUG_OPTIONS) -Mdir . -sc $(VLT_FLAGS) -I$(BENCH_SYSC_INCLUDE_DIR) -I$(BENCH_SYSC_SRC_DIR) -f $(VLT_COMMAND_FILE).generated

# SystemC modules library
$(SIM_VLT_DIR)/libmodules.a:
	@echo; echo "\tCompiling SystemC modules"; echo
	$(Q)export VLT_CPPFLAGS="$(VLT_CPPFLAGS)"; \
	$(MAKE) -C $(BENCH_SYSC_SRC_DIR) -f $(BENCH_SYSC_SRC_DIR)/Modules.make $(VLT_SYSC_DEBUG_DEFINE) 


ALL_VLOG=$(shell find $(RTL_VERILOG_DIR) -name "*.v")

# Verilator command script
# Generate the compile script to give Verilator - make it sensitive to the RTL
$(SIM_VLT_DIR)/$(VLT_COMMAND_FILE).generated: $(ALL_VLOG)
	@echo; echo "\tGenerating verilator compile script"; echo
	$(Q)sed < $(SIM_BIN_DIR)/$(VLT_COMMAND_FILE) > $(SIM_VLT_DIR)/$(VLT_COMMAND_FILE).generated \
		-e s!\$$BENCH_DIR!$(BENCH_VERILOG_DIR)!              \
		-e s!\$$RTL_DIR!$(RTL_VERILOG_DIR)!                  \
		-e s!\$$BACKEND_DIR!$(BACKEND_DIR)!                  \
		-e \\!^//.*\$$!d -e \\!^\$$!d;

.PHONY: vlt-model-links
vlt-model-links:
# Link all the required system C model files into the verilator work dir
	@echo; echo "\tLinking SystemC model source to verilator build path"; echo
	@if [ ! -d $(SIM_VLT_DIR) ]; then mkdir $(SIM_VLT_DIR); fi
	$(Q)cd $(SIM_VLT_DIR) && \
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
vlt-tests: prepare-sw prepare-rtl prepare-dirs prepare-vlt
	@echo
	@echo "Beginning loop that will complete the following tests: $(TESTS)"
	@echo
	$(Q)for TEST in $(TESTS); do \
		echo "################################################################################"; \
		echo; \
		echo "\t#### Current test: $$TEST ####"; echo; \
		echo "\t#### Compiling software ####"; echo; \
		CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $$TEST | cut -d "-" -f 1`; \
		$(MAKE) -C $$CURRENT_TEST_SW_DIR $$TEST.vmem $(TEST_SW_MAKE_OPTS) UART_PRINTF=1; \
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

###############################################################################
# Verilator profiled module make
###############################################################################
# To run this, first run a "make prepare-vlt VLT_DO_PROFILING=1" then do a 
# "make clean" and then a "make prepare-vlt_profiled"
# This new make target copies athe results of the profiling back to the right
# paths before we create everything again
###############################################################################
.PHONY: prepare-vlt-profiled
prepare-vlt-profiled: $(SIM_VLT_DIR)/OrpsocMain.gcda clean vlt-restore-profileoutput prepare-rtl vlt-model-links $(SIM_VLT_DIR)/Vorpsoc_top

$(SIM_VLT_DIR)/OrpsocMain.gcda: $(SIM_VLT_DIR)/Vorpsoc_top-for-profiling prepare-sw-uart-printf
	$(MAKE) -C $(SW_DIR)/dhry dhry-nocache-O2 NUM_RUNS=200
	$(SIM_VLT_DIR)/Vorpsoc_top -f $(SW_DIR)/dhry/dhry-nocache-O2.or32 -v -l sim.log --crash-monitor

.PHONY: $(SIM_VLT_DIR)/Vorpsoc_top-for-profiling
$(SIM_VLT_DIR)/Vorpsoc_top-for-profiling:
	$(MAKE) prepare-vlt VLT_DO_PROFILING=1

.PHONY: vlt-restore-profileoutput
vlt-restore-profileoutput:
	@echo;echo "\tRestoring profiling outputs"; echo
	$(Q)mkdir -p ../vlt
	$(Q)cp /tmp/*.gc* $(SIM_VLT_DIR)
	$(Q)cp /tmp/*.gc* $(BENCH_SYSC_SRC_DIR)

################################################################################
# Architectural simulator test loop
################################################################################

# Verilator defaults to internal memories
sim-tests: prepare-sw
	@if [ ! -d $(SIM_RESULTS_DIR) ]; then mkdir -p $(SIM_RESULTS_DIR); fi
	@echo
	@echo "Beginning loop that will complete the following tests: $(TESTS)"
	@echo
	$(Q)for TEST in $(TESTS); do \
		echo "################################################################################"; \
		echo; \
		echo "\t#### Current test: $$TEST ####"; echo; \
		echo "\t#### Compiling software ####"; echo; \
		CURRENT_TEST_SW_DIR=$(SW_DIR)/`echo $$TEST | cut -d "-" -f 1`; \
		$(MAKE) -C $$CURRENT_TEST_SW_DIR $$TEST.vmem $(TEST_SW_MAKE_OPTS) UART_PRINTF=1; \
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

dist-clean: clean
	$(MAKE) -C $(SW_DIR)/utils clean

clean: clean-sw clean-sim clean-sysc clean-rtl clean-vpi

clean-sw:
	@for SWDIR in `ls $(SW_DIR) | grep -v utils`; do \
		echo $$SWDIR; \
		$(MAKE) -C $(SW_DIR)/$$SWDIR clean; \
	done

clean-sim:
#backup any profiling output files
	@if [ -f $(SIM_VLT_DIR)/OrpsocMain.gcda ]; then echo;echo "\tBacking up verilator profiling output to /tmp"; echo; \
	cp $(SIM_VLT_DIR)/*.gc* /tmp; \
	cp $(BENCH_SYSC_SRC_DIR)/*.gc* /tmp; fi
	rm -rf $(SIM_RESULTS_DIR) $(SIM_RUN_DIR)/*.* $(SIM_VLT_DIR) $(MGC_ORPSOC_LIB_DIR) $(SIM_RUN_DIR)/work $(SIM_RUN_DIR)/transcript

clean-sysc:
# Clean away dependency files generated by verilator
	$(MAKE) -C $(BENCH_SYSC_SRC_DIR) -f $(BENCH_SYSC_SRC_DIR)/Modules.make clean

clean-rtl:
# Clean away temporary verilog source files
	rm -f $(RTL_VERILOG_DIR)/components/wb_sdram_ctrl/wb_sdram_ctrl_fsm.v

