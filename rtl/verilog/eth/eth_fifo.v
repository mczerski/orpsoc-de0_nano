//////////////////////////////////////////////////////////////////////
////                                                              ////
////  eth_fifo.v                                                  ////
////                                                              ////
////  This file is part of the Ethernet IP core project           ////
////  http://www.opencores.org/projects/ethmac/                   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Igor Mohor (igorM@opencores.org)                      ////
////                                                              ////
////  All additional information is avaliable in the Readme.txt   ////
////  file.                                                       ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2001 Authors                                   ////
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
//
// CVS Revision History
//
// $Log: not supported by cvs2svn $
// Revision 1.3  2002/04/22 13:45:52  mohor
// Generic ram or Xilinx ram can be used in fifo (selectable by setting
// ETH_FIFO_XILINX in eth_defines.v).
//
// Revision 1.2  2002/03/25 13:33:04  mohor
// When clear and read/write are active at the same time, cnt and pointers are
// set to 1.
//
// Revision 1.1  2002/02/05 16:44:39  mohor
// Both rx and tx part are finished. Tested with wb_clk_i between 10 and 200
// MHz. Statuses, overrun, control frame transmission and reception still  need
// to be fixed.
//
//

`include "eth_defines.v"
`include "timescale.v"

module eth_fifo (data_in, data_out, clk, reset, write, read, clear, almost_full, full, almost_empty, empty, cnt);

parameter DATA_WIDTH    = 32;
parameter DEPTH         = 8;
parameter CNT_WIDTH     = 4;

input                     clk;
input                     reset;
input                     write;
input                     read;
input                     clear;
input   [DATA_WIDTH-1:0]  data_in;

output  [DATA_WIDTH-1:0]  data_out;
output                    almost_full;
output                    full;
output                    almost_empty;
output                    empty;
output  [CNT_WIDTH-1:0]   cnt;



reg [CNT_WIDTH-1:0] 	  cnt;
   reg 			  final_read;
   
always @ (posedge clk or posedge reset)
begin
  if(reset)
    cnt <= 0;
  else
  if(clear)
    cnt <= { {(CNT_WIDTH-1){1'b0}}, read^write};
  else
  if(read ^ write)
    if(read)
      cnt <= cnt - 1'b1;
    else
      cnt <= cnt + 1'b1;
end

   
`ifdef ETH_FIFO_GENERIC

   reg     [DATA_WIDTH-1:0]  fifo  [0:DEPTH-1] /*synthesis syn_ramstyle = "no_rw_check"*/ ;
   
   
   // This should make the synthesis tool infer RAMs
   reg [CNT_WIDTH-2:0] waddr, raddr, raddr_reg;
   reg 		       clear_reg; // Register the clear pulse   
   
   always @(posedge clk)
     if (reset)
       waddr <= 0;
     else if (write)
       waddr <= waddr + 1;

   wire 	       raddr_reg_adv;
   reg 		       read_reg;
   always @(posedge clk)
     read_reg <= read;

   // Advance the address after a read = first/next word fallthrough   
   assign raddr_reg_adv = (cnt > 2) & read_reg;
   
   always @(posedge clk)
     if (reset)
       raddr <= 0;
     else if (clear)
       raddr <= waddr;
     else if (read | clear_reg )
       raddr <= raddr + 1;
   
   always @ (posedge clk)
     if (write & ~full)
       fifo[waddr] <=  data_in;


   always @(posedge clk)
     clear_reg <= clear;

   always @ (posedge clk)
     if (read | clear_reg)
       raddr_reg <= raddr;
   
   assign  data_out = fifo[raddr_reg];


   always @(posedge clk)
     if (reset)
       final_read <= 0;
     else if (final_read & read & !write)
       final_read <= ~final_read;
     else if ((cnt == 1) & read & !write)
       final_read <= 1; // Indicate last read data has been output
   
   
   assign empty = ~(|cnt);
   assign almost_empty = cnt==1;
   assign full  = cnt == DEPTH;
   assign almost_full  = &cnt[CNT_WIDTH-2:0];

`else // !`ifdef ETH_FIFO_GENERIC
   
reg     [CNT_WIDTH-2:0]   read_pointer;
reg     [CNT_WIDTH-2:0]   write_pointer;


always @ (posedge clk or posedge reset)
begin
  if(reset)
    read_pointer <= 0;
  else
  if(clear)
    //read_pointer <= { {(CNT_WIDTH-2){1'b0}}, read};
    read_pointer <= { {(CNT_WIDTH-2){1'b0}}, 1'b1};
  else
  if(read & ~empty)
    read_pointer <= read_pointer + 1'b1;
end

always @ (posedge clk or posedge reset)
begin
  if(reset)
    write_pointer <= 0;
  else
  if(clear)
    write_pointer <= { {(CNT_WIDTH-2){1'b0}}, write};
  else
  if(write & ~full)
    write_pointer <= write_pointer + 1'b1;
end

`ifdef ETH_FIFO_XILINX
  xilinx_dist_ram_16x32 fifo
  ( .data_out(data_out), 
    .we(write & ~full),
    .data_in(data_in),
    .read_address( clear ? {CNT_WIDTH-1{1'b0}} : read_pointer),
    .write_address(clear ? {CNT_WIDTH-1{1'b0}} : write_pointer),
    .wclk(clk)
  );
`else   // !ETH_FIFO_XILINX
`ifdef ETH_ALTERA_ALTSYNCRAM
  altera_dpram_16x32	altera_dpram_16x32_inst
  (
  	.data             (data_in),
  	.wren             (write & ~full),
  	.wraddress        (clear ? {CNT_WIDTH-1{1'b0}} : write_pointer),
  	.rdaddress        (clear ? {CNT_WIDTH-1{1'b0}} : read_pointer ),
  	.clock            (clk),
  	.q                (data_out)
  );  //exemplar attribute altera_dpram_16x32_inst NOOPT TRUE
`endif //  `ifdef ETH_ALTERA_ALTSYNCRAM
`endif // !`ifdef ETH_FIFO_XILINX

   
assign empty = ~(|cnt);
assign almost_empty = cnt == 1;
assign full  = cnt == DEPTH;
assign almost_full  = &cnt[CNT_WIDTH-2:0];
   
`endif // !`ifdef ETH_FIFO_GENERIC
   


endmodule
