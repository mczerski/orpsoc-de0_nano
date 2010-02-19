# Include file for tools, etc (mainly interested in the Xilinx path here)
include ../../../../tools.inc

ORPSOC_ROOT=../../../../..
BOARD=ml501

CUR_DIR=$(shell pwd)
# The root path of the whole project
PROJECT_ROOT =$(CUR_DIR)/$(ORPSOC_ROOT)

SIM_DIR=$(CUR_DIR)/../../sim

BOARD_BENCH_DIR=$(CUR_DIR)/../../bench
BOARD_RTL_DIR=$(CUR_DIR)/../../rtl
BOARD_SW_DIR=$(CUR_DIR)/../../sw
BOARD_SYN_DIR=$(CUR_DIR)/../../syn


# Important!
RTL_TESTBENCH_TOP=ml501_testbench
BENCH_TOP_VERILOG_DIR=$(BOARD_BENCH_DIR)

# Extra defines passed to testbench compilation
# Used here for DDR2 model defines
EXTRA_BENCH_DEFINES=+define+sg37E +define+x16

#MEMORY_MODELS=$(BENCH_VERILOG_DIR)/cy7c1354.v $(BENCH_VERILOG_DIR)/ddr2_model.v

SIMULATOR=vsim

RTL_VERILOG_INCLUDE_DIR =$(BOARD_RTL_DIR)


include $(ORPSOC_ROOT)/sim/bin/Makefile


ifeq ($(VCD), 1)
VOPT_ARGS=+acc=rnp
endif


# Here we re-define the modelsim compilation variable, changing include dirs 
# so we use the includes/defines from the board's rtl path instead of the 
# normal orpsocv2 bench path.


# Modelsim testench compilation - we change this from the standard makefile
# to change:
# 1) The include directory (should be the board RTL path, not the main RTL path)
# 2) Change the define for the name of the top testbench (board dependent)
# 3) Add the board's testbench paths
# 4) Add the various extra memory models we use (maybe should just use a script for this instead? TODO!)
VSIM_COMPILE_TB = vlog $(BENCH_VERILOG_DIR)/or1200_monitor.v $(BENCH_TOP_VERILOG_DIR)/$(RTL_TESTBENCH_TOP).v
VSIM_COMPILE_TB += +incdir+$(BENCH_VERILOG_DIR) +incdir+$(BENCH_TOP_VERILOG_DIR) +incdir+$(BOARD_RTL_DIR) +incdir+$(XILINX_VERILOG_SRC)  
VSIM_COMPILE_TB += +define+TEST_DEFINE_FILE  
VSIM_COMPILE_TB += +define+OR1200_TOP=$(RTL_TESTBENCH_TOP).dut.i_or1k.i_or1200_top 
VSIM_COMPILE_TB += +define+TESTBENCH_DEFINES=\"$(RTL_TESTBENCH_TOP)_defines.v\"
VSIM_COMPILE_TB += -y $(BENCH_VERILOG_DIR) -y $(BOARD_BENCH_DIR) +libext+.v
VSIM_COMPILE_TB += $(EXTRA_BENCH_DEFINES)

VOPT_STEP=vopt -quiet $(VOPT_ARGS) glbl $(RTL_TESTBENCH_TOP) -L $(MGC_ORPSOC_LIB) -o testbench
SIM_COMMANDRUN= $(VSIM_COMPILE_TB); $(VOPT_STEP); $(VSIM) -c -quiet +nowarnTFMPC -L $(MGC_ORPSOC_LIB)  -do "run -all; exit" testbench

# Re-define the command-file generation rule - we add a few extra things to 
# our scripts to tell the simulator where the Xilinx tools, other set of 
# includes, etc.
$(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE): $(SIM_BIN_DIR)/$(SIM_COMMANDFILE)
	$(Q)sed < $(SIM_BIN_DIR)/$(SIM_COMMANDFILE) > $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE) \
		-e s!\$$BENCH_DIR!$(BENCH_VERILOG_DIR)!              \
		-e s!\$$RTL_DIR!$(RTL_VERILOG_DIR)!                  \
		-e s!\$$BOARD_BENCH_DIR!$(BOARD_BENCH_DIR)!          \
		-e s!\$$BOARD_RTL_DIR!$(BOARD_RTL_DIR)!              \
		-e s!\$$BACKEND_DIR!$(BACKEND_DIR)!                  \
		-e s!\$$XILINX_VERILOG_SRC!$(XILINX_VERILOG_SRC)!    \
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



