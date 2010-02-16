//////////////////////////////////////////////////////////////////////
////                                                              ////
////  User controllable reset generation                          ////
////                                                              ////
////  Description                                                 ////
////  Pulls a signal low when accessed. This signal should be     ////
////  looped back out of the design and back into the reset       ////
////  module, resetting the system.                               ////
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
module usr_rst(wb_clk, wb_rst, wb_cyc_i, wb_stb_i, wb_ack_o, usr_rst_out);
   
   input wb_clk, wb_rst, wb_cyc_i, wb_stb_i;
   output reg wb_ack_o;
   output     usr_rst_out;


   always @(posedge wb_clk)
     if (wb_rst)
       wb_ack_o <= 0;
     else if (wb_cyc_i & wb_stb_i & !wb_ack_o)
       wb_ack_o <= 1;
     else
       wb_ack_o <= 0;
   
   // Generate an active low reset pulse when this module is accessed.
   // We don't generate ACKs because the thing will be reset anyway...
   assign usr_rst_out = !(wb_cyc_i & wb_stb_i & !wb_rst);

endmodule // usr_rst
