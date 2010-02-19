#
#  ORPSoC on ML501 Synthesis Makefile
#
# Only uses XST currently. run "make ml501.ngc"
#

# Include file for tools, etc
include ../../../tools.inc

BOARD=ml501
PART=xc5vlx50-ff676-1

# Paths in rtl/verilog/components that we're including in the system
MODULES=or1200r2 or1k_startup or1k_top tap debug_if wb_conbus uart16550 ram_wb ethernet

# A list of parts of names of files to be excluded from the automatic file list generation
EXCLUDE=or1200_dpram or1200_fpu eth_defines

# When cleaning - files not to delete
FILES_TO_KEEP=$(BOARD).xcf  $(BOARD)_xst.tpl  ml501_ddr2_wb_if_cache.ngc timescale.v Makefile 

# Relative path to the rtl, sim, sw, etc. directories
ORPSOC_ROOT=../../../..
CUR_DIR=$(shell pwd)

# Path from the root to the verilog components
RTL_COMPONENTS_PATH=rtl/verilog/components

# Make RTL_PATHS contain a list of paths to the RTL dirs for the modules
RTL_PATHS=$(shell for module in $(MODULES); do echo $(ORPSOC_ROOT)/$(RTL_COMPONENTS_PATH)/$$module; done)

EXCLUDE_LIST_E=$(shell for exclude in $(EXCLUDE); do echo "-e $$exclude"; done)

# Get a list of the verilog source files themselves
VERILOG_SRC=$(shell for path in $(RTL_PATHS); do ls $$path/*.v | grep -v $(EXCLUDE_LIST_E); done)
# Add the source files from the board's RTL dir
VERILOG_SRC += $(shell ls ../rtl/*.v)
VERILOG_SRC += $(shell ls ../rtl/ddr2_mig/*.v)

XST_PRJ_FILE_SRC_DECLARE=verilog work
XILINX_FLAGS=-intstyle silent
XILINX_XST_FLAGS += -power NO -glob_opt AllClockNets -write_timing_constraints NO -cross_clock_analysis NO -slice_utilization_ratio 100 -bram_utilization_ratio 100 -dsp_utilization_ratio 100 -safe_implementation No -fsm_style lut -ram_extract Yes -ram_style Auto -rom_extract Yes -rom_style Auto -auto_bram_packing NO -mux_extract YES -mux_style Auto -decoder_extract YES -priority_extract YES -shreg_extract YES -shift_extract YES -xor_collapse YES -resource_sharing YES -async_to_sync NO -use_dsp48 auto -iobuf YES -max_fanout 100000 -bufg 32 -register_duplication YES -equivalent_register_removal YES -register_balancing No -slice_packing YES -optimize_primitives NO -use_clock_enable Auto -use_sync_set Auto -use_sync_reset Auto -iob Auto -slice_utilization_ratio_maxmargin 5



BOOT_SW=boot
BOOT_SW_DIR=$(CUR_DIR)/../sw/$(BOOT_SW)

$(BOOT_SW).vmem: $(BOOT_SW_DIR)/$(BOOT_SW).vmem
	if [ ! -e sram.vmem ]; then ln -s $? sram.vmem; fi
# Force this to happen each time
.PHONY: $(BOOT_SW_DIR)/$(BOOT_SW).vmem
$(BOOT_SW_DIR)/$(BOOT_SW).vmem:
	$(MAKE) -C $(BOOT_SW_DIR) clean $(BOOT_SW) SYNTHESIS=1

# Generate the .xst file from the template, .tpl
# Substitute in the include paths, board name and part
%.xst: %_xst.tpl Makefile
	@echo; echo "\t#### Generating Xilinx XST file ####";
	@sed < $< > $@ \
	-e s!\$$RTL_COMPONENT_PATHS!"$(RTL_PATHS)"! \
	-e s!\$$BOARD!"$(BOARD)"! \
	-e s!\$$PART!"$(PART)"!
	@echo

# Generate Xilinx project (.prj) file
%.prj: Makefile
	@echo; echo "\t#### Generating Xilinx PRJ file ####";
	@if [ -e $@ ]; then rm -f $@; fi
	@for file in $(VERILOG_SRC); do \
		echo $(XST_PRJ_FILE_SRC_DECLARE) $$file >> $@ ; \
	done
	@echo

%.ngc: %.prj %.xst %.xcf ../rtl/%.v $(BOOT_SW).vmem
	@echo; echo "\t#### Running XST ####";
	@(. $(XILINX_SETTINGS_SCRIPT) ; xst -ifn $*.xst $(XILINX_FLAGS) $(XST_FLAGS) )
	@echo

%.v: %.ngc
	@echo; echo "\t#### Generating verilog netlist ####";
	@(. $(XILINX_SETTINGS_SCRIPT) ; \
	netgen -sim -aka -dir . -ofmt verilog $*.ngc -w $@ )	

FILES_TO_KEEP_E=$(shell for file in $(FILES_TO_KEEP); do echo "-e $$file"; done)
FILES_TO_DEL=$(shell ls | grep -v $(FILES_TO_KEEP_E))

clean-test:
	@echo Would remove: $(FILES_TO_DEL)

clean-sw:
	@$(MAKE) -C $(BOOT_SW_DIR)
clean: clean-sw
	@rm -rfv $(FILES_TO_DEL)



.PRECIOUS : %.ngc %.prj %.xst