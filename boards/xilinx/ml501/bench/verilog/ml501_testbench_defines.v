//////////////////////////////////////////////////////////////////////
////                                                              ////
////  ORPSoC on Xilinx ml501 Testbench Defines                    ////
////                                                              ////
////  Description                                                 ////
////  ORPSoC testbench defines file                               ////
////                                                              ////
////  To Do:                                                      ////
////   -                                                          ////
////                                                              ////
////  Author(s):                                                  ////
////      - jb, jb@orsoc.se                                       ////
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

// 100MHz board clock
// Is an FPGA-targetted sim for Xilinx stuff, meaning we'll be including
// glbl.v, meaning timescale will be 1ps/1ps, so clock period must be in ps
`define CLOCK_PERIOD 10_000
`define CLOCK_RATE 100_000_000

// Period for 125MHz clock is 8ns
 `define ETH_CLK_PERIOD 8

// The ORPSoC tests makefile should generate the test_define.v file in
// the sim/run directory.
`ifdef TEST_DEFINE_FILE
 `include "test_define.v"
`else
 `define TEST_NAME_STRING "unspecified-test"
 `define TEST_RESULTS_DIR "./"
`endif

`undef UART_LOG_TX