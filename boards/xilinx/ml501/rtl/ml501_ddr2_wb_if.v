//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Xilinx ML501 DDR2 controller Wishbone Interface             ////
////                                                              ////
////  Description                                                 ////
////  Simple interface to the Xilinx MIG generated DDR2 controller////
////                                                              ////
////  To Do:                                                      ////
////   Increase usage of cache BRAM to maximum (currently only    ////
////   256 bytes out of about 8192)                               ////
////   Make this a Wishbone B3 registered feedback burst friendly ////
////   server.                                                    ////
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
/*
 * The controller is design to stream lots of data out at the DDR2 controller's
 * rate. All we implement here is enough to do the simplest accesses into a 
 * small cache, which eases the domain crossing headaches.
 * 
 * This was originally written to handle a DDR2 part which is doing burst length
 * of 4 as a minimum via a databus which is 64-bits wide.
 * 
 * This means the smallest accesses is 4*64=256-bits or 32-bytes.
 * 
 * We are bridging to a 32-bit wide system bus, so this means we must handle
 * accesses in 8-word lots.
 * 
 * A simple cache mechanism has been implemented, meaning we check if the cached
 * data has been written to, and therefore needs writing back to the main memory
 * before any other access can occur.
 * 
 * Cache memory:
 * The cache memory is a core-generated module, instantiating something out
 * of the XilinxCoreLib. The reason is because an arrangement or RAMB36s with
 * different sized A and B data in/out ports can't be instantiated directly
 * for some reason.
 * What we have is side A with 32-bits, and side B with 128-bits wide.
 * 
 * TODO:
 * This only supports 8-words for now but can easily be expanded, although 
 * multiple way/associativity caching will require some extra work to handle
 * multiple cached addresses.
 * 
 * But it should be easy enough to make this thing cache as much as its RAMB
 * resources allow (4-RAMB16s becuase due to the 128-bit DDR2-side interface)
 * which is about 8Kbyte.
 * 
 * Multi-cycle paths:
 * Write:
 * To indicate that a writeback is occuring, a system-bus domain (wishbone, in
 * this case) signal is set, and then sampled in the controller domain whenever
 * a system-bus domain clock edge is detected. This register is "do_writeback"
 * and then the controller domain register "ddr2_write_done" is asserted when
 * the data has been written out of the RAMs and into the controller's fifos.
 * "ddr2_write_done" is then sampled by the system-bus domain and "do_writeback"
 * So there are paths between:
 * ( register -> (sampled by) -> register )
 * wb_clk:do_writeback -> ddr2_clk:do_writeback_ddr2_shifter
 * wb_clk:do_writeback -> ddr2_clk:ddr2_write_done
 * ddr2_clk:ddr2_write_done -> wb_clk:do_writeback
 * 
 * Read:
 * The only signal crossing we have here is the one indicating the read data
 * has arrived into the cache RAM from the controller. The controller domain
 * register "ddr2_read_done" is set, and sampled in the system-bus domain by the
 * logic controlling the "do_readfrom" register. "ddr2_read_done" is cleared
 * when the controller domain sees that "do_readfrom" has been de-asserted.
 * So there are paths between:
 * ( register -> (sampled by) -> register )
 * ddr2_clk:ddr2_read_done -> wb_clk:do_readfrom
 * wb_clk:do_readfrom -> ddr2_clk:ddr2_read_done
 * 
*/
module ml501_ddr2_wb_if ( 
    input [31:0]       wb_adr_i,
    input 	       wb_stb_i,
    input 	       wb_cyc_i,
    input 	       wb_we_i,
    input [3:0]        wb_sel_i,
    input [31:0]       wb_dat_i,
    output [31:0]      wb_dat_o,
    output reg 	       wb_ack_o,
			  
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
    input 	       idly_clk_200,
			  
    input 	       wb_clk,
    input 	       wb_rst);
   
`include "ml501_ddr2_params.vh"

   wire 	       ddr2_clk; // DDR2 iface domain clock.
   wire 	       ddr2_rst; // reset from the ddr2 module
   
   wire 	       wb_req;   
   reg 		       wb_req_r;
   reg 		       wb_ack_o_r;   
   
   wire 	       wb_req_new;
   reg 		       wb_req_new_r;
   
   reg 		       wb_req_addr_hit;
   
   reg 		       cached_addr_valid;
   
   reg [31:5] 	       cached_addr;
   
   wire 	       cache_hit;
   
   reg 		       cache_dirty;
   
   reg [2:0] 	       wb_req_cache_word_addr;
   
   wire 	       wb_cache_en;
   
   reg 		       do_writeback, do_writeback_r;
   wire 	       do_writeback_start, do_writeback_finished;
   wire 	       doing_writeback;
   
   reg 		       do_readfrom, do_readfrom_r;   
   wire 	       do_readfrom_start, do_readfrom_finished;
   wire 	       doing_readfrom;
   
   
   // Domain crossing logic
   reg 		       wb_clk_r;
   reg 		       wb_clk_in_ddr2_clk;
   
   reg 		       wb_clk_in_ddr2_clk_r;
   wire 	       wb_clk_edge;   
   reg [2:0] 	       ddr2_clk_phase;
   // Sample when clk phase is 0
   reg [3:0] 	       do_writeback_ddr2_shifter;
   reg [3:0] 	       do_writeback_ddr2_shifter_r;
   reg 		       do_writeback_ddr2_fifo_we;
   reg 		       ddr2_write_done;   
   
   // Currently, ddr2-side of cache is address is a single bit
   reg 		       ddr2_cache_addr;
   wire [127:0]        ddr2_cache_data_o;
   reg 		       rd_data_valid_r;
   reg 		       ddr2_read_done;
   
   // DDR2 MIG interface wires
   wire 	       app_af_afull;
   wire 	       app_wdf_afull;
   wire 	       app_wdf_wren;
   wire 	       app_af_wren;
   wire [30:0] 	       app_af_addr;
   wire [2:0] 	       app_af_cmd;
   wire [(APPDATA_WIDTH)-1:0] app_wdf_data;
   wire [(APPDATA_WIDTH/8)-1:0] app_wdf_mask_data;
   wire 			rd_data_valid;
   wire [(APPDATA_WIDTH)-1:0] 	rd_data_fifo_out;
   wire 			phy_init_done;
   
   
   assign cache_hit = (cached_addr ==  wb_adr_i[31:5]) & cached_addr_valid;
   
   // Wishbone request detection
   assign wb_req = wb_stb_i & wb_cyc_i & phy_init_done; 
   
   always @(posedge wb_clk)
     wb_req_r <= wb_req;
   
   assign wb_req_new = wb_req & !wb_req_r;
   
   always @(posedge wb_clk)
     wb_req_new_r <= wb_req_new;
   
   // Register whether it's a hit or not
   // As more lines are added, add them to this check.
   always @(posedge wb_clk)
     if (wb_rst)
       wb_req_addr_hit <= 0;   
     else 
       wb_req_addr_hit <= wb_req & cache_hit & cached_addr_valid;
   
   always @(posedge wb_clk)
     if (wb_rst)
       wb_ack_o <= 0;
     else
       wb_ack_o <= wb_req_addr_hit & !wb_ack_o & !wb_ack_o_r;
   
   always @(posedge wb_clk)
     wb_ack_o_r <= wb_ack_o;
   
   // Address valid logic
   always @(posedge wb_clk)
     if (wb_rst)
       cached_addr_valid <= 0;
     else if (do_readfrom_finished)
       cached_addr_valid <= 1;
     else if ( do_writeback_finished ) // Data written back, cache not valid
       cached_addr_valid <= 0;
     else if (wb_req & !cache_hit & cached_addr_valid & !cache_dirty)
       // Invalidate cache so a readfrom begins
       cached_addr_valid <= 0;
   
   // Address cacheing
   always @(posedge wb_clk)
     if (wb_rst)
       cached_addr <= 0;
     else if (do_readfrom_start)
       cached_addr <= wb_adr_i[31:5];
   
   // Cache dirty signal
   always @(posedge wb_clk)
     if (wb_rst)
       cache_dirty <= 0;
     else if (wb_req & wb_we_i & wb_req_addr_hit & wb_ack_o)
       cache_dirty <= 1;
     else if (!cached_addr_valid & cache_dirty)
       cache_dirty <= 0;

   // Wishbone side of cache enable. Important!
   // 1. Enable on first access, if it's not a write
   // 2. Enable if we've just refreshed the cache
   // 3. Enable on ACK'ing for a write
   assign wb_cache_en = (wb_req_new & !wb_we_i) | do_readfrom_finished | 
			(wb_req_addr_hit & wb_stb_i & !wb_we_i & !wb_ack_o) |
			(wb_ack_o & wb_we_i);
   
   // Writeback detect logic
   always @(posedge wb_clk)
     if (wb_rst)
       do_writeback <= 0;
     else if (ddr2_write_done) // DDR2 domain signal
       do_writeback <= 0;
     else if (wb_req & !cache_hit & cached_addr_valid & !doing_writeback & cache_dirty)
       do_writeback <= 1;
   
   
   always @(posedge wb_clk)
     do_writeback_r <= do_writeback;
   
   assign do_writeback_start = do_writeback & !do_writeback_r;
   assign do_writeback_finished = !do_writeback & do_writeback_r;
   assign doing_writeback = do_writeback | do_writeback_r;
      
   // DDR2 Read detect logic
   always @(posedge wb_clk)
     if (wb_rst)
       do_readfrom <= 0;
     else if (ddr2_read_done) // DDR2 domain signal
       do_readfrom <= 0;
     else if (wb_req & !cache_hit & !cached_addr_valid & !doing_readfrom & !cache_dirty)
       do_readfrom <= 1;

   always @(posedge wb_clk)
     do_readfrom_r <= do_readfrom;

   assign do_readfrom_start = do_readfrom & !do_readfrom_r;
   assign do_readfrom_finished = !do_readfrom & do_readfrom_r;
   assign doing_readfrom = do_readfrom | do_readfrom_r;   

   // Address fifo signals
   assign app_af_wren = (do_writeback_finished | do_readfrom_start);
   assign app_af_cmd[0] = do_readfrom_start; // 1 - read, 0 - write
   assign app_af_cmd[2:1] = 0;
   assign app_af_addr = do_readfrom_start ?  {2'd0, wb_adr_i[31:5],2'd0} :
			{2'd0,cached_addr,2'd0};
   
   assign app_wdf_wren = do_writeback_ddr2_fifo_we;
   assign app_wdf_data = ddr2_cache_data_o;
   assign app_wdf_mask_data = 0;   
   
   always @(posedge wb_clk) if (wb_rst) wb_clk_r <= 0; else wb_clk_r <= ~wb_clk_r;
   always @(posedge ddr2_clk) wb_clk_in_ddr2_clk <= wb_clk_r;
   always @(posedge ddr2_clk) wb_clk_in_ddr2_clk_r <= wb_clk_in_ddr2_clk;
   
   assign wb_clk_edge = wb_clk_in_ddr2_clk & !wb_clk_in_ddr2_clk_r;
   
   always @(posedge ddr2_clk)
     if (ddr2_rst)
       ddr2_clk_phase <= 0;
     else if (wb_clk_edge)
       ddr2_clk_phase <= 0;
     else
       ddr2_clk_phase <= ddr2_clk_phase + 1;
   
   always @(posedge ddr2_clk)
     do_writeback_ddr2_fifo_we <= (do_writeback_ddr2_shifter_r[0]) | 
 				  (do_writeback_ddr2_shifter_r[2]);

   // Kick off counting when we see that the wb_clk domain is
   // doing a writeback.
   always @(posedge ddr2_clk)
     if (ddr2_rst)
       do_writeback_ddr2_shifter <= 4'h0;
     else if  (|do_writeback_ddr2_shifter)
       do_writeback_ddr2_shifter <= {do_writeback_ddr2_shifter[2:0], 1'b0};
     else if (!(|ddr2_clk_phase) & do_writeback) // sample WB domain
       do_writeback_ddr2_shifter <= 4'h1;


   
   always @(posedge ddr2_clk)
     do_writeback_ddr2_shifter_r <= do_writeback_ddr2_shifter;
   
   always @(posedge ddr2_clk)
     if (ddr2_rst)
       ddr2_write_done <= 0;
     else if (do_writeback_ddr2_shifter[3])
       ddr2_write_done <= 1;
     else if ((!(|ddr2_clk_phase)) & !do_writeback) // sample WB domain
       ddr2_write_done <= 0;
   
   always @(posedge ddr2_clk)
     if (ddr2_rst)
       ddr2_cache_addr <= 0;
     else if (rd_data_valid | do_writeback_ddr2_fifo_we)
       ddr2_cache_addr <= ~ddr2_cache_addr;
   
   always @(posedge ddr2_clk)
     rd_data_valid_r <= rd_data_valid;
   
   // Read done signaling to WB domain
   always @(posedge ddr2_clk)
     if (ddr2_rst)
       ddr2_read_done <= 0;
     else if (!rd_data_valid & rd_data_valid_r) // Detect read data valid falling edge
       ddr2_read_done <= 1;
     else if (!(|ddr2_clk_phase) & !do_readfrom) // Read WB domain
       ddr2_read_done <= 0;

   wire [2:0] wb_cache_adr;
   assign wb_cache_adr = wb_adr_i[4:2];   
   wire [3:0] wb_cache_sel_we;   
   assign wb_cache_sel_we = {4{wb_we_i}} & wb_sel_i;
   wire       ddr2_cache_en;
   wire [15:0] ddr2_cache_we;
   assign ddr2_cache_en = rd_data_valid | (|do_writeback_ddr2_shifter);   
   assign ddr2_cache_we = {16{rd_data_valid}};
   
   
   // Xilinx Coregen true dual-port RAMB array.
   // Wishbone side : 32-bit
   // DDR2 side : 128-bit
   ml501_ddr2_wb_if_cache cache_mem0
     (
      // Wishbone side
      .clka(wb_clk),
      .ena(wb_cache_en),
      .wea(wb_cache_sel_we),
      .addra(wb_cache_adr),
      .dina(wb_dat_i),
      .douta(wb_dat_o),

      // DDR2 controller side
      .clkb(ddr2_clk),
      .enb(ddr2_cache_en),
      .web(ddr2_cache_we),
      .addrb(ddr2_cache_addr),
      .dinb(rd_data_fifo_out),
      .doutb(ddr2_cache_data_o));
  
   ddr2_mig #
     (
     .BANK_WIDTH            (BANK_WIDTH),
     .CKE_WIDTH             (CKE_WIDTH),
     .CLK_WIDTH             (CLK_WIDTH),
     .COL_WIDTH             (COL_WIDTH),
     .CS_NUM                (CS_NUM),
     .CS_WIDTH              (CS_WIDTH),
     .CS_BITS               (CS_BITS),
     .DM_WIDTH                     (DM_WIDTH),
     .DQ_WIDTH              (DQ_WIDTH),
     .DQ_PER_DQS            (DQ_PER_DQS),
     .DQ_BITS               (DQ_BITS),
     .DQS_WIDTH             (DQS_WIDTH),
     .DQS_BITS              (DQS_BITS),
     .HIGH_PERFORMANCE_MODE (HIGH_PERFORMANCE_MODE),
     .ODT_WIDTH             (ODT_WIDTH),
     .ROW_WIDTH             (ROW_WIDTH),
     .APPDATA_WIDTH         (APPDATA_WIDTH),
     .ADDITIVE_LAT          (ADDITIVE_LAT),
     .BURST_LEN             (BURST_LEN),
     .BURST_TYPE            (BURST_TYPE),
     .CAS_LAT               (CAS_LAT),
     .ECC_ENABLE            (ECC_ENABLE),
     .MULTI_BANK_EN         (MULTI_BANK_EN),
     .ODT_TYPE              (ODT_TYPE),
     .REDUCE_DRV            (REDUCE_DRV),
     .REG_ENABLE            (REG_ENABLE),
     .TREFI_NS              (TREFI_NS),
     .TRAS                  (TRAS),
     .TRCD                  (TRCD),
     .TRFC                  (TRFC),
     .TRP                   (TRP),
     .TRTP                  (TRTP),
     .TWR                   (TWR),
     .TWTR                  (TWTR),
     .SIM_ONLY              (SIM_ONLY),
     .RST_ACT_LOW           (RST_ACT_LOW),
     .CLK_TYPE                     (CLK_TYPE),
     .DLL_FREQ_MODE                (DLL_FREQ_MODE),
     .CLK_PERIOD            (CLK_PERIOD)
       )
   ddr2_mig0
     (
     .sys_clk           (ddr2_if_clk),
     .idly_clk_200      (idly_clk_200),
     .sys_rst_n         (wb_rst),
     .ddr2_ras_n        (ddr2_ras_n),
     .ddr2_cas_n        (ddr2_cas_n),
     .ddr2_we_n         (ddr2_we_n),
     .ddr2_cs_n         (ddr2_cs_n),
     .ddr2_cke          (ddr2_cke),
     .ddr2_odt          (ddr2_odt),
     .ddr2_dm           (ddr2_dm),
     .ddr2_dq           (ddr2_dq),
     .ddr2_dqs          (ddr2_dqs),
     .ddr2_dqs_n        (ddr2_dqs_n),
     .ddr2_ck           (ddr2_ck),
     .ddr2_ck_n         (ddr2_ck_n),
     .ddr2_ba           (ddr2_ba),
     .ddr2_a            (ddr2_a),
     
      .clk0_tb           (ddr2_clk),
      .rst0_tb           (ddr2_rst),
      .usr_clk (wb_clk),
     .app_af_afull      (app_af_afull),
     .app_wdf_afull     (app_wdf_afull),
     .rd_data_valid     (rd_data_valid),
     .rd_data_fifo_out  (rd_data_fifo_out),
     .app_af_wren       (app_af_wren),
     .app_af_cmd        (app_af_cmd),
     .app_af_addr       (app_af_addr),
     .app_wdf_wren      (app_wdf_wren),
     .app_wdf_data      (app_wdf_data),
     .app_wdf_mask_data (app_wdf_mask_data),
     .phy_init_done     (phy_init_done)
      );
     

endmodule // ml501_ddr2_wb_if
// Local Variables:
// verilog-library-directories:("." "ddr2_mig")
// verilog-library-extensions:(".v" ".h")
// End:
