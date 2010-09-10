/////////////////////////////////////////////////////////////////////
////                                                             ////
////  OpenCores                    MC68HC11E based SPI interface ////
////                                                             ////
////  Author: Richard Herveille                                  ////
////          richard@asics.ws                                   ////
////          www.asics.ws                                       ////
////                                                             ////
/////////////////////////////////////////////////////////////////////
////                                                             ////
//// Copyright (C) 2002 Richard Herveille                        ////
////                    richard@asics.ws                         ////
////                                                             ////
//// This source file may be used and distributed without        ////
//// restriction provided that this copyright statement is not   ////
//// removed from the file and that any derivative work contains ////
//// the original copyright notice and the associated disclaimer.////
////                                                             ////
////     THIS SOFTWARE IS PROVIDED ``AS IS'' AND WITHOUT ANY     ////
//// EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   ////
//// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS   ////
//// FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL THE AUTHOR      ////
//// OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,         ////
//// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES    ////
//// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE   ////
//// GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR        ////
//// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF  ////
//// LIABILITY, WHETHER IN  CONTRACT, STRICT LIABILITY, OR TORT  ////
//// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT  ////
//// OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE         ////
//// POSSIBILITY OF SUCH DAMAGE.                                 ////
////                                                             ////
/////////////////////////////////////////////////////////////////////

//  CVS Log
//
//  $Id: simple_spi_top.v,v 1.5 2004-02-28 15:59:50 rherveille Exp $
//
//  $Date: 2004-02-28 15:59:50 $
//  $Revision: 1.5 $
//  $Author: rherveille $
//  $Locker:  $
//  $State: Exp $
//
// Change History:
//               $Log: not supported by cvs2svn $
//               Revision 1.4  2003/08/01 11:41:54  rherveille
//               Fixed some timing bugs.
//
//               Revision 1.3  2003/01/09 16:47:59  rherveille
//               Updated clkcnt size and decoding due to new SPR bit assignments.
//
//               Revision 1.2  2003/01/07 13:29:52  rherveille
//               Changed SPR bits coding.
//
//               Revision 1.1.1.1  2002/12/22 16:07:15  rherveille
//               Initial release
//
//



//
// Motorola MC68HC11E based SPI interface
//
// Currently only MASTER mode is supported
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

`define SIMPLE_SPI_RST_SENS rst_i

//module simple_spi_top(
module simple_spi ( // renamed by Julius
		    // 8bit WISHBONE bus slave interface
		    clk_i,         // clock
		    rst_i,         // reset (asynchronous active low)
		    cyc_i,         // cycle
		    stb_i,         // strobe
		    adr_i,         // address
		    we_i,          // write enable
		    dat_i,         // data input
		    dat_o,         // data output
		    ack_o,         // normal bus termination
		    inta_o,        // interrupt output
		    
		    
		    sck_o,         // serial clock output
		    ss_o, //slave select
		    mosi_o,        // MasterOut SlaveIN
		    miso_i         // MasterIn SlaveOut		    
		    );
   
   parameter slave_select_width = 1;
   
   input  wire 	    clk_i;         // clock
   input  wire 	    rst_i;         // reset (asynchronous active low)
   input  wire 	    cyc_i;         // cycle
   input  wire 	    stb_i;         // strobe
   input  wire [2:0] adr_i;         // address
   input  wire 	     we_i;          // write enable
   input  wire [7:0] dat_i;         // data input
   output reg [7:0]  dat_o;         // data output
   output reg 	     ack_o;         // normal bus termination
   output reg 	     inta_o;        // interrupt output
   
   // SPI port
   output reg 	     sck_o;         // serial clock output
   output [slave_select_width-1:0] ss_o;
   output wire 			       mosi_o;        // MasterOut SlaveIN
   input  wire 			       miso_i;         // MasterIn SlaveOut	
   

   reg [slave_select_width-1:0]        ss_r;      
		 
  //
  // Module body
  //
  reg  [7:0] spcr;       // Serial Peripheral Control Register ('HC11 naming)
  wire [7:0] spsr;       // Serial Peripheral Status register ('HC11 naming)
  reg  [7:0] sper;       // Serial Peripheral Extension register
  reg  [7:0] treg; // Transmit/Receive register

  // fifo signals
  wire [7:0] rfdout;
  reg        wfre, rfwe;
  wire       rfre, rffull, rfempty;
  wire [7:0] wfdout;
  wire       wfwe, wffull, wfempty;

  // misc signals
  wire      tirq;     // transfer interrupt (selected number of transfers done)
  wire      wfov;     // write fifo overrun (writing while fifo full)
  reg [1:0] state;    // statemachine state
  reg [2:0] bcnt;


   // Little startup init FSM and logic
   // Does 4 accesses and waits to read out the data so the module is 
   // properly reset:
   // Write 1: 0x3
   // Write 2: 0x0
   // Write 3: 0x0
   // Write 4: 0x0
   //
   // This means anysoftware that wants to read can simply start pushing stuff
   // into the fifo to kick it off
   //
   reg [3:0] 			       startup_state = 0;
   reg [3:0] 			       startup_state_r = 0;
   parameter startup_state_reset = 0; // Set to 0x10 to init to read on startup
   parameter startup_spcr = 0;
   parameter startup_slave_select = 0;
   
   wire 			       startup_rfre;
   wire 			       startup_busy;
   assign startup_busy = |startup_state_r;
   
   
   always @(posedge clk_i)
     if (rst_i)
       startup_state <= startup_state_reset;
     else if ((startup_state == startup_state_r))// Whenever state is back to 0
       startup_state <= {1'b0,startup_state[3:1]};
   
   always @(posedge clk_i)
     if (rst_i)
       startup_state_r <= startup_state_reset;
     else if (startup_rfre)
       startup_state_r <= {1'b0,startup_state_r[3:1]};
   
   wire [1:0] 			       startup_state_wdf;
   // This sets the 0x3 command, to read
   assign startup_state_wdf = {startup_state[3], startup_state[3]};

   wire 			       startup_wfwe;
   assign startup_wfwe = startup_busy & (startup_state == startup_state_r & !rst_i);
   
   
   assign startup_rfre = (startup_busy) & !rfempty & 
			 (startup_state != startup_state_r);
   
   
  //
  // Wishbone interface
  wire wb_acc = cyc_i & stb_i & !startup_busy;       // WISHBONE access
  wire wb_wr  = wb_acc & we_i;       // WISHBONE write access

  // dat_i
  always @(posedge clk_i)
    if (`SIMPLE_SPI_RST_SENS)
      begin
         spcr <=  8'h10 | startup_spcr;  // set master bit
         sper <=  8'h00;
	 ss_r <=  0;
      end
    else if (wb_wr)
      begin
        if (adr_i == 3'b000)
          spcr <=  dat_i | 8'h10; // always set master bit

        if (adr_i == 3'b011)
          sper <=  dat_i;
	 
	 if (adr_i == 3'b100)
           ss_r <=  dat_i[slave_select_width-1:0];
      end // if (wb_wr)
    else if (startup_busy)
      ss_r <= startup_slave_select;
   
   // Slave select output
   // SPI slave select is active low   
   assign ss_o = ~ss_r;

  // write fifo
  assign wfwe = wb_acc & (adr_i == 3'b010) & ack_o &  we_i;
  assign wfov = wfwe & wffull;

  // dat_o
  always @(posedge clk_i)
    case(adr_i) // synopsys full_case parallel_case
      3'b000: dat_o <=  spcr;
      3'b001: dat_o <=  spsr;
      3'b010: dat_o <=  rfdout;
      3'b011: dat_o <=  sper;
      3'b100: dat_o <=  {{(8-slave_select_width){1'b0}},ss_r};
      default:
	dat_o <= 0;      
    endcase

  // read fifo
  assign rfre = wb_acc & (adr_i == 3'b010) & ack_o & ~we_i;

  // ack_o
  always @(posedge clk_i)
    if (`SIMPLE_SPI_RST_SENS)
      ack_o <=  1'b0;
    else
      ack_o <=  wb_acc & !ack_o;

  // decode Serial Peripheral Control Register
  wire       spie = spcr[7];   // Interrupt enable bit
  wire       spe  = spcr[6];   // System Enable bit
  wire       dwom = spcr[5];   // Port D Wired-OR Mode Bit
  wire       mstr = spcr[4];   // Master Mode Select Bit
  wire       cpol = spcr[3];   // Clock Polarity Bit
  wire       cpha = spcr[2];   // Clock Phase Bit
  wire [1:0] spr  = spcr[1:0]; // Clock Rate Select Bits

  // decode Serial Peripheral Extension Register
  wire [1:0] icnt = sper[7:6]; // interrupt on transfer count
  wire [1:0] spre = sper[1:0]; // extended clock rate select

  wire [3:0] espr = {spre, spr};

  // generate status register
  wire wr_spsr = wb_wr & (adr_i == 3'b001);

  reg spif;
  always @(posedge clk_i)
    if (~spe | rst_i)
      spif <=  1'b0;
    else
      spif <=  (tirq | spif) & ~(wr_spsr & dat_i[7]);

  reg wcol;
  always @(posedge clk_i)
    if (~spe | rst_i)
      wcol <=  1'b0;
    else
      wcol <=  (wfov | wcol) & ~(wr_spsr & dat_i[6]);

  assign spsr[7]   = spif;
  assign spsr[6]   = wcol;
  assign spsr[5:4] = 2'b00;
  assign spsr[3]   = wffull;
  assign spsr[2]   = wfempty;
  assign spsr[1]   = rffull;
  assign spsr[0]   = rfempty;
  

  // generate IRQ output (inta_o)
  always @(posedge clk_i)
    inta_o <=  spif & spie;


   wire [7:0] wfifo_dat_i;
   assign wfifo_dat_i = startup_busy ? {6'd0, startup_state_wdf} : dat_i;
   
   wire       wfifo_wfwe;
   assign wfifo_wfwe =  wfwe | startup_wfwe;

   wire       rfifo_rfre = rfre | startup_rfre;
   
  //
  // hookup read/write buffer fifo
  fifo4 #(8)
  rfifo(
	.clk   ( clk_i   ),
	.rst   ( ~rst_i   ),
	.clr   ( ~spe    ),
	.din   ( treg    ),
	.we    ( rfwe    ),
	.dout  ( rfdout  ),
	.re    ( rfifo_rfre    ),
	.full  ( rffull  ),
	.empty ( rfempty )
  ),
  wfifo(
	.clk   ( clk_i   ),
	.rst   ( ~rst_i   ),
	.clr   ( ~spe    ),
	.din   ( wfifo_dat_i   ),
	.we    ( wfifo_wfwe    ),
	.dout  ( wfdout  ),
	.re    ( wfre    ),
	.full  ( wffull  ),
	.empty ( wfempty )
  );

  //
  // generate clk divider
  reg [11:0] clkcnt;
  always @(posedge clk_i)
    if(spe & (|clkcnt & |state))
      clkcnt <=  clkcnt - 11'h1;
    else
      case (espr) // synopsys full_case parallel_case
        4'b0000: clkcnt <=  12'h0;   // 2   -- original M68HC11 coding
        4'b0001: clkcnt <=  12'h1;   // 4   -- original M68HC11 coding
        4'b0010: clkcnt <=  12'h3;   // 16  -- original M68HC11 coding
        4'b0011: clkcnt <=  12'hf;   // 32  -- original M68HC11 coding
        4'b0100: clkcnt <=  12'h1f;  // 8
        4'b0101: clkcnt <=  12'h7;   // 64
        4'b0110: clkcnt <=  12'h3f;  // 128
        4'b0111: clkcnt <=  12'h7f;  // 256
        4'b1000: clkcnt <=  12'hff;  // 512
        4'b1001: clkcnt <=  12'h1ff; // 1024
        4'b1010: clkcnt <=  12'h3ff; // 2048
        4'b1011: clkcnt <=  12'h7ff; // 4096
      endcase

  // generate clock enable signal
  wire ena = ~|clkcnt;

  // transfer statemachine
  always @(posedge clk_i)
    if (~spe | rst_i)
      begin
          state <=  2'b00; // idle
          bcnt  <=  3'h0;
          treg  <=  8'h00;
          wfre  <=  1'b0;
          rfwe  <=  1'b0;
          sck_o <=  1'b0;
      end
    else
      begin
         wfre <=  1'b0;
         rfwe <=  1'b0;

         case (state) //synopsys full_case parallel_case
           2'b00: // idle state
              begin
                  bcnt  <=  3'h7;   // set transfer counter
                  treg  <=  wfdout; // load transfer register
                  sck_o <=  cpol;   // set sck

                  if (~wfempty) begin
                    wfre  <=  1'b1;
                    state <=  2'b01;
                    if (cpha) sck_o <=  ~sck_o;
                  end
              end

           2'b01: // clock-phase2, next data
              if (ena) begin
                sck_o   <=  ~sck_o;
                state   <=  2'b11;
              end

           2'b11: // clock phase1
              if (ena) begin
                treg <=  {treg[6:0], miso_i};
                bcnt <=  bcnt -3'h1;

                if (~|bcnt) begin
                  state <=  2'b00;
                  sck_o <=  cpol;
                  rfwe  <=  1'b1;
                end else begin
                  state <=  2'b01;
                  sck_o <=  ~sck_o;
                end
              end

           2'b10: state <=  2'b00;
         endcase
      end

  assign mosi_o = treg[7];


  // count number of transfers (for interrupt generation)
  reg [1:0] tcnt; // transfer count
  always @(posedge clk_i)
    if (~spe)
      tcnt <=  icnt;
    else if (rfwe) // rfwe gets asserted when all bits have been transfered
      if (|tcnt)
        tcnt <=  tcnt - 2'h1;
      else
        tcnt <=  icnt;

  assign tirq = ~|tcnt & rfwe;

endmodule

