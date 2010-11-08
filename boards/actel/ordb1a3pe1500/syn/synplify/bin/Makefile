#
# Makefile for synthesis
#
# To generate the EDIF, just do "# make all"
#
# To synthesize for older ORSoC board with A3P1000, do:
#	# make clean all FPGA_FAMILY=ProASIC3 FPGA_PART=A3P1000
#	
# Note: correct pll model must be linked in backend path.
#

# Name of the directory we're currently in
CUR_DIR=$(shell pwd)

# The root path of the board build
BOARD_DIR ?=$(CUR_DIR)/../../..
PROJECT_ROOT=$(BOARD_DIR)/../../..

# Export BOARD_PATH for the software makefiles
BOARD_PATH=$(BOARD_DIR)
export BOARD_PATH

DESIGN_NAME=orpsoc

# Paths to other important parts of this test suite

# Paths to other important parts of this test suite
COMMON_RTL_DIR = $(PROJECT_ROOT)/rtl
COMMON_RTL_VERILOG_DIR = $(COMMON_RTL_DIR)/verilog
#COMMON_RTL_VHDL_DIR = $(COMMON_RTL_DIR)/vhdl

BOARD_RTL_DIR=$(BOARD_DIR)/rtl
BOARD_RTL_VERILOG_DIR=$(BOARD_RTL_DIR)/verilog
# Only 1 include path for board builds - their own!
BOARD_RTL_VERILOG_INCLUDE_DIR=$(BOARD_RTL_VERILOG_DIR)/include
#BOARD_RTL_VHDL_DIR = $(BOARD_RTL_DIR)/vhdl


BACKEND_DIR=$(BOARD_DIR)/backend
BACKEND_VERILOG_DIR=$(BACKEND_DIR)/rtl/verilog

# Set V=1 when calling make to enable verbose output
# mainly for debugging purposes.
ifeq ($(V), 1)
Q=
else
Q ?=@
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
	@echo echo; echo "\t### Board verilog modules ###"; echo;
	@echo $(BOARD_RTL_VERILOG_MODULES)

# Now get list of modules that we don't have a version of in the board path
COMMON_VERILOG_MODULES_EXCLUDE= include
COMMON_VERILOG_MODULES_EXCLUDE += $(BOARD_RTL_VERILOG_MODULES)

COMMON_RTL_VERILOG_MODULES_DIR_LIST=$(shell ls $(COMMON_RTL_VERILOG_DIR))
COMMON_RTL_VERILOG_MODULES=$(filter-out $(COMMON_VERILOG_MODULES_EXCLUDE), $(COMMON_RTL_VERILOG_MODULES_DIR_LIST))

# Rule for debugging this script
print-common-modules-exclude:
	@echo echo; echo "\t### Common verilog modules being excluded due to board versions ###"; echo;
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

#
# Add backend files here, except for the proasic3 library
#
RTL_VERILOG_SRC+=$(shell ls $(BACKEND_VERILOG_DIR)/*.v)

#
# VHDL DUT source variables
#
# VHDL modules
#RTL_VHDL_MODULES=$(shell ls $(RTL_VHDL_DIR))
# VHDL sources
#RTL_VHDL_SRC=$(shell for module in $(RTL_VHDL_MODULES); do if [ -d $(RTL_VHDL_DIR)/$$module ]; then ls $(RTL_VHDL_DIR)/$$module/*.vhd; fi; done)

# Tool settings
# For Linux, the Actel licenses only support Synplify Pro
SYN_WORK_DIR 		?=synplify_work
SYN_SCRIPT 		?=synplify.prj 	# We will generate this
SYN_LOG 		?=syn.log	
SYN_TOOL 		?=synplify_pro	# Name of the executable to call
# Options passed after the executable.
SYN_LICENSE_OPTS	?=-licensetype synplifypro_acteloem
SYN_TOOL_OPTS 		?=$(SYN_SCRIPT) $(SYN_LICENSE_OPTS) -batch -log $(SYN_LOG)


SYN_PROJ_NAME ?= $(DESIGN_NAME)
RTL_TOP ?= $(DESIGN_NAME)_top
EDIF_FILE ?=$(RTL_TOP).edn
EDIF_FILE_OUT ?= ../out/$(EDIF_FILE)
VLOG_NETLIST_FILE ?=$(RTL_TOP).vm
VLOG_NETLIST_FILE_OUT ?= ../out/$(VLOG_NETLIST_FILE)
# Synthesis params
#FREQ ?= 50.0000
FREQ ?= 125.000
FPGA_FAMILY ?=ProASIC3E
#FPGA_PART ?=A3P1000
FPGA_PART ?=A3PE1500
FPGA_PACKAGE ?=PQFP208
#FPGA_SPEED_GRADE ?=-2
FPGA_SPEED_GRADE ?=Std
MAXFAN ?=50
MAXFAN_HARD ?=0
RETIMING ?=1
GLOBALTHRESH ?=50
DISABLE_IO_INSERTION ?= 0
RESOURCE_SHARING ?=1

# Time reporting variable
NUM_PATHS=50
NUM_ENDPOINTS=50

SDC_FILE=$(DESIGN_NAME)_top.sdc

# Rule to print out current config of current session
print-config:
	@echo; echo "\t### Synthesis make configuration ###"; echo
	@echo "\tRTL_TOP="$(RTL_TOP)
	@echo "\tFPGA_FAMILY="$(FPGA_FAMILY)
	@echo "\tFPGA_PART="$(FPGA_PART)
	@echo "\tFPGA_PACKAGE="$(FPGA_PACKAGE)
	@echo "\tFPGA_SPEED_GRADE="$(FPGA_SPEED_GRADE)
	@echo "\tFREQ="$(FREQ)
	@echo "\tMAXFAN="$(MAXFAN)
	@echo "\tMAXFAN_HARD="$(MAXFAN_HARD)
	@echo "\tRETIMING="$(RETIMING)
	@echo "\tGLOBALTHRESH="$(GLOBALTHRESH)
	@echo "\tDISABLE_IO_INSERTION="$(DISABLE_IO_INSERTION)
	@echo "\tRESOURCE_SHARING="$(RESOURCE_SHARING)
	@echo



all: print-config $(EDIF_FILE_OUT) $(VLOG_NETLIST_FILE_OUT)

#create the work dir
$(SYN_WORK_DIR):
	mkdir $(SYN_WORK_DIR)

#
# Dynamically created files included by different parts of the defines
#

BOOTROM_FILE=bootrom.v
BOARD_SW_DIR=$(BOARD_DIR)/sw
BOARD_BOOTROM_SW_DIR=$(BOARD_SW_DIR)/bootrom
BOOTROM_VERILOG=$(BOARD_BOOTROM_SW_DIR)/$(BOOTROM_FILE)
bootrom: $(BOOTROM_VERILOG)
$(BOOTROM_VERILOG):
	$(MAKE) -C $(BOARD_BOOTROM_SW_DIR) $(BOOTROM_FILE)

SYNDIR_BOOTROM_VERILOG=$(SYN_WORK_DIR)/$(BOOTROM_FILE)
$(SYNDIR_BOOTROM_VERILOG): $(BOOTROM_VERILOG)
	cp $^ $@

TIMESCALE_FILE=timescale.v
SYNDIR_TIMESCALE_FILE=$(SYN_WORK_DIR)/$(TIMESCALE_FILE)
$(SYNDIR_TIMESCALE_FILE):
	$(Q)echo "" > $@

SYN_VERILOG_DEFINES=synthesis-defines.v
SYNDIR_SYN_VERILOG_DEFINES=$(SYN_WORK_DIR)/$(SYN_VERILOG_DEFINES)
$(SYNDIR_SYN_VERILOG_DEFINES):
	$(Q)echo "\`define SYNTHESIS" > $@
	$(Q)echo "\`define ACTEL" >> $@
	$(Q)echo "" >> $@

GENERATED_DEFINES = $(SYNDIR_BOOTROM_VERILOG) 
GENERATED_DEFINES += $(SYNDIR_TIMESCALE_FILE)
GENERATED_DEFINES += $(SYNDIR_SYN_VERILOG_DEFINES)

# Generate the prj file
.PHONY: $(SYN_WORK_DIR)/$(SYN_SCRIPT)
$(SYN_WORK_DIR)/$(SYN_SCRIPT): $(SYN_WORK_DIR) $(RTL_VERILOG_SRC) $(RTL_VERILOG_INCLUDES) $(GENERATED_DEFINES) $(SYN_WORK_DIR)/$(SDC_FILE)
	$(Q)echo; echo "\t### Generating Synplify project file ###"; echo
	$(Q)echo -n "# Autogenerated synthesis script " > $@
	$(Q)date >> $@
	$(Q)for file in $(RTL_VERILOG_SRC); do \
		echo "add_file -verilog "$$file >> $@; \
	done
	$(Q)for file in $(RTL_VHDL_SRC); do \
		echo "add_file -vhdl "$$file >> $@; \
	done
	$(Q)echo "add_file -constraint "$(SDC_FILE) >> $@
	$(Q)echo "set_option -include_path "$(BOARD_RTL_VERILOG_INCLUDE_DIR) >> $@
	$(Q)echo "set_option -include_path ." >> $@
	$(Q)echo "impl -add "$(SYN_PROJ_NAME)" -type fpga" >> $@
	$(Q)echo "set_option -technology "$(FPGA_FAMILY) >> $@
	$(Q)echo "set_option -part "$(FPGA_PART) >> $@
	$(Q)echo "set_option -package "$(FPGA_PACKAGE) >> $@
	$(Q)echo "set_option -speed_grade "$(FPGA_SPEED_GRADE) >> $@
	$(Q)echo "set_option -part_companion \"\"" >> $@
	$(Q)echo "set_option -use_fsm_explorer 0" >> $@
	$(Q)echo "set_option -top_module \""$(RTL_TOP)"\"" >> $@
	$(Q)echo "set_option -symbolic_fsm_compiler 1" >> $@
	$(Q)echo "set_option -compiler_compatible 0" >> $@
	$(Q)echo "set_option -resource_sharing "$(RESOURCE_SHARING) >> $@
	$(Q)echo "set_option -frequency "$(FREQ) >> $@
	$(Q)echo "set_option -write_verilog 1" >> $@
	$(Q)echo "set_option -write_vhdl 0" >> $@
	$(Q)echo "set_option -run_prop_extract 1" >> $@
	$(Q)echo "set_option -maxfan "$(MAXFAN) >> $@
	$(Q)echo "set_option -maxfan_hard "$(MAXFAN_HARD) >> $@
	$(Q)echo "set_option -disable_io_insertion "$(DISABLE_IO_INSERTION) >> $@
	$(Q)echo "set_option -retiming "$(RETIMING) >> $@
	$(Q)echo "set_option -report_path 4000" >> $@
	$(Q)echo "set_option -opcond COMWC" >> $@
	$(Q)echo "set_option -update_models_cp 0" >> $@
	$(Q)echo "set_option -preserve_registers 0" >> $@
	$(Q)echo "set_option -globalthreshold "$(GLOBALTHRESH) >> $@
	$(Q)echo "set_option -syn_global_buffers 18" >> $@
	$(Q)echo "set_option -reporting_filter {-from {*} -to {*}}" >> $@
	$(Q)echo "set_option -reporting_filename "$(RTL_TOP)".ta" >> $@
	$(Q)echo "set_option -reporting_output_srm 0" >> $@
	$(Q)echo "set_option -write_apr_constraint 1" >> $@
	$(Q)echo "project -result_format \"edif\"" >> $@
	$(Q)echo "project -result_file \""$(EDIF_FILE)"\"" >> $@
	$(Q)echo "set_option -vlog_std v2001" >> $@
	$(Q)echo "set_option -num_startend_points "$(NUM_ENDPOINTS) >> $@
	$(Q)echo "set_option -num_critical_paths "$(NUM_PATHS) >> $@
	$(Q)echo "set_option -project_relative_includes 1" >> $@
	$(Q)echo "impl -active \""$(SYN_PROJ_NAME)"\"" >> $@

#
# Constraint script generation
#
IN_CLK_PERIOD_NS = 15.625 # 64 MHz
WB_CLK_PERIOD_NS = 31.25 # 32 MHz
#
# Timing (SDC)
#
# I can't figure out how to get these constraints into synplify properly..
# but doesn't really appear to matter, we simply overconstrain the whole
# thing to fastest frequency we need, which is currently:
# SMII @ 125MHz
# 
$(SYN_WORK_DIR)/$(SDC_FILE):
	$(Q)echo; echo "\t### Generating SDC file ###"; echo
	$(Q)rm -f $@
	$(Q)echo >> $@
#	$(Q)echo "create_clock  -name { sys_clk } -period "$(IN_CLK_PERIOD_NS)" { p:sys_clk  } " >> $@
#	$(Q)echo "create_clock  -name { tck_pad_i } -period 100.000 -waveform { 0.000 50.000  }  { p:tck_pad_i  } " >> $@
#	$(Q)echo "create_generated_clock  -name { clkgen0/pll0/Core:GLA } -divide_by 72  -multiply_by 36  -source { clkgen0/pll0/Core:CLKA } { clkgen0/pll0/Core:GLA  }" >> $@
#	$(Q)echo "create_generated_clock  -name { clkgen0/pll0/Core:GLB } -divide_by 36  -multiply_by 36  -source { clkgen0/pll0/Core:CLKA } { clkgen0/pll0/Core:GLB  } " >> $@ 
#	$(Q)echo "create_generated_clock  -name { clkgen0.pll0.wb_clk_i } -divide_by 72  -multiply_by 36  -source { t:clkgen0.pll0.wb_clk_i } { t:clkgen0.pll0.wb_clk_i  }" >> $@


# change into work dir, call synplify, hopefully create the edif
$(SYN_WORK_DIR)/$(SYN_PROJ_NAME)/$(EDIF_FILE): $(SYN_WORK_DIR)/$(SYN_SCRIPT)
	cd $(SYN_WORK_DIR) && time $(SYN_TOOL) $(SYN_TOOL_OPTS)

##
# Generate a report for each module, and for whole thing
##
MODULES ?=arbiter_ibus arbiter_dbus arbiter_bytebus jtag_tap or1200_top dbg_if rom ram_wb uart16550 spacewire_wb_if mp2_top simple_spi i2c_core_wb_if usbslave scet gpio versatile_mem_ctrl urtu_top
MODULES_SRR=$(shell for mod in $(MODULES); do echo $(SYN_WORK_DIR)"/"$(SYN_PROJ_NAME)"/"$$mod".srr"; done)

syn-report: $(MODULES_SRR)
	rm -f $@
	for srrfile in $^; do \
		echo `echo $$srrfile | xargs basename | cut -d '.' -f 1`>> $@; \
		grep "Core Cells" $$srrfile >> $@; \
		grep "Block Rams" $$srrfile >> $@; \
		grep -B 1 -A 5 "Starting Clock" $$srrfile >> $@; \
		echo >> $@; echo >> $@; \
	done

%.srr:
	@echo; echo "\tGenerating "$@; echo
	export RTL_TOP=$(shell echo $@ | xargs basename | cut -d '.' -f 1); \
	$(MAKE) $(SYN_WORK_DIR)/$(SYN_PROJ_NAME)/$$RTL_TOP.edn


$(EDIF_FILE_OUT): $(SYN_WORK_DIR)/$(SYN_PROJ_NAME)/$(EDIF_FILE)
	cp $^ $@

$(VLOG_NETLIST_FILE_OUT): $(SYN_WORK_DIR)/$(SYN_PROJ_NAME)/$(VLOG_NETLIST_FILE)
	cp $^ $@

clean-all: clean-sw clean clean-edifs

clean-sw:
	$(MAKE) -C $(PROJECT_ROOT)/sw/lib clean-all

clean: clean-build

clean-edifs:
	rm -f *.edn ../out/*

clean-build:
	rm -rf $(SYN_WORK_DIR) *.edn

clean-srr:
	rm $(MODULES_SRR)
