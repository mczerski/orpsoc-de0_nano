//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Xilinx DDR2 controller Wishbone Interface                   ////
////                                                              ////
////  Description                                                 ////
////  Simple interface to the Xilinx MIG generated DDR2 controller////
////  The interface presents four wishbone slaves,                ////  
////  which are mapped into four 32-bit user ports of the MIG     ////
////                                                              ////
////  To Do:                                                      ////
////   Make this a Wishbone B3 registered feedback burst friendly ////
////   server.                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - Julius Baxter, julius.baxter@orsoc.se                 ////
////      - Stefan Kristiansson, stefan@langante.mine.nu          ////
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

module xilinx_ddr2_if ( 
    input [31:0]       wb0_adr_i,
    input 	           wb0_stb_i,
    input 	           wb0_cyc_i,
    input  [2:0]       wb0_cti_i,
    input  [1:0]       wb0_bte_i,
    input 	           wb0_we_i,
    input  [3:0]       wb0_sel_i,
    input  [31:0]      wb0_dat_i,
    output [31:0]      wb0_dat_o,
    output             wb0_ack_o,

    input [31:0]       wb1_adr_i,
    input              wb1_stb_i,
    input              wb1_cyc_i,
    input  [2:0]       wb1_cti_i,
    input  [1:0]       wb1_bte_i,
    input              wb1_we_i,
    input  [3:0]       wb1_sel_i,
    input  [31:0]      wb1_dat_i,
    output [31:0]      wb1_dat_o,
    output             wb1_ack_o,

    input [31:0]       wb2_adr_i,
    input              wb2_stb_i,
    input              wb2_cyc_i,
    input  [2:0]       wb2_cti_i,
    input  [1:0]       wb2_bte_i,
    input              wb2_we_i,
    input  [3:0]       wb2_sel_i,
    input  [31:0]      wb2_dat_i,
    output [31:0]      wb2_dat_o,
    output             wb2_ack_o,

    input [31:0]       wb3_adr_i,
    input              wb3_stb_i,
    input              wb3_cyc_i,
    input  [2:0]       wb3_cti_i,
    input  [1:0]       wb3_bte_i,
    input              wb3_we_i,
    input  [3:0]       wb3_sel_i,
    input  [31:0]      wb3_dat_i,
    output [31:0]      wb3_dat_o,
    output             wb3_ack_o,

    output [12:0]      ddr2_a,
    output [2:0]       ddr2_ba,
    output 	           ddr2_ras_n,
    output 	           ddr2_cas_n,
    output 	           ddr2_we_n,
    output             ddr2_rzq,
    output             ddr2_zio,
    output             ddr2_odt,
    output             ddr2_cke,
    output             ddr2_dm,
    output             ddr2_udm,

    inout [15:0]       ddr2_dq,		  
    inout              ddr2_dqs,
    inout              ddr2_dqs_n,
    inout              ddr2_udqs,
    inout              ddr2_udqs_n,
    output             ddr2_ck,
    output             ddr2_ck_n,

    input 	           ddr2_if_clk,
    input 	           ddr2_if_rst,
    input 	           wb_clk,
    input 	           wb_rst);
   
