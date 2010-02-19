//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Xilinx ML501 Memory controller Wishbone Interface           ////
////                                                              ////
////  Description                                                 ////
////  Module which can instantiate the different external memory  ////
////  control modules, as well as the internal BRAMS.             ////
////                                                              ////
////  To Do:                                                      ////
////   Fix the addressing (letting internal SRAMs take lowest     ////
////   addresses, followed by next biggest memory server, ect)    ////
////                                                              ////
////  Author(s):                                                  ////
////      - Julius Baxter, julius.baxter@orsoc.se                 ////
////                                                              ////
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
/* Memory and memory control module for ml501 board */
`include "ml501_defines.v"
module ml501_mc
  (
    input [31:0]       wb_adr_i,
    input 	       wb_stb_i,
    input 	       wb_cyc_i,
    input 	       wb_we_i,
    input [3:0]        wb_sel_i,
    input [31:0]       wb_dat_i,
    output [31:0]      wb_dat_o,
    output 	       wb_ack_o,
   
`ifdef ML501_MEMORY_SSRAM
    output	       sram_clk,
    input 	       sram_clk_fb,
    output [21:1]      sram_addr,
    inout [31:0]       sram_dq_io,
    output	       sram_ce_l,
    output	       sram_oe_l,    
    output	       sram_we_l,
    output [3:0]       sram_bw_l,
    output 	       sram_adv_ld_l,
    output 	       sram_mode,
`endif //  `ifdef ML501_MEMORY_SSRAM

`ifdef ML501_MEMORY_DDR2

    output [12:0]      ddr2_a,
    output [1:0]       ddr2_ba,
    output 	       ddr2_ras_n,
    output 	       ddr2_cas_n,
    output 	       ddr2_we_n,
    output [1:0]       ddr2_cs_n,
    output [1:0]       ddr2_odt,
    output [1:0]       ddr2_cke,
    output [7:0]       ddr2_dm,

    inout [63:0]       ddr2_dq,			  
    inout [7:0]        ddr2_dqs,
    inout [7:0]        ddr2_dqs_n,
    output [1:0]       ddr2_ck,
    output [1:0]       ddr2_ck_n,

    input 	       ddr2_if_clk,
`endif //  `ifdef ML501_MEMORY_DDR2
    
    input 	       clk_200,
    input 	       wb_clk,
    input 	       wb_rst);

`ifdef ML501_MEMORY_STARTUP
   parameter startup_size = `ML501_MEMORY_STARTUP_ADDR_SPAN;
`else
   parameter startup_size = 0;
`endif
   
    wire [31:0]        wbs_strtup_dat_o;
    wire [31:0]        wbs_strtup_dat_i;
    wire [31:0]        wbs_strtup_adr_i;
    wire [3:0] 	       wbs_strtup_sel_i;
    wire 	       wbs_strtup_stb_i;
    wire 	       wbs_strtup_cyc_i;
    wire 	       wbs_strtup_ack_o;
   parameter wbs_strtup_err_o = 1'b0;

   wire [31:0] 	       wbs_mc_dat_o;
   wire [31:0] 	       wbs_mc_dat_i;
   wire [31:0] 	       wbs_mc_adr_i;
   wire [3:0] 	       wbs_mc_sel_i;
   wire [2:0]	       wbs_mc_cti_i;
   wire 	       wbs_mc_stb_i;
   wire 	       wbs_mc_cyc_i;
   wire 	       wbs_mc_ack_o;
   parameter wbs_mc_err_o = 1'b0;

   wire 	       mem_sel;   

   // In to startup memory
   assign wbs_strtup_adr_i = wb_adr_i;
   assign wbs_strtup_dat_i = wb_dat_i;
   assign wbs_strtup_sel_i = wb_sel_i;
   assign wbs_strtup_cyc_i = wb_cyc_i;
   assign wbs_strtup_we_i = wb_we_i;

   // In to larger memory controller
   assign wbs_mc_adr_i = wb_adr_i;
   assign wbs_mc_dat_i = wb_dat_i;
   assign wbs_mc_sel_i = wb_sel_i;
   assign wbs_mc_cyc_i = wb_cyc_i;
   assign wbs_mc_we_i = wb_we_i;
   assign wbs_mc_cti_i = 0;

   assign mem_sel = ( wb_adr_i >= startup_size);   
   
   // Assign signals according to which memory should be used
   assign wbs_strtup_stb_i = mem_sel ? 0 : wb_stb_i;
   assign wbs_mc_stb_i      = mem_sel ? wb_stb_i : 0;
   
   assign wb_ack_o = mem_sel ? wbs_mc_ack_o : wbs_strtup_ack_o;
   assign wb_dat_o = mem_sel ? wbs_mc_dat_o : wbs_strtup_dat_o;

`ifdef ML501_MEMORY_STARTUP   
   /* On-chip startup RAM */
   ml501_startup ml501_startup0
   (
    .wb_adr_i(wbs_strtup_adr_i),
    .wb_stb_i(wbs_strtup_stb_i),
    .wb_cyc_i(wbs_strtup_cyc_i),
    .wb_we_i(wbs_strtup_we_i),
    .wb_sel_i(wbs_strtup_sel_i),
    .wb_dat_o(wbs_strtup_dat_o),
    .wb_dat_i(wbs_strtup_dat_i),
    .wb_ack_o(wbs_strtup_ack_o),
    .wb_clk(wb_clk),
    .wb_rst(wb_rst)
    );
   defparam  ml501_startup0.mem_span = startup_size;
   defparam ml501_startup0.adr_width = `ML501_MEMORY_STARTUP_ADDR_WIDTH;   
`else // !`ifdef ML501_MEMORY_STARTUP
   assign wbs_strtup_dat_o = 0;
   assign wb_strtup_ack_o = 0;
`endif // !`ifdef ML501_MEMORY_STARTUP
   
`ifdef ML501_MEMORY_ONCHIP
   parameter ram_wb_dat_width = 32;
   // From board defines
   parameter ram_wb_adr_width = `ML501_MEMORY_ONCHIP_ADDRESS_WIDTH; 
   parameter ram_wb_mem_size  = ((`ML501_MEMORY_ONCHIP_SIZE_BYTES)/4);

   ram_wb
     #
     (
      .dat_width(ram_wb_dat_width),
      .adr_width(ram_wb_adr_width),
      .mem_size(ram_wb_mem_size)
      )
   ram_wb0
     (
      .dat_i(wbs_mc_dat_i),
      .dat_o(wbs_mc_dat_o),
      .sel_i(wbs_mc_sel_i),
      .adr_i(wbs_mc_adr_i[ram_wb_adr_width-1:2]),
      .we_i (wbs_mc_we_i),
      .cti_i(wbs_mc_cti_i),
      .stb_i(wbs_mc_stb_i),
      .cyc_i(wbs_mc_cyc_i),
      .ack_o(wbs_mc_ack_o),
      .clk_i(wb_clk),
      .rst_i(wb_rst)
      );
`else // !`ifdef ML501_MEMORY_ONCHIP
 `ifdef ML501_MEMORY_SSRAM

   /* ZBT SSRAM controller */

   ssram_controller ssram_controller0
     (
      // Outputs
      .wb_dat_o				(wbs_mc_dat_o),
      .wb_ack_o				(wbs_mc_ack_o),
      .sram_clk				(sram_clk),
      .sram_addr			(sram_addr),
      .sram_ce_l			(sram_ce_l),
      .sram_oe_l			(sram_oe_l),
      .sram_we_l			(sram_we_l),
      .sram_bw_l			(sram_bw_l),
      .sram_adv_ld_l			(sram_adv_ld_l),
      .sram_mode			(sram_mode),
      // Inouts
      .sram_dq_io			(sram_dq_io),
      // Inputs
      .wb_adr_i				(wbs_mc_adr_i),
      .wb_stb_i				(wbs_mc_stb_i),
      .wb_cyc_i				(wbs_mc_cyc_i),
      .wb_we_i				(wbs_mc_we_i),
      .wb_sel_i				(wbs_mc_sel_i),
      .wb_dat_i				(wbs_mc_dat_i),
      .wb_clk				(wb_clk),
      .wb_rst				(wb_rst),
      .clk_200			        (clk_200),
      .sram_clk_fb			(sram_clk_fb));
   
 `else
  `ifdef ML501_MEMORY_DDR2
   
   /* DDR2 SDRAM controller */

   /* ml501_ddr2_wb_if AUTO_TEMPLATE */

   ml501_ddr2_wb_if ml501_ddr2_wb_if0
     (

      .wb_dat_o				(wbs_mc_dat_o[31:0]),
      .wb_ack_o				(wbs_mc_ack_o),
      .wb_adr_i				(wbs_mc_adr_i[31:0]),
      .wb_stb_i				(wbs_mc_stb_i),
      .wb_cyc_i				(wbs_mc_cyc_i),
      .wb_we_i				(wbs_mc_we_i),
      .wb_sel_i				(wbs_mc_sel_i[3:0]),
      .wb_dat_i				(wbs_mc_dat_i[31:0]),

      .ddr2_a				(ddr2_a[12:0]),
      .ddr2_ba				(ddr2_ba[1:0]),
      .ddr2_ras_n			(ddr2_ras_n),
      .ddr2_cas_n			(ddr2_cas_n),
      .ddr2_we_n			(ddr2_we_n),
      .ddr2_cs_n			(ddr2_cs_n),
      .ddr2_odt				(ddr2_odt),
      .ddr2_cke				(ddr2_cke),
      .ddr2_dm				(ddr2_dm[7:0]),
      .ddr2_ck				(ddr2_ck[1:0]),
      .ddr2_ck_n			(ddr2_ck_n[1:0]),
      .ddr2_dq				(ddr2_dq[63:0]),
      .ddr2_dqs				(ddr2_dqs[7:0]),
      .ddr2_dqs_n			(ddr2_dqs_n[7:0]),

      .ddr2_if_clk      		(clk_200),
      .idly_clk_200			(clk_200),
      .wb_clk				(wb_clk),
      .wb_rst				(wb_rst));
  
`else

   /* No memory controller*/
   dummy_slave 
     # ( .value(32'h00000000))
   mc_ds
     ( 
       .dat_o(wbs_mc_dat_o), 
       .stb_i(wbs_mc_stb_i), 
       .cyc_i(wbs_mc_cyc_i), 
       .ack_o(wbs_mc_ack_o), 
       .clk(wb_clk), 
       .rst(wb_rst) 
       );

   always @(posedge wb_clk)
     if (wbs_mc_stb_i & wbs_mc_cyc_i & wbs_mc_ack_o)
       begin
	  $display("* Warning - access to non-existent memory location, 0x%x\n",wb_adr_i);	  
       end
   
   
  `endif  
 `endif // !`ifdef ML501_MEMORY_SSRAM
`endif // !`ifdef ML501_MEMORY_ONCHIP
endmodule // ml501_mem_ctrl

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-extensions:(".v" ".h")
// End:
