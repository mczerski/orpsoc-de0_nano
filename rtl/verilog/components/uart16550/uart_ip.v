//////////////////////////////////////////////////////////////////////
////                                                              ////
////  raminfr.v                                                   ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  Inferrable Distributed RAM for FIFOs                        ////
////                                                              ////
////  Known problems (limits):                                    ////
////  None                .                                       ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing so far.                                             ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////                                                              ////
////  Created:        2002/07/22                                  ////
////  Last Updated:   2002/07/22                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: raminfr.v,v $
// Revision 1.2  2002/07/29 21:16:18  gorban
// The uart_defines.v file is included again in sources.
//
// Revision 1.1  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UART_HAS_BAUDRATE_OUTPUT to use.
//

//Following is the Verilog code for a dual-port RAM with asynchronous read. 
`include "uart_defines.v"
module raminfr   
        (clk, we, a, dpra, di, dpo); 

parameter addr_width = 4;
parameter data_width = 8;
parameter depth = 16;

input clk;   
input we;   
input  [addr_width-1:0] a;   
input  [addr_width-1:0] dpra;   
input  [data_width-1:0] di;   
//output [data_width-1:0] spo;   
output [data_width-1:0] dpo;   
reg    [data_width-1:0] ram [depth-1:0]; 
`ifdef SYNC_RAM
   reg [data_width-1:0] dpo;
`else
   wire [data_width-1:0] dpo;
`endif
   
wire  [data_width-1:0] di;   
wire  [addr_width-1:0] a;   
wire  [addr_width-1:0] dpra;   
 
  always @(posedge clk) begin   
    if (we)   
      ram[a] <= di;   
  end   

`ifdef SYNC_RAM
   always @(negedge clk)
     dpo = ram[dpra];
`else
   assign dpo = ram[dpra];
`endif
   
endmodule 

//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_sync_flops.v                                             ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UART core receiver logic                                    ////
////                                                              ////
////  Known problems (limits):                                    ////
////  None known                                                  ////
////                                                              ////
////  To Do:                                                      ////
////  Thourough testing.                                          ////
////                                                              ////
////  Author(s):                                                  ////
////      - Andrej Erzen (andreje@flextronics.si)                 ////
////      - Tadej Markovic (tadejm@flextronics.si)                ////
////                                                              ////
////  Created:        2004/05/20                                  ////
////  Last Updated:   2004/05/20                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: uart_sync_flops.v,v $
// Revision 1.1  2004/05/21 11:43:25  tadejm
// Added to synchronize RX input to Wishbone clock.
//
//


`include "timescale.v"


module uart_sync_flops
(
  // internal signals
  rst_i,
  clk_i,
  stage1_rst_i,
  stage1_clk_en_i,
  async_dat_i,
  sync_dat_o
);

parameter Tp            = 1;
parameter width         = 1;
parameter init_value    = 1'b0;

input                           rst_i;                  // reset input
input                           clk_i;                  // clock input
input                           stage1_rst_i;           // synchronous reset for stage 1 FF
input                           stage1_clk_en_i;        // synchronous clock enable for stage 1 FF
input   [width-1:0]             async_dat_i;            // asynchronous data input
output  [width-1:0]             sync_dat_o;             // synchronous data output


//
// Interal signal declarations
//

reg     [width-1:0]             sync_dat_o;
reg     [width-1:0]             flop_0;


// first stage
always @ (posedge clk_i or posedge rst_i)
begin
    if (rst_i)
        flop_0 <= #Tp {width{init_value}};
    else
        flop_0 <= #Tp async_dat_i;    
end

// second stage
always @ (posedge clk_i or posedge rst_i)
begin
    if (rst_i)
        sync_dat_o <= #Tp {width{init_value}};
    else if (stage1_rst_i)
        sync_dat_o <= #Tp {width{init_value}};
    else if (stage1_clk_en_i)
        sync_dat_o <= #Tp flop_0;       
end

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_regs.v                                                 ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  Registers of the uart 16550 core                            ////
////                                                              ////
////  Known problems (limits):                                    ////
////  Inserts 1 wait state in all WISHBONE transfers              ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing or verification.                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   (See log for the revision history           ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: uart_regs.v,v $
// Revision 1.42  2004/11/22 09:21:59  igorm
// Timeout interrupt should be generated only when there is at least ony
// character in the fifo.
//
// Revision 1.41  2004/05/21 11:44:41  tadejm
// Added synchronizer flops for RX input.
//
// Revision 1.40  2003/06/11 16:37:47  gorban
// This fixes errors in some cases when data is being read and put to the FIFO at the same time. Patch is submitted by Scott Furman. Update is very recommended.
//
// Revision 1.39  2002/07/29 21:16:18  gorban
// The uart_defines.v file is included again in sources.
//
// Revision 1.38  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UART_HAS_BAUDRATE_OUTPUT to use.
//
// Revision 1.37  2001/12/27 13:24:09  mohor
// lsr[7] was not showing overrun errors.
//
// Revision 1.36  2001/12/20 13:25:46  mohor
// rx push changed to be only one cycle wide.
//
// Revision 1.35  2001/12/19 08:03:34  mohor
// Warnings cleared.
//
// Revision 1.34  2001/12/19 07:33:54  mohor
// Synplicity was having troubles with the comment.
//
// Revision 1.33  2001/12/17 10:14:43  mohor
// Things related to msr register changed. After THRE IRQ occurs, and one
// character is written to the transmit fifo, the detection of the THRE bit in the
// LSR is delayed for one character time.
//
// Revision 1.32  2001/12/14 13:19:24  mohor
// MSR register fixed.
//
// Revision 1.31  2001/12/14 10:06:58  mohor
// After reset modem status register MSR should be reset.
//
// Revision 1.30  2001/12/13 10:09:13  mohor
// thre irq should be cleared only when being source of interrupt.
//
// Revision 1.29  2001/12/12 09:05:46  mohor
// LSR status bit 0 was not cleared correctly in case of reseting the FCR (rx fifo).
//
// Revision 1.28  2001/12/10 19:52:41  gorban
// Scratch register added
//
// Revision 1.27  2001/12/06 14:51:04  gorban
// Bug in LSR[0] is fixed.
// All WISHBONE signals are now sampled, so another wait-state is introduced on all transfers.
//
// Revision 1.26  2001/12/03 21:44:29  gorban
// Updated specification documentation.
// Added full 32-bit data bus interface, now as default.
// Address is 5-bit wide in 32-bit data bus mode.
// Added wb_sel_i input to the core. It's used in the 32-bit mode.
// Added debug interface with two 32-bit read-only registers in 32-bit mode.
// Bits 5 and 6 of LSR are now only cleared on TX FIFO write.
// My small test bench is modified to work with 32-bit mode.
//
// Revision 1.25  2001/11/28 19:36:39  gorban
// Fixed: timeout and break didn't pay attention to current data format when counting time
//
// Revision 1.24  2001/11/26 21:38:54  gorban
// Lots of fixes:
// Break condition wasn't handled correctly at all.
// LSR bits could lose their values.
// LSR value after reset was wrong.
// Timing of THRE interrupt signal corrected.
// LSR bit 0 timing corrected.
//
// Revision 1.23  2001/11/12 21:57:29  gorban
// fixed more typo bugs
//
// Revision 1.22  2001/11/12 15:02:28  mohor
// lsr1r error fixed.
//
// Revision 1.21  2001/11/12 14:57:27  mohor
// ti_int_pnd error fixed.
//
// Revision 1.20  2001/11/12 14:50:27  mohor
// ti_int_d error fixed.
//
// Revision 1.19  2001/11/10 12:43:21  gorban
// Logic Synthesis bugs fixed. Some other minor changes
//
// Revision 1.18  2001/11/08 14:54:23  mohor
// Comments in Slovene language deleted, few small fixes for better work of
// old tools. IRQs need to be fix.
//
// Revision 1.17  2001/11/07 17:51:52  gorban
// Heavily rewritten interrupt and LSR subsystems.
// Many bugs hopefully squashed.
//
// Revision 1.16  2001/11/02 09:55:16  mohor
// no message
//
// Revision 1.15  2001/10/31 15:19:22  gorban
// Fixes to break and timeout conditions
//
// Revision 1.14  2001/10/29 17:00:46  gorban
// fixed parity sending and tx_fifo resets over- and underrun
//
// Revision 1.13  2001/10/20 09:58:40  gorban
// Small synopsis fixes
//
// Revision 1.12  2001/10/19 16:21:40  gorban
// Changes data_out to be synchronous again as it should have been.
//
// Revision 1.11  2001/10/18 20:35:45  gorban
// small fix
//
// Revision 1.10  2001/08/24 21:01:12  mohor
// Things connected to parity changed.
// Clock devider changed.
//
// Revision 1.9  2001/08/23 16:05:05  mohor
// Stop bit bug fixed.
// Parity bug fixed.
// WISHBONE read cycle bug fixed,
// OE indicator (Overrun Error) bug fixed.
// PE indicator (Parity Error) bug fixed.
// Register read bug fixed.
//
// Revision 1.10  2001/06/23 11:21:48  gorban
// DL made 16-bit long. Fixed transmission/reception bugs.
//
// Revision 1.9  2001/05/31 20:08:01  gorban
// FIFO changes and other corrections.
//
// Revision 1.8  2001/05/29 20:05:04  gorban
// Fixed some bugs and synthesis problems.
//
// Revision 1.7  2001/05/27 17:37:49  gorban
// Fixed many bugs. Updated spec. Changed FIFO files structure. See CHANGES.txt file.
//
// Revision 1.6  2001/05/21 19:12:02  gorban
// Corrected some Linter messages.
//
// Revision 1.5  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:11+02  jacob
// Initial revision
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "uart_defines.v"

`define UART_DL1 7:0
`define UART_DL2 15:8

module uart_regs (clk,
	wb_rst_i, wb_addr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_re_i, 

// additional signals
	modem_inputs,
	stx_pad_o, srx_pad_i,

`ifdef DATA_BUS_WIDTH_8
`else
// debug interface signals	enabled
ier, iir, fcr, mcr, lcr, msr, lsr, rf_count, tf_count, tstate, rstate,
`endif				
	rts_pad_o, dtr_pad_o, int_o
`ifdef UART_HAS_BAUDRATE_OUTPUT
	, baud_o
`endif

	);

input 									clk;
input 									wb_rst_i;
input [`UART_ADDR_WIDTH-1:0] 		wb_addr_i;
input [7:0] 							wb_dat_i;
output [7:0] 							wb_dat_o;
input 									wb_we_i;
input 									wb_re_i;

output 									stx_pad_o;
input 									srx_pad_i;

input [3:0] 							modem_inputs;
output 									rts_pad_o;
output 									dtr_pad_o;
output 									int_o;
`ifdef UART_HAS_BAUDRATE_OUTPUT
output	baud_o;
`endif

`ifdef DATA_BUS_WIDTH_8
`else
// if 32-bit databus and debug interface are enabled
output [3:0]							ier;
output [3:0]							iir;
output [1:0]							fcr;  /// bits 7 and 6 of fcr. Other bits are ignored
output [4:0]							mcr;
output [7:0]							lcr;
output [7:0]							msr;
output [7:0] 							lsr;
output [`UART_FIFO_COUNTER_W-1:0] 	rf_count;
output [`UART_FIFO_COUNTER_W-1:0] 	tf_count;
output [2:0] 							tstate;
output [3:0] 							rstate;

`endif

wire [3:0] 								modem_inputs;
reg 										enable;
`ifdef UART_HAS_BAUDRATE_OUTPUT
assign baud_o = enable; // baud_o is actually the enable signal
`endif


wire 										stx_pad_o;		// received from transmitter module
wire 										srx_pad_i;
wire 										srx_pad;

reg [7:0] 								wb_dat_o;

wire [`UART_ADDR_WIDTH-1:0] 		wb_addr_i;
wire [7:0] 								wb_dat_i;


reg [3:0] 								ier;
reg [3:0] 								iir;
reg [1:0] 								fcr;  /// bits 7 and 6 of fcr. Other bits are ignored
reg [4:0] 								mcr;
reg [7:0] 								lcr;
reg [7:0] 								msr;
`ifdef UART_FIX_BAUDRATE
   wire [15:0] 								dl;
   assign dl = 16'h`UART_DIVISOR;
`else      
reg [15:0] 								dl;  // 32-bit divisor latch
`endif
reg [7:0] 								scratch; // UART scratch register
reg 										start_dlc; // activate dlc on writing to UART_DL1
reg 										lsr_mask_d; // delay for lsr_mask condition
reg 										msi_reset; // reset MSR 4 lower bits indicator
//reg 										threi_clear; // THRE interrupt clear flag
reg [15:0] 								dlc;  // 32-bit divisor latch counter
reg 										int_o;

reg [3:0] 								trigger_level; // trigger level of the receiver FIFO
reg 										rx_reset;
reg 										tx_reset;

wire 										dlab;			   // divisor latch access bit
wire 										cts_pad_i, dsr_pad_i, ri_pad_i, dcd_pad_i; // modem status bits
wire 										loopback;		   // loopback bit (MCR bit 4)
wire 										cts, dsr, ri, dcd;	   // effective signals
wire                    cts_c, dsr_c, ri_c, dcd_c; // Complement effective signals (considering loopback)
wire 										rts_pad_o, dtr_pad_o;		   // modem control outputs

// LSR bits wires and regs
wire [7:0] 								lsr;
wire 										lsr0, lsr1, lsr2, lsr3, lsr4, lsr5, lsr6, lsr7;
reg										lsr0r, lsr1r, lsr2r, lsr3r, lsr4r, lsr5r, lsr6r, lsr7r;
wire 										lsr_mask; // lsr_mask

//
// ASSINGS
//

assign 									lsr[7:0] = { lsr7r, lsr6r, lsr5r, lsr4r, lsr3r, lsr2r, lsr1r, lsr0r };

assign 									{cts_pad_i, dsr_pad_i, ri_pad_i, dcd_pad_i} = modem_inputs;
assign 									{cts, dsr, ri, dcd} = ~{cts_pad_i,dsr_pad_i,ri_pad_i,dcd_pad_i};

assign                  {cts_c, dsr_c, ri_c, dcd_c} = loopback ? {mcr[`UART_MC_RTS],mcr[`UART_MC_DTR],mcr[`UART_MC_OUT1],mcr[`UART_MC_OUT2]}
                                                               : {cts_pad_i,dsr_pad_i,ri_pad_i,dcd_pad_i};

assign 									dlab = lcr[`UART_LC_DL];
assign 									loopback = mcr[4];

// assign modem outputs
assign 									rts_pad_o = mcr[`UART_MC_RTS];
assign 									dtr_pad_o = mcr[`UART_MC_DTR];

// Interrupt signals
wire 										rls_int;  // receiver line status interrupt
wire 										rda_int;  // receiver data available interrupt
wire 										ti_int;   // timeout indicator interrupt
wire										thre_int; // transmitter holding register empty interrupt
wire 										ms_int;   // modem status interrupt

// FIFO signals
reg 										tf_push;
reg 										rf_pop;
wire [`UART_FIFO_REC_WIDTH-1:0] 	rf_data_out;
wire 										rf_error_bit; // an error (parity or framing) is inside the fifo
wire [`UART_FIFO_COUNTER_W-1:0] 	rf_count;
wire [`UART_FIFO_COUNTER_W-1:0] 	tf_count;
wire [2:0] 								tstate;
wire [3:0] 								rstate;
wire [9:0] 								counter_t;

wire                      thre_set_en; // THRE status is delayed one character time when a character is written to fifo.
reg  [7:0]                block_cnt;   // While counter counts, THRE status is blocked (delayed one character cycle)
reg  [7:0]                block_value; // One character length minus stop bit

// Transmitter Instance
wire serial_out;

uart_transmitter transmitter(clk, wb_rst_i, lcr, tf_push, wb_dat_i, enable, serial_out, tstate, tf_count, tx_reset, lsr_mask);

  // Synchronizing and sampling serial RX input
  uart_sync_flops    i_uart_sync_flops
  (
    .rst_i           (wb_rst_i),
    .clk_i           (clk),
    .stage1_rst_i    (1'b0),
    .stage1_clk_en_i (1'b1),
    .async_dat_i     (srx_pad_i),
    .sync_dat_o      (srx_pad)
  );
  defparam i_uart_sync_flops.width      = 1;
  defparam i_uart_sync_flops.init_value = 1'b1;

// handle loopback
wire serial_in = loopback ? serial_out : srx_pad;
assign stx_pad_o = loopback ? 1'b1 : serial_out;

// Receiver Instance
uart_receiver receiver(clk, wb_rst_i, lcr, rf_pop, serial_in, enable, 
	counter_t, rf_count, rf_data_out, rf_error_bit, rf_overrun, rx_reset, lsr_mask, rstate, rf_push_pulse);


// Asynchronous reading here because the outputs are sampled in uart_wb.v file 
always @(dl or dlab or ier or iir or scratch
			or lcr or lsr or msr or rf_data_out or wb_addr_i or wb_re_i)   // asynchrounous reading
begin
	case (wb_addr_i)
		`UART_REG_RB   : wb_dat_o = dlab ? dl[`UART_DL1] : rf_data_out[10:3];
		`UART_REG_IE	: wb_dat_o = dlab ? dl[`UART_DL2] : ier;
		`UART_REG_II	: wb_dat_o = {4'b1100,iir};
		`UART_REG_LC	: wb_dat_o = lcr;
		`UART_REG_LS	: wb_dat_o = lsr;
		`UART_REG_MS	: wb_dat_o = msr;
		`UART_REG_SR	: wb_dat_o = scratch;
		default:  wb_dat_o = 8'b0; // ??
	endcase // case(wb_addr_i)
end // always @ (dl or dlab or ier or iir or scratch...


// rf_pop signal handling
always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		rf_pop <= #1 0; 
	else
	if (rf_pop)	// restore the signal to 0 after one clock cycle
		rf_pop <= #1 0;
	else
	if (wb_re_i && wb_addr_i == `UART_REG_RB && !dlab)
		rf_pop <= #1 1; // advance read pointer
end

wire 	lsr_mask_condition;
wire 	iir_read;
wire  msr_read;
wire	fifo_read;
wire	fifo_write;

assign lsr_mask_condition = (wb_re_i && wb_addr_i == `UART_REG_LS && !dlab);
assign iir_read = (wb_re_i && wb_addr_i == `UART_REG_II && !dlab);
assign msr_read = (wb_re_i && wb_addr_i == `UART_REG_MS && !dlab);
assign fifo_read = (wb_re_i && wb_addr_i == `UART_REG_RB && !dlab);
assign fifo_write = (wb_we_i && wb_addr_i == `UART_REG_TR && !dlab);

// lsr_mask_d delayed signal handling
always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		lsr_mask_d <= #1 0;
	else // reset bits in the Line Status Register
		lsr_mask_d <= #1 lsr_mask_condition;
end

// lsr_mask is rise detected
assign lsr_mask = lsr_mask_condition && ~lsr_mask_d;

// msi_reset signal handling
always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		msi_reset <= #1 1;
	else
	if (msi_reset)
		msi_reset <= #1 0;
	else
	if (msr_read)
		msi_reset <= #1 1; // reset bits in Modem Status Register
end


//
//   WRITES AND RESETS   //
//
// Line Control Register
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		lcr <= #1 8'b00000011; // 8n1 setting
	else
	if (wb_we_i && wb_addr_i==`UART_REG_LC)
		lcr <= #1 wb_dat_i;

// Interrupt Enable Register or UART_DL2
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
	begin
		ier <= #1 4'b0000; // no interrupts after reset
`ifdef UART_FIX_BAUDRATE
`else	   
		dl[`UART_DL2] <= #1 8'b0;
`endif	   
	end
	else
	if (wb_we_i && wb_addr_i==`UART_REG_IE)
		if (dlab)
		  begin
`ifdef UART_FIX_BAUDRATE
`else		     
			dl[`UART_DL2] <= #1 wb_dat_i;
`endif		     
		end
		else
			ier <= #1 wb_dat_i[3:0]; // ier uses only 4 lsb


// FIFO Control Register and rx_reset, tx_reset signals
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) begin
		fcr <= #1 2'b11; 
		rx_reset <= #1 0;
		tx_reset <= #1 0;
	end else
	if (wb_we_i && wb_addr_i==`UART_REG_FC) begin
		fcr <= #1 wb_dat_i[7:6];
		rx_reset <= #1 wb_dat_i[1];
		tx_reset <= #1 wb_dat_i[2];
	end else begin
		rx_reset <= #1 0;
		tx_reset <= #1 0;
	end

// Modem Control Register
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		mcr <= #1 5'b0; 
	else
	if (wb_we_i && wb_addr_i==`UART_REG_MC)
			mcr <= #1 wb_dat_i[4:0];

// Scratch register
// Line Control Register
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		scratch <= #1 0; // 8n1 setting
	else
	if (wb_we_i && wb_addr_i==`UART_REG_SR)
		scratch <= #1 wb_dat_i;

// TX_FIFO or UART_DL1
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
	  begin
`ifdef UART_FIX_BAUDRATE
`else	     
		dl[`UART_DL1]  <= #1 8'b0;
`endif	     
		tf_push   <= #1 1'b0;
		start_dlc <= #1 1'b0;
	end
	else
	if (wb_we_i && wb_addr_i==`UART_REG_TR)
		if (dlab)
		  begin
`ifdef UART_FIX_BAUDRATE
`else		     
			dl[`UART_DL1] <= #1 wb_dat_i;
`endif
			start_dlc <= #1 1'b1; // enable DL counter
			tf_push <= #1 1'b0;
		end
		else
		begin
			tf_push   <= #1 1'b1;
			start_dlc <= #1 1'b0;
		end // else: !if(dlab)
	else
	begin
		start_dlc <= #1 1'b0;
		tf_push   <= #1 1'b0;
	end // else: !if(dlab)

// Receiver FIFO trigger level selection logic (asynchronous mux)
always @(fcr)
	case (fcr[`UART_FC_TL])
		2'b00 : trigger_level = 1;
		2'b01 : trigger_level = 4;
		2'b10 : trigger_level = 8;
		2'b11 : trigger_level = 14;
	endcase // case(fcr[`UART_FC_TL])
	
//
//  STATUS REGISTERS  //
//

// Modem Status Register
reg [3:0] delayed_modem_signals;
always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
	  begin
  		msr <= #1 0;
	  	delayed_modem_signals[3:0] <= #1 0;
	  end
	else begin
		msr[`UART_MS_DDCD:`UART_MS_DCTS] <= #1 msi_reset ? 4'b0 :
			msr[`UART_MS_DDCD:`UART_MS_DCTS] | ({dcd, ri, dsr, cts} ^ delayed_modem_signals[3:0]);
		msr[`UART_MS_CDCD:`UART_MS_CCTS] <= #1 {dcd_c, ri_c, dsr_c, cts_c};
		delayed_modem_signals[3:0] <= #1 {dcd, ri, dsr, cts};
	end
end


// Line Status Register

// activation conditions
assign lsr0 = (rf_count==0 && rf_push_pulse);  // data in receiver fifo available set condition
assign lsr1 = rf_overrun;     // Receiver overrun error
assign lsr2 = rf_data_out[1]; // parity error bit
assign lsr3 = rf_data_out[0]; // framing error bit
assign lsr4 = rf_data_out[2]; // break error in the character
assign lsr5 = (tf_count==5'b0 && thre_set_en);  // transmitter fifo is empty
assign lsr6 = (tf_count==5'b0 && thre_set_en && (tstate == /*`S_IDLE */ 0)); // transmitter empty
assign lsr7 = rf_error_bit | rf_overrun;

// lsr bit0 (receiver data available)
reg 	 lsr0_d;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr0_d <= #1 0;
	else lsr0_d <= #1 lsr0;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr0r <= #1 0;
	else lsr0r <= #1 (rf_count==1 && rf_pop && !rf_push_pulse || rx_reset) ? 0 : // deassert condition
					  lsr0r || (lsr0 && ~lsr0_d); // set on rise of lsr0 and keep asserted until deasserted 

// lsr bit 1 (receiver overrun)
reg lsr1_d; // delayed

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr1_d <= #1 0;
	else lsr1_d <= #1 lsr1;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr1r <= #1 0;
	else	lsr1r <= #1	lsr_mask ? 0 : lsr1r || (lsr1 && ~lsr1_d); // set on rise

// lsr bit 2 (parity error)
reg lsr2_d; // delayed

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr2_d <= #1 0;
	else lsr2_d <= #1 lsr2;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr2r <= #1 0;
	else lsr2r <= #1 lsr_mask ? 0 : lsr2r || (lsr2 && ~lsr2_d); // set on rise

// lsr bit 3 (framing error)
reg lsr3_d; // delayed

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr3_d <= #1 0;
	else lsr3_d <= #1 lsr3;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr3r <= #1 0;
	else lsr3r <= #1 lsr_mask ? 0 : lsr3r || (lsr3 && ~lsr3_d); // set on rise

// lsr bit 4 (break indicator)
reg lsr4_d; // delayed

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr4_d <= #1 0;
	else lsr4_d <= #1 lsr4;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr4r <= #1 0;
	else lsr4r <= #1 lsr_mask ? 0 : lsr4r || (lsr4 && ~lsr4_d);

// lsr bit 5 (transmitter fifo is empty)
reg lsr5_d;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr5_d <= #1 1;
	else lsr5_d <= #1 lsr5;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr5r <= #1 1;
	else lsr5r <= #1 (fifo_write) ? 0 :  lsr5r || (lsr5 && ~lsr5_d);

// lsr bit 6 (transmitter empty indicator)
reg lsr6_d;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr6_d <= #1 1;
	else lsr6_d <= #1 lsr6;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr6r <= #1 1;
	else lsr6r <= #1 (fifo_write) ? 0 : lsr6r || (lsr6 && ~lsr6_d);

// lsr bit 7 (error in fifo)
reg lsr7_d;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr7_d <= #1 0;
	else lsr7_d <= #1 lsr7;

always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) lsr7r <= #1 0;
	else lsr7r <= #1 lsr_mask ? 0 : lsr7r || (lsr7 && ~lsr7_d);

// Frequency divider
always @(posedge clk or posedge wb_rst_i) 
begin
	if (wb_rst_i)
		dlc <= #1 0;
	else
		if (start_dlc | ~ (|dlc))
  			dlc <= #1 dl - 1;               // preset counter
		else
			dlc <= #1 dlc - 1;              // decrement counter
end

// Enable signal generation logic
always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		enable <= #1 1'b0;
	else
		if (|dl & ~(|dlc))     // dl>0 & dlc==0
			enable <= #1 1'b1;
		else
			enable <= #1 1'b0;
end

// Delaying THRE status for one character cycle after a character is written to an empty fifo.
always @(lcr)
  case (lcr[3:0])
    4'b0000                             : block_value =  95; // 6 bits
    4'b0100                             : block_value = 103; // 6.5 bits
    4'b0001, 4'b1000                    : block_value = 111; // 7 bits
    4'b1100                             : block_value = 119; // 7.5 bits
    4'b0010, 4'b0101, 4'b1001           : block_value = 127; // 8 bits
    4'b0011, 4'b0110, 4'b1010, 4'b1101  : block_value = 143; // 9 bits
    4'b0111, 4'b1011, 4'b1110           : block_value = 159; // 10 bits
    4'b1111                             : block_value = 175; // 11 bits
  endcase // case(lcr[3:0])

// Counting time of one character minus stop bit
always @(posedge clk or posedge wb_rst_i)
begin
  if (wb_rst_i)
    block_cnt <= #1 8'd0;
  else
  if(lsr5r & fifo_write)  // THRE bit set & write to fifo occured
    block_cnt <= #1 block_value;
  else
  if (enable & block_cnt != 8'b0)  // only work on enable times
    block_cnt <= #1 block_cnt - 1;  // decrement break counter
end // always of break condition detection

// Generating THRE status enable signal
assign thre_set_en = ~(|block_cnt);


//
//	INTERRUPT LOGIC
//

assign rls_int  = ier[`UART_IE_RLS] && (lsr[`UART_LS_OE] || lsr[`UART_LS_PE] || lsr[`UART_LS_FE] || lsr[`UART_LS_BI]);
assign rda_int  = ier[`UART_IE_RDA] && (rf_count >= {1'b0,trigger_level});
assign thre_int = ier[`UART_IE_THRE] && lsr[`UART_LS_TFE];
assign ms_int   = ier[`UART_IE_MS] && (| msr[3:0]);
assign ti_int   = ier[`UART_IE_RDA] && (counter_t == 10'b0) && (|rf_count);

reg 	 rls_int_d;
reg 	 thre_int_d;
reg 	 ms_int_d;
reg 	 ti_int_d;
reg 	 rda_int_d;

// delay lines
always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) rls_int_d <= #1 0;
	else rls_int_d <= #1 rls_int;

always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) rda_int_d <= #1 0;
	else rda_int_d <= #1 rda_int;

always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) thre_int_d <= #1 0;
	else thre_int_d <= #1 thre_int;

always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) ms_int_d <= #1 0;
	else ms_int_d <= #1 ms_int;

always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) ti_int_d <= #1 0;
	else ti_int_d <= #1 ti_int;

// rise detection signals

wire 	 rls_int_rise;
wire 	 thre_int_rise;
wire 	 ms_int_rise;
wire 	 ti_int_rise;
wire 	 rda_int_rise;

assign rda_int_rise    = rda_int & ~rda_int_d;
assign rls_int_rise 	  = rls_int & ~rls_int_d;
assign thre_int_rise   = thre_int & ~thre_int_d;
assign ms_int_rise 	  = ms_int & ~ms_int_d;
assign ti_int_rise 	  = ti_int & ~ti_int_d;

// interrupt pending flags
reg 	rls_int_pnd;
reg	rda_int_pnd;
reg 	thre_int_pnd;
reg 	ms_int_pnd;
reg 	ti_int_pnd;

// interrupt pending flags assignments
always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) rls_int_pnd <= #1 0; 
	else 
		rls_int_pnd <= #1 lsr_mask ? 0 :  						// reset condition
							rls_int_rise ? 1 :						// latch condition
							rls_int_pnd && ier[`UART_IE_RLS];	// default operation: remove if masked

always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) rda_int_pnd <= #1 0; 
	else 
		rda_int_pnd <= #1 ((rf_count == {1'b0,trigger_level}) && fifo_read) ? 0 :  	// reset condition
							rda_int_rise ? 1 :						// latch condition
							rda_int_pnd && ier[`UART_IE_RDA];	// default operation: remove if masked

always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) thre_int_pnd <= #1 0; 
	else 
		thre_int_pnd <= #1 fifo_write || (iir_read & ~iir[`UART_II_IP] & iir[`UART_II_II] == `UART_II_THRE)? 0 : 
							thre_int_rise ? 1 :
							thre_int_pnd && ier[`UART_IE_THRE];

always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) ms_int_pnd <= #1 0; 
	else 
		ms_int_pnd <= #1 msr_read ? 0 : 
							ms_int_rise ? 1 :
							ms_int_pnd && ier[`UART_IE_MS];

always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) ti_int_pnd <= #1 0; 
	else 
		ti_int_pnd <= #1 fifo_read ? 0 : 
							ti_int_rise ? 1 :
							ti_int_pnd && ier[`UART_IE_RDA];
// end of pending flags

// INT_O logic
always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)	
		int_o <= #1 1'b0;
	else
		int_o <= #1 
					rls_int_pnd		?	~lsr_mask					:
					rda_int_pnd		? 1								:
					ti_int_pnd		? ~fifo_read					:
					thre_int_pnd	? !(fifo_write & iir_read) :
					ms_int_pnd		? ~msr_read						:
					0;	// if no interrupt are pending
end


// Interrupt Identification register
always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		iir <= #1 1;
	else
	if (rls_int_pnd)  // interrupt is pending
	begin
		iir[`UART_II_II] <= #1 `UART_II_RLS;	// set identification register to correct value
		iir[`UART_II_IP] <= #1 1'b0;		// and clear the IIR bit 0 (interrupt pending)
	end else // the sequence of conditions determines priority of interrupt identification
	if (rda_int)
	begin
		iir[`UART_II_II] <= #1 `UART_II_RDA;
		iir[`UART_II_IP] <= #1 1'b0;
	end
	else if (ti_int_pnd)
	begin
		iir[`UART_II_II] <= #1 `UART_II_TI;
		iir[`UART_II_IP] <= #1 1'b0;
	end
	else if (thre_int_pnd)
	begin
		iir[`UART_II_II] <= #1 `UART_II_THRE;
		iir[`UART_II_IP] <= #1 1'b0;
	end
	else if (ms_int_pnd)
	begin
		iir[`UART_II_II] <= #1 `UART_II_MS;
		iir[`UART_II_IP] <= #1 1'b0;
	end else	// no interrupt is pending
	begin
		iir[`UART_II_II] <= #1 0;
		iir[`UART_II_IP] <= #1 1'b1;
	end
end

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_rfifo.v (Modified from uart_fifo.v)                    ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UART core receiver FIFO                                     ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing.                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   2002/07/22                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: uart_rfifo.v,v $
// Revision 1.4  2003/07/11 18:20:26  gorban
// added clearing the receiver fifo statuses on resets
//
// Revision 1.3  2003/06/11 16:37:47  gorban
// This fixes errors in some cases when data is being read and put to the FIFO at the same time. Patch is submitted by Scott Furman. Update is very recommended.
//
// Revision 1.2  2002/07/29 21:16:18  gorban
// The uart_defines.v file is included again in sources.
//
// Revision 1.1  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UART_HAS_BAUDRATE_OUTPUT to use.
//
// Revision 1.16  2001/12/20 13:25:46  mohor
// rx push changed to be only one cycle wide.
//
// Revision 1.15  2001/12/18 09:01:07  mohor
// Bug that was entered in the last update fixed (rx state machine).
//
// Revision 1.14  2001/12/17 14:46:48  mohor
// overrun signal was moved to separate block because many sequential lsr
// reads were preventing data from being written to rx fifo.
// underrun signal was not used and was removed from the project.
//
// Revision 1.13  2001/11/26 21:38:54  gorban
// Lots of fixes:
// Break condition wasn't handled correctly at all.
// LSR bits could lose their values.
// LSR value after reset was wrong.
// Timing of THRE interrupt signal corrected.
// LSR bit 0 timing corrected.
//
// Revision 1.12  2001/11/08 14:54:23  mohor
// Comments in Slovene language deleted, few small fixes for better work of
// old tools. IRQs need to be fix.
//
// Revision 1.11  2001/11/07 17:51:52  gorban
// Heavily rewritten interrupt and LSR subsystems.
// Many bugs hopefully squashed.
//
// Revision 1.10  2001/10/20 09:58:40  gorban
// Small synopsis fixes
//
// Revision 1.9  2001/08/24 21:01:12  mohor
// Things connected to parity changed.
// Clock devider changed.
//
// Revision 1.8  2001/08/24 08:48:10  mohor
// FIFO was not cleared after the data was read bug fixed.
//
// Revision 1.7  2001/08/23 16:05:05  mohor
// Stop bit bug fixed.
// Parity bug fixed.
// WISHBONE read cycle bug fixed,
// OE indicator (Overrun Error) bug fixed.
// PE indicator (Parity Error) bug fixed.
// Register read bug fixed.
//
// Revision 1.3  2001/05/31 20:08:01  gorban
// FIFO changes and other corrections.
//
// Revision 1.3  2001/05/27 17:37:48  gorban
// Fixed many bugs. Updated spec. Changed FIFO files structure. See CHANGES.txt file.
//
// Revision 1.2  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:12+02  jacob
// Initial revision
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "uart_defines.v"

module uart_rfifo (clk, 
	wb_rst_i, data_in, data_out,
// Control signals
	push, // push strobe, active high
	pop,   // pop strobe, active high
// status signals
	overrun,
	count,
	error_bit,
	fifo_reset,
	reset_status
	);


// FIFO parameters
parameter fifo_width = `UART_FIFO_WIDTH;
parameter fifo_depth = `UART_FIFO_DEPTH;
parameter fifo_pointer_w = `UART_FIFO_POINTER_W;
parameter fifo_counter_w = `UART_FIFO_COUNTER_W;

input				clk;
input				wb_rst_i;
input				push;
input				pop;
input	[fifo_width-1:0]	data_in;
input				fifo_reset;
input       reset_status;

output	[fifo_width-1:0]	data_out;
output				overrun;
output	[fifo_counter_w-1:0]	count;
output				error_bit;

wire	[fifo_width-1:0]	data_out;
wire [7:0] data8_out;
// flags FIFO
reg	[2:0]	fifo[fifo_depth-1:0];

// FIFO pointers
reg	[fifo_pointer_w-1:0]	top;
reg	[fifo_pointer_w-1:0]	bottom;

reg	[fifo_counter_w-1:0]	count;
reg				overrun;

wire [fifo_pointer_w-1:0] top_plus_1 = top + 1'b1;

raminfr #(fifo_pointer_w,8,fifo_depth) rfifo  
        (.clk(clk), 
			.we(push), 
			.a(top), 
			.dpra(bottom), 
			.di(data_in[fifo_width-1:fifo_width-8]), 
			.dpo(data8_out)
		); 

always @(posedge clk or posedge wb_rst_i) // synchronous FIFO
begin
	if (wb_rst_i)
	begin
		top		<= #1 0;
		bottom		<= #1 1'b0;
		count		<= #1 0;
		fifo[0] <= #1 0;
		fifo[1] <= #1 0;
		fifo[2] <= #1 0;
		fifo[3] <= #1 0;
		fifo[4] <= #1 0;
		fifo[5] <= #1 0;
		fifo[6] <= #1 0;
		fifo[7] <= #1 0;
		fifo[8] <= #1 0;
		fifo[9] <= #1 0;
		fifo[10] <= #1 0;
		fifo[11] <= #1 0;
		fifo[12] <= #1 0;
		fifo[13] <= #1 0;
		fifo[14] <= #1 0;
		fifo[15] <= #1 0;
	end
	else
	if (fifo_reset) begin
		top		<= #1 0;
		bottom		<= #1 1'b0;
		count		<= #1 0;
		fifo[0] <= #1 0;
		fifo[1] <= #1 0;
		fifo[2] <= #1 0;
		fifo[3] <= #1 0;
		fifo[4] <= #1 0;
		fifo[5] <= #1 0;
		fifo[6] <= #1 0;
		fifo[7] <= #1 0;
		fifo[8] <= #1 0;
		fifo[9] <= #1 0;
		fifo[10] <= #1 0;
		fifo[11] <= #1 0;
		fifo[12] <= #1 0;
		fifo[13] <= #1 0;
		fifo[14] <= #1 0;
		fifo[15] <= #1 0;
	end
  else
	begin
		case ({push, pop})
		2'b10 : if (count<fifo_depth)  // overrun condition
			begin
				top       <= #1 top_plus_1;
				fifo[top] <= #1 data_in[2:0];
				count     <= #1 count + 1'b1;
			end
		2'b01 : if(count>0)
			begin
        fifo[bottom] <= #1 0;
				bottom   <= #1 bottom + 1'b1;
				count	 <= #1 count - 1'b1;
			end
		2'b11 : begin
				bottom   <= #1 bottom + 1'b1;
				top       <= #1 top_plus_1;
				fifo[top] <= #1 data_in[2:0];
		        end
    default: ;
		endcase
	end
end   // always

always @(posedge clk or posedge wb_rst_i) // synchronous FIFO
begin
  if (wb_rst_i)
    overrun   <= #1 1'b0;
  else
  if(fifo_reset | reset_status) 
    overrun   <= #1 1'b0;
  else
  if(push & ~pop & (count==fifo_depth))
    overrun   <= #1 1'b1;
end   // always


// please note though that data_out is only valid one clock after pop signal
assign data_out = {data8_out,fifo[bottom]};

// Additional logic for detection of error conditions (parity and framing) inside the FIFO
// for the Line Status Register bit 7

wire	[2:0]	word0 = fifo[0];
wire	[2:0]	word1 = fifo[1];
wire	[2:0]	word2 = fifo[2];
wire	[2:0]	word3 = fifo[3];
wire	[2:0]	word4 = fifo[4];
wire	[2:0]	word5 = fifo[5];
wire	[2:0]	word6 = fifo[6];
wire	[2:0]	word7 = fifo[7];

wire	[2:0]	word8 = fifo[8];
wire	[2:0]	word9 = fifo[9];
wire	[2:0]	word10 = fifo[10];
wire	[2:0]	word11 = fifo[11];
wire	[2:0]	word12 = fifo[12];
wire	[2:0]	word13 = fifo[13];
wire	[2:0]	word14 = fifo[14];
wire	[2:0]	word15 = fifo[15];

// a 1 is returned if any of the error bits in the fifo is 1
assign	error_bit = |(word0[2:0]  | word1[2:0]  | word2[2:0]  | word3[2:0]  |
            		      word4[2:0]  | word5[2:0]  | word6[2:0]  | word7[2:0]  |
            		      word8[2:0]  | word9[2:0]  | word10[2:0] | word11[2:0] |
            		      word12[2:0] | word13[2:0] | word14[2:0] | word15[2:0] );

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_tfifo.v                                                ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UART core transmitter FIFO                                  ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing.                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   2002/07/22                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: uart_tfifo.v,v $
// Revision 1.2  2002/07/29 21:16:18  gorban
// The uart_defines.v file is included again in sources.
//
// Revision 1.1  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UART_HAS_BAUDRATE_OUTPUT to use.
//
// Revision 1.16  2001/12/20 13:25:46  mohor
// rx push changed to be only one cycle wide.
//
// Revision 1.15  2001/12/18 09:01:07  mohor
// Bug that was entered in the last update fixed (rx state machine).
//
// Revision 1.14  2001/12/17 14:46:48  mohor
// overrun signal was moved to separate block because many sequential lsr
// reads were preventing data from being written to rx fifo.
// underrun signal was not used and was removed from the project.
//
// Revision 1.13  2001/11/26 21:38:54  gorban
// Lots of fixes:
// Break condition wasn't handled correctly at all.
// LSR bits could lose their values.
// LSR value after reset was wrong.
// Timing of THRE interrupt signal corrected.
// LSR bit 0 timing corrected.
//
// Revision 1.12  2001/11/08 14:54:23  mohor
// Comments in Slovene language deleted, few small fixes for better work of
// old tools. IRQs need to be fix.
//
// Revision 1.11  2001/11/07 17:51:52  gorban
// Heavily rewritten interrupt and LSR subsystems.
// Many bugs hopefully squashed.
//
// Revision 1.10  2001/10/20 09:58:40  gorban
// Small synopsis fixes
//
// Revision 1.9  2001/08/24 21:01:12  mohor
// Things connected to parity changed.
// Clock devider changed.
//
// Revision 1.8  2001/08/24 08:48:10  mohor
// FIFO was not cleared after the data was read bug fixed.
//
// Revision 1.7  2001/08/23 16:05:05  mohor
// Stop bit bug fixed.
// Parity bug fixed.
// WISHBONE read cycle bug fixed,
// OE indicator (Overrun Error) bug fixed.
// PE indicator (Parity Error) bug fixed.
// Register read bug fixed.
//
// Revision 1.3  2001/05/31 20:08:01  gorban
// FIFO changes and other corrections.
//
// Revision 1.3  2001/05/27 17:37:48  gorban
// Fixed many bugs. Updated spec. Changed FIFO files structure. See CHANGES.txt file.
//
// Revision 1.2  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:12+02  jacob
// Initial revision
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "uart_defines.v"

module uart_tfifo (clk, 
	wb_rst_i, data_in, data_out,
// Control signals
	push, // push strobe, active high
	pop,   // pop strobe, active high
// status signals
	overrun,
	count,
	fifo_reset,
	reset_status
	);


// FIFO parameters
parameter fifo_width = `UART_FIFO_WIDTH;
parameter fifo_depth = `UART_FIFO_DEPTH;
parameter fifo_pointer_w = `UART_FIFO_POINTER_W;
parameter fifo_counter_w = `UART_FIFO_COUNTER_W;

input				clk;
input				wb_rst_i;
input				push;
input				pop;
input	[fifo_width-1:0]	data_in;
input				fifo_reset;
input       reset_status;

output	[fifo_width-1:0]	data_out;
output				overrun;
output	[fifo_counter_w-1:0]	count;

wire	[fifo_width-1:0]	data_out;

// FIFO pointers
reg	[fifo_pointer_w-1:0]	top;
reg	[fifo_pointer_w-1:0]	bottom;

reg	[fifo_counter_w-1:0]	count;
reg				overrun;
wire [fifo_pointer_w-1:0] top_plus_1 = top + 1'b1;

raminfr #(fifo_pointer_w,fifo_width,fifo_depth) tfifo  
        (.clk(clk), 
			.we(push), 
			.a(top), 
			.dpra(bottom), 
			.di(data_in), 
			.dpo(data_out)
		); 


always @(posedge clk or posedge wb_rst_i) // synchronous FIFO
begin
	if (wb_rst_i)
	begin
		top		<= #1 0;
		bottom		<= #1 1'b0;
		count		<= #1 0;
	end
	else
	if (fifo_reset) begin
		top		<= #1 0;
		bottom		<= #1 1'b0;
		count		<= #1 0;
	end
  else
	begin
		case ({push, pop})
		2'b10 : if (count<fifo_depth)  // overrun condition
			begin
				top       <= #1 top_plus_1;
				count     <= #1 count + 1'b1;
			end
		2'b01 : if(count>0)
			begin
				bottom   <= #1 bottom + 1'b1;
				count	 <= #1 count - 1'b1;
			end
		2'b11 : begin
				bottom   <= #1 bottom + 1'b1;
				top       <= #1 top_plus_1;
		        end
    default: ;
		endcase
	end
end   // always

always @(posedge clk or posedge wb_rst_i) // synchronous FIFO
begin
  if (wb_rst_i)
    overrun   <= #1 1'b0;
  else
  if(fifo_reset | reset_status) 
    overrun   <= #1 1'b0;
  else
  if(push & (count==fifo_depth))
    overrun   <= #1 1'b1;
end   // always

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_receiver.v                                             ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UART core receiver logic                                    ////
////                                                              ////
////  Known problems (limits):                                    ////
////  None known                                                  ////
////                                                              ////
////  To Do:                                                      ////
////  Thourough testing.                                          ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   2001/05/17                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: uart_receiver.v,v $
// Revision 1.31  2004/06/18 14:46:15  tadejm
// Brandl Tobias repaired a bug regarding frame error in receiver when brake is received.
//
// Revision 1.29  2002/07/29 21:16:18  gorban
// The uart_defines.v file is included again in sources.
//
// Revision 1.28  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UART_HAS_BAUDRATE_OUTPUT to use.
//
// Revision 1.27  2001/12/30 20:39:13  mohor
// More than one character was stored in case of break. End of the break
// was not detected correctly.
//
// Revision 1.26  2001/12/20 13:28:27  mohor
// Missing declaration of rf_push_q fixed.
//
// Revision 1.25  2001/12/20 13:25:46  mohor
// rx push changed to be only one cycle wide.
//
// Revision 1.24  2001/12/19 08:03:34  mohor
// Warnings cleared.
//
// Revision 1.23  2001/12/19 07:33:54  mohor
// Synplicity was having troubles with the comment.
//
// Revision 1.22  2001/12/17 14:46:48  mohor
// overrun signal was moved to separate block because many sequential lsr
// reads were preventing data from being written to rx fifo.
// underrun signal was not used and was removed from the project.
//
// Revision 1.21  2001/12/13 10:31:16  mohor
// timeout irq must be set regardless of the rda irq (rda irq does not reset the
// timeout counter).
//
// Revision 1.20  2001/12/10 19:52:05  gorban
// Igor fixed break condition bugs
//
// Revision 1.19  2001/12/06 14:51:04  gorban
// Bug in LSR[0] is fixed.
// All WISHBONE signals are now sampled, so another wait-state is introduced on all transfers.
//
// Revision 1.18  2001/12/03 21:44:29  gorban
// Updated specification documentation.
// Added full 32-bit data bus interface, now as default.
// Address is 5-bit wide in 32-bit data bus mode.
// Added wb_sel_i input to the core. It's used in the 32-bit mode.
// Added debug interface with two 32-bit read-only registers in 32-bit mode.
// Bits 5 and 6 of LSR are now only cleared on TX FIFO write.
// My small test bench is modified to work with 32-bit mode.
//
// Revision 1.17  2001/11/28 19:36:39  gorban
// Fixed: timeout and break didn't pay attention to current data format when counting time
//
// Revision 1.16  2001/11/27 22:17:09  gorban
// Fixed bug that prevented synthesis in uart_receiver.v
//
// Revision 1.15  2001/11/26 21:38:54  gorban
// Lots of fixes:
// Break condition wasn't handled correctly at all.
// LSR bits could lose their values.
// LSR value after reset was wrong.
// Timing of THRE interrupt signal corrected.
// LSR bit 0 timing corrected.
//
// Revision 1.14  2001/11/10 12:43:21  gorban
// Logic Synthesis bugs fixed. Some other minor changes
//
// Revision 1.13  2001/11/08 14:54:23  mohor
// Comments in Slovene language deleted, few small fixes for better work of
// old tools. IRQs need to be fix.
//
// Revision 1.12  2001/11/07 17:51:52  gorban
// Heavily rewritten interrupt and LSR subsystems.
// Many bugs hopefully squashed.
//
// Revision 1.11  2001/10/31 15:19:22  gorban
// Fixes to break and timeout conditions
//
// Revision 1.10  2001/10/20 09:58:40  gorban
// Small synopsis fixes
//
// Revision 1.9  2001/08/24 21:01:12  mohor
// Things connected to parity changed.
// Clock devider changed.
//
// Revision 1.8  2001/08/23 16:05:05  mohor
// Stop bit bug fixed.
// Parity bug fixed.
// WISHBONE read cycle bug fixed,
// OE indicator (Overrun Error) bug fixed.
// PE indicator (Parity Error) bug fixed.
// Register read bug fixed.
//
// Revision 1.6  2001/06/23 11:21:48  gorban
// DL made 16-bit long. Fixed transmission/reception bugs.
//
// Revision 1.5  2001/06/02 14:28:14  gorban
// Fixed receiver and transmitter. Major bug fixed.
//
// Revision 1.4  2001/05/31 20:08:01  gorban
// FIFO changes and other corrections.
//
// Revision 1.3  2001/05/27 17:37:49  gorban
// Fixed many bugs. Updated spec. Changed FIFO files structure. See CHANGES.txt file.
//
// Revision 1.2  2001/05/21 19:12:02  gorban
// Corrected some Linter messages.
//
// Revision 1.1  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:11+02  jacob
// Initial revision
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "uart_defines.v"

module uart_receiver (clk, wb_rst_i, lcr, rf_pop, srx_pad_i, enable, 
	counter_t, rf_count, rf_data_out, rf_error_bit, rf_overrun, rx_reset, lsr_mask, rstate, rf_push_pulse);

input				clk;
input				wb_rst_i;
input	[7:0]	lcr;
input				rf_pop;
input				srx_pad_i;
input				enable;
input				rx_reset;
input       lsr_mask;

output	[9:0]			counter_t;
output	[`UART_FIFO_COUNTER_W-1:0]	rf_count;
output	[`UART_FIFO_REC_WIDTH-1:0]	rf_data_out;
output				rf_overrun;
output				rf_error_bit;
output [3:0] 		rstate;
output 				rf_push_pulse;

reg	[3:0]	rstate;
reg	[3:0]	rcounter16;
reg	[2:0]	rbit_counter;
reg	[7:0]	rshift;			// receiver shift register
reg		rparity;		// received parity
reg		rparity_error;
reg		rframing_error;		// framing error flag
reg		rbit_in;
reg		rparity_xor;
reg	[7:0]	counter_b;	// counts the 0 (low) signals
reg   rf_push_q;

// RX FIFO signals
reg	[`UART_FIFO_REC_WIDTH-1:0]	rf_data_in;
wire	[`UART_FIFO_REC_WIDTH-1:0]	rf_data_out;
wire      rf_push_pulse;
reg				rf_push;
wire				rf_pop;
wire				rf_overrun;
wire	[`UART_FIFO_COUNTER_W-1:0]	rf_count;
wire				rf_error_bit; // an error (parity or framing) is inside the fifo
wire 				break_error = (counter_b == 0);

// RX FIFO instance
uart_rfifo #(`UART_FIFO_REC_WIDTH) fifo_rx(
	.clk(		clk		), 
	.wb_rst_i(	wb_rst_i	),
	.data_in(	rf_data_in	),
	.data_out(	rf_data_out	),
	.push(		rf_push_pulse		),
	.pop(		rf_pop		),
	.overrun(	rf_overrun	),
	.count(		rf_count	),
	.error_bit(	rf_error_bit	),
	.fifo_reset(	rx_reset	),
	.reset_status(lsr_mask)
);

wire 		rcounter16_eq_7 = (rcounter16 == 4'd7);
wire		rcounter16_eq_0 = (rcounter16 == 4'd0);
wire		rcounter16_eq_1 = (rcounter16 == 4'd1);

wire [3:0] rcounter16_minus_1 = rcounter16 - 1'b1;

parameter  sr_idle 					= 4'd0;
parameter  sr_rec_start 			= 4'd1;
parameter  sr_rec_bit 				= 4'd2;
parameter  sr_rec_parity			= 4'd3;
parameter  sr_rec_stop 				= 4'd4;
parameter  sr_check_parity 		= 4'd5;
parameter  sr_rec_prepare 			= 4'd6;
parameter  sr_end_bit				= 4'd7;
parameter  sr_ca_lc_parity	      = 4'd8;
parameter  sr_wait1 					= 4'd9;
parameter  sr_push 					= 4'd10;


always @(posedge clk or posedge wb_rst_i)
begin
  if (wb_rst_i)
  begin
     rstate 			<= #1 sr_idle;
	  rbit_in 				<= #1 1'b0;
	  rcounter16 			<= #1 0;
	  rbit_counter 		<= #1 0;
	  rparity_xor 		<= #1 1'b0;
	  rframing_error 	<= #1 1'b0;
	  rparity_error 		<= #1 1'b0;
	  rparity 				<= #1 1'b0;
	  rshift 				<= #1 0;
	  rf_push 				<= #1 1'b0;
	  rf_data_in 			<= #1 0;
  end
  else
  if (enable)
  begin
	case (rstate)
	sr_idle : begin
			rf_push 			  <= #1 1'b0;
			rf_data_in 	  <= #1 0;
			rcounter16 	  <= #1 4'b1110;
			if (srx_pad_i==1'b0 & ~break_error)   // detected a pulse (start bit?)
			begin
				rstate 		  <= #1 sr_rec_start;
			end
		end
	sr_rec_start :	begin
  			rf_push 			  <= #1 1'b0;
				if (rcounter16_eq_7)    // check the pulse
					if (srx_pad_i==1'b1)   // no start bit
						rstate <= #1 sr_idle;
					else            // start bit detected
						rstate <= #1 sr_rec_prepare;
				rcounter16 <= #1 rcounter16_minus_1;
			end
	sr_rec_prepare:begin
				case (lcr[/*`UART_LC_BITS*/1:0])  // number of bits in a word
				2'b00 : rbit_counter <= #1 3'b100;
				2'b01 : rbit_counter <= #1 3'b101;
				2'b10 : rbit_counter <= #1 3'b110;
				2'b11 : rbit_counter <= #1 3'b111;
				endcase
				if (rcounter16_eq_0)
				begin
					rstate		<= #1 sr_rec_bit;
					rcounter16	<= #1 4'b1110;
					rshift		<= #1 0;
				end
				else
					rstate <= #1 sr_rec_prepare;
				rcounter16 <= #1 rcounter16_minus_1;
			end
	sr_rec_bit :	begin
				if (rcounter16_eq_0)
					rstate <= #1 sr_end_bit;
				if (rcounter16_eq_7) // read the bit
					case (lcr[/*`UART_LC_BITS*/1:0])  // number of bits in a word
					2'b00 : rshift[4:0]  <= #1 {srx_pad_i, rshift[4:1]};
					2'b01 : rshift[5:0]  <= #1 {srx_pad_i, rshift[5:1]};
					2'b10 : rshift[6:0]  <= #1 {srx_pad_i, rshift[6:1]};
					2'b11 : rshift[7:0]  <= #1 {srx_pad_i, rshift[7:1]};
					endcase
				rcounter16 <= #1 rcounter16_minus_1;
			end
	sr_end_bit :   begin
				if (rbit_counter==3'b0) // no more bits in word
					if (lcr[`UART_LC_PE]) // choose state based on parity
						rstate <= #1 sr_rec_parity;
					else
					begin
						rstate <= #1 sr_rec_stop;
						rparity_error <= #1 1'b0;  // no parity - no error :)
					end
				else		// else we have more bits to read
				begin
					rstate <= #1 sr_rec_bit;
					rbit_counter <= #1 rbit_counter - 1'b1;
				end
				rcounter16 <= #1 4'b1110;
			end
	sr_rec_parity: begin
				if (rcounter16_eq_7)	// read the parity
				begin
					rparity <= #1 srx_pad_i;
					rstate <= #1 sr_ca_lc_parity;
				end
				rcounter16 <= #1 rcounter16_minus_1;
			end
	sr_ca_lc_parity : begin    // rcounter equals 6
				rcounter16  <= #1 rcounter16_minus_1;
				rparity_xor <= #1 ^{rshift,rparity}; // calculate parity on all incoming data
				rstate      <= #1 sr_check_parity;
			  end
	sr_check_parity: begin	  // rcounter equals 5
				case ({lcr[`UART_LC_EP],lcr[`UART_LC_SP]})
					2'b00: rparity_error <= #1  rparity_xor == 0;  // no error if parity 1
					2'b01: rparity_error <= #1 ~rparity;      // parity should sticked to 1
					2'b10: rparity_error <= #1  rparity_xor == 1;   // error if parity is odd
					2'b11: rparity_error <= #1  rparity;	  // parity should be sticked to 0
				endcase
				rcounter16 <= #1 rcounter16_minus_1;
				rstate <= #1 sr_wait1;
			  end
	sr_wait1 :	if (rcounter16_eq_0)
			begin
				rstate <= #1 sr_rec_stop;
				rcounter16 <= #1 4'b1110;
			end
			else
				rcounter16 <= #1 rcounter16_minus_1;
	sr_rec_stop :	begin
				if (rcounter16_eq_7)	// read the parity
				begin
					rframing_error <= #1 !srx_pad_i; // no framing error if input is 1 (stop bit)
					rstate <= #1 sr_push;
				end
				rcounter16 <= #1 rcounter16_minus_1;
			end
	sr_push :	begin
///////////////////////////////////////
//				$display($time, ": received: %b", rf_data_in);
        if(srx_pad_i | break_error)
          begin
            if(break_error)
        		  rf_data_in 	<= #1 {8'b0, 3'b100}; // break input (empty character) to receiver FIFO
            else
        			rf_data_in  <= #1 {rshift, 1'b0, rparity_error, rframing_error};
      		  rf_push 		  <= #1 1'b1;
    				rstate        <= #1 sr_idle;
          end
        else if(~rframing_error)  // There's always a framing before break_error -> wait for break or srx_pad_i
          begin
       			rf_data_in  <= #1 {rshift, 1'b0, rparity_error, rframing_error};
      		  rf_push 		  <= #1 1'b1;
      			rcounter16 	  <= #1 4'b1110;
    				rstate 		  <= #1 sr_rec_start;
          end
                      
			end
	default : rstate <= #1 sr_idle;
	endcase
  end  // if (enable)
end // always of receiver

always @ (posedge clk or posedge wb_rst_i)
begin
  if(wb_rst_i)
    rf_push_q <= 0;
  else
    rf_push_q <= #1 rf_push;
end

assign rf_push_pulse = rf_push & ~rf_push_q;

  
//
// Break condition detection.
// Works in conjuction with the receiver state machine

reg 	[9:0]	toc_value; // value to be set to timeout counter

always @(lcr)
	case (lcr[3:0])
		4'b0000										: toc_value = 447; // 7 bits
		4'b0100										: toc_value = 479; // 7.5 bits
		4'b0001,	4'b1000							: toc_value = 511; // 8 bits
		4'b1100										: toc_value = 543; // 8.5 bits
		4'b0010, 4'b0101, 4'b1001				: toc_value = 575; // 9 bits
		4'b0011, 4'b0110, 4'b1010, 4'b1101	: toc_value = 639; // 10 bits
		4'b0111, 4'b1011, 4'b1110				: toc_value = 703; // 11 bits
		4'b1111										: toc_value = 767; // 12 bits
	endcase // case(lcr[3:0])

wire [7:0] 	brc_value; // value to be set to break counter
assign 		brc_value = toc_value[9:2]; // the same as timeout but 1 insead of 4 character times

always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		counter_b <= #1 8'd159;
	else
	if (srx_pad_i)
		counter_b <= #1 brc_value; // character time length - 1
	else
	if(enable & counter_b != 8'b0)            // only work on enable times  break not reached.
		counter_b <= #1 counter_b - 1;  // decrement break counter
end // always of break condition detection

///
/// Timeout condition detection
reg	[9:0]	counter_t;	// counts the timeout condition clocks

always @(posedge clk or posedge wb_rst_i)
begin
	if (wb_rst_i)
		counter_t <= #1 10'd639; // 10 bits for the default 8N1
	else
		if(rf_push_pulse || rf_pop || rf_count == 0) // counter is reset when RX FIFO is empty, accessed or above trigger level
			counter_t <= #1 toc_value;
		else
		if (enable && counter_t != 10'b0)  // we don't want to underflow
			counter_t <= #1 counter_t - 1;		
end
	
endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_transmitter.v                                          ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UART core transmitter logic                                 ////
////                                                              ////
////  Known problems (limits):                                    ////
////  None known                                                  ////
////                                                              ////
////  To Do:                                                      ////
////  Thourough testing.                                          ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   2001/05/17                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: uart_transmitter.v,v $
// Revision 1.19  2002/07/29 21:16:18  gorban
// The uart_defines.v file is included again in sources.
//
// Revision 1.18  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UART_HAS_BAUDRATE_OUTPUT to use.
//
// Revision 1.16  2002/01/08 11:29:40  mohor
// tf_pop was too wide. Now it is only 1 clk cycle width.
//
// Revision 1.15  2001/12/17 14:46:48  mohor
// overrun signal was moved to separate block because many sequential lsr
// reads were preventing data from being written to rx fifo.
// underrun signal was not used and was removed from the project.
//
// Revision 1.14  2001/12/03 21:44:29  gorban
// Updated specification documentation.
// Added full 32-bit data bus interface, now as default.
// Address is 5-bit wide in 32-bit data bus mode.
// Added wb_sel_i input to the core. It's used in the 32-bit mode.
// Added debug interface with two 32-bit read-only registers in 32-bit mode.
// Bits 5 and 6 of LSR are now only cleared on TX FIFO write.
// My small test bench is modified to work with 32-bit mode.
//
// Revision 1.13  2001/11/08 14:54:23  mohor
// Comments in Slovene language deleted, few small fixes for better work of
// old tools. IRQs need to be fix.
//
// Revision 1.12  2001/11/07 17:51:52  gorban
// Heavily rewritten interrupt and LSR subsystems.
// Many bugs hopefully squashed.
//
// Revision 1.11  2001/10/29 17:00:46  gorban
// fixed parity sending and tx_fifo resets over- and underrun
//
// Revision 1.10  2001/10/20 09:58:40  gorban
// Small synopsis fixes
//
// Revision 1.9  2001/08/24 21:01:12  mohor
// Things connected to parity changed.
// Clock devider changed.
//
// Revision 1.8  2001/08/23 16:05:05  mohor
// Stop bit bug fixed.
// Parity bug fixed.
// WISHBONE read cycle bug fixed,
// OE indicator (Overrun Error) bug fixed.
// PE indicator (Parity Error) bug fixed.
// Register read bug fixed.
//
// Revision 1.6  2001/06/23 11:21:48  gorban
// DL made 16-bit long. Fixed transmission/reception bugs.
//
// Revision 1.5  2001/06/02 14:28:14  gorban
// Fixed receiver and transmitter. Major bug fixed.
//
// Revision 1.4  2001/05/31 20:08:01  gorban
// FIFO changes and other corrections.
//
// Revision 1.3  2001/05/27 17:37:49  gorban
// Fixed many bugs. Updated spec. Changed FIFO files structure. See CHANGES.txt file.
//
// Revision 1.2  2001/05/21 19:12:02  gorban
// Corrected some Linter messages.
//
// Revision 1.1  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:12+02  jacob
// Initial revision
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "uart_defines.v"

module uart_transmitter (clk, wb_rst_i, lcr, tf_push, wb_dat_i, enable,	stx_pad_o, tstate, tf_count, tx_reset, lsr_mask);

input 										clk;
input 										wb_rst_i;
input [7:0] 								lcr;
input 										tf_push;
input [7:0] 								wb_dat_i;
input 										enable;
input 										tx_reset;
input 										lsr_mask; //reset of fifo
output 										stx_pad_o;
output [2:0] 								tstate;
output [`UART_FIFO_COUNTER_W-1:0] 	tf_count;

reg [2:0] 									tstate;
reg [4:0] 									counter;
reg [2:0] 									bit_counter;   // counts the bits to be sent
reg [6:0] 									shift_out;	// output shift register
reg 											stx_o_tmp;
reg 											parity_xor;  // parity of the word
reg 											tf_pop;
reg 											bit_out;

// TX FIFO instance
//
// Transmitter FIFO signals
wire [`UART_FIFO_WIDTH-1:0] 			tf_data_in;
wire [`UART_FIFO_WIDTH-1:0] 			tf_data_out;
wire 											tf_push;
wire 											tf_overrun;
wire [`UART_FIFO_COUNTER_W-1:0] 		tf_count;

assign 										tf_data_in = wb_dat_i;

uart_tfifo fifo_tx(	// error bit signal is not used in transmitter FIFO
	.clk(		clk		), 
	.wb_rst_i(	wb_rst_i	),
	.data_in(	tf_data_in	),
	.data_out(	tf_data_out	),
	.push(		tf_push		),
	.pop(		tf_pop		),
	.overrun(	tf_overrun	),
	.count(		tf_count	),
	.fifo_reset(	tx_reset	),
	.reset_status(lsr_mask)
);

`ifdef UART_LOG_TX
   integer file_handler;

initial
  begin
     file_handler = $fopen("uart_tx.txt");
  end
  
always @(negedge tf_push)
  begin
   $fwrite(file_handler, "%s", tf_data_out);
   $display("UART: %s", tf_data_out);
  end
`endif   
   
// TRANSMITTER FINAL STATE MACHINE
   
parameter s_idle        = 3'd0;
parameter s_send_start  = 3'd1;
parameter s_send_byte   = 3'd2;
parameter s_send_parity = 3'd3;
parameter s_send_stop   = 3'd4;
parameter s_pop_byte    = 3'd5;

always @(posedge clk or posedge wb_rst_i)
begin
  if (wb_rst_i)
  begin
	tstate       <= #1 s_idle;
	stx_o_tmp       <= #1 1'b1;
	counter   <= #1 5'b0;
	shift_out   <= #1 7'b0;
	bit_out     <= #1 1'b0;
	parity_xor  <= #1 1'b0;
	tf_pop      <= #1 1'b0;
	bit_counter <= #1 3'b0;
  end
  else
  if (enable)
  begin
	case (tstate)
	s_idle	 :	if (~|tf_count) // if tf_count==0
			begin
				tstate <= #1 s_idle;
				stx_o_tmp <= #1 1'b1;
			end
			else
			begin
				tf_pop <= #1 1'b0;
				stx_o_tmp  <= #1 1'b1;
				tstate  <= #1 s_pop_byte;
			end
	s_pop_byte :	begin
				tf_pop <= #1 1'b1;
				case (lcr[/*`UART_LC_BITS*/1:0])  // number of bits in a word
				2'b00 : begin
					bit_counter <= #1 3'b100;
					parity_xor  <= #1 ^tf_data_out[4:0];
				     end
				2'b01 : begin
					bit_counter <= #1 3'b101;
					parity_xor  <= #1 ^tf_data_out[5:0];
				     end
				2'b10 : begin
					bit_counter <= #1 3'b110;
					parity_xor  <= #1 ^tf_data_out[6:0];
				     end
				2'b11 : begin
					bit_counter <= #1 3'b111;
					parity_xor  <= #1 ^tf_data_out[7:0];
				     end
				endcase
				{shift_out[6:0], bit_out} <= #1 tf_data_out;
				tstate <= #1 s_send_start;
			end
	s_send_start :	begin
				tf_pop <= #1 1'b0;
				if (~|counter)
					counter <= #1 5'b01111;
				else
				if (counter == 5'b00001)
				begin
					counter <= #1 0;
					tstate <= #1 s_send_byte;
				end
				else
					counter <= #1 counter - 1'b1;
				stx_o_tmp <= #1 1'b0;
			end
	s_send_byte :	begin
				if (~|counter)
					counter <= #1 5'b01111;
				else
				if (counter == 5'b00001)
				begin
					if (bit_counter > 3'b0)
					begin
						bit_counter <= #1 bit_counter - 1'b1;
						{shift_out[5:0],bit_out  } <= #1 {shift_out[6:1], shift_out[0]};
						tstate <= #1 s_send_byte;
					end
					else   // end of byte
					if (~lcr[`UART_LC_PE])
					begin
						tstate <= #1 s_send_stop;
					end
					else
					begin
						case ({lcr[`UART_LC_EP],lcr[`UART_LC_SP]})
						2'b00:	bit_out <= #1 ~parity_xor;
						2'b01:	bit_out <= #1 1'b1;
						2'b10:	bit_out <= #1 parity_xor;
						2'b11:	bit_out <= #1 1'b0;
						endcase
						tstate <= #1 s_send_parity;
					end
					counter <= #1 0;
				end
				else
					counter <= #1 counter - 1'b1;
				stx_o_tmp <= #1 bit_out; // set output pin
			end
	s_send_parity :	begin
				if (~|counter)
					counter <= #1 5'b01111;
				else
				if (counter == 5'b00001)
				begin
					counter <= #1 4'b0;
					tstate <= #1 s_send_stop;
				end
				else
					counter <= #1 counter - 1'b1;
				stx_o_tmp <= #1 bit_out;
			end
	s_send_stop :  begin
				if (~|counter)
				  begin
						casex ({lcr[`UART_LC_SB],lcr[`UART_LC_BITS]})
  						3'b0xx:	  counter <= #1 5'b01101;     // 1 stop bit ok igor
  						3'b100:	  counter <= #1 5'b10101;     // 1.5 stop bit
  						default:	  counter <= #1 5'b11101;     // 2 stop bits
						endcase
					end
				else
				if (counter == 5'b00001)
				begin
					counter <= #1 0;
					tstate <= #1 s_idle;
				end
				else
					counter <= #1 counter - 1'b1;
				stx_o_tmp <= #1 1'b1;
			end

		default : // should never get here
			tstate <= #1 s_idle;
	endcase
  end // end if enable
  else
    tf_pop <= #1 1'b0;  // tf_pop must be 1 cycle width
end // transmitter logic

assign stx_pad_o = lcr[`UART_LC_BC] ? 1'b0 : stx_o_tmp;    // Break condition
	
endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_debug_if.v                                             ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UART core debug interface.                                  ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////                                                              ////
////  Created:        2001/12/02                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: uart_debug_if.v,v $
// Revision 1.5  2002/07/29 21:16:18  gorban
// The uart_defines.v file is included again in sources.
//
// Revision 1.4  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UART_HAS_BAUDRATE_OUTPUT to use.
//
// Revision 1.3  2001/12/19 08:40:03  mohor
// Warnings fixed (unused signals removed).
//
// Revision 1.2  2001/12/12 22:17:30  gorban
// some synthesis bugs fixed
//
// Revision 1.1  2001/12/04 21:14:16  gorban
// committed the debug interface file
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "uart_defines.v"

module uart_debug_if (/*AUTOARG*/
// Outputs
wb_dat32_o, 
// Inputs
wb_adr_i, ier, iir, fcr, mcr, lcr, msr, 
lsr, rf_count, tf_count, tstate, rstate
) ;

input [`UART_ADDR_WIDTH-1:0] 		wb_adr_i;
output [31:0] 							wb_dat32_o;
input [3:0] 							ier;
input [3:0] 							iir;
input [1:0] 							fcr;  /// bits 7 and 6 of fcr. Other bits are ignored
input [4:0] 							mcr;
input [7:0] 							lcr;
input [7:0] 							msr;
input [7:0] 							lsr;
input [`UART_FIFO_COUNTER_W-1:0] rf_count;
input [`UART_FIFO_COUNTER_W-1:0] tf_count;
input [2:0] 							tstate;
input [3:0] 							rstate;


wire [`UART_ADDR_WIDTH-1:0] 		wb_adr_i;
reg [31:0] 								wb_dat32_o;

always @(/*AUTOSENSE*/fcr or ier or iir or lcr or lsr or mcr or msr
			or rf_count or rstate or tf_count or tstate or wb_adr_i)
	case (wb_adr_i)
		                      // 8 + 8 + 4 + 4 + 8
		5'b01000: wb_dat32_o = {msr,lcr,iir,ier,lsr};
		               // 5 + 2 + 5 + 4 + 5 + 3
		5'b01100: wb_dat32_o = {8'b0, fcr,mcr, rf_count, rstate, tf_count, tstate};
		default: wb_dat32_o = 0;
	endcase // case(wb_adr_i)

endmodule // uart_debug_if

//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_wb.v                                                   ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UART core WISHBONE interface.                               ////
////                                                              ////
////  Known problems (limits):                                    ////
////  Inserts one wait state on all transfers.                    ////
////  Note affected signals and the way they are affected.        ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing.                                                    ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   2001/05/17                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: uart_wb.v,v $
// Revision 1.17  2004/05/21 12:35:15  tadejm
// Added 2 LSB address generation dependent on select lines and LITLE/BIG endian when UART is in 32-bit mode.
//
// Revision 1.16  2002/07/29 21:16:18  gorban
// The uart_defines.v file is included again in sources.
//
// Revision 1.15  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UART_HAS_BAUDRATE_OUTPUT to use.
//
// Revision 1.12  2001/12/19 08:03:34  mohor
// Warnings cleared.
//
// Revision 1.11  2001/12/06 14:51:04  gorban
// Bug in LSR[0] is fixed.
// All WISHBONE signals are now sampled, so another wait-state is introduced on all transfers.
//
// Revision 1.10  2001/12/03 21:44:29  gorban
// Updated specification documentation.
// Added full 32-bit data bus interface, now as default.
// Address is 5-bit wide in 32-bit data bus mode.
// Added wb_sel_i input to the core. It's used in the 32-bit mode.
// Added debug interface with two 32-bit read-only registers in 32-bit mode.
// Bits 5 and 6 of LSR are now only cleared on TX FIFO write.
// My small test bench is modified to work with 32-bit mode.
//
// Revision 1.9  2001/10/20 09:58:40  gorban
// Small synopsis fixes
//
// Revision 1.8  2001/08/24 21:01:12  mohor
// Things connected to parity changed.
// Clock devider changed.
//
// Revision 1.7  2001/08/23 16:05:05  mohor
// Stop bit bug fixed.
// Parity bug fixed.
// WISHBONE read cycle bug fixed,
// OE indicator (Overrun Error) bug fixed.
// PE indicator (Parity Error) bug fixed.
// Register read bug fixed.
//
// Revision 1.4  2001/05/31 20:08:01  gorban
// FIFO changes and other corrections.
//
// Revision 1.3  2001/05/21 19:12:01  gorban
// Corrected some Linter messages.
//
// Revision 1.2  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:13+02  jacob
// Initial revision
//
//

// UART core WISHBONE interface 
//
// Author: Jacob Gorban   (jacob.gorban@flextronicssemi.com)
// Company: Flextronics Semiconductor
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "uart_defines.v"
 
module uart_wb (clk, wb_rst_i, 
	wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_adr_i,
	wb_adr_int, wb_dat_i, wb_dat_o, wb_dat8_i, wb_dat8_o, wb_dat32_o, wb_sel_i,
	we_o, re_o // Write and read enable output for the core
);

input 		  clk;

// WISHBONE interface	
input 		  wb_rst_i;
input 		  wb_we_i;
input 		  wb_stb_i;
input 		  wb_cyc_i;
input [3:0]   wb_sel_i;
input [`UART_ADDR_WIDTH-1:0] 	wb_adr_i; //WISHBONE address line

`ifdef DATA_BUS_WIDTH_8
input [7:0]  wb_dat_i; //input WISHBONE bus 
output [7:0] wb_dat_o;
reg [7:0] 	 wb_dat_o;
wire [7:0] 	 wb_dat_i;
reg [7:0] 	 wb_dat_is;
`else // for 32 data bus mode
input [31:0]  wb_dat_i; //input WISHBONE bus 
output [31:0] wb_dat_o;
reg [31:0] 	  wb_dat_o;
wire [31:0]   wb_dat_i;
reg [31:0] 	  wb_dat_is;
`endif // !`ifdef DATA_BUS_WIDTH_8

output [`UART_ADDR_WIDTH-1:0]	wb_adr_int; // internal signal for address bus
input [7:0]   wb_dat8_o; // internal 8 bit output to be put into wb_dat_o
output [7:0]  wb_dat8_i;
input [31:0]  wb_dat32_o; // 32 bit data output (for debug interface)
output 		  wb_ack_o;
output 		  we_o;
output 		  re_o;

wire 			  we_o;
reg 			  wb_ack_o;
reg [7:0] 	  wb_dat8_i;
wire [7:0] 	  wb_dat8_o;
wire [`UART_ADDR_WIDTH-1:0]	wb_adr_int; // internal signal for address bus
reg [`UART_ADDR_WIDTH-1:0]	wb_adr_is;
reg 								wb_we_is;
reg 								wb_cyc_is;
reg 								wb_stb_is;
reg [3:0] 						wb_sel_is;
wire [3:0]   wb_sel_i;
reg 			 wre ;// timing control signal for write or read enable

// wb_ack_o FSM
reg [1:0] 	 wbstate;
always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) begin
		wb_ack_o <= #1 1'b0;
		wbstate <= #1 0;
		wre <= #1 1'b1;
	end else
		case (wbstate)
			0: begin
				if (wb_stb_is & wb_cyc_is) begin
					wre <= #1 0;
					wbstate <= #1 1;
					wb_ack_o <= #1 1;
				end else begin
					wre <= #1 1;
					wb_ack_o <= #1 0;
				end
			end
			1: begin
			   wb_ack_o <= #1 0;
				wbstate <= #1 2;
				wre <= #1 0;
			end
			2,3: begin
				wb_ack_o <= #1 0;
				wbstate <= #1 0;
				wre <= #1 0;
			end
		endcase

assign we_o =  wb_we_is & wb_stb_is & wb_cyc_is & wre ; //WE for registers	
assign re_o = ~wb_we_is & wb_stb_is & wb_cyc_is & wre ; //RE for registers	

// Sample input signals
always  @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i) begin
		wb_adr_is <= #1 0;
		wb_we_is <= #1 0;
		wb_cyc_is <= #1 0;
		wb_stb_is <= #1 0;
		wb_dat_is <= #1 0;
		wb_sel_is <= #1 0;
	end else begin
		wb_adr_is <= #1 wb_adr_i;
		wb_we_is <= #1 wb_we_i;
		wb_cyc_is <= #1 wb_cyc_i;
		wb_stb_is <= #1 wb_stb_i;
		wb_dat_is <= #1 wb_dat_i;
		wb_sel_is <= #1 wb_sel_i;
	end

`ifdef DATA_BUS_WIDTH_8 // 8-bit data bus
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		wb_dat_o <= #1 0;
	else
		wb_dat_o <= #1 wb_dat8_o;

always @(wb_dat_is)
	wb_dat8_i = wb_dat_is;

assign wb_adr_int = wb_adr_is;

`else // 32-bit bus
// put output to the correct byte in 32 bits using select line
always @(posedge clk or posedge wb_rst_i)
	if (wb_rst_i)
		wb_dat_o <= #1 0;
	else if (re_o)
		case (wb_sel_is)
			4'b0001: wb_dat_o <= #1 {24'b0, wb_dat8_o};
			4'b0010: wb_dat_o <= #1 {16'b0, wb_dat8_o, 8'b0};
			4'b0100: wb_dat_o <= #1 {8'b0, wb_dat8_o, 16'b0};
			4'b1000: wb_dat_o <= #1 {wb_dat8_o, 24'b0};
			4'b1111: wb_dat_o <= #1 wb_dat32_o; // debug interface output
 			default: wb_dat_o <= #1 0;
		endcase // case(wb_sel_i)

reg [1:0] wb_adr_int_lsb;

always @(wb_sel_is or wb_dat_is)
begin
	case (wb_sel_is)
		4'b0001 : wb_dat8_i = wb_dat_is[7:0];
		4'b0010 : wb_dat8_i = wb_dat_is[15:8];
		4'b0100 : wb_dat8_i = wb_dat_is[23:16];
		4'b1000 : wb_dat8_i = wb_dat_is[31:24];
		default : wb_dat8_i = wb_dat_is[7:0];
	endcase // case(wb_sel_i)

  `ifdef LITLE_ENDIAN
	case (wb_sel_is)
		4'b0001 : wb_adr_int_lsb = 2'h0;
		4'b0010 : wb_adr_int_lsb = 2'h1;
		4'b0100 : wb_adr_int_lsb = 2'h2;
		4'b1000 : wb_adr_int_lsb = 2'h3;
		default : wb_adr_int_lsb = 2'h0;
	endcase // case(wb_sel_i)
  `else
	case (wb_sel_is)
		4'b0001 : wb_adr_int_lsb = 2'h3;
		4'b0010 : wb_adr_int_lsb = 2'h2;
		4'b0100 : wb_adr_int_lsb = 2'h1;
		4'b1000 : wb_adr_int_lsb = 2'h0;
		default : wb_adr_int_lsb = 2'h0;
	endcase // case(wb_sel_i)
  `endif
end

assign wb_adr_int = {wb_adr_is[`UART_ADDR_WIDTH-1:2], wb_adr_int_lsb};

`endif // !`ifdef DATA_BUS_WIDTH_8

endmodule










//////////////////////////////////////////////////////////////////////
////                                                              ////
////  uart_top.v                                                  ////
////                                                              ////
////                                                              ////
////  This file is part of the "UART 16550 compatible" project    ////
////  http://www.opencores.org/cores/uart16550/                   ////
////                                                              ////
////  Documentation related to this project:                      ////
////  - http://www.opencores.org/cores/uart16550/                 ////
////                                                              ////
////  Projects compatibility:                                     ////
////  - WISHBONE                                                  ////
////  RS232 Protocol                                              ////
////  16550D uart (mostly supported)                              ////
////                                                              ////
////  Overview (main Features):                                   ////
////  UART core top level.                                        ////
////                                                              ////
////  Known problems (limits):                                    ////
////  Note that transmitter and receiver instances are inside     ////
////  the uart_regs.v file.                                       ////
////                                                              ////
////  To Do:                                                      ////
////  Nothing so far.                                             ////
////                                                              ////
////  Author(s):                                                  ////
////      - gorban@opencores.org                                  ////
////      - Jacob Gorban                                          ////
////      - Igor Mohor (igorm@opencores.org)                      ////
////                                                              ////
////  Created:        2001/05/12                                  ////
////  Last Updated:   2001/05/17                                  ////
////                  (See log for the revision history)          ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000, 2001 Authors                             ////
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
// $Log: uart_top.v,v $
// Revision 1.19  2002/07/29 21:16:18  gorban
// The uart_defines.v file is included again in sources.
//
// Revision 1.18  2002/07/22 23:02:23  gorban
// Bug Fixes:
//  * Possible loss of sync and bad reception of stop bit on slow baud rates fixed.
//   Problem reported by Kenny.Tung.
//  * Bad (or lack of ) loopback handling fixed. Reported by Cherry Withers.
//
// Improvements:
//  * Made FIFO's as general inferrable memory where possible.
//  So on FPGA they should be inferred as RAM (Distributed RAM on Xilinx).
//  This saves about 1/3 of the Slice count and reduces P&R and synthesis times.
//
//  * Added optional baudrate output (baud_o).
//  This is identical to BAUDOUT* signal on 16550 chip.
//  It outputs 16xbit_clock_rate - the divided clock.
//  It's disabled by default. Define UART_HAS_BAUDRATE_OUTPUT to use.
//
// Revision 1.17  2001/12/19 08:40:03  mohor
// Warnings fixed (unused signals removed).
//
// Revision 1.16  2001/12/06 14:51:04  gorban
// Bug in LSR[0] is fixed.
// All WISHBONE signals are now sampled, so another wait-state is introduced on all transfers.
//
// Revision 1.15  2001/12/03 21:44:29  gorban
// Updated specification documentation.
// Added full 32-bit data bus interface, now as default.
// Address is 5-bit wide in 32-bit data bus mode.
// Added wb_sel_i input to the core. It's used in the 32-bit mode.
// Added debug interface with two 32-bit read-only registers in 32-bit mode.
// Bits 5 and 6 of LSR are now only cleared on TX FIFO write.
// My small test bench is modified to work with 32-bit mode.
//
// Revision 1.14  2001/11/07 17:51:52  gorban
// Heavily rewritten interrupt and LSR subsystems.
// Many bugs hopefully squashed.
//
// Revision 1.13  2001/10/20 09:58:40  gorban
// Small synopsis fixes
//
// Revision 1.12  2001/08/25 15:46:19  gorban
// Modified port names again
//
// Revision 1.11  2001/08/24 21:01:12  mohor
// Things connected to parity changed.
// Clock devider changed.
//
// Revision 1.10  2001/08/23 16:05:05  mohor
// Stop bit bug fixed.
// Parity bug fixed.
// WISHBONE read cycle bug fixed,
// OE indicator (Overrun Error) bug fixed.
// PE indicator (Parity Error) bug fixed.
// Register read bug fixed.
//
// Revision 1.4  2001/05/31 20:08:01  gorban
// FIFO changes and other corrections.
//
// Revision 1.3  2001/05/21 19:12:02  gorban
// Corrected some Linter messages.
//
// Revision 1.2  2001/05/17 18:34:18  gorban
// First 'stable' release. Should be sythesizable now. Also added new header.
//
// Revision 1.0  2001-05-17 21:27:12+02  jacob
// Initial revision
//
//
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`include "uart_defines.v"

module uart_top	(
	wb_clk_i, 
	
	// Wishbone signals
	wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
	int_o, // interrupt request

	// UART	signals
	// serial input/output
	stx_pad_o, srx_pad_i,

	// modem signals
	rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
`ifdef UART_HAS_BAUDRATE_OUTPUT
	, baud_o
`endif
	);

parameter 							 uart_data_width = `UART_DATA_WIDTH;
parameter 							 uart_addr_width = `UART_ADDR_WIDTH;

input 								 wb_clk_i;

// WISHBONE interface
input 								 wb_rst_i;
input [uart_addr_width-1:0] 	 wb_adr_i;
input [uart_data_width-1:0] 	 wb_dat_i;
output [uart_data_width-1:0] 	 wb_dat_o;
input 								 wb_we_i;
input 								 wb_stb_i;
input 								 wb_cyc_i;
input [3:0]							 wb_sel_i;
output 								 wb_ack_o;
output 								 int_o;

// UART	signals
input 								 srx_pad_i;
output 								 stx_pad_o;
output 								 rts_pad_o;
input 								 cts_pad_i;
output 								 dtr_pad_o;
input 								 dsr_pad_i;
input 								 ri_pad_i;
input 								 dcd_pad_i;

// optional baudrate output
`ifdef UART_HAS_BAUDRATE_OUTPUT
output	baud_o;
`endif


wire 									 stx_pad_o;
wire 									 rts_pad_o;
wire 									 dtr_pad_o;

wire [uart_addr_width-1:0] 	 wb_adr_i;
wire [uart_data_width-1:0] 	 wb_dat_i;
wire [uart_data_width-1:0] 	 wb_dat_o;

wire [7:0] 							 wb_dat8_i; // 8-bit internal data input
wire [7:0] 							 wb_dat8_o; // 8-bit internal data output
wire [31:0] 						 wb_dat32_o; // debug interface 32-bit output
wire [3:0] 							 wb_sel_i;  // WISHBONE select signal
wire [uart_addr_width-1:0] 	 wb_adr_int;
wire 									 we_o;	// Write enable for registers
wire		          	     re_o;	// Read enable for registers
//
// MODULE INSTANCES
//

`ifdef DATA_BUS_WIDTH_8
`else
// debug interface wires
wire	[3:0] ier;
wire	[3:0] iir;
wire	[1:0] fcr;
wire	[4:0] mcr;
wire	[7:0] lcr;
wire	[7:0] msr;
wire	[7:0] lsr;
wire	[`UART_FIFO_COUNTER_W-1:0] rf_count;
wire	[`UART_FIFO_COUNTER_W-1:0] tf_count;
wire	[2:0] tstate;
wire	[3:0] rstate; 
`endif

`ifdef DATA_BUS_WIDTH_8
////  WISHBONE interface module
uart_wb		wb_interface(
		.clk(		wb_clk_i		),
		.wb_rst_i(	wb_rst_i	),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o),
	.wb_dat8_i(wb_dat8_i),
	.wb_dat8_o(wb_dat8_o),
	 .wb_dat32_o(32'b0),								 
	 .wb_sel_i(4'b0),
		.wb_we_i(	wb_we_i		),
		.wb_stb_i(	wb_stb_i	),
		.wb_cyc_i(	wb_cyc_i	),
		.wb_ack_o(	wb_ack_o	),
	.wb_adr_i(wb_adr_i),
	.wb_adr_int(wb_adr_int),
		.we_o(		we_o		),
		.re_o(re_o)
		);
`else
uart_wb		wb_interface(
		.clk(		wb_clk_i		),
		.wb_rst_i(	wb_rst_i	),
	.wb_dat_i(wb_dat_i),
	.wb_dat_o(wb_dat_o),
	.wb_dat8_i(wb_dat8_i),
	.wb_dat8_o(wb_dat8_o),
	 .wb_sel_i(wb_sel_i),
	 .wb_dat32_o(wb_dat32_o),								 
		.wb_we_i(	wb_we_i		),
		.wb_stb_i(	wb_stb_i	),
		.wb_cyc_i(	wb_cyc_i	),
		.wb_ack_o(	wb_ack_o	),
	.wb_adr_i(wb_adr_i),
	.wb_adr_int(wb_adr_int),
		.we_o(		we_o		),
		.re_o(re_o)
		);
`endif

// Registers
uart_regs	regs(
	.clk(		wb_clk_i		),
	.wb_rst_i(	wb_rst_i	),
	.wb_addr_i(	wb_adr_int	),
	.wb_dat_i(	wb_dat8_i	),
	.wb_dat_o(	wb_dat8_o	),
	.wb_we_i(	we_o		),
   .wb_re_i(re_o),
	.modem_inputs(	{cts_pad_i, dsr_pad_i,
	ri_pad_i,  dcd_pad_i}	),
	.stx_pad_o(		stx_pad_o		),
	.srx_pad_i(		srx_pad_i		),
`ifdef DATA_BUS_WIDTH_8
`else
// debug interface signals	enabled
.ier(ier), 
.iir(iir), 
.fcr(fcr), 
.mcr(mcr), 
.lcr(lcr), 
.msr(msr), 
.lsr(lsr), 
.rf_count(rf_count),
.tf_count(tf_count),
.tstate(tstate),
.rstate(rstate),
`endif					  
	.rts_pad_o(		rts_pad_o		),
	.dtr_pad_o(		dtr_pad_o		),
	.int_o(		int_o		)
`ifdef UART_HAS_BAUDRATE_OUTPUT
	, .baud_o(baud_o)
`endif

);

`ifdef DATA_BUS_WIDTH_8
`else
uart_debug_if dbg(/*AUTOINST*/
						// Outputs
						.wb_dat32_o				 (wb_dat32_o[31:0]),
						// Inputs
						.wb_adr_i				 (wb_adr_int[`UART_ADDR_WIDTH-1:0]),
						.ier						 (ier[3:0]),
						.iir						 (iir[3:0]),
						.fcr						 (fcr[1:0]),
						.mcr						 (mcr[4:0]),
						.lcr						 (lcr[7:0]),
						.msr						 (msr[7:0]),
						.lsr						 (lsr[7:0]),
						.rf_count				 (rf_count[`UART_FIFO_COUNTER_W-1:0]),
						.tf_count				 (tf_count[`UART_FIFO_COUNTER_W-1:0]),
						.tstate					 (tstate[2:0]),
						.rstate					 (rstate[3:0]));
`endif 

initial
begin
	`ifdef DATA_BUS_WIDTH_8
		$display("(%m) UART INFO: Data bus width is 8. No Debug interface.\n");
	`else
		$display("(%m) UART INFO: Data bus width is 32. Debug Interface present.\n");
	`endif
	`ifdef UART_HAS_BAUDRATE_OUTPUT
		$display("(%m) UART INFO: Has baudrate output\n");
	`else
		$display("(%m) UART INFO: Doesn't have baudrate output\n");
	`endif
end

endmodule


