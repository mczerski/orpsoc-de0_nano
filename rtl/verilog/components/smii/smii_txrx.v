//////////////////////////////////////////////////////////////////////
////                                                              ////
////  SMII                                                        ////
////                                                              ////
////  Description                                                 ////
////  Low pin count serial MII ethernet interface                 ////
////                                                              ////
////  To Do:                                                      ////
////   -                                                          ////
////                                                              ////
////  Author(s):                                                  ////
////      - Michael Unneback, unneback@opencores.org              ////
////        ORSoC AB          michael.unneback@orsoc.se           ////
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
module smii_txrx
  (
   // SMII
    output     tx,
    input      rx,
   // MII
   // TX
    input [3:0] mtxd,
    input 	mtxen,
    input 	mtxerr,
    output 	mtx_clk,
   // RX
    output reg [3:0] mrxd,
    output reg	 mrxdv,
    output reg	 mrxerr,
    output  	 mrx_clk,
    output 	 mcoll,
    output reg	 mcrs,
`ifdef SMII_SPEED
    output reg	 speed,
`endif
`ifdef SMII_DUPLEX
    output reg	 duplex,
`endif
`ifdef SMII_LINK
    output reg	 link,
`endif
   // internal
    input [10:1] state,
   // clock and reset
    input 	 clk,
    input 	 rst
   );

   reg [7:0]		 tx_data_reg;
   reg 			 tx_data_reg_valid;
   reg 			 a0;
   reg 			 state_data;

   reg [3:0] 	 rx_tmp;
   
`ifndef SMII_SPEED
   reg 		 speed;
`endif   
`ifndef SMII_DUPLEX
   reg 		 duplex;
`endif
`ifndef SMII_LINK
   reg 		 link;
`endif
   reg 		 jabber;

   reg 		 mtx_clk_tmp, mrx_clk_tmp;

   reg [3:0] 	 tx_cnt;
   reg [3:0] 	 rx_cnt;
   
   /////////////////////////////////////////////////
   // Speed

   always @ (posedge clk or posedge rst)
     if (rst)
       tx_cnt <= 4'd0;
     else
       if (speed)
	 tx_cnt <= 4'd0;
       else if (state[10])
	 if (tx_cnt == 4'd9)
	   tx_cnt <= 4'd0;
	 else
	   tx_cnt <= tx_cnt + 4'd1;
   
   /////////////////////////////////////////////////
   // Transmit

   /* Timing scheme:
    On the first clock of segment 0 (so each segment when 100Mb/s,
    fast ethernet, or every 10 segments for 10Mb/s ethernet) we 
    deteremine if that segment is data or not, depending on what is 
    in the tx_data_reg_valid register. If the MAC wants to transmit 
    something, we overwrite the previously sent values when they're 
    no longer needed. Once the first nibble is sent, we can then 
    overwrite it, and same for the second - so we generate the TX 
    clock when state is 5, and sample the new nibble on the next 
    clock, same with the second nibble, that is clocked when state 
    is 9, and sampled when it is 10, so it gets overwritten when 
    we've finished putting it on the serial line.*/
      
     always @ (posedge clk or posedge rst)
     if (rst)
       mtx_clk_tmp <= 1'b0;
     else
       if ((state[5] | state[9]) & (tx_cnt == 4'd0))
	 mtx_clk_tmp <= 1'b1;
       else if (state[6] | state[10])
	 mtx_clk_tmp <= 1'b0;

`ifdef ACTEL
   gbuf bufg1
     (
      .CLK(mtx_clk_tmp),
      .GL(mtx_clk)
      );
`else
   assign #1 mtx_clk = mtx_clk_tmp;
`endif

   // storage of data from MII
   always @ (posedge clk or posedge rst)
     if (rst)
       begin
	  tx_data_reg <= 8'd0;
	  tx_data_reg_valid <= 1'b0;
	  a0 <= 1'b0;
       end
     else
       if ((state[6] | state[10]) & (tx_cnt == 4'd0))
	 begin
	    /* Toggale a0 when MII TX_EN goes high */
	    if (!mtxen)
	      a0 <= 1'b0;
	    else
	      a0 <= ~a0;

	    /* byte will be valid when MII TX_EN 
	     is high from the MAC */
	    if (!mtxen & !a0)
	      tx_data_reg_valid <= 1'b0;	    
	    else if (a0)
	      tx_data_reg_valid <= 1'b1;

	    /* Sample the nibble */
	    if (mtxen & !a0)
	      tx_data_reg[3:0] <= mtxd;	    
	    else if (mtxen & a0)
	      tx_data_reg[7:4] <= mtxd;	    
	    
	 end // if ((state[4] | state[9]) & (tx_cnt == 4'd0))
   

   /* Determine if we output a data byte or the inter-frame sequence 
    with status information */
   always @ (posedge clk or posedge rst)
     if (rst)
       state_data <= 1'b0;
     else
       if (state[1] & (tx_cnt == 4'd0))
	 state_data <= tx_data_reg_valid;
   
   /* A wire hooked up from bit 0 with the last byte of the state counter/shiftreg */
   wire [7:0] state_data_byte;
   assign state_data_byte[7:0] = state[10:3];
   
   /* Assign the SMII TX wire */
   /* First bit always TX_ERR, then depending on the next bit, TX_EN, output
    either the inter-frame status byte or a data byte */
   assign tx = state[1] ? mtxerr :
	       state[2] ? ((tx_data_reg_valid & (tx_cnt == 4'd0)) | state_data) :
	       state_data ? |(state_data_byte & tx_data_reg) :
	       |(state_data_byte & {3'b111,jabber,link,duplex,speed,mtxerr});

   /////////////////////////////////////////////////
   // Receive

   always @ (posedge clk or posedge rst)
     if (rst)
       rx_cnt <= 4'd0;
     else
       if (speed)
	 rx_cnt <= 4'd0;
       else if (!mrxdv & state[8] & rx_tmp[3])
	 rx_cnt <= 4'd9;
       else if (state[10])
	 if (rx_cnt == 4'd9)
	   rx_cnt <= 4'd0;
	 else
	   rx_cnt <= rx_cnt + 4'd1;
   
   always @ (posedge clk or posedge rst)
     if (rst)
       begin
	  {mcrs, mrxdv, mrxerr, speed, duplex, link, jabber} <= 7'b0001110;
	  rx_tmp <= 4'h0;	  
	  mrxd <= 4'h0;
       end
     else
       begin
	  /* Continually shift rx into rx_tmp bit 2, and shift rx_tmp along */
	  rx_tmp[2:0] <= {rx,rx_tmp[2:1]};

	  /* We appear to be beginning our sampling when state bit 3 is set */
	  if (state[3])
	    mcrs <= rx;	  
	  
	  /* rx_tmp[3] is used as the RX_DV bit*/
	  if (state[4])
	    rx_tmp[3] <= rx;

	  if (rx_tmp[3]) //If data byte valid, and when we've got the first nibble, output it */
	    begin
	       /* At this stage we've got the first 3 bits of the bottom 
		nibble - we can sample the rx line directly to get the 
		4th, and we'll also indicate that this byte is valid by 
		raising the MII RX data valid (dv) line. */
	       if (state[8])
		 {mrxdv,mrxd} <= #1 {rx_tmp[3],rx,rx_tmp[2:0]};
	       /* High nibble, we have 3 bits and the final one is on 
		the line - put it out for the MAC to read.*/
	       else if (state[2])
		 mrxd <= #1 {rx,rx_tmp[2:0]};
	    end
	  else
	    begin
	       /* Not a data byte, it's the inter-frame status byte */
	       if (state[5])
		 mrxerr <= #1 rx;
	       if (state[6])
		 speed <= #1 rx;
	       if (state[7])
		 duplex <= #1 rx;
	       if (state[8])
		 begin
		    link <= #1 rx;
		    mrxdv <= #1 1'b0;
		 end
	       if (state[9])
		 jabber <= #1 rx;
	    end
       end // else: !if(rst)
   
   always @ (posedge clk or posedge rst)
     if (rst)
       mrx_clk_tmp <= 1'b0;
     else
       if ((state[1] | state[6]) & (rx_cnt == 4'd0))
	 mrx_clk_tmp <= 1'b1;
       else if (state[3] | state[8])
	 mrx_clk_tmp <= 1'b0;

`ifdef ACTEL
   gbuf bufg2
     (
      .CLK(mrx_clk_tmp),
      .GL(mrx_clk)
      );
`else
   assign #1 mrx_clk = mrx_clk_tmp;
`endif
   
assign mcoll =  mcrs & mtxen & !duplex;
      
   
endmodule // smii_top