# A new set of tests for software which will run only on this board

BOARD_TESTS=boot memtest eth gpio

rtl-board-tests: $(SIM_RUN_DIR)/$(GENERATED_COMMANDFILE) prepare-sw prepare-rtl prepare-dirs
	@echo
	@echo "Beginning loop that will complete the following tests for $(BOARD) board: $(BOARD_TESTS)"
	@echo
	$(Q)for TEST in $(BOARD_TESTS); do \
		echo "################################################################################"; \
		echo; \
		echo "\t#### Current test: $$TEST ####"; echo; \
		echo "\t#### Compiling software ####"; echo; \
		CURRENT_TEST_SW_DIR=$(BOARD_SW_DIR)/`echo $$TEST | cut -d "-" -f 1`; \
		$(MAKE) -C $$CURRENT_TEST_SW_DIR clean $$TEST $(TEST_SW_MAKE_OPTS); \
		rm -f $(SIM_RUN_DIR)/$(SIM_FLASH_MEM_FILE); \
		rm -f $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		ln -s $$CURRENT_TEST_SW_DIR/$$TEST.vmem $(SIM_RUN_DIR)/$(SIM_SRAM_MEM_FILE); \
		echo "\`define TEST_NAME_STRING \"$$TEST\"" > $(SIM_RUN_DIR)/test_define.v; \
		echo "\`define TEST_RESULTS_DIR \"$(SIM_RESULTS_DIR)/\" " >> $(SIM_RUN_DIR)/test_define.v; \
		if [ ! -z $$VCD ]; \
			then echo "\`define VCD" >> $(SIM_RUN_DIR)/test_define.v; \
		fi; \
		if [ ! -z $$UART_PRINTF ]; \
			then echo "\`define UART_PRINTF" >> $(SIM_RUN_DIR)/test_define.v; \
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


SYN_SIM_COMMANDCOMPILE=if [ ! -e work ]; then vlib work; vlib $(MGC_ORPSOC_LIB); vlog -work $(MGC_ORPSOC_LIB) +libext+.v -y $(XILINX_VERILOG_SRC) +incdir+$(XILINX_VERILOG_SRC) -y $(XILINX_VERILOG_SRC)/unisims +incdir+$(XILINX_VERILOG_SRC)/unisims -y $(XILINX_VERILOG_SRC)/XilinxCoreLib +incdir+$(XILINX_VERILOG_SRC)/XilinxCoreLib $(BOARD_SYN_DIR)/$(BOARD).v $(BOARD_RTL_DIR)/ml501_ddr2_wb_if_cache.v ; fi
syn-board-test:  prepare-dirs $(BOARD_SYN_DIR)/$(BOARD).v
	$(Q)echo "\`define TEST_NAME_STRING \"ml501-post-synthesis\"" > $(SIM_RUN_DIR)/test_define.v; \
	echo "\`define POST_SYNTHESIS_SIM" >> $(SIM_RUN_DIR)/test_define.v; \

	echo "\`define TEST_RESULTS_DIR \"$(SIM_RESULTS_DIR)/\" " >> $(SIM_RUN_DIR)/test_define.v; \
	if [ ! -z $$VCD ]; \
		then echo "\`define VCD" >> $(SIM_RUN_DIR)/test_define.v; \
		if [ ! -z $$VCD_DEPTH ]; \
			then echo "\`define VCD_DEPTH "$(VCD_DEPTH) >> $(SIM_RUN_DIR)/test_define.v; \
		fi; \
	fi; \
	if [ ! -z $$UART_PRINTF ]; \
		then echo "\`define UART_PRINTF" >> $(SIM_RUN_DIR)/test_define.v; \
	fi; \
	echo "\t#### Compiling RTL ####"; \
	$(SYN_SIM_COMMANDCOMPILE); \
	echo; \
	echo "\t#### Beginning simulation ####"; \
	time -p $(SIM_COMMANDRUN) ; \
	echo
