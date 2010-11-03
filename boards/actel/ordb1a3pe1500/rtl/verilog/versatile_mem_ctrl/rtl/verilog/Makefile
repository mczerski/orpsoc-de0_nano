VERSATILE_FIFO_PROJECT_FILES =versatile_fifo_dual_port_ram.v
VERSATILE_FIFO_PROJECT_FILES +=versatile_fifo_async_cmp.v
VERSATILE_FIFO_PROJECT_FILES +=dff_sr.v
VERSATILE_FIFO_PROJECT_FILES +=async_fifo_mq.v
VERSATILE_FIFO_PROJECT_FILES +=async_fifo_mq_md.v
VERSATILE_FIFO_PROJECT_FILES +=versatile_fifo_dual_port_ram_dc_sw.v

$(VERSATILE_FIFO_PROJECT_FILES):
	svn export http://opencores.org/ocsvn/versatile_fifo/versatile_fifo/trunk/rtl/verilog/$@

VERSATILE_COUNTER_PROJECT_FILES =versatile_counter_generator.php
VERSATILE_COUNTER_PROJECT_FILES +=CSV.class.php

$(VERSATILE_COUNTER_PROJECT_FILES):
	svn export http://opencores.org/ocsvn/versatile_counter/versatile_counter/trunk/rtl/verilog/$@

versatile_fifo_dual_port_ram_dc_dw.v: versatile_fifo_dual_port_ram.v
	vppreproc +define+TYPE+"dc_dw" +define+DC +define+DW +define+DATA_WIDTH+36 +define+ADDR_WIDTH+8 --simple versatile_fifo_dual_port_ram.v > versatile_fifo_dual_port_ram_dc_dw.v

# These rules will generate counters as they're required, but some CSVs stil hang around (the ones we don't use, ironically.)
counter_csvs:versatile_counter.xls versatile_counter_generator.php CSV.class.php
	excel2csv $< -S ,

%.csv:
	$(MAKE) counter_csvs

%.v: %.csv
	@if [ ! -e $< ]; then ls $<; fi
	./versatile_counter_generator.php $^ > $@

fifo_fill.v: fifo_fill.fzm
	perl fizzim.pl -encoding onehot < fifo_fill.fzm > fifo_fill.v

ddr_16_generated.v: ddr_16.fzm ddr_16_defines.v
		perl fizzim.pl -encoding onehot < ddr_16.fzm > $@

ddr_16.v: ddr_16_generated.v
	vppreproc --simple $^ > $@

#fifo_adr_counter.v:
#	@echo;echo "\tThis file,"$@", doesn't exist, is it still needed?!. \n\tMake will now stop";echo
#	ls notexisting

VERSATILE_MEM_CTRL_IP_FILES=versatile_fifo_async_cmp.v async_fifo_mq.v versatile_fifo_dual_port_ram_dc_dw.v ctrl_counter.v fifo.v fifo_fill.v inc_adr.v ref_counter.v ref_delay_counter.v pre_delay_counter.v burst_length_counter.v ddr_16.v fsm_wb.v delay.v ddr_ff.v dcm_pll.v dff_sr.v versatile_mem_ctrl_ddr.v ddr_16_defines.v sdr_16_defines.v codec.v gray_counter.v egress_fifo.v versatile_fifo_dual_port_ram_dc_sw.v fsm_sdr_16.v versatile_mem_ctrl_wb.v versatile_mem_ctrl_top.v

versatile_mem_ctrl_ip.v: $(VERSATILE_MEM_CTRL_IP_FILES)
	cat $^  | cat copyright.v - > $@

# SDRAM 16-bit wide databus dependency files - force a recompile
SDR_16_FILES=sdr_16_defines.v fsm_wb.v versatile_fifo_async_cmp.v async_fifo_mq.v delay.v codec.v gray_counter.v egress_fifo.v versatile_fifo_dual_port_ram_dc_sw.v dff_sr.v ref_counter.v fsm_sdr_16.v versatile_mem_ctrl_wb.v versatile_mem_ctrl_top.v
sdr_16.v: $(SDR_16_FILES)
	vppreproc +define+SDR_16 +incdir+.  $^ > $@

# the single all rule
all: versatile_fifo_dual_port_ram.v versatile_fifo_async_cmp.v versatile_fifo_dual_port_ram_dc_dw.v counter_csvs fifo_fill.v sdr_16.v ddr_16.v versatile_mem_ctrl_ip.v


clean:
	rm -rf $(VERSATILE_FIFO_PROJECT_FILES) $(VERSATILE_COUNTER_PROJECT_FILES)
	rm -rf fifo_fill.v sdr_16.v ddr_16.v
	rm -f versatile_fifo_dual_port_ram_dc_dw.v ddr_16_generated.v
	rm -rf *_counter.v
	rm -rf *.csv
	rm -rf *~