`include "orpsoc-defines.v"
`include "xilinx_ddr2_params.v"
   wire 	           ddr2_clk; // DDR2 iface domain clock.
   wire 	           ddr2_rst; // reset from the ddr2 module
   
   wire 	           wb0_req;
   reg 		           wb0_req_r;
   reg 		           wb0_ack_write;
   wire 	           wb0_req_new;

   wire                wb1_req;
   reg                 wb1_req_r;
   reg                 wb1_ack_write;
   wire                wb1_req_new;

   wire                wb2_req;
   reg                 wb2_req_r;
   reg                 wb2_ack_write;
   wire                wb2_req_new;

   wire                wb3_req;
   reg                 wb3_req_r;
   reg                 wb3_ack_write;
   wire                wb3_req_new;
   
   // DDR2 MIG interface wires
   wire 	                         ddr2_p0_cmd_full;
   wire 	                         ddr2_p0_wr_full;
   wire 	                         ddr2_p0_wr_en;
   wire 	                         ddr2_p0_cmd_en;
   wire [29:0]                       ddr2_p0_cmd_byte_addr;
   wire [2:0] 	                     ddr2_p0_cmd_instr;
   wire [(C3_P0_DATA_PORT_SIZE)-1:0] ddr2_p0_wr_data;
   wire [(C3_P0_MASK_SIZE)-1:0]      ddr2_p0_wr_mask;
   wire [(C3_P0_DATA_PORT_SIZE)-1:0] ddr2_p0_rd_data;
   wire [5:0]                        ddr2_p0_cmd_bl;
   wire                              ddr2_p0_rd_en;
   wire                              ddr2_p0_cmd_empty;
   wire                              ddr2_p0_wr_empty;
   wire                              ddr2_p0_wr_count;
   wire                              ddr2_p0_wr_underrun;
   wire                              ddr2_p0_wr_error;
   wire                              ddr2_p0_rd_full;
   wire                              ddr2_p0_rd_empty;
   wire                              ddr2_p0_rd_count;
   wire                              ddr2_p0_rd_overflow;
   wire                              ddr2_p0_rd_error;

   wire                              ddr2_p1_cmd_full;
   wire                              ddr2_p1_wr_full;
   wire                              ddr2_p1_wr_en;
   wire                              ddr2_p1_cmd_en;
   wire [29:0]                       ddr2_p1_cmd_byte_addr;
   wire [2:0]                        ddr2_p1_cmd_instr;
   wire [(C3_P1_DATA_PORT_SIZE)-1:0] ddr2_p1_wr_data;
   wire [(C3_P1_MASK_SIZE)-1:0]      ddr2_p1_wr_mask;
   wire [(C3_P1_DATA_PORT_SIZE)-1:0] ddr2_p1_rd_data;
   wire [5:0]                        ddr2_p1_cmd_bl;
   wire                              ddr2_p1_rd_en;
   wire                              ddr2_p1_cmd_empty;
   wire                              ddr2_p1_wr_empty;
   wire                              ddr2_p1_wr_count;
   wire                              ddr2_p1_wr_underrun;
   wire                              ddr2_p1_wr_error;
   wire                              ddr2_p1_rd_full;
   wire                              ddr2_p1_rd_empty;
   wire                              ddr2_p1_rd_count;
   wire                              ddr2_p1_rd_overflow;
   wire                              ddr2_p1_rd_error;
   
   wire                              ddr2_p2_cmd_full;
   wire                              ddr2_p2_wr_full;
   wire                              ddr2_p2_wr_en;
   wire                              ddr2_p2_cmd_en;
   wire [29:0]                       ddr2_p2_cmd_byte_addr;
   wire [2:0]                        ddr2_p2_cmd_instr;
   wire [31:0]                       ddr2_p2_wr_data;
   wire [3:0]                        ddr2_p2_wr_mask;
   wire [31:0]                       ddr2_p2_rd_data;
   wire [5:0]                        ddr2_p2_cmd_bl;
   wire                              ddr2_p2_rd_en;
   wire                              ddr2_p2_cmd_empty;
   wire                              ddr2_p2_wr_empty;
   wire                              ddr2_p2_wr_count;
   wire                              ddr2_p2_wr_underrun;
   wire                              ddr2_p2_wr_error;
   wire                              ddr2_p2_rd_full;
   wire                              ddr2_p2_rd_empty;
   wire                              ddr2_p2_rd_count;
   wire                              ddr2_p2_rd_overflow;
   wire                              ddr2_p2_rd_error;

   wire                              ddr2_p3_cmd_full;
   wire                              ddr2_p3_wr_full;
   wire                              ddr2_p3_wr_en;
   wire                              ddr2_p3_cmd_en;
   wire [29:0]                       ddr2_p3_cmd_byte_addr;
   wire [2:0]                        ddr2_p3_cmd_instr;
   wire [31:0]                       ddr2_p3_wr_data;
   wire [3:0]                        ddr2_p3_wr_mask;
   wire [31:0]                       ddr2_p3_rd_data;
   wire [5:0]                        ddr2_p3_cmd_bl;
   wire                              ddr2_p3_rd_en;
   wire                              ddr2_p3_cmd_empty;
   wire                              ddr2_p3_wr_empty;
   wire                              ddr2_p3_wr_count;
   wire                              ddr2_p3_wr_underrun;
   wire                              ddr2_p3_wr_error;
   wire                              ddr2_p3_rd_full;
   wire                              ddr2_p3_rd_empty;
   wire                              ddr2_p3_rd_count;
   wire                              ddr2_p3_rd_overflow;
   wire                              ddr2_p3_rd_error;

   wire 	                         ddr2_calib_done;
   
   assign wb0_req = wb0_stb_i & wb0_cyc_i & ddr2_calib_done; 
   assign wb1_req = wb1_stb_i & wb1_cyc_i & ddr2_calib_done;
   assign wb2_req = wb2_stb_i & wb2_cyc_i & ddr2_calib_done;
   
   always @(posedge wb_clk) begin
      wb0_req_r <= wb0_req & !wb0_ack_o;
      wb1_req_r <= wb1_req & !wb1_ack_o;
      wb2_req_r <= wb2_req & !wb2_ack_o;
   end
   
   assign wb0_req_new = wb0_req & !wb0_req_r;
   assign wb1_req_new = wb1_req & !wb1_req_r;
   assign wb2_req_new = wb2_req & !wb2_req_r;

   always @(posedge wb_clk) begin
      wb0_ack_write <= wb0_req & wb0_we_i & !wb0_ack_write;
      wb1_ack_write <= wb1_req & wb1_we_i & !wb1_ack_write;
      wb2_ack_write <= wb2_req & wb2_we_i & !wb2_ack_write;
   end
   
   // Map wishbone signals to/from DDR2 MIG controller
   assign ddr2_p0_cmd_byte_addr = {wb0_adr_i[29:2],2'b0};
   assign ddr2_p0_cmd_instr     = {2'b0, !wb0_we_i};
   assign ddr2_p0_cmd_en        = wb0_we_i ? wb0_ack_write : wb0_req_new;
   assign ddr2_p0_cmd_bl        = 0; // => 1 * 32 bit r/w
   assign ddr2_p0_rd_en         = 1;
   assign ddr2_p0_wr_en         = wb0_we_i ? wb0_req_new : 1'b0;
   assign ddr2_p0_wr_data       = wb0_dat_i;
   assign ddr2_p0_wr_mask       = ~wb0_sel_i;
   assign wb0_dat_o             = ddr2_p0_rd_data;
   assign wb0_ack_o             = (wb0_we_i ? wb0_ack_write : !ddr2_p0_rd_empty) & wb0_stb_i;

   assign ddr2_p1_cmd_byte_addr = {wb1_adr_i[29:2],2'b0};
   assign ddr2_p1_cmd_instr     = {2'b0, !wb1_we_i};
   assign ddr2_p1_cmd_en        = wb1_we_i ? wb1_ack_write : wb1_req_new;
   assign ddr2_p1_cmd_bl        = 0; // => 1 * 32 bit r/w
   assign ddr2_p1_rd_en         = 1;
   assign ddr2_p1_wr_en         = wb1_we_i ? wb1_req_new : 1'b0;
   assign ddr2_p1_wr_data       = wb1_dat_i;
   assign ddr2_p1_wr_mask       = ~wb1_sel_i;
   assign wb1_dat_o             = ddr2_p1_rd_data;
   assign wb1_ack_o             = (wb1_we_i ? wb1_ack_write : !ddr2_p1_rd_empty) & wb1_stb_i;

   assign ddr2_p2_cmd_byte_addr = {wb2_adr_i[29:2],2'b0};
   assign ddr2_p2_cmd_instr     = {2'b0, !wb2_we_i};
   assign ddr2_p2_cmd_en        = wb2_we_i ? wb2_ack_write : wb2_req_new;
   assign ddr2_p2_cmd_bl        = 0; // => 1 * 32 bit r/w
   assign ddr2_p2_rd_en         = 1;
   assign ddr2_p2_wr_en         = wb2_we_i ? wb2_req_new : 1'b0;
   assign ddr2_p2_wr_data       = wb2_dat_i;
   assign ddr2_p2_wr_mask       = ~wb2_sel_i;
   assign wb2_dat_o             = ddr2_p2_rd_data;
   assign wb2_ack_o             = (wb2_we_i ? wb2_ack_write : !ddr2_p2_rd_empty) & wb2_stb_i;

  `define WB3_BURST_ADDR_WIDTH 4
  `define WB3_BURST_ADDR_ALIGN (`WB3_BURST_ADDR_WIDTH + 2)
  `define WB3_BURST_LENGTH     (2**`WB3_BURST_ADDR_WIDTH)

   reg [31:0]                      wb3_burst_data_buf[`WB3_BURST_LENGTH-1:0];
   reg [31:`WB3_BURST_ADDR_ALIGN]  wb3_burst_addr;
   reg [`WB3_BURST_ADDR_WIDTH-1:0] wb3_burst_cnt;
   reg                             wb3_bursting;
   wire                            wb3_addr_match;
   reg                             wb3_burst_start;
   reg                             wb3_read_done;
   reg                             wb3_ack_read;
   reg                             wb3_first_req; // guard first req from being read from buffer
 
   assign wb3_req = wb3_stb_i & wb3_cyc_i & ddr2_calib_done; 
   
   always @(posedge wb_clk) begin
      wb3_req_r <= wb3_req & !wb3_ack_o;
   end
   
   assign wb3_req_new    = wb3_req & !wb3_req_r;
   assign wb3_read_req   = wb3_req & !wb3_we_i & !wb3_ack_read;
   assign wb3_addr_match = (wb3_burst_addr == wb3_adr_i[31:`WB3_BURST_ADDR_ALIGN]) & !wb3_first_req;

   always @(posedge wb_clk) begin
     wb3_burst_start <= 0;
     wb3_ack_read    <= 0;
     if (wb3_read_req) begin
       if (wb3_addr_match & (!wb3_bursting)) begin
         wb3_ack_read <= 1;
       end else if (wb3_addr_match & wb3_bursting & (wb3_burst_cnt > wb3_adr_i[`WB3_BURST_ADDR_ALIGN-1:2])) begin
         wb3_ack_read <= 1;
       end else if (wb3_addr_match & wb3_read_done) begin
         wb3_ack_read <= 1;
       end else if (!wb3_bursting & !wb3_burst_start) begin
         wb3_burst_start <= 1;
       end
     end
   end

   always @(posedge wb_clk) begin
     wb3_read_done <= 0;
     if (wb_rst) begin
       wb3_burst_cnt <= 0;
       wb3_bursting  <= 0;
       wb3_first_req <= 1;
     end else if (wb3_burst_start & !wb3_bursting) begin
       wb3_first_req <= 0;
       wb3_burst_cnt <= 0;
       wb3_bursting  <= 1;
       wb3_burst_addr <= wb3_adr_i[31:`WB3_BURST_ADDR_ALIGN];
     end else if (!ddr2_p3_rd_empty) begin
       wb3_burst_data_buf[wb3_burst_cnt] <= ddr2_p3_rd_data;
       wb3_burst_cnt <= wb3_burst_cnt + 1;
       if (&wb3_burst_cnt)
         wb3_bursting <= 0;      
       if (wb3_burst_cnt >= wb3_adr_i[`WB3_BURST_ADDR_ALIGN-1:2])
         wb3_read_done <= 1;
     end
   end
   
   always @(posedge wb_clk) begin
      wb3_ack_write <= wb3_req & wb3_we_i & !wb3_ack_write & !ddr2_p3_cmd_full;
   end

   assign ddr2_p3_cmd_byte_addr = wb3_we_i ? {wb3_adr_i[29:2],2'b0} : {wb3_adr_i[29:`WB3_BURST_ADDR_ALIGN],/*`WB3_BURST_ADDR_ALIGN*/6'b0};
   assign ddr2_p3_cmd_instr     = {2'b0, !wb3_we_i};
   assign ddr2_p3_cmd_en        = wb3_we_i ? wb3_ack_write : wb3_burst_start;
   assign ddr2_p3_cmd_bl        = wb3_we_i ? 0 : `WB3_BURST_LENGTH-1;
   assign ddr2_p3_rd_en         = 1;
   assign ddr2_p3_wr_en         = wb3_we_i ? wb3_req_new : 1'b0;
   assign ddr2_p3_wr_data       = wb3_dat_i;
   assign ddr2_p3_wr_mask       = ~wb3_sel_i;
   assign wb3_ack_o             = (wb3_we_i ? wb3_ack_write : wb3_ack_read) & wb3_stb_i;
   assign wb3_dat_o             = wb3_burst_data_buf[wb3_adr_i[`WB3_BURST_ADDR_ALIGN-1:2]];

 ddr2_mig  #
  (
   .C3_P0_MASK_SIZE       (C3_P0_MASK_SIZE),
   .C3_P0_DATA_PORT_SIZE  (C3_P0_DATA_PORT_SIZE),
   .C3_P1_MASK_SIZE       (C3_P1_MASK_SIZE),
   .C3_P1_DATA_PORT_SIZE  (C3_P1_DATA_PORT_SIZE),
   .DEBUG_EN              (DEBUG_EN),       
   .C3_MEMCLK_PERIOD      (C3_MEMCLK_PERIOD),       
   .C3_CALIB_SOFT_IP      (C3_CALIB_SOFT_IP),       
   .C3_SIMULATION         (C3_SIMULATION),       
   .C3_RST_ACT_LOW        (C3_RST_ACT_LOW),       
   .C3_INPUT_CLK_TYPE     (C3_INPUT_CLK_TYPE),       
   .C3_MEM_ADDR_ORDER     (C3_MEM_ADDR_ORDER),       
   .C3_NUM_DQ_PINS        (C3_NUM_DQ_PINS),       
   .C3_MEM_ADDR_WIDTH     (C3_MEM_ADDR_WIDTH),       
   .C3_MEM_BANKADDR_WIDTH (C3_MEM_BANKADDR_WIDTH)       
   )
   ddr2_mig
   (

    .mcb3_dram_dq         (ddr2_dq),
    .mcb3_dram_a          (ddr2_a),
    .mcb3_dram_ba         (ddr2_ba),
    .mcb3_dram_ras_n      (ddr2_ras_n),
    .mcb3_dram_cas_n      (ddr2_cas_n),
    .mcb3_dram_we_n       (ddr2_we_n),
    .mcb3_dram_odt        (ddr2_odt),
    .mcb3_dram_cke        (ddr2_cke),
    .mcb3_dram_dm         (ddr2_dm),
    .mcb3_dram_udqs       (ddr2_udqs),        
    .mcb3_dram_udqs_n     (ddr2_udqs_n), 
    .mcb3_rzq             (ddr2_rzq),
    .mcb3_zio             (ddr2_zio),
    .mcb3_dram_udm        (ddr2_udm),
    .c3_sys_clk           (ddr2_if_clk),
    .c3_sys_rst_n         (ddr2_if_rst),
    .c3_calib_done        (ddr2_calib_done),
    .c3_clk0              (ddr2_clk),
    .c3_rst0              (ddr2_rst),
    .mcb3_dram_dqs        (ddr2_dqs),
    .mcb3_dram_dqs_n      (ddr2_dqs_n),
    .mcb3_dram_ck         (ddr2_ck),          
    .mcb3_dram_ck_n       (ddr2_ck_n),
    .c3_p0_cmd_clk        (wb_clk),
    .c3_p0_cmd_en         (ddr2_p0_cmd_en),
    .c3_p0_cmd_instr      (ddr2_p0_cmd_instr),
    .c3_p0_cmd_bl         (ddr2_p0_cmd_bl),
    .c3_p0_cmd_byte_addr  (ddr2_p0_cmd_byte_addr),
    .c3_p0_cmd_empty      (ddr2_p0_cmd_empty),
    .c3_p0_cmd_full       (ddr2_p0_cmd_full),
    .c3_p0_wr_clk         (wb_clk),
    .c3_p0_wr_en          (ddr2_p0_wr_en),
    .c3_p0_wr_mask        (ddr2_p0_wr_mask),
    .c3_p0_wr_data        (ddr2_p0_wr_data),
    .c3_p0_wr_full        (ddr2_p0_wr_full),
    .c3_p0_wr_empty       (ddr2_p0_wr_empty),
    .c3_p0_wr_count       (ddr2_p0_wr_count),
    .c3_p0_wr_underrun    (ddr2_p0_wr_underrun),
    .c3_p0_wr_error       (ddr2_p0_wr_error),
    .c3_p0_rd_clk         (wb_clk),
    .c3_p0_rd_en          (ddr2_p0_rd_en),
    .c3_p0_rd_data        (ddr2_p0_rd_data),
    .c3_p0_rd_full        (ddr2_p0_rd_full),
    .c3_p0_rd_empty       (ddr2_p0_rd_empty),
    .c3_p0_rd_count       (ddr2_p0_rd_count),
    .c3_p0_rd_overflow    (ddr2_p0_rd_overflow),
    .c3_p0_rd_error       (ddr2_p0_rd_error),
    .c3_p1_cmd_clk        (wb_clk),
    .c3_p1_cmd_en         (ddr2_p1_cmd_en),
    .c3_p1_cmd_instr      (ddr2_p1_cmd_instr),
    .c3_p1_cmd_bl         (ddr2_p1_cmd_bl),
    .c3_p1_cmd_byte_addr  (ddr2_p1_cmd_byte_addr),
    .c3_p1_cmd_empty      (ddr2_p1_cmd_empty),
    .c3_p1_cmd_full       (ddr2_p1_cmd_full),
    .c3_p1_wr_clk         (wb_clk),
    .c3_p1_wr_en          (ddr2_p1_wr_en),
    .c3_p1_wr_mask        (ddr2_p1_wr_mask),
    .c3_p1_wr_data        (ddr2_p1_wr_data),
    .c3_p1_wr_full        (ddr2_p1_wr_full),
    .c3_p1_wr_empty       (ddr2_p1_wr_empty),
    .c3_p1_wr_count       (ddr2_p1_wr_count),
    .c3_p1_wr_underrun    (ddr2_p1_wr_underrun),
    .c3_p1_wr_error       (ddr2_p1_wr_error),
    .c3_p1_rd_clk         (wb_clk),
    .c3_p1_rd_en          (ddr2_p1_rd_en),
    .c3_p1_rd_data        (ddr2_p1_rd_data),
    .c3_p1_rd_full        (ddr2_p1_rd_full),
    .c3_p1_rd_empty       (ddr2_p1_rd_empty),
    .c3_p1_rd_count       (ddr2_p1_rd_count),
    .c3_p1_rd_overflow    (ddr2_p1_rd_overflow),
    .c3_p1_rd_error       (ddr2_p1_rd_error),
    .c3_p2_cmd_clk        (wb_clk),
    .c3_p2_cmd_en         (ddr2_p2_cmd_en),
    .c3_p2_cmd_instr      (ddr2_p2_cmd_instr),
    .c3_p2_cmd_bl         (ddr2_p2_cmd_bl),
    .c3_p2_cmd_byte_addr  (ddr2_p2_cmd_byte_addr),
    .c3_p2_cmd_empty      (ddr2_p2_cmd_empty),
    .c3_p2_cmd_full       (ddr2_p2_cmd_full),
    .c3_p2_wr_clk         (wb_clk),
    .c3_p2_wr_en          (ddr2_p2_wr_en),
    .c3_p2_wr_mask        (ddr2_p2_wr_mask),
    .c3_p2_wr_data        (ddr2_p2_wr_data),
    .c3_p2_wr_full        (ddr2_p2_wr_full),
    .c3_p2_wr_empty       (ddr2_p2_wr_empty),
    .c3_p2_wr_count       (ddr2_p2_wr_count),
    .c3_p2_wr_underrun    (ddr2_p2_wr_underrun),
    .c3_p2_wr_error       (ddr2_p2_wr_error),
    .c3_p2_rd_clk         (wb_clk),
    .c3_p2_rd_en          (ddr2_p2_rd_en),
    .c3_p2_rd_data        (ddr2_p2_rd_data),
    .c3_p2_rd_full        (ddr2_p2_rd_full),
    .c3_p2_rd_empty       (ddr2_p2_rd_empty),
    .c3_p2_rd_count       (ddr2_p2_rd_count),
    .c3_p2_rd_overflow    (ddr2_p2_rd_overflow),
    .c3_p2_rd_error       (ddr2_p2_rd_error),
    .c3_p3_cmd_clk        (wb_clk),
    .c3_p3_cmd_en         (ddr2_p3_cmd_en),
    .c3_p3_cmd_instr      (ddr2_p3_cmd_instr),
    .c3_p3_cmd_bl         (ddr2_p3_cmd_bl),
    .c3_p3_cmd_byte_addr  (ddr2_p3_cmd_byte_addr),
    .c3_p3_cmd_empty      (ddr2_p3_cmd_empty),
    .c3_p3_cmd_full       (ddr2_p3_cmd_full),
    .c3_p3_wr_clk         (wb_clk),
    .c3_p3_wr_en          (ddr2_p3_wr_en),
    .c3_p3_wr_mask        (ddr2_p3_wr_mask),
    .c3_p3_wr_data        (ddr2_p3_wr_data),
    .c3_p3_wr_full        (ddr2_p3_wr_full),
    .c3_p3_wr_empty       (ddr2_p3_wr_empty),
    .c3_p3_wr_count       (ddr2_p3_wr_count),
    .c3_p3_wr_underrun    (ddr2_p3_wr_underrun),
    .c3_p3_wr_error       (ddr2_p3_wr_error),
    .c3_p3_rd_clk         (wb_clk),
    .c3_p3_rd_en          (ddr2_p3_rd_en),
    .c3_p3_rd_data        (ddr2_p3_rd_data),
    .c3_p3_rd_full        (ddr2_p3_rd_full),
    .c3_p3_rd_empty       (ddr2_p3_rd_empty),
    .c3_p3_rd_count       (ddr2_p3_rd_count),
    .c3_p3_rd_overflow    (ddr2_p3_rd_overflow),
    .c3_p3_rd_error       (ddr2_p3_rd_error)    
   );

   ////////////////////////////////////////////////////////////////////////
   //
   // Xilinx ChipScope
   // 
   ////////////////////////////////////////////////////////////////////////
/*
   wire [35:0] ila0_ctrl;
	
   chipscope_icon icon0 (
    .CONTROL0(ila0_ctrl) 		// INOUT BUS [35:0]
   );

	chipscope_ila ila0 (
    .CONTROL(ila0_ctrl), 		// INOUT BUS [35:0]
    .CLK(wb_clk), 				// IN
    .TRIG0(wb_adr_i), 			// IN BUS [31:0]
    .TRIG1(wb_dat_i), 			// IN BUS [31:0]
    .TRIG2(wb_cyc_i), 			// IN BUS [0:0]
    .TRIG3(wb_dat_o), 			// IN BUS [31:0]
    .TRIG4(wb_we_i), 			// IN BUS [0:0]
    .TRIG5(wb_stb_i), 			// IN BUS [0:0]
    .TRIG6(wb_sel_i), 			// IN BUS [3:0]
    .TRIG7(wb_ack_o), 			// IN BUS [0:0]
    .TRIG8(ddr2_p0_cmd_en),	        // IN BUS [0:0]
    .TRIG9(ddr2_p0_wr_en),  	        // IN BUS [0:0]
    .TRIG10(wb_cti_i),  	        // IN BUS [2:0]
    .TRIG11(wb_bte_i), 	                // IN BUS [1:0]
    .TRIG12({ddr2_p0_cmd_full,
             ddr2_p0_wr_empty,ddr2_p0_wr_full,
             ddr2_p0_wr_underrun,ddr2_p0_wr_error,
             ddr2_p0_rd_overflow,ddr2_p0_rd_error})           // IN BUS [6:0]
   );
  */ 

endmodule // atlys_ddr2_if
// Local Variables:
// verilog-library-directories:("." "ddr2_mig")
// verilog-library-extensions:(".v" ".h")
// End:
