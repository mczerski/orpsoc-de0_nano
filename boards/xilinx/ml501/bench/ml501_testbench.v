//////////////////////////////////////////////////////////////////////
////                                                              ////
////  ORPSoC on ml501 testbench                                   ////
////                                                              ////
////  Description                                                 ////
////  ORPSoC Testbench file                                       ////
////                                                              ////
////  To Do:                                                      ////
////        Update ethernet and SPI models appropriately          ////
////                                                              ////
////  Author(s):                                                  ////
////      - Julius Baxter, julius.baxter@orsoc.se                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2010 Authors and OPENCORES.ORG                 ////
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

`timescale 1ns/1ps
`include "glbl.v"
`include "ml501_defines.v"
`include "ml501_testbench_defines.v"

module ml501_testbench();

   reg clk, clk_200;
   reg rst_n;
   wire clk_200_p, clk_200_n;   
   
   // Setup global clock. Period defined in orpsoc_testbench_defines.v
   initial
     begin
	clk <= 0;
	clk_200 <= 0;	
	rst_n <= 1;
     end

   always
     #2500 clk_200 <= ~clk_200;
   
   always 
	#((`CLOCK_PERIOD)/2) clk <= ~clk;

   
   assign clk_200_p = clk_200;
   assign clk_200_n = ~clk_200;
   
   // Assert rst_n and then bring it low again
   initial 
     begin
	repeat (4) @(negedge clk);
	rst_n <= 0;
	repeat (16) @(negedge clk);
	rst_n <= 1;
     end


   wire usr_rst_in, usr_rst_out;
   assign usr_rst_in = usr_rst_out;
   
   
   // Wires for the dut
   wire spi_sd_sclk_o;
   wire spi_sd_ss_o;
   wire spi_sd_miso_i;
   wire spi_sd_mosi_o;

   
`ifdef ML501_MEMORY_SSRAM
   wire `tsramtrace sram_clk;
   wire sram_clk_fb;
   wire `tsramtrace sram_adv_ld_n;
   wire [3:0] `tsramtrace sram_bw;
   wire       `tsramtrace sram_cen;
   wire [21:1] `tsramtrace sram_flash_addr;
   wire [31:0] `tsramtrace sram_flash_data;
   wire        `tsramtrace sram_flash_oe_n;
   wire        `tsramtrace sram_flash_we_n;
   wire        `tsramtrace sram_mode;
`endif //  `ifdef ML501_MEMORY_SSRAM


`ifdef ML501_MEMORY_DDR2

   `include "ml501_ddr2_params.vh"
   
   localparam DEVICE_WIDTH    = 16;      // Memory device data width
   localparam real CLK_PERIOD_NS   = CLK_PERIOD / 1000.0;
   localparam real TCYC_200           = 5.0;
   localparam real TPROP_DQS          = 0.00;  // Delay for DQS signal during Write Operation
   localparam real TPROP_DQS_RD       = 0.00;  // Delay for DQS signal during Read Operation
   localparam real TPROP_PCB_CTRL     = 0.00;  // Delay for Address and Ctrl signals
   localparam real TPROP_PCB_DATA     = 0.00;  // Delay for data signal during Write operation
   localparam real TPROP_PCB_DATA_RD  = 0.00;  // Delay for data signal during Read operation

   wire [DQ_WIDTH-1:0] ddr2_dq_sdram;
   wire [DQS_WIDTH-1:0] ddr2_dqs_sdram;
   wire [DQS_WIDTH-1:0] ddr2_dqs_n_sdram;
   wire [DM_WIDTH-1:0] 	ddr2_dm_sdram;
   reg [DM_WIDTH-1:0] 	ddr2_dm_sdram_tmp;
   reg [CLK_WIDTH-1:0] 	ddr2_ck_sdram;
   reg [CLK_WIDTH-1:0] 	ddr2_ck_n_sdram;
   reg [ROW_WIDTH-1:0] 	ddr2_a_sdram;
   reg [BANK_WIDTH-1:0] ddr2_ba_sdram;
   reg 			ddr2_ras_n_sdram;
   reg 			ddr2_cas_n_sdram;
   reg 			ddr2_we_n_sdram;
   reg [CS_WIDTH-1:0] 	ddr2_cs_n_sdram;
   reg [CKE_WIDTH-1:0] 	ddr2_cke_sdram;
   reg [ODT_WIDTH-1:0] 	ddr2_odt_sdram;

   
   wire [DQ_WIDTH-1:0] 	ddr2_dq_fpga;
   wire [DQS_WIDTH-1:0] ddr2_dqs_fpga;
   wire [DQS_WIDTH-1:0] ddr2_dqs_n_fpga;
   wire [DM_WIDTH-1:0] 	ddr2_dm_fpga;
   wire [CLK_WIDTH-1:0] ddr2_ck_fpga;
   wire [CLK_WIDTH-1:0] ddr2_ck_n_fpga;
   wire [ROW_WIDTH-1:0] ddr2_a_fpga;
   wire [BANK_WIDTH-1:0] ddr2_ba_fpga;
   wire 		 ddr2_ras_n_fpga;
   wire 		 ddr2_cas_n_fpga;
   wire 		 ddr2_we_n_fpga;
   wire [CS_WIDTH-1:0] 	 ddr2_cs_n_fpga;
   wire [CKE_WIDTH-1:0]  ddr2_cke_fpga;
   wire [ODT_WIDTH-1:0]  ddr2_odt_fpga;
   
`endif
   
   
`ifdef USE_SPI_FLASH
   wire        spi_flash_sclk_o;
   wire        spi_flash_ss_o;
   wire        spi_flash_miso_i;
   wire        spi_flash_mosi_o;
   wire        spi_flash_w_n_o;
   wire        spi_flash_hold_n_o;
`endif   

`ifdef USE_ETHERNET
   wire        phy_tx_clk;
   wire [3:0]  phy_tx_data;
   wire        phy_tx_en;
   wire        phy_tx_er;
   wire        phy_rx_clk;
   wire [3:0]  phy_rx_data;
   wire        phy_dv;
   wire        phy_rx_er;
   wire        phy_col;
   wire        phy_crs;
   wire        phy_smi_clk;
   wire        phy_smi_data;
   wire        phy_rst_n;
`endif
   
   
   
   wire       spi1_mosi_o;
   wire       spi1_miso_i;
   wire       spi1_ss_o;
   wire       spi1_sclk_o;
   wire [25:0] gpio;
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
   assign rst_i = rst_n;

   // Tie off some inputs   
   assign spi1_miso_i = 0;
   assign uart0_srx_i = 1;

   ml501 dut 
     (
      .sys_rst_in        		(rst_i),
      .sys_clk_in			(clk_i),
      .sys_clk_in_p			(clk_200_p),
      .sys_clk_in_n			(clk_200_n),
      .usr_rst_in                       (usr_rst_in),
      .usr_rst_out                      (usr_rst_out),
      

      // UART
      .uart0_stx_pad_o			(uart0_stx_o),
      .uart0_srx_pad_i			(uart0_srx_i),
      
      // JTAG
      .dbg_tdo_pad_o			(dbg_tdo_o),
      .dbg_tdi_pad_i			(dbg_tdi_i),
      .dbg_tck_pad_i			(dbg_tck_i),
      .dbg_tms_pad_i			(dbg_tms_i),

`ifdef USE_ETHERNET
      .phy_tx_clk(phy_tx_clk),
      .phy_tx_data(phy_tx_data),
      .phy_tx_en(phy_tx_en),
      .phy_tx_er(phy_tx_er),
      .phy_rx_clk(phy_rx_clk),
      .phy_rx_data(phy_rx_data),
      .phy_dv(phy_dv),
      .phy_rx_er(phy_rx_er),
      .phy_col(phy_col),
      .phy_crs(phy_crs),
      .phy_smi_clk(phy_smi_clk),
      .phy_smi_data(phy_smi_data),
      .phy_rst_n(phy_rst_n),
`endif      
      
`ifdef ML501_MEMORY_SSRAM
      // ZBT SSRAM
      .sram_clk                         (sram_clk),
      .sram_flash_addr                  (sram_flash_addr),
      .sram_cen                         (sram_cen),
      .sram_flash_oe_n                  (sram_flash_oe_n),
      .sram_flash_we_n                  (sram_flash_we_n),
      .sram_bw                          (sram_bw),
      .sram_adv_ld_n                    (sram_adv_ld_n),
      .sram_mode                        (sram_mode),
      .sram_clk_fb                      (sram_clk_fb),
      .sram_flash_data                  (sram_flash_data),
`endif //  `ifdef ML501_MEMORY_SSRAM

`ifdef ML501_MEMORY_DDR2
      .ddr2_a				(ddr2_a_fpga),
      .ddr2_ba				(ddr2_ba_fpga),
      .ddr2_ras_n			(ddr2_ras_n_fpga),
      .ddr2_cas_n			(ddr2_cas_n_fpga),
      .ddr2_we_n			(ddr2_we_n_fpga),
      .ddr2_cs_n			(ddr2_cs_n_fpga),
      .ddr2_odt				(ddr2_odt_fpga),
      .ddr2_cke				(ddr2_cke_fpga),
      .ddr2_dm				(ddr2_dm_fpga),
      .ddr2_ck				(ddr2_ck_fpga),
      .ddr2_ck_n			(ddr2_ck_n_fpga),
      .ddr2_dq				(ddr2_dq_fpga),
      .ddr2_dqs				(ddr2_dqs_fpga),
      .ddr2_dqs_n			(ddr2_dqs_n_fpga),
`endif //  `ifdef ML501_MEMORY_DDR2
      
      
`ifdef USE_SPI_FLASH
      .spi_flash_sclk_pad_o		(spi_flash_sclk_o),
      .spi_flash_ss_pad_o		(spi_flash_ss_o),
      .spi_flash_mosi_pad_o		(spi_flash_mosi_o),
      .spi_flash_w_n_pad_o		(spi_flash_w_n_o),
      .spi_flash_hold_n_pad_o		(spi_flash_hold_n_o),
      .spi_flash_miso_pad_i		(spi_flash_miso_i),
`endif     
      // GPIO
      .gpio			        (gpio)
      );
   
`ifndef POST_SYNTHESIS_SIM
   // Make the RF be quiet
   defparam dut.i_or1k.i_or1200_top.or1200_cpu.or1200_rf.rf_a.ramb16_s36_s36.SIM_COLLISION_CHECK = "NONE";
   defparam dut.i_or1k.i_or1200_top.or1200_cpu.or1200_rf.rf_b.ramb16_s36_s36.SIM_COLLISION_CHECK = "NONE";
`endif
   
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

`ifdef USE_ETHERNET
   
   eth_phy eth_phy0
     (
      // Outputs
      .mtx_clk_o			(phy_tx_clk),
      .mrx_clk_o			(phy_rx_clk),
      .mrxd_o				(phy_rx_data),
      .mrxdv_o				(phy_dv),
      .mrxerr_o				(phy_rx_er),
      .mcoll_o				(phy_col),
      .mcrs_o				(phy_crs),
      // Inouts
      .md_io				(phy_smi_data),
      // Inputs
      .m_rst_n_i			(phy_rst_n),
      .mtxd_i				(phy_tx_data),
      .mtxen_i				(phy_tx_en),
      .mtxerr_i				(phy_tx_er),
      .mdc_i				(phy_smi_clk));
   
`endif
   

   // External memories, if enabled

`ifdef ML501_MEMORY_SSRAM
   wire [18:0] 	sram_a;
   wire [3:0] 	dqp;   
   
   assign sram_a[18:0] = sram_flash_addr[19:1];   
   wire 	sram_ce1b, sram_ce2, sram_ce3b;
   assign sram_ce1b = 1'b0;
   assign sram_ce2 = 1'b1;   
   assign sram_ce3b = 1'b0;   
   assign sram_clk_fb = sram_clk;   

   cy7c1354 ssram0
     (
      // Inouts
      // This model puts each parity bit after each byte, but the ML501's part
      // doesn't, so we wire up the data bus like so.
      .d				({dqp[3],sram_flash_data[31:24],dqp[2],sram_flash_data[23:16],dqp[1],sram_flash_data[15:8],dqp[0],sram_flash_data[7:0]}),
      // Inputs
      .clk				(sram_clk),
      .we_b				(sram_flash_we_n),
      .adv_lb				(sram_adv_ld_n),
      .ce1b				(sram_ce1b),
      .ce2				(sram_ce2),
      .ce3b				(sram_ce3b),
      .oeb				(sram_flash_oe_n),
      .cenb				(sram_cen),
      .mode				(sram_mode),
      .bws				(sram_bw),
      .a				(sram_a));

`endif //  `ifdef ML501_MEMORY_SSRAM



`ifdef ML501_MEMORY_DDR2

`ifndef POST_SYNTHESIS_SIM
   defparam dut.ml501_mc0.ml501_ddr2_wb_if0.ddr2_mig0.SIM_ONLY = 1;
`endif

   always @( * ) begin
      ddr2_ck_sdram        <=  #(TPROP_PCB_CTRL) ddr2_ck_fpga;
      ddr2_ck_n_sdram      <=  #(TPROP_PCB_CTRL) ddr2_ck_n_fpga;
      ddr2_a_sdram    <=  #(TPROP_PCB_CTRL) ddr2_a_fpga;
      ddr2_ba_sdram         <=  #(TPROP_PCB_CTRL) ddr2_ba_fpga;
      ddr2_ras_n_sdram      <=  #(TPROP_PCB_CTRL) ddr2_ras_n_fpga;
      ddr2_cas_n_sdram      <=  #(TPROP_PCB_CTRL) ddr2_cas_n_fpga;
      ddr2_we_n_sdram       <=  #(TPROP_PCB_CTRL) ddr2_we_n_fpga;
      ddr2_cs_n_sdram       <=  #(TPROP_PCB_CTRL) ddr2_cs_n_fpga;
      ddr2_cke_sdram        <=  #(TPROP_PCB_CTRL) ddr2_cke_fpga;
      ddr2_odt_sdram        <=  #(TPROP_PCB_CTRL) ddr2_odt_fpga;
      ddr2_dm_sdram_tmp     <=  #(TPROP_PCB_DATA) ddr2_dm_fpga;//DM signal generation
   end // always @ ( * )
   
   
   // Model delays on bi-directional BUS
   genvar dqwd;
   generate
      for (dqwd = 0;dqwd < DQ_WIDTH;dqwd = dqwd+1) begin : dq_delay
	 WireDelay #
	   (
            .Delay_g     (TPROP_PCB_DATA),
            .Delay_rd    (TPROP_PCB_DATA_RD)
	    )
	 u_delay_dq
	   (
            .A           (ddr2_dq_fpga[dqwd]),
            .B           (ddr2_dq_sdram[dqwd]),
            .reset       (rst_n)
	    );
      end
   endgenerate
   
   genvar dqswd;
   generate
      for (dqswd = 0;dqswd < DQS_WIDTH;dqswd = dqswd+1) begin : dqs_delay
	 WireDelay #
	   (
            .Delay_g     (TPROP_DQS),
            .Delay_rd    (TPROP_DQS_RD)
	    )
	 u_delay_dqs
	   (
            .A           (ddr2_dqs_fpga[dqswd]),
            .B           (ddr2_dqs_sdram[dqswd]),
            .reset       (rst_n)
	    );
	 
	 WireDelay #
	   (
            .Delay_g     (TPROP_DQS),
            .Delay_rd    (TPROP_DQS_RD)
	    )
	 u_delay_dqs_n
	   (
            .A           (ddr2_dqs_n_fpga[dqswd]),
            .B           (ddr2_dqs_n_sdram[dqswd]),
            .reset       (rst_n)
	    );
      end
   endgenerate
   
   assign ddr2_dm_sdram = ddr2_dm_sdram_tmp;

      
   genvar i, j;
   generate
      // if the data width is multiple of 16
      for(j = 0; j < CS_NUM; j = j+1) begin : gen_cs
         for(i = 0; i < DQS_WIDTH/2; i = i+1) begin : gen
            ddr2_model u_mem0
              (
               .ck        (ddr2_ck_sdram[CLK_WIDTH*i/DQS_WIDTH]),
               .ck_n      (ddr2_ck_n_sdram[CLK_WIDTH*i/DQS_WIDTH]),
               .cke       (ddr2_cke_sdram[j]),
               .cs_n      (ddr2_cs_n_sdram[CS_WIDTH*i/DQS_WIDTH]),
               .ras_n     (ddr2_ras_n_sdram),
               .cas_n     (ddr2_cas_n_sdram),
               .we_n      (ddr2_we_n_sdram),
               .dm_rdqs   (ddr2_dm_sdram[(2*(i+1))-1 : i*2]),
               .ba        (ddr2_ba_sdram),
               .addr      (ddr2_a_sdram),
               .dq        (ddr2_dq_sdram[(16*(i+1))-1 : i*16]),
               .dqs       (ddr2_dqs_sdram[(2*(i+1))-1 : i*2]),
               .dqs_n     (ddr2_dqs_n_sdram[(2*(i+1))-1 : i*2]),
               .rdqs_n    (),
               .odt       (ddr2_odt_sdram[ODT_WIDTH*i/DQS_WIDTH])
               );
         end
      end
   endgenerate
   
`endif //  `ifdef ML501_MEMORY_DDR2
   
   
`ifdef USE_SPI_FLASH
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
`endif //  `ifdef USE_SPI_FLASH

initial
  begin
     $display("\nStarting RTL simulation of ml501 board %s test\n", `TEST_NAME_STRING);
`ifdef USE_SDRAM
     $display("Using SDRAM - loading application from SPI flash memory\n");
`endif

`ifdef VCD

 `ifdef ML501_MEMORY_DDR2
//     #81263000; // DDR2 calibration completed
 `endif
     
     $display("VCD in %s\n", {`TEST_RESULTS_DIR,`TEST_NAME_STRING,".vcd"});
     $dumpfile({`TEST_RESULTS_DIR,`TEST_NAME_STRING,".vcd"});

 `ifdef VCD_DEPTH     
     $dumpvars(`VCD_DEPTH);
 `else
     $dumpvars(0);
 `endif
     
`endif
  end

`ifndef POST_SYNTHESIS_SIM
   // Instantiate the monitor
   or1200_monitor monitor();
`endif
   
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
// verilog-library-directories:("." "../rtl" "../../../../bench/verilog")
// End:
