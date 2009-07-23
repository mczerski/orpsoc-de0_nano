//////////////////////////////////////////////////////////////////////
////                                                              ////
////  SMII Receiver/Decoder (usually at PHY end)                  ////
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
////      - Julius Baxter, jb@orsoc.se                            ////
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
module smii_phy
  (
   // SMII
    input     smii_tx,
    input     smii_sync,
    output    smii_rx,
   
   // MII
   // TX
   /* ALL I/Os swapped compared to SMII on MAC end MAC - jb */
    output reg [3:0] ethphy_mii_tx_d,
    output reg 	     ethphy_mii_tx_en,
    output reg 	     ethphy_mii_tx_err,
    input 	     ethphy_mii_tx_clk,
   // RX
    input [3:0]      ethphy_mii_rx_d,
    input 	     ethphy_mii_rx_dv,
    input 	     ethphy_mii_rx_err,
    input 	     ethphy_mii_rx_clk,
    input 	     ethphy_mii_mcoll,
    input 	     ethphy_mii_crs,

    input 	     fast_ethernet,
    input 	     duplex,
    input 	     link,

   // internal
    //input [10:1] state,
   // clock and reset
    input 	 clk, /* Global reference clock for both SMII modules */
    input 	 rst_n
   );

   reg [3:0] 	 rx_tmp;
   
   reg 		 jabber = 0;

   reg 		 mtx_clk_tmp, mrx_clk_tmp;

   reg [3:0] 	 tx_cnt;
   reg [3:0] 	 rx_cnt;

   
/**************************************************************************/
/* Counters */
/**************************************************************************/

   /* Generate the state counter, based on incoming sync signal */
   /* 10-bit shift register, indicating where we are */
   reg [10:1] 	 state_shiftreg;

   always @(posedge clk)
     begin
	if (!rst_n)
	  begin
	     state_shiftreg <= 10'b0000000001;
	  end
	else
	  begin
	     if (smii_sync) /* sync signal from MAC */
	       state_shiftreg <= 10'b0000000010;
	     else if (state_shiftreg[10])
	       state_shiftreg <= 10'b0000000001;
	     else
	       state_shiftreg[10:2] <= state_shiftreg[9:1];
	  end // else: !if(!rst_n)	
     end // always @ (posedge clk)
   
   
   /* counter from 0 to 9, counting the 10-bit segments we'll transmit
    via SMII*/
   reg [3:0] segment_ctr; 

   always @(posedge clk)
     begin
	if(!rst_n)
	  segment_ctr <= 4'h0;
	else
	  begin
 	     if(fast_ethernet) /* If using 100Mbs, then each segment is 
			    different, we don't count the repeats */
	       segment_ctr <= 4'h0;
	     else if (state_shiftreg[10])
	       if (segment_ctr == 4'h9) /* Wrap */
		 segment_ctr <= 4'h0;
	       else /* Increment */
		 segment_ctr <= segment_ctr + 1'b1;
	  end
     end
   
/**************************************************************************/
/* RX path logic PHY->(MII->SMII)->MAC */
/**************************************************************************/

   reg rx_nibble_sel, rx_byte_valid;
   reg [7:0] rx_data_byte_rx_clk;   

   /* Receive the RX data from the PHY and serialise it */
   /* If RX data valid goes high, then it's the beginning of a 
    proper data segment*/
   always @(posedge ethphy_mii_rx_clk or negedge rst_n)
     begin
	if(!rst_n)
	  begin
	     rx_nibble_sel <= 0; /* start with low nibble receiving */
	     rx_data_byte_rx_clk <= 0;
	     rx_byte_valid <= 0;	     
	  end
	else
	  begin
	     /* Half way through, and at the end of each 10-bit section 
	      and whenever we should load a new segment (each time for 
	      fast ethernet, else once every 10 times; whenever segment_ctr 
	      is 0)*/	     
	     //if ((state_shiftreg[6] | state_shiftreg[10]) & (segment_ctr==4'h0))
	     //  begin
		  /* Alternate the nibble we're selecting when RX_dv */
		  if(!ethphy_mii_rx_dv) /* data on rx line is not valid */
		    rx_nibble_sel <= 0;
		  else
		    rx_nibble_sel <= ~rx_nibble_sel;

		  if (!ethphy_mii_rx_dv & !rx_nibble_sel)
		    rx_byte_valid <= 0;
		  else if (rx_nibble_sel) /* sampled high nibble, byte OK*/
		    rx_byte_valid <= 1;
		  
		  if (ethphy_mii_rx_dv & !rx_nibble_sel)
		    /* Sampling low nibble */
		    rx_data_byte_rx_clk[3:0] <= ethphy_mii_rx_d;
		  else if (ethphy_mii_rx_dv & rx_nibble_sel)
		    /* Sample high nibble */
		    rx_data_byte_rx_clk[7:4] <= ethphy_mii_rx_d;
		  
	       //end // if ((state_shiftreg[4] | state_shiftreg[9]) & (segment_ctr==4'h0))	     
	  end // else: !if(!rst_n)
     end // always @ (posedge clk)'

   /* SMII domain RX signals */
   reg [7:0] rx_data_byte;
   reg rx_line_rx_dv; /* Reg for second bit of SMII RX sequence, RX_DV */

   /* A wire hooked up from bit 0 with the last byte of the state counter/shiftreg */
   wire [7:0] state_shiftreg_top_byte;
   assign state_shiftreg_top_byte[7:0] = state_shiftreg[10:3];
   
   /* Move RX's DV and data into SMII clk domain */
   always @(posedge clk)
     begin
	if(!rst_n)
	  begin
	     rx_line_rx_dv <= 0;
	  end
	else
	  begin
	     /* When we're at the beginning of a new 10-bit sequence and
	      the beginning of the 10-segment loop load the valid bit */
	     if(state_shiftreg[1] & (segment_ctr==4'h0))
	       begin
		  rx_line_rx_dv <= rx_byte_valid;
		  rx_data_byte <= rx_data_byte_rx_clk;
	       end
	  end // else: !if(!rst_n)
     end // always @ (posedge clk)
   
   /* Assign the rx line out */   
   assign smii_rx = state_shiftreg[1] ? ethphy_mii_crs : /* 1st bit is MII CRS */
		    /* next is RX_DV bit */
		    state_shiftreg[2] ? ((rx_byte_valid & (segment_ctr==4'h0)) | 
					 rx_line_rx_dv) : 
		    /* Depending on RX_DV, output the status byte or data byte */
		    rx_line_rx_dv ? |(state_shiftreg_top_byte & rx_data_byte) :
		    /* Output status byte */
                    |(state_shiftreg_top_byte &
   /* Status seq.: CRS, DV, ER, Speed, Duplex, Link, Jabber, UPV, FCD, 1 */
       {1'b1,1'b0,1'b1,jabber,link,duplex,fast_ethernet,ethphy_mii_rx_err});

/**************************************************************************/
/* TX path logic MAC->(SMII->MII)->PHY */
/**************************************************************************/

   /* We ignore the data when TX_EN bit is not high - 
    it's only used in MAC to MAC comms*/


   /* Register the sequence appropriately as it comes in */
   reg tx_er_seqbit_scratch;
   reg tx_en_seqbit_scratch;
   reg [7:0] tx_data_byte_scratch;

   reg [1:0] tx_byte_to_phy; /* PHY sourced TX_CLK domain */
   
   wire      tx_fifo_empty;
   wire      tx_fifo_full;
   wire [7:0] tx_fifo_q_dat;
   wire       tx_fifo_q_err;
   reg 	      tx_fifo_pop;
   

   /* Signal to tell us an appropriate time to copy the values out of the 
    temp regs we put the incoming TX line into when we've received a 
    sequence off the SMII TX line that has TX_EN high */
   wire      tx_seqbits_copy;
   assign tx_seqbits_copy = ((((!fast_ethernet) & (segment_ctr==4'h1)) |
			      ((fast_ethernet) & (state_shiftreg[1])))
			     & tx_en_seqbit_scratch);

   always @(posedge clk)
     begin
	if (!rst_n)
	  begin
	     tx_er_seqbit_scratch <= 0;
	     tx_en_seqbit_scratch <= 0;
	     tx_data_byte_scratch <= 0;
	  end
	else
	  begin
	     if (segment_ctr==4'h0)
	       begin
		  if(state_shiftreg[1])
		    tx_er_seqbit_scratch <= smii_tx;
		  
		  if(state_shiftreg[2])
		    tx_en_seqbit_scratch <= smii_tx;
		  
		  /* Preserve all but current bit of interest, as indicated
		   by state vector bit (reversed, becuase we get MSbit 
		   first) and OR in the current smii_tx line value at this 
		   position*/
		  if((|state_shiftreg[10:3]) & tx_en_seqbit_scratch)
		    tx_data_byte_scratch <= (tx_data_byte_scratch & ~state_shiftreg_top_byte) |
					    ({8{smii_tx}} & state_shiftreg_top_byte);
		  
	       end // if (segment_ctr==4'h0)

	     /* If we've just received a sequence with TX_EN then put 
	      these values in the proper regs at the appropriate time, 
	      depending on the speed , ready for transmission to the PHY */
	     if (tx_seqbits_copy)
	       begin
		  
		  /* Now clear the tx_en scratch bit so we don't do 
		   this again */
		  tx_en_seqbit_scratch <= 0;
		  
	       end // if (tx_seqbits_copy)
	  end
     end // always @ (posedge clk)


   /* In the event we have a valid byte frame then get it to the 
    PHY as quickly as possible - this is TX_CLK domain */
   always @(posedge ethphy_mii_tx_clk or negedge rst_n)
     begin
	if(!rst_n)
	  begin
	     tx_byte_to_phy <= 0;
	     tx_fifo_pop <= 1'b0;
	     /* Output MII registers to the PHY */
	     ethphy_mii_tx_d <= 0;
	     ethphy_mii_tx_en <= 0;
	     ethphy_mii_tx_err <= 0;
	     
	  end
	else
	  begin
	     
	     if(!tx_fifo_empty) /* A byte ready to go to the MAC */
	       begin
		  if(tx_byte_to_phy == 2'b00) 
		    begin
		       /* Pop */
		       tx_fifo_pop <= 1;		       
		       tx_byte_to_phy <= 2'b01;
		    end
	       end

	     /* FIFO control loop */
	     if (tx_byte_to_phy == 2'b01) /* Output bits 3-0 (bottom nibble ) */
	       begin
		  ethphy_mii_tx_d <= tx_fifo_q_dat[3:0];
		  ethphy_mii_tx_en <= 1;
		  ethphy_mii_tx_err <= tx_fifo_q_err;
		  tx_fifo_pop <= 0;
		  tx_byte_to_phy <= 2'b10;
	       end
	     else if (tx_byte_to_phy == 2'b10) /* Output bits 7-4 (top nibble) */
	       begin
		  ethphy_mii_tx_d <= tx_fifo_q_dat[7:4];
		  if(!tx_fifo_empty) /* Check if more in FIFO */
		    begin
		       tx_fifo_pop <= 1; /* Pop again */
		       tx_byte_to_phy <= 2'b01;
		    end
		  else /* Finish up */
		    begin
		       tx_byte_to_phy <= 2'b11;
		    end
	       end
	     else if (tx_byte_to_phy == 2'b11) /* De-assert TX_EN */
	       begin
		  ethphy_mii_tx_en <= 0;
		  tx_byte_to_phy <= 2'b00;
	       end
	  end // else: !if(!rst_n)
     end // always @ (posedge ethphy_mii_tx_clk or negedge rst_n)

   /* A fifo, storing TX bytes coming from the SMII interface */
   generic_fifo #(9, 64) tx_fifo
     (
      // Outputs
      .psh_full				(tx_fifo_full),
      .pop_q				({tx_fifo_q_err,tx_fifo_q_dat}),
      .pop_empty			(tx_fifo_empty),
      // Inputs
      .async_rst_n			(rst_n),
      .psh_clk				(clk),
      .psh_we				(tx_seqbits_copy),
      .psh_d				({tx_er_seqbit_scratch,tx_data_byte_scratch}),
      .pop_clk				(),
      .pop_re				(tx_fifo_pop));
   
   
   //assign mcoll = mcrs & mtxen;
   
endmodule // smii_top



/* Generic fifo - this is bad, should probably be done some other way */
module generic_fifo (async_rst_n, psh_clk, psh_we, psh_d, psh_full, pop_clk, pop_re, pop_q, pop_empty);

   parameter dw = 8;
   parameter size = 64;

   /* Asynch. reset, active low */
   input async_rst_n;   
   
   /* Push side signals */
   input psh_clk;   
   input psh_we;   
   input [dw-1:0] psh_d;
   output 	  psh_full;
   
   /* Pop side signals */
   input 	  pop_clk;
   input 	  pop_re;
   output reg [dw-1:0] pop_q;
   output 	       pop_empty;
   
   /* Actual FIFO memory */
   reg [dw-1:0]   fifo_mem [0:size-1];

   /* Poorly defined pointer logic -- will need to be changed if the size paramter is too big - Verilog needs some log base 2 thing */
   reg [7:0]   ptr; /* Only 8 bits, so max size of 255 of fifo! */


   /* FIFO full signal for push side */
   assign psh_full = (ptr == size-1) ? 1 : 0;
   /* FIFO empty signal for pop side */
   assign pop_empty = (ptr == 0) ? 1 : 0;
   

   /* This will work if pushing side is a lot faster than popping side */
   reg 	       pop_re_psh_clk;   
   wire       pop_re_risingedge_psh_clk; /* Signal to help push side see when 
					    there's been a pop_re rising edge, 
					    sampled on push clock */

   /* Detect edge of signal in pop domain for psh domain */
   assign pop_re_risingedge_psh_clk = (pop_re & !pop_re_psh_clk);


   integer    i;
   always @(posedge psh_clk or negedge async_rst_n)
     begin
	if (!async_rst_n)
	  begin
	     ptr <= 0;


	     for (i=0;i<size;i=i+1) fifo_mem[i] <= 0;

	     pop_re_psh_clk <= 0;
	     
	  end
	else	  
	  begin
	     
	     pop_re_psh_clk <= pop_re; /* Register pop command in psh domain */  
	     
	     if (psh_we) /* Push into FIFO */
	       begin
		  if (!pop_re_psh_clk) /* If no pop at the same time, simple */
		    begin
		       fifo_mem[ptr] <= psh_d;		       
		       ptr <= ptr + 1'b1;
		    end
		  else /* Pop at same edge */		    
		    begin
		       /* Shift fifo contents */
		       for(i=1;i<size;i=i+1)
			 fifo_mem[i-1] <= fifo_mem[i];
		       fifo_mem[size-1] <= 0;
		       pop_q <= fifo_mem[0];
		       fifo_mem[ptr] <= psh_d;
		       /* ptr remains unchanged */
		    end // else: !if!(pop_re_psh_clk)
	       end // if (psh_we)
	     else /* No push, see if there's a pop */
	       begin
		  if (pop_re_risingedge_psh_clk) /* Detected a pop */
		    begin
		       for(i=1;i<size;i=i+1)
			 fifo_mem[i-1] <= fifo_mem[i];
		       fifo_mem[size-1] <= 0;
		       pop_q <= fifo_mem[0];
		       ptr <= ptr - 1'b1;
		    end		  
	       end // else: !if(psh_we)	     
	  end // else: !if(!async_rst_n)
     end // always @ (posedge psh_clk or negedge async_rst_n)
   
		       
endmodule // generic_fifo

   