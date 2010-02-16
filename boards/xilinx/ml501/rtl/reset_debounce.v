//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Reset control/debouncer                                     ////
////                                                              ////
////  Description                                                 ////
////  Debounce reset button signal. It is also sensitive to the   ////
////  user generated reset and DCM lock signals.                  ////
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

module reset_debounce
  (
    input sys_rst_in,
    input usr_rst_in,	      
    input sys_clk_in,		      
    output rst_dcm0,
    input dcm0_clk,
    input dcm0_locked,
    output rst
		      );
   
   reg [9:0] debounce_count = 10'h000;
   wire      sys_rst = !(sys_rst_in & usr_rst_in); // Either of these going low triggers reset
   reg 	     debounced_rst;
   
   always @(posedge sys_clk_in) begin
      if (sys_rst) begin
	 debounced_rst <= 1'b1;
	 debounce_count <= 10'h3ff;
      end else begin
	 if (debounce_count > 10'b0000000000) debounce_count <= debounce_count - 1'b1;
	 if (debounce_count == 10'b0000000001) debounced_rst <= sys_rst;
      end
   end
   
   assign rst_dcm0 = debounced_rst;
   
   /* Hold reset for a little longer after the dcm locks */
   reg [15:0] rst_dcm0_count;
   always @(posedge dcm0_clk or posedge debounced_rst)
     if (debounced_rst)
       rst_dcm0_count <= 16'hffff;
     else
       rst_dcm0_count <= {rst_dcm0_count[14:0], ~dcm0_locked};

   
   assign rst = rst_dcm0_count[15];

endmodule // reset_debounce
