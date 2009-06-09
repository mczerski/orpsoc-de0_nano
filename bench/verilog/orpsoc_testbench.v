//////////////////////////////////////////////////////////////////////
////                                                              ////
////  ORPSoC Testbench                                            ////
////                                                              ////
////  Description                                                 ////
////  ORPSoC Testbench file                                       ////
////                                                              ////
////  To Do:                                                      ////
////                                                              ////
////                                                              ////
////  Author(s):                                                  ////
////      - jb, jb@orsoc.se                                       ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2009 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`include "timescale.v"
`include "orpsoc_testbench_defines.v"

module orpsoc_testbench();
   

   reg clk;
   reg rst;
   
   // Setup global clock. Period defined in orpsoc_testbench_defines.v
   initial
     begin
	clk <= 0;
	rst <= 1;
     end
   
   always 
     begin
	#((`CLOCK_PERIOD)/2) clk <= ~clk;
     end
   
   // Assert rst and then bring it low again
   initial 
     begin
	repeat (2) @(negedge clk);
	rst <= 0;
	repeat (16) @(negedge clk);
	rst <= 1;
     end


   // Wires for the dut
   wire spi_sd_sclk_o;
   wire spi_sd_ss_o;
   wire spi_sd_miso_i;
   wire spi_sd_mosi_o;
`ifdef USE_SDRAM
   wire [15:0] mem_dat_io;
   wire [12:0] mem_adr_o;
   wire [1:0]  mem_dqm_o;
   wire [1:0]  mem_ba_o;
   wire        mem_cs_o;
   wire        mem_ras_o;
   wire        mem_cas_o;
   wire        mem_we_o;
   wire        mem_cke_o;
   wire        spi_flash_sclk_o;
   wire        spi_flash_ss_o;
   wire        spi_flash_miso_i;
   wire        spi_flash_mosi_o;
   wire        spi_flash_w_n_o;
   wire        spi_flash_hold_n_o;
`endif //  `ifdef USE_SDRAM

`ifdef USE_ETHERNET
   wire [1:1]  eth_sync_o;
   wire [1:1] eth_tx_o;
   wire [1:1] eth_rx_i;
   wire       eth_clk_i;
   wire [1:1] eth_md_io;
   wire [1:1] eth_mdc_o;
`endif
   
   wire       spi1_mosi_o;
   wire       spi1_miso_i;
   wire       spi1_ss_o;
   wire       spi1_sclk_o;
   wire [8-1:0] gpio_a_io;
   wire 	uart0_srx_i;
   wire 	uart0_stx_o;
   wire 	dbg_tdi_i;
   wire 	dbg_tck_i;
   wire 	dbg_tms_i;
   wire 	dbg_tdo_o;
   wire 	rst_i;
   wire 	rst_o;
   wire 	clk_i;


   assign clk_i = clk;
   assign rst_i = rst;

   // Tie off some inputs   
   assign spi1_miso_i = 0;
   assign uart0_srx_i = 1;


   orpsoc_top dut 
     (
      // Outputs
      .spi_sd_sclk_pad_o			(spi_sd_sclk_o),
      .spi_sd_ss_pad_o			(spi_sd_ss_o),
      .spi_sd_mosi_pad_o			(spi_sd_mosi_o),
      .spi1_mosi_pad_o			(spi1_mosi_o),
      .spi1_ss_pad_o			(spi1_ss_o),
      .spi1_sclk_pad_o			(spi1_sclk_o),
      .uart0_stx_pad_o			(uart0_stx_o),
      .dbg_tdo_pad_o			(dbg_tdo_o),
      .rst_pad_o				(rst_o),
      .gpio_a_pad_io			(gpio_a_io[8-1:0]),
      // Inputs
      .spi_sd_miso_pad_i			(spi_sd_miso_i),
      .spi1_miso_pad_i			(spi1_miso_i),
      .uart0_srx_pad_i			(uart0_srx_i),
      .dbg_tdi_pad_i			(dbg_tdi_i),
      .dbg_tck_pad_i			(dbg_tck_i),
      .dbg_tms_pad_i			(dbg_tms_i),
`ifdef USE_ETHERNET
      // Ethernet ports
      .eth_md_pad_io			(eth_md_io[1:1]),
      .eth_sync_pad_o			(eth_sync_o[1:1]),
      .eth_tx_pad_o			(eth_tx_o[1:1]),
      .eth_mdc_pad_o			(eth_mdc_o[1:1]),
      .eth_rx_pad_i			(eth_rx_i[1:1]),
      .eth_clk_pad_i			(eth_clk_i),
`endif  //  `ifdef USE_ETHERNET      
      // SDRAM and flash memory ports
`ifdef USE_SDRAM
      .mem_dat_pad_io			(mem_dat_io[15:0]),
      .mem_adr_pad_o			(mem_adr_o[12:0]),
      .mem_dqm_pad_o			(mem_dqm_o[1:0]),
      .mem_ba_pad_o			(mem_ba_o[1:0]),
      .mem_cs_pad_o			(mem_cs_o),
      .mem_ras_pad_o			(mem_ras_o),
      .mem_cas_pad_o			(mem_cas_o),
      .mem_we_pad_o			(mem_we_o),
      .mem_cke_pad_o			(mem_cke_o),
      .spi_flash_sclk_pad_o		(spi_flash_sclk_o),
      .spi_flash_ss_pad_o			(spi_flash_ss_o),
      .spi_flash_mosi_pad_o		(spi_flash_mosi_o),
      .spi_flash_w_n_pad_o			(spi_flash_w_n_o),
      .spi_flash_hold_n_pad_o		(spi_flash_hold_n_o),
      .spi_flash_miso_pad_i		(spi_flash_miso_i),
`endif
      .rst_pad_i				(rst_i),
      .clk_pad_i				(clk_i));

`ifdef VPI_DEBUG_ENABLE
   // Debugging interface
   vpi_debug_module vpi_dbg(
			    .tms(dbg_tms_i), 
			    .tck(dbg_tck_i), 
			    .tdi(dbg_tdi_i), 
			    .tdo(dbg_tdo_o));
`else
   // If no VPI debugging, tie off JTAG inputs
   assign dbg_tdi_i = 1;
   assign dbg_tck_i = 0;
   assign dbg_tms_i = 1;
`endif



   // External memories, if enabled
`ifdef USE_SDRAM   
   // SPI Flash
   AT26DFxxx spi_flash
     (
      // Outputs
      .SO					(spi_flash_miso_i),
      // Inputs
      .CSB					(spi_flash_ss_o),
      .SCK					(spi_flash_sclk_o),
      .SI					(spi_flash_mosi_o),
      .WPB					(spi_flash_w_n_o)
      //.HOLDB				(spi_flash_hold_n_o)
      );

   // SDRAM
   mt48lc16m16a2 sdram 
     (
      // Inouts
      .Dq					(mem_dat_io),
      // Inputs
      .Addr				(mem_adr_o),
      .Ba					(mem_ba_o),
      .Clk					(clk_i),
      .Cke					(mem_cke_o),
      .Cs_n				(mem_cs_o),
      .Ras_n				(mem_ras_o),
      .Cas_n				(mem_cas_o),
      .We_n				(mem_we_o),
      .Dqm					(mem_dqm_o));

`endif // !`ifdef USE_SDRAM


initial
  begin
     $display("\nStarting RTL simulation of %s test\n", `TEST_NAME_STRING);
`ifdef USE_SDRAM
     $display("Using SDRAM - loading application from SPI flash memory\n");
`endif

`ifdef VCD
     $display("VCD in %s\n", {`TEST_RESULTS_DIR,`TEST_NAME_STRING,".vcd"});
     $dumpfile({`TEST_RESULTS_DIR,`TEST_NAME_STRING,".vcd"});
     $dumpvars(0);
`endif
  end

   // Instantiate the monitor
   or1200_monitor monitor();

   // If we're using UART for printf output, include the
   // UART decoder
`ifdef UART_PRINTF
   // Define the UART's txt line for it to listen to
 `define UART_TX_LINE uart0_stx_o
 `define UART_BAUDRATE 115200
 `include "uart_decoder.v"
`endif
   
endmodule // orpsoc_testbench

// Local Variables:
// verilog-library-files:("../../rtl/verilog/orp_soc.v")
// verilog-library-directories:("." "../../rtl/verilog")
// End: