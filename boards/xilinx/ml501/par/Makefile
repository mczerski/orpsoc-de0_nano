#
#  ORPSoC on ML501 Place And Route Makefile
#

# Include file for tools, etc
include ../../../tools.inc

BOARD=ml501
PART=xc5vlx50-ff676-1

XILINX_FLAGS=-intstyle silent
XILINX_MAP_FLAGS=-logic_opt off
## By default we don't echo the bash commands, but if you want to, for
# debugging purposes, set Q= when calling make
Q ?=@

%.ngd: %_xst.ucf ../syn/%.ngc
	@echo; echo "\t#### Running NGDBuild ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
	ngdbuild -p $(PART) -sd ../syn -uc $*_xst.ucf $*.ngc $*.ngd )

../syn/%.ngc:
	${MAKE} -C ../syn $*.ngc

# -pr is pack and the options are <i|o|b>
XILINX_AREA_TARGET = speed
#This target uses Xilinx tools to perform Mapping
%_map.ncd: %.ngd
	@echo; echo "\t#### Mapping ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
        export XIL_MAP_NO_DSP_AUTOREG=1 && \
        export XIL_MAP_ALLOW_ANY_DLL_INPUT=1 && \
	map -p $(PART) -detail -pr b -cm ${XILINX_AREA_TARGET} \
	-timing -ol high -w $(XILINX_FLAGS) -o $*_map.ncd -xe n $*.ngd $*.pcf )

#This target uses Xilinx tools to Place & Route the design
%.ncd: %_map.ncd
	@echo; echo "\t#### PAR'ing ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
	par -w -pl high -rl high $(XILINX_FLAGS) $*_map.ncd $*.ncd $*.pcf )

#This target uses Xilinx tools to generate a bitstream
%.bit: %.ncd
	@echo; echo "\t#### Generating .bit file ####";
	$(Q)( . $(XILINX_SETTINGS_SCRIPT) && \
	bitgen -w $(XILINX_FLAGS) -g StartUpClk:JtagClk $*.ncd $*.bit )

#this target downloads the bitstream to the target fpga
%.download: %.bit %.batch
	$(Q)( . ${XILINX_PATH}/settings32.sh && \
	impact -batch $*.batch )

#This target uses netgen to make a simulation netlist
%.netlist: %.ncd
	@echo; echo "\t#### Generating netlist ####";
	$(Q)(. $(XILINX_SETTINGS_SCRIPT) && \
	netgen -ofmt verilog -sim -dir netlist -pcf $*.pcf $*.ncd)

#This one uses TRCE to make a timing report
%.twr: %.ncd
	@echo; echo "\t#### Generating timing report ####";
	$(Q)(. $(XILINX_SETTINGS_SCRIPT) && \
	trce -u 1000 -e 1000 $*.ncd)


FILES_TO_KEEP=$(BOARD)_xst.ucf $(BOARD).batch  Makefile
FILES_TO_KEEP_E=$(shell for file in $(FILES_TO_KEEP); do echo "-e $$file"; done)
FILES_TO_DEL=$(shell ls | grep -v $(FILES_TO_KEEP_E))

clean-test:
	@echo Would remove: $(FILES_TO_DEL)
clean:
	@rm -rfv $(FILES_TO_DEL)

.PRECIOUS : %.ncd %.ngd %_map.ncd %.bit ../syn/%.edf ../syn/%.ngc
