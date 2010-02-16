/*******************************************************************************
*     This file is owned and controlled by Xilinx and must be used             *
*     solely for design, simulation, implementation and creation of            *
*     design files limited to Xilinx devices or technologies. Use              *
*     with non-Xilinx devices or technologies is expressly prohibited          *
*     and immediately terminates your license.                                 *
*                                                                              *
*     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"            *
*     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR                  *
*     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION          *
*     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION              *
*     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS                *
*     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,                  *
*     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE         *
*     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY                 *
*     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE                  *
*     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR           *
*     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF          *
*     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS          *
*     FOR A PARTICULAR PURPOSE.                                                *
*                                                                              *
*     Xilinx products are not intended for use in life support                 *
*     appliances, devices, or systems. Use in such applications are            *
*     expressly prohibited.                                                    *
*                                                                              *
*     (c) Copyright 1995-2009 Xilinx, Inc.                                     *
*     All rights reserved.                                                     *
*******************************************************************************/
// The synthesis directives "translate_off/translate_on" specified below are
// supported by Xilinx, Mentor Graphics and Synplicity synthesis
// tools. Ensure they are correct for your synthesis tool(s).

// You must compile the wrapper file ml501_ddr2_wb_if_cache.v when simulating
// the core, ml501_ddr2_wb_if_cache. When compiling the wrapper file, be sure to
// reference the XilinxCoreLib Verilog simulation library. For detailed
// instructions, please refer to the "CORE Generator Help".

`timescale 1ns/1ps

module ml501_ddr2_wb_if_cache(
	clka,
	ena,
	wea,
	addra,
	dina,
	douta,
	clkb,
	enb,
	web,
	addrb,
	dinb,
	doutb);


input clka;
input ena;
input [3 : 0] wea;
input [2 : 0] addra;
input [31 : 0] dina;
output [31 : 0] douta;
input clkb;
input enb;
input [15 : 0] web;
input [0 : 0] addrb;
input [127 : 0] dinb;
output [127 : 0] doutb;

// synthesis translate_off

      BLK_MEM_GEN_V3_1 #(
		.C_ADDRA_WIDTH(3),
		.C_ADDRB_WIDTH(1),
		.C_ALGORITHM(1),
		.C_BYTE_SIZE(8),
		.C_COMMON_CLK(0),
		.C_DEFAULT_DATA("0"),
		.C_DISABLE_WARN_BHV_COLL(0),
		.C_DISABLE_WARN_BHV_RANGE(0),
		.C_FAMILY("virtex5"),
		.C_HAS_ENA(1),
		.C_HAS_ENB(1),
		.C_HAS_INJECTERR(0),
		.C_HAS_MEM_OUTPUT_REGS_A(0),
		.C_HAS_MEM_OUTPUT_REGS_B(0),
		.C_HAS_MUX_OUTPUT_REGS_A(0),
		.C_HAS_MUX_OUTPUT_REGS_B(0),
		.C_HAS_REGCEA(0),
		.C_HAS_REGCEB(0),
		.C_HAS_RSTA(0),
		.C_HAS_RSTB(0),
		.C_INITA_VAL("0"),
		.C_INITB_VAL("0"),
		.C_INIT_FILE_NAME("no_coe_file_loaded"),
		.C_LOAD_INIT_FILE(0),
		.C_MEM_TYPE(2),
		.C_MUX_PIPELINE_STAGES(0),
		.C_PRIM_TYPE(1),
		.C_READ_DEPTH_A(8),
		.C_READ_DEPTH_B(2),
		.C_READ_WIDTH_A(32),
		.C_READ_WIDTH_B(128),
		.C_RSTRAM_A(0),
		.C_RSTRAM_B(0),
		.C_RST_PRIORITY_A("CE"),
		.C_RST_PRIORITY_B("CE"),
		.C_RST_TYPE("SYNC"),
		.C_SIM_COLLISION_CHECK("NONE"),
		.C_USE_BYTE_WEA(1),
		.C_USE_BYTE_WEB(1),
		.C_USE_DEFAULT_DATA(0),
		.C_USE_ECC(0),
		.C_WEA_WIDTH(4),
		.C_WEB_WIDTH(16),
		.C_WRITE_DEPTH_A(8),
		.C_WRITE_DEPTH_B(2),
		.C_WRITE_MODE_A("WRITE_FIRST"),
		.C_WRITE_MODE_B("WRITE_FIRST"),
		.C_WRITE_WIDTH_A(32),
		.C_WRITE_WIDTH_B(128),
		.C_XDEVICEFAMILY("virtex5"))
	inst (
		.CLKA(clka),
		.ENA(ena),
		.WEA(wea),
		.ADDRA(addra),
		.DINA(dina),
		.DOUTA(douta),
		.CLKB(clkb),
		.ENB(enb),
		.WEB(web),
		.ADDRB(addrb),
		.DINB(dinb),
		.DOUTB(doutb),
		.RSTA(),
		.REGCEA(),
		.RSTB(),
		.REGCEB(),
		.INJECTSBITERR(),
		.INJECTDBITERR(),
		.SBITERR(),
		.DBITERR(),
		.RDADDRECC());


// synthesis translate_on

// XST black box declaration
// box_type "black_box"
// synthesis attribute box_type of ml501_ddr2_wb_if_cache is "black_box"

endmodule

   /*
 	      
   
   

module ml501_ddr2_wb_if_cache(
			      wb_clk,
			      wb_addr,
			      wb_di,
			      wb_do,
			      wb_we,
			      wb_sel,
			      wb_en,

			      ddr2_clk,
			      ddr2_addr,
			      ddr2_di,
			      ddr2_do,
			      ddr2_we
			      );
   input wb_clk;
   input [2:0] wb_addr;
   input [31:0] wb_di;
   output [31:0] wb_do;
   input 	 wb_we;
   input [3:0] 	 wb_sel;
   input 	 wb_en;
   
   input 	ddr2_clk;
   input 	ddr2_addr;
   input [127:0] ddr2_di;
   output [127:0] ddr2_do;
   input 	  ddr2_we;
   
   wire [3:0] 	  wb_sel_we;
   assign wb_sel_we = {4{wb_we}} & wb_sel;
   
   // Didn't want to work!?

   genvar 	  i;
   generate
      for (i = 0; i < 4; i = i + 1) begin: gen_rambs
	
        // RAMB36: 32k+4k Parity Paramatizable True Dual-Port BlockRAM
	//         Virtex-5
	// Xilinx HDL Libraries Guide, version 10.1.2
	RAMB36 #(
		 .SIM_MODE("SAFE"), // Simulation: "SAFE" vs. "FAST", see "Synthesis and Simulation Design Guide" for details
		 .DOA_REG(0), // Optional output registers on A port (0 or 1)
		 .DOB_REG(0), // Optional output registers on B port (0 or 1)
		 .INIT_A(36'h000000000), // Initial values on A output port
		 .INIT_B(36'h000000000), // Initial values on B output port
		 .RAM_EXTENSION_A("NONE"), // "UPPER", "LOWER" or "NONE" when cascaded
		 .RAM_EXTENSION_B("NONE"), // "UPPER", "LOWER" or "NONE" when cascaded
		 .READ_WIDTH_A(9), // Valid values are 1, 2, 4, 9, 18, or 36
		 .READ_WIDTH_B(36), // Valid values are 1, 2, 4, 9, 18, or 36
		 .SIM_COLLISION_CHECK("NONE"), // Collision check enable "ALL", "WARNING_ONLY",
		 //   "GENERATE_X_ONLY" or "NONE"
		 .SRVAL_A(36'h000000000), // Set/Reset value for A port output
		 .SRVAL_B(36'h000000000), // Set/Reset value for B port output
		 .WRITE_MODE_A("WRITE_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		 .WRITE_MODE_B("WRITE_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
		 .WRITE_WIDTH_A(9), // Valid values are 1, 2, 4, 9, 18, or 36
		 .WRITE_WIDTH_B(36) // Valid values are 1, 2, 4, 9, 18, or 36
		 ) ddr2_if_cache0
     (
      //.CASCADEOUTLATA(CASCADEOUTLATA), // 1-bit cascade A latch output
      //.CASCADEOUTLATB(CASCADEOUTLATB), // 1-bit cascade B latch output
      //.CASCADEOUTREGA(CASCADEOUTREGA), // 1-bit cascade A register output
      //.CASCADEOUTREGB(CASCADEOUTREGB), // 1-bit cascade B register output
      .DOA(wb_do[(i+1)*8-1:(i*8)]),      // 8-bit A port data output
      .DOB(ddr2_do[(i+1)*32-1:i*32]),      // 32-bit B port data output
      //      .DOPA(DOPA),    // A port parity data output
      //      .DOPB(DOPB),    // B port parity data output
      .ADDRA(wb_addr), // A port address input
      .ADDRB(ddr2_addr), // B port address input
      .CASCADEINLATA(0), // 1-bit cascade A latch input
      .CASCADEINLATB(0), // 1-bit cascade B latch input
      .CASCADEINREGA(0), // 1-bit cascade A register input
      .CASCADEINREGB(0), // 1-bit cascade B register input
      .CLKA(wb_clk),     // 1-bit A port clock input
      .CLKB(ddr2_clk),     // 1-bit B port clock input
      .DIA(wb_di[(i+1)*8-1:(i*8)]),       // 8-bit A port data input
      .DIB(ddr2_di[(i+1)*32-1:i*32]),       // 32-bit B port data input
      .DIPA(0),     // 4-bit A port parity data input
      .DIPB(0),     // 4-bit B port parity data input
      .ENA(wb_en),       // 1-bit A port enable input
      .ENB(~wb_en),       // 1-bit B port enable input
      .REGCEA(0), // 1-bit A port register enable input
      .REGCEB(0), // 1-bit B port register enable input
      .SSRA(0),     // 1-bit A port set/reset input
      .SSRB(0),     // 1-bit B port set/reset input
      .WEA(wb_sel_we[i]),       // 4-bit A port write enable input
      .WEB(ddr2_we)        // 4-bit B port write enable input
      );
      end // for (i = 0; i < 4; i = i + 1)
   endgenerate
    */
   
  