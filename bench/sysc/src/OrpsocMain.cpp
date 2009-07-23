//////////////////////////////////////////////////////////////////////
////                                                              ////
////  ORPSoC SystemC Testbench                                    ////
////                                                              ////
////  Description                                                 ////
////  ORPSoC Testbench file                                       ////
////                                                              ////
////  To Do:                                                      ////
////        Somehow allow tracing to begin later in the sim       ////
////                                                              ////
////                                                              ////
////  Author(s):                                                  ////
////      - Jeremy Bennett jeremy.bennett@embecosm.com            ////
////      - Julius Baxter jb@orsoc.se                             ////
////                                                              ////
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

#include "OrpsocMain.h"

#include "Vorpsoc_top.h"
#include "OrpsocAccess.h"
#include "TraceSC.h"
#include "ResetSC.h"
#include "Or1200MonitorSC.h"
#include "UartSC.h"


int sc_main (int   argc,
	     char *argv[] )
{

  // CPU clock (also used as JTAG TCK) and reset (both active high and low)
  sc_time  clkPeriod (BENCH_CLK_HALFPERIOD * 2.0, TIMESCALE_UNIT);

  sc_clock             clk ("clk", clkPeriod);
  sc_signal<bool>      rst;
  sc_signal<bool>      rstn;
  sc_signal<bool>      rst_o;

  sc_signal<bool>      jtag_tdi;		// JTAG interface
  sc_signal<bool>      jtag_tdo;
  sc_signal<bool>      jtag_tms;
  sc_signal<bool>      jtag_trst;

  sc_signal<bool>      uart_rx;		// External UART
  sc_signal<bool>      uart_tx;

  sc_signal<bool> spi_sd_sclk; // SD Card Memory SPI
  sc_signal<bool> spi_sd_ss;
  sc_signal<bool> spi_sd_miso;
  sc_signal<bool> spi_sd_mosi;
  
  sc_signal<uint32_t> gpio_a; // GPIO bus - output only in verilator sims

  sc_signal<bool> spi1_mosi;
  sc_signal<bool> spi1_miso;
  sc_signal<bool> spi1_ss;
  sc_signal<bool> spi1_sclk;


  // Verilator accessor
  OrpsocAccess    *accessor;

  // Modules
  Vorpsoc_top *orpsoc;		// Verilated ORPSoC
  TraceSC          *trace;		// Drive VCD
  
  ResetSC          *reset;		// Generate a RESET signal
  Or1200MonitorSC  *monitor;		// Handle l.nop x instructions
  UartSC          *uart;		// Handle UART signals

  // Instantiate the Verilator model, VCD trace handler and accessor
  orpsoc     = new Vorpsoc_top ("orpsoc");
  trace      = new TraceSC ("trace", orpsoc, argc, argv);
  accessor   = new OrpsocAccess (orpsoc);
  
  // Instantiate the SystemC modules
  reset         = new ResetSC ("reset", BENCH_RESET_TIME);
  monitor       = new Or1200MonitorSC ("monitor", accessor);
  uart          = new UartSC("uart"); // TODO: Probalby some sort of param

  // Connect up ORPSoC
  orpsoc->clk_pad_i (clk);
  orpsoc->rst_pad_i (rstn);
  orpsoc->rst_pad_o (rst_o);

  orpsoc->dbg_tck_pad_i  (clk);		// JTAG interface
  orpsoc->dbg_tdi_pad_i  (jtag_tdi);
  orpsoc->dbg_tms_pad_i  (jtag_tms);
  orpsoc->dbg_tdo_pad_o  (jtag_tdo);

  orpsoc->uart0_srx_pad_i (uart_rx);		// External UART
  orpsoc->uart0_stx_pad_o (uart_tx);

  orpsoc->spi_sd_sclk_pad_o (spi_sd_sclk); // SD Card Memory SPI
  orpsoc->spi_sd_ss_pad_o (spi_sd_ss);
  orpsoc->spi_sd_miso_pad_i (spi_sd_miso);
  orpsoc->spi_sd_mosi_pad_o (spi_sd_mosi);

  orpsoc->spi1_mosi_pad_o (spi1_mosi);
  orpsoc->spi1_miso_pad_i (spi1_miso);
  orpsoc->spi1_ss_pad_o  (spi1_ss);
  orpsoc->spi1_sclk_pad_o (spi1_sclk);


  orpsoc->gpio_a_pad_io (gpio_a); // GPIO bus - output only in 
                                  // verilator sims
  

  // Connect up the VCD trace handler
  trace->clk (clk);			// Trace

  // Connect up the SystemC  modules
  reset->clk (clk);			// Reset
  reset->rst (rst);
  reset->rstn (rstn);

  monitor->clk (clk);			// Monitor

  uart->clk (clk); // Uart
  uart->uartrx (uart_rx); // orpsoc's receive line
  uart->uarttx (uart_tx); // orpsoc's transmit line

   // Tie off signals
   jtag_tdi      = 1;			// Tie off the JTAG inputs
   jtag_tms      = 1;

   spi_sd_miso = 0; // Tie off master-in/slave-out of SD SPI bus

  spi1_miso = 0;
  
  printf("Beginning test\n");

  // Init the UART function
  uart->initUart(25000000, 115200);

  // Turn on logging by setting the "-log logfilename" option on the command line
  monitor->init_displayState(argc, argv);

  // Execute until we stop
  sc_start ();

  // Free memory
  delete monitor;
  delete reset;

  delete accessor;

  delete trace;
  delete orpsoc;

  return 0;

}	/* sc_main() */
