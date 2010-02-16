//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Xilinx ML501 GPIO controller with Wishbone Interface        ////
////                                                              ////
////  Description                                                 ////
////  Wishbone interface to simple GPIO registers.                ////
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
module ml501_gpio (adr_i, dat_i, dat_o, sel_i, stb_i, cyc_i, we_i, ack_o, clk, rst, gpio );
   
   parameter gpio_width = 26;
   
   // WB interface
   input  [2:0]  adr_i;   
   output [31:0] dat_o;
   input [31:0]  dat_i;
   input [3:0] 	 sel_i; 	 
   input 	 stb_i;   
   input 	 cyc_i;
   input 	 we_i;   
   output reg 	 ack_o;
   input 	 clk;
   input 	 rst;
   
   inout [gpio_width - 1 : 0] gpio;
   
   wire [gpio_width -1 : 0]   gpio_i;
   
   reg [31:0] 		      gpio_o, gpio_o_r, gpio_dir;

   reg [gpio_width - 1 : 0]   dat_o_r;

   assign dat_o[gpio_width-1: 0] = dat_o_r;
   assign dat_o[31:gpio_width] = 0;   
   
   always @(posedge clk)
     if (rst)
       gpio_dir <= 0; // All in
     else
       if (stb_i & cyc_i & we_i & adr_i[2])
	 begin
	    if (sel_i[3]) gpio_dir[31:24] <= dat_i[31:24];
	    if (sel_i[2]) gpio_dir[23:16] <= dat_i[23:16];
	    if (sel_i[1]) gpio_dir[15:8] <= dat_i[15:8];
	    if (sel_i[0]) gpio_dir[7:0] <= dat_i[7:0];
	 end

   always @(posedge clk)
     if (rst)
       ack_o <= 0;
     else if (stb_i & cyc_i & !ack_o)
       ack_o <= 1;
     else
       ack_o <= 0;
   
   
   always @(posedge clk)
     if (rst)
       gpio_o <= 0;
     else if (stb_i & cyc_i & we_i & !adr_i[2])
       begin
	  if (sel_i[3]) gpio_o[31:24] <= dat_i[31:24];
	  if (sel_i[2]) gpio_o[23:16] <= dat_i[23:16];
	  if (sel_i[1]) gpio_o[15:8] <= dat_i[15:8];
	  if (sel_i[0]) gpio_o[7:0] <= dat_i[7:0];
       end
   
   
   genvar i;
   generate
      for (i=0; i<gpio_width; i=i+1) begin: gpio_tribuf_gen
	 
	 always @(posedge clk)
	   if (stb_i & cyc_i & !we_i)
	     if (!adr_i[2])
	       dat_o_r[i]  <= gpio_dir[i]  ?  gpio_o_r[i] : gpio_i[i];
	     else
	       dat_o_r[i]  <= gpio_dir[i];
	 
	 // Xilinx primitive
	 IOBUF U
	   (
	    // Outputs
	    .O                                 (gpio_i[i]),
	    // Inouts
	    .IO                                (gpio[i]),
	    // Inputs
	    .I                                 (gpio_o[i]),
	    .T                                 (!gpio_dir[i]));
      end // block: gpio_tribuf_gen
   endgenerate

endmodule // ml501_gpio

