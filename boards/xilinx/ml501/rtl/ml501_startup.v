//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Xilinx ML501 Startup Memory                                 ////
////                                                              ////
////  Description                                                 ////
////  Describes inferrable memory slave.                          ////
////                                                              ////
////  To Do:                                                      ////
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

/* Memory containing memory addresses 0x0 up to mem_span */
module ml501_startup
  (   wb_adr_i, wb_stb_i, wb_cyc_i, wb_we_i, wb_sel_i, wb_dat_i, 
      wb_dat_o, wb_ack_o, 
      wb_clk, wb_rst 
      );

   /* Make this memory span up to this value */
   parameter mem_span = 12'h800;
   parameter adr_width = 11; // log2(mem_span)
   parameter mem_span_word_address_width =  (adr_width-2);
     
   input [adr_width-1:0]        wb_adr_i;
   input 	       wb_stb_i;
   input 	       wb_cyc_i;
   input 	       wb_we_i;
   input [3:0] 	       wb_sel_i;
   input [31:0]        wb_dat_i;
   output [31:0]       wb_dat_o;
   output 	       wb_ack_o;
   input 	       wb_clk;
   input 	       wb_rst;
   


   // synthesis attribute ram_style of mem is block
   reg [31:0] 	       mem [0:(mem_span/4)-1] /* synthesis ram_style = no_rw_check */;
   reg [mem_span_word_address_width-1:0] adr;
   
   
   parameter memory_file = "sram.vmem";

   initial
     begin
	$readmemh(memory_file, mem);
     end

   
   wire [31:0] 	       wr_data;
   
   // mux for data to ram, RMW on part sel != 4'hf
   assign wr_data[31:24] = wb_sel_i[3] ? wb_dat_i[31:24] : wb_dat_o[31:24];
   assign wr_data[23:16] = wb_sel_i[2] ? wb_dat_i[23:16] : wb_dat_o[23:16];
   assign wr_data[15: 8] = wb_sel_i[1] ? wb_dat_i[15: 8] : wb_dat_o[15: 8];
   assign wr_data[ 7: 0] = wb_sel_i[0] ? wb_dat_i[ 7: 0] : wb_dat_o[ 7: 0];

   always @(posedge wb_clk or posedge wb_rst)
     begin 
	if (wb_rst)
	  adr <= 0;
	else
	  if (wb_cyc_i & wb_stb_i)
	    adr <= wb_adr_i[(mem_span_word_address_width+2)-1:2];
     end

// Define REG_READS to have registered reads   
//`define REG_READS

   reg [31:0] wb_dat_o_r;
   
`ifdef REG_READS
   // Registered read
   assign wb_dat_o = wb_dat_o_r;   
`else
   // Unregistered read
   assign wb_dat_o = mem[adr];
`endif
   
   always @ (posedge wb_clk)
     begin
	if (wb_we_i & wb_ack_o)
	  mem[adr] <= wb_dat_i;
`ifdef REG_READS
	// Registered read
	wb_dat_o_r <= mem[adr];
`endif	
     end
   
   
   // ack_o
   
   reg wb_ack_o_r, wb_ack_o_r2;

`ifdef REG_READS   
   // Use the following for registered reads
   assign wb_ack_o = wb_ack_o_r2;
`else
   // Use the following for UNregistered reads
   assign wb_ack_o = wb_ack_o_r;
`endif
   
   always @ (posedge wb_clk or posedge wb_rst)
     if (wb_rst)
       wb_ack_o_r <= 1'b0;
     else
       if (!wb_ack_o_r) 
	 begin
	    if (wb_cyc_i & wb_stb_i
`ifdef REG_READS		
		& !wb_ack_o_r2
`endif		
		)
	      wb_ack_o_r <= 1'b1; 
	 end
       else
	 wb_ack_o_r <= 1'b0;

   always @ (posedge wb_clk)
     wb_ack_o_r2 <= wb_ack_o_r;
   
   
endmodule 
