//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's ALU                                                ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  ALU                                                         ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_alu.v,v $
// Revision 1.15  2005/01/07 09:23:39  andreje
// l.ff1 and l.cmov instructions added
//
// Revision 1.14  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.13  2004/05/09 19:49:03  lampret
// Added some l.cust5 custom instructions as example
//
// Revision 1.12  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.11  2003/04/24 00:16:07  lampret
// No functional changes. Added defines to disable implementation of multiplier/MAC
//
// Revision 1.10  2002/09/08 05:52:16  lampret
// Added optional l.div/l.divu insns. By default they are disabled.
//
// Revision 1.9  2002/09/07 19:16:10  lampret
// If SR[CY] implemented with OR1200_IMPL_ADDC enabled, l.add/l.addi also set SR[CY].
//
// Revision 1.8  2002/09/07 05:42:02  lampret
// Added optional SR[CY]. Added define to enable additional (compare) flag modifiers. Defines are OR1200_IMPL_ADDC and OR1200_ADDITIONAL_FLAG_MODIFIERS.
//
// Revision 1.7  2002/09/03 22:28:21  lampret
// As per Taylor Su suggestion all case blocks are full case by default and optionally (OR1200_CASE_DEFAULT) can be disabled to increase clock frequncy.
//
// Revision 1.6  2002/03/29 16:40:10  lampret
// Added a directive to ignore signed division variables that are only used in simulation.
//
// Revision 1.5  2002/03/29 16:33:59  lampret
// Added again just recently removed full_case directive
//
// Revision 1.4  2002/03/29 15:16:53  lampret
// Some of the warnings fixed.
//
// Revision 1.3  2002/01/28 01:15:59  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.10  2001/11/12 01:45:40  lampret
// Moved flag bit into SR. Changed RF enable from constant enable to dynamic enable for read ports.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/19 23:28:45  lampret
// Fixed some synthesis warnings. Configured with caches and MMUs.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_alu(
	a, b, mult_mac_result, macrc_op,
	alu_op, shrot_op, comp_op,
	cust5_op, cust5_limm,
	result, flagforw, flag_we,
	cyforw, cy_we, carry, flag
);

parameter width = `OR1200_OPERAND_WIDTH;

//
// I/O
//
input	[width-1:0]		a;
input	[width-1:0]		b;
input	[width-1:0]		mult_mac_result;
input				macrc_op;
input	[`OR1200_ALUOP_WIDTH-1:0]	alu_op;
input	[`OR1200_SHROTOP_WIDTH-1:0]	shrot_op;
input	[`OR1200_COMPOP_WIDTH-1:0]	comp_op;
input	[4:0]			cust5_op;
input	[5:0]			cust5_limm;
output	[width-1:0]		result;
output				flagforw;
output				flag_we;
output				cyforw;
output				cy_we;
input				carry;
input         flag;

//
// Internal wires and regs
//
reg	[width-1:0]		result;
reg	[width-1:0]		shifted_rotated;
reg	[width-1:0]		result_cust5;
reg				flagforw;
reg				flagcomp;
reg				flag_we;
reg				cy_we;
wire	[width-1:0]		comp_a;
wire	[width-1:0]		comp_b;
`ifdef OR1200_IMPL_ALU_COMP1
wire				a_eq_b;
wire				a_lt_b;
`endif
wire	[width-1:0]		result_sum;
`ifdef OR1200_IMPL_ADDC
wire	[width-1:0]		result_csum;
wire				cy_csum;
`endif
wire	[width-1:0]		result_and;
wire				cy_sum;
reg				cyforw;

//
// Combinatorial logic
//
assign comp_a = {a[width-1] ^ comp_op[3] , a[width-2:0]};
assign comp_b = {b[width-1] ^ comp_op[3] , b[width-2:0]};
`ifdef OR1200_IMPL_ALU_COMP1
assign a_eq_b = (comp_a == comp_b);
assign a_lt_b = (comp_a < comp_b);
`endif
assign {cy_sum, result_sum} = a + b;
`ifdef OR1200_IMPL_ADDC
assign {cy_csum, result_csum} = a + b + {`OR1200_OPERAND_WIDTH'd0, carry};
`endif
assign result_and = a & b;

//
// Simulation check for bad ALU behavior
//
`ifdef OR1200_WARNINGS
// synopsys translate_off
always @(result) begin
	if (result === 32'bx)
		$display("%t: WARNING: 32'bx detected on ALU result bus. Please check !", $time);
end
// synopsys translate_on
`endif

//
// Central part of the ALU
//
always @(alu_op or a or b or result_sum or result_and or macrc_op or shifted_rotated or mult_mac_result or flag or result_cust5 or carry
`ifdef OR1200_IMPL_ADDC
         or result_csum
`endif
) begin
`ifdef OR1200_CASE_DEFAULT
	casex (alu_op)		// synopsys parallel_case
`else
	casex (alu_op)		// synopsys full_case parallel_case
`endif
    `OR1200_ALUOP_FF1: begin
        result = a[0] ? 1 : a[1] ? 2 : a[2] ? 3 : a[3] ? 4 : a[4] ? 5 : a[5] ? 6 : a[6] ? 7 : a[7] ? 8 : a[8] ? 9 : a[9] ? 10 : a[10] ? 11 : a[11] ? 12 : a[12] ? 13 : a[13] ? 14 : a[14] ? 15 : a[15] ? 16 : a[16] ? 17 : a[17] ? 18 : a[18] ? 19 : a[19] ? 20 : a[20] ? 21 : a[21] ? 22 : a[22] ? 23 : a[23] ? 24 : a[24] ? 25 : a[25] ? 26 : a[26] ? 27 : a[27] ? 28 : a[28] ? 29 : a[29] ? 30 : a[30] ? 31 : a[31] ? 32 : 0;
    end
		`OR1200_ALUOP_CUST5 : begin 
				result = result_cust5;
		end
		`OR1200_ALUOP_SHROT : begin 
				result = shifted_rotated;
		end
		`OR1200_ALUOP_ADD : begin
				result = result_sum;
		end
`ifdef OR1200_IMPL_ADDC
		`OR1200_ALUOP_ADDC : begin
				result = result_csum;
		end
`endif
		`OR1200_ALUOP_SUB : begin
				result = a - b;
		end
		`OR1200_ALUOP_XOR : begin
				result = a ^ b;
		end
		`OR1200_ALUOP_OR  : begin
				result = a | b;
		end
		`OR1200_ALUOP_IMM : begin
				result = b;
		end
		`OR1200_ALUOP_MOVHI : begin
				if (macrc_op) begin
					result = mult_mac_result;
				end
				else begin
					result = b << 16;
				end
		end
`ifdef OR1200_MULT_IMPLEMENTED
`ifdef OR1200_IMPL_DIV
		`OR1200_ALUOP_DIV,
		`OR1200_ALUOP_DIVU,
`endif
		`OR1200_ALUOP_MUL : begin
				result = mult_mac_result;
		end
`endif
    `OR1200_ALUOP_CMOV: begin
        result = flag ? a : b;
    end

`ifdef OR1200_CASE_DEFAULT
    default: begin
`else
    `OR1200_ALUOP_COMP, `OR1200_ALUOP_AND:
    begin
`endif
      result=result_and;
    end 
	endcase
end

//
// l.cust5 custom instructions
//
// Examples for move byte, set bit and clear bit
//
always @(cust5_op or cust5_limm or a or b) begin
	casex (cust5_op)		// synopsys parallel_case
		5'h1 : begin 
			casex (cust5_limm[1:0])
				2'h0: result_cust5 = {a[31:8], b[7:0]};
				2'h1: result_cust5 = {a[31:16], b[7:0], a[7:0]};
				2'h2: result_cust5 = {a[31:24], b[7:0], a[15:0]};
				2'h3: result_cust5 = {b[7:0], a[23:0]};
			endcase
		end
		5'h2 :
			result_cust5 = a | (1 << cust5_limm);
		5'h3 :
			result_cust5 = a & (32'hffffffff ^ (1 << cust5_limm));
//
// *** Put here new l.cust5 custom instructions ***
//
		default: begin
			result_cust5 = a;
		end
	endcase
end

//
// Generate flag and flag write enable
//
always @(alu_op or result_sum or result_and or flagcomp
`ifdef OR1200_IMPL_ADDC
         or result_csum
`endif
) begin
	casex (alu_op)		// synopsys parallel_case
`ifdef OR1200_ADDITIONAL_FLAG_MODIFIERS
		`OR1200_ALUOP_ADD : begin
			flagforw = (result_sum == 32'h0000_0000);
			flag_we = 1'b1;
		end
`ifdef OR1200_IMPL_ADDC
		`OR1200_ALUOP_ADDC : begin
			flagforw = (result_csum == 32'h0000_0000);
			flag_we = 1'b1;
		end
`endif
		`OR1200_ALUOP_AND: begin
			flagforw = (result_and == 32'h0000_0000);
			flag_we = 1'b1;
		end
`endif
		`OR1200_ALUOP_COMP: begin
			flagforw = flagcomp;
			flag_we = 1'b1;
		end
		default: begin
			flagforw = 1'b0;
			flag_we = 1'b0;
		end
	endcase
end

//
// Generate SR[CY] write enable
//
always @(alu_op or cy_sum
`ifdef OR1200_IMPL_ADDC
         or cy_csum
`endif
) begin
	casex (alu_op)		// synopsys parallel_case
`ifdef OR1200_IMPL_CY
		`OR1200_ALUOP_ADD : begin
			cyforw = cy_sum;
			cy_we = 1'b1;
		end
`ifdef OR1200_IMPL_ADDC
		`OR1200_ALUOP_ADDC: begin
			cyforw = cy_csum;
			cy_we = 1'b1;
		end
`endif
`endif
		default: begin
			cyforw = 1'b0;
			cy_we = 1'b0;
		end
	endcase
end

//
// Shifts and rotation
//
always @(shrot_op or a or b) begin
	case (shrot_op)		// synopsys parallel_case
	`OR1200_SHROTOP_SLL :
				shifted_rotated = (a << b[4:0]);
		`OR1200_SHROTOP_SRL :
				shifted_rotated = (a >> b[4:0]);

`ifdef OR1200_IMPL_ALU_ROTATE
		`OR1200_SHROTOP_ROR :
				shifted_rotated = (a << (6'd32-{1'b0, b[4:0]})) | (a >> b[4:0]);
`endif
		default:
				shifted_rotated = ({32{a[31]}} << (6'd32-{1'b0, b[4:0]})) | a >> b[4:0];
	endcase
end

//
// First type of compare implementation
//
`ifdef OR1200_IMPL_ALU_COMP1
always @(comp_op or a_eq_b or a_lt_b) begin
	case(comp_op[2:0])	// synopsys parallel_case
		`OR1200_COP_SFEQ:
			flagcomp = a_eq_b;
		`OR1200_COP_SFNE:
			flagcomp = ~a_eq_b;
		`OR1200_COP_SFGT:
			flagcomp = ~(a_eq_b | a_lt_b);
		`OR1200_COP_SFGE:
			flagcomp = ~a_lt_b;
		`OR1200_COP_SFLT:
			flagcomp = a_lt_b;
		`OR1200_COP_SFLE:
			flagcomp = a_eq_b | a_lt_b;
		default:
			flagcomp = 1'b0;
	endcase
end
`endif

//
// Second type of compare implementation
//
`ifdef OR1200_IMPL_ALU_COMP2
always @(comp_op or comp_a or comp_b) begin
	case(comp_op[2:0])	// synopsys parallel_case
		`OR1200_COP_SFEQ:
			flagcomp = (comp_a == comp_b);
		`OR1200_COP_SFNE:
			flagcomp = (comp_a != comp_b);
		`OR1200_COP_SFGT:
			flagcomp = (comp_a > comp_b);
		`OR1200_COP_SFGE:
			flagcomp = (comp_a >= comp_b);
		`OR1200_COP_SFLT:
			flagcomp = (comp_a < comp_b);
		`OR1200_COP_SFLE:
			flagcomp = (comp_a <= comp_b);
		default:
			flagcomp = 1'b0;
	endcase
end
`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's 32x32 multiply for ASIC                            ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  32x32 multiply for ASIC                                     ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_amultp2_32x32.v,v $
// Revision 1.2  2003/04/07 01:23:31  lampret
// Added another pipe stage to match gmult. One day second pipe in amult and gmult might be removed to get better performance.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.9  2001/12/04 05:02:35  lampret
// Added OR1200_GENERIC_MULTP2_32X32 and OR1200_ASIC_MULTP2_32X32
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

`ifdef OR1200_ASIC_MULTP2_32X32

module PP_LOW ( ONEPOS, ONENEG, TWONEG, INA, INB, PPBIT );
input  ONEPOS;
input  ONENEG;
input  TWONEG;
input  INA;
input  INB;
output PPBIT;
   assign PPBIT = (ONEPOS & INA) | (ONENEG & INB) | TWONEG;
endmodule


module PP_MIDDLE ( ONEPOS, ONENEG, TWOPOS, TWONEG, INA, INB, INC, IND, PPBIT );
input  ONEPOS;
input  ONENEG;
input  TWOPOS;
input  TWONEG;
input  INA;
input  INB;
input  INC;
input  IND;
output PPBIT;
   assign PPBIT =  ~ (( ~ (INA & TWOPOS)) & ( ~ (INB & TWONEG)) & ( ~ (INC & ONEPOS)) & ( ~ (IND & ONENEG)));
endmodule


module PP_HIGH ( ONEPOS, ONENEG, TWOPOS, TWONEG, INA, INB, PPBIT );
input  ONEPOS;
input  ONENEG;
input  TWOPOS;
input  TWONEG;
input  INA;
input  INB;
output PPBIT;
   assign PPBIT =  ~ ((INA & ONEPOS) | (INB & ONENEG) | (INA & TWOPOS) | (INB & TWONEG));
endmodule


module R_GATE ( INA, INB, INC, PPBIT );
input  INA;
input  INB;
input  INC;
output PPBIT;
   assign PPBIT = ( ~ (INA & INB)) & INC;
endmodule


module DECODER ( INA, INB, INC, TWOPOS, TWONEG, ONEPOS, ONENEG );
input  INA;
input  INB;
input  INC;
output TWOPOS;
output TWONEG;
output ONEPOS;
output ONENEG;
   assign TWOPOS =  ~ ( ~ (INA & INB & ( ~ INC)));
   assign TWONEG =  ~ ( ~ (( ~ INA) & ( ~ INB) & INC));
   assign ONEPOS = (( ~ INA) & INB & ( ~ INC)) | (( ~ INC) & ( ~ INB) & INA);
   assign ONENEG = (INA & ( ~ INB) & INC) | (INC & INB & ( ~ INA));
endmodule


module BOOTHCODER_33_32 ( OPA, OPB, SUMMAND );
input  [0:32] OPA;
input  [0:31] OPB;
output [0:575] SUMMAND;
   wire [0:32] INV_MULTIPLICAND;
   wire [0:63] INT_MULTIPLIER;
   wire LOGIC_ONE, LOGIC_ZERO;
   assign LOGIC_ONE = 1;
   assign LOGIC_ZERO = 0;
   DECODER DEC_0 (.INA (LOGIC_ZERO) , .INB (OPB[0]) , .INC (OPB[1]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) );
   assign INV_MULTIPLICAND[0] =  ~ OPA[0];
   PP_LOW PPL_0 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[0]) );
   R_GATE RGATE_0 (.INA (LOGIC_ZERO) , .INB (OPB[0]) , .INC (OPB[1]) , .PPBIT (SUMMAND[1]) );
   assign INV_MULTIPLICAND[1] =  ~ OPA[1];
   PP_MIDDLE PPM_0 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[2]) );
   assign INV_MULTIPLICAND[2] =  ~ OPA[2];
   PP_MIDDLE PPM_1 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[3]) );
   assign INV_MULTIPLICAND[3] =  ~ OPA[3];
   PP_MIDDLE PPM_2 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[6]) );
   assign INV_MULTIPLICAND[4] =  ~ OPA[4];
   PP_MIDDLE PPM_3 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[8]) );
   assign INV_MULTIPLICAND[5] =  ~ OPA[5];
   PP_MIDDLE PPM_4 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[12]) );
   assign INV_MULTIPLICAND[6] =  ~ OPA[6];
   PP_MIDDLE PPM_5 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[15]) );
   assign INV_MULTIPLICAND[7] =  ~ OPA[7];
   PP_MIDDLE PPM_6 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[20]) );
   assign INV_MULTIPLICAND[8] =  ~ OPA[8];
   PP_MIDDLE PPM_7 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[24]) );
   assign INV_MULTIPLICAND[9] =  ~ OPA[9];
   PP_MIDDLE PPM_8 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[30]) );
   assign INV_MULTIPLICAND[10] =  ~ OPA[10];
   PP_MIDDLE PPM_9 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[35]) );
   assign INV_MULTIPLICAND[11] =  ~ OPA[11];
   PP_MIDDLE PPM_10 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[42]) );
   assign INV_MULTIPLICAND[12] =  ~ OPA[12];
   PP_MIDDLE PPM_11 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[48]) );
   assign INV_MULTIPLICAND[13] =  ~ OPA[13];
   PP_MIDDLE PPM_12 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[56]) );
   assign INV_MULTIPLICAND[14] =  ~ OPA[14];
   PP_MIDDLE PPM_13 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[63]) );
   assign INV_MULTIPLICAND[15] =  ~ OPA[15];
   PP_MIDDLE PPM_14 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[72]) );
   assign INV_MULTIPLICAND[16] =  ~ OPA[16];
   PP_MIDDLE PPM_15 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[80]) );
   assign INV_MULTIPLICAND[17] =  ~ OPA[17];
   PP_MIDDLE PPM_16 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[90]) );
   assign INV_MULTIPLICAND[18] =  ~ OPA[18];
   PP_MIDDLE PPM_17 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[99]) );
   assign INV_MULTIPLICAND[19] =  ~ OPA[19];
   PP_MIDDLE PPM_18 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[110]) );
   assign INV_MULTIPLICAND[20] =  ~ OPA[20];
   PP_MIDDLE PPM_19 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[120]) );
   assign INV_MULTIPLICAND[21] =  ~ OPA[21];
   PP_MIDDLE PPM_20 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[132]) );
   assign INV_MULTIPLICAND[22] =  ~ OPA[22];
   PP_MIDDLE PPM_21 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[143]) );
   assign INV_MULTIPLICAND[23] =  ~ OPA[23];
   PP_MIDDLE PPM_22 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[156]) );
   assign INV_MULTIPLICAND[24] =  ~ OPA[24];
   PP_MIDDLE PPM_23 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[168]) );
   assign INV_MULTIPLICAND[25] =  ~ OPA[25];
   PP_MIDDLE PPM_24 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[182]) );
   assign INV_MULTIPLICAND[26] =  ~ OPA[26];
   PP_MIDDLE PPM_25 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[195]) );
   assign INV_MULTIPLICAND[27] =  ~ OPA[27];
   PP_MIDDLE PPM_26 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[210]) );
   assign INV_MULTIPLICAND[28] =  ~ OPA[28];
   PP_MIDDLE PPM_27 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[224]) );
   assign INV_MULTIPLICAND[29] =  ~ OPA[29];
   PP_MIDDLE PPM_28 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[240]) );
   assign INV_MULTIPLICAND[30] =  ~ OPA[30];
   PP_MIDDLE PPM_29 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[255]) );
   assign INV_MULTIPLICAND[31] =  ~ OPA[31];
   PP_MIDDLE PPM_30 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[272]) );
   assign INV_MULTIPLICAND[32] =  ~ OPA[32];
   PP_MIDDLE PPM_31 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[288]) );
   PP_HIGH PPH_0 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[0]) , .TWONEG (INT_MULTIPLIER[1]) , .ONEPOS (INT_MULTIPLIER[2]) , .ONENEG (INT_MULTIPLIER[3]) , .PPBIT (SUMMAND[304]) );
   assign SUMMAND[305] = 1;
   DECODER DEC_1 (.INA (OPB[1]) , .INB (OPB[2]) , .INC (OPB[3]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) );
   PP_LOW PPL_1 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[4]) );
   R_GATE RGATE_1 (.INA (OPB[1]) , .INB (OPB[2]) , .INC (OPB[3]) , .PPBIT (SUMMAND[5]) );
   PP_MIDDLE PPM_32 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[7]) );
   PP_MIDDLE PPM_33 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[9]) );
   PP_MIDDLE PPM_34 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[13]) );
   PP_MIDDLE PPM_35 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[16]) );
   PP_MIDDLE PPM_36 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[21]) );
   PP_MIDDLE PPM_37 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[25]) );
   PP_MIDDLE PPM_38 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[31]) );
   PP_MIDDLE PPM_39 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[36]) );
   PP_MIDDLE PPM_40 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[43]) );
   PP_MIDDLE PPM_41 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[49]) );
   PP_MIDDLE PPM_42 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[57]) );
   PP_MIDDLE PPM_43 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[64]) );
   PP_MIDDLE PPM_44 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[73]) );
   PP_MIDDLE PPM_45 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[81]) );
   PP_MIDDLE PPM_46 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[91]) );
   PP_MIDDLE PPM_47 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[100]) );
   PP_MIDDLE PPM_48 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[111]) );
   PP_MIDDLE PPM_49 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[121]) );
   PP_MIDDLE PPM_50 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[133]) );
   PP_MIDDLE PPM_51 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[144]) );
   PP_MIDDLE PPM_52 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[157]) );
   PP_MIDDLE PPM_53 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[169]) );
   PP_MIDDLE PPM_54 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[183]) );
   PP_MIDDLE PPM_55 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[196]) );
   PP_MIDDLE PPM_56 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[211]) );
   PP_MIDDLE PPM_57 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[225]) );
   PP_MIDDLE PPM_58 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[241]) );
   PP_MIDDLE PPM_59 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[256]) );
   PP_MIDDLE PPM_60 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[273]) );
   PP_MIDDLE PPM_61 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[289]) );
   PP_MIDDLE PPM_62 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[306]) );
   PP_MIDDLE PPM_63 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[321]) );
   assign SUMMAND[322] = LOGIC_ONE;
   PP_HIGH PPH_1 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[4]) , .TWONEG (INT_MULTIPLIER[5]) , .ONEPOS (INT_MULTIPLIER[6]) , .ONENEG (INT_MULTIPLIER[7]) , .PPBIT (SUMMAND[337]) );
   DECODER DEC_2 (.INA (OPB[3]) , .INB (OPB[4]) , .INC (OPB[5]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) );
   PP_LOW PPL_2 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[10]) );
   R_GATE RGATE_2 (.INA (OPB[3]) , .INB (OPB[4]) , .INC (OPB[5]) , .PPBIT (SUMMAND[11]) );
   PP_MIDDLE PPM_64 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[14]) );
   PP_MIDDLE PPM_65 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[17]) );
   PP_MIDDLE PPM_66 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[22]) );
   PP_MIDDLE PPM_67 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[26]) );
   PP_MIDDLE PPM_68 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[32]) );
   PP_MIDDLE PPM_69 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[37]) );
   PP_MIDDLE PPM_70 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[44]) );
   PP_MIDDLE PPM_71 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[50]) );
   PP_MIDDLE PPM_72 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[58]) );
   PP_MIDDLE PPM_73 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[65]) );
   PP_MIDDLE PPM_74 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[74]) );
   PP_MIDDLE PPM_75 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[82]) );
   PP_MIDDLE PPM_76 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[92]) );
   PP_MIDDLE PPM_77 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[101]) );
   PP_MIDDLE PPM_78 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[112]) );
   PP_MIDDLE PPM_79 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[122]) );
   PP_MIDDLE PPM_80 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[134]) );
   PP_MIDDLE PPM_81 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[145]) );
   PP_MIDDLE PPM_82 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[158]) );
   PP_MIDDLE PPM_83 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[170]) );
   PP_MIDDLE PPM_84 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[184]) );
   PP_MIDDLE PPM_85 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[197]) );
   PP_MIDDLE PPM_86 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[212]) );
   PP_MIDDLE PPM_87 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[226]) );
   PP_MIDDLE PPM_88 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[242]) );
   PP_MIDDLE PPM_89 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[257]) );
   PP_MIDDLE PPM_90 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[274]) );
   PP_MIDDLE PPM_91 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[290]) );
   PP_MIDDLE PPM_92 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[307]) );
   PP_MIDDLE PPM_93 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[323]) );
   PP_MIDDLE PPM_94 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[338]) );
   PP_MIDDLE PPM_95 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[352]) );
   assign SUMMAND[353] = LOGIC_ONE;
   PP_HIGH PPH_2 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[8]) , .TWONEG (INT_MULTIPLIER[9]) , .ONEPOS (INT_MULTIPLIER[10]) , .ONENEG (INT_MULTIPLIER[11]) , .PPBIT (SUMMAND[367]) );
   DECODER DEC_3 (.INA (OPB[5]) , .INB (OPB[6]) , .INC (OPB[7]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) );
   PP_LOW PPL_3 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[18]) );
   R_GATE RGATE_3 (.INA (OPB[5]) , .INB (OPB[6]) , .INC (OPB[7]) , .PPBIT (SUMMAND[19]) );
   PP_MIDDLE PPM_96 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[23]) );
   PP_MIDDLE PPM_97 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[27]) );
   PP_MIDDLE PPM_98 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[33]) );
   PP_MIDDLE PPM_99 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[38]) );
   PP_MIDDLE PPM_100 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[45]) );
   PP_MIDDLE PPM_101 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[51]) );
   PP_MIDDLE PPM_102 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[59]) );
   PP_MIDDLE PPM_103 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[66]) );
   PP_MIDDLE PPM_104 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[75]) );
   PP_MIDDLE PPM_105 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[83]) );
   PP_MIDDLE PPM_106 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[93]) );
   PP_MIDDLE PPM_107 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[102]) );
   PP_MIDDLE PPM_108 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[113]) );
   PP_MIDDLE PPM_109 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[123]) );
   PP_MIDDLE PPM_110 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[135]) );
   PP_MIDDLE PPM_111 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[146]) );
   PP_MIDDLE PPM_112 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[159]) );
   PP_MIDDLE PPM_113 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[171]) );
   PP_MIDDLE PPM_114 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[185]) );
   PP_MIDDLE PPM_115 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[198]) );
   PP_MIDDLE PPM_116 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[213]) );
   PP_MIDDLE PPM_117 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[227]) );
   PP_MIDDLE PPM_118 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[243]) );
   PP_MIDDLE PPM_119 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[258]) );
   PP_MIDDLE PPM_120 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[275]) );
   PP_MIDDLE PPM_121 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[291]) );
   PP_MIDDLE PPM_122 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[308]) );
   PP_MIDDLE PPM_123 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[324]) );
   PP_MIDDLE PPM_124 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[339]) );
   PP_MIDDLE PPM_125 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[354]) );
   PP_MIDDLE PPM_126 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[368]) );
   PP_MIDDLE PPM_127 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[381]) );
   assign SUMMAND[382] = LOGIC_ONE;
   PP_HIGH PPH_3 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[12]) , .TWONEG (INT_MULTIPLIER[13]) , .ONEPOS (INT_MULTIPLIER[14]) , .ONENEG (INT_MULTIPLIER[15]) , .PPBIT (SUMMAND[395]) );
   DECODER DEC_4 (.INA (OPB[7]) , .INB (OPB[8]) , .INC (OPB[9]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) );
   PP_LOW PPL_4 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[28]) );
   R_GATE RGATE_4 (.INA (OPB[7]) , .INB (OPB[8]) , .INC (OPB[9]) , .PPBIT (SUMMAND[29]) );
   PP_MIDDLE PPM_128 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[34]) );
   PP_MIDDLE PPM_129 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[39]) );
   PP_MIDDLE PPM_130 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[46]) );
   PP_MIDDLE PPM_131 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[52]) );
   PP_MIDDLE PPM_132 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[60]) );
   PP_MIDDLE PPM_133 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[67]) );
   PP_MIDDLE PPM_134 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[76]) );
   PP_MIDDLE PPM_135 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[84]) );
   PP_MIDDLE PPM_136 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[94]) );
   PP_MIDDLE PPM_137 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[103]) );
   PP_MIDDLE PPM_138 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[114]) );
   PP_MIDDLE PPM_139 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[124]) );
   PP_MIDDLE PPM_140 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[136]) );
   PP_MIDDLE PPM_141 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[147]) );
   PP_MIDDLE PPM_142 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[160]) );
   PP_MIDDLE PPM_143 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[172]) );
   PP_MIDDLE PPM_144 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[186]) );
   PP_MIDDLE PPM_145 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[199]) );
   PP_MIDDLE PPM_146 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[214]) );
   PP_MIDDLE PPM_147 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[228]) );
   PP_MIDDLE PPM_148 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[244]) );
   PP_MIDDLE PPM_149 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[259]) );
   PP_MIDDLE PPM_150 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[276]) );
   PP_MIDDLE PPM_151 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[292]) );
   PP_MIDDLE PPM_152 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[309]) );
   PP_MIDDLE PPM_153 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[325]) );
   PP_MIDDLE PPM_154 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[340]) );
   PP_MIDDLE PPM_155 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[355]) );
   PP_MIDDLE PPM_156 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[369]) );
   PP_MIDDLE PPM_157 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[383]) );
   PP_MIDDLE PPM_158 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[396]) );
   PP_MIDDLE PPM_159 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[408]) );
   assign SUMMAND[409] = LOGIC_ONE;
   PP_HIGH PPH_4 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[16]) , .TWONEG (INT_MULTIPLIER[17]) , .ONEPOS (INT_MULTIPLIER[18]) , .ONENEG (INT_MULTIPLIER[19]) , .PPBIT (SUMMAND[421]) );
   DECODER DEC_5 (.INA (OPB[9]) , .INB (OPB[10]) , .INC (OPB[11]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) );
   PP_LOW PPL_5 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[40]) );
   R_GATE RGATE_5 (.INA (OPB[9]) , .INB (OPB[10]) , .INC (OPB[11]) , .PPBIT (SUMMAND[41]) );
   PP_MIDDLE PPM_160 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[47]) );
   PP_MIDDLE PPM_161 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[53]) );
   PP_MIDDLE PPM_162 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[61]) );
   PP_MIDDLE PPM_163 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[68]) );
   PP_MIDDLE PPM_164 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[77]) );
   PP_MIDDLE PPM_165 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[85]) );
   PP_MIDDLE PPM_166 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[95]) );
   PP_MIDDLE PPM_167 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[104]) );
   PP_MIDDLE PPM_168 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[115]) );
   PP_MIDDLE PPM_169 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[125]) );
   PP_MIDDLE PPM_170 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[137]) );
   PP_MIDDLE PPM_171 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[148]) );
   PP_MIDDLE PPM_172 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[161]) );
   PP_MIDDLE PPM_173 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[173]) );
   PP_MIDDLE PPM_174 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[187]) );
   PP_MIDDLE PPM_175 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[200]) );
   PP_MIDDLE PPM_176 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[215]) );
   PP_MIDDLE PPM_177 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[229]) );
   PP_MIDDLE PPM_178 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[245]) );
   PP_MIDDLE PPM_179 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[260]) );
   PP_MIDDLE PPM_180 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[277]) );
   PP_MIDDLE PPM_181 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[293]) );
   PP_MIDDLE PPM_182 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[310]) );
   PP_MIDDLE PPM_183 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[326]) );
   PP_MIDDLE PPM_184 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[341]) );
   PP_MIDDLE PPM_185 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[356]) );
   PP_MIDDLE PPM_186 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[370]) );
   PP_MIDDLE PPM_187 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[384]) );
   PP_MIDDLE PPM_188 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[397]) );
   PP_MIDDLE PPM_189 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[410]) );
   PP_MIDDLE PPM_190 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[422]) );
   PP_MIDDLE PPM_191 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[433]) );
   assign SUMMAND[434] = LOGIC_ONE;
   PP_HIGH PPH_5 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[20]) , .TWONEG (INT_MULTIPLIER[21]) , .ONEPOS (INT_MULTIPLIER[22]) , .ONENEG (INT_MULTIPLIER[23]) , .PPBIT (SUMMAND[445]) );
   DECODER DEC_6 (.INA (OPB[11]) , .INB (OPB[12]) , .INC (OPB[13]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) );
   PP_LOW PPL_6 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[54]) );
   R_GATE RGATE_6 (.INA (OPB[11]) , .INB (OPB[12]) , .INC (OPB[13]) , .PPBIT (SUMMAND[55]) );
   PP_MIDDLE PPM_192 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[62]) );
   PP_MIDDLE PPM_193 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[69]) );
   PP_MIDDLE PPM_194 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[78]) );
   PP_MIDDLE PPM_195 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[86]) );
   PP_MIDDLE PPM_196 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[96]) );
   PP_MIDDLE PPM_197 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[105]) );
   PP_MIDDLE PPM_198 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[116]) );
   PP_MIDDLE PPM_199 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[126]) );
   PP_MIDDLE PPM_200 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[138]) );
   PP_MIDDLE PPM_201 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[149]) );
   PP_MIDDLE PPM_202 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[162]) );
   PP_MIDDLE PPM_203 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[174]) );
   PP_MIDDLE PPM_204 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[188]) );
   PP_MIDDLE PPM_205 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[201]) );
   PP_MIDDLE PPM_206 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[216]) );
   PP_MIDDLE PPM_207 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[230]) );
   PP_MIDDLE PPM_208 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[246]) );
   PP_MIDDLE PPM_209 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[261]) );
   PP_MIDDLE PPM_210 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[278]) );
   PP_MIDDLE PPM_211 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[294]) );
   PP_MIDDLE PPM_212 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[311]) );
   PP_MIDDLE PPM_213 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[327]) );
   PP_MIDDLE PPM_214 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[342]) );
   PP_MIDDLE PPM_215 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[357]) );
   PP_MIDDLE PPM_216 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[371]) );
   PP_MIDDLE PPM_217 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[385]) );
   PP_MIDDLE PPM_218 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[398]) );
   PP_MIDDLE PPM_219 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[411]) );
   PP_MIDDLE PPM_220 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[423]) );
   PP_MIDDLE PPM_221 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[435]) );
   PP_MIDDLE PPM_222 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[446]) );
   PP_MIDDLE PPM_223 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[456]) );
   assign SUMMAND[457] = LOGIC_ONE;
   PP_HIGH PPH_6 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[24]) , .TWONEG (INT_MULTIPLIER[25]) , .ONEPOS (INT_MULTIPLIER[26]) , .ONENEG (INT_MULTIPLIER[27]) , .PPBIT (SUMMAND[467]) );
   DECODER DEC_7 (.INA (OPB[13]) , .INB (OPB[14]) , .INC (OPB[15]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) );
   PP_LOW PPL_7 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[70]) );
   R_GATE RGATE_7 (.INA (OPB[13]) , .INB (OPB[14]) , .INC (OPB[15]) , .PPBIT (SUMMAND[71]) );
   PP_MIDDLE PPM_224 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[79]) );
   PP_MIDDLE PPM_225 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[87]) );
   PP_MIDDLE PPM_226 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[97]) );
   PP_MIDDLE PPM_227 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[106]) );
   PP_MIDDLE PPM_228 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[117]) );
   PP_MIDDLE PPM_229 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[127]) );
   PP_MIDDLE PPM_230 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[139]) );
   PP_MIDDLE PPM_231 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[150]) );
   PP_MIDDLE PPM_232 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[163]) );
   PP_MIDDLE PPM_233 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[175]) );
   PP_MIDDLE PPM_234 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[189]) );
   PP_MIDDLE PPM_235 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[202]) );
   PP_MIDDLE PPM_236 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[217]) );
   PP_MIDDLE PPM_237 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[231]) );
   PP_MIDDLE PPM_238 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[247]) );
   PP_MIDDLE PPM_239 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[262]) );
   PP_MIDDLE PPM_240 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[279]) );
   PP_MIDDLE PPM_241 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[295]) );
   PP_MIDDLE PPM_242 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[312]) );
   PP_MIDDLE PPM_243 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[328]) );
   PP_MIDDLE PPM_244 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[343]) );
   PP_MIDDLE PPM_245 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[358]) );
   PP_MIDDLE PPM_246 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[372]) );
   PP_MIDDLE PPM_247 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[386]) );
   PP_MIDDLE PPM_248 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[399]) );
   PP_MIDDLE PPM_249 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[412]) );
   PP_MIDDLE PPM_250 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[424]) );
   PP_MIDDLE PPM_251 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[436]) );
   PP_MIDDLE PPM_252 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[447]) );
   PP_MIDDLE PPM_253 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[458]) );
   PP_MIDDLE PPM_254 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[468]) );
   PP_MIDDLE PPM_255 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[477]) );
   assign SUMMAND[478] = LOGIC_ONE;
   PP_HIGH PPH_7 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[28]) , .TWONEG (INT_MULTIPLIER[29]) , .ONEPOS (INT_MULTIPLIER[30]) , .ONENEG (INT_MULTIPLIER[31]) , .PPBIT (SUMMAND[487]) );
   DECODER DEC_8 (.INA (OPB[15]) , .INB (OPB[16]) , .INC (OPB[17]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) );
   PP_LOW PPL_8 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[88]) );
   R_GATE RGATE_8 (.INA (OPB[15]) , .INB (OPB[16]) , .INC (OPB[17]) , .PPBIT (SUMMAND[89]) );
   PP_MIDDLE PPM_256 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[98]) );
   PP_MIDDLE PPM_257 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[107]) );
   PP_MIDDLE PPM_258 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[118]) );
   PP_MIDDLE PPM_259 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[128]) );
   PP_MIDDLE PPM_260 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[140]) );
   PP_MIDDLE PPM_261 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[151]) );
   PP_MIDDLE PPM_262 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[164]) );
   PP_MIDDLE PPM_263 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[176]) );
   PP_MIDDLE PPM_264 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[190]) );
   PP_MIDDLE PPM_265 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[203]) );
   PP_MIDDLE PPM_266 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[218]) );
   PP_MIDDLE PPM_267 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[232]) );
   PP_MIDDLE PPM_268 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[248]) );
   PP_MIDDLE PPM_269 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[263]) );
   PP_MIDDLE PPM_270 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[280]) );
   PP_MIDDLE PPM_271 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[296]) );
   PP_MIDDLE PPM_272 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[313]) );
   PP_MIDDLE PPM_273 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[329]) );
   PP_MIDDLE PPM_274 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[344]) );
   PP_MIDDLE PPM_275 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[359]) );
   PP_MIDDLE PPM_276 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[373]) );
   PP_MIDDLE PPM_277 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[387]) );
   PP_MIDDLE PPM_278 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[400]) );
   PP_MIDDLE PPM_279 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[413]) );
   PP_MIDDLE PPM_280 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[425]) );
   PP_MIDDLE PPM_281 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[437]) );
   PP_MIDDLE PPM_282 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[448]) );
   PP_MIDDLE PPM_283 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[459]) );
   PP_MIDDLE PPM_284 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[469]) );
   PP_MIDDLE PPM_285 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[479]) );
   PP_MIDDLE PPM_286 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[488]) );
   PP_MIDDLE PPM_287 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[496]) );
   assign SUMMAND[497] = LOGIC_ONE;
   PP_HIGH PPH_8 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[32]) , .TWONEG (INT_MULTIPLIER[33]) , .ONEPOS (INT_MULTIPLIER[34]) , .ONENEG (INT_MULTIPLIER[35]) , .PPBIT (SUMMAND[505]) );
   DECODER DEC_9 (.INA (OPB[17]) , .INB (OPB[18]) , .INC (OPB[19]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) );
   PP_LOW PPL_9 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[108]) );
   R_GATE RGATE_9 (.INA (OPB[17]) , .INB (OPB[18]) , .INC (OPB[19]) , .PPBIT (SUMMAND[109]) );
   PP_MIDDLE PPM_288 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[119]) );
   PP_MIDDLE PPM_289 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[129]) );
   PP_MIDDLE PPM_290 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[141]) );
   PP_MIDDLE PPM_291 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[152]) );
   PP_MIDDLE PPM_292 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[165]) );
   PP_MIDDLE PPM_293 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[177]) );
   PP_MIDDLE PPM_294 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[191]) );
   PP_MIDDLE PPM_295 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[204]) );
   PP_MIDDLE PPM_296 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[219]) );
   PP_MIDDLE PPM_297 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[233]) );
   PP_MIDDLE PPM_298 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[249]) );
   PP_MIDDLE PPM_299 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[264]) );
   PP_MIDDLE PPM_300 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[281]) );
   PP_MIDDLE PPM_301 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[297]) );
   PP_MIDDLE PPM_302 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[314]) );
   PP_MIDDLE PPM_303 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[330]) );
   PP_MIDDLE PPM_304 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[345]) );
   PP_MIDDLE PPM_305 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[360]) );
   PP_MIDDLE PPM_306 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[374]) );
   PP_MIDDLE PPM_307 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[388]) );
   PP_MIDDLE PPM_308 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[401]) );
   PP_MIDDLE PPM_309 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[414]) );
   PP_MIDDLE PPM_310 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[426]) );
   PP_MIDDLE PPM_311 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[438]) );
   PP_MIDDLE PPM_312 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[449]) );
   PP_MIDDLE PPM_313 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[460]) );
   PP_MIDDLE PPM_314 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[470]) );
   PP_MIDDLE PPM_315 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[480]) );
   PP_MIDDLE PPM_316 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[489]) );
   PP_MIDDLE PPM_317 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[498]) );
   PP_MIDDLE PPM_318 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[506]) );
   PP_MIDDLE PPM_319 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[513]) );
   assign SUMMAND[514] = LOGIC_ONE;
   PP_HIGH PPH_9 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[36]) , .TWONEG (INT_MULTIPLIER[37]) , .ONEPOS (INT_MULTIPLIER[38]) , .ONENEG (INT_MULTIPLIER[39]) , .PPBIT (SUMMAND[521]) );
   DECODER DEC_10 (.INA (OPB[19]) , .INB (OPB[20]) , .INC (OPB[21]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) );
   PP_LOW PPL_10 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[130]) );
   R_GATE RGATE_10 (.INA (OPB[19]) , .INB (OPB[20]) , .INC (OPB[21]) , .PPBIT (SUMMAND[131]) );
   PP_MIDDLE PPM_320 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[142]) );
   PP_MIDDLE PPM_321 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[153]) );
   PP_MIDDLE PPM_322 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[166]) );
   PP_MIDDLE PPM_323 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[178]) );
   PP_MIDDLE PPM_324 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[192]) );
   PP_MIDDLE PPM_325 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[205]) );
   PP_MIDDLE PPM_326 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[220]) );
   PP_MIDDLE PPM_327 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[234]) );
   PP_MIDDLE PPM_328 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[250]) );
   PP_MIDDLE PPM_329 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[265]) );
   PP_MIDDLE PPM_330 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[282]) );
   PP_MIDDLE PPM_331 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[298]) );
   PP_MIDDLE PPM_332 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[315]) );
   PP_MIDDLE PPM_333 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[331]) );
   PP_MIDDLE PPM_334 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[346]) );
   PP_MIDDLE PPM_335 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[361]) );
   PP_MIDDLE PPM_336 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[375]) );
   PP_MIDDLE PPM_337 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[389]) );
   PP_MIDDLE PPM_338 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[402]) );
   PP_MIDDLE PPM_339 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[415]) );
   PP_MIDDLE PPM_340 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[427]) );
   PP_MIDDLE PPM_341 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[439]) );
   PP_MIDDLE PPM_342 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[450]) );
   PP_MIDDLE PPM_343 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[461]) );
   PP_MIDDLE PPM_344 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[471]) );
   PP_MIDDLE PPM_345 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[481]) );
   PP_MIDDLE PPM_346 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[490]) );
   PP_MIDDLE PPM_347 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[499]) );
   PP_MIDDLE PPM_348 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[507]) );
   PP_MIDDLE PPM_349 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[515]) );
   PP_MIDDLE PPM_350 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[522]) );
   PP_MIDDLE PPM_351 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[528]) );
   assign SUMMAND[529] = LOGIC_ONE;
   PP_HIGH PPH_10 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[40]) , .TWONEG (INT_MULTIPLIER[41]) , .ONEPOS (INT_MULTIPLIER[42]) , .ONENEG (INT_MULTIPLIER[43]) , .PPBIT (SUMMAND[535]) );
   DECODER DEC_11 (.INA (OPB[21]) , .INB (OPB[22]) , .INC (OPB[23]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) );
   PP_LOW PPL_11 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[154]) );
   R_GATE RGATE_11 (.INA (OPB[21]) , .INB (OPB[22]) , .INC (OPB[23]) , .PPBIT (SUMMAND[155]) );
   PP_MIDDLE PPM_352 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[167]) );
   PP_MIDDLE PPM_353 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[179]) );
   PP_MIDDLE PPM_354 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[193]) );
   PP_MIDDLE PPM_355 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[206]) );
   PP_MIDDLE PPM_356 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[221]) );
   PP_MIDDLE PPM_357 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[235]) );
   PP_MIDDLE PPM_358 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[251]) );
   PP_MIDDLE PPM_359 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[266]) );
   PP_MIDDLE PPM_360 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[283]) );
   PP_MIDDLE PPM_361 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[299]) );
   PP_MIDDLE PPM_362 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[316]) );
   PP_MIDDLE PPM_363 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[332]) );
   PP_MIDDLE PPM_364 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[347]) );
   PP_MIDDLE PPM_365 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[362]) );
   PP_MIDDLE PPM_366 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[376]) );
   PP_MIDDLE PPM_367 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[390]) );
   PP_MIDDLE PPM_368 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[403]) );
   PP_MIDDLE PPM_369 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[416]) );
   PP_MIDDLE PPM_370 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[428]) );
   PP_MIDDLE PPM_371 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[440]) );
   PP_MIDDLE PPM_372 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[451]) );
   PP_MIDDLE PPM_373 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[462]) );
   PP_MIDDLE PPM_374 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[472]) );
   PP_MIDDLE PPM_375 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[482]) );
   PP_MIDDLE PPM_376 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[491]) );
   PP_MIDDLE PPM_377 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[500]) );
   PP_MIDDLE PPM_378 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[508]) );
   PP_MIDDLE PPM_379 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[516]) );
   PP_MIDDLE PPM_380 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[523]) );
   PP_MIDDLE PPM_381 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[530]) );
   PP_MIDDLE PPM_382 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[536]) );
   PP_MIDDLE PPM_383 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[541]) );
   assign SUMMAND[542] = LOGIC_ONE;
   PP_HIGH PPH_11 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[44]) , .TWONEG (INT_MULTIPLIER[45]) , .ONEPOS (INT_MULTIPLIER[46]) , .ONENEG (INT_MULTIPLIER[47]) , .PPBIT (SUMMAND[547]) );
   DECODER DEC_12 (.INA (OPB[23]) , .INB (OPB[24]) , .INC (OPB[25]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) );
   PP_LOW PPL_12 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[180]) );
   R_GATE RGATE_12 (.INA (OPB[23]) , .INB (OPB[24]) , .INC (OPB[25]) , .PPBIT (SUMMAND[181]) );
   PP_MIDDLE PPM_384 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[194]) );
   PP_MIDDLE PPM_385 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[207]) );
   PP_MIDDLE PPM_386 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[222]) );
   PP_MIDDLE PPM_387 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[236]) );
   PP_MIDDLE PPM_388 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[252]) );
   PP_MIDDLE PPM_389 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[267]) );
   PP_MIDDLE PPM_390 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[284]) );
   PP_MIDDLE PPM_391 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[300]) );
   PP_MIDDLE PPM_392 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[317]) );
   PP_MIDDLE PPM_393 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[333]) );
   PP_MIDDLE PPM_394 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[348]) );
   PP_MIDDLE PPM_395 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[363]) );
   PP_MIDDLE PPM_396 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[377]) );
   PP_MIDDLE PPM_397 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[391]) );
   PP_MIDDLE PPM_398 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[404]) );
   PP_MIDDLE PPM_399 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[417]) );
   PP_MIDDLE PPM_400 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[429]) );
   PP_MIDDLE PPM_401 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[441]) );
   PP_MIDDLE PPM_402 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[452]) );
   PP_MIDDLE PPM_403 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[463]) );
   PP_MIDDLE PPM_404 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[473]) );
   PP_MIDDLE PPM_405 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[483]) );
   PP_MIDDLE PPM_406 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[492]) );
   PP_MIDDLE PPM_407 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[501]) );
   PP_MIDDLE PPM_408 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[509]) );
   PP_MIDDLE PPM_409 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[517]) );
   PP_MIDDLE PPM_410 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[524]) );
   PP_MIDDLE PPM_411 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[531]) );
   PP_MIDDLE PPM_412 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[537]) );
   PP_MIDDLE PPM_413 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[543]) );
   PP_MIDDLE PPM_414 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[548]) );
   PP_MIDDLE PPM_415 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[552]) );
   assign SUMMAND[553] = LOGIC_ONE;
   PP_HIGH PPH_12 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[48]) , .TWONEG (INT_MULTIPLIER[49]) , .ONEPOS (INT_MULTIPLIER[50]) , .ONENEG (INT_MULTIPLIER[51]) , .PPBIT (SUMMAND[557]) );
   DECODER DEC_13 (.INA (OPB[25]) , .INB (OPB[26]) , .INC (OPB[27]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) );
   PP_LOW PPL_13 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[208]) );
   R_GATE RGATE_13 (.INA (OPB[25]) , .INB (OPB[26]) , .INC (OPB[27]) , .PPBIT (SUMMAND[209]) );
   PP_MIDDLE PPM_416 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[223]) );
   PP_MIDDLE PPM_417 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[237]) );
   PP_MIDDLE PPM_418 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[253]) );
   PP_MIDDLE PPM_419 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[268]) );
   PP_MIDDLE PPM_420 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[285]) );
   PP_MIDDLE PPM_421 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[301]) );
   PP_MIDDLE PPM_422 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[318]) );
   PP_MIDDLE PPM_423 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[334]) );
   PP_MIDDLE PPM_424 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[349]) );
   PP_MIDDLE PPM_425 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[364]) );
   PP_MIDDLE PPM_426 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[378]) );
   PP_MIDDLE PPM_427 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[392]) );
   PP_MIDDLE PPM_428 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[405]) );
   PP_MIDDLE PPM_429 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[418]) );
   PP_MIDDLE PPM_430 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[430]) );
   PP_MIDDLE PPM_431 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[442]) );
   PP_MIDDLE PPM_432 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[453]) );
   PP_MIDDLE PPM_433 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[464]) );
   PP_MIDDLE PPM_434 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[474]) );
   PP_MIDDLE PPM_435 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[484]) );
   PP_MIDDLE PPM_436 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[493]) );
   PP_MIDDLE PPM_437 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[502]) );
   PP_MIDDLE PPM_438 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[510]) );
   PP_MIDDLE PPM_439 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[518]) );
   PP_MIDDLE PPM_440 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[525]) );
   PP_MIDDLE PPM_441 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[532]) );
   PP_MIDDLE PPM_442 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[538]) );
   PP_MIDDLE PPM_443 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[544]) );
   PP_MIDDLE PPM_444 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[549]) );
   PP_MIDDLE PPM_445 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[554]) );
   PP_MIDDLE PPM_446 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[558]) );
   PP_MIDDLE PPM_447 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[561]) );
   assign SUMMAND[562] = LOGIC_ONE;
   PP_HIGH PPH_13 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[52]) , .TWONEG (INT_MULTIPLIER[53]) , .ONEPOS (INT_MULTIPLIER[54]) , .ONENEG (INT_MULTIPLIER[55]) , .PPBIT (SUMMAND[565]) );
   DECODER DEC_14 (.INA (OPB[27]) , .INB (OPB[28]) , .INC (OPB[29]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) );
   PP_LOW PPL_14 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[238]) );
   R_GATE RGATE_14 (.INA (OPB[27]) , .INB (OPB[28]) , .INC (OPB[29]) , .PPBIT (SUMMAND[239]) );
   PP_MIDDLE PPM_448 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[254]) );
   PP_MIDDLE PPM_449 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[269]) );
   PP_MIDDLE PPM_450 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[286]) );
   PP_MIDDLE PPM_451 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[302]) );
   PP_MIDDLE PPM_452 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[319]) );
   PP_MIDDLE PPM_453 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[335]) );
   PP_MIDDLE PPM_454 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[350]) );
   PP_MIDDLE PPM_455 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[365]) );
   PP_MIDDLE PPM_456 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[379]) );
   PP_MIDDLE PPM_457 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[393]) );
   PP_MIDDLE PPM_458 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[406]) );
   PP_MIDDLE PPM_459 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[419]) );
   PP_MIDDLE PPM_460 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[431]) );
   PP_MIDDLE PPM_461 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[443]) );
   PP_MIDDLE PPM_462 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[454]) );
   PP_MIDDLE PPM_463 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[465]) );
   PP_MIDDLE PPM_464 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[475]) );
   PP_MIDDLE PPM_465 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[485]) );
   PP_MIDDLE PPM_466 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[494]) );
   PP_MIDDLE PPM_467 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[503]) );
   PP_MIDDLE PPM_468 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[511]) );
   PP_MIDDLE PPM_469 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[519]) );
   PP_MIDDLE PPM_470 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[526]) );
   PP_MIDDLE PPM_471 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[533]) );
   PP_MIDDLE PPM_472 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[539]) );
   PP_MIDDLE PPM_473 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[545]) );
   PP_MIDDLE PPM_474 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[550]) );
   PP_MIDDLE PPM_475 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[555]) );
   PP_MIDDLE PPM_476 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[559]) );
   PP_MIDDLE PPM_477 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[563]) );
   PP_MIDDLE PPM_478 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[566]) );
   PP_MIDDLE PPM_479 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[568]) );
   assign SUMMAND[569] = LOGIC_ONE;
   PP_HIGH PPH_14 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[56]) , .TWONEG (INT_MULTIPLIER[57]) , .ONEPOS (INT_MULTIPLIER[58]) , .ONENEG (INT_MULTIPLIER[59]) , .PPBIT (SUMMAND[571]) );
   DECODER DEC_15 (.INA (OPB[29]) , .INB (OPB[30]) , .INC (OPB[31]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) );
   PP_LOW PPL_15 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[270]) );
   R_GATE RGATE_15 (.INA (OPB[29]) , .INB (OPB[30]) , .INC (OPB[31]) , .PPBIT (SUMMAND[271]) );
   PP_MIDDLE PPM_480 (.INA (OPA[0]) , .INB (INV_MULTIPLICAND[0]) , .INC (OPA[1]) , .IND (INV_MULTIPLICAND[1]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[287]) );
   PP_MIDDLE PPM_481 (.INA (OPA[1]) , .INB (INV_MULTIPLICAND[1]) , .INC (OPA[2]) , .IND (INV_MULTIPLICAND[2]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[303]) );
   PP_MIDDLE PPM_482 (.INA (OPA[2]) , .INB (INV_MULTIPLICAND[2]) , .INC (OPA[3]) , .IND (INV_MULTIPLICAND[3]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[320]) );
   PP_MIDDLE PPM_483 (.INA (OPA[3]) , .INB (INV_MULTIPLICAND[3]) , .INC (OPA[4]) , .IND (INV_MULTIPLICAND[4]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[336]) );
   PP_MIDDLE PPM_484 (.INA (OPA[4]) , .INB (INV_MULTIPLICAND[4]) , .INC (OPA[5]) , .IND (INV_MULTIPLICAND[5]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[351]) );
   PP_MIDDLE PPM_485 (.INA (OPA[5]) , .INB (INV_MULTIPLICAND[5]) , .INC (OPA[6]) , .IND (INV_MULTIPLICAND[6]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[366]) );
   PP_MIDDLE PPM_486 (.INA (OPA[6]) , .INB (INV_MULTIPLICAND[6]) , .INC (OPA[7]) , .IND (INV_MULTIPLICAND[7]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[380]) );
   PP_MIDDLE PPM_487 (.INA (OPA[7]) , .INB (INV_MULTIPLICAND[7]) , .INC (OPA[8]) , .IND (INV_MULTIPLICAND[8]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[394]) );
   PP_MIDDLE PPM_488 (.INA (OPA[8]) , .INB (INV_MULTIPLICAND[8]) , .INC (OPA[9]) , .IND (INV_MULTIPLICAND[9]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[407]) );
   PP_MIDDLE PPM_489 (.INA (OPA[9]) , .INB (INV_MULTIPLICAND[9]) , .INC (OPA[10]) , .IND (INV_MULTIPLICAND[10]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[420]) );
   PP_MIDDLE PPM_490 (.INA (OPA[10]) , .INB (INV_MULTIPLICAND[10]) , .INC (OPA[11]) , .IND (INV_MULTIPLICAND[11]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[432]) );
   PP_MIDDLE PPM_491 (.INA (OPA[11]) , .INB (INV_MULTIPLICAND[11]) , .INC (OPA[12]) , .IND (INV_MULTIPLICAND[12]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[444]) );
   PP_MIDDLE PPM_492 (.INA (OPA[12]) , .INB (INV_MULTIPLICAND[12]) , .INC (OPA[13]) , .IND (INV_MULTIPLICAND[13]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[455]) );
   PP_MIDDLE PPM_493 (.INA (OPA[13]) , .INB (INV_MULTIPLICAND[13]) , .INC (OPA[14]) , .IND (INV_MULTIPLICAND[14]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[466]) );
   PP_MIDDLE PPM_494 (.INA (OPA[14]) , .INB (INV_MULTIPLICAND[14]) , .INC (OPA[15]) , .IND (INV_MULTIPLICAND[15]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[476]) );
   PP_MIDDLE PPM_495 (.INA (OPA[15]) , .INB (INV_MULTIPLICAND[15]) , .INC (OPA[16]) , .IND (INV_MULTIPLICAND[16]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[486]) );
   PP_MIDDLE PPM_496 (.INA (OPA[16]) , .INB (INV_MULTIPLICAND[16]) , .INC (OPA[17]) , .IND (INV_MULTIPLICAND[17]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[495]) );
   PP_MIDDLE PPM_497 (.INA (OPA[17]) , .INB (INV_MULTIPLICAND[17]) , .INC (OPA[18]) , .IND (INV_MULTIPLICAND[18]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[504]) );
   PP_MIDDLE PPM_498 (.INA (OPA[18]) , .INB (INV_MULTIPLICAND[18]) , .INC (OPA[19]) , .IND (INV_MULTIPLICAND[19]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[512]) );
   PP_MIDDLE PPM_499 (.INA (OPA[19]) , .INB (INV_MULTIPLICAND[19]) , .INC (OPA[20]) , .IND (INV_MULTIPLICAND[20]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[520]) );
   PP_MIDDLE PPM_500 (.INA (OPA[20]) , .INB (INV_MULTIPLICAND[20]) , .INC (OPA[21]) , .IND (INV_MULTIPLICAND[21]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[527]) );
   PP_MIDDLE PPM_501 (.INA (OPA[21]) , .INB (INV_MULTIPLICAND[21]) , .INC (OPA[22]) , .IND (INV_MULTIPLICAND[22]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[534]) );
   PP_MIDDLE PPM_502 (.INA (OPA[22]) , .INB (INV_MULTIPLICAND[22]) , .INC (OPA[23]) , .IND (INV_MULTIPLICAND[23]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[540]) );
   PP_MIDDLE PPM_503 (.INA (OPA[23]) , .INB (INV_MULTIPLICAND[23]) , .INC (OPA[24]) , .IND (INV_MULTIPLICAND[24]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[546]) );
   PP_MIDDLE PPM_504 (.INA (OPA[24]) , .INB (INV_MULTIPLICAND[24]) , .INC (OPA[25]) , .IND (INV_MULTIPLICAND[25]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[551]) );
   PP_MIDDLE PPM_505 (.INA (OPA[25]) , .INB (INV_MULTIPLICAND[25]) , .INC (OPA[26]) , .IND (INV_MULTIPLICAND[26]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[556]) );
   PP_MIDDLE PPM_506 (.INA (OPA[26]) , .INB (INV_MULTIPLICAND[26]) , .INC (OPA[27]) , .IND (INV_MULTIPLICAND[27]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[560]) );
   PP_MIDDLE PPM_507 (.INA (OPA[27]) , .INB (INV_MULTIPLICAND[27]) , .INC (OPA[28]) , .IND (INV_MULTIPLICAND[28]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[564]) );
   PP_MIDDLE PPM_508 (.INA (OPA[28]) , .INB (INV_MULTIPLICAND[28]) , .INC (OPA[29]) , .IND (INV_MULTIPLICAND[29]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[567]) );
   PP_MIDDLE PPM_509 (.INA (OPA[29]) , .INB (INV_MULTIPLICAND[29]) , .INC (OPA[30]) , .IND (INV_MULTIPLICAND[30]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[570]) );
   PP_MIDDLE PPM_510 (.INA (OPA[30]) , .INB (INV_MULTIPLICAND[30]) , .INC (OPA[31]) , .IND (INV_MULTIPLICAND[31]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[572]) );
   PP_MIDDLE PPM_511 (.INA (OPA[31]) , .INB (INV_MULTIPLICAND[31]) , .INC (OPA[32]) , .IND (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[573]) );
   assign SUMMAND[574] = LOGIC_ONE;
   PP_HIGH PPH_15 (.INA (OPA[32]) , .INB (INV_MULTIPLICAND[32]) , .TWOPOS (INT_MULTIPLIER[60]) , .TWONEG (INT_MULTIPLIER[61]) , .ONEPOS (INT_MULTIPLIER[62]) , .ONENEG (INT_MULTIPLIER[63]) , .PPBIT (SUMMAND[575]) );
endmodule


module FULL_ADDER ( DATA_A, DATA_B, DATA_C, SAVE, CARRY );
input  DATA_A;
input  DATA_B;
input  DATA_C;
output SAVE;
output CARRY;
   wire TMP;
   assign TMP = DATA_A ^ DATA_B;
   assign SAVE = TMP ^ DATA_C;
   assign CARRY =  ~ (( ~ (TMP & DATA_C)) & ( ~ (DATA_A & DATA_B)));
endmodule


module HALF_ADDER ( DATA_A, DATA_B, SAVE, CARRY );
input  DATA_A;
input  DATA_B;
output SAVE;
output CARRY;
   assign SAVE = DATA_A ^ DATA_B;
   assign CARRY = DATA_A & DATA_B;
endmodule


module FLIPFLOP ( DIN, RST, CLK, DOUT );
input  DIN;
input  RST;
input  CLK;
output DOUT;
   reg DOUT_reg;
   always @ ( posedge RST or posedge CLK ) begin
      if (RST)
        DOUT_reg <= 1'b0;
      else
        DOUT_reg <= #1 DIN;
   end
   assign DOUT = DOUT_reg;
endmodule


module WALLACE_33_32 ( SUMMAND, RST, CLK, CARRY, SUM );
input  [0:575] SUMMAND;
input  RST;
input  CLK;
output [0:62] CARRY;
output [0:63] SUM;
   wire [0:7] LATCHED_PP;
   wire [0:523] INT_CARRY;
   wire [0:669] INT_SUM;
   HALF_ADDER HA_0 (.DATA_A (SUMMAND[0]) , .DATA_B (SUMMAND[1]) , .SAVE (INT_SUM[0]) , .CARRY (INT_CARRY[0]) );
   FLIPFLOP LA_0 (.DIN (INT_SUM[0]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[0]) );
   FLIPFLOP LA_1 (.DIN (INT_CARRY[0]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[0]) );
   assign INT_SUM[1] = SUMMAND[2];
   assign CARRY[1] = 0;
   FLIPFLOP LA_2 (.DIN (INT_SUM[1]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[1]) );
   FULL_ADDER FA_0 (.DATA_A (SUMMAND[3]) , .DATA_B (SUMMAND[4]) , .DATA_C (SUMMAND[5]) , .SAVE (INT_SUM[2]) , .CARRY (INT_CARRY[1]) );
   FLIPFLOP LA_3 (.DIN (INT_SUM[2]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[2]) );
   FLIPFLOP LA_4 (.DIN (INT_CARRY[1]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[2]) );
   HALF_ADDER HA_1 (.DATA_A (SUMMAND[6]) , .DATA_B (SUMMAND[7]) , .SAVE (INT_SUM[3]) , .CARRY (INT_CARRY[2]) );
   FLIPFLOP LA_5 (.DIN (INT_SUM[3]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[3]) );
   FLIPFLOP LA_6 (.DIN (INT_CARRY[2]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[3]) );
   FULL_ADDER FA_1 (.DATA_A (SUMMAND[8]) , .DATA_B (SUMMAND[9]) , .DATA_C (SUMMAND[10]) , .SAVE (INT_SUM[4]) , .CARRY (INT_CARRY[4]) );
   assign INT_SUM[5] = SUMMAND[11];
   HALF_ADDER HA_2 (.DATA_A (INT_SUM[4]) , .DATA_B (INT_SUM[5]) , .SAVE (INT_SUM[6]) , .CARRY (INT_CARRY[3]) );
   FLIPFLOP LA_7 (.DIN (INT_SUM[6]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[4]) );
   FLIPFLOP LA_8 (.DIN (INT_CARRY[3]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[4]) );
   FULL_ADDER FA_2 (.DATA_A (SUMMAND[12]) , .DATA_B (SUMMAND[13]) , .DATA_C (SUMMAND[14]) , .SAVE (INT_SUM[7]) , .CARRY (INT_CARRY[6]) );
   HALF_ADDER HA_3 (.DATA_A (INT_SUM[7]) , .DATA_B (INT_CARRY[4]) , .SAVE (INT_SUM[8]) , .CARRY (INT_CARRY[5]) );
   FLIPFLOP LA_9 (.DIN (INT_SUM[8]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[5]) );
   FLIPFLOP LA_10 (.DIN (INT_CARRY[5]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[5]) );
   FULL_ADDER FA_3 (.DATA_A (SUMMAND[15]) , .DATA_B (SUMMAND[16]) , .DATA_C (SUMMAND[17]) , .SAVE (INT_SUM[9]) , .CARRY (INT_CARRY[8]) );
   HALF_ADDER HA_4 (.DATA_A (SUMMAND[18]) , .DATA_B (SUMMAND[19]) , .SAVE (INT_SUM[10]) , .CARRY (INT_CARRY[9]) );
   FULL_ADDER FA_4 (.DATA_A (INT_SUM[9]) , .DATA_B (INT_SUM[10]) , .DATA_C (INT_CARRY[6]) , .SAVE (INT_SUM[11]) , .CARRY (INT_CARRY[7]) );
   FLIPFLOP LA_11 (.DIN (INT_SUM[11]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[6]) );
   FLIPFLOP LA_12 (.DIN (INT_CARRY[7]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[6]) );
   FULL_ADDER FA_5 (.DATA_A (SUMMAND[20]) , .DATA_B (SUMMAND[21]) , .DATA_C (SUMMAND[22]) , .SAVE (INT_SUM[12]) , .CARRY (INT_CARRY[11]) );
   assign INT_SUM[13] = SUMMAND[23];
   FULL_ADDER FA_6 (.DATA_A (INT_SUM[12]) , .DATA_B (INT_SUM[13]) , .DATA_C (INT_CARRY[8]) , .SAVE (INT_SUM[14]) , .CARRY (INT_CARRY[12]) );
   assign INT_SUM[15] = INT_CARRY[9];
   HALF_ADDER HA_5 (.DATA_A (INT_SUM[14]) , .DATA_B (INT_SUM[15]) , .SAVE (INT_SUM[16]) , .CARRY (INT_CARRY[10]) );
   FLIPFLOP LA_13 (.DIN (INT_SUM[16]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[7]) );
   FLIPFLOP LA_14 (.DIN (INT_CARRY[10]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[7]) );
   FULL_ADDER FA_7 (.DATA_A (SUMMAND[24]) , .DATA_B (SUMMAND[25]) , .DATA_C (SUMMAND[26]) , .SAVE (INT_SUM[17]) , .CARRY (INT_CARRY[14]) );
   FULL_ADDER FA_8 (.DATA_A (SUMMAND[27]) , .DATA_B (SUMMAND[28]) , .DATA_C (SUMMAND[29]) , .SAVE (INT_SUM[18]) , .CARRY (INT_CARRY[15]) );
   FULL_ADDER FA_9 (.DATA_A (INT_SUM[17]) , .DATA_B (INT_SUM[18]) , .DATA_C (INT_CARRY[11]) , .SAVE (INT_SUM[19]) , .CARRY (INT_CARRY[16]) );
   HALF_ADDER HA_6 (.DATA_A (INT_SUM[19]) , .DATA_B (INT_CARRY[12]) , .SAVE (INT_SUM[20]) , .CARRY (INT_CARRY[13]) );
   FLIPFLOP LA_15 (.DIN (INT_SUM[20]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[8]) );
   FLIPFLOP LA_16 (.DIN (INT_CARRY[13]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[8]) );
   FULL_ADDER FA_10 (.DATA_A (SUMMAND[30]) , .DATA_B (SUMMAND[31]) , .DATA_C (SUMMAND[32]) , .SAVE (INT_SUM[21]) , .CARRY (INT_CARRY[18]) );
   HALF_ADDER HA_7 (.DATA_A (SUMMAND[33]) , .DATA_B (SUMMAND[34]) , .SAVE (INT_SUM[22]) , .CARRY (INT_CARRY[19]) );
   FULL_ADDER FA_11 (.DATA_A (INT_SUM[21]) , .DATA_B (INT_SUM[22]) , .DATA_C (INT_CARRY[14]) , .SAVE (INT_SUM[23]) , .CARRY (INT_CARRY[20]) );
   assign INT_SUM[24] = INT_CARRY[15];
   FULL_ADDER FA_12 (.DATA_A (INT_SUM[23]) , .DATA_B (INT_SUM[24]) , .DATA_C (INT_CARRY[16]) , .SAVE (INT_SUM[25]) , .CARRY (INT_CARRY[17]) );
   FLIPFLOP LA_17 (.DIN (INT_SUM[25]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[9]) );
   FLIPFLOP LA_18 (.DIN (INT_CARRY[17]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[9]) );
   FULL_ADDER FA_13 (.DATA_A (SUMMAND[35]) , .DATA_B (SUMMAND[36]) , .DATA_C (SUMMAND[37]) , .SAVE (INT_SUM[26]) , .CARRY (INT_CARRY[22]) );
   FULL_ADDER FA_14 (.DATA_A (SUMMAND[38]) , .DATA_B (SUMMAND[39]) , .DATA_C (SUMMAND[40]) , .SAVE (INT_SUM[27]) , .CARRY (INT_CARRY[23]) );
   assign INT_SUM[28] = SUMMAND[41];
   FULL_ADDER FA_15 (.DATA_A (INT_SUM[26]) , .DATA_B (INT_SUM[27]) , .DATA_C (INT_SUM[28]) , .SAVE (INT_SUM[29]) , .CARRY (INT_CARRY[24]) );
   HALF_ADDER HA_8 (.DATA_A (INT_CARRY[18]) , .DATA_B (INT_CARRY[19]) , .SAVE (INT_SUM[30]) , .CARRY (INT_CARRY[25]) );
   FULL_ADDER FA_16 (.DATA_A (INT_SUM[29]) , .DATA_B (INT_SUM[30]) , .DATA_C (INT_CARRY[20]) , .SAVE (INT_SUM[31]) , .CARRY (INT_CARRY[21]) );
   FLIPFLOP LA_19 (.DIN (INT_SUM[31]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[10]) );
   FLIPFLOP LA_20 (.DIN (INT_CARRY[21]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[10]) );
   FULL_ADDER FA_17 (.DATA_A (SUMMAND[42]) , .DATA_B (SUMMAND[43]) , .DATA_C (SUMMAND[44]) , .SAVE (INT_SUM[32]) , .CARRY (INT_CARRY[27]) );
   FULL_ADDER FA_18 (.DATA_A (SUMMAND[45]) , .DATA_B (SUMMAND[46]) , .DATA_C (SUMMAND[47]) , .SAVE (INT_SUM[33]) , .CARRY (INT_CARRY[28]) );
   FULL_ADDER FA_19 (.DATA_A (INT_SUM[32]) , .DATA_B (INT_SUM[33]) , .DATA_C (INT_CARRY[22]) , .SAVE (INT_SUM[34]) , .CARRY (INT_CARRY[29]) );
   assign INT_SUM[35] = INT_CARRY[23];
   FULL_ADDER FA_20 (.DATA_A (INT_SUM[34]) , .DATA_B (INT_SUM[35]) , .DATA_C (INT_CARRY[24]) , .SAVE (INT_SUM[36]) , .CARRY (INT_CARRY[30]) );
   assign INT_SUM[37] = INT_CARRY[25];
   HALF_ADDER HA_9 (.DATA_A (INT_SUM[36]) , .DATA_B (INT_SUM[37]) , .SAVE (INT_SUM[38]) , .CARRY (INT_CARRY[26]) );
   FLIPFLOP LA_21 (.DIN (INT_SUM[38]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[11]) );
   FLIPFLOP LA_22 (.DIN (INT_CARRY[26]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[11]) );
   FULL_ADDER FA_21 (.DATA_A (SUMMAND[48]) , .DATA_B (SUMMAND[49]) , .DATA_C (SUMMAND[50]) , .SAVE (INT_SUM[39]) , .CARRY (INT_CARRY[32]) );
   FULL_ADDER FA_22 (.DATA_A (SUMMAND[51]) , .DATA_B (SUMMAND[52]) , .DATA_C (SUMMAND[53]) , .SAVE (INT_SUM[40]) , .CARRY (INT_CARRY[33]) );
   assign INT_SUM[41] = SUMMAND[54];
   assign INT_SUM[42] = SUMMAND[55];
   FULL_ADDER FA_23 (.DATA_A (INT_SUM[39]) , .DATA_B (INT_SUM[40]) , .DATA_C (INT_SUM[41]) , .SAVE (INT_SUM[43]) , .CARRY (INT_CARRY[34]) );
   FULL_ADDER FA_24 (.DATA_A (INT_SUM[42]) , .DATA_B (INT_CARRY[27]) , .DATA_C (INT_CARRY[28]) , .SAVE (INT_SUM[44]) , .CARRY (INT_CARRY[35]) );
   FULL_ADDER FA_25 (.DATA_A (INT_SUM[43]) , .DATA_B (INT_SUM[44]) , .DATA_C (INT_CARRY[29]) , .SAVE (INT_SUM[45]) , .CARRY (INT_CARRY[36]) );
   HALF_ADDER HA_10 (.DATA_A (INT_SUM[45]) , .DATA_B (INT_CARRY[30]) , .SAVE (INT_SUM[46]) , .CARRY (INT_CARRY[31]) );
   FLIPFLOP LA_23 (.DIN (INT_SUM[46]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[12]) );
   FLIPFLOP LA_24 (.DIN (INT_CARRY[31]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[12]) );
   FULL_ADDER FA_26 (.DATA_A (SUMMAND[56]) , .DATA_B (SUMMAND[57]) , .DATA_C (SUMMAND[58]) , .SAVE (INT_SUM[47]) , .CARRY (INT_CARRY[38]) );
   FULL_ADDER FA_27 (.DATA_A (SUMMAND[59]) , .DATA_B (SUMMAND[60]) , .DATA_C (SUMMAND[61]) , .SAVE (INT_SUM[48]) , .CARRY (INT_CARRY[39]) );
   assign INT_SUM[49] = SUMMAND[62];
   FULL_ADDER FA_28 (.DATA_A (INT_SUM[47]) , .DATA_B (INT_SUM[48]) , .DATA_C (INT_SUM[49]) , .SAVE (INT_SUM[50]) , .CARRY (INT_CARRY[40]) );
   HALF_ADDER HA_11 (.DATA_A (INT_CARRY[32]) , .DATA_B (INT_CARRY[33]) , .SAVE (INT_SUM[51]) , .CARRY (INT_CARRY[41]) );
   FULL_ADDER FA_29 (.DATA_A (INT_SUM[50]) , .DATA_B (INT_SUM[51]) , .DATA_C (INT_CARRY[34]) , .SAVE (INT_SUM[52]) , .CARRY (INT_CARRY[42]) );
   assign INT_SUM[53] = INT_CARRY[35];
   FULL_ADDER FA_30 (.DATA_A (INT_SUM[52]) , .DATA_B (INT_SUM[53]) , .DATA_C (INT_CARRY[36]) , .SAVE (INT_SUM[54]) , .CARRY (INT_CARRY[37]) );
   FLIPFLOP LA_25 (.DIN (INT_SUM[54]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[13]) );
   FLIPFLOP LA_26 (.DIN (INT_CARRY[37]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[13]) );
   FULL_ADDER FA_31 (.DATA_A (SUMMAND[63]) , .DATA_B (SUMMAND[64]) , .DATA_C (SUMMAND[65]) , .SAVE (INT_SUM[55]) , .CARRY (INT_CARRY[44]) );
   FULL_ADDER FA_32 (.DATA_A (SUMMAND[66]) , .DATA_B (SUMMAND[67]) , .DATA_C (SUMMAND[68]) , .SAVE (INT_SUM[56]) , .CARRY (INT_CARRY[45]) );
   FULL_ADDER FA_33 (.DATA_A (SUMMAND[69]) , .DATA_B (SUMMAND[70]) , .DATA_C (SUMMAND[71]) , .SAVE (INT_SUM[57]) , .CARRY (INT_CARRY[46]) );
   FULL_ADDER FA_34 (.DATA_A (INT_SUM[55]) , .DATA_B (INT_SUM[56]) , .DATA_C (INT_SUM[57]) , .SAVE (INT_SUM[58]) , .CARRY (INT_CARRY[47]) );
   HALF_ADDER HA_12 (.DATA_A (INT_CARRY[38]) , .DATA_B (INT_CARRY[39]) , .SAVE (INT_SUM[59]) , .CARRY (INT_CARRY[48]) );
   FULL_ADDER FA_35 (.DATA_A (INT_SUM[58]) , .DATA_B (INT_SUM[59]) , .DATA_C (INT_CARRY[40]) , .SAVE (INT_SUM[60]) , .CARRY (INT_CARRY[49]) );
   assign INT_SUM[61] = INT_CARRY[41];
   FULL_ADDER FA_36 (.DATA_A (INT_SUM[60]) , .DATA_B (INT_SUM[61]) , .DATA_C (INT_CARRY[42]) , .SAVE (INT_SUM[62]) , .CARRY (INT_CARRY[43]) );
   FLIPFLOP LA_27 (.DIN (INT_SUM[62]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[14]) );
   FLIPFLOP LA_28 (.DIN (INT_CARRY[43]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[14]) );
   FULL_ADDER FA_37 (.DATA_A (SUMMAND[72]) , .DATA_B (SUMMAND[73]) , .DATA_C (SUMMAND[74]) , .SAVE (INT_SUM[63]) , .CARRY (INT_CARRY[51]) );
   FULL_ADDER FA_38 (.DATA_A (SUMMAND[75]) , .DATA_B (SUMMAND[76]) , .DATA_C (SUMMAND[77]) , .SAVE (INT_SUM[64]) , .CARRY (INT_CARRY[52]) );
   HALF_ADDER HA_13 (.DATA_A (SUMMAND[78]) , .DATA_B (SUMMAND[79]) , .SAVE (INT_SUM[65]) , .CARRY (INT_CARRY[53]) );
   FULL_ADDER FA_39 (.DATA_A (INT_SUM[63]) , .DATA_B (INT_SUM[64]) , .DATA_C (INT_SUM[65]) , .SAVE (INT_SUM[66]) , .CARRY (INT_CARRY[54]) );
   FULL_ADDER FA_40 (.DATA_A (INT_CARRY[44]) , .DATA_B (INT_CARRY[45]) , .DATA_C (INT_CARRY[46]) , .SAVE (INT_SUM[67]) , .CARRY (INT_CARRY[55]) );
   FULL_ADDER FA_41 (.DATA_A (INT_SUM[66]) , .DATA_B (INT_SUM[67]) , .DATA_C (INT_CARRY[47]) , .SAVE (INT_SUM[68]) , .CARRY (INT_CARRY[56]) );
   assign INT_SUM[69] = INT_CARRY[48];
   FULL_ADDER FA_42 (.DATA_A (INT_SUM[68]) , .DATA_B (INT_SUM[69]) , .DATA_C (INT_CARRY[49]) , .SAVE (INT_SUM[70]) , .CARRY (INT_CARRY[50]) );
   FLIPFLOP LA_29 (.DIN (INT_SUM[70]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[15]) );
   FLIPFLOP LA_30 (.DIN (INT_CARRY[50]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[15]) );
   FULL_ADDER FA_43 (.DATA_A (SUMMAND[80]) , .DATA_B (SUMMAND[81]) , .DATA_C (SUMMAND[82]) , .SAVE (INT_SUM[71]) , .CARRY (INT_CARRY[58]) );
   FULL_ADDER FA_44 (.DATA_A (SUMMAND[83]) , .DATA_B (SUMMAND[84]) , .DATA_C (SUMMAND[85]) , .SAVE (INT_SUM[72]) , .CARRY (INT_CARRY[59]) );
   FULL_ADDER FA_45 (.DATA_A (SUMMAND[86]) , .DATA_B (SUMMAND[87]) , .DATA_C (SUMMAND[88]) , .SAVE (INT_SUM[73]) , .CARRY (INT_CARRY[60]) );
   assign INT_SUM[74] = SUMMAND[89];
   FULL_ADDER FA_46 (.DATA_A (INT_SUM[71]) , .DATA_B (INT_SUM[72]) , .DATA_C (INT_SUM[73]) , .SAVE (INT_SUM[75]) , .CARRY (INT_CARRY[61]) );
   FULL_ADDER FA_47 (.DATA_A (INT_SUM[74]) , .DATA_B (INT_CARRY[51]) , .DATA_C (INT_CARRY[52]) , .SAVE (INT_SUM[76]) , .CARRY (INT_CARRY[62]) );
   assign INT_SUM[77] = INT_CARRY[53];
   FULL_ADDER FA_48 (.DATA_A (INT_SUM[75]) , .DATA_B (INT_SUM[76]) , .DATA_C (INT_SUM[77]) , .SAVE (INT_SUM[78]) , .CARRY (INT_CARRY[63]) );
   HALF_ADDER HA_14 (.DATA_A (INT_CARRY[54]) , .DATA_B (INT_CARRY[55]) , .SAVE (INT_SUM[79]) , .CARRY (INT_CARRY[64]) );
   FULL_ADDER FA_49 (.DATA_A (INT_SUM[78]) , .DATA_B (INT_SUM[79]) , .DATA_C (INT_CARRY[56]) , .SAVE (INT_SUM[80]) , .CARRY (INT_CARRY[57]) );
   FLIPFLOP LA_31 (.DIN (INT_SUM[80]) , .RST(RST), .CLK (CLK) , .DOUT (SUM[16]) );
   FLIPFLOP LA_32 (.DIN (INT_CARRY[57]) , .RST(RST), .CLK (CLK) , .DOUT (CARRY[16]) );
   FULL_ADDER FA_50 (.DATA_A (SUMMAND[90]) , .DATA_B (SUMMAND[91]) , .DATA_C (SUMMAND[92]) , .SAVE (INT_SUM[81]) , .CARRY (INT_CARRY[65]) );
   FULL_ADDER FA_51 (.DATA_A (SUMMAND[93]) , .DATA_B (SUMMAND[94]) , .DATA_C (SUMMAND[95]) , .SAVE (INT_SUM[82]) , .CARRY (INT_CARRY[66]) );
   FULL_ADDER FA_52 (.DATA_A (SUMMAND[96]) , .DATA_B (SUMMAND[97]) , .DATA_C (SUMMAND[98]) , .SAVE (INT_SUM[83]) , .CARRY (INT_CARRY[67]) );
   FULL_ADDER FA_53 (.DATA_A (INT_SUM[81]) , .DATA_B (INT_SUM[82]) , .DATA_C (INT_SUM[83]) , .SAVE (INT_SUM[84]) , .CARRY (INT_CARRY[68]) );
   FULL_ADDER FA_54 (.DATA_A (INT_CARRY[58]) , .DATA_B (INT_CARRY[59]) , .DATA_C (INT_CARRY[60]) , .SAVE (INT_SUM[85]) , .CARRY (INT_CARRY[69]) );
   FULL_ADDER FA_55 (.DATA_A (INT_SUM[84]) , .DATA_B (INT_SUM[85]) , .DATA_C (INT_CARRY[61]) , .SAVE (INT_SUM[86]) , .CARRY (INT_CARRY[70]) );
   assign INT_SUM[87] = INT_CARRY[62];
   FULL_ADDER FA_56 (.DATA_A (INT_SUM[86]) , .DATA_B (INT_SUM[87]) , .DATA_C (INT_CARRY[63]) , .SAVE (INT_SUM[88]) , .CARRY (INT_CARRY[71]) );
   assign INT_SUM[90] = INT_CARRY[64];
   FLIPFLOP LA_33 (.DIN (INT_SUM[88]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[89]) );
   FLIPFLOP LA_34 (.DIN (INT_SUM[90]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[91]) );
   HALF_ADDER HA_15 (.DATA_A (INT_SUM[89]) , .DATA_B (INT_SUM[91]) , .SAVE (SUM[17]) , .CARRY (CARRY[17]) );
   FULL_ADDER FA_57 (.DATA_A (SUMMAND[99]) , .DATA_B (SUMMAND[100]) , .DATA_C (SUMMAND[101]) , .SAVE (INT_SUM[92]) , .CARRY (INT_CARRY[73]) );
   FULL_ADDER FA_58 (.DATA_A (SUMMAND[102]) , .DATA_B (SUMMAND[103]) , .DATA_C (SUMMAND[104]) , .SAVE (INT_SUM[93]) , .CARRY (INT_CARRY[74]) );
   FULL_ADDER FA_59 (.DATA_A (SUMMAND[105]) , .DATA_B (SUMMAND[106]) , .DATA_C (SUMMAND[107]) , .SAVE (INT_SUM[94]) , .CARRY (INT_CARRY[75]) );
   assign INT_SUM[95] = SUMMAND[108];
   assign INT_SUM[96] = SUMMAND[109];
   FULL_ADDER FA_60 (.DATA_A (INT_SUM[92]) , .DATA_B (INT_SUM[93]) , .DATA_C (INT_SUM[94]) , .SAVE (INT_SUM[97]) , .CARRY (INT_CARRY[76]) );
   FULL_ADDER FA_61 (.DATA_A (INT_SUM[95]) , .DATA_B (INT_SUM[96]) , .DATA_C (INT_CARRY[65]) , .SAVE (INT_SUM[98]) , .CARRY (INT_CARRY[77]) );
   assign INT_SUM[99] = INT_CARRY[66];
   assign INT_SUM[100] = INT_CARRY[67];
   FULL_ADDER FA_62 (.DATA_A (INT_SUM[97]) , .DATA_B (INT_SUM[98]) , .DATA_C (INT_SUM[99]) , .SAVE (INT_SUM[101]) , .CARRY (INT_CARRY[78]) );
   FULL_ADDER FA_63 (.DATA_A (INT_SUM[100]) , .DATA_B (INT_CARRY[68]) , .DATA_C (INT_CARRY[69]) , .SAVE (INT_SUM[102]) , .CARRY (INT_CARRY[79]) );
   FULL_ADDER FA_64 (.DATA_A (INT_SUM[101]) , .DATA_B (INT_SUM[102]) , .DATA_C (INT_CARRY[70]) , .SAVE (INT_SUM[103]) , .CARRY (INT_CARRY[80]) );
   FLIPFLOP LA_35 (.DIN (INT_SUM[103]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[104]) );
   FLIPFLOP LA_36 (.DIN (INT_CARRY[71]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[72]) );
   HALF_ADDER HA_16 (.DATA_A (INT_SUM[104]) , .DATA_B (INT_CARRY[72]) , .SAVE (SUM[18]) , .CARRY (CARRY[18]) );
   FULL_ADDER FA_65 (.DATA_A (SUMMAND[110]) , .DATA_B (SUMMAND[111]) , .DATA_C (SUMMAND[112]) , .SAVE (INT_SUM[105]) , .CARRY (INT_CARRY[82]) );
   FULL_ADDER FA_66 (.DATA_A (SUMMAND[113]) , .DATA_B (SUMMAND[114]) , .DATA_C (SUMMAND[115]) , .SAVE (INT_SUM[106]) , .CARRY (INT_CARRY[83]) );
   FULL_ADDER FA_67 (.DATA_A (SUMMAND[116]) , .DATA_B (SUMMAND[117]) , .DATA_C (SUMMAND[118]) , .SAVE (INT_SUM[107]) , .CARRY (INT_CARRY[84]) );
   assign INT_SUM[108] = SUMMAND[119];
   FULL_ADDER FA_68 (.DATA_A (INT_SUM[105]) , .DATA_B (INT_SUM[106]) , .DATA_C (INT_SUM[107]) , .SAVE (INT_SUM[109]) , .CARRY (INT_CARRY[85]) );
   FULL_ADDER FA_69 (.DATA_A (INT_SUM[108]) , .DATA_B (INT_CARRY[73]) , .DATA_C (INT_CARRY[74]) , .SAVE (INT_SUM[110]) , .CARRY (INT_CARRY[86]) );
   assign INT_SUM[111] = INT_CARRY[75];
   FULL_ADDER FA_70 (.DATA_A (INT_SUM[109]) , .DATA_B (INT_SUM[110]) , .DATA_C (INT_SUM[111]) , .SAVE (INT_SUM[112]) , .CARRY (INT_CARRY[87]) );
   HALF_ADDER HA_17 (.DATA_A (INT_CARRY[76]) , .DATA_B (INT_CARRY[77]) , .SAVE (INT_SUM[113]) , .CARRY (INT_CARRY[88]) );
   FULL_ADDER FA_71 (.DATA_A (INT_SUM[112]) , .DATA_B (INT_SUM[113]) , .DATA_C (INT_CARRY[78]) , .SAVE (INT_SUM[114]) , .CARRY (INT_CARRY[89]) );
   assign INT_SUM[116] = INT_CARRY[79];
   FLIPFLOP LA_37 (.DIN (INT_SUM[114]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[115]) );
   FLIPFLOP LA_38 (.DIN (INT_SUM[116]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[117]) );
   FLIPFLOP LA_39 (.DIN (INT_CARRY[80]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[81]) );
   FULL_ADDER FA_72 (.DATA_A (INT_SUM[115]) , .DATA_B (INT_SUM[117]) , .DATA_C (INT_CARRY[81]) , .SAVE (SUM[19]) , .CARRY (CARRY[19]) );
   FULL_ADDER FA_73 (.DATA_A (SUMMAND[120]) , .DATA_B (SUMMAND[121]) , .DATA_C (SUMMAND[122]) , .SAVE (INT_SUM[118]) , .CARRY (INT_CARRY[91]) );
   FULL_ADDER FA_74 (.DATA_A (SUMMAND[123]) , .DATA_B (SUMMAND[124]) , .DATA_C (SUMMAND[125]) , .SAVE (INT_SUM[119]) , .CARRY (INT_CARRY[92]) );
   FULL_ADDER FA_75 (.DATA_A (SUMMAND[126]) , .DATA_B (SUMMAND[127]) , .DATA_C (SUMMAND[128]) , .SAVE (INT_SUM[120]) , .CARRY (INT_CARRY[93]) );
   FULL_ADDER FA_76 (.DATA_A (SUMMAND[129]) , .DATA_B (SUMMAND[130]) , .DATA_C (SUMMAND[131]) , .SAVE (INT_SUM[121]) , .CARRY (INT_CARRY[94]) );
   FULL_ADDER FA_77 (.DATA_A (INT_SUM[118]) , .DATA_B (INT_SUM[119]) , .DATA_C (INT_SUM[120]) , .SAVE (INT_SUM[122]) , .CARRY (INT_CARRY[95]) );
   FULL_ADDER FA_78 (.DATA_A (INT_SUM[121]) , .DATA_B (INT_CARRY[82]) , .DATA_C (INT_CARRY[83]) , .SAVE (INT_SUM[123]) , .CARRY (INT_CARRY[96]) );
   assign INT_SUM[124] = INT_CARRY[84];
   FULL_ADDER FA_79 (.DATA_A (INT_SUM[122]) , .DATA_B (INT_SUM[123]) , .DATA_C (INT_SUM[124]) , .SAVE (INT_SUM[125]) , .CARRY (INT_CARRY[97]) );
   HALF_ADDER HA_18 (.DATA_A (INT_CARRY[85]) , .DATA_B (INT_CARRY[86]) , .SAVE (INT_SUM[126]) , .CARRY (INT_CARRY[98]) );
   FULL_ADDER FA_80 (.DATA_A (INT_SUM[125]) , .DATA_B (INT_SUM[126]) , .DATA_C (INT_CARRY[87]) , .SAVE (INT_SUM[127]) , .CARRY (INT_CARRY[99]) );
   assign INT_SUM[129] = INT_CARRY[88];
   FLIPFLOP LA_40 (.DIN (INT_SUM[127]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[128]) );
   FLIPFLOP LA_41 (.DIN (INT_SUM[129]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[130]) );
   FLIPFLOP LA_42 (.DIN (INT_CARRY[89]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[90]) );
   FULL_ADDER FA_81 (.DATA_A (INT_SUM[128]) , .DATA_B (INT_SUM[130]) , .DATA_C (INT_CARRY[90]) , .SAVE (SUM[20]) , .CARRY (CARRY[20]) );
   FULL_ADDER FA_82 (.DATA_A (SUMMAND[132]) , .DATA_B (SUMMAND[133]) , .DATA_C (SUMMAND[134]) , .SAVE (INT_SUM[131]) , .CARRY (INT_CARRY[101]) );
   FULL_ADDER FA_83 (.DATA_A (SUMMAND[135]) , .DATA_B (SUMMAND[136]) , .DATA_C (SUMMAND[137]) , .SAVE (INT_SUM[132]) , .CARRY (INT_CARRY[102]) );
   FULL_ADDER FA_84 (.DATA_A (SUMMAND[138]) , .DATA_B (SUMMAND[139]) , .DATA_C (SUMMAND[140]) , .SAVE (INT_SUM[133]) , .CARRY (INT_CARRY[103]) );
   assign INT_SUM[134] = SUMMAND[141];
   assign INT_SUM[135] = SUMMAND[142];
   FULL_ADDER FA_85 (.DATA_A (INT_SUM[131]) , .DATA_B (INT_SUM[132]) , .DATA_C (INT_SUM[133]) , .SAVE (INT_SUM[136]) , .CARRY (INT_CARRY[104]) );
   FULL_ADDER FA_86 (.DATA_A (INT_SUM[134]) , .DATA_B (INT_SUM[135]) , .DATA_C (INT_CARRY[91]) , .SAVE (INT_SUM[137]) , .CARRY (INT_CARRY[105]) );
   FULL_ADDER FA_87 (.DATA_A (INT_CARRY[92]) , .DATA_B (INT_CARRY[93]) , .DATA_C (INT_CARRY[94]) , .SAVE (INT_SUM[138]) , .CARRY (INT_CARRY[106]) );
   FULL_ADDER FA_88 (.DATA_A (INT_SUM[136]) , .DATA_B (INT_SUM[137]) , .DATA_C (INT_SUM[138]) , .SAVE (INT_SUM[139]) , .CARRY (INT_CARRY[107]) );
   HALF_ADDER HA_19 (.DATA_A (INT_CARRY[95]) , .DATA_B (INT_CARRY[96]) , .SAVE (INT_SUM[140]) , .CARRY (INT_CARRY[108]) );
   FULL_ADDER FA_89 (.DATA_A (INT_SUM[139]) , .DATA_B (INT_SUM[140]) , .DATA_C (INT_CARRY[97]) , .SAVE (INT_SUM[141]) , .CARRY (INT_CARRY[109]) );
   assign INT_SUM[143] = INT_CARRY[98];
   FLIPFLOP LA_43 (.DIN (INT_SUM[141]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[142]) );
   FLIPFLOP LA_44 (.DIN (INT_SUM[143]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[144]) );
   FLIPFLOP LA_45 (.DIN (INT_CARRY[99]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[100]) );
   FULL_ADDER FA_90 (.DATA_A (INT_SUM[142]) , .DATA_B (INT_SUM[144]) , .DATA_C (INT_CARRY[100]) , .SAVE (SUM[21]) , .CARRY (CARRY[21]) );
   FULL_ADDER FA_91 (.DATA_A (SUMMAND[143]) , .DATA_B (SUMMAND[144]) , .DATA_C (SUMMAND[145]) , .SAVE (INT_SUM[145]) , .CARRY (INT_CARRY[111]) );
   FULL_ADDER FA_92 (.DATA_A (SUMMAND[146]) , .DATA_B (SUMMAND[147]) , .DATA_C (SUMMAND[148]) , .SAVE (INT_SUM[146]) , .CARRY (INT_CARRY[112]) );
   FULL_ADDER FA_93 (.DATA_A (SUMMAND[149]) , .DATA_B (SUMMAND[150]) , .DATA_C (SUMMAND[151]) , .SAVE (INT_SUM[147]) , .CARRY (INT_CARRY[113]) );
   FULL_ADDER FA_94 (.DATA_A (SUMMAND[152]) , .DATA_B (SUMMAND[153]) , .DATA_C (SUMMAND[154]) , .SAVE (INT_SUM[148]) , .CARRY (INT_CARRY[114]) );
   assign INT_SUM[149] = SUMMAND[155];
   FULL_ADDER FA_95 (.DATA_A (INT_SUM[145]) , .DATA_B (INT_SUM[146]) , .DATA_C (INT_SUM[147]) , .SAVE (INT_SUM[150]) , .CARRY (INT_CARRY[115]) );
   FULL_ADDER FA_96 (.DATA_A (INT_SUM[148]) , .DATA_B (INT_SUM[149]) , .DATA_C (INT_CARRY[101]) , .SAVE (INT_SUM[151]) , .CARRY (INT_CARRY[116]) );
   HALF_ADDER HA_20 (.DATA_A (INT_CARRY[102]) , .DATA_B (INT_CARRY[103]) , .SAVE (INT_SUM[152]) , .CARRY (INT_CARRY[117]) );
   FULL_ADDER FA_97 (.DATA_A (INT_SUM[150]) , .DATA_B (INT_SUM[151]) , .DATA_C (INT_SUM[152]) , .SAVE (INT_SUM[153]) , .CARRY (INT_CARRY[118]) );
   FULL_ADDER FA_98 (.DATA_A (INT_CARRY[104]) , .DATA_B (INT_CARRY[105]) , .DATA_C (INT_CARRY[106]) , .SAVE (INT_SUM[154]) , .CARRY (INT_CARRY[119]) );
   FULL_ADDER FA_99 (.DATA_A (INT_SUM[153]) , .DATA_B (INT_SUM[154]) , .DATA_C (INT_CARRY[107]) , .SAVE (INT_SUM[155]) , .CARRY (INT_CARRY[120]) );
   assign INT_SUM[157] = INT_CARRY[108];
   FLIPFLOP LA_46 (.DIN (INT_SUM[155]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[156]) );
   FLIPFLOP LA_47 (.DIN (INT_SUM[157]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[158]) );
   FLIPFLOP LA_48 (.DIN (INT_CARRY[109]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[110]) );
   FULL_ADDER FA_100 (.DATA_A (INT_SUM[156]) , .DATA_B (INT_SUM[158]) , .DATA_C (INT_CARRY[110]) , .SAVE (SUM[22]) , .CARRY (CARRY[22]) );
   FULL_ADDER FA_101 (.DATA_A (SUMMAND[156]) , .DATA_B (SUMMAND[157]) , .DATA_C (SUMMAND[158]) , .SAVE (INT_SUM[159]) , .CARRY (INT_CARRY[122]) );
   FULL_ADDER FA_102 (.DATA_A (SUMMAND[159]) , .DATA_B (SUMMAND[160]) , .DATA_C (SUMMAND[161]) , .SAVE (INT_SUM[160]) , .CARRY (INT_CARRY[123]) );
   FULL_ADDER FA_103 (.DATA_A (SUMMAND[162]) , .DATA_B (SUMMAND[163]) , .DATA_C (SUMMAND[164]) , .SAVE (INT_SUM[161]) , .CARRY (INT_CARRY[124]) );
   FULL_ADDER FA_104 (.DATA_A (SUMMAND[165]) , .DATA_B (SUMMAND[166]) , .DATA_C (SUMMAND[167]) , .SAVE (INT_SUM[162]) , .CARRY (INT_CARRY[125]) );
   FULL_ADDER FA_105 (.DATA_A (INT_SUM[159]) , .DATA_B (INT_SUM[160]) , .DATA_C (INT_SUM[161]) , .SAVE (INT_SUM[163]) , .CARRY (INT_CARRY[126]) );
   FULL_ADDER FA_106 (.DATA_A (INT_SUM[162]) , .DATA_B (INT_CARRY[111]) , .DATA_C (INT_CARRY[112]) , .SAVE (INT_SUM[164]) , .CARRY (INT_CARRY[127]) );
   HALF_ADDER HA_21 (.DATA_A (INT_CARRY[113]) , .DATA_B (INT_CARRY[114]) , .SAVE (INT_SUM[165]) , .CARRY (INT_CARRY[128]) );
   FULL_ADDER FA_107 (.DATA_A (INT_SUM[163]) , .DATA_B (INT_SUM[164]) , .DATA_C (INT_SUM[165]) , .SAVE (INT_SUM[166]) , .CARRY (INT_CARRY[129]) );
   FULL_ADDER FA_108 (.DATA_A (INT_CARRY[115]) , .DATA_B (INT_CARRY[116]) , .DATA_C (INT_CARRY[117]) , .SAVE (INT_SUM[167]) , .CARRY (INT_CARRY[130]) );
   FULL_ADDER FA_109 (.DATA_A (INT_SUM[166]) , .DATA_B (INT_SUM[167]) , .DATA_C (INT_CARRY[118]) , .SAVE (INT_SUM[168]) , .CARRY (INT_CARRY[131]) );
   assign INT_SUM[170] = INT_CARRY[119];
   FLIPFLOP LA_49 (.DIN (INT_SUM[168]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[169]) );
   FLIPFLOP LA_50 (.DIN (INT_SUM[170]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[171]) );
   FLIPFLOP LA_51 (.DIN (INT_CARRY[120]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[121]) );
   FULL_ADDER FA_110 (.DATA_A (INT_SUM[169]) , .DATA_B (INT_SUM[171]) , .DATA_C (INT_CARRY[121]) , .SAVE (SUM[23]) , .CARRY (CARRY[23]) );
   FULL_ADDER FA_111 (.DATA_A (SUMMAND[168]) , .DATA_B (SUMMAND[169]) , .DATA_C (SUMMAND[170]) , .SAVE (INT_SUM[172]) , .CARRY (INT_CARRY[133]) );
   FULL_ADDER FA_112 (.DATA_A (SUMMAND[171]) , .DATA_B (SUMMAND[172]) , .DATA_C (SUMMAND[173]) , .SAVE (INT_SUM[173]) , .CARRY (INT_CARRY[134]) );
   FULL_ADDER FA_113 (.DATA_A (SUMMAND[174]) , .DATA_B (SUMMAND[175]) , .DATA_C (SUMMAND[176]) , .SAVE (INT_SUM[174]) , .CARRY (INT_CARRY[135]) );
   FULL_ADDER FA_114 (.DATA_A (SUMMAND[177]) , .DATA_B (SUMMAND[178]) , .DATA_C (SUMMAND[179]) , .SAVE (INT_SUM[175]) , .CARRY (INT_CARRY[136]) );
   HALF_ADDER HA_22 (.DATA_A (SUMMAND[180]) , .DATA_B (SUMMAND[181]) , .SAVE (INT_SUM[176]) , .CARRY (INT_CARRY[137]) );
   FULL_ADDER FA_115 (.DATA_A (INT_SUM[172]) , .DATA_B (INT_SUM[173]) , .DATA_C (INT_SUM[174]) , .SAVE (INT_SUM[177]) , .CARRY (INT_CARRY[138]) );
   FULL_ADDER FA_116 (.DATA_A (INT_SUM[175]) , .DATA_B (INT_SUM[176]) , .DATA_C (INT_CARRY[122]) , .SAVE (INT_SUM[178]) , .CARRY (INT_CARRY[139]) );
   FULL_ADDER FA_117 (.DATA_A (INT_CARRY[123]) , .DATA_B (INT_CARRY[124]) , .DATA_C (INT_CARRY[125]) , .SAVE (INT_SUM[179]) , .CARRY (INT_CARRY[140]) );
   FULL_ADDER FA_118 (.DATA_A (INT_SUM[177]) , .DATA_B (INT_SUM[178]) , .DATA_C (INT_SUM[179]) , .SAVE (INT_SUM[180]) , .CARRY (INT_CARRY[141]) );
   FULL_ADDER FA_119 (.DATA_A (INT_CARRY[126]) , .DATA_B (INT_CARRY[127]) , .DATA_C (INT_CARRY[128]) , .SAVE (INT_SUM[181]) , .CARRY (INT_CARRY[142]) );
   FULL_ADDER FA_120 (.DATA_A (INT_SUM[180]) , .DATA_B (INT_SUM[181]) , .DATA_C (INT_CARRY[129]) , .SAVE (INT_SUM[182]) , .CARRY (INT_CARRY[143]) );
   assign INT_SUM[184] = INT_CARRY[130];
   FLIPFLOP LA_52 (.DIN (INT_SUM[182]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[183]) );
   FLIPFLOP LA_53 (.DIN (INT_SUM[184]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[185]) );
   FLIPFLOP LA_54 (.DIN (INT_CARRY[131]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[132]) );
   FULL_ADDER FA_121 (.DATA_A (INT_SUM[183]) , .DATA_B (INT_SUM[185]) , .DATA_C (INT_CARRY[132]) , .SAVE (SUM[24]) , .CARRY (CARRY[24]) );
   FULL_ADDER FA_122 (.DATA_A (SUMMAND[182]) , .DATA_B (SUMMAND[183]) , .DATA_C (SUMMAND[184]) , .SAVE (INT_SUM[186]) , .CARRY (INT_CARRY[145]) );
   FULL_ADDER FA_123 (.DATA_A (SUMMAND[185]) , .DATA_B (SUMMAND[186]) , .DATA_C (SUMMAND[187]) , .SAVE (INT_SUM[187]) , .CARRY (INT_CARRY[146]) );
   FULL_ADDER FA_124 (.DATA_A (SUMMAND[188]) , .DATA_B (SUMMAND[189]) , .DATA_C (SUMMAND[190]) , .SAVE (INT_SUM[188]) , .CARRY (INT_CARRY[147]) );
   FULL_ADDER FA_125 (.DATA_A (SUMMAND[191]) , .DATA_B (SUMMAND[192]) , .DATA_C (SUMMAND[193]) , .SAVE (INT_SUM[189]) , .CARRY (INT_CARRY[148]) );
   assign INT_SUM[190] = SUMMAND[194];
   FULL_ADDER FA_126 (.DATA_A (INT_SUM[186]) , .DATA_B (INT_SUM[187]) , .DATA_C (INT_SUM[188]) , .SAVE (INT_SUM[191]) , .CARRY (INT_CARRY[149]) );
   FULL_ADDER FA_127 (.DATA_A (INT_SUM[189]) , .DATA_B (INT_SUM[190]) , .DATA_C (INT_CARRY[133]) , .SAVE (INT_SUM[192]) , .CARRY (INT_CARRY[150]) );
   FULL_ADDER FA_128 (.DATA_A (INT_CARRY[134]) , .DATA_B (INT_CARRY[135]) , .DATA_C (INT_CARRY[136]) , .SAVE (INT_SUM[193]) , .CARRY (INT_CARRY[151]) );
   assign INT_SUM[194] = INT_CARRY[137];
   FULL_ADDER FA_129 (.DATA_A (INT_SUM[191]) , .DATA_B (INT_SUM[192]) , .DATA_C (INT_SUM[193]) , .SAVE (INT_SUM[195]) , .CARRY (INT_CARRY[152]) );
   FULL_ADDER FA_130 (.DATA_A (INT_SUM[194]) , .DATA_B (INT_CARRY[138]) , .DATA_C (INT_CARRY[139]) , .SAVE (INT_SUM[196]) , .CARRY (INT_CARRY[153]) );
   assign INT_SUM[197] = INT_CARRY[140];
   FULL_ADDER FA_131 (.DATA_A (INT_SUM[195]) , .DATA_B (INT_SUM[196]) , .DATA_C (INT_SUM[197]) , .SAVE (INT_SUM[198]) , .CARRY (INT_CARRY[154]) );
   HALF_ADDER HA_23 (.DATA_A (INT_CARRY[141]) , .DATA_B (INT_CARRY[142]) , .SAVE (INT_SUM[200]) , .CARRY (INT_CARRY[156]) );
   FLIPFLOP LA_55 (.DIN (INT_SUM[198]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[199]) );
   FLIPFLOP LA_56 (.DIN (INT_SUM[200]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[201]) );
   FLIPFLOP LA_57 (.DIN (INT_CARRY[143]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[144]) );
   FULL_ADDER FA_132 (.DATA_A (INT_SUM[199]) , .DATA_B (INT_SUM[201]) , .DATA_C (INT_CARRY[144]) , .SAVE (SUM[25]) , .CARRY (CARRY[25]) );
   FULL_ADDER FA_133 (.DATA_A (SUMMAND[195]) , .DATA_B (SUMMAND[196]) , .DATA_C (SUMMAND[197]) , .SAVE (INT_SUM[202]) , .CARRY (INT_CARRY[158]) );
   FULL_ADDER FA_134 (.DATA_A (SUMMAND[198]) , .DATA_B (SUMMAND[199]) , .DATA_C (SUMMAND[200]) , .SAVE (INT_SUM[203]) , .CARRY (INT_CARRY[159]) );
   FULL_ADDER FA_135 (.DATA_A (SUMMAND[201]) , .DATA_B (SUMMAND[202]) , .DATA_C (SUMMAND[203]) , .SAVE (INT_SUM[204]) , .CARRY (INT_CARRY[160]) );
   FULL_ADDER FA_136 (.DATA_A (SUMMAND[204]) , .DATA_B (SUMMAND[205]) , .DATA_C (SUMMAND[206]) , .SAVE (INT_SUM[205]) , .CARRY (INT_CARRY[161]) );
   FULL_ADDER FA_137 (.DATA_A (SUMMAND[207]) , .DATA_B (SUMMAND[208]) , .DATA_C (SUMMAND[209]) , .SAVE (INT_SUM[206]) , .CARRY (INT_CARRY[162]) );
   FULL_ADDER FA_138 (.DATA_A (INT_SUM[202]) , .DATA_B (INT_SUM[203]) , .DATA_C (INT_SUM[204]) , .SAVE (INT_SUM[207]) , .CARRY (INT_CARRY[163]) );
   FULL_ADDER FA_139 (.DATA_A (INT_SUM[205]) , .DATA_B (INT_SUM[206]) , .DATA_C (INT_CARRY[145]) , .SAVE (INT_SUM[208]) , .CARRY (INT_CARRY[164]) );
   FULL_ADDER FA_140 (.DATA_A (INT_CARRY[146]) , .DATA_B (INT_CARRY[147]) , .DATA_C (INT_CARRY[148]) , .SAVE (INT_SUM[209]) , .CARRY (INT_CARRY[165]) );
   FULL_ADDER FA_141 (.DATA_A (INT_SUM[207]) , .DATA_B (INT_SUM[208]) , .DATA_C (INT_SUM[209]) , .SAVE (INT_SUM[210]) , .CARRY (INT_CARRY[166]) );
   FULL_ADDER FA_142 (.DATA_A (INT_CARRY[149]) , .DATA_B (INT_CARRY[150]) , .DATA_C (INT_CARRY[151]) , .SAVE (INT_SUM[211]) , .CARRY (INT_CARRY[167]) );
   FULL_ADDER FA_143 (.DATA_A (INT_SUM[210]) , .DATA_B (INT_SUM[211]) , .DATA_C (INT_CARRY[152]) , .SAVE (INT_SUM[212]) , .CARRY (INT_CARRY[168]) );
   assign INT_SUM[214] = INT_CARRY[153];
   FLIPFLOP LA_58 (.DIN (INT_SUM[212]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[213]) );
   FLIPFLOP LA_59 (.DIN (INT_SUM[214]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[215]) );
   FLIPFLOP LA_60 (.DIN (INT_CARRY[154]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[155]) );
   FULL_ADDER FA_144 (.DATA_A (INT_SUM[213]) , .DATA_B (INT_SUM[215]) , .DATA_C (INT_CARRY[155]) , .SAVE (INT_SUM[216]) , .CARRY (INT_CARRY[170]) );
   FLIPFLOP LA_61 (.DIN (INT_CARRY[156]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[157]) );
   assign INT_SUM[217] = INT_CARRY[157];
   HALF_ADDER HA_24 (.DATA_A (INT_SUM[216]) , .DATA_B (INT_SUM[217]) , .SAVE (SUM[26]) , .CARRY (CARRY[26]) );
   FULL_ADDER FA_145 (.DATA_A (SUMMAND[210]) , .DATA_B (SUMMAND[211]) , .DATA_C (SUMMAND[212]) , .SAVE (INT_SUM[218]) , .CARRY (INT_CARRY[171]) );
   FULL_ADDER FA_146 (.DATA_A (SUMMAND[213]) , .DATA_B (SUMMAND[214]) , .DATA_C (SUMMAND[215]) , .SAVE (INT_SUM[219]) , .CARRY (INT_CARRY[172]) );
   FULL_ADDER FA_147 (.DATA_A (SUMMAND[216]) , .DATA_B (SUMMAND[217]) , .DATA_C (SUMMAND[218]) , .SAVE (INT_SUM[220]) , .CARRY (INT_CARRY[173]) );
   FULL_ADDER FA_148 (.DATA_A (SUMMAND[219]) , .DATA_B (SUMMAND[220]) , .DATA_C (SUMMAND[221]) , .SAVE (INT_SUM[221]) , .CARRY (INT_CARRY[174]) );
   HALF_ADDER HA_25 (.DATA_A (SUMMAND[222]) , .DATA_B (SUMMAND[223]) , .SAVE (INT_SUM[222]) , .CARRY (INT_CARRY[175]) );
   FULL_ADDER FA_149 (.DATA_A (INT_SUM[218]) , .DATA_B (INT_SUM[219]) , .DATA_C (INT_SUM[220]) , .SAVE (INT_SUM[223]) , .CARRY (INT_CARRY[176]) );
   FULL_ADDER FA_150 (.DATA_A (INT_SUM[221]) , .DATA_B (INT_SUM[222]) , .DATA_C (INT_CARRY[158]) , .SAVE (INT_SUM[224]) , .CARRY (INT_CARRY[177]) );
   FULL_ADDER FA_151 (.DATA_A (INT_CARRY[159]) , .DATA_B (INT_CARRY[160]) , .DATA_C (INT_CARRY[161]) , .SAVE (INT_SUM[225]) , .CARRY (INT_CARRY[178]) );
   assign INT_SUM[226] = INT_CARRY[162];
   FULL_ADDER FA_152 (.DATA_A (INT_SUM[223]) , .DATA_B (INT_SUM[224]) , .DATA_C (INT_SUM[225]) , .SAVE (INT_SUM[227]) , .CARRY (INT_CARRY[179]) );
   FULL_ADDER FA_153 (.DATA_A (INT_SUM[226]) , .DATA_B (INT_CARRY[163]) , .DATA_C (INT_CARRY[164]) , .SAVE (INT_SUM[228]) , .CARRY (INT_CARRY[180]) );
   assign INT_SUM[229] = INT_CARRY[165];
   FULL_ADDER FA_154 (.DATA_A (INT_SUM[227]) , .DATA_B (INT_SUM[228]) , .DATA_C (INT_SUM[229]) , .SAVE (INT_SUM[230]) , .CARRY (INT_CARRY[181]) );
   assign INT_SUM[232] = INT_CARRY[166];
   assign INT_SUM[234] = INT_CARRY[167];
   FLIPFLOP LA_62 (.DIN (INT_SUM[230]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[231]) );
   FLIPFLOP LA_63 (.DIN (INT_SUM[232]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[233]) );
   FLIPFLOP LA_64 (.DIN (INT_SUM[234]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[235]) );
   FULL_ADDER FA_155 (.DATA_A (INT_SUM[231]) , .DATA_B (INT_SUM[233]) , .DATA_C (INT_SUM[235]) , .SAVE (INT_SUM[236]) , .CARRY (INT_CARRY[183]) );
   FLIPFLOP LA_65 (.DIN (INT_CARRY[168]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[169]) );
   assign INT_SUM[237] = INT_CARRY[169];
   FULL_ADDER FA_156 (.DATA_A (INT_SUM[236]) , .DATA_B (INT_SUM[237]) , .DATA_C (INT_CARRY[170]) , .SAVE (SUM[27]) , .CARRY (CARRY[27]) );
   FULL_ADDER FA_157 (.DATA_A (SUMMAND[224]) , .DATA_B (SUMMAND[225]) , .DATA_C (SUMMAND[226]) , .SAVE (INT_SUM[238]) , .CARRY (INT_CARRY[184]) );
   FULL_ADDER FA_158 (.DATA_A (SUMMAND[227]) , .DATA_B (SUMMAND[228]) , .DATA_C (SUMMAND[229]) , .SAVE (INT_SUM[239]) , .CARRY (INT_CARRY[185]) );
   FULL_ADDER FA_159 (.DATA_A (SUMMAND[230]) , .DATA_B (SUMMAND[231]) , .DATA_C (SUMMAND[232]) , .SAVE (INT_SUM[240]) , .CARRY (INT_CARRY[186]) );
   FULL_ADDER FA_160 (.DATA_A (SUMMAND[233]) , .DATA_B (SUMMAND[234]) , .DATA_C (SUMMAND[235]) , .SAVE (INT_SUM[241]) , .CARRY (INT_CARRY[187]) );
   FULL_ADDER FA_161 (.DATA_A (SUMMAND[236]) , .DATA_B (SUMMAND[237]) , .DATA_C (SUMMAND[238]) , .SAVE (INT_SUM[242]) , .CARRY (INT_CARRY[188]) );
   assign INT_SUM[243] = SUMMAND[239];
   FULL_ADDER FA_162 (.DATA_A (INT_SUM[238]) , .DATA_B (INT_SUM[239]) , .DATA_C (INT_SUM[240]) , .SAVE (INT_SUM[244]) , .CARRY (INT_CARRY[189]) );
   FULL_ADDER FA_163 (.DATA_A (INT_SUM[241]) , .DATA_B (INT_SUM[242]) , .DATA_C (INT_SUM[243]) , .SAVE (INT_SUM[245]) , .CARRY (INT_CARRY[190]) );
   FULL_ADDER FA_164 (.DATA_A (INT_CARRY[171]) , .DATA_B (INT_CARRY[172]) , .DATA_C (INT_CARRY[173]) , .SAVE (INT_SUM[246]) , .CARRY (INT_CARRY[191]) );
   assign INT_SUM[247] = INT_CARRY[174];
   assign INT_SUM[248] = INT_CARRY[175];
   FULL_ADDER FA_165 (.DATA_A (INT_SUM[244]) , .DATA_B (INT_SUM[245]) , .DATA_C (INT_SUM[246]) , .SAVE (INT_SUM[249]) , .CARRY (INT_CARRY[192]) );
   FULL_ADDER FA_166 (.DATA_A (INT_SUM[247]) , .DATA_B (INT_SUM[248]) , .DATA_C (INT_CARRY[176]) , .SAVE (INT_SUM[250]) , .CARRY (INT_CARRY[193]) );
   assign INT_SUM[251] = INT_CARRY[177];
   assign INT_SUM[252] = INT_CARRY[178];
   FULL_ADDER FA_167 (.DATA_A (INT_SUM[249]) , .DATA_B (INT_SUM[250]) , .DATA_C (INT_SUM[251]) , .SAVE (INT_SUM[253]) , .CARRY (INT_CARRY[194]) );
   FULL_ADDER FA_168 (.DATA_A (INT_SUM[252]) , .DATA_B (INT_CARRY[179]) , .DATA_C (INT_CARRY[180]) , .SAVE (INT_SUM[255]) , .CARRY (INT_CARRY[196]) );
   FLIPFLOP LA_66 (.DIN (INT_SUM[253]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[254]) );
   FLIPFLOP LA_67 (.DIN (INT_SUM[255]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[256]) );
   FLIPFLOP LA_68 (.DIN (INT_CARRY[181]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[182]) );
   FULL_ADDER FA_169 (.DATA_A (INT_SUM[254]) , .DATA_B (INT_SUM[256]) , .DATA_C (INT_CARRY[182]) , .SAVE (INT_SUM[257]) , .CARRY (INT_CARRY[198]) );
   HALF_ADDER HA_26 (.DATA_A (INT_SUM[257]) , .DATA_B (INT_CARRY[183]) , .SAVE (SUM[28]) , .CARRY (CARRY[28]) );
   FULL_ADDER FA_170 (.DATA_A (SUMMAND[240]) , .DATA_B (SUMMAND[241]) , .DATA_C (SUMMAND[242]) , .SAVE (INT_SUM[258]) , .CARRY (INT_CARRY[199]) );
   FULL_ADDER FA_171 (.DATA_A (SUMMAND[243]) , .DATA_B (SUMMAND[244]) , .DATA_C (SUMMAND[245]) , .SAVE (INT_SUM[259]) , .CARRY (INT_CARRY[200]) );
   FULL_ADDER FA_172 (.DATA_A (SUMMAND[246]) , .DATA_B (SUMMAND[247]) , .DATA_C (SUMMAND[248]) , .SAVE (INT_SUM[260]) , .CARRY (INT_CARRY[201]) );
   FULL_ADDER FA_173 (.DATA_A (SUMMAND[249]) , .DATA_B (SUMMAND[250]) , .DATA_C (SUMMAND[251]) , .SAVE (INT_SUM[261]) , .CARRY (INT_CARRY[202]) );
   FULL_ADDER FA_174 (.DATA_A (SUMMAND[252]) , .DATA_B (SUMMAND[253]) , .DATA_C (SUMMAND[254]) , .SAVE (INT_SUM[262]) , .CARRY (INT_CARRY[203]) );
   FULL_ADDER FA_175 (.DATA_A (INT_SUM[258]) , .DATA_B (INT_SUM[259]) , .DATA_C (INT_SUM[260]) , .SAVE (INT_SUM[263]) , .CARRY (INT_CARRY[204]) );
   FULL_ADDER FA_176 (.DATA_A (INT_SUM[261]) , .DATA_B (INT_SUM[262]) , .DATA_C (INT_CARRY[184]) , .SAVE (INT_SUM[264]) , .CARRY (INT_CARRY[205]) );
   FULL_ADDER FA_177 (.DATA_A (INT_CARRY[185]) , .DATA_B (INT_CARRY[186]) , .DATA_C (INT_CARRY[187]) , .SAVE (INT_SUM[265]) , .CARRY (INT_CARRY[206]) );
   assign INT_SUM[266] = INT_CARRY[188];
   FULL_ADDER FA_178 (.DATA_A (INT_SUM[263]) , .DATA_B (INT_SUM[264]) , .DATA_C (INT_SUM[265]) , .SAVE (INT_SUM[267]) , .CARRY (INT_CARRY[207]) );
   FULL_ADDER FA_179 (.DATA_A (INT_SUM[266]) , .DATA_B (INT_CARRY[189]) , .DATA_C (INT_CARRY[190]) , .SAVE (INT_SUM[268]) , .CARRY (INT_CARRY[208]) );
   assign INT_SUM[269] = INT_CARRY[191];
   FULL_ADDER FA_180 (.DATA_A (INT_SUM[267]) , .DATA_B (INT_SUM[268]) , .DATA_C (INT_SUM[269]) , .SAVE (INT_SUM[270]) , .CARRY (INT_CARRY[209]) );
   HALF_ADDER HA_27 (.DATA_A (INT_CARRY[192]) , .DATA_B (INT_CARRY[193]) , .SAVE (INT_SUM[272]) , .CARRY (INT_CARRY[211]) );
   FLIPFLOP LA_69 (.DIN (INT_SUM[270]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[271]) );
   FLIPFLOP LA_70 (.DIN (INT_SUM[272]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[273]) );
   FLIPFLOP LA_71 (.DIN (INT_CARRY[194]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[195]) );
   FULL_ADDER FA_181 (.DATA_A (INT_SUM[271]) , .DATA_B (INT_SUM[273]) , .DATA_C (INT_CARRY[195]) , .SAVE (INT_SUM[274]) , .CARRY (INT_CARRY[213]) );
   FLIPFLOP LA_72 (.DIN (INT_CARRY[196]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[197]) );
   assign INT_SUM[275] = INT_CARRY[197];
   FULL_ADDER FA_182 (.DATA_A (INT_SUM[274]) , .DATA_B (INT_SUM[275]) , .DATA_C (INT_CARRY[198]) , .SAVE (SUM[29]) , .CARRY (CARRY[29]) );
   FULL_ADDER FA_183 (.DATA_A (SUMMAND[255]) , .DATA_B (SUMMAND[256]) , .DATA_C (SUMMAND[257]) , .SAVE (INT_SUM[276]) , .CARRY (INT_CARRY[214]) );
   FULL_ADDER FA_184 (.DATA_A (SUMMAND[258]) , .DATA_B (SUMMAND[259]) , .DATA_C (SUMMAND[260]) , .SAVE (INT_SUM[277]) , .CARRY (INT_CARRY[215]) );
   FULL_ADDER FA_185 (.DATA_A (SUMMAND[261]) , .DATA_B (SUMMAND[262]) , .DATA_C (SUMMAND[263]) , .SAVE (INT_SUM[278]) , .CARRY (INT_CARRY[216]) );
   FULL_ADDER FA_186 (.DATA_A (SUMMAND[264]) , .DATA_B (SUMMAND[265]) , .DATA_C (SUMMAND[266]) , .SAVE (INT_SUM[279]) , .CARRY (INT_CARRY[217]) );
   FULL_ADDER FA_187 (.DATA_A (SUMMAND[267]) , .DATA_B (SUMMAND[268]) , .DATA_C (SUMMAND[269]) , .SAVE (INT_SUM[280]) , .CARRY (INT_CARRY[218]) );
   assign INT_SUM[281] = SUMMAND[270];
   assign INT_SUM[282] = SUMMAND[271];
   FULL_ADDER FA_188 (.DATA_A (INT_SUM[276]) , .DATA_B (INT_SUM[277]) , .DATA_C (INT_SUM[278]) , .SAVE (INT_SUM[283]) , .CARRY (INT_CARRY[219]) );
   FULL_ADDER FA_189 (.DATA_A (INT_SUM[279]) , .DATA_B (INT_SUM[280]) , .DATA_C (INT_SUM[281]) , .SAVE (INT_SUM[284]) , .CARRY (INT_CARRY[220]) );
   FULL_ADDER FA_190 (.DATA_A (INT_SUM[282]) , .DATA_B (INT_CARRY[199]) , .DATA_C (INT_CARRY[200]) , .SAVE (INT_SUM[285]) , .CARRY (INT_CARRY[221]) );
   FULL_ADDER FA_191 (.DATA_A (INT_CARRY[201]) , .DATA_B (INT_CARRY[202]) , .DATA_C (INT_CARRY[203]) , .SAVE (INT_SUM[286]) , .CARRY (INT_CARRY[222]) );
   FULL_ADDER FA_192 (.DATA_A (INT_SUM[283]) , .DATA_B (INT_SUM[284]) , .DATA_C (INT_SUM[285]) , .SAVE (INT_SUM[287]) , .CARRY (INT_CARRY[223]) );
   FULL_ADDER FA_193 (.DATA_A (INT_SUM[286]) , .DATA_B (INT_CARRY[204]) , .DATA_C (INT_CARRY[205]) , .SAVE (INT_SUM[288]) , .CARRY (INT_CARRY[224]) );
   assign INT_SUM[289] = INT_CARRY[206];
   FULL_ADDER FA_194 (.DATA_A (INT_SUM[287]) , .DATA_B (INT_SUM[288]) , .DATA_C (INT_SUM[289]) , .SAVE (INT_SUM[290]) , .CARRY (INT_CARRY[225]) );
   HALF_ADDER HA_28 (.DATA_A (INT_CARRY[207]) , .DATA_B (INT_CARRY[208]) , .SAVE (INT_SUM[292]) , .CARRY (INT_CARRY[227]) );
   FLIPFLOP LA_73 (.DIN (INT_SUM[290]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[291]) );
   FLIPFLOP LA_74 (.DIN (INT_SUM[292]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[293]) );
   FLIPFLOP LA_75 (.DIN (INT_CARRY[209]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[210]) );
   FULL_ADDER FA_195 (.DATA_A (INT_SUM[291]) , .DATA_B (INT_SUM[293]) , .DATA_C (INT_CARRY[210]) , .SAVE (INT_SUM[294]) , .CARRY (INT_CARRY[229]) );
   FLIPFLOP LA_76 (.DIN (INT_CARRY[211]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[212]) );
   assign INT_SUM[295] = INT_CARRY[212];
   FULL_ADDER FA_196 (.DATA_A (INT_SUM[294]) , .DATA_B (INT_SUM[295]) , .DATA_C (INT_CARRY[213]) , .SAVE (SUM[30]) , .CARRY (CARRY[30]) );
   FULL_ADDER FA_197 (.DATA_A (SUMMAND[272]) , .DATA_B (SUMMAND[273]) , .DATA_C (SUMMAND[274]) , .SAVE (INT_SUM[296]) , .CARRY (INT_CARRY[230]) );
   FULL_ADDER FA_198 (.DATA_A (SUMMAND[275]) , .DATA_B (SUMMAND[276]) , .DATA_C (SUMMAND[277]) , .SAVE (INT_SUM[297]) , .CARRY (INT_CARRY[231]) );
   FULL_ADDER FA_199 (.DATA_A (SUMMAND[278]) , .DATA_B (SUMMAND[279]) , .DATA_C (SUMMAND[280]) , .SAVE (INT_SUM[298]) , .CARRY (INT_CARRY[232]) );
   FULL_ADDER FA_200 (.DATA_A (SUMMAND[281]) , .DATA_B (SUMMAND[282]) , .DATA_C (SUMMAND[283]) , .SAVE (INT_SUM[299]) , .CARRY (INT_CARRY[233]) );
   FULL_ADDER FA_201 (.DATA_A (SUMMAND[284]) , .DATA_B (SUMMAND[285]) , .DATA_C (SUMMAND[286]) , .SAVE (INT_SUM[300]) , .CARRY (INT_CARRY[234]) );
   assign INT_SUM[301] = SUMMAND[287];
   FULL_ADDER FA_202 (.DATA_A (INT_SUM[296]) , .DATA_B (INT_SUM[297]) , .DATA_C (INT_SUM[298]) , .SAVE (INT_SUM[302]) , .CARRY (INT_CARRY[235]) );
   FULL_ADDER FA_203 (.DATA_A (INT_SUM[299]) , .DATA_B (INT_SUM[300]) , .DATA_C (INT_SUM[301]) , .SAVE (INT_SUM[303]) , .CARRY (INT_CARRY[236]) );
   FULL_ADDER FA_204 (.DATA_A (INT_CARRY[214]) , .DATA_B (INT_CARRY[215]) , .DATA_C (INT_CARRY[216]) , .SAVE (INT_SUM[304]) , .CARRY (INT_CARRY[237]) );
   assign INT_SUM[305] = INT_CARRY[217];
   assign INT_SUM[306] = INT_CARRY[218];
   FULL_ADDER FA_205 (.DATA_A (INT_SUM[302]) , .DATA_B (INT_SUM[303]) , .DATA_C (INT_SUM[304]) , .SAVE (INT_SUM[307]) , .CARRY (INT_CARRY[238]) );
   FULL_ADDER FA_206 (.DATA_A (INT_SUM[305]) , .DATA_B (INT_SUM[306]) , .DATA_C (INT_CARRY[219]) , .SAVE (INT_SUM[308]) , .CARRY (INT_CARRY[239]) );
   FULL_ADDER FA_207 (.DATA_A (INT_CARRY[220]) , .DATA_B (INT_CARRY[221]) , .DATA_C (INT_CARRY[222]) , .SAVE (INT_SUM[309]) , .CARRY (INT_CARRY[240]) );
   FULL_ADDER FA_208 (.DATA_A (INT_SUM[307]) , .DATA_B (INT_SUM[308]) , .DATA_C (INT_SUM[309]) , .SAVE (INT_SUM[310]) , .CARRY (INT_CARRY[241]) );
   HALF_ADDER HA_29 (.DATA_A (INT_CARRY[223]) , .DATA_B (INT_CARRY[224]) , .SAVE (INT_SUM[312]) , .CARRY (INT_CARRY[243]) );
   FLIPFLOP LA_77 (.DIN (INT_SUM[310]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[311]) );
   FLIPFLOP LA_78 (.DIN (INT_SUM[312]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[313]) );
   FLIPFLOP LA_79 (.DIN (INT_CARRY[225]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[226]) );
   FULL_ADDER FA_209 (.DATA_A (INT_SUM[311]) , .DATA_B (INT_SUM[313]) , .DATA_C (INT_CARRY[226]) , .SAVE (INT_SUM[314]) , .CARRY (INT_CARRY[245]) );
   FLIPFLOP LA_80 (.DIN (INT_CARRY[227]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[228]) );
   assign INT_SUM[315] = INT_CARRY[228];
   FULL_ADDER FA_210 (.DATA_A (INT_SUM[314]) , .DATA_B (INT_SUM[315]) , .DATA_C (INT_CARRY[229]) , .SAVE (SUM[31]) , .CARRY (CARRY[31]) );
   FULL_ADDER FA_211 (.DATA_A (SUMMAND[288]) , .DATA_B (SUMMAND[289]) , .DATA_C (SUMMAND[290]) , .SAVE (INT_SUM[316]) , .CARRY (INT_CARRY[246]) );
   FULL_ADDER FA_212 (.DATA_A (SUMMAND[291]) , .DATA_B (SUMMAND[292]) , .DATA_C (SUMMAND[293]) , .SAVE (INT_SUM[317]) , .CARRY (INT_CARRY[247]) );
   FULL_ADDER FA_213 (.DATA_A (SUMMAND[294]) , .DATA_B (SUMMAND[295]) , .DATA_C (SUMMAND[296]) , .SAVE (INT_SUM[318]) , .CARRY (INT_CARRY[248]) );
   FULL_ADDER FA_214 (.DATA_A (SUMMAND[297]) , .DATA_B (SUMMAND[298]) , .DATA_C (SUMMAND[299]) , .SAVE (INT_SUM[319]) , .CARRY (INT_CARRY[249]) );
   FULL_ADDER FA_215 (.DATA_A (SUMMAND[300]) , .DATA_B (SUMMAND[301]) , .DATA_C (SUMMAND[302]) , .SAVE (INT_SUM[320]) , .CARRY (INT_CARRY[250]) );
   assign INT_SUM[321] = SUMMAND[303];
   FULL_ADDER FA_216 (.DATA_A (INT_SUM[316]) , .DATA_B (INT_SUM[317]) , .DATA_C (INT_SUM[318]) , .SAVE (INT_SUM[322]) , .CARRY (INT_CARRY[251]) );
   FULL_ADDER FA_217 (.DATA_A (INT_SUM[319]) , .DATA_B (INT_SUM[320]) , .DATA_C (INT_SUM[321]) , .SAVE (INT_SUM[323]) , .CARRY (INT_CARRY[252]) );
   FULL_ADDER FA_218 (.DATA_A (INT_CARRY[230]) , .DATA_B (INT_CARRY[231]) , .DATA_C (INT_CARRY[232]) , .SAVE (INT_SUM[324]) , .CARRY (INT_CARRY[253]) );
   HALF_ADDER HA_30 (.DATA_A (INT_CARRY[233]) , .DATA_B (INT_CARRY[234]) , .SAVE (INT_SUM[325]) , .CARRY (INT_CARRY[254]) );
   FULL_ADDER FA_219 (.DATA_A (INT_SUM[322]) , .DATA_B (INT_SUM[323]) , .DATA_C (INT_SUM[324]) , .SAVE (INT_SUM[326]) , .CARRY (INT_CARRY[255]) );
   FULL_ADDER FA_220 (.DATA_A (INT_SUM[325]) , .DATA_B (INT_CARRY[235]) , .DATA_C (INT_CARRY[236]) , .SAVE (INT_SUM[327]) , .CARRY (INT_CARRY[256]) );
   assign INT_SUM[328] = INT_CARRY[237];
   FULL_ADDER FA_221 (.DATA_A (INT_SUM[326]) , .DATA_B (INT_SUM[327]) , .DATA_C (INT_SUM[328]) , .SAVE (INT_SUM[329]) , .CARRY (INT_CARRY[257]) );
   FULL_ADDER FA_222 (.DATA_A (INT_CARRY[238]) , .DATA_B (INT_CARRY[239]) , .DATA_C (INT_CARRY[240]) , .SAVE (INT_SUM[331]) , .CARRY (INT_CARRY[259]) );
   FLIPFLOP LA_81 (.DIN (INT_SUM[329]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[330]) );
   FLIPFLOP LA_82 (.DIN (INT_SUM[331]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[332]) );
   FLIPFLOP LA_83 (.DIN (INT_CARRY[241]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[242]) );
   FULL_ADDER FA_223 (.DATA_A (INT_SUM[330]) , .DATA_B (INT_SUM[332]) , .DATA_C (INT_CARRY[242]) , .SAVE (INT_SUM[333]) , .CARRY (INT_CARRY[261]) );
   FLIPFLOP LA_84 (.DIN (INT_CARRY[243]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[244]) );
   assign INT_SUM[334] = INT_CARRY[244];
   FULL_ADDER FA_224 (.DATA_A (INT_SUM[333]) , .DATA_B (INT_SUM[334]) , .DATA_C (INT_CARRY[245]) , .SAVE (SUM[32]) , .CARRY (CARRY[32]) );
   FULL_ADDER FA_225 (.DATA_A (SUMMAND[304]) , .DATA_B (SUMMAND[305]) , .DATA_C (SUMMAND[306]) , .SAVE (INT_SUM[335]) , .CARRY (INT_CARRY[262]) );
   FULL_ADDER FA_226 (.DATA_A (SUMMAND[307]) , .DATA_B (SUMMAND[308]) , .DATA_C (SUMMAND[309]) , .SAVE (INT_SUM[336]) , .CARRY (INT_CARRY[263]) );
   FULL_ADDER FA_227 (.DATA_A (SUMMAND[310]) , .DATA_B (SUMMAND[311]) , .DATA_C (SUMMAND[312]) , .SAVE (INT_SUM[337]) , .CARRY (INT_CARRY[264]) );
   FULL_ADDER FA_228 (.DATA_A (SUMMAND[313]) , .DATA_B (SUMMAND[314]) , .DATA_C (SUMMAND[315]) , .SAVE (INT_SUM[338]) , .CARRY (INT_CARRY[265]) );
   FULL_ADDER FA_229 (.DATA_A (SUMMAND[316]) , .DATA_B (SUMMAND[317]) , .DATA_C (SUMMAND[318]) , .SAVE (INT_SUM[339]) , .CARRY (INT_CARRY[266]) );
   assign INT_SUM[340] = SUMMAND[319];
   assign INT_SUM[341] = SUMMAND[320];
   FULL_ADDER FA_230 (.DATA_A (INT_SUM[335]) , .DATA_B (INT_SUM[336]) , .DATA_C (INT_SUM[337]) , .SAVE (INT_SUM[342]) , .CARRY (INT_CARRY[267]) );
   FULL_ADDER FA_231 (.DATA_A (INT_SUM[338]) , .DATA_B (INT_SUM[339]) , .DATA_C (INT_SUM[340]) , .SAVE (INT_SUM[343]) , .CARRY (INT_CARRY[268]) );
   FULL_ADDER FA_232 (.DATA_A (INT_SUM[341]) , .DATA_B (INT_CARRY[246]) , .DATA_C (INT_CARRY[247]) , .SAVE (INT_SUM[344]) , .CARRY (INT_CARRY[269]) );
   FULL_ADDER FA_233 (.DATA_A (INT_CARRY[248]) , .DATA_B (INT_CARRY[249]) , .DATA_C (INT_CARRY[250]) , .SAVE (INT_SUM[345]) , .CARRY (INT_CARRY[270]) );
   FULL_ADDER FA_234 (.DATA_A (INT_SUM[342]) , .DATA_B (INT_SUM[343]) , .DATA_C (INT_SUM[344]) , .SAVE (INT_SUM[346]) , .CARRY (INT_CARRY[271]) );
   FULL_ADDER FA_235 (.DATA_A (INT_SUM[345]) , .DATA_B (INT_CARRY[251]) , .DATA_C (INT_CARRY[252]) , .SAVE (INT_SUM[347]) , .CARRY (INT_CARRY[272]) );
   assign INT_SUM[348] = INT_CARRY[253];
   assign INT_SUM[349] = INT_CARRY[254];
   FULL_ADDER FA_236 (.DATA_A (INT_SUM[346]) , .DATA_B (INT_SUM[347]) , .DATA_C (INT_SUM[348]) , .SAVE (INT_SUM[350]) , .CARRY (INT_CARRY[273]) );
   FULL_ADDER FA_237 (.DATA_A (INT_SUM[349]) , .DATA_B (INT_CARRY[255]) , .DATA_C (INT_CARRY[256]) , .SAVE (INT_SUM[352]) , .CARRY (INT_CARRY[275]) );
   FLIPFLOP LA_85 (.DIN (INT_SUM[350]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[351]) );
   FLIPFLOP LA_86 (.DIN (INT_SUM[352]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[353]) );
   FLIPFLOP LA_87 (.DIN (INT_CARRY[257]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[258]) );
   FULL_ADDER FA_238 (.DATA_A (INT_SUM[351]) , .DATA_B (INT_SUM[353]) , .DATA_C (INT_CARRY[258]) , .SAVE (INT_SUM[354]) , .CARRY (INT_CARRY[277]) );
   FLIPFLOP LA_88 (.DIN (INT_CARRY[259]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[260]) );
   assign INT_SUM[355] = INT_CARRY[260];
   FULL_ADDER FA_239 (.DATA_A (INT_SUM[354]) , .DATA_B (INT_SUM[355]) , .DATA_C (INT_CARRY[261]) , .SAVE (SUM[33]) , .CARRY (CARRY[33]) );
   FULL_ADDER FA_240 (.DATA_A (SUMMAND[321]) , .DATA_B (SUMMAND[322]) , .DATA_C (SUMMAND[323]) , .SAVE (INT_SUM[356]) , .CARRY (INT_CARRY[278]) );
   FULL_ADDER FA_241 (.DATA_A (SUMMAND[324]) , .DATA_B (SUMMAND[325]) , .DATA_C (SUMMAND[326]) , .SAVE (INT_SUM[357]) , .CARRY (INT_CARRY[279]) );
   FULL_ADDER FA_242 (.DATA_A (SUMMAND[327]) , .DATA_B (SUMMAND[328]) , .DATA_C (SUMMAND[329]) , .SAVE (INT_SUM[358]) , .CARRY (INT_CARRY[280]) );
   FULL_ADDER FA_243 (.DATA_A (SUMMAND[330]) , .DATA_B (SUMMAND[331]) , .DATA_C (SUMMAND[332]) , .SAVE (INT_SUM[359]) , .CARRY (INT_CARRY[281]) );
   FULL_ADDER FA_244 (.DATA_A (SUMMAND[333]) , .DATA_B (SUMMAND[334]) , .DATA_C (SUMMAND[335]) , .SAVE (INT_SUM[360]) , .CARRY (INT_CARRY[282]) );
   assign INT_SUM[361] = SUMMAND[336];
   FULL_ADDER FA_245 (.DATA_A (INT_SUM[356]) , .DATA_B (INT_SUM[357]) , .DATA_C (INT_SUM[358]) , .SAVE (INT_SUM[362]) , .CARRY (INT_CARRY[283]) );
   FULL_ADDER FA_246 (.DATA_A (INT_SUM[359]) , .DATA_B (INT_SUM[360]) , .DATA_C (INT_SUM[361]) , .SAVE (INT_SUM[363]) , .CARRY (INT_CARRY[284]) );
   FULL_ADDER FA_247 (.DATA_A (INT_CARRY[262]) , .DATA_B (INT_CARRY[263]) , .DATA_C (INT_CARRY[264]) , .SAVE (INT_SUM[364]) , .CARRY (INT_CARRY[285]) );
   assign INT_SUM[365] = INT_CARRY[265];
   assign INT_SUM[366] = INT_CARRY[266];
   FULL_ADDER FA_248 (.DATA_A (INT_SUM[362]) , .DATA_B (INT_SUM[363]) , .DATA_C (INT_SUM[364]) , .SAVE (INT_SUM[367]) , .CARRY (INT_CARRY[286]) );
   FULL_ADDER FA_249 (.DATA_A (INT_SUM[365]) , .DATA_B (INT_SUM[366]) , .DATA_C (INT_CARRY[267]) , .SAVE (INT_SUM[368]) , .CARRY (INT_CARRY[287]) );
   FULL_ADDER FA_250 (.DATA_A (INT_CARRY[268]) , .DATA_B (INT_CARRY[269]) , .DATA_C (INT_CARRY[270]) , .SAVE (INT_SUM[369]) , .CARRY (INT_CARRY[288]) );
   FULL_ADDER FA_251 (.DATA_A (INT_SUM[367]) , .DATA_B (INT_SUM[368]) , .DATA_C (INT_SUM[369]) , .SAVE (INT_SUM[370]) , .CARRY (INT_CARRY[289]) );
   HALF_ADDER HA_31 (.DATA_A (INT_CARRY[271]) , .DATA_B (INT_CARRY[272]) , .SAVE (INT_SUM[372]) , .CARRY (INT_CARRY[291]) );
   FLIPFLOP LA_89 (.DIN (INT_SUM[370]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[371]) );
   FLIPFLOP LA_90 (.DIN (INT_SUM[372]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[373]) );
   FLIPFLOP LA_91 (.DIN (INT_CARRY[273]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[274]) );
   FULL_ADDER FA_252 (.DATA_A (INT_SUM[371]) , .DATA_B (INT_SUM[373]) , .DATA_C (INT_CARRY[274]) , .SAVE (INT_SUM[374]) , .CARRY (INT_CARRY[293]) );
   FLIPFLOP LA_92 (.DIN (INT_CARRY[275]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[276]) );
   assign INT_SUM[375] = INT_CARRY[276];
   FULL_ADDER FA_253 (.DATA_A (INT_SUM[374]) , .DATA_B (INT_SUM[375]) , .DATA_C (INT_CARRY[277]) , .SAVE (SUM[34]) , .CARRY (CARRY[34]) );
   FULL_ADDER FA_254 (.DATA_A (SUMMAND[337]) , .DATA_B (SUMMAND[338]) , .DATA_C (SUMMAND[339]) , .SAVE (INT_SUM[376]) , .CARRY (INT_CARRY[294]) );
   FULL_ADDER FA_255 (.DATA_A (SUMMAND[340]) , .DATA_B (SUMMAND[341]) , .DATA_C (SUMMAND[342]) , .SAVE (INT_SUM[377]) , .CARRY (INT_CARRY[295]) );
   FULL_ADDER FA_256 (.DATA_A (SUMMAND[343]) , .DATA_B (SUMMAND[344]) , .DATA_C (SUMMAND[345]) , .SAVE (INT_SUM[378]) , .CARRY (INT_CARRY[296]) );
   FULL_ADDER FA_257 (.DATA_A (SUMMAND[346]) , .DATA_B (SUMMAND[347]) , .DATA_C (SUMMAND[348]) , .SAVE (INT_SUM[379]) , .CARRY (INT_CARRY[297]) );
   FULL_ADDER FA_258 (.DATA_A (SUMMAND[349]) , .DATA_B (SUMMAND[350]) , .DATA_C (SUMMAND[351]) , .SAVE (INT_SUM[380]) , .CARRY (INT_CARRY[298]) );
   FULL_ADDER FA_259 (.DATA_A (INT_SUM[376]) , .DATA_B (INT_SUM[377]) , .DATA_C (INT_SUM[378]) , .SAVE (INT_SUM[381]) , .CARRY (INT_CARRY[299]) );
   FULL_ADDER FA_260 (.DATA_A (INT_SUM[379]) , .DATA_B (INT_SUM[380]) , .DATA_C (INT_CARRY[278]) , .SAVE (INT_SUM[382]) , .CARRY (INT_CARRY[300]) );
   FULL_ADDER FA_261 (.DATA_A (INT_CARRY[279]) , .DATA_B (INT_CARRY[280]) , .DATA_C (INT_CARRY[281]) , .SAVE (INT_SUM[383]) , .CARRY (INT_CARRY[301]) );
   assign INT_SUM[384] = INT_CARRY[282];
   FULL_ADDER FA_262 (.DATA_A (INT_SUM[381]) , .DATA_B (INT_SUM[382]) , .DATA_C (INT_SUM[383]) , .SAVE (INT_SUM[385]) , .CARRY (INT_CARRY[302]) );
   FULL_ADDER FA_263 (.DATA_A (INT_SUM[384]) , .DATA_B (INT_CARRY[283]) , .DATA_C (INT_CARRY[284]) , .SAVE (INT_SUM[386]) , .CARRY (INT_CARRY[303]) );
   assign INT_SUM[387] = INT_CARRY[285];
   FULL_ADDER FA_264 (.DATA_A (INT_SUM[385]) , .DATA_B (INT_SUM[386]) , .DATA_C (INT_SUM[387]) , .SAVE (INT_SUM[388]) , .CARRY (INT_CARRY[304]) );
   FULL_ADDER FA_265 (.DATA_A (INT_CARRY[286]) , .DATA_B (INT_CARRY[287]) , .DATA_C (INT_CARRY[288]) , .SAVE (INT_SUM[390]) , .CARRY (INT_CARRY[306]) );
   FLIPFLOP LA_93 (.DIN (INT_SUM[388]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[389]) );
   FLIPFLOP LA_94 (.DIN (INT_SUM[390]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[391]) );
   FLIPFLOP LA_95 (.DIN (INT_CARRY[289]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[290]) );
   FULL_ADDER FA_266 (.DATA_A (INT_SUM[389]) , .DATA_B (INT_SUM[391]) , .DATA_C (INT_CARRY[290]) , .SAVE (INT_SUM[392]) , .CARRY (INT_CARRY[308]) );
   FLIPFLOP LA_96 (.DIN (INT_CARRY[291]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[292]) );
   assign INT_SUM[393] = INT_CARRY[292];
   FULL_ADDER FA_267 (.DATA_A (INT_SUM[392]) , .DATA_B (INT_SUM[393]) , .DATA_C (INT_CARRY[293]) , .SAVE (SUM[35]) , .CARRY (CARRY[35]) );
   FULL_ADDER FA_268 (.DATA_A (SUMMAND[352]) , .DATA_B (SUMMAND[353]) , .DATA_C (SUMMAND[354]) , .SAVE (INT_SUM[394]) , .CARRY (INT_CARRY[309]) );
   FULL_ADDER FA_269 (.DATA_A (SUMMAND[355]) , .DATA_B (SUMMAND[356]) , .DATA_C (SUMMAND[357]) , .SAVE (INT_SUM[395]) , .CARRY (INT_CARRY[310]) );
   FULL_ADDER FA_270 (.DATA_A (SUMMAND[358]) , .DATA_B (SUMMAND[359]) , .DATA_C (SUMMAND[360]) , .SAVE (INT_SUM[396]) , .CARRY (INT_CARRY[311]) );
   FULL_ADDER FA_271 (.DATA_A (SUMMAND[361]) , .DATA_B (SUMMAND[362]) , .DATA_C (SUMMAND[363]) , .SAVE (INT_SUM[397]) , .CARRY (INT_CARRY[312]) );
   FULL_ADDER FA_272 (.DATA_A (SUMMAND[364]) , .DATA_B (SUMMAND[365]) , .DATA_C (SUMMAND[366]) , .SAVE (INT_SUM[398]) , .CARRY (INT_CARRY[313]) );
   FULL_ADDER FA_273 (.DATA_A (INT_SUM[394]) , .DATA_B (INT_SUM[395]) , .DATA_C (INT_SUM[396]) , .SAVE (INT_SUM[399]) , .CARRY (INT_CARRY[314]) );
   FULL_ADDER FA_274 (.DATA_A (INT_SUM[397]) , .DATA_B (INT_SUM[398]) , .DATA_C (INT_CARRY[294]) , .SAVE (INT_SUM[400]) , .CARRY (INT_CARRY[315]) );
   FULL_ADDER FA_275 (.DATA_A (INT_CARRY[295]) , .DATA_B (INT_CARRY[296]) , .DATA_C (INT_CARRY[297]) , .SAVE (INT_SUM[401]) , .CARRY (INT_CARRY[316]) );
   assign INT_SUM[402] = INT_CARRY[298];
   FULL_ADDER FA_276 (.DATA_A (INT_SUM[399]) , .DATA_B (INT_SUM[400]) , .DATA_C (INT_SUM[401]) , .SAVE (INT_SUM[403]) , .CARRY (INT_CARRY[317]) );
   FULL_ADDER FA_277 (.DATA_A (INT_SUM[402]) , .DATA_B (INT_CARRY[299]) , .DATA_C (INT_CARRY[300]) , .SAVE (INT_SUM[404]) , .CARRY (INT_CARRY[318]) );
   assign INT_SUM[405] = INT_CARRY[301];
   FULL_ADDER FA_278 (.DATA_A (INT_SUM[403]) , .DATA_B (INT_SUM[404]) , .DATA_C (INT_SUM[405]) , .SAVE (INT_SUM[406]) , .CARRY (INT_CARRY[319]) );
   HALF_ADDER HA_32 (.DATA_A (INT_CARRY[302]) , .DATA_B (INT_CARRY[303]) , .SAVE (INT_SUM[408]) , .CARRY (INT_CARRY[321]) );
   FLIPFLOP LA_97 (.DIN (INT_SUM[406]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[407]) );
   FLIPFLOP LA_98 (.DIN (INT_SUM[408]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[409]) );
   FLIPFLOP LA_99 (.DIN (INT_CARRY[304]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[305]) );
   FULL_ADDER FA_279 (.DATA_A (INT_SUM[407]) , .DATA_B (INT_SUM[409]) , .DATA_C (INT_CARRY[305]) , .SAVE (INT_SUM[410]) , .CARRY (INT_CARRY[323]) );
   FLIPFLOP LA_100 (.DIN (INT_CARRY[306]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[307]) );
   assign INT_SUM[411] = INT_CARRY[307];
   FULL_ADDER FA_280 (.DATA_A (INT_SUM[410]) , .DATA_B (INT_SUM[411]) , .DATA_C (INT_CARRY[308]) , .SAVE (SUM[36]) , .CARRY (CARRY[36]) );
   FULL_ADDER FA_281 (.DATA_A (SUMMAND[367]) , .DATA_B (SUMMAND[368]) , .DATA_C (SUMMAND[369]) , .SAVE (INT_SUM[412]) , .CARRY (INT_CARRY[324]) );
   FULL_ADDER FA_282 (.DATA_A (SUMMAND[370]) , .DATA_B (SUMMAND[371]) , .DATA_C (SUMMAND[372]) , .SAVE (INT_SUM[413]) , .CARRY (INT_CARRY[325]) );
   FULL_ADDER FA_283 (.DATA_A (SUMMAND[373]) , .DATA_B (SUMMAND[374]) , .DATA_C (SUMMAND[375]) , .SAVE (INT_SUM[414]) , .CARRY (INT_CARRY[326]) );
   FULL_ADDER FA_284 (.DATA_A (SUMMAND[376]) , .DATA_B (SUMMAND[377]) , .DATA_C (SUMMAND[378]) , .SAVE (INT_SUM[415]) , .CARRY (INT_CARRY[327]) );
   HALF_ADDER HA_33 (.DATA_A (SUMMAND[379]) , .DATA_B (SUMMAND[380]) , .SAVE (INT_SUM[416]) , .CARRY (INT_CARRY[328]) );
   FULL_ADDER FA_285 (.DATA_A (INT_SUM[412]) , .DATA_B (INT_SUM[413]) , .DATA_C (INT_SUM[414]) , .SAVE (INT_SUM[417]) , .CARRY (INT_CARRY[329]) );
   FULL_ADDER FA_286 (.DATA_A (INT_SUM[415]) , .DATA_B (INT_SUM[416]) , .DATA_C (INT_CARRY[309]) , .SAVE (INT_SUM[418]) , .CARRY (INT_CARRY[330]) );
   FULL_ADDER FA_287 (.DATA_A (INT_CARRY[310]) , .DATA_B (INT_CARRY[311]) , .DATA_C (INT_CARRY[312]) , .SAVE (INT_SUM[419]) , .CARRY (INT_CARRY[331]) );
   assign INT_SUM[420] = INT_CARRY[313];
   FULL_ADDER FA_288 (.DATA_A (INT_SUM[417]) , .DATA_B (INT_SUM[418]) , .DATA_C (INT_SUM[419]) , .SAVE (INT_SUM[421]) , .CARRY (INT_CARRY[332]) );
   FULL_ADDER FA_289 (.DATA_A (INT_SUM[420]) , .DATA_B (INT_CARRY[314]) , .DATA_C (INT_CARRY[315]) , .SAVE (INT_SUM[422]) , .CARRY (INT_CARRY[333]) );
   assign INT_SUM[423] = INT_CARRY[316];
   FULL_ADDER FA_290 (.DATA_A (INT_SUM[421]) , .DATA_B (INT_SUM[422]) , .DATA_C (INT_SUM[423]) , .SAVE (INT_SUM[424]) , .CARRY (INT_CARRY[334]) );
   HALF_ADDER HA_34 (.DATA_A (INT_CARRY[317]) , .DATA_B (INT_CARRY[318]) , .SAVE (INT_SUM[426]) , .CARRY (INT_CARRY[336]) );
   FLIPFLOP LA_101 (.DIN (INT_SUM[424]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[425]) );
   FLIPFLOP LA_102 (.DIN (INT_SUM[426]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[427]) );
   FLIPFLOP LA_103 (.DIN (INT_CARRY[319]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[320]) );
   FULL_ADDER FA_291 (.DATA_A (INT_SUM[425]) , .DATA_B (INT_SUM[427]) , .DATA_C (INT_CARRY[320]) , .SAVE (INT_SUM[428]) , .CARRY (INT_CARRY[338]) );
   FLIPFLOP LA_104 (.DIN (INT_CARRY[321]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[322]) );
   assign INT_SUM[429] = INT_CARRY[322];
   FULL_ADDER FA_292 (.DATA_A (INT_SUM[428]) , .DATA_B (INT_SUM[429]) , .DATA_C (INT_CARRY[323]) , .SAVE (SUM[37]) , .CARRY (CARRY[37]) );
   FULL_ADDER FA_293 (.DATA_A (SUMMAND[381]) , .DATA_B (SUMMAND[382]) , .DATA_C (SUMMAND[383]) , .SAVE (INT_SUM[430]) , .CARRY (INT_CARRY[339]) );
   FULL_ADDER FA_294 (.DATA_A (SUMMAND[384]) , .DATA_B (SUMMAND[385]) , .DATA_C (SUMMAND[386]) , .SAVE (INT_SUM[431]) , .CARRY (INT_CARRY[340]) );
   FULL_ADDER FA_295 (.DATA_A (SUMMAND[387]) , .DATA_B (SUMMAND[388]) , .DATA_C (SUMMAND[389]) , .SAVE (INT_SUM[432]) , .CARRY (INT_CARRY[341]) );
   FULL_ADDER FA_296 (.DATA_A (SUMMAND[390]) , .DATA_B (SUMMAND[391]) , .DATA_C (SUMMAND[392]) , .SAVE (INT_SUM[433]) , .CARRY (INT_CARRY[342]) );
   HALF_ADDER HA_35 (.DATA_A (SUMMAND[393]) , .DATA_B (SUMMAND[394]) , .SAVE (INT_SUM[434]) , .CARRY (INT_CARRY[343]) );
   FULL_ADDER FA_297 (.DATA_A (INT_SUM[430]) , .DATA_B (INT_SUM[431]) , .DATA_C (INT_SUM[432]) , .SAVE (INT_SUM[435]) , .CARRY (INT_CARRY[344]) );
   FULL_ADDER FA_298 (.DATA_A (INT_SUM[433]) , .DATA_B (INT_SUM[434]) , .DATA_C (INT_CARRY[324]) , .SAVE (INT_SUM[436]) , .CARRY (INT_CARRY[345]) );
   FULL_ADDER FA_299 (.DATA_A (INT_CARRY[325]) , .DATA_B (INT_CARRY[326]) , .DATA_C (INT_CARRY[327]) , .SAVE (INT_SUM[437]) , .CARRY (INT_CARRY[346]) );
   assign INT_SUM[438] = INT_CARRY[328];
   FULL_ADDER FA_300 (.DATA_A (INT_SUM[435]) , .DATA_B (INT_SUM[436]) , .DATA_C (INT_SUM[437]) , .SAVE (INT_SUM[439]) , .CARRY (INT_CARRY[347]) );
   FULL_ADDER FA_301 (.DATA_A (INT_SUM[438]) , .DATA_B (INT_CARRY[329]) , .DATA_C (INT_CARRY[330]) , .SAVE (INT_SUM[440]) , .CARRY (INT_CARRY[348]) );
   assign INT_SUM[441] = INT_CARRY[331];
   FULL_ADDER FA_302 (.DATA_A (INT_SUM[439]) , .DATA_B (INT_SUM[440]) , .DATA_C (INT_SUM[441]) , .SAVE (INT_SUM[442]) , .CARRY (INT_CARRY[349]) );
   HALF_ADDER HA_36 (.DATA_A (INT_CARRY[332]) , .DATA_B (INT_CARRY[333]) , .SAVE (INT_SUM[444]) , .CARRY (INT_CARRY[351]) );
   FLIPFLOP LA_105 (.DIN (INT_SUM[442]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[443]) );
   FLIPFLOP LA_106 (.DIN (INT_SUM[444]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[445]) );
   FLIPFLOP LA_107 (.DIN (INT_CARRY[334]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[335]) );
   FULL_ADDER FA_303 (.DATA_A (INT_SUM[443]) , .DATA_B (INT_SUM[445]) , .DATA_C (INT_CARRY[335]) , .SAVE (INT_SUM[446]) , .CARRY (INT_CARRY[353]) );
   FLIPFLOP LA_108 (.DIN (INT_CARRY[336]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[337]) );
   assign INT_SUM[447] = INT_CARRY[337];
   FULL_ADDER FA_304 (.DATA_A (INT_SUM[446]) , .DATA_B (INT_SUM[447]) , .DATA_C (INT_CARRY[338]) , .SAVE (SUM[38]) , .CARRY (CARRY[38]) );
   FULL_ADDER FA_305 (.DATA_A (SUMMAND[395]) , .DATA_B (SUMMAND[396]) , .DATA_C (SUMMAND[397]) , .SAVE (INT_SUM[448]) , .CARRY (INT_CARRY[354]) );
   FULL_ADDER FA_306 (.DATA_A (SUMMAND[398]) , .DATA_B (SUMMAND[399]) , .DATA_C (SUMMAND[400]) , .SAVE (INT_SUM[449]) , .CARRY (INT_CARRY[355]) );
   FULL_ADDER FA_307 (.DATA_A (SUMMAND[401]) , .DATA_B (SUMMAND[402]) , .DATA_C (SUMMAND[403]) , .SAVE (INT_SUM[450]) , .CARRY (INT_CARRY[356]) );
   FULL_ADDER FA_308 (.DATA_A (SUMMAND[404]) , .DATA_B (SUMMAND[405]) , .DATA_C (SUMMAND[406]) , .SAVE (INT_SUM[451]) , .CARRY (INT_CARRY[357]) );
   assign INT_SUM[452] = SUMMAND[407];
   FULL_ADDER FA_309 (.DATA_A (INT_SUM[448]) , .DATA_B (INT_SUM[449]) , .DATA_C (INT_SUM[450]) , .SAVE (INT_SUM[453]) , .CARRY (INT_CARRY[358]) );
   FULL_ADDER FA_310 (.DATA_A (INT_SUM[451]) , .DATA_B (INT_SUM[452]) , .DATA_C (INT_CARRY[339]) , .SAVE (INT_SUM[454]) , .CARRY (INT_CARRY[359]) );
   FULL_ADDER FA_311 (.DATA_A (INT_CARRY[340]) , .DATA_B (INT_CARRY[341]) , .DATA_C (INT_CARRY[342]) , .SAVE (INT_SUM[455]) , .CARRY (INT_CARRY[360]) );
   assign INT_SUM[456] = INT_CARRY[343];
   FULL_ADDER FA_312 (.DATA_A (INT_SUM[453]) , .DATA_B (INT_SUM[454]) , .DATA_C (INT_SUM[455]) , .SAVE (INT_SUM[457]) , .CARRY (INT_CARRY[361]) );
   FULL_ADDER FA_313 (.DATA_A (INT_SUM[456]) , .DATA_B (INT_CARRY[344]) , .DATA_C (INT_CARRY[345]) , .SAVE (INT_SUM[458]) , .CARRY (INT_CARRY[362]) );
   assign INT_SUM[459] = INT_CARRY[346];
   FULL_ADDER FA_314 (.DATA_A (INT_SUM[457]) , .DATA_B (INT_SUM[458]) , .DATA_C (INT_SUM[459]) , .SAVE (INT_SUM[460]) , .CARRY (INT_CARRY[363]) );
   HALF_ADDER HA_37 (.DATA_A (INT_CARRY[347]) , .DATA_B (INT_CARRY[348]) , .SAVE (INT_SUM[462]) , .CARRY (INT_CARRY[365]) );
   FLIPFLOP LA_109 (.DIN (INT_SUM[460]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[461]) );
   FLIPFLOP LA_110 (.DIN (INT_SUM[462]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[463]) );
   FLIPFLOP LA_111 (.DIN (INT_CARRY[349]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[350]) );
   FULL_ADDER FA_315 (.DATA_A (INT_SUM[461]) , .DATA_B (INT_SUM[463]) , .DATA_C (INT_CARRY[350]) , .SAVE (INT_SUM[464]) , .CARRY (INT_CARRY[367]) );
   FLIPFLOP LA_112 (.DIN (INT_CARRY[351]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[352]) );
   assign INT_SUM[465] = INT_CARRY[352];
   FULL_ADDER FA_316 (.DATA_A (INT_SUM[464]) , .DATA_B (INT_SUM[465]) , .DATA_C (INT_CARRY[353]) , .SAVE (SUM[39]) , .CARRY (CARRY[39]) );
   FULL_ADDER FA_317 (.DATA_A (SUMMAND[408]) , .DATA_B (SUMMAND[409]) , .DATA_C (SUMMAND[410]) , .SAVE (INT_SUM[466]) , .CARRY (INT_CARRY[368]) );
   FULL_ADDER FA_318 (.DATA_A (SUMMAND[411]) , .DATA_B (SUMMAND[412]) , .DATA_C (SUMMAND[413]) , .SAVE (INT_SUM[467]) , .CARRY (INT_CARRY[369]) );
   FULL_ADDER FA_319 (.DATA_A (SUMMAND[414]) , .DATA_B (SUMMAND[415]) , .DATA_C (SUMMAND[416]) , .SAVE (INT_SUM[468]) , .CARRY (INT_CARRY[370]) );
   FULL_ADDER FA_320 (.DATA_A (SUMMAND[417]) , .DATA_B (SUMMAND[418]) , .DATA_C (SUMMAND[419]) , .SAVE (INT_SUM[469]) , .CARRY (INT_CARRY[371]) );
   FULL_ADDER FA_321 (.DATA_A (SUMMAND[420]) , .DATA_B (INT_CARRY[354]) , .DATA_C (INT_CARRY[355]) , .SAVE (INT_SUM[470]) , .CARRY (INT_CARRY[372]) );
   assign INT_SUM[471] = INT_CARRY[356];
   assign INT_SUM[472] = INT_CARRY[357];
   FULL_ADDER FA_322 (.DATA_A (INT_SUM[466]) , .DATA_B (INT_SUM[467]) , .DATA_C (INT_SUM[468]) , .SAVE (INT_SUM[473]) , .CARRY (INT_CARRY[373]) );
   FULL_ADDER FA_323 (.DATA_A (INT_SUM[469]) , .DATA_B (INT_SUM[470]) , .DATA_C (INT_SUM[471]) , .SAVE (INT_SUM[474]) , .CARRY (INT_CARRY[374]) );
   FULL_ADDER FA_324 (.DATA_A (INT_SUM[472]) , .DATA_B (INT_CARRY[358]) , .DATA_C (INT_CARRY[359]) , .SAVE (INT_SUM[475]) , .CARRY (INT_CARRY[375]) );
   assign INT_SUM[476] = INT_CARRY[360];
   FULL_ADDER FA_325 (.DATA_A (INT_SUM[473]) , .DATA_B (INT_SUM[474]) , .DATA_C (INT_SUM[475]) , .SAVE (INT_SUM[477]) , .CARRY (INT_CARRY[376]) );
   FULL_ADDER FA_326 (.DATA_A (INT_SUM[476]) , .DATA_B (INT_CARRY[361]) , .DATA_C (INT_CARRY[362]) , .SAVE (INT_SUM[479]) , .CARRY (INT_CARRY[378]) );
   FLIPFLOP LA_113 (.DIN (INT_SUM[477]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[478]) );
   FLIPFLOP LA_114 (.DIN (INT_SUM[479]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[480]) );
   FLIPFLOP LA_115 (.DIN (INT_CARRY[363]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[364]) );
   FULL_ADDER FA_327 (.DATA_A (INT_SUM[478]) , .DATA_B (INT_SUM[480]) , .DATA_C (INT_CARRY[364]) , .SAVE (INT_SUM[481]) , .CARRY (INT_CARRY[380]) );
   FLIPFLOP LA_116 (.DIN (INT_CARRY[365]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[366]) );
   assign INT_SUM[482] = INT_CARRY[366];
   FULL_ADDER FA_328 (.DATA_A (INT_SUM[481]) , .DATA_B (INT_SUM[482]) , .DATA_C (INT_CARRY[367]) , .SAVE (SUM[40]) , .CARRY (CARRY[40]) );
   FULL_ADDER FA_329 (.DATA_A (SUMMAND[421]) , .DATA_B (SUMMAND[422]) , .DATA_C (SUMMAND[423]) , .SAVE (INT_SUM[483]) , .CARRY (INT_CARRY[381]) );
   FULL_ADDER FA_330 (.DATA_A (SUMMAND[424]) , .DATA_B (SUMMAND[425]) , .DATA_C (SUMMAND[426]) , .SAVE (INT_SUM[484]) , .CARRY (INT_CARRY[382]) );
   FULL_ADDER FA_331 (.DATA_A (SUMMAND[427]) , .DATA_B (SUMMAND[428]) , .DATA_C (SUMMAND[429]) , .SAVE (INT_SUM[485]) , .CARRY (INT_CARRY[383]) );
   FULL_ADDER FA_332 (.DATA_A (SUMMAND[430]) , .DATA_B (SUMMAND[431]) , .DATA_C (SUMMAND[432]) , .SAVE (INT_SUM[486]) , .CARRY (INT_CARRY[384]) );
   FULL_ADDER FA_333 (.DATA_A (INT_SUM[483]) , .DATA_B (INT_SUM[484]) , .DATA_C (INT_SUM[485]) , .SAVE (INT_SUM[487]) , .CARRY (INT_CARRY[385]) );
   FULL_ADDER FA_334 (.DATA_A (INT_SUM[486]) , .DATA_B (INT_CARRY[368]) , .DATA_C (INT_CARRY[369]) , .SAVE (INT_SUM[488]) , .CARRY (INT_CARRY[386]) );
   FULL_ADDER FA_335 (.DATA_A (INT_CARRY[370]) , .DATA_B (INT_CARRY[371]) , .DATA_C (INT_CARRY[372]) , .SAVE (INT_SUM[489]) , .CARRY (INT_CARRY[387]) );
   FULL_ADDER FA_336 (.DATA_A (INT_SUM[487]) , .DATA_B (INT_SUM[488]) , .DATA_C (INT_SUM[489]) , .SAVE (INT_SUM[490]) , .CARRY (INT_CARRY[388]) );
   FULL_ADDER FA_337 (.DATA_A (INT_CARRY[373]) , .DATA_B (INT_CARRY[374]) , .DATA_C (INT_CARRY[375]) , .SAVE (INT_SUM[492]) , .CARRY (INT_CARRY[390]) );
   FLIPFLOP LA_117 (.DIN (INT_SUM[490]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[491]) );
   FLIPFLOP LA_118 (.DIN (INT_SUM[492]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[493]) );
   FLIPFLOP LA_119 (.DIN (INT_CARRY[376]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[377]) );
   FULL_ADDER FA_338 (.DATA_A (INT_SUM[491]) , .DATA_B (INT_SUM[493]) , .DATA_C (INT_CARRY[377]) , .SAVE (INT_SUM[494]) , .CARRY (INT_CARRY[392]) );
   FLIPFLOP LA_120 (.DIN (INT_CARRY[378]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[379]) );
   assign INT_SUM[495] = INT_CARRY[379];
   FULL_ADDER FA_339 (.DATA_A (INT_SUM[494]) , .DATA_B (INT_SUM[495]) , .DATA_C (INT_CARRY[380]) , .SAVE (SUM[41]) , .CARRY (CARRY[41]) );
   FULL_ADDER FA_340 (.DATA_A (SUMMAND[433]) , .DATA_B (SUMMAND[434]) , .DATA_C (SUMMAND[435]) , .SAVE (INT_SUM[496]) , .CARRY (INT_CARRY[393]) );
   FULL_ADDER FA_341 (.DATA_A (SUMMAND[436]) , .DATA_B (SUMMAND[437]) , .DATA_C (SUMMAND[438]) , .SAVE (INT_SUM[497]) , .CARRY (INT_CARRY[394]) );
   FULL_ADDER FA_342 (.DATA_A (SUMMAND[439]) , .DATA_B (SUMMAND[440]) , .DATA_C (SUMMAND[441]) , .SAVE (INT_SUM[498]) , .CARRY (INT_CARRY[395]) );
   FULL_ADDER FA_343 (.DATA_A (SUMMAND[442]) , .DATA_B (SUMMAND[443]) , .DATA_C (SUMMAND[444]) , .SAVE (INT_SUM[499]) , .CARRY (INT_CARRY[396]) );
   FULL_ADDER FA_344 (.DATA_A (INT_SUM[496]) , .DATA_B (INT_SUM[497]) , .DATA_C (INT_SUM[498]) , .SAVE (INT_SUM[500]) , .CARRY (INT_CARRY[397]) );
   FULL_ADDER FA_345 (.DATA_A (INT_SUM[499]) , .DATA_B (INT_CARRY[381]) , .DATA_C (INT_CARRY[382]) , .SAVE (INT_SUM[501]) , .CARRY (INT_CARRY[398]) );
   HALF_ADDER HA_38 (.DATA_A (INT_CARRY[383]) , .DATA_B (INT_CARRY[384]) , .SAVE (INT_SUM[502]) , .CARRY (INT_CARRY[399]) );
   FULL_ADDER FA_346 (.DATA_A (INT_SUM[500]) , .DATA_B (INT_SUM[501]) , .DATA_C (INT_SUM[502]) , .SAVE (INT_SUM[503]) , .CARRY (INT_CARRY[400]) );
   FULL_ADDER FA_347 (.DATA_A (INT_CARRY[385]) , .DATA_B (INT_CARRY[386]) , .DATA_C (INT_CARRY[387]) , .SAVE (INT_SUM[505]) , .CARRY (INT_CARRY[402]) );
   FLIPFLOP LA_121 (.DIN (INT_SUM[503]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[504]) );
   FLIPFLOP LA_122 (.DIN (INT_SUM[505]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[506]) );
   FLIPFLOP LA_123 (.DIN (INT_CARRY[388]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[389]) );
   FULL_ADDER FA_348 (.DATA_A (INT_SUM[504]) , .DATA_B (INT_SUM[506]) , .DATA_C (INT_CARRY[389]) , .SAVE (INT_SUM[507]) , .CARRY (INT_CARRY[404]) );
   FLIPFLOP LA_124 (.DIN (INT_CARRY[390]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[391]) );
   assign INT_SUM[508] = INT_CARRY[391];
   FULL_ADDER FA_349 (.DATA_A (INT_SUM[507]) , .DATA_B (INT_SUM[508]) , .DATA_C (INT_CARRY[392]) , .SAVE (SUM[42]) , .CARRY (CARRY[42]) );
   FULL_ADDER FA_350 (.DATA_A (SUMMAND[445]) , .DATA_B (SUMMAND[446]) , .DATA_C (SUMMAND[447]) , .SAVE (INT_SUM[509]) , .CARRY (INT_CARRY[405]) );
   FULL_ADDER FA_351 (.DATA_A (SUMMAND[448]) , .DATA_B (SUMMAND[449]) , .DATA_C (SUMMAND[450]) , .SAVE (INT_SUM[510]) , .CARRY (INT_CARRY[406]) );
   FULL_ADDER FA_352 (.DATA_A (SUMMAND[451]) , .DATA_B (SUMMAND[452]) , .DATA_C (SUMMAND[453]) , .SAVE (INT_SUM[511]) , .CARRY (INT_CARRY[407]) );
   assign INT_SUM[512] = SUMMAND[454];
   assign INT_SUM[513] = SUMMAND[455];
   FULL_ADDER FA_353 (.DATA_A (INT_SUM[509]) , .DATA_B (INT_SUM[510]) , .DATA_C (INT_SUM[511]) , .SAVE (INT_SUM[514]) , .CARRY (INT_CARRY[408]) );
   FULL_ADDER FA_354 (.DATA_A (INT_SUM[512]) , .DATA_B (INT_SUM[513]) , .DATA_C (INT_CARRY[393]) , .SAVE (INT_SUM[515]) , .CARRY (INT_CARRY[409]) );
   FULL_ADDER FA_355 (.DATA_A (INT_CARRY[394]) , .DATA_B (INT_CARRY[395]) , .DATA_C (INT_CARRY[396]) , .SAVE (INT_SUM[516]) , .CARRY (INT_CARRY[410]) );
   FULL_ADDER FA_356 (.DATA_A (INT_SUM[514]) , .DATA_B (INT_SUM[515]) , .DATA_C (INT_SUM[516]) , .SAVE (INT_SUM[517]) , .CARRY (INT_CARRY[411]) );
   FULL_ADDER FA_357 (.DATA_A (INT_CARRY[397]) , .DATA_B (INT_CARRY[398]) , .DATA_C (INT_CARRY[399]) , .SAVE (INT_SUM[519]) , .CARRY (INT_CARRY[413]) );
   FLIPFLOP LA_125 (.DIN (INT_SUM[517]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[518]) );
   FLIPFLOP LA_126 (.DIN (INT_SUM[519]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[520]) );
   FLIPFLOP LA_127 (.DIN (INT_CARRY[400]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[401]) );
   FULL_ADDER FA_358 (.DATA_A (INT_SUM[518]) , .DATA_B (INT_SUM[520]) , .DATA_C (INT_CARRY[401]) , .SAVE (INT_SUM[521]) , .CARRY (INT_CARRY[415]) );
   FLIPFLOP LA_128 (.DIN (INT_CARRY[402]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[403]) );
   assign INT_SUM[522] = INT_CARRY[403];
   FULL_ADDER FA_359 (.DATA_A (INT_SUM[521]) , .DATA_B (INT_SUM[522]) , .DATA_C (INT_CARRY[404]) , .SAVE (SUM[43]) , .CARRY (CARRY[43]) );
   FULL_ADDER FA_360 (.DATA_A (SUMMAND[456]) , .DATA_B (SUMMAND[457]) , .DATA_C (SUMMAND[458]) , .SAVE (INT_SUM[523]) , .CARRY (INT_CARRY[416]) );
   FULL_ADDER FA_361 (.DATA_A (SUMMAND[459]) , .DATA_B (SUMMAND[460]) , .DATA_C (SUMMAND[461]) , .SAVE (INT_SUM[524]) , .CARRY (INT_CARRY[417]) );
   FULL_ADDER FA_362 (.DATA_A (SUMMAND[462]) , .DATA_B (SUMMAND[463]) , .DATA_C (SUMMAND[464]) , .SAVE (INT_SUM[525]) , .CARRY (INT_CARRY[418]) );
   HALF_ADDER HA_39 (.DATA_A (SUMMAND[465]) , .DATA_B (SUMMAND[466]) , .SAVE (INT_SUM[526]) , .CARRY (INT_CARRY[419]) );
   FULL_ADDER FA_363 (.DATA_A (INT_SUM[523]) , .DATA_B (INT_SUM[524]) , .DATA_C (INT_SUM[525]) , .SAVE (INT_SUM[527]) , .CARRY (INT_CARRY[420]) );
   FULL_ADDER FA_364 (.DATA_A (INT_SUM[526]) , .DATA_B (INT_CARRY[405]) , .DATA_C (INT_CARRY[406]) , .SAVE (INT_SUM[528]) , .CARRY (INT_CARRY[421]) );
   assign INT_SUM[529] = INT_CARRY[407];
   FULL_ADDER FA_365 (.DATA_A (INT_SUM[527]) , .DATA_B (INT_SUM[528]) , .DATA_C (INT_SUM[529]) , .SAVE (INT_SUM[530]) , .CARRY (INT_CARRY[422]) );
   FULL_ADDER FA_366 (.DATA_A (INT_CARRY[408]) , .DATA_B (INT_CARRY[409]) , .DATA_C (INT_CARRY[410]) , .SAVE (INT_SUM[532]) , .CARRY (INT_CARRY[424]) );
   FLIPFLOP LA_129 (.DIN (INT_SUM[530]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[531]) );
   FLIPFLOP LA_130 (.DIN (INT_SUM[532]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[533]) );
   FLIPFLOP LA_131 (.DIN (INT_CARRY[411]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[412]) );
   FULL_ADDER FA_367 (.DATA_A (INT_SUM[531]) , .DATA_B (INT_SUM[533]) , .DATA_C (INT_CARRY[412]) , .SAVE (INT_SUM[534]) , .CARRY (INT_CARRY[426]) );
   FLIPFLOP LA_132 (.DIN (INT_CARRY[413]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[414]) );
   assign INT_SUM[535] = INT_CARRY[414];
   FULL_ADDER FA_368 (.DATA_A (INT_SUM[534]) , .DATA_B (INT_SUM[535]) , .DATA_C (INT_CARRY[415]) , .SAVE (SUM[44]) , .CARRY (CARRY[44]) );
   FULL_ADDER FA_369 (.DATA_A (SUMMAND[467]) , .DATA_B (SUMMAND[468]) , .DATA_C (SUMMAND[469]) , .SAVE (INT_SUM[536]) , .CARRY (INT_CARRY[427]) );
   FULL_ADDER FA_370 (.DATA_A (SUMMAND[470]) , .DATA_B (SUMMAND[471]) , .DATA_C (SUMMAND[472]) , .SAVE (INT_SUM[537]) , .CARRY (INT_CARRY[428]) );
   FULL_ADDER FA_371 (.DATA_A (SUMMAND[473]) , .DATA_B (SUMMAND[474]) , .DATA_C (SUMMAND[475]) , .SAVE (INT_SUM[538]) , .CARRY (INT_CARRY[429]) );
   assign INT_SUM[539] = SUMMAND[476];
   FULL_ADDER FA_372 (.DATA_A (INT_SUM[536]) , .DATA_B (INT_SUM[537]) , .DATA_C (INT_SUM[538]) , .SAVE (INT_SUM[540]) , .CARRY (INT_CARRY[430]) );
   FULL_ADDER FA_373 (.DATA_A (INT_SUM[539]) , .DATA_B (INT_CARRY[416]) , .DATA_C (INT_CARRY[417]) , .SAVE (INT_SUM[541]) , .CARRY (INT_CARRY[431]) );
   assign INT_SUM[542] = INT_CARRY[418];
   assign INT_SUM[543] = INT_CARRY[419];
   FULL_ADDER FA_374 (.DATA_A (INT_SUM[540]) , .DATA_B (INT_SUM[541]) , .DATA_C (INT_SUM[542]) , .SAVE (INT_SUM[544]) , .CARRY (INT_CARRY[432]) );
   FULL_ADDER FA_375 (.DATA_A (INT_SUM[543]) , .DATA_B (INT_CARRY[420]) , .DATA_C (INT_CARRY[421]) , .SAVE (INT_SUM[546]) , .CARRY (INT_CARRY[434]) );
   FLIPFLOP LA_133 (.DIN (INT_SUM[544]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[545]) );
   FLIPFLOP LA_134 (.DIN (INT_SUM[546]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[547]) );
   FLIPFLOP LA_135 (.DIN (INT_CARRY[422]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[423]) );
   FULL_ADDER FA_376 (.DATA_A (INT_SUM[545]) , .DATA_B (INT_SUM[547]) , .DATA_C (INT_CARRY[423]) , .SAVE (INT_SUM[548]) , .CARRY (INT_CARRY[436]) );
   FLIPFLOP LA_136 (.DIN (INT_CARRY[424]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[425]) );
   assign INT_SUM[549] = INT_CARRY[425];
   FULL_ADDER FA_377 (.DATA_A (INT_SUM[548]) , .DATA_B (INT_SUM[549]) , .DATA_C (INT_CARRY[426]) , .SAVE (SUM[45]) , .CARRY (CARRY[45]) );
   FULL_ADDER FA_378 (.DATA_A (SUMMAND[477]) , .DATA_B (SUMMAND[478]) , .DATA_C (SUMMAND[479]) , .SAVE (INT_SUM[550]) , .CARRY (INT_CARRY[437]) );
   FULL_ADDER FA_379 (.DATA_A (SUMMAND[480]) , .DATA_B (SUMMAND[481]) , .DATA_C (SUMMAND[482]) , .SAVE (INT_SUM[551]) , .CARRY (INT_CARRY[438]) );
   FULL_ADDER FA_380 (.DATA_A (SUMMAND[483]) , .DATA_B (SUMMAND[484]) , .DATA_C (SUMMAND[485]) , .SAVE (INT_SUM[552]) , .CARRY (INT_CARRY[439]) );
   assign INT_SUM[553] = SUMMAND[486];
   FULL_ADDER FA_381 (.DATA_A (INT_SUM[550]) , .DATA_B (INT_SUM[551]) , .DATA_C (INT_SUM[552]) , .SAVE (INT_SUM[554]) , .CARRY (INT_CARRY[440]) );
   FULL_ADDER FA_382 (.DATA_A (INT_SUM[553]) , .DATA_B (INT_CARRY[427]) , .DATA_C (INT_CARRY[428]) , .SAVE (INT_SUM[555]) , .CARRY (INT_CARRY[441]) );
   assign INT_SUM[556] = INT_CARRY[429];
   FULL_ADDER FA_383 (.DATA_A (INT_SUM[554]) , .DATA_B (INT_SUM[555]) , .DATA_C (INT_SUM[556]) , .SAVE (INT_SUM[557]) , .CARRY (INT_CARRY[442]) );
   HALF_ADDER HA_40 (.DATA_A (INT_CARRY[430]) , .DATA_B (INT_CARRY[431]) , .SAVE (INT_SUM[559]) , .CARRY (INT_CARRY[444]) );
   FLIPFLOP LA_137 (.DIN (INT_SUM[557]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[558]) );
   FLIPFLOP LA_138 (.DIN (INT_SUM[559]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[560]) );
   FLIPFLOP LA_139 (.DIN (INT_CARRY[432]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[433]) );
   FULL_ADDER FA_384 (.DATA_A (INT_SUM[558]) , .DATA_B (INT_SUM[560]) , .DATA_C (INT_CARRY[433]) , .SAVE (INT_SUM[561]) , .CARRY (INT_CARRY[446]) );
   FLIPFLOP LA_140 (.DIN (INT_CARRY[434]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[435]) );
   assign INT_SUM[562] = INT_CARRY[435];
   FULL_ADDER FA_385 (.DATA_A (INT_SUM[561]) , .DATA_B (INT_SUM[562]) , .DATA_C (INT_CARRY[436]) , .SAVE (SUM[46]) , .CARRY (CARRY[46]) );
   FULL_ADDER FA_386 (.DATA_A (SUMMAND[487]) , .DATA_B (SUMMAND[488]) , .DATA_C (SUMMAND[489]) , .SAVE (INT_SUM[563]) , .CARRY (INT_CARRY[447]) );
   FULL_ADDER FA_387 (.DATA_A (SUMMAND[490]) , .DATA_B (SUMMAND[491]) , .DATA_C (SUMMAND[492]) , .SAVE (INT_SUM[564]) , .CARRY (INT_CARRY[448]) );
   FULL_ADDER FA_388 (.DATA_A (SUMMAND[493]) , .DATA_B (SUMMAND[494]) , .DATA_C (SUMMAND[495]) , .SAVE (INT_SUM[565]) , .CARRY (INT_CARRY[449]) );
   FULL_ADDER FA_389 (.DATA_A (INT_SUM[563]) , .DATA_B (INT_SUM[564]) , .DATA_C (INT_SUM[565]) , .SAVE (INT_SUM[566]) , .CARRY (INT_CARRY[450]) );
   FULL_ADDER FA_390 (.DATA_A (INT_CARRY[437]) , .DATA_B (INT_CARRY[438]) , .DATA_C (INT_CARRY[439]) , .SAVE (INT_SUM[567]) , .CARRY (INT_CARRY[451]) );
   FULL_ADDER FA_391 (.DATA_A (INT_SUM[566]) , .DATA_B (INT_SUM[567]) , .DATA_C (INT_CARRY[440]) , .SAVE (INT_SUM[568]) , .CARRY (INT_CARRY[452]) );
   assign INT_SUM[570] = INT_CARRY[441];
   FLIPFLOP LA_141 (.DIN (INT_SUM[568]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[569]) );
   FLIPFLOP LA_142 (.DIN (INT_SUM[570]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[571]) );
   FLIPFLOP LA_143 (.DIN (INT_CARRY[442]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[443]) );
   FULL_ADDER FA_392 (.DATA_A (INT_SUM[569]) , .DATA_B (INT_SUM[571]) , .DATA_C (INT_CARRY[443]) , .SAVE (INT_SUM[572]) , .CARRY (INT_CARRY[454]) );
   FLIPFLOP LA_144 (.DIN (INT_CARRY[444]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[445]) );
   assign INT_SUM[573] = INT_CARRY[445];
   FULL_ADDER FA_393 (.DATA_A (INT_SUM[572]) , .DATA_B (INT_SUM[573]) , .DATA_C (INT_CARRY[446]) , .SAVE (SUM[47]) , .CARRY (CARRY[47]) );
   FULL_ADDER FA_394 (.DATA_A (SUMMAND[496]) , .DATA_B (SUMMAND[497]) , .DATA_C (SUMMAND[498]) , .SAVE (INT_SUM[574]) , .CARRY (INT_CARRY[455]) );
   FULL_ADDER FA_395 (.DATA_A (SUMMAND[499]) , .DATA_B (SUMMAND[500]) , .DATA_C (SUMMAND[501]) , .SAVE (INT_SUM[575]) , .CARRY (INT_CARRY[456]) );
   FULL_ADDER FA_396 (.DATA_A (SUMMAND[502]) , .DATA_B (SUMMAND[503]) , .DATA_C (SUMMAND[504]) , .SAVE (INT_SUM[576]) , .CARRY (INT_CARRY[457]) );
   FULL_ADDER FA_397 (.DATA_A (INT_SUM[574]) , .DATA_B (INT_SUM[575]) , .DATA_C (INT_SUM[576]) , .SAVE (INT_SUM[577]) , .CARRY (INT_CARRY[458]) );
   FULL_ADDER FA_398 (.DATA_A (INT_CARRY[447]) , .DATA_B (INT_CARRY[448]) , .DATA_C (INT_CARRY[449]) , .SAVE (INT_SUM[578]) , .CARRY (INT_CARRY[459]) );
   FULL_ADDER FA_399 (.DATA_A (INT_SUM[577]) , .DATA_B (INT_SUM[578]) , .DATA_C (INT_CARRY[450]) , .SAVE (INT_SUM[579]) , .CARRY (INT_CARRY[460]) );
   assign INT_SUM[581] = INT_CARRY[451];
   FLIPFLOP LA_145 (.DIN (INT_SUM[579]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[580]) );
   FLIPFLOP LA_146 (.DIN (INT_SUM[581]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[582]) );
   FLIPFLOP LA_147 (.DIN (INT_CARRY[452]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[453]) );
   FULL_ADDER FA_400 (.DATA_A (INT_SUM[580]) , .DATA_B (INT_SUM[582]) , .DATA_C (INT_CARRY[453]) , .SAVE (INT_SUM[583]) , .CARRY (INT_CARRY[462]) );
   HALF_ADDER HA_41 (.DATA_A (INT_SUM[583]) , .DATA_B (INT_CARRY[454]) , .SAVE (SUM[48]) , .CARRY (CARRY[48]) );
   FULL_ADDER FA_401 (.DATA_A (SUMMAND[505]) , .DATA_B (SUMMAND[506]) , .DATA_C (SUMMAND[507]) , .SAVE (INT_SUM[584]) , .CARRY (INT_CARRY[463]) );
   FULL_ADDER FA_402 (.DATA_A (SUMMAND[508]) , .DATA_B (SUMMAND[509]) , .DATA_C (SUMMAND[510]) , .SAVE (INT_SUM[585]) , .CARRY (INT_CARRY[464]) );
   FULL_ADDER FA_403 (.DATA_A (SUMMAND[511]) , .DATA_B (SUMMAND[512]) , .DATA_C (INT_CARRY[455]) , .SAVE (INT_SUM[586]) , .CARRY (INT_CARRY[465]) );
   HALF_ADDER HA_42 (.DATA_A (INT_CARRY[456]) , .DATA_B (INT_CARRY[457]) , .SAVE (INT_SUM[587]) , .CARRY (INT_CARRY[466]) );
   FULL_ADDER FA_404 (.DATA_A (INT_SUM[584]) , .DATA_B (INT_SUM[585]) , .DATA_C (INT_SUM[586]) , .SAVE (INT_SUM[588]) , .CARRY (INT_CARRY[467]) );
   FULL_ADDER FA_405 (.DATA_A (INT_SUM[587]) , .DATA_B (INT_CARRY[458]) , .DATA_C (INT_CARRY[459]) , .SAVE (INT_SUM[590]) , .CARRY (INT_CARRY[469]) );
   FLIPFLOP LA_148 (.DIN (INT_SUM[588]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[589]) );
   FLIPFLOP LA_149 (.DIN (INT_SUM[590]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[591]) );
   FLIPFLOP LA_150 (.DIN (INT_CARRY[460]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[461]) );
   FULL_ADDER FA_406 (.DATA_A (INT_SUM[589]) , .DATA_B (INT_SUM[591]) , .DATA_C (INT_CARRY[461]) , .SAVE (INT_SUM[592]) , .CARRY (INT_CARRY[471]) );
   HALF_ADDER HA_43 (.DATA_A (INT_SUM[592]) , .DATA_B (INT_CARRY[462]) , .SAVE (SUM[49]) , .CARRY (CARRY[49]) );
   FULL_ADDER FA_407 (.DATA_A (SUMMAND[513]) , .DATA_B (SUMMAND[514]) , .DATA_C (SUMMAND[515]) , .SAVE (INT_SUM[593]) , .CARRY (INT_CARRY[472]) );
   FULL_ADDER FA_408 (.DATA_A (SUMMAND[516]) , .DATA_B (SUMMAND[517]) , .DATA_C (SUMMAND[518]) , .SAVE (INT_SUM[594]) , .CARRY (INT_CARRY[473]) );
   assign INT_SUM[595] = SUMMAND[519];
   assign INT_SUM[596] = SUMMAND[520];
   FULL_ADDER FA_409 (.DATA_A (INT_SUM[593]) , .DATA_B (INT_SUM[594]) , .DATA_C (INT_SUM[595]) , .SAVE (INT_SUM[597]) , .CARRY (INT_CARRY[474]) );
   assign INT_SUM[598] = INT_SUM[596];
   FULL_ADDER FA_410 (.DATA_A (INT_SUM[597]) , .DATA_B (INT_SUM[598]) , .DATA_C (INT_CARRY[463]) , .SAVE (INT_SUM[599]) , .CARRY (INT_CARRY[475]) );
   FULL_ADDER FA_411 (.DATA_A (INT_CARRY[464]) , .DATA_B (INT_CARRY[465]) , .DATA_C (INT_CARRY[466]) , .SAVE (INT_SUM[601]) , .CARRY (INT_CARRY[477]) );
   FLIPFLOP LA_151 (.DIN (INT_SUM[599]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[600]) );
   FLIPFLOP LA_152 (.DIN (INT_SUM[601]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[602]) );
   FLIPFLOP LA_153 (.DIN (INT_CARRY[467]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[468]) );
   FULL_ADDER FA_412 (.DATA_A (INT_SUM[600]) , .DATA_B (INT_SUM[602]) , .DATA_C (INT_CARRY[468]) , .SAVE (INT_SUM[603]) , .CARRY (INT_CARRY[479]) );
   FLIPFLOP LA_154 (.DIN (INT_CARRY[469]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[470]) );
   assign INT_SUM[604] = INT_CARRY[470];
   FULL_ADDER FA_413 (.DATA_A (INT_SUM[603]) , .DATA_B (INT_SUM[604]) , .DATA_C (INT_CARRY[471]) , .SAVE (SUM[50]) , .CARRY (CARRY[50]) );
   FULL_ADDER FA_414 (.DATA_A (SUMMAND[521]) , .DATA_B (SUMMAND[522]) , .DATA_C (SUMMAND[523]) , .SAVE (INT_SUM[605]) , .CARRY (INT_CARRY[480]) );
   FULL_ADDER FA_415 (.DATA_A (SUMMAND[524]) , .DATA_B (SUMMAND[525]) , .DATA_C (SUMMAND[526]) , .SAVE (INT_SUM[606]) , .CARRY (INT_CARRY[481]) );
   FULL_ADDER FA_416 (.DATA_A (SUMMAND[527]) , .DATA_B (INT_CARRY[472]) , .DATA_C (INT_CARRY[473]) , .SAVE (INT_SUM[607]) , .CARRY (INT_CARRY[482]) );
   FULL_ADDER FA_417 (.DATA_A (INT_SUM[605]) , .DATA_B (INT_SUM[606]) , .DATA_C (INT_SUM[607]) , .SAVE (INT_SUM[608]) , .CARRY (INT_CARRY[483]) );
   assign INT_SUM[610] = INT_CARRY[474];
   FLIPFLOP LA_155 (.DIN (INT_SUM[608]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[609]) );
   FLIPFLOP LA_156 (.DIN (INT_SUM[610]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[611]) );
   FLIPFLOP LA_157 (.DIN (INT_CARRY[475]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[476]) );
   FULL_ADDER FA_418 (.DATA_A (INT_SUM[609]) , .DATA_B (INT_SUM[611]) , .DATA_C (INT_CARRY[476]) , .SAVE (INT_SUM[612]) , .CARRY (INT_CARRY[485]) );
   FLIPFLOP LA_158 (.DIN (INT_CARRY[477]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[478]) );
   assign INT_SUM[613] = INT_CARRY[478];
   FULL_ADDER FA_419 (.DATA_A (INT_SUM[612]) , .DATA_B (INT_SUM[613]) , .DATA_C (INT_CARRY[479]) , .SAVE (SUM[51]) , .CARRY (CARRY[51]) );
   FULL_ADDER FA_420 (.DATA_A (SUMMAND[528]) , .DATA_B (SUMMAND[529]) , .DATA_C (SUMMAND[530]) , .SAVE (INT_SUM[614]) , .CARRY (INT_CARRY[486]) );
   FULL_ADDER FA_421 (.DATA_A (SUMMAND[531]) , .DATA_B (SUMMAND[532]) , .DATA_C (SUMMAND[533]) , .SAVE (INT_SUM[615]) , .CARRY (INT_CARRY[487]) );
   assign INT_SUM[616] = SUMMAND[534];
   FULL_ADDER FA_422 (.DATA_A (INT_SUM[614]) , .DATA_B (INT_SUM[615]) , .DATA_C (INT_SUM[616]) , .SAVE (INT_SUM[617]) , .CARRY (INT_CARRY[488]) );
   FULL_ADDER FA_423 (.DATA_A (INT_CARRY[480]) , .DATA_B (INT_CARRY[481]) , .DATA_C (INT_CARRY[482]) , .SAVE (INT_SUM[619]) , .CARRY (INT_CARRY[490]) );
   FLIPFLOP LA_159 (.DIN (INT_SUM[617]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[618]) );
   FLIPFLOP LA_160 (.DIN (INT_SUM[619]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[620]) );
   FLIPFLOP LA_161 (.DIN (INT_CARRY[483]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[484]) );
   FULL_ADDER FA_424 (.DATA_A (INT_SUM[618]) , .DATA_B (INT_SUM[620]) , .DATA_C (INT_CARRY[484]) , .SAVE (INT_SUM[621]) , .CARRY (INT_CARRY[492]) );
   HALF_ADDER HA_44 (.DATA_A (INT_SUM[621]) , .DATA_B (INT_CARRY[485]) , .SAVE (SUM[52]) , .CARRY (CARRY[52]) );
   FULL_ADDER FA_425 (.DATA_A (SUMMAND[535]) , .DATA_B (SUMMAND[536]) , .DATA_C (SUMMAND[537]) , .SAVE (INT_SUM[622]) , .CARRY (INT_CARRY[493]) );
   FULL_ADDER FA_426 (.DATA_A (SUMMAND[538]) , .DATA_B (SUMMAND[539]) , .DATA_C (SUMMAND[540]) , .SAVE (INT_SUM[623]) , .CARRY (INT_CARRY[494]) );
   FULL_ADDER FA_427 (.DATA_A (INT_SUM[622]) , .DATA_B (INT_SUM[623]) , .DATA_C (INT_CARRY[486]) , .SAVE (INT_SUM[624]) , .CARRY (INT_CARRY[495]) );
   assign INT_SUM[626] = INT_CARRY[487];
   FLIPFLOP LA_162 (.DIN (INT_SUM[624]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[625]) );
   FLIPFLOP LA_163 (.DIN (INT_SUM[626]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[627]) );
   FLIPFLOP LA_164 (.DIN (INT_CARRY[488]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[489]) );
   FULL_ADDER FA_428 (.DATA_A (INT_SUM[625]) , .DATA_B (INT_SUM[627]) , .DATA_C (INT_CARRY[489]) , .SAVE (INT_SUM[628]) , .CARRY (INT_CARRY[497]) );
   FLIPFLOP LA_165 (.DIN (INT_CARRY[490]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[491]) );
   assign INT_SUM[629] = INT_CARRY[491];
   FULL_ADDER FA_429 (.DATA_A (INT_SUM[628]) , .DATA_B (INT_SUM[629]) , .DATA_C (INT_CARRY[492]) , .SAVE (SUM[53]) , .CARRY (CARRY[53]) );
   FULL_ADDER FA_430 (.DATA_A (SUMMAND[541]) , .DATA_B (SUMMAND[542]) , .DATA_C (SUMMAND[543]) , .SAVE (INT_SUM[630]) , .CARRY (INT_CARRY[498]) );
   FULL_ADDER FA_431 (.DATA_A (SUMMAND[544]) , .DATA_B (SUMMAND[545]) , .DATA_C (SUMMAND[546]) , .SAVE (INT_SUM[631]) , .CARRY (INT_CARRY[499]) );
   FULL_ADDER FA_432 (.DATA_A (INT_SUM[630]) , .DATA_B (INT_SUM[631]) , .DATA_C (INT_CARRY[493]) , .SAVE (INT_SUM[632]) , .CARRY (INT_CARRY[500]) );
   assign INT_SUM[634] = INT_CARRY[494];
   FLIPFLOP LA_166 (.DIN (INT_SUM[632]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[633]) );
   FLIPFLOP LA_167 (.DIN (INT_SUM[634]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[635]) );
   FLIPFLOP LA_168 (.DIN (INT_CARRY[495]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[496]) );
   FULL_ADDER FA_433 (.DATA_A (INT_SUM[633]) , .DATA_B (INT_SUM[635]) , .DATA_C (INT_CARRY[496]) , .SAVE (INT_SUM[636]) , .CARRY (INT_CARRY[502]) );
   HALF_ADDER HA_45 (.DATA_A (INT_SUM[636]) , .DATA_B (INT_CARRY[497]) , .SAVE (SUM[54]) , .CARRY (CARRY[54]) );
   FULL_ADDER FA_434 (.DATA_A (SUMMAND[547]) , .DATA_B (SUMMAND[548]) , .DATA_C (SUMMAND[549]) , .SAVE (INT_SUM[637]) , .CARRY (INT_CARRY[503]) );
   HALF_ADDER HA_46 (.DATA_A (SUMMAND[550]) , .DATA_B (SUMMAND[551]) , .SAVE (INT_SUM[638]) , .CARRY (INT_CARRY[504]) );
   FULL_ADDER FA_435 (.DATA_A (INT_SUM[637]) , .DATA_B (INT_SUM[638]) , .DATA_C (INT_CARRY[498]) , .SAVE (INT_SUM[639]) , .CARRY (INT_CARRY[505]) );
   assign INT_SUM[641] = INT_CARRY[499];
   FLIPFLOP LA_169 (.DIN (INT_SUM[639]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[640]) );
   FLIPFLOP LA_170 (.DIN (INT_SUM[641]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[642]) );
   FLIPFLOP LA_171 (.DIN (INT_CARRY[500]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[501]) );
   FULL_ADDER FA_436 (.DATA_A (INT_SUM[640]) , .DATA_B (INT_SUM[642]) , .DATA_C (INT_CARRY[501]) , .SAVE (INT_SUM[643]) , .CARRY (INT_CARRY[507]) );
   HALF_ADDER HA_47 (.DATA_A (INT_SUM[643]) , .DATA_B (INT_CARRY[502]) , .SAVE (SUM[55]) , .CARRY (CARRY[55]) );
   FULL_ADDER FA_437 (.DATA_A (SUMMAND[552]) , .DATA_B (SUMMAND[553]) , .DATA_C (SUMMAND[554]) , .SAVE (INT_SUM[644]) , .CARRY (INT_CARRY[508]) );
   HALF_ADDER HA_48 (.DATA_A (SUMMAND[555]) , .DATA_B (SUMMAND[556]) , .SAVE (INT_SUM[645]) , .CARRY (INT_CARRY[509]) );
   FULL_ADDER FA_438 (.DATA_A (INT_SUM[644]) , .DATA_B (INT_SUM[645]) , .DATA_C (INT_CARRY[503]) , .SAVE (INT_SUM[646]) , .CARRY (INT_CARRY[510]) );
   assign INT_SUM[648] = INT_CARRY[504];
   FLIPFLOP LA_172 (.DIN (INT_SUM[646]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[647]) );
   FLIPFLOP LA_173 (.DIN (INT_SUM[648]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[649]) );
   FLIPFLOP LA_174 (.DIN (INT_CARRY[505]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[506]) );
   FULL_ADDER FA_439 (.DATA_A (INT_SUM[647]) , .DATA_B (INT_SUM[649]) , .DATA_C (INT_CARRY[506]) , .SAVE (INT_SUM[650]) , .CARRY (INT_CARRY[512]) );
   HALF_ADDER HA_49 (.DATA_A (INT_SUM[650]) , .DATA_B (INT_CARRY[507]) , .SAVE (SUM[56]) , .CARRY (CARRY[56]) );
   FULL_ADDER FA_440 (.DATA_A (SUMMAND[557]) , .DATA_B (SUMMAND[558]) , .DATA_C (SUMMAND[559]) , .SAVE (INT_SUM[651]) , .CARRY (INT_CARRY[513]) );
   FULL_ADDER FA_441 (.DATA_A (SUMMAND[560]) , .DATA_B (INT_CARRY[508]) , .DATA_C (INT_CARRY[509]) , .SAVE (INT_SUM[653]) , .CARRY (INT_CARRY[515]) );
   FLIPFLOP LA_175 (.DIN (INT_SUM[651]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[652]) );
   FLIPFLOP LA_176 (.DIN (INT_SUM[653]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[654]) );
   FLIPFLOP LA_177 (.DIN (INT_CARRY[510]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[511]) );
   FULL_ADDER FA_442 (.DATA_A (INT_SUM[652]) , .DATA_B (INT_SUM[654]) , .DATA_C (INT_CARRY[511]) , .SAVE (INT_SUM[655]) , .CARRY (INT_CARRY[517]) );
   HALF_ADDER HA_50 (.DATA_A (INT_SUM[655]) , .DATA_B (INT_CARRY[512]) , .SAVE (SUM[57]) , .CARRY (CARRY[57]) );
   FULL_ADDER FA_443 (.DATA_A (SUMMAND[561]) , .DATA_B (SUMMAND[562]) , .DATA_C (SUMMAND[563]) , .SAVE (INT_SUM[656]) , .CARRY (INT_CARRY[518]) );
   assign INT_SUM[658] = SUMMAND[564];
   FLIPFLOP LA_178 (.DIN (INT_SUM[656]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[657]) );
   FLIPFLOP LA_179 (.DIN (INT_SUM[658]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[659]) );
   FLIPFLOP LA_180 (.DIN (INT_CARRY[513]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[514]) );
   FULL_ADDER FA_444 (.DATA_A (INT_SUM[657]) , .DATA_B (INT_SUM[659]) , .DATA_C (INT_CARRY[514]) , .SAVE (INT_SUM[660]) , .CARRY (INT_CARRY[520]) );
   FLIPFLOP LA_181 (.DIN (INT_CARRY[515]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[516]) );
   assign INT_SUM[661] = INT_CARRY[516];
   FULL_ADDER FA_445 (.DATA_A (INT_SUM[660]) , .DATA_B (INT_SUM[661]) , .DATA_C (INT_CARRY[517]) , .SAVE (SUM[58]) , .CARRY (CARRY[58]) );
   FULL_ADDER FA_446 (.DATA_A (SUMMAND[565]) , .DATA_B (SUMMAND[566]) , .DATA_C (SUMMAND[567]) , .SAVE (INT_SUM[662]) , .CARRY (INT_CARRY[521]) );
   FLIPFLOP LA_182 (.DIN (INT_SUM[662]) , .RST(RST), .CLK (CLK) , .DOUT (INT_SUM[663]) );
   assign INT_SUM[664] = INT_SUM[663];
   FLIPFLOP LA_183 (.DIN (INT_CARRY[518]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[519]) );
   assign INT_SUM[665] = INT_CARRY[519];
   FULL_ADDER FA_447 (.DATA_A (INT_SUM[664]) , .DATA_B (INT_SUM[665]) , .DATA_C (INT_CARRY[520]) , .SAVE (SUM[59]) , .CARRY (CARRY[59]) );
   FLIPFLOP LA_184 (.DIN (SUMMAND[568]) , .RST(RST), .CLK (CLK) , .DOUT (LATCHED_PP[0]) );
   FLIPFLOP LA_185 (.DIN (SUMMAND[569]) , .RST(RST), .CLK (CLK) , .DOUT (LATCHED_PP[1]) );
   FLIPFLOP LA_186 (.DIN (SUMMAND[570]) , .RST(RST), .CLK (CLK) , .DOUT (LATCHED_PP[2]) );
   FULL_ADDER FA_448 (.DATA_A (LATCHED_PP[0]) , .DATA_B (LATCHED_PP[1]) , .DATA_C (LATCHED_PP[2]) , .SAVE (INT_SUM[666]) , .CARRY (INT_CARRY[523]) );
   FLIPFLOP LA_187 (.DIN (INT_CARRY[521]) , .RST(RST), .CLK (CLK) , .DOUT (INT_CARRY[522]) );
   assign INT_SUM[667] = INT_CARRY[522];
   HALF_ADDER HA_51 (.DATA_A (INT_SUM[666]) , .DATA_B (INT_SUM[667]) , .SAVE (SUM[60]) , .CARRY (CARRY[60]) );
   FLIPFLOP LA_188 (.DIN (SUMMAND[571]) , .RST(RST), .CLK (CLK) , .DOUT (LATCHED_PP[3]) );
   assign INT_SUM[668] = LATCHED_PP[3];
   FLIPFLOP LA_189 (.DIN (SUMMAND[572]) , .RST(RST), .CLK (CLK) , .DOUT (LATCHED_PP[4]) );
   assign INT_SUM[669] = LATCHED_PP[4];
   FULL_ADDER FA_449 (.DATA_A (INT_SUM[668]) , .DATA_B (INT_SUM[669]) , .DATA_C (INT_CARRY[523]) , .SAVE (SUM[61]) , .CARRY (CARRY[61]) );
   FLIPFLOP LA_190 (.DIN (SUMMAND[573]) , .RST(RST), .CLK (CLK) , .DOUT (LATCHED_PP[5]) );
   FLIPFLOP LA_191 (.DIN (SUMMAND[574]) , .RST(RST), .CLK (CLK) , .DOUT (LATCHED_PP[6]) );
   HALF_ADDER HA_52 (.DATA_A (LATCHED_PP[5]) , .DATA_B (LATCHED_PP[6]) , .SAVE (SUM[62]) , .CARRY (CARRY[62]) );
   FLIPFLOP LA_192 (.DIN (SUMMAND[575]) , .RST(RST), .CLK (CLK) , .DOUT (LATCHED_PP[7]) );
   assign SUM[63] = LATCHED_PP[7];
endmodule


module INVBLOCK ( GIN, PHI, GOUT );
input  GIN;
input  PHI;
output GOUT;
   assign GOUT =  ~ GIN;
endmodule


module XXOR1 ( A, B, GIN, PHI, SUM );
input  A;
input  B;
input  GIN;
input  PHI;
output SUM;
   assign SUM = ( ~ (A ^ B)) ^ GIN;
endmodule


module BLOCK0 ( A, B, PHI, POUT, GOUT );
input  A;
input  B;
input  PHI;
output POUT;
output GOUT;
   assign POUT =  ~ (A | B);
   assign GOUT =  ~ (A & B);
endmodule


module BLOCK1 ( PIN1, PIN2, GIN1, GIN2, PHI, POUT, GOUT );
input  PIN1;
input  PIN2;
input  GIN1;
input  GIN2;
input  PHI;
output POUT;
output GOUT;
   assign POUT =  ~ (PIN1 | PIN2);
   assign GOUT =  ~ (GIN2 & (PIN2 | GIN1));
endmodule


module BLOCK2 ( PIN1, PIN2, GIN1, GIN2, PHI, POUT, GOUT );
input  PIN1;
input  PIN2;
input  GIN1;
input  GIN2;
input  PHI;
output POUT;
output GOUT;
   assign POUT =  ~ (PIN1 & PIN2);
   assign GOUT =  ~ (GIN2 | (PIN2 & GIN1));
endmodule


module BLOCK1A ( PIN2, GIN1, GIN2, PHI, GOUT );
input  PIN2;
input  GIN1;
input  GIN2;
input  PHI;
output GOUT;
   assign GOUT =  ~ (GIN2 & (PIN2 | GIN1));
endmodule


module BLOCK2A ( PIN2, GIN1, GIN2, PHI, GOUT );
input  PIN2;
input  GIN1;
input  GIN2;
input  PHI;
output GOUT;
   assign GOUT =  ~ (GIN2 | (PIN2 & GIN1));
endmodule


module PRESTAGE_64 ( A, B, CIN, PHI, POUT, GOUT );
input  [0:63] A;
input  [0:63] B;
input  CIN;
input  PHI;
output [0:63] POUT;
output [0:64] GOUT;
   BLOCK0 U10 (A[0] , B[0] , PHI , POUT[0] , GOUT[1] );
   BLOCK0 U11 (A[1] , B[1] , PHI , POUT[1] , GOUT[2] );
   BLOCK0 U12 (A[2] , B[2] , PHI , POUT[2] , GOUT[3] );
   BLOCK0 U13 (A[3] , B[3] , PHI , POUT[3] , GOUT[4] );
   BLOCK0 U14 (A[4] , B[4] , PHI , POUT[4] , GOUT[5] );
   BLOCK0 U15 (A[5] , B[5] , PHI , POUT[5] , GOUT[6] );
   BLOCK0 U16 (A[6] , B[6] , PHI , POUT[6] , GOUT[7] );
   BLOCK0 U17 (A[7] , B[7] , PHI , POUT[7] , GOUT[8] );
   BLOCK0 U18 (A[8] , B[8] , PHI , POUT[8] , GOUT[9] );
   BLOCK0 U19 (A[9] , B[9] , PHI , POUT[9] , GOUT[10] );
   BLOCK0 U110 (A[10] , B[10] , PHI , POUT[10] , GOUT[11] );
   BLOCK0 U111 (A[11] , B[11] , PHI , POUT[11] , GOUT[12] );
   BLOCK0 U112 (A[12] , B[12] , PHI , POUT[12] , GOUT[13] );
   BLOCK0 U113 (A[13] , B[13] , PHI , POUT[13] , GOUT[14] );
   BLOCK0 U114 (A[14] , B[14] , PHI , POUT[14] , GOUT[15] );
   BLOCK0 U115 (A[15] , B[15] , PHI , POUT[15] , GOUT[16] );
   BLOCK0 U116 (A[16] , B[16] , PHI , POUT[16] , GOUT[17] );
   BLOCK0 U117 (A[17] , B[17] , PHI , POUT[17] , GOUT[18] );
   BLOCK0 U118 (A[18] , B[18] , PHI , POUT[18] , GOUT[19] );
   BLOCK0 U119 (A[19] , B[19] , PHI , POUT[19] , GOUT[20] );
   BLOCK0 U120 (A[20] , B[20] , PHI , POUT[20] , GOUT[21] );
   BLOCK0 U121 (A[21] , B[21] , PHI , POUT[21] , GOUT[22] );
   BLOCK0 U122 (A[22] , B[22] , PHI , POUT[22] , GOUT[23] );
   BLOCK0 U123 (A[23] , B[23] , PHI , POUT[23] , GOUT[24] );
   BLOCK0 U124 (A[24] , B[24] , PHI , POUT[24] , GOUT[25] );
   BLOCK0 U125 (A[25] , B[25] , PHI , POUT[25] , GOUT[26] );
   BLOCK0 U126 (A[26] , B[26] , PHI , POUT[26] , GOUT[27] );
   BLOCK0 U127 (A[27] , B[27] , PHI , POUT[27] , GOUT[28] );
   BLOCK0 U128 (A[28] , B[28] , PHI , POUT[28] , GOUT[29] );
   BLOCK0 U129 (A[29] , B[29] , PHI , POUT[29] , GOUT[30] );
   BLOCK0 U130 (A[30] , B[30] , PHI , POUT[30] , GOUT[31] );
   BLOCK0 U131 (A[31] , B[31] , PHI , POUT[31] , GOUT[32] );
   BLOCK0 U132 (A[32] , B[32] , PHI , POUT[32] , GOUT[33] );
   BLOCK0 U133 (A[33] , B[33] , PHI , POUT[33] , GOUT[34] );
   BLOCK0 U134 (A[34] , B[34] , PHI , POUT[34] , GOUT[35] );
   BLOCK0 U135 (A[35] , B[35] , PHI , POUT[35] , GOUT[36] );
   BLOCK0 U136 (A[36] , B[36] , PHI , POUT[36] , GOUT[37] );
   BLOCK0 U137 (A[37] , B[37] , PHI , POUT[37] , GOUT[38] );
   BLOCK0 U138 (A[38] , B[38] , PHI , POUT[38] , GOUT[39] );
   BLOCK0 U139 (A[39] , B[39] , PHI , POUT[39] , GOUT[40] );
   BLOCK0 U140 (A[40] , B[40] , PHI , POUT[40] , GOUT[41] );
   BLOCK0 U141 (A[41] , B[41] , PHI , POUT[41] , GOUT[42] );
   BLOCK0 U142 (A[42] , B[42] , PHI , POUT[42] , GOUT[43] );
   BLOCK0 U143 (A[43] , B[43] , PHI , POUT[43] , GOUT[44] );
   BLOCK0 U144 (A[44] , B[44] , PHI , POUT[44] , GOUT[45] );
   BLOCK0 U145 (A[45] , B[45] , PHI , POUT[45] , GOUT[46] );
   BLOCK0 U146 (A[46] , B[46] , PHI , POUT[46] , GOUT[47] );
   BLOCK0 U147 (A[47] , B[47] , PHI , POUT[47] , GOUT[48] );
   BLOCK0 U148 (A[48] , B[48] , PHI , POUT[48] , GOUT[49] );
   BLOCK0 U149 (A[49] , B[49] , PHI , POUT[49] , GOUT[50] );
   BLOCK0 U150 (A[50] , B[50] , PHI , POUT[50] , GOUT[51] );
   BLOCK0 U151 (A[51] , B[51] , PHI , POUT[51] , GOUT[52] );
   BLOCK0 U152 (A[52] , B[52] , PHI , POUT[52] , GOUT[53] );
   BLOCK0 U153 (A[53] , B[53] , PHI , POUT[53] , GOUT[54] );
   BLOCK0 U154 (A[54] , B[54] , PHI , POUT[54] , GOUT[55] );
   BLOCK0 U155 (A[55] , B[55] , PHI , POUT[55] , GOUT[56] );
   BLOCK0 U156 (A[56] , B[56] , PHI , POUT[56] , GOUT[57] );
   BLOCK0 U157 (A[57] , B[57] , PHI , POUT[57] , GOUT[58] );
   BLOCK0 U158 (A[58] , B[58] , PHI , POUT[58] , GOUT[59] );
   BLOCK0 U159 (A[59] , B[59] , PHI , POUT[59] , GOUT[60] );
   BLOCK0 U160 (A[60] , B[60] , PHI , POUT[60] , GOUT[61] );
   BLOCK0 U161 (A[61] , B[61] , PHI , POUT[61] , GOUT[62] );
   BLOCK0 U162 (A[62] , B[62] , PHI , POUT[62] , GOUT[63] );
   BLOCK0 U163 (A[63] , B[63] , PHI , POUT[63] , GOUT[64] );
   INVBLOCK U2 (CIN , PHI , GOUT[0] );
endmodule


module DBLC_0_64 ( PIN, GIN, PHI, POUT, GOUT );
input  [0:63] PIN;
input  [0:64] GIN;
input  PHI;
output [0:62] POUT;
output [0:64] GOUT;
   INVBLOCK U10 (GIN[0] , PHI , GOUT[0] );
   BLOCK1A U21 (PIN[0] , GIN[0] , GIN[1] , PHI , GOUT[1] );
   BLOCK1 U32 (PIN[0] , PIN[1] , GIN[1] , GIN[2] , PHI , POUT[0] , GOUT[2] );
   BLOCK1 U33 (PIN[1] , PIN[2] , GIN[2] , GIN[3] , PHI , POUT[1] , GOUT[3] );
   BLOCK1 U34 (PIN[2] , PIN[3] , GIN[3] , GIN[4] , PHI , POUT[2] , GOUT[4] );
   BLOCK1 U35 (PIN[3] , PIN[4] , GIN[4] , GIN[5] , PHI , POUT[3] , GOUT[5] );
   BLOCK1 U36 (PIN[4] , PIN[5] , GIN[5] , GIN[6] , PHI , POUT[4] , GOUT[6] );
   BLOCK1 U37 (PIN[5] , PIN[6] , GIN[6] , GIN[7] , PHI , POUT[5] , GOUT[7] );
   BLOCK1 U38 (PIN[6] , PIN[7] , GIN[7] , GIN[8] , PHI , POUT[6] , GOUT[8] );
   BLOCK1 U39 (PIN[7] , PIN[8] , GIN[8] , GIN[9] , PHI , POUT[7] , GOUT[9] );
   BLOCK1 U310 (PIN[8] , PIN[9] , GIN[9] , GIN[10] , PHI , POUT[8] , GOUT[10] );
   BLOCK1 U311 (PIN[9] , PIN[10] , GIN[10] , GIN[11] , PHI , POUT[9] , GOUT[11] );
   BLOCK1 U312 (PIN[10] , PIN[11] , GIN[11] , GIN[12] , PHI , POUT[10] , GOUT[12] );
   BLOCK1 U313 (PIN[11] , PIN[12] , GIN[12] , GIN[13] , PHI , POUT[11] , GOUT[13] );
   BLOCK1 U314 (PIN[12] , PIN[13] , GIN[13] , GIN[14] , PHI , POUT[12] , GOUT[14] );
   BLOCK1 U315 (PIN[13] , PIN[14] , GIN[14] , GIN[15] , PHI , POUT[13] , GOUT[15] );
   BLOCK1 U316 (PIN[14] , PIN[15] , GIN[15] , GIN[16] , PHI , POUT[14] , GOUT[16] );
   BLOCK1 U317 (PIN[15] , PIN[16] , GIN[16] , GIN[17] , PHI , POUT[15] , GOUT[17] );
   BLOCK1 U318 (PIN[16] , PIN[17] , GIN[17] , GIN[18] , PHI , POUT[16] , GOUT[18] );
   BLOCK1 U319 (PIN[17] , PIN[18] , GIN[18] , GIN[19] , PHI , POUT[17] , GOUT[19] );
   BLOCK1 U320 (PIN[18] , PIN[19] , GIN[19] , GIN[20] , PHI , POUT[18] , GOUT[20] );
   BLOCK1 U321 (PIN[19] , PIN[20] , GIN[20] , GIN[21] , PHI , POUT[19] , GOUT[21] );
   BLOCK1 U322 (PIN[20] , PIN[21] , GIN[21] , GIN[22] , PHI , POUT[20] , GOUT[22] );
   BLOCK1 U323 (PIN[21] , PIN[22] , GIN[22] , GIN[23] , PHI , POUT[21] , GOUT[23] );
   BLOCK1 U324 (PIN[22] , PIN[23] , GIN[23] , GIN[24] , PHI , POUT[22] , GOUT[24] );
   BLOCK1 U325 (PIN[23] , PIN[24] , GIN[24] , GIN[25] , PHI , POUT[23] , GOUT[25] );
   BLOCK1 U326 (PIN[24] , PIN[25] , GIN[25] , GIN[26] , PHI , POUT[24] , GOUT[26] );
   BLOCK1 U327 (PIN[25] , PIN[26] , GIN[26] , GIN[27] , PHI , POUT[25] , GOUT[27] );
   BLOCK1 U328 (PIN[26] , PIN[27] , GIN[27] , GIN[28] , PHI , POUT[26] , GOUT[28] );
   BLOCK1 U329 (PIN[27] , PIN[28] , GIN[28] , GIN[29] , PHI , POUT[27] , GOUT[29] );
   BLOCK1 U330 (PIN[28] , PIN[29] , GIN[29] , GIN[30] , PHI , POUT[28] , GOUT[30] );
   BLOCK1 U331 (PIN[29] , PIN[30] , GIN[30] , GIN[31] , PHI , POUT[29] , GOUT[31] );
   BLOCK1 U332 (PIN[30] , PIN[31] , GIN[31] , GIN[32] , PHI , POUT[30] , GOUT[32] );
   BLOCK1 U333 (PIN[31] , PIN[32] , GIN[32] , GIN[33] , PHI , POUT[31] , GOUT[33] );
   BLOCK1 U334 (PIN[32] , PIN[33] , GIN[33] , GIN[34] , PHI , POUT[32] , GOUT[34] );
   BLOCK1 U335 (PIN[33] , PIN[34] , GIN[34] , GIN[35] , PHI , POUT[33] , GOUT[35] );
   BLOCK1 U336 (PIN[34] , PIN[35] , GIN[35] , GIN[36] , PHI , POUT[34] , GOUT[36] );
   BLOCK1 U337 (PIN[35] , PIN[36] , GIN[36] , GIN[37] , PHI , POUT[35] , GOUT[37] );
   BLOCK1 U338 (PIN[36] , PIN[37] , GIN[37] , GIN[38] , PHI , POUT[36] , GOUT[38] );
   BLOCK1 U339 (PIN[37] , PIN[38] , GIN[38] , GIN[39] , PHI , POUT[37] , GOUT[39] );
   BLOCK1 U340 (PIN[38] , PIN[39] , GIN[39] , GIN[40] , PHI , POUT[38] , GOUT[40] );
   BLOCK1 U341 (PIN[39] , PIN[40] , GIN[40] , GIN[41] , PHI , POUT[39] , GOUT[41] );
   BLOCK1 U342 (PIN[40] , PIN[41] , GIN[41] , GIN[42] , PHI , POUT[40] , GOUT[42] );
   BLOCK1 U343 (PIN[41] , PIN[42] , GIN[42] , GIN[43] , PHI , POUT[41] , GOUT[43] );
   BLOCK1 U344 (PIN[42] , PIN[43] , GIN[43] , GIN[44] , PHI , POUT[42] , GOUT[44] );
   BLOCK1 U345 (PIN[43] , PIN[44] , GIN[44] , GIN[45] , PHI , POUT[43] , GOUT[45] );
   BLOCK1 U346 (PIN[44] , PIN[45] , GIN[45] , GIN[46] , PHI , POUT[44] , GOUT[46] );
   BLOCK1 U347 (PIN[45] , PIN[46] , GIN[46] , GIN[47] , PHI , POUT[45] , GOUT[47] );
   BLOCK1 U348 (PIN[46] , PIN[47] , GIN[47] , GIN[48] , PHI , POUT[46] , GOUT[48] );
   BLOCK1 U349 (PIN[47] , PIN[48] , GIN[48] , GIN[49] , PHI , POUT[47] , GOUT[49] );
   BLOCK1 U350 (PIN[48] , PIN[49] , GIN[49] , GIN[50] , PHI , POUT[48] , GOUT[50] );
   BLOCK1 U351 (PIN[49] , PIN[50] , GIN[50] , GIN[51] , PHI , POUT[49] , GOUT[51] );
   BLOCK1 U352 (PIN[50] , PIN[51] , GIN[51] , GIN[52] , PHI , POUT[50] , GOUT[52] );
   BLOCK1 U353 (PIN[51] , PIN[52] , GIN[52] , GIN[53] , PHI , POUT[51] , GOUT[53] );
   BLOCK1 U354 (PIN[52] , PIN[53] , GIN[53] , GIN[54] , PHI , POUT[52] , GOUT[54] );
   BLOCK1 U355 (PIN[53] , PIN[54] , GIN[54] , GIN[55] , PHI , POUT[53] , GOUT[55] );
   BLOCK1 U356 (PIN[54] , PIN[55] , GIN[55] , GIN[56] , PHI , POUT[54] , GOUT[56] );
   BLOCK1 U357 (PIN[55] , PIN[56] , GIN[56] , GIN[57] , PHI , POUT[55] , GOUT[57] );
   BLOCK1 U358 (PIN[56] , PIN[57] , GIN[57] , GIN[58] , PHI , POUT[56] , GOUT[58] );
   BLOCK1 U359 (PIN[57] , PIN[58] , GIN[58] , GIN[59] , PHI , POUT[57] , GOUT[59] );
   BLOCK1 U360 (PIN[58] , PIN[59] , GIN[59] , GIN[60] , PHI , POUT[58] , GOUT[60] );
   BLOCK1 U361 (PIN[59] , PIN[60] , GIN[60] , GIN[61] , PHI , POUT[59] , GOUT[61] );
   BLOCK1 U362 (PIN[60] , PIN[61] , GIN[61] , GIN[62] , PHI , POUT[60] , GOUT[62] );
   BLOCK1 U363 (PIN[61] , PIN[62] , GIN[62] , GIN[63] , PHI , POUT[61] , GOUT[63] );
   BLOCK1 U364 (PIN[62] , PIN[63] , GIN[63] , GIN[64] , PHI , POUT[62] , GOUT[64] );
endmodule


module DBLC_1_64 ( PIN, GIN, PHI, POUT, GOUT );
input  [0:62] PIN;
input  [0:64] GIN;
input  PHI;
output [0:60] POUT;
output [0:64] GOUT;
   INVBLOCK U10 (GIN[0] , PHI , GOUT[0] );
   INVBLOCK U11 (GIN[1] , PHI , GOUT[1] );
   BLOCK2A U22 (PIN[0] , GIN[0] , GIN[2] , PHI , GOUT[2] );
   BLOCK2A U23 (PIN[1] , GIN[1] , GIN[3] , PHI , GOUT[3] );
   BLOCK2 U34 (PIN[0] , PIN[2] , GIN[2] , GIN[4] , PHI , POUT[0] , GOUT[4] );
   BLOCK2 U35 (PIN[1] , PIN[3] , GIN[3] , GIN[5] , PHI , POUT[1] , GOUT[5] );
   BLOCK2 U36 (PIN[2] , PIN[4] , GIN[4] , GIN[6] , PHI , POUT[2] , GOUT[6] );
   BLOCK2 U37 (PIN[3] , PIN[5] , GIN[5] , GIN[7] , PHI , POUT[3] , GOUT[7] );
   BLOCK2 U38 (PIN[4] , PIN[6] , GIN[6] , GIN[8] , PHI , POUT[4] , GOUT[8] );
   BLOCK2 U39 (PIN[5] , PIN[7] , GIN[7] , GIN[9] , PHI , POUT[5] , GOUT[9] );
   BLOCK2 U310 (PIN[6] , PIN[8] , GIN[8] , GIN[10] , PHI , POUT[6] , GOUT[10] );
   BLOCK2 U311 (PIN[7] , PIN[9] , GIN[9] , GIN[11] , PHI , POUT[7] , GOUT[11] );
   BLOCK2 U312 (PIN[8] , PIN[10] , GIN[10] , GIN[12] , PHI , POUT[8] , GOUT[12] );
   BLOCK2 U313 (PIN[9] , PIN[11] , GIN[11] , GIN[13] , PHI , POUT[9] , GOUT[13] );
   BLOCK2 U314 (PIN[10] , PIN[12] , GIN[12] , GIN[14] , PHI , POUT[10] , GOUT[14] );
   BLOCK2 U315 (PIN[11] , PIN[13] , GIN[13] , GIN[15] , PHI , POUT[11] , GOUT[15] );
   BLOCK2 U316 (PIN[12] , PIN[14] , GIN[14] , GIN[16] , PHI , POUT[12] , GOUT[16] );
   BLOCK2 U317 (PIN[13] , PIN[15] , GIN[15] , GIN[17] , PHI , POUT[13] , GOUT[17] );
   BLOCK2 U318 (PIN[14] , PIN[16] , GIN[16] , GIN[18] , PHI , POUT[14] , GOUT[18] );
   BLOCK2 U319 (PIN[15] , PIN[17] , GIN[17] , GIN[19] , PHI , POUT[15] , GOUT[19] );
   BLOCK2 U320 (PIN[16] , PIN[18] , GIN[18] , GIN[20] , PHI , POUT[16] , GOUT[20] );
   BLOCK2 U321 (PIN[17] , PIN[19] , GIN[19] , GIN[21] , PHI , POUT[17] , GOUT[21] );
   BLOCK2 U322 (PIN[18] , PIN[20] , GIN[20] , GIN[22] , PHI , POUT[18] , GOUT[22] );
   BLOCK2 U323 (PIN[19] , PIN[21] , GIN[21] , GIN[23] , PHI , POUT[19] , GOUT[23] );
   BLOCK2 U324 (PIN[20] , PIN[22] , GIN[22] , GIN[24] , PHI , POUT[20] , GOUT[24] );
   BLOCK2 U325 (PIN[21] , PIN[23] , GIN[23] , GIN[25] , PHI , POUT[21] , GOUT[25] );
   BLOCK2 U326 (PIN[22] , PIN[24] , GIN[24] , GIN[26] , PHI , POUT[22] , GOUT[26] );
   BLOCK2 U327 (PIN[23] , PIN[25] , GIN[25] , GIN[27] , PHI , POUT[23] , GOUT[27] );
   BLOCK2 U328 (PIN[24] , PIN[26] , GIN[26] , GIN[28] , PHI , POUT[24] , GOUT[28] );
   BLOCK2 U329 (PIN[25] , PIN[27] , GIN[27] , GIN[29] , PHI , POUT[25] , GOUT[29] );
   BLOCK2 U330 (PIN[26] , PIN[28] , GIN[28] , GIN[30] , PHI , POUT[26] , GOUT[30] );
   BLOCK2 U331 (PIN[27] , PIN[29] , GIN[29] , GIN[31] , PHI , POUT[27] , GOUT[31] );
   BLOCK2 U332 (PIN[28] , PIN[30] , GIN[30] , GIN[32] , PHI , POUT[28] , GOUT[32] );
   BLOCK2 U333 (PIN[29] , PIN[31] , GIN[31] , GIN[33] , PHI , POUT[29] , GOUT[33] );
   BLOCK2 U334 (PIN[30] , PIN[32] , GIN[32] , GIN[34] , PHI , POUT[30] , GOUT[34] );
   BLOCK2 U335 (PIN[31] , PIN[33] , GIN[33] , GIN[35] , PHI , POUT[31] , GOUT[35] );
   BLOCK2 U336 (PIN[32] , PIN[34] , GIN[34] , GIN[36] , PHI , POUT[32] , GOUT[36] );
   BLOCK2 U337 (PIN[33] , PIN[35] , GIN[35] , GIN[37] , PHI , POUT[33] , GOUT[37] );
   BLOCK2 U338 (PIN[34] , PIN[36] , GIN[36] , GIN[38] , PHI , POUT[34] , GOUT[38] );
   BLOCK2 U339 (PIN[35] , PIN[37] , GIN[37] , GIN[39] , PHI , POUT[35] , GOUT[39] );
   BLOCK2 U340 (PIN[36] , PIN[38] , GIN[38] , GIN[40] , PHI , POUT[36] , GOUT[40] );
   BLOCK2 U341 (PIN[37] , PIN[39] , GIN[39] , GIN[41] , PHI , POUT[37] , GOUT[41] );
   BLOCK2 U342 (PIN[38] , PIN[40] , GIN[40] , GIN[42] , PHI , POUT[38] , GOUT[42] );
   BLOCK2 U343 (PIN[39] , PIN[41] , GIN[41] , GIN[43] , PHI , POUT[39] , GOUT[43] );
   BLOCK2 U344 (PIN[40] , PIN[42] , GIN[42] , GIN[44] , PHI , POUT[40] , GOUT[44] );
   BLOCK2 U345 (PIN[41] , PIN[43] , GIN[43] , GIN[45] , PHI , POUT[41] , GOUT[45] );
   BLOCK2 U346 (PIN[42] , PIN[44] , GIN[44] , GIN[46] , PHI , POUT[42] , GOUT[46] );
   BLOCK2 U347 (PIN[43] , PIN[45] , GIN[45] , GIN[47] , PHI , POUT[43] , GOUT[47] );
   BLOCK2 U348 (PIN[44] , PIN[46] , GIN[46] , GIN[48] , PHI , POUT[44] , GOUT[48] );
   BLOCK2 U349 (PIN[45] , PIN[47] , GIN[47] , GIN[49] , PHI , POUT[45] , GOUT[49] );
   BLOCK2 U350 (PIN[46] , PIN[48] , GIN[48] , GIN[50] , PHI , POUT[46] , GOUT[50] );
   BLOCK2 U351 (PIN[47] , PIN[49] , GIN[49] , GIN[51] , PHI , POUT[47] , GOUT[51] );
   BLOCK2 U352 (PIN[48] , PIN[50] , GIN[50] , GIN[52] , PHI , POUT[48] , GOUT[52] );
   BLOCK2 U353 (PIN[49] , PIN[51] , GIN[51] , GIN[53] , PHI , POUT[49] , GOUT[53] );
   BLOCK2 U354 (PIN[50] , PIN[52] , GIN[52] , GIN[54] , PHI , POUT[50] , GOUT[54] );
   BLOCK2 U355 (PIN[51] , PIN[53] , GIN[53] , GIN[55] , PHI , POUT[51] , GOUT[55] );
   BLOCK2 U356 (PIN[52] , PIN[54] , GIN[54] , GIN[56] , PHI , POUT[52] , GOUT[56] );
   BLOCK2 U357 (PIN[53] , PIN[55] , GIN[55] , GIN[57] , PHI , POUT[53] , GOUT[57] );
   BLOCK2 U358 (PIN[54] , PIN[56] , GIN[56] , GIN[58] , PHI , POUT[54] , GOUT[58] );
   BLOCK2 U359 (PIN[55] , PIN[57] , GIN[57] , GIN[59] , PHI , POUT[55] , GOUT[59] );
   BLOCK2 U360 (PIN[56] , PIN[58] , GIN[58] , GIN[60] , PHI , POUT[56] , GOUT[60] );
   BLOCK2 U361 (PIN[57] , PIN[59] , GIN[59] , GIN[61] , PHI , POUT[57] , GOUT[61] );
   BLOCK2 U362 (PIN[58] , PIN[60] , GIN[60] , GIN[62] , PHI , POUT[58] , GOUT[62] );
   BLOCK2 U363 (PIN[59] , PIN[61] , GIN[61] , GIN[63] , PHI , POUT[59] , GOUT[63] );
   BLOCK2 U364 (PIN[60] , PIN[62] , GIN[62] , GIN[64] , PHI , POUT[60] , GOUT[64] );
endmodule


module DBLC_2_64 ( PIN, GIN, PHI, POUT, GOUT );
input  [0:60] PIN;
input  [0:64] GIN;
input  PHI;
output [0:56] POUT;
output [0:64] GOUT;
   INVBLOCK U10 (GIN[0] , PHI , GOUT[0] );
   INVBLOCK U11 (GIN[1] , PHI , GOUT[1] );
   INVBLOCK U12 (GIN[2] , PHI , GOUT[2] );
   INVBLOCK U13 (GIN[3] , PHI , GOUT[3] );
   BLOCK1A U24 (PIN[0] , GIN[0] , GIN[4] , PHI , GOUT[4] );
   BLOCK1A U25 (PIN[1] , GIN[1] , GIN[5] , PHI , GOUT[5] );
   BLOCK1A U26 (PIN[2] , GIN[2] , GIN[6] , PHI , GOUT[6] );
   BLOCK1A U27 (PIN[3] , GIN[3] , GIN[7] , PHI , GOUT[7] );
   BLOCK1 U38 (PIN[0] , PIN[4] , GIN[4] , GIN[8] , PHI , POUT[0] , GOUT[8] );
   BLOCK1 U39 (PIN[1] , PIN[5] , GIN[5] , GIN[9] , PHI , POUT[1] , GOUT[9] );
   BLOCK1 U310 (PIN[2] , PIN[6] , GIN[6] , GIN[10] , PHI , POUT[2] , GOUT[10] );
   BLOCK1 U311 (PIN[3] , PIN[7] , GIN[7] , GIN[11] , PHI , POUT[3] , GOUT[11] );
   BLOCK1 U312 (PIN[4] , PIN[8] , GIN[8] , GIN[12] , PHI , POUT[4] , GOUT[12] );
   BLOCK1 U313 (PIN[5] , PIN[9] , GIN[9] , GIN[13] , PHI , POUT[5] , GOUT[13] );
   BLOCK1 U314 (PIN[6] , PIN[10] , GIN[10] , GIN[14] , PHI , POUT[6] , GOUT[14] );
   BLOCK1 U315 (PIN[7] , PIN[11] , GIN[11] , GIN[15] , PHI , POUT[7] , GOUT[15] );
   BLOCK1 U316 (PIN[8] , PIN[12] , GIN[12] , GIN[16] , PHI , POUT[8] , GOUT[16] );
   BLOCK1 U317 (PIN[9] , PIN[13] , GIN[13] , GIN[17] , PHI , POUT[9] , GOUT[17] );
   BLOCK1 U318 (PIN[10] , PIN[14] , GIN[14] , GIN[18] , PHI , POUT[10] , GOUT[18] );
   BLOCK1 U319 (PIN[11] , PIN[15] , GIN[15] , GIN[19] , PHI , POUT[11] , GOUT[19] );
   BLOCK1 U320 (PIN[12] , PIN[16] , GIN[16] , GIN[20] , PHI , POUT[12] , GOUT[20] );
   BLOCK1 U321 (PIN[13] , PIN[17] , GIN[17] , GIN[21] , PHI , POUT[13] , GOUT[21] );
   BLOCK1 U322 (PIN[14] , PIN[18] , GIN[18] , GIN[22] , PHI , POUT[14] , GOUT[22] );
   BLOCK1 U323 (PIN[15] , PIN[19] , GIN[19] , GIN[23] , PHI , POUT[15] , GOUT[23] );
   BLOCK1 U324 (PIN[16] , PIN[20] , GIN[20] , GIN[24] , PHI , POUT[16] , GOUT[24] );
   BLOCK1 U325 (PIN[17] , PIN[21] , GIN[21] , GIN[25] , PHI , POUT[17] , GOUT[25] );
   BLOCK1 U326 (PIN[18] , PIN[22] , GIN[22] , GIN[26] , PHI , POUT[18] , GOUT[26] );
   BLOCK1 U327 (PIN[19] , PIN[23] , GIN[23] , GIN[27] , PHI , POUT[19] , GOUT[27] );
   BLOCK1 U328 (PIN[20] , PIN[24] , GIN[24] , GIN[28] , PHI , POUT[20] , GOUT[28] );
   BLOCK1 U329 (PIN[21] , PIN[25] , GIN[25] , GIN[29] , PHI , POUT[21] , GOUT[29] );
   BLOCK1 U330 (PIN[22] , PIN[26] , GIN[26] , GIN[30] , PHI , POUT[22] , GOUT[30] );
   BLOCK1 U331 (PIN[23] , PIN[27] , GIN[27] , GIN[31] , PHI , POUT[23] , GOUT[31] );
   BLOCK1 U332 (PIN[24] , PIN[28] , GIN[28] , GIN[32] , PHI , POUT[24] , GOUT[32] );
   BLOCK1 U333 (PIN[25] , PIN[29] , GIN[29] , GIN[33] , PHI , POUT[25] , GOUT[33] );
   BLOCK1 U334 (PIN[26] , PIN[30] , GIN[30] , GIN[34] , PHI , POUT[26] , GOUT[34] );
   BLOCK1 U335 (PIN[27] , PIN[31] , GIN[31] , GIN[35] , PHI , POUT[27] , GOUT[35] );
   BLOCK1 U336 (PIN[28] , PIN[32] , GIN[32] , GIN[36] , PHI , POUT[28] , GOUT[36] );
   BLOCK1 U337 (PIN[29] , PIN[33] , GIN[33] , GIN[37] , PHI , POUT[29] , GOUT[37] );
   BLOCK1 U338 (PIN[30] , PIN[34] , GIN[34] , GIN[38] , PHI , POUT[30] , GOUT[38] );
   BLOCK1 U339 (PIN[31] , PIN[35] , GIN[35] , GIN[39] , PHI , POUT[31] , GOUT[39] );
   BLOCK1 U340 (PIN[32] , PIN[36] , GIN[36] , GIN[40] , PHI , POUT[32] , GOUT[40] );
   BLOCK1 U341 (PIN[33] , PIN[37] , GIN[37] , GIN[41] , PHI , POUT[33] , GOUT[41] );
   BLOCK1 U342 (PIN[34] , PIN[38] , GIN[38] , GIN[42] , PHI , POUT[34] , GOUT[42] );
   BLOCK1 U343 (PIN[35] , PIN[39] , GIN[39] , GIN[43] , PHI , POUT[35] , GOUT[43] );
   BLOCK1 U344 (PIN[36] , PIN[40] , GIN[40] , GIN[44] , PHI , POUT[36] , GOUT[44] );
   BLOCK1 U345 (PIN[37] , PIN[41] , GIN[41] , GIN[45] , PHI , POUT[37] , GOUT[45] );
   BLOCK1 U346 (PIN[38] , PIN[42] , GIN[42] , GIN[46] , PHI , POUT[38] , GOUT[46] );
   BLOCK1 U347 (PIN[39] , PIN[43] , GIN[43] , GIN[47] , PHI , POUT[39] , GOUT[47] );
   BLOCK1 U348 (PIN[40] , PIN[44] , GIN[44] , GIN[48] , PHI , POUT[40] , GOUT[48] );
   BLOCK1 U349 (PIN[41] , PIN[45] , GIN[45] , GIN[49] , PHI , POUT[41] , GOUT[49] );
   BLOCK1 U350 (PIN[42] , PIN[46] , GIN[46] , GIN[50] , PHI , POUT[42] , GOUT[50] );
   BLOCK1 U351 (PIN[43] , PIN[47] , GIN[47] , GIN[51] , PHI , POUT[43] , GOUT[51] );
   BLOCK1 U352 (PIN[44] , PIN[48] , GIN[48] , GIN[52] , PHI , POUT[44] , GOUT[52] );
   BLOCK1 U353 (PIN[45] , PIN[49] , GIN[49] , GIN[53] , PHI , POUT[45] , GOUT[53] );
   BLOCK1 U354 (PIN[46] , PIN[50] , GIN[50] , GIN[54] , PHI , POUT[46] , GOUT[54] );
   BLOCK1 U355 (PIN[47] , PIN[51] , GIN[51] , GIN[55] , PHI , POUT[47] , GOUT[55] );
   BLOCK1 U356 (PIN[48] , PIN[52] , GIN[52] , GIN[56] , PHI , POUT[48] , GOUT[56] );
   BLOCK1 U357 (PIN[49] , PIN[53] , GIN[53] , GIN[57] , PHI , POUT[49] , GOUT[57] );
   BLOCK1 U358 (PIN[50] , PIN[54] , GIN[54] , GIN[58] , PHI , POUT[50] , GOUT[58] );
   BLOCK1 U359 (PIN[51] , PIN[55] , GIN[55] , GIN[59] , PHI , POUT[51] , GOUT[59] );
   BLOCK1 U360 (PIN[52] , PIN[56] , GIN[56] , GIN[60] , PHI , POUT[52] , GOUT[60] );
   BLOCK1 U361 (PIN[53] , PIN[57] , GIN[57] , GIN[61] , PHI , POUT[53] , GOUT[61] );
   BLOCK1 U362 (PIN[54] , PIN[58] , GIN[58] , GIN[62] , PHI , POUT[54] , GOUT[62] );
   BLOCK1 U363 (PIN[55] , PIN[59] , GIN[59] , GIN[63] , PHI , POUT[55] , GOUT[63] );
   BLOCK1 U364 (PIN[56] , PIN[60] , GIN[60] , GIN[64] , PHI , POUT[56] , GOUT[64] );
endmodule


module DBLC_3_64 ( PIN, GIN, PHI, POUT, GOUT );
input  [0:56] PIN;
input  [0:64] GIN;
input  PHI;
output [0:48] POUT;
output [0:64] GOUT;
   INVBLOCK U10 (GIN[0] , PHI , GOUT[0] );
   INVBLOCK U11 (GIN[1] , PHI , GOUT[1] );
   INVBLOCK U12 (GIN[2] , PHI , GOUT[2] );
   INVBLOCK U13 (GIN[3] , PHI , GOUT[3] );
   INVBLOCK U14 (GIN[4] , PHI , GOUT[4] );
   INVBLOCK U15 (GIN[5] , PHI , GOUT[5] );
   INVBLOCK U16 (GIN[6] , PHI , GOUT[6] );
   INVBLOCK U17 (GIN[7] , PHI , GOUT[7] );
   BLOCK2A U28 (PIN[0] , GIN[0] , GIN[8] , PHI , GOUT[8] );
   BLOCK2A U29 (PIN[1] , GIN[1] , GIN[9] , PHI , GOUT[9] );
   BLOCK2A U210 (PIN[2] , GIN[2] , GIN[10] , PHI , GOUT[10] );
   BLOCK2A U211 (PIN[3] , GIN[3] , GIN[11] , PHI , GOUT[11] );
   BLOCK2A U212 (PIN[4] , GIN[4] , GIN[12] , PHI , GOUT[12] );
   BLOCK2A U213 (PIN[5] , GIN[5] , GIN[13] , PHI , GOUT[13] );
   BLOCK2A U214 (PIN[6] , GIN[6] , GIN[14] , PHI , GOUT[14] );
   BLOCK2A U215 (PIN[7] , GIN[7] , GIN[15] , PHI , GOUT[15] );
   BLOCK2 U316 (PIN[0] , PIN[8] , GIN[8] , GIN[16] , PHI , POUT[0] , GOUT[16] );
   BLOCK2 U317 (PIN[1] , PIN[9] , GIN[9] , GIN[17] , PHI , POUT[1] , GOUT[17] );
   BLOCK2 U318 (PIN[2] , PIN[10] , GIN[10] , GIN[18] , PHI , POUT[2] , GOUT[18] );
   BLOCK2 U319 (PIN[3] , PIN[11] , GIN[11] , GIN[19] , PHI , POUT[3] , GOUT[19] );
   BLOCK2 U320 (PIN[4] , PIN[12] , GIN[12] , GIN[20] , PHI , POUT[4] , GOUT[20] );
   BLOCK2 U321 (PIN[5] , PIN[13] , GIN[13] , GIN[21] , PHI , POUT[5] , GOUT[21] );
   BLOCK2 U322 (PIN[6] , PIN[14] , GIN[14] , GIN[22] , PHI , POUT[6] , GOUT[22] );
   BLOCK2 U323 (PIN[7] , PIN[15] , GIN[15] , GIN[23] , PHI , POUT[7] , GOUT[23] );
   BLOCK2 U324 (PIN[8] , PIN[16] , GIN[16] , GIN[24] , PHI , POUT[8] , GOUT[24] );
   BLOCK2 U325 (PIN[9] , PIN[17] , GIN[17] , GIN[25] , PHI , POUT[9] , GOUT[25] );
   BLOCK2 U326 (PIN[10] , PIN[18] , GIN[18] , GIN[26] , PHI , POUT[10] , GOUT[26] );
   BLOCK2 U327 (PIN[11] , PIN[19] , GIN[19] , GIN[27] , PHI , POUT[11] , GOUT[27] );
   BLOCK2 U328 (PIN[12] , PIN[20] , GIN[20] , GIN[28] , PHI , POUT[12] , GOUT[28] );
   BLOCK2 U329 (PIN[13] , PIN[21] , GIN[21] , GIN[29] , PHI , POUT[13] , GOUT[29] );
   BLOCK2 U330 (PIN[14] , PIN[22] , GIN[22] , GIN[30] , PHI , POUT[14] , GOUT[30] );
   BLOCK2 U331 (PIN[15] , PIN[23] , GIN[23] , GIN[31] , PHI , POUT[15] , GOUT[31] );
   BLOCK2 U332 (PIN[16] , PIN[24] , GIN[24] , GIN[32] , PHI , POUT[16] , GOUT[32] );
   BLOCK2 U333 (PIN[17] , PIN[25] , GIN[25] , GIN[33] , PHI , POUT[17] , GOUT[33] );
   BLOCK2 U334 (PIN[18] , PIN[26] , GIN[26] , GIN[34] , PHI , POUT[18] , GOUT[34] );
   BLOCK2 U335 (PIN[19] , PIN[27] , GIN[27] , GIN[35] , PHI , POUT[19] , GOUT[35] );
   BLOCK2 U336 (PIN[20] , PIN[28] , GIN[28] , GIN[36] , PHI , POUT[20] , GOUT[36] );
   BLOCK2 U337 (PIN[21] , PIN[29] , GIN[29] , GIN[37] , PHI , POUT[21] , GOUT[37] );
   BLOCK2 U338 (PIN[22] , PIN[30] , GIN[30] , GIN[38] , PHI , POUT[22] , GOUT[38] );
   BLOCK2 U339 (PIN[23] , PIN[31] , GIN[31] , GIN[39] , PHI , POUT[23] , GOUT[39] );
   BLOCK2 U340 (PIN[24] , PIN[32] , GIN[32] , GIN[40] , PHI , POUT[24] , GOUT[40] );
   BLOCK2 U341 (PIN[25] , PIN[33] , GIN[33] , GIN[41] , PHI , POUT[25] , GOUT[41] );
   BLOCK2 U342 (PIN[26] , PIN[34] , GIN[34] , GIN[42] , PHI , POUT[26] , GOUT[42] );
   BLOCK2 U343 (PIN[27] , PIN[35] , GIN[35] , GIN[43] , PHI , POUT[27] , GOUT[43] );
   BLOCK2 U344 (PIN[28] , PIN[36] , GIN[36] , GIN[44] , PHI , POUT[28] , GOUT[44] );
   BLOCK2 U345 (PIN[29] , PIN[37] , GIN[37] , GIN[45] , PHI , POUT[29] , GOUT[45] );
   BLOCK2 U346 (PIN[30] , PIN[38] , GIN[38] , GIN[46] , PHI , POUT[30] , GOUT[46] );
   BLOCK2 U347 (PIN[31] , PIN[39] , GIN[39] , GIN[47] , PHI , POUT[31] , GOUT[47] );
   BLOCK2 U348 (PIN[32] , PIN[40] , GIN[40] , GIN[48] , PHI , POUT[32] , GOUT[48] );
   BLOCK2 U349 (PIN[33] , PIN[41] , GIN[41] , GIN[49] , PHI , POUT[33] , GOUT[49] );
   BLOCK2 U350 (PIN[34] , PIN[42] , GIN[42] , GIN[50] , PHI , POUT[34] , GOUT[50] );
   BLOCK2 U351 (PIN[35] , PIN[43] , GIN[43] , GIN[51] , PHI , POUT[35] , GOUT[51] );
   BLOCK2 U352 (PIN[36] , PIN[44] , GIN[44] , GIN[52] , PHI , POUT[36] , GOUT[52] );
   BLOCK2 U353 (PIN[37] , PIN[45] , GIN[45] , GIN[53] , PHI , POUT[37] , GOUT[53] );
   BLOCK2 U354 (PIN[38] , PIN[46] , GIN[46] , GIN[54] , PHI , POUT[38] , GOUT[54] );
   BLOCK2 U355 (PIN[39] , PIN[47] , GIN[47] , GIN[55] , PHI , POUT[39] , GOUT[55] );
   BLOCK2 U356 (PIN[40] , PIN[48] , GIN[48] , GIN[56] , PHI , POUT[40] , GOUT[56] );
   BLOCK2 U357 (PIN[41] , PIN[49] , GIN[49] , GIN[57] , PHI , POUT[41] , GOUT[57] );
   BLOCK2 U358 (PIN[42] , PIN[50] , GIN[50] , GIN[58] , PHI , POUT[42] , GOUT[58] );
   BLOCK2 U359 (PIN[43] , PIN[51] , GIN[51] , GIN[59] , PHI , POUT[43] , GOUT[59] );
   BLOCK2 U360 (PIN[44] , PIN[52] , GIN[52] , GIN[60] , PHI , POUT[44] , GOUT[60] );
   BLOCK2 U361 (PIN[45] , PIN[53] , GIN[53] , GIN[61] , PHI , POUT[45] , GOUT[61] );
   BLOCK2 U362 (PIN[46] , PIN[54] , GIN[54] , GIN[62] , PHI , POUT[46] , GOUT[62] );
   BLOCK2 U363 (PIN[47] , PIN[55] , GIN[55] , GIN[63] , PHI , POUT[47] , GOUT[63] );
   BLOCK2 U364 (PIN[48] , PIN[56] , GIN[56] , GIN[64] , PHI , POUT[48] , GOUT[64] );
endmodule


module DBLC_4_64 ( PIN, GIN, PHI, POUT, GOUT );
input  [0:48] PIN;
input  [0:64] GIN;
input  PHI;
output [0:32] POUT;
output [0:64] GOUT;
   INVBLOCK U10 (GIN[0] , PHI , GOUT[0] );
   INVBLOCK U11 (GIN[1] , PHI , GOUT[1] );
   INVBLOCK U12 (GIN[2] , PHI , GOUT[2] );
   INVBLOCK U13 (GIN[3] , PHI , GOUT[3] );
   INVBLOCK U14 (GIN[4] , PHI , GOUT[4] );
   INVBLOCK U15 (GIN[5] , PHI , GOUT[5] );
   INVBLOCK U16 (GIN[6] , PHI , GOUT[6] );
   INVBLOCK U17 (GIN[7] , PHI , GOUT[7] );
   INVBLOCK U18 (GIN[8] , PHI , GOUT[8] );
   INVBLOCK U19 (GIN[9] , PHI , GOUT[9] );
   INVBLOCK U110 (GIN[10] , PHI , GOUT[10] );
   INVBLOCK U111 (GIN[11] , PHI , GOUT[11] );
   INVBLOCK U112 (GIN[12] , PHI , GOUT[12] );
   INVBLOCK U113 (GIN[13] , PHI , GOUT[13] );
   INVBLOCK U114 (GIN[14] , PHI , GOUT[14] );
   INVBLOCK U115 (GIN[15] , PHI , GOUT[15] );
   BLOCK1A U216 (PIN[0] , GIN[0] , GIN[16] , PHI , GOUT[16] );
   BLOCK1A U217 (PIN[1] , GIN[1] , GIN[17] , PHI , GOUT[17] );
   BLOCK1A U218 (PIN[2] , GIN[2] , GIN[18] , PHI , GOUT[18] );
   BLOCK1A U219 (PIN[3] , GIN[3] , GIN[19] , PHI , GOUT[19] );
   BLOCK1A U220 (PIN[4] , GIN[4] , GIN[20] , PHI , GOUT[20] );
   BLOCK1A U221 (PIN[5] , GIN[5] , GIN[21] , PHI , GOUT[21] );
   BLOCK1A U222 (PIN[6] , GIN[6] , GIN[22] , PHI , GOUT[22] );
   BLOCK1A U223 (PIN[7] , GIN[7] , GIN[23] , PHI , GOUT[23] );
   BLOCK1A U224 (PIN[8] , GIN[8] , GIN[24] , PHI , GOUT[24] );
   BLOCK1A U225 (PIN[9] , GIN[9] , GIN[25] , PHI , GOUT[25] );
   BLOCK1A U226 (PIN[10] , GIN[10] , GIN[26] , PHI , GOUT[26] );
   BLOCK1A U227 (PIN[11] , GIN[11] , GIN[27] , PHI , GOUT[27] );
   BLOCK1A U228 (PIN[12] , GIN[12] , GIN[28] , PHI , GOUT[28] );
   BLOCK1A U229 (PIN[13] , GIN[13] , GIN[29] , PHI , GOUT[29] );
   BLOCK1A U230 (PIN[14] , GIN[14] , GIN[30] , PHI , GOUT[30] );
   BLOCK1A U231 (PIN[15] , GIN[15] , GIN[31] , PHI , GOUT[31] );
   BLOCK1 U332 (PIN[0] , PIN[16] , GIN[16] , GIN[32] , PHI , POUT[0] , GOUT[32] );
   BLOCK1 U333 (PIN[1] , PIN[17] , GIN[17] , GIN[33] , PHI , POUT[1] , GOUT[33] );
   BLOCK1 U334 (PIN[2] , PIN[18] , GIN[18] , GIN[34] , PHI , POUT[2] , GOUT[34] );
   BLOCK1 U335 (PIN[3] , PIN[19] , GIN[19] , GIN[35] , PHI , POUT[3] , GOUT[35] );
   BLOCK1 U336 (PIN[4] , PIN[20] , GIN[20] , GIN[36] , PHI , POUT[4] , GOUT[36] );
   BLOCK1 U337 (PIN[5] , PIN[21] , GIN[21] , GIN[37] , PHI , POUT[5] , GOUT[37] );
   BLOCK1 U338 (PIN[6] , PIN[22] , GIN[22] , GIN[38] , PHI , POUT[6] , GOUT[38] );
   BLOCK1 U339 (PIN[7] , PIN[23] , GIN[23] , GIN[39] , PHI , POUT[7] , GOUT[39] );
   BLOCK1 U340 (PIN[8] , PIN[24] , GIN[24] , GIN[40] , PHI , POUT[8] , GOUT[40] );
   BLOCK1 U341 (PIN[9] , PIN[25] , GIN[25] , GIN[41] , PHI , POUT[9] , GOUT[41] );
   BLOCK1 U342 (PIN[10] , PIN[26] , GIN[26] , GIN[42] , PHI , POUT[10] , GOUT[42] );
   BLOCK1 U343 (PIN[11] , PIN[27] , GIN[27] , GIN[43] , PHI , POUT[11] , GOUT[43] );
   BLOCK1 U344 (PIN[12] , PIN[28] , GIN[28] , GIN[44] , PHI , POUT[12] , GOUT[44] );
   BLOCK1 U345 (PIN[13] , PIN[29] , GIN[29] , GIN[45] , PHI , POUT[13] , GOUT[45] );
   BLOCK1 U346 (PIN[14] , PIN[30] , GIN[30] , GIN[46] , PHI , POUT[14] , GOUT[46] );
   BLOCK1 U347 (PIN[15] , PIN[31] , GIN[31] , GIN[47] , PHI , POUT[15] , GOUT[47] );
   BLOCK1 U348 (PIN[16] , PIN[32] , GIN[32] , GIN[48] , PHI , POUT[16] , GOUT[48] );
   BLOCK1 U349 (PIN[17] , PIN[33] , GIN[33] , GIN[49] , PHI , POUT[17] , GOUT[49] );
   BLOCK1 U350 (PIN[18] , PIN[34] , GIN[34] , GIN[50] , PHI , POUT[18] , GOUT[50] );
   BLOCK1 U351 (PIN[19] , PIN[35] , GIN[35] , GIN[51] , PHI , POUT[19] , GOUT[51] );
   BLOCK1 U352 (PIN[20] , PIN[36] , GIN[36] , GIN[52] , PHI , POUT[20] , GOUT[52] );
   BLOCK1 U353 (PIN[21] , PIN[37] , GIN[37] , GIN[53] , PHI , POUT[21] , GOUT[53] );
   BLOCK1 U354 (PIN[22] , PIN[38] , GIN[38] , GIN[54] , PHI , POUT[22] , GOUT[54] );
   BLOCK1 U355 (PIN[23] , PIN[39] , GIN[39] , GIN[55] , PHI , POUT[23] , GOUT[55] );
   BLOCK1 U356 (PIN[24] , PIN[40] , GIN[40] , GIN[56] , PHI , POUT[24] , GOUT[56] );
   BLOCK1 U357 (PIN[25] , PIN[41] , GIN[41] , GIN[57] , PHI , POUT[25] , GOUT[57] );
   BLOCK1 U358 (PIN[26] , PIN[42] , GIN[42] , GIN[58] , PHI , POUT[26] , GOUT[58] );
   BLOCK1 U359 (PIN[27] , PIN[43] , GIN[43] , GIN[59] , PHI , POUT[27] , GOUT[59] );
   BLOCK1 U360 (PIN[28] , PIN[44] , GIN[44] , GIN[60] , PHI , POUT[28] , GOUT[60] );
   BLOCK1 U361 (PIN[29] , PIN[45] , GIN[45] , GIN[61] , PHI , POUT[29] , GOUT[61] );
   BLOCK1 U362 (PIN[30] , PIN[46] , GIN[46] , GIN[62] , PHI , POUT[30] , GOUT[62] );
   BLOCK1 U363 (PIN[31] , PIN[47] , GIN[47] , GIN[63] , PHI , POUT[31] , GOUT[63] );
   BLOCK1 U364 (PIN[32] , PIN[48] , GIN[48] , GIN[64] , PHI , POUT[32] , GOUT[64] );
endmodule


module DBLC_5_64 ( PIN, GIN, PHI, POUT, GOUT );
input  [0:32] PIN;
input  [0:64] GIN;
input  PHI;
output [0:0] POUT;
output [0:64] GOUT;
   INVBLOCK U10 (GIN[0] , PHI , GOUT[0] );
   INVBLOCK U11 (GIN[1] , PHI , GOUT[1] );
   INVBLOCK U12 (GIN[2] , PHI , GOUT[2] );
   INVBLOCK U13 (GIN[3] , PHI , GOUT[3] );
   INVBLOCK U14 (GIN[4] , PHI , GOUT[4] );
   INVBLOCK U15 (GIN[5] , PHI , GOUT[5] );
   INVBLOCK U16 (GIN[6] , PHI , GOUT[6] );
   INVBLOCK U17 (GIN[7] , PHI , GOUT[7] );
   INVBLOCK U18 (GIN[8] , PHI , GOUT[8] );
   INVBLOCK U19 (GIN[9] , PHI , GOUT[9] );
   INVBLOCK U110 (GIN[10] , PHI , GOUT[10] );
   INVBLOCK U111 (GIN[11] , PHI , GOUT[11] );
   INVBLOCK U112 (GIN[12] , PHI , GOUT[12] );
   INVBLOCK U113 (GIN[13] , PHI , GOUT[13] );
   INVBLOCK U114 (GIN[14] , PHI , GOUT[14] );
   INVBLOCK U115 (GIN[15] , PHI , GOUT[15] );
   INVBLOCK U116 (GIN[16] , PHI , GOUT[16] );
   INVBLOCK U117 (GIN[17] , PHI , GOUT[17] );
   INVBLOCK U118 (GIN[18] , PHI , GOUT[18] );
   INVBLOCK U119 (GIN[19] , PHI , GOUT[19] );
   INVBLOCK U120 (GIN[20] , PHI , GOUT[20] );
   INVBLOCK U121 (GIN[21] , PHI , GOUT[21] );
   INVBLOCK U122 (GIN[22] , PHI , GOUT[22] );
   INVBLOCK U123 (GIN[23] , PHI , GOUT[23] );
   INVBLOCK U124 (GIN[24] , PHI , GOUT[24] );
   INVBLOCK U125 (GIN[25] , PHI , GOUT[25] );
   INVBLOCK U126 (GIN[26] , PHI , GOUT[26] );
   INVBLOCK U127 (GIN[27] , PHI , GOUT[27] );
   INVBLOCK U128 (GIN[28] , PHI , GOUT[28] );
   INVBLOCK U129 (GIN[29] , PHI , GOUT[29] );
   INVBLOCK U130 (GIN[30] , PHI , GOUT[30] );
   INVBLOCK U131 (GIN[31] , PHI , GOUT[31] );
   BLOCK2A U232 (PIN[0] , GIN[0] , GIN[32] , PHI , GOUT[32] );
   BLOCK2A U233 (PIN[1] , GIN[1] , GIN[33] , PHI , GOUT[33] );
   BLOCK2A U234 (PIN[2] , GIN[2] , GIN[34] , PHI , GOUT[34] );
   BLOCK2A U235 (PIN[3] , GIN[3] , GIN[35] , PHI , GOUT[35] );
   BLOCK2A U236 (PIN[4] , GIN[4] , GIN[36] , PHI , GOUT[36] );
   BLOCK2A U237 (PIN[5] , GIN[5] , GIN[37] , PHI , GOUT[37] );
   BLOCK2A U238 (PIN[6] , GIN[6] , GIN[38] , PHI , GOUT[38] );
   BLOCK2A U239 (PIN[7] , GIN[7] , GIN[39] , PHI , GOUT[39] );
   BLOCK2A U240 (PIN[8] , GIN[8] , GIN[40] , PHI , GOUT[40] );
   BLOCK2A U241 (PIN[9] , GIN[9] , GIN[41] , PHI , GOUT[41] );
   BLOCK2A U242 (PIN[10] , GIN[10] , GIN[42] , PHI , GOUT[42] );
   BLOCK2A U243 (PIN[11] , GIN[11] , GIN[43] , PHI , GOUT[43] );
   BLOCK2A U244 (PIN[12] , GIN[12] , GIN[44] , PHI , GOUT[44] );
   BLOCK2A U245 (PIN[13] , GIN[13] , GIN[45] , PHI , GOUT[45] );
   BLOCK2A U246 (PIN[14] , GIN[14] , GIN[46] , PHI , GOUT[46] );
   BLOCK2A U247 (PIN[15] , GIN[15] , GIN[47] , PHI , GOUT[47] );
   BLOCK2A U248 (PIN[16] , GIN[16] , GIN[48] , PHI , GOUT[48] );
   BLOCK2A U249 (PIN[17] , GIN[17] , GIN[49] , PHI , GOUT[49] );
   BLOCK2A U250 (PIN[18] , GIN[18] , GIN[50] , PHI , GOUT[50] );
   BLOCK2A U251 (PIN[19] , GIN[19] , GIN[51] , PHI , GOUT[51] );
   BLOCK2A U252 (PIN[20] , GIN[20] , GIN[52] , PHI , GOUT[52] );
   BLOCK2A U253 (PIN[21] , GIN[21] , GIN[53] , PHI , GOUT[53] );
   BLOCK2A U254 (PIN[22] , GIN[22] , GIN[54] , PHI , GOUT[54] );
   BLOCK2A U255 (PIN[23] , GIN[23] , GIN[55] , PHI , GOUT[55] );
   BLOCK2A U256 (PIN[24] , GIN[24] , GIN[56] , PHI , GOUT[56] );
   BLOCK2A U257 (PIN[25] , GIN[25] , GIN[57] , PHI , GOUT[57] );
   BLOCK2A U258 (PIN[26] , GIN[26] , GIN[58] , PHI , GOUT[58] );
   BLOCK2A U259 (PIN[27] , GIN[27] , GIN[59] , PHI , GOUT[59] );
   BLOCK2A U260 (PIN[28] , GIN[28] , GIN[60] , PHI , GOUT[60] );
   BLOCK2A U261 (PIN[29] , GIN[29] , GIN[61] , PHI , GOUT[61] );
   BLOCK2A U262 (PIN[30] , GIN[30] , GIN[62] , PHI , GOUT[62] );
   BLOCK2A U263 (PIN[31] , GIN[31] , GIN[63] , PHI , GOUT[63] );
   BLOCK2 U364 (PIN[0] , PIN[32] , GIN[32] , GIN[64] , PHI , POUT[0] , GOUT[64] );
endmodule


module XORSTAGE_64 ( A, B, PBIT, PHI, CARRY, SUM, COUT );
input  [0:63] A;
input  [0:63] B;
input  PBIT;
input  PHI;
input  [0:64] CARRY;
output [0:63] SUM;
output COUT;
   XXOR1 U20 (A[0] , B[0] , CARRY[0] , PHI , SUM[0] );
   XXOR1 U21 (A[1] , B[1] , CARRY[1] , PHI , SUM[1] );
   XXOR1 U22 (A[2] , B[2] , CARRY[2] , PHI , SUM[2] );
   XXOR1 U23 (A[3] , B[3] , CARRY[3] , PHI , SUM[3] );
   XXOR1 U24 (A[4] , B[4] , CARRY[4] , PHI , SUM[4] );
   XXOR1 U25 (A[5] , B[5] , CARRY[5] , PHI , SUM[5] );
   XXOR1 U26 (A[6] , B[6] , CARRY[6] , PHI , SUM[6] );
   XXOR1 U27 (A[7] , B[7] , CARRY[7] , PHI , SUM[7] );
   XXOR1 U28 (A[8] , B[8] , CARRY[8] , PHI , SUM[8] );
   XXOR1 U29 (A[9] , B[9] , CARRY[9] , PHI , SUM[9] );
   XXOR1 U210 (A[10] , B[10] , CARRY[10] , PHI , SUM[10] );
   XXOR1 U211 (A[11] , B[11] , CARRY[11] , PHI , SUM[11] );
   XXOR1 U212 (A[12] , B[12] , CARRY[12] , PHI , SUM[12] );
   XXOR1 U213 (A[13] , B[13] , CARRY[13] , PHI , SUM[13] );
   XXOR1 U214 (A[14] , B[14] , CARRY[14] , PHI , SUM[14] );
   XXOR1 U215 (A[15] , B[15] , CARRY[15] , PHI , SUM[15] );
   XXOR1 U216 (A[16] , B[16] , CARRY[16] , PHI , SUM[16] );
   XXOR1 U217 (A[17] , B[17] , CARRY[17] , PHI , SUM[17] );
   XXOR1 U218 (A[18] , B[18] , CARRY[18] , PHI , SUM[18] );
   XXOR1 U219 (A[19] , B[19] , CARRY[19] , PHI , SUM[19] );
   XXOR1 U220 (A[20] , B[20] , CARRY[20] , PHI , SUM[20] );
   XXOR1 U221 (A[21] , B[21] , CARRY[21] , PHI , SUM[21] );
   XXOR1 U222 (A[22] , B[22] , CARRY[22] , PHI , SUM[22] );
   XXOR1 U223 (A[23] , B[23] , CARRY[23] , PHI , SUM[23] );
   XXOR1 U224 (A[24] , B[24] , CARRY[24] , PHI , SUM[24] );
   XXOR1 U225 (A[25] , B[25] , CARRY[25] , PHI , SUM[25] );
   XXOR1 U226 (A[26] , B[26] , CARRY[26] , PHI , SUM[26] );
   XXOR1 U227 (A[27] , B[27] , CARRY[27] , PHI , SUM[27] );
   XXOR1 U228 (A[28] , B[28] , CARRY[28] , PHI , SUM[28] );
   XXOR1 U229 (A[29] , B[29] , CARRY[29] , PHI , SUM[29] );
   XXOR1 U230 (A[30] , B[30] , CARRY[30] , PHI , SUM[30] );
   XXOR1 U231 (A[31] , B[31] , CARRY[31] , PHI , SUM[31] );
   XXOR1 U232 (A[32] , B[32] , CARRY[32] , PHI , SUM[32] );
   XXOR1 U233 (A[33] , B[33] , CARRY[33] , PHI , SUM[33] );
   XXOR1 U234 (A[34] , B[34] , CARRY[34] , PHI , SUM[34] );
   XXOR1 U235 (A[35] , B[35] , CARRY[35] , PHI , SUM[35] );
   XXOR1 U236 (A[36] , B[36] , CARRY[36] , PHI , SUM[36] );
   XXOR1 U237 (A[37] , B[37] , CARRY[37] , PHI , SUM[37] );
   XXOR1 U238 (A[38] , B[38] , CARRY[38] , PHI , SUM[38] );
   XXOR1 U239 (A[39] , B[39] , CARRY[39] , PHI , SUM[39] );
   XXOR1 U240 (A[40] , B[40] , CARRY[40] , PHI , SUM[40] );
   XXOR1 U241 (A[41] , B[41] , CARRY[41] , PHI , SUM[41] );
   XXOR1 U242 (A[42] , B[42] , CARRY[42] , PHI , SUM[42] );
   XXOR1 U243 (A[43] , B[43] , CARRY[43] , PHI , SUM[43] );
   XXOR1 U244 (A[44] , B[44] , CARRY[44] , PHI , SUM[44] );
   XXOR1 U245 (A[45] , B[45] , CARRY[45] , PHI , SUM[45] );
   XXOR1 U246 (A[46] , B[46] , CARRY[46] , PHI , SUM[46] );
   XXOR1 U247 (A[47] , B[47] , CARRY[47] , PHI , SUM[47] );
   XXOR1 U248 (A[48] , B[48] , CARRY[48] , PHI , SUM[48] );
   XXOR1 U249 (A[49] , B[49] , CARRY[49] , PHI , SUM[49] );
   XXOR1 U250 (A[50] , B[50] , CARRY[50] , PHI , SUM[50] );
   XXOR1 U251 (A[51] , B[51] , CARRY[51] , PHI , SUM[51] );
   XXOR1 U252 (A[52] , B[52] , CARRY[52] , PHI , SUM[52] );
   XXOR1 U253 (A[53] , B[53] , CARRY[53] , PHI , SUM[53] );
   XXOR1 U254 (A[54] , B[54] , CARRY[54] , PHI , SUM[54] );
   XXOR1 U255 (A[55] , B[55] , CARRY[55] , PHI , SUM[55] );
   XXOR1 U256 (A[56] , B[56] , CARRY[56] , PHI , SUM[56] );
   XXOR1 U257 (A[57] , B[57] , CARRY[57] , PHI , SUM[57] );
   XXOR1 U258 (A[58] , B[58] , CARRY[58] , PHI , SUM[58] );
   XXOR1 U259 (A[59] , B[59] , CARRY[59] , PHI , SUM[59] );
   XXOR1 U260 (A[60] , B[60] , CARRY[60] , PHI , SUM[60] );
   XXOR1 U261 (A[61] , B[61] , CARRY[61] , PHI , SUM[61] );
   XXOR1 U262 (A[62] , B[62] , CARRY[62] , PHI , SUM[62] );
   XXOR1 U263 (A[63] , B[63] , CARRY[63] , PHI , SUM[63] );
   BLOCK1A U1 (PBIT , CARRY[0] , CARRY[64] , PHI , COUT );
endmodule


module DBLCTREE_64 ( PIN, GIN, PHI, GOUT, POUT );
input  [0:63] PIN;
input  [0:64] GIN;
input  PHI;
output [0:64] GOUT;
output [0:0] POUT;
   wire [0:62] INTPROP_0;
   wire [0:64] INTGEN_0;
   wire [0:60] INTPROP_1;
   wire [0:64] INTGEN_1;
   wire [0:56] INTPROP_2;
   wire [0:64] INTGEN_2;
   wire [0:48] INTPROP_3;
   wire [0:64] INTGEN_3;
   wire [0:32] INTPROP_4;
   wire [0:64] INTGEN_4;
   DBLC_0_64 U_0 (.PIN(PIN) , .GIN(GIN) , .PHI(PHI) , .POUT(INTPROP_0) , .GOUT(INTGEN_0) );
   DBLC_1_64 U_1 (.PIN(INTPROP_0) , .GIN(INTGEN_0) , .PHI(PHI) , .POUT(INTPROP_1) , .GOUT(INTGEN_1) );
   DBLC_2_64 U_2 (.PIN(INTPROP_1) , .GIN(INTGEN_1) , .PHI(PHI) , .POUT(INTPROP_2) , .GOUT(INTGEN_2) );
   DBLC_3_64 U_3 (.PIN(INTPROP_2) , .GIN(INTGEN_2) , .PHI(PHI) , .POUT(INTPROP_3) , .GOUT(INTGEN_3) );
   DBLC_4_64 U_4 (.PIN(INTPROP_3) , .GIN(INTGEN_3) , .PHI(PHI) , .POUT(INTPROP_4) , .GOUT(INTGEN_4) );
   DBLC_5_64 U_5 (.PIN(INTPROP_4) , .GIN(INTGEN_4) , .PHI(PHI) , .POUT(POUT) , .GOUT(GOUT) );
endmodule


module DBLCADDER_64_64 ( OPA, OPB, CIN, PHI, SUM, COUT );
input  [0:63] OPA;
input  [0:63] OPB;
input  CIN;
input  PHI;
output [0:63] SUM;
output COUT;
   wire [0:63] INTPROP;
   wire [0:64] INTGEN;
   wire [0:0] PBIT;
   wire [0:64] CARRY;
   PRESTAGE_64 U1 (OPA , OPB , CIN , PHI , INTPROP , INTGEN );
   DBLCTREE_64 U2 (INTPROP , INTGEN , PHI , CARRY , PBIT );
   XORSTAGE_64 U3 (OPA[0:63] , OPB[0:63] , PBIT[0] , PHI , CARRY[0:64] , SUM , COUT );
endmodule


module MULTIPLIER_33_32 ( MULTIPLICAND, MULTIPLIER, RST, CLK, PHI, RESULT );
input  [0:32] MULTIPLICAND;
input  [0:31] MULTIPLIER;
input  RST;
input  CLK;
input  PHI;
output [0:63] RESULT;
   wire [0:575] PPBIT;
   wire [0:64] INT_CARRY;
   wire [0:63] INT_SUM;
   wire LOGIC_ZERO;
   wire [0:63] ARESULT;
   reg [0:63] RESULT;
   assign LOGIC_ZERO = 0;
   BOOTHCODER_33_32 B (.OPA(MULTIPLICAND[0:32]) , .OPB(MULTIPLIER[0:31]) , .SUMMAND(PPBIT[0:575]) );
   WALLACE_33_32 W (.SUMMAND(PPBIT[0:575]) , .RST(RST), .CLK (CLK) , .CARRY(INT_CARRY[1:63]) , .SUM(INT_SUM[0:63]) );
   assign INT_CARRY[0] = LOGIC_ZERO;
   DBLCADDER_64_64 D (.OPA(INT_SUM[0:63]) , .OPB(INT_CARRY[0:63]) , .CIN (LOGIC_ZERO) , .PHI (PHI) , .SUM(ARESULT[0:63]), .COUT() );
   always @(posedge CLK or posedge RST)
     if (RST)
	RESULT <= #1 64'h0000_0000_0000_0000;
     else
	RESULT <= ARESULT;
endmodule


// 32x32 multiplier, no input/output registers
// Registers inside Wallace trees every 8 full adder levels,
// with first pipeline after level 4

module or1200_amultp2_32x32 ( X, Y, RST, CLK, P );
input  [31:0] X;
input  [31:0] Y;
input  RST;
input  CLK;
output [63:0] P;
   wire [0:32] A;
   wire [0:31] B;
   wire [0:63] Q;
   assign A[0] = X[0];
   assign A[1] = X[1];
   assign A[2] = X[2];
   assign A[3] = X[3];
   assign A[4] = X[4];
   assign A[5] = X[5];
   assign A[6] = X[6];
   assign A[7] = X[7];
   assign A[8] = X[8];
   assign A[9] = X[9];
   assign A[10] = X[10];
   assign A[11] = X[11];
   assign A[12] = X[12];
   assign A[13] = X[13];
   assign A[14] = X[14];
   assign A[15] = X[15];
   assign A[16] = X[16];
   assign A[17] = X[17];
   assign A[18] = X[18];
   assign A[19] = X[19];
   assign A[20] = X[20];
   assign A[21] = X[21];
   assign A[22] = X[22];
   assign A[23] = X[23];
   assign A[24] = X[24];
   assign A[25] = X[25];
   assign A[26] = X[26];
   assign A[27] = X[27];
   assign A[28] = X[28];
   assign A[29] = X[29];
   assign A[30] = X[30];
   assign A[31] = X[31];
   assign A[32] = X[31];
   assign B[0] = Y[0];
   assign B[1] = Y[1];
   assign B[2] = Y[2];
   assign B[3] = Y[3];
   assign B[4] = Y[4];
   assign B[5] = Y[5];
   assign B[6] = Y[6];
   assign B[7] = Y[7];
   assign B[8] = Y[8];
   assign B[9] = Y[9];
   assign B[10] = Y[10];
   assign B[11] = Y[11];
   assign B[12] = Y[12];
   assign B[13] = Y[13];
   assign B[14] = Y[14];
   assign B[15] = Y[15];
   assign B[16] = Y[16];
   assign B[17] = Y[17];
   assign B[18] = Y[18];
   assign B[19] = Y[19];
   assign B[20] = Y[20];
   assign B[21] = Y[21];
   assign B[22] = Y[22];
   assign B[23] = Y[23];
   assign B[24] = Y[24];
   assign B[25] = Y[25];
   assign B[26] = Y[26];
   assign B[27] = Y[27];
   assign B[28] = Y[28];
   assign B[29] = Y[29];
   assign B[30] = Y[30];
   assign B[31] = Y[31];
   assign P[0] = Q[0];
   assign P[1] = Q[1];
   assign P[2] = Q[2];
   assign P[3] = Q[3];
   assign P[4] = Q[4];
   assign P[5] = Q[5];
   assign P[6] = Q[6];
   assign P[7] = Q[7];
   assign P[8] = Q[8];
   assign P[9] = Q[9];
   assign P[10] = Q[10];
   assign P[11] = Q[11];
   assign P[12] = Q[12];
   assign P[13] = Q[13];
   assign P[14] = Q[14];
   assign P[15] = Q[15];
   assign P[16] = Q[16];
   assign P[17] = Q[17];
   assign P[18] = Q[18];
   assign P[19] = Q[19];
   assign P[20] = Q[20];
   assign P[21] = Q[21];
   assign P[22] = Q[22];
   assign P[23] = Q[23];
   assign P[24] = Q[24];
   assign P[25] = Q[25];
   assign P[26] = Q[26];
   assign P[27] = Q[27];
   assign P[28] = Q[28];
   assign P[29] = Q[29];
   assign P[30] = Q[30];
   assign P[31] = Q[31];
   assign P[32] = Q[32];
   assign P[33] = Q[33];
   assign P[34] = Q[34];
   assign P[35] = Q[35];
   assign P[36] = Q[36];
   assign P[37] = Q[37];
   assign P[38] = Q[38];
   assign P[39] = Q[39];
   assign P[40] = Q[40];
   assign P[41] = Q[41];
   assign P[42] = Q[42];
   assign P[43] = Q[43];
   assign P[44] = Q[44];
   assign P[45] = Q[45];
   assign P[46] = Q[46];
   assign P[47] = Q[47];
   assign P[48] = Q[48];
   assign P[49] = Q[49];
   assign P[50] = Q[50];
   assign P[51] = Q[51];
   assign P[52] = Q[52];
   assign P[53] = Q[53];
   assign P[54] = Q[54];
   assign P[55] = Q[55];
   assign P[56] = Q[56];
   assign P[57] = Q[57];
   assign P[58] = Q[58];
   assign P[59] = Q[59];
   assign P[60] = Q[60];
   assign P[61] = Q[61];
   assign P[62] = Q[62];
   assign P[63] = Q[63];
   MULTIPLIER_33_32 U1 (.MULTIPLICAND(A) , .MULTIPLIER(B) , .RST(RST), .CLK(CLK) , .PHI(1'b0) , .RESULT(Q) );
endmodule

`endif
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's VR, UPR and Configuration Registers                ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  According to OR1K architectural and OR1200 specifications.  ////
////                                                              ////
////  To Do:                                                      ////
////   - done                                                     ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_cfgr.v,v $
// Revision 1.4  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.3  2002/03/29 15:16:54  lampret
// Some of the warnings fixed.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.7  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.6  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.1  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:21  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_cfgr(
	// RISC Internal Interface
	spr_addr, spr_dat_o
);

//
// RISC Internal Interface
//
input	[31:0]	spr_addr;	// SPR Address
output	[31:0]	spr_dat_o;	// SPR Read Data

//
// Internal wires & registers
//
reg	[31:0]	spr_dat_o;	// SPR Read Data

`ifdef OR1200_CFGR_IMPLEMENTED

//
// Implementation of VR, UPR and configuration registers
//
always @(spr_addr)
`ifdef OR1200_SYS_FULL_DECODE
	if (~|spr_addr[31:4])
`endif
		case(spr_addr[3:0])		// synopsys parallel_case
			`OR1200_SPRGRP_SYS_VR: begin
				spr_dat_o[`OR1200_VR_REV_BITS] = `OR1200_VR_REV;
				spr_dat_o[`OR1200_VR_RES1_BITS] = `OR1200_VR_RES1;
				spr_dat_o[`OR1200_VR_CFG_BITS] = `OR1200_VR_CFG;
				spr_dat_o[`OR1200_VR_VER_BITS] = `OR1200_VR_VER;
			end
			`OR1200_SPRGRP_SYS_UPR: begin
				spr_dat_o[`OR1200_UPR_UP_BITS] = `OR1200_UPR_UP;
				spr_dat_o[`OR1200_UPR_DCP_BITS] = `OR1200_UPR_DCP;
				spr_dat_o[`OR1200_UPR_ICP_BITS] = `OR1200_UPR_ICP;
				spr_dat_o[`OR1200_UPR_DMP_BITS] = `OR1200_UPR_DMP;
				spr_dat_o[`OR1200_UPR_IMP_BITS] = `OR1200_UPR_IMP;
				spr_dat_o[`OR1200_UPR_MP_BITS] = `OR1200_UPR_MP;
				spr_dat_o[`OR1200_UPR_DUP_BITS] = `OR1200_UPR_DUP;
				spr_dat_o[`OR1200_UPR_PCUP_BITS] = `OR1200_UPR_PCUP;
				spr_dat_o[`OR1200_UPR_PMP_BITS] = `OR1200_UPR_PMP;
				spr_dat_o[`OR1200_UPR_PICP_BITS] = `OR1200_UPR_PICP;
				spr_dat_o[`OR1200_UPR_TTP_BITS] = `OR1200_UPR_TTP;
				spr_dat_o[`OR1200_UPR_RES1_BITS] = `OR1200_UPR_RES1;
				spr_dat_o[`OR1200_UPR_CUP_BITS] = `OR1200_UPR_CUP;
			end
			`OR1200_SPRGRP_SYS_CPUCFGR: begin
				spr_dat_o[`OR1200_CPUCFGR_NSGF_BITS] = `OR1200_CPUCFGR_NSGF;
				spr_dat_o[`OR1200_CPUCFGR_HGF_BITS] = `OR1200_CPUCFGR_HGF;
				spr_dat_o[`OR1200_CPUCFGR_OB32S_BITS] = `OR1200_CPUCFGR_OB32S;
				spr_dat_o[`OR1200_CPUCFGR_OB64S_BITS] = `OR1200_CPUCFGR_OB64S;
				spr_dat_o[`OR1200_CPUCFGR_OF32S_BITS] = `OR1200_CPUCFGR_OF32S;
				spr_dat_o[`OR1200_CPUCFGR_OF64S_BITS] = `OR1200_CPUCFGR_OF64S;
				spr_dat_o[`OR1200_CPUCFGR_OV64S_BITS] = `OR1200_CPUCFGR_OV64S;
				spr_dat_o[`OR1200_CPUCFGR_RES1_BITS] = `OR1200_CPUCFGR_RES1;
			end
			`OR1200_SPRGRP_SYS_DMMUCFGR: begin
				spr_dat_o[`OR1200_DMMUCFGR_NTW_BITS] = `OR1200_DMMUCFGR_NTW;
				spr_dat_o[`OR1200_DMMUCFGR_NTS_BITS] = `OR1200_DMMUCFGR_NTS;
				spr_dat_o[`OR1200_DMMUCFGR_NAE_BITS] = `OR1200_DMMUCFGR_NAE;
				spr_dat_o[`OR1200_DMMUCFGR_CRI_BITS] = `OR1200_DMMUCFGR_CRI;
				spr_dat_o[`OR1200_DMMUCFGR_PRI_BITS] = `OR1200_DMMUCFGR_PRI;
				spr_dat_o[`OR1200_DMMUCFGR_TEIRI_BITS] = `OR1200_DMMUCFGR_TEIRI;
				spr_dat_o[`OR1200_DMMUCFGR_HTR_BITS] = `OR1200_DMMUCFGR_HTR;
				spr_dat_o[`OR1200_DMMUCFGR_RES1_BITS] = `OR1200_DMMUCFGR_RES1;
			end
			`OR1200_SPRGRP_SYS_IMMUCFGR: begin
				spr_dat_o[`OR1200_IMMUCFGR_NTW_BITS] = `OR1200_IMMUCFGR_NTW;
				spr_dat_o[`OR1200_IMMUCFGR_NTS_BITS] = `OR1200_IMMUCFGR_NTS;
				spr_dat_o[`OR1200_IMMUCFGR_NAE_BITS] = `OR1200_IMMUCFGR_NAE;
				spr_dat_o[`OR1200_IMMUCFGR_CRI_BITS] = `OR1200_IMMUCFGR_CRI;
				spr_dat_o[`OR1200_IMMUCFGR_PRI_BITS] = `OR1200_IMMUCFGR_PRI;
				spr_dat_o[`OR1200_IMMUCFGR_TEIRI_BITS] = `OR1200_IMMUCFGR_TEIRI;
				spr_dat_o[`OR1200_IMMUCFGR_HTR_BITS] = `OR1200_IMMUCFGR_HTR;
				spr_dat_o[`OR1200_IMMUCFGR_RES1_BITS] = `OR1200_IMMUCFGR_RES1;
			end
			`OR1200_SPRGRP_SYS_DCCFGR: begin
				spr_dat_o[`OR1200_DCCFGR_NCW_BITS] = `OR1200_DCCFGR_NCW;
				spr_dat_o[`OR1200_DCCFGR_NCS_BITS] = `OR1200_DCCFGR_NCS;
				spr_dat_o[`OR1200_DCCFGR_CBS_BITS] = `OR1200_DCCFGR_CBS;
				spr_dat_o[`OR1200_DCCFGR_CWS_BITS] = `OR1200_DCCFGR_CWS;
				spr_dat_o[`OR1200_DCCFGR_CCRI_BITS] = `OR1200_DCCFGR_CCRI;
				spr_dat_o[`OR1200_DCCFGR_CBIRI_BITS] = `OR1200_DCCFGR_CBIRI;
				spr_dat_o[`OR1200_DCCFGR_CBPRI_BITS] = `OR1200_DCCFGR_CBPRI;
				spr_dat_o[`OR1200_DCCFGR_CBLRI_BITS] = `OR1200_DCCFGR_CBLRI;
				spr_dat_o[`OR1200_DCCFGR_CBFRI_BITS] = `OR1200_DCCFGR_CBFRI;
				spr_dat_o[`OR1200_DCCFGR_CBWBRI_BITS] = `OR1200_DCCFGR_CBWBRI;
				spr_dat_o[`OR1200_DCCFGR_RES1_BITS] = `OR1200_DCCFGR_RES1;
			end
			`OR1200_SPRGRP_SYS_ICCFGR: begin
				spr_dat_o[`OR1200_ICCFGR_NCW_BITS] = `OR1200_ICCFGR_NCW;
				spr_dat_o[`OR1200_ICCFGR_NCS_BITS] = `OR1200_ICCFGR_NCS;
				spr_dat_o[`OR1200_ICCFGR_CBS_BITS] = `OR1200_ICCFGR_CBS;
				spr_dat_o[`OR1200_ICCFGR_CWS_BITS] = `OR1200_ICCFGR_CWS;
				spr_dat_o[`OR1200_ICCFGR_CCRI_BITS] = `OR1200_ICCFGR_CCRI;
				spr_dat_o[`OR1200_ICCFGR_CBIRI_BITS] = `OR1200_ICCFGR_CBIRI;
				spr_dat_o[`OR1200_ICCFGR_CBPRI_BITS] = `OR1200_ICCFGR_CBPRI;
				spr_dat_o[`OR1200_ICCFGR_CBLRI_BITS] = `OR1200_ICCFGR_CBLRI;
				spr_dat_o[`OR1200_ICCFGR_CBFRI_BITS] = `OR1200_ICCFGR_CBFRI;
				spr_dat_o[`OR1200_ICCFGR_CBWBRI_BITS] = `OR1200_ICCFGR_CBWBRI;
				spr_dat_o[`OR1200_ICCFGR_RES1_BITS] = `OR1200_ICCFGR_RES1;
			end
			`OR1200_SPRGRP_SYS_DCFGR: begin
				spr_dat_o[`OR1200_DCFGR_NDP_BITS] = `OR1200_DCFGR_NDP;
				spr_dat_o[`OR1200_DCFGR_WPCI_BITS] = `OR1200_DCFGR_WPCI;
				spr_dat_o[`OR1200_DCFGR_RES1_BITS] = `OR1200_DCFGR_RES1;
			end
			default: spr_dat_o = 32'h0000_0000;
		endcase
`ifdef OR1200_SYS_FULL_DECODE
	else
		spr_dat_o = 32'h0000_0000;
`endif

`else

//
// When configuration registers are not implemented, only
// implement VR and UPR
//
always @(spr_addr)
`ifdef OR1200_SYS_FULL_DECODE
	if (spr_addr[31:4] == 28'h0)
`endif
		case(spr_addr[3:0])
			`OR1200_SPRGRP_SYS_VR: begin
				spr_dat_o[`OR1200_VR_REV_BITS] = `OR1200_VR_REV;
				spr_dat_o[`OR1200_VR_RES1_BITS] = `OR1200_VR_RES1;
				spr_dat_o[`OR1200_VR_CFG_BITS] = `OR1200_VR_CFG;
				spr_dat_o[`OR1200_VR_VER_BITS] = `OR1200_VR_VER;
			end
			`OR1200_SPRGRP_SYS_UPR: begin
				spr_dat_o[`OR1200_UPR_UP_BITS] = `OR1200_UPR_UP;
				spr_dat_o[`OR1200_UPR_DCP_BITS] = `OR1200_UPR_DCP;
				spr_dat_o[`OR1200_UPR_ICP_BITS] = `OR1200_UPR_ICP;
				spr_dat_o[`OR1200_UPR_DMP_BITS] = `OR1200_UPR_DMP;
				spr_dat_o[`OR1200_UPR_IMP_BITS] = `OR1200_UPR_IMP;
				spr_dat_o[`OR1200_UPR_MP_BITS] = `OR1200_UPR_MP;
				spr_dat_o[`OR1200_UPR_DUP_BITS] = `OR1200_UPR_DUP;
				spr_dat_o[`OR1200_UPR_PCUP_BITS] = `OR1200_UPR_PCUP;
				spr_dat_o[`OR1200_UPR_PMP_BITS] = `OR1200_UPR_PMP;
				spr_dat_o[`OR1200_UPR_PICP_BITS] = `OR1200_UPR_PICP;
				spr_dat_o[`OR1200_UPR_TTP_BITS] = `OR1200_UPR_TTP;
				spr_dat_o[`OR1200_UPR_RES1_BITS] = `OR1200_UPR_RES1;
				spr_dat_o[`OR1200_UPR_CUP_BITS] = `OR1200_UPR_CUP;
			end
			default: spr_dat_o = 32'h0000_0000;
		endcase
`ifdef OR1200_SYS_FULL_DECODE
	else
		spr_dat_o = 32'h0000_0000;
`endif

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's CPU                                                ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of internal CPU blocks. IFETCH, SPRS, FRZ,    ////
////  ALU, EXCEPT, ID, WBMUX, OPERANDMUX, RF etc.                 ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_cpu.v,v $
// Revision 1.16  2005/01/07 09:28:37  andreje
// flag for l.cmov instruction added
//
// Revision 1.15  2004/05/09 19:49:04  lampret
// Added some l.cust5 custom instructions as example
//
// Revision 1.14  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.12.4.2  2004/02/11 01:40:11  lampret
// preliminary HW breakpoints support in debug unit (by default disabled). To enable define OR1200_DU_HWBKPTS.
//
// Revision 1.12.4.1  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.12  2002/09/07 05:42:02  lampret
// Added optional SR[CY]. Added define to enable additional (compare) flag modifiers. Defines are OR1200_IMPL_ADDC and OR1200_ADDITIONAL_FLAG_MODIFIERS.
//
// Revision 1.11  2002/08/28 01:44:25  lampret
// Removed some commented RTL. Fixed SR/ESR flag bug.
//
// Revision 1.10  2002/07/14 22:17:17  lampret
// Added simple trace buffer [only for Xilinx Virtex target]. Fixed instruction fetch abort when new exception is recognized.
//
// Revision 1.9  2002/03/29 16:29:37  lampret
// Fixed some ports in instnatiations that were removed from the modules
//
// Revision 1.8  2002/03/29 15:16:54  lampret
// Some of the warnings fixed.
//
// Revision 1.7  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.6  2002/02/01 19:56:54  lampret
// Fixed combinational loops.
//
// Revision 1.5  2002/01/28 01:15:59  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.4  2002/01/18 14:21:43  lampret
// Fixed 'the NPC single-step fix'.
//
// Revision 1.3  2002/01/18 07:56:00  lampret
// No more low/high priority interrupts (PICPR removed). Added tick timer exception. Added exception prefix (SR[EPH]). Fixed single-step bug whenreading NPC.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.19  2001/11/30 18:59:47  simons
// *** empty log message ***
//
// Revision 1.18  2001/11/23 21:42:31  simons
// Program counter divided to PPC and NPC.
//
// Revision 1.17  2001/11/23 08:38:51  lampret
// Changed DSR/DRR behavior and exception detection.
//
// Revision 1.16  2001/11/20 00:57:22  lampret
// Fixed width of du_except.
//
// Revision 1.15  2001/11/18 09:58:28  lampret
// Fixed some l.trap typos.
//
// Revision 1.14  2001/11/18 08:36:28  lampret
// For GDB changed single stepping and disabled trap exception.
//
// Revision 1.13  2001/11/13 10:02:21  lampret
// Added 'setpc'. Renamed some signals (except_flushpipe into flushpipe etc)
//
// Revision 1.12  2001/11/12 01:45:40  lampret
// Moved flag bit into SR. Changed RF enable from constant enable to dynamic enable for read ports.
//
// Revision 1.11  2001/11/10 03:43:57  lampret
// Fixed exceptions.
//
// Revision 1.10  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.9  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.4  2001/08/17 08:01:19  lampret
// IC enable/disable.
//
// Revision 1.3  2001/08/13 03:36:20  lampret
// Added cfg regs. Moved all defines into one defines.v file. More cleanup.
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_cpu(
	// Clk & Rst
	clk, rst,

	// Insn interface
	ic_en,
	icpu_adr_o, icpu_cycstb_o, icpu_sel_o, icpu_tag_o,
	icpu_dat_i, icpu_ack_i, icpu_rty_i, icpu_err_i, icpu_adr_i, icpu_tag_i,
	immu_en,

	// Debug unit
	ex_insn, ex_freeze, id_pc, branch_op,
	spr_dat_npc, rf_dataw,
	du_stall, du_addr, du_dat_du, du_read, du_write, du_dsr, du_hwbkpt,
	du_except, du_dat_cpu,
	
	// Data interface
	dc_en,
	dcpu_adr_o, dcpu_cycstb_o, dcpu_we_o, dcpu_sel_o, dcpu_tag_o, dcpu_dat_o,
	dcpu_dat_i, dcpu_ack_i, dcpu_rty_i, dcpu_err_i, dcpu_tag_i,
	dmmu_en,

    // SR Interface
    boot_adr_sel_i,

	// Interrupt & tick exceptions
	sig_int, sig_tick,

	// SPR interface
	supv, spr_addr, spr_dat_cpu, spr_dat_pic, spr_dat_tt, spr_dat_pm,
	spr_dat_dmmu, spr_dat_immu, spr_dat_du, spr_cs, spr_we
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_REGFILE_ADDR_WIDTH;

//
// I/O ports
//

//
// Clk & Rst
//
input 				clk;
input 				rst;

//
// Insn (IC) interface
//
output				ic_en;
output	[31:0]			icpu_adr_o;
output				icpu_cycstb_o;
output	[3:0]			icpu_sel_o;
output	[3:0]			icpu_tag_o;
input	[31:0]			icpu_dat_i;
input				icpu_ack_i;
input				icpu_rty_i;
input				icpu_err_i;
input	[31:0]			icpu_adr_i;
input	[3:0]			icpu_tag_i;

//
// Insn (IMMU) interface
//
output				immu_en;

//
// Debug interface
//
output	[31:0]			ex_insn;
output				ex_freeze;
output	[31:0]			id_pc;
output	[`OR1200_BRANCHOP_WIDTH-1:0]	branch_op;

input				du_stall;
input	[dw-1:0]		du_addr;
input	[dw-1:0]		du_dat_du;
input				du_read;
input				du_write;
input	[`OR1200_DU_DSR_WIDTH-1:0]	du_dsr;
input				du_hwbkpt;
output	[12:0]			du_except;
output	[dw-1:0]		du_dat_cpu;
output	[dw-1:0]		rf_dataw;

//
// Data (DC) interface
//
output	[31:0]			dcpu_adr_o;
output				dcpu_cycstb_o;
output				dcpu_we_o;
output	[3:0]			dcpu_sel_o;
output	[3:0]			dcpu_tag_o;
output	[31:0]			dcpu_dat_o;
input	[31:0]			dcpu_dat_i;
input				dcpu_ack_i;
input				dcpu_rty_i;
input				dcpu_err_i;
input	[3:0]			dcpu_tag_i;
output				dc_en;

//
// Data (DMMU) interface
//
output				dmmu_en;

//
// SR Interface 
//
input			    boot_adr_sel_i;

//
// SPR interface
//
output				supv;
input	[dw-1:0]		spr_dat_pic;
input	[dw-1:0]		spr_dat_tt;
input	[dw-1:0]		spr_dat_pm;
input	[dw-1:0]		spr_dat_dmmu;
input	[dw-1:0]		spr_dat_immu;
input	[dw-1:0]		spr_dat_du;
output	[dw-1:0]		spr_addr;
output	[dw-1:0]		spr_dat_cpu;
output	[dw-1:0]		spr_dat_npc;
output	[31:0]			spr_cs;
output				spr_we;

//
// Interrupt exceptions
//
input				sig_int;
input				sig_tick;

//
// Internal wires
//
wire	[31:0]			if_insn;
wire	[31:0]			if_pc;
wire	[31:2]			lr_sav;
wire	[aw-1:0]		rf_addrw;
wire	[aw-1:0] 		rf_addra;
wire	[aw-1:0] 		rf_addrb;
wire				rf_rda;
wire				rf_rdb;
wire	[dw-1:0]		simm;
wire	[dw-1:2]		branch_addrofs;
wire	[`OR1200_ALUOP_WIDTH-1:0]	alu_op;
wire	[`OR1200_SHROTOP_WIDTH-1:0]	shrot_op;
wire	[`OR1200_COMPOP_WIDTH-1:0]	comp_op;
wire	[`OR1200_BRANCHOP_WIDTH-1:0]	pre_branch_op;
wire	[`OR1200_BRANCHOP_WIDTH-1:0]	branch_op;
wire	[`OR1200_LSUOP_WIDTH-1:0]	lsu_op;
wire				genpc_freeze;
wire				if_freeze;
wire				id_freeze;
wire				ex_freeze;
wire				wb_freeze;
wire	[`OR1200_SEL_WIDTH-1:0]	sel_a;
wire	[`OR1200_SEL_WIDTH-1:0]	sel_b;
wire	[`OR1200_RFWBOP_WIDTH-1:0]	rfwb_op;
wire	[dw-1:0]		rf_dataw;
wire	[dw-1:0]		rf_dataa;
wire	[dw-1:0]		rf_datab;
wire	[dw-1:0]		muxed_b;
wire	[dw-1:0]		wb_forw;
wire				wbforw_valid;
wire	[dw-1:0]		operand_a;
wire	[dw-1:0]		operand_b;
wire	[dw-1:0]		alu_dataout;
wire	[dw-1:0]		lsu_dataout;
wire	[dw-1:0]		sprs_dataout;
wire	[31:0]			lsu_addrofs;
wire	[`OR1200_MULTICYCLE_WIDTH-1:0]	multicycle;
wire	[`OR1200_EXCEPT_WIDTH-1:0]	except_type;
wire	[4:0]			cust5_op;
wire	[5:0]			cust5_limm;
wire				flushpipe;
wire				extend_flush;
wire				branch_taken;
wire				flag;
wire				flagforw;
wire				flag_we;
wire				carry;
wire				cyforw;
wire				cy_we_alu;
wire				cy_we_rf;
wire				lsu_stall;
wire				epcr_we;
wire				eear_we;
wire				esr_we;
wire				pc_we;
wire	[31:0]			epcr;
wire	[31:0]			eear;
wire	[`OR1200_SR_WIDTH-1:0]	esr;
wire				sr_we;
wire	[`OR1200_SR_WIDTH-1:0]	to_sr;
wire	[`OR1200_SR_WIDTH-1:0]	sr;
wire				except_start;
wire				except_started;
wire	[31:0]			wb_insn;
wire	[15:0]			spr_addrimm;
wire				sig_syscall;
wire				sig_trap;
wire	[31:0]			spr_dat_cfgr;
wire	[31:0]			spr_dat_rf;
wire    [31:0]                  spr_dat_npc;
wire	[31:0]			spr_dat_ppc;
wire	[31:0]			spr_dat_mac;
wire				force_dslot_fetch;
wire				no_more_dslot;
wire				ex_void;
wire				if_stall;
wire				id_macrc_op;
wire				ex_macrc_op;
wire	[`OR1200_MACOP_WIDTH-1:0] mac_op;
wire	[31:0]			mult_mac_result;
wire				mac_stall;
wire	[12:0]			except_stop;
wire				genpc_refetch;
wire				rfe;
wire				lsu_unstall;
wire				except_align;
wire				except_dtlbmiss;
wire				except_dmmufault;
wire				except_illegal;
wire				except_itlbmiss;
wire				except_immufault;
wire				except_ibuserr;
wire				except_dbuserr;
wire				abort_ex;

//
// Send exceptions to Debug Unit
//
assign du_except = except_stop;

//
// Data cache enable
//
assign dc_en = sr[`OR1200_SR_DCE];

//
// Instruction cache enable
//
assign ic_en = sr[`OR1200_SR_ICE];

//
// DMMU enable
//
assign dmmu_en = sr[`OR1200_SR_DME];

//
// IMMU enable
//
assign immu_en = sr[`OR1200_SR_IME];

//
// SUPV bit
//
assign supv = sr[`OR1200_SR_SM];

//
// Instantiation of instruction fetch block
//
or1200_genpc or1200_genpc(
	.clk(clk),
	.rst(rst),
	.icpu_adr_o(icpu_adr_o),
	.icpu_cycstb_o(icpu_cycstb_o),
	.icpu_sel_o(icpu_sel_o),
	.icpu_tag_o(icpu_tag_o),
	.icpu_rty_i(icpu_rty_i),
	.icpu_adr_i(icpu_adr_i),

	.pre_branch_op(pre_branch_op),
	.branch_op(branch_op),
	.except_type(except_type),
	.except_start(except_start),
	.except_prefix(sr[`OR1200_SR_EPH]),
	.branch_addrofs(branch_addrofs),
	.lr_restor(operand_b),
	.flag(flag),
	.taken(branch_taken),
	.binsn_addr(lr_sav),
	.epcr(epcr),
	.spr_dat_i(spr_dat_cpu),
	.spr_pc_we(pc_we),
	.genpc_refetch(genpc_refetch),
	.genpc_freeze(genpc_freeze),
  .genpc_stop_prefetch(1'b0),
	.no_more_dslot(no_more_dslot)
);

//
// Instantiation of instruction fetch block
//
or1200_if or1200_if(
	.clk(clk),
	.rst(rst),
	.icpu_dat_i(icpu_dat_i),
	.icpu_ack_i(icpu_ack_i),
	.icpu_err_i(icpu_err_i),
	.icpu_adr_i(icpu_adr_i),
	.icpu_tag_i(icpu_tag_i),

	.if_freeze(if_freeze),
	.if_insn(if_insn),
	.if_pc(if_pc),
	.flushpipe(flushpipe),
	.if_stall(if_stall),
	.no_more_dslot(no_more_dslot),
	.genpc_refetch(genpc_refetch),
	.rfe(rfe),
	.except_itlbmiss(except_itlbmiss),
	.except_immufault(except_immufault),
	.except_ibuserr(except_ibuserr)
);

//
// Instantiation of instruction decode/control logic
//
or1200_ctrl or1200_ctrl(
	.clk(clk),
	.rst(rst),
	.id_freeze(id_freeze),
	.ex_freeze(ex_freeze),
	.wb_freeze(wb_freeze),
	.flushpipe(flushpipe),
	.if_insn(if_insn),
	.ex_insn(ex_insn),
	.pre_branch_op(pre_branch_op),
	.branch_op(branch_op),
	.branch_taken(branch_taken),
	.rf_addra(rf_addra),
	.rf_addrb(rf_addrb),
	.rf_rda(rf_rda),
	.rf_rdb(rf_rdb),
	.alu_op(alu_op),
	.mac_op(mac_op),
	.shrot_op(shrot_op),
	.comp_op(comp_op),
	.rf_addrw(rf_addrw),
	.rfwb_op(rfwb_op),
	.wb_insn(wb_insn),
	.simm(simm),
	.branch_addrofs(branch_addrofs),
	.lsu_addrofs(lsu_addrofs),
	.sel_a(sel_a),
	.sel_b(sel_b),
	.lsu_op(lsu_op),
	.cust5_op(cust5_op),
	.cust5_limm(cust5_limm),
	.multicycle(multicycle),
	.spr_addrimm(spr_addrimm),
	.wbforw_valid(wbforw_valid),
	.sig_syscall(sig_syscall),
	.sig_trap(sig_trap),
	.force_dslot_fetch(force_dslot_fetch),
	.no_more_dslot(no_more_dslot),
	.ex_void(ex_void),
	.id_macrc_op(id_macrc_op),
	.ex_macrc_op(ex_macrc_op),
	.rfe(rfe),
	.du_hwbkpt(du_hwbkpt),
	.except_illegal(except_illegal)
);

//
// Instantiation of register file
//
or1200_rf or1200_rf(
	.clk(clk),
	.rst(rst),
	.cy_we_i(cy_we_alu),
	.cy_we_o(cy_we_rf),
	.supv(sr[`OR1200_SR_SM]),
	.wb_freeze(wb_freeze),
	.addrw(rf_addrw),
	.dataw(rf_dataw),
	.id_freeze(id_freeze),
	.we(rfwb_op[0]),
	.flushpipe(flushpipe),
	.addra(rf_addra),
	.rda(rf_rda),
	.dataa(rf_dataa),
	.addrb(rf_addrb),
	.rdb(rf_rdb),
	.datab(rf_datab),
	.spr_cs(spr_cs[`OR1200_SPR_GROUP_SYS]),
	.spr_write(spr_we),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_cpu),
	.spr_dat_o(spr_dat_rf)
);

//
// Instantiation of operand muxes
//
or1200_operandmuxes or1200_operandmuxes(
	.clk(clk),
	.rst(rst),
	.id_freeze(id_freeze),
	.ex_freeze(ex_freeze),
	.rf_dataa(rf_dataa),
	.rf_datab(rf_datab),
	.ex_forw(rf_dataw),
	.wb_forw(wb_forw),
	.simm(simm),
	.sel_a(sel_a),
	.sel_b(sel_b),
	.operand_a(operand_a),
	.operand_b(operand_b),
	.muxed_b(muxed_b)
);

//
// Instantiation of CPU's ALU
//
or1200_alu or1200_alu(
	.a(operand_a),
	.b(operand_b),
	.mult_mac_result(mult_mac_result),
	.macrc_op(ex_macrc_op),
	.alu_op(alu_op),
	.shrot_op(shrot_op),
	.comp_op(comp_op),
	.cust5_op(cust5_op),
	.cust5_limm(cust5_limm),
	.result(alu_dataout),
	.flagforw(flagforw),
	.flag_we(flag_we),
	.cyforw(cyforw),
	.cy_we(cy_we_alu),
  .flag(flag),
	.carry(carry)
);

//
// Instantiation of CPU's ALU
//
or1200_mult_mac or1200_mult_mac(
	.clk(clk),
	.rst(rst),
	.ex_freeze(ex_freeze),
	.id_macrc_op(id_macrc_op),
	.macrc_op(ex_macrc_op),
	.a(operand_a),
	.b(operand_b),
	.mac_op(mac_op),
	.alu_op(alu_op),
	.result(mult_mac_result),
	.mac_stall_r(mac_stall),
	.spr_cs(spr_cs[`OR1200_SPR_GROUP_MAC]),
	.spr_write(spr_we),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_cpu),
	.spr_dat_o(spr_dat_mac)
);

//
// Instantiation of CPU's SPRS block
//
or1200_sprs or1200_sprs(
	.clk(clk),
	.rst(rst),
	.addrbase(operand_a),
	.addrofs(spr_addrimm),
	.dat_i(operand_b),
	.alu_op(alu_op),
	.flagforw(flagforw),
	.flag_we(flag_we),
	.flag(flag),
	.cyforw(cyforw),
	.cy_we(cy_we_rf),
	.carry(carry),
	.to_wbmux(sprs_dataout),

	.du_addr(du_addr),
	.du_dat_du(du_dat_du),
	.du_read(du_read),
	.du_write(du_write),
	.du_dat_cpu(du_dat_cpu),

    .boot_adr_sel_i(boot_adr_sel_i),
	.spr_addr(spr_addr),
	.spr_dat_pic(spr_dat_pic),
	.spr_dat_tt(spr_dat_tt),
	.spr_dat_pm(spr_dat_pm),
	.spr_dat_cfgr(spr_dat_cfgr),
	.spr_dat_rf(spr_dat_rf),
	.spr_dat_npc(spr_dat_npc),
        .spr_dat_ppc(spr_dat_ppc),
	.spr_dat_mac(spr_dat_mac),
	.spr_dat_dmmu(spr_dat_dmmu),
	.spr_dat_immu(spr_dat_immu),
	.spr_dat_du(spr_dat_du),
	.spr_dat_o(spr_dat_cpu),
	.spr_cs(spr_cs),
	.spr_we(spr_we),

	.epcr_we(epcr_we),
	.eear_we(eear_we),
	.esr_we(esr_we),
	.pc_we(pc_we),
	.epcr(epcr),
	.eear(eear),
	.esr(esr),
	.except_started(except_started),

	.sr_we(sr_we),
	.to_sr(to_sr),
	.sr(sr),
	.branch_op(branch_op)
);

//
// Instantiation of load/store unit
//
or1200_lsu or1200_lsu(
	.addrbase(operand_a),
	.addrofs(lsu_addrofs),
	.lsu_op(lsu_op),
	.lsu_datain(operand_b),
	.lsu_dataout(lsu_dataout),
	.lsu_stall(lsu_stall),
	.lsu_unstall(lsu_unstall),
        .du_stall(du_stall),
	.except_align(except_align),
	.except_dtlbmiss(except_dtlbmiss),
	.except_dmmufault(except_dmmufault),
	.except_dbuserr(except_dbuserr),

	.dcpu_adr_o(dcpu_adr_o),
	.dcpu_cycstb_o(dcpu_cycstb_o),
	.dcpu_we_o(dcpu_we_o),
	.dcpu_sel_o(dcpu_sel_o),
	.dcpu_tag_o(dcpu_tag_o),
	.dcpu_dat_o(dcpu_dat_o),
	.dcpu_dat_i(dcpu_dat_i),
	.dcpu_ack_i(dcpu_ack_i),
	.dcpu_rty_i(dcpu_rty_i),
	.dcpu_err_i(dcpu_err_i),
	.dcpu_tag_i(dcpu_tag_i)
);

//
// Instantiation of write-back muxes
//
or1200_wbmux or1200_wbmux(
	.clk(clk),
	.rst(rst),
	.wb_freeze(wb_freeze),
	.rfwb_op(rfwb_op),
	.muxin_a(alu_dataout),
	.muxin_b(lsu_dataout),
	.muxin_c(sprs_dataout),
	.muxin_d({lr_sav, 2'b0}),
	.muxout(rf_dataw),
	.muxreg(wb_forw),
	.muxreg_valid(wbforw_valid)
);

//
// Instantiation of freeze logic
//
or1200_freeze or1200_freeze(
	.clk(clk),
	.rst(rst),
	.multicycle(multicycle),
	.flushpipe(flushpipe),
	.extend_flush(extend_flush),
	.lsu_stall(lsu_stall),
	.if_stall(if_stall),
	.lsu_unstall(lsu_unstall),
	.force_dslot_fetch(force_dslot_fetch),
	.abort_ex(abort_ex),
	.du_stall(du_stall),
	.mac_stall(mac_stall),
	.genpc_freeze(genpc_freeze),
	.if_freeze(if_freeze),
	.id_freeze(id_freeze),
	.ex_freeze(ex_freeze),
	.wb_freeze(wb_freeze),
	.icpu_ack_i(icpu_ack_i),
	.icpu_err_i(icpu_err_i)
);

//
// Instantiation of exception block
//
or1200_except or1200_except(
	.clk(clk),
	.rst(rst),
	.sig_ibuserr(except_ibuserr),
	.sig_dbuserr(except_dbuserr),
	.sig_illegal(except_illegal),
	.sig_align(except_align),
	.sig_range(1'b0),
	.sig_dtlbmiss(except_dtlbmiss),
	.sig_dmmufault(except_dmmufault),
	.sig_int(sig_int),
	.sig_syscall(sig_syscall),
	.sig_trap(sig_trap),
	.sig_itlbmiss(except_itlbmiss),
	.sig_immufault(except_immufault),
	.sig_tick(sig_tick),
	.branch_taken(branch_taken),
	.icpu_ack_i(icpu_ack_i),
	.icpu_err_i(icpu_err_i),
	.dcpu_ack_i(dcpu_ack_i),
	.dcpu_err_i(dcpu_err_i),
	.genpc_freeze(genpc_freeze),
        .id_freeze(id_freeze),
        .ex_freeze(ex_freeze),
        .wb_freeze(wb_freeze),
	.if_stall(if_stall),
	.if_pc(if_pc),
	.id_pc(id_pc),
	.lr_sav(lr_sav),
	.flushpipe(flushpipe),
	.extend_flush(extend_flush),
	.except_type(except_type),
	.except_start(except_start),
	.except_started(except_started),
	.except_stop(except_stop),
	.ex_void(ex_void),
	.spr_dat_ppc(spr_dat_ppc),
	.spr_dat_npc(spr_dat_npc),

	.datain(operand_b),
	.du_dsr(du_dsr),
	.epcr_we(epcr_we),
	.eear_we(eear_we),
	.esr_we(esr_we),
	.pc_we(pc_we),
        .epcr(epcr),
	.eear(eear),
	.esr(esr),

	.lsu_addr(dcpu_adr_o),
	.sr_we(sr_we),
	.to_sr(to_sr),
	.sr(sr),
	.abort_ex(abort_ex)
);

//
// Instantiation of configuration registers
//
or1200_cfgr or1200_cfgr(
	.spr_addr(spr_addr),
	.spr_dat_o(spr_dat_cfgr)
);

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Instruction decode                                 ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Majority of instruction decoding is performed here.         ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_ctrl.v,v $
// Revision 1.13  2005/01/13 11:03:43  phoenix
// revert to the old l.sfxxi behavior
//
// Revision 1.12  2005/01/07 09:31:07  andreje
// sign/zero extension for l.sfxxi instructions corrected
//
// Revision 1.11  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.10  2004/05/09 19:49:04  lampret
// Added some l.cust5 custom instructions as example
//
// Revision 1.9  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.8.4.1  2004/02/11 01:40:11  lampret
// preliminary HW breakpoints support in debug unit (by default disabled). To enable define OR1200_DU_HWBKPTS.
//
// Revision 1.8  2003/04/24 00:16:07  lampret
// No functional changes. Added defines to disable implementation of multiplier/MAC
//
// Revision 1.7  2002/09/07 05:42:02  lampret
// Added optional SR[CY]. Added define to enable additional (compare) flag modifiers. Defines are OR1200_IMPL_ADDC and OR1200_ADDITIONAL_FLAG_MODIFIERS.
//
// Revision 1.6  2002/03/29 15:16:54  lampret
// Some of the warnings fixed.
//
// Revision 1.5  2002/02/01 19:56:54  lampret
// Fixed combinational loops.
//
// Revision 1.4  2002/01/28 01:15:59  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.3  2002/01/18 14:21:43  lampret
// Fixed 'the NPC single-step fix'.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.14  2001/11/30 18:59:17  simons
// force_dslot_fetch does not work -  allways zero.
//
// Revision 1.13  2001/11/20 18:46:15  simons
// Break point bug fixed
//
// Revision 1.12  2001/11/18 08:36:28  lampret
// For GDB changed single stepping and disabled trap exception.
//
// Revision 1.11  2001/11/13 10:02:21  lampret
// Added 'setpc'. Renamed some signals (except_flushpipe into flushpipe etc)
//
// Revision 1.10  2001/11/12 01:45:40  lampret
// Moved flag bit into SR. Changed RF enable from constant enable to dynamic enable for read ports.
//
// Revision 1.9  2001/11/10 03:43:57  lampret
// Fixed exceptions.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/13 03:36:20  lampret
// Added cfg regs. Moved all defines into one defines.v file. More cleanup.
//
// Revision 1.1  2001/08/09 13:39:33  lampret
// Major clean-up.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_ctrl(
	// Clock and reset
	clk, rst,

	// Internal i/f
	id_freeze, ex_freeze, wb_freeze, flushpipe, if_insn, ex_insn, pre_branch_op, branch_op, branch_taken,
	rf_addra, rf_addrb, rf_rda, rf_rdb, alu_op, mac_op, shrot_op, comp_op, rf_addrw, rfwb_op,
	wb_insn, simm, branch_addrofs, lsu_addrofs, sel_a, sel_b, lsu_op,
	cust5_op, cust5_limm,
	multicycle, spr_addrimm, wbforw_valid, du_hwbkpt, sig_syscall, sig_trap,
	force_dslot_fetch, no_more_dslot, ex_void, id_macrc_op, ex_macrc_op, rfe, except_illegal
);

//
// I/O
//
input					clk;
input					rst;
input					id_freeze;
input					ex_freeze;
input					wb_freeze;
input					flushpipe;
input	[31:0]				if_insn;
output	[31:0]				ex_insn;
output	[`OR1200_BRANCHOP_WIDTH-1:0]		pre_branch_op;
output	[`OR1200_BRANCHOP_WIDTH-1:0]		branch_op;
input						branch_taken;
output	[`OR1200_REGFILE_ADDR_WIDTH-1:0]	rf_addrw;
output	[`OR1200_REGFILE_ADDR_WIDTH-1:0]	rf_addra;
output	[`OR1200_REGFILE_ADDR_WIDTH-1:0]	rf_addrb;
output					rf_rda;
output					rf_rdb;
output	[`OR1200_ALUOP_WIDTH-1:0]		alu_op;
output	[`OR1200_MACOP_WIDTH-1:0]		mac_op;
output	[`OR1200_SHROTOP_WIDTH-1:0]		shrot_op;
output	[`OR1200_RFWBOP_WIDTH-1:0]		rfwb_op;
output	[31:0]				wb_insn;
output	[31:0]				simm;
output	[31:2]				branch_addrofs;
output	[31:0]				lsu_addrofs;
output	[`OR1200_SEL_WIDTH-1:0]		sel_a;
output	[`OR1200_SEL_WIDTH-1:0]		sel_b;
output	[`OR1200_LSUOP_WIDTH-1:0]		lsu_op;
output	[`OR1200_COMPOP_WIDTH-1:0]		comp_op;
output	[`OR1200_MULTICYCLE_WIDTH-1:0]		multicycle;
output	[4:0]				cust5_op;
output	[5:0]				cust5_limm;
output	[15:0]				spr_addrimm;
input					wbforw_valid;
input					du_hwbkpt;
output					sig_syscall;
output					sig_trap;
output					force_dslot_fetch;
output					no_more_dslot;
output					ex_void;
output					id_macrc_op;
output					ex_macrc_op;
output					rfe;
output					except_illegal;

//
// Internal wires and regs
//
reg	[`OR1200_BRANCHOP_WIDTH-1:0]		pre_branch_op;
reg	[`OR1200_BRANCHOP_WIDTH-1:0]		branch_op;
reg	[`OR1200_ALUOP_WIDTH-1:0]		alu_op;
`ifdef OR1200_MAC_IMPLEMENTED
reg	[`OR1200_MACOP_WIDTH-1:0]		mac_op;
reg					ex_macrc_op;
`else
wire	[`OR1200_MACOP_WIDTH-1:0]		mac_op;
wire					ex_macrc_op;
`endif
reg	[`OR1200_SHROTOP_WIDTH-1:0]		shrot_op;
reg	[31:0]				id_insn;
reg	[31:0]				ex_insn;
reg	[31:0]				wb_insn;
reg	[`OR1200_REGFILE_ADDR_WIDTH-1:0]	rf_addrw;
reg	[`OR1200_REGFILE_ADDR_WIDTH-1:0]	wb_rfaddrw;
reg	[`OR1200_RFWBOP_WIDTH-1:0]		rfwb_op;
reg	[31:0]				lsu_addrofs;
reg	[`OR1200_SEL_WIDTH-1:0]		sel_a;
reg	[`OR1200_SEL_WIDTH-1:0]		sel_b;
reg					sel_imm;
reg	[`OR1200_LSUOP_WIDTH-1:0]		lsu_op;
reg	[`OR1200_COMPOP_WIDTH-1:0]		comp_op;
reg	[`OR1200_MULTICYCLE_WIDTH-1:0]		multicycle;
reg					imm_signextend;
reg	[15:0]				spr_addrimm;
reg					sig_syscall;
reg					sig_trap;
reg					except_illegal;
wire					id_void;

//
// Register file read addresses
//
assign rf_addra = if_insn[20:16];
assign rf_addrb = if_insn[15:11];
assign rf_rda = if_insn[31];
assign rf_rdb = if_insn[30];

//
// Force fetch of delay slot instruction when jump/branch is preceeded by load/store
// instructions
//
// SIMON
// assign force_dslot_fetch = ((|pre_branch_op) & (|lsu_op));
assign force_dslot_fetch = 1'b0;
assign no_more_dslot = |branch_op & !id_void & branch_taken | (branch_op == `OR1200_BRANCHOP_RFE);
assign id_void = (id_insn[31:26] == `OR1200_OR32_NOP) & id_insn[16];
assign ex_void = (ex_insn[31:26] == `OR1200_OR32_NOP) & ex_insn[16];

//
// Sign/Zero extension of immediates
//
assign simm = (imm_signextend == 1'b1) ? {{16{id_insn[15]}}, id_insn[15:0]} : {{16'b0}, id_insn[15:0]};

//
// Sign extension of branch offset
//
assign branch_addrofs = {{4{ex_insn[25]}}, ex_insn[25:0]};

//
// l.macrc in ID stage
//
`ifdef OR1200_MAC_IMPLEMENTED
assign id_macrc_op = (id_insn[31:26] == `OR1200_OR32_MOVHI) & id_insn[16];
`else
assign id_macrc_op = 1'b0;
`endif

//
// cust5_op, cust5_limm (L immediate)
//
assign cust5_op = ex_insn[4:0];
assign cust5_limm = ex_insn[10:5];

//
//
//
assign rfe = (pre_branch_op == `OR1200_BRANCHOP_RFE) | (branch_op == `OR1200_BRANCHOP_RFE);

//
// Generation of sel_a
//
always @(rf_addrw or id_insn or rfwb_op or wbforw_valid or wb_rfaddrw)
	if ((id_insn[20:16] == rf_addrw) && rfwb_op[0])
		sel_a = `OR1200_SEL_EX_FORW;
	else if ((id_insn[20:16] == wb_rfaddrw) && wbforw_valid)
		sel_a = `OR1200_SEL_WB_FORW;
	else
		sel_a = `OR1200_SEL_RF;

//
// Generation of sel_b
//
always @(rf_addrw or sel_imm or id_insn or rfwb_op or wbforw_valid or wb_rfaddrw)
	if (sel_imm)
		sel_b = `OR1200_SEL_IMM;
	else if ((id_insn[15:11] == rf_addrw) && rfwb_op[0])
		sel_b = `OR1200_SEL_EX_FORW;
	else if ((id_insn[15:11] == wb_rfaddrw) && wbforw_valid)
		sel_b = `OR1200_SEL_WB_FORW;
	else
		sel_b = `OR1200_SEL_RF;

//
// l.macrc in EX stage
//
`ifdef OR1200_MAC_IMPLEMENTED
always @(posedge clk or posedge rst) begin
	if (rst)
		ex_macrc_op <= #1 1'b0;
	else if (!ex_freeze & id_freeze | flushpipe)
		ex_macrc_op <= #1 1'b0;
	else if (!ex_freeze)
		ex_macrc_op <= #1 id_macrc_op;
end
`else
assign ex_macrc_op = 1'b0;
`endif

//
// Decode of spr_addrimm
//
always @(posedge clk or posedge rst) begin
	if (rst)
		spr_addrimm <= #1 16'h0000;
	else if (!ex_freeze & id_freeze | flushpipe)
		spr_addrimm <= #1 16'h0000;
	else if (!ex_freeze) begin
		case (id_insn[31:26])	// synopsys parallel_case
			// l.mfspr
			`OR1200_OR32_MFSPR: 
				spr_addrimm <= #1 id_insn[15:0];
			// l.mtspr
			default:
				spr_addrimm <= #1 {id_insn[25:21], id_insn[10:0]};
		endcase
	end
end

//
// Decode of multicycle
//
always @(id_insn) begin
  case (id_insn[31:26])		// synopsys parallel_case
`ifdef UNUSED
    // l.lwz
    `OR1200_OR32_LWZ:
      multicycle = `OR1200_TWO_CYCLES;
    
    // l.lbz
    `OR1200_OR32_LBZ:
      multicycle = `OR1200_TWO_CYCLES;
    
    // l.lbs
    `OR1200_OR32_LBS:
      multicycle = `OR1200_TWO_CYCLES;
    
    // l.lhz
    `OR1200_OR32_LHZ:
      multicycle = `OR1200_TWO_CYCLES;
    
    // l.lhs
    `OR1200_OR32_LHS:
      multicycle = `OR1200_TWO_CYCLES;
    
    // l.sw
    `OR1200_OR32_SW:
      multicycle = `OR1200_TWO_CYCLES;
    
    // l.sb
    `OR1200_OR32_SB:
      multicycle = `OR1200_TWO_CYCLES;
    
    // l.sh
    `OR1200_OR32_SH:
      multicycle = `OR1200_TWO_CYCLES;
`endif    
    // ALU instructions except the one with immediate
    `OR1200_OR32_ALU:
      multicycle = id_insn[`OR1200_ALUMCYC_POS];
    
    `OR1200_OR32_MULI:
      multicycle = 2'h3;
    
    // Single cycle instructions
    default: begin
      multicycle = `OR1200_ONE_CYCLE;
    end
    
  endcase
  
end

//
// Decode of imm_signextend
//
always @(id_insn) begin
  case (id_insn[31:26])		// synopsys parallel_case

	// l.addi
	`OR1200_OR32_ADDI:
		imm_signextend = 1'b1;

	// l.addic
	`OR1200_OR32_ADDIC:
		imm_signextend = 1'b1;

	// l.xori
	`OR1200_OR32_XORI:
		imm_signextend = 1'b1;

	// l.muli
`ifdef OR1200_MULT_IMPLEMENTED
	`OR1200_OR32_MULI:
		imm_signextend = 1'b1;
`endif

	// l.maci
`ifdef OR1200_MAC_IMPLEMENTED
	`OR1200_OR32_MACI:
		imm_signextend = 1'b1;
`endif

	// SFXX insns with immediate
	`OR1200_OR32_SFXXI:
		imm_signextend = 1'b1;

	// Instructions with no or zero extended immediate
	default: begin
		imm_signextend = 1'b0;
	end

endcase

end

//
// LSU addr offset
//
always @(lsu_op or ex_insn) begin
	lsu_addrofs[10:0] = ex_insn[10:0];
	case(lsu_op)	// synopsys parallel_case
		`OR1200_LSUOP_SW, `OR1200_LSUOP_SH, `OR1200_LSUOP_SB : 
			lsu_addrofs[31:11] = {{16{ex_insn[25]}}, ex_insn[25:21]};
		default : 
			lsu_addrofs[31:11] = {{16{ex_insn[15]}}, ex_insn[15:11]};
	endcase
end

//
// Register file write address
//
always @(posedge clk or posedge rst) begin
	if (rst)
		rf_addrw <= #1 5'd0;
	else if (!ex_freeze & id_freeze)
		rf_addrw <= #1 5'd00;
	else if (!ex_freeze)
		case (pre_branch_op)	// synopsys parallel_case
			`OR1200_BRANCHOP_JR, `OR1200_BRANCHOP_BAL:
				rf_addrw <= #1 5'd09;	// link register r9
			default:
				rf_addrw <= #1 id_insn[25:21];
		endcase
end

//
// rf_addrw in wb stage (used in forwarding logic)
//
always @(posedge clk or posedge rst) begin
	if (rst)
		wb_rfaddrw <= #1 5'd0;
	else if (!wb_freeze)
		wb_rfaddrw <= #1 rf_addrw;
end

//
// Instruction latch in id_insn
//
always @(posedge clk or posedge rst) begin
	if (rst)
		id_insn <= #1 {`OR1200_OR32_NOP, 26'h041_0000};
        else if (flushpipe)
                id_insn <= #1 {`OR1200_OR32_NOP, 26'h041_0000};        // id_insn[16] must be 1
	else if (!id_freeze) begin
		id_insn <= #1 if_insn;
`ifdef OR1200_VERBOSE
// synopsys translate_off
		$display("%t: id_insn <= %h", $time, if_insn);
// synopsys translate_on
`endif
	end
end

//
// Instruction latch in ex_insn
//
always @(posedge clk or posedge rst) begin
	if (rst)
		ex_insn <= #1 {`OR1200_OR32_NOP, 26'h041_0000};
	else if (!ex_freeze & id_freeze | flushpipe)
		ex_insn <= #1 {`OR1200_OR32_NOP, 26'h041_0000};	// ex_insn[16] must be 1
	else if (!ex_freeze) begin
		ex_insn <= #1 id_insn;
`ifdef OR1200_VERBOSE
// synopsys translate_off
		$display("%t: ex_insn <= %h", $time, id_insn);
// synopsys translate_on
`endif
	end
end

//
// Instruction latch in wb_insn
//
always @(posedge clk or posedge rst) begin
	if (rst)
		wb_insn <= #1 {`OR1200_OR32_NOP, 26'h041_0000};
	else if (flushpipe)
		wb_insn <= #1 {`OR1200_OR32_NOP, 26'h041_0000};	// wb_insn[16] must be 1
	else if (!wb_freeze) begin
		wb_insn <= #1 ex_insn;
	end
end

//
// Decode of sel_imm
//
always @(posedge clk or posedge rst) begin
	if (rst)
		sel_imm <= #1 1'b0;
	else if (!id_freeze) begin
	  case (if_insn[31:26])		// synopsys parallel_case

	    // j.jalr
	    `OR1200_OR32_JALR:
	      sel_imm <= #1 1'b0;
	    
	    // l.jr
	    `OR1200_OR32_JR:
	      sel_imm <= #1 1'b0;
	    
	    // l.rfe
	    `OR1200_OR32_RFE:
	      sel_imm <= #1 1'b0;
	    
	    // l.mfspr
	    `OR1200_OR32_MFSPR:
	      sel_imm <= #1 1'b0;
	    
	    // l.mtspr
	    `OR1200_OR32_MTSPR:
	      sel_imm <= #1 1'b0;
	    
	    // l.sys, l.brk and all three sync insns
	    `OR1200_OR32_XSYNC:
	      sel_imm <= #1 1'b0;
	    
	    // l.mac/l.msb
`ifdef OR1200_MAC_IMPLEMENTED
	    `OR1200_OR32_MACMSB:
	      sel_imm <= #1 1'b0;
`endif

	    // l.sw
	    `OR1200_OR32_SW:
	      sel_imm <= #1 1'b0;
	    
	    // l.sb
	    `OR1200_OR32_SB:
	      sel_imm <= #1 1'b0;
	    
	    // l.sh
	    `OR1200_OR32_SH:
	      sel_imm <= #1 1'b0;
	    
	    // ALU instructions except the one with immediate
	    `OR1200_OR32_ALU:
	      sel_imm <= #1 1'b0;
	    
	    // SFXX instructions
	    `OR1200_OR32_SFXX:
	      sel_imm <= #1 1'b0;

`ifdef OR1200_OR32_CUST5
	    // l.cust5 instructions
	    `OR1200_OR32_CUST5:
	      sel_imm <= #1 1'b0;
`endif
	    
	    // l.nop
	    `OR1200_OR32_NOP:
	      sel_imm <= #1 1'b0;

	    // All instructions with immediates
	    default: begin
	      sel_imm <= #1 1'b1;
	    end
	    
	  endcase
	  
	end
end

//
// Decode of except_illegal
//
always @(posedge clk or posedge rst) begin
	if (rst)
		except_illegal <= #1 1'b0;
	else if (!ex_freeze & id_freeze | flushpipe)
		except_illegal <= #1 1'b0;
	else if (!ex_freeze) begin
	  case (id_insn[31:26])		// synopsys parallel_case

	    `OR1200_OR32_J,
	    `OR1200_OR32_JAL,
	    `OR1200_OR32_JALR,
	    `OR1200_OR32_JR,
	    `OR1200_OR32_BNF,
	    `OR1200_OR32_BF,
	    `OR1200_OR32_RFE,
	    `OR1200_OR32_MOVHI,
	    `OR1200_OR32_MFSPR,
	    `OR1200_OR32_XSYNC,
`ifdef OR1200_MAC_IMPLEMENTED
	    `OR1200_OR32_MACI,
`endif
	    `OR1200_OR32_LWZ,
	    `OR1200_OR32_LBZ,
	    `OR1200_OR32_LBS,
	    `OR1200_OR32_LHZ,
	    `OR1200_OR32_LHS,
	    `OR1200_OR32_ADDI,
	    `OR1200_OR32_ADDIC,
	    `OR1200_OR32_ANDI,
	    `OR1200_OR32_ORI,
	    `OR1200_OR32_XORI,
`ifdef OR1200_MULT_IMPLEMENTED
	    `OR1200_OR32_MULI,
`endif
	    `OR1200_OR32_SH_ROTI,
	    `OR1200_OR32_SFXXI,
	    `OR1200_OR32_MTSPR,
`ifdef OR1200_MAC_IMPLEMENTED
	    `OR1200_OR32_MACMSB,
`endif
	    `OR1200_OR32_SW,
	    `OR1200_OR32_SB,
	    `OR1200_OR32_SH,
	    `OR1200_OR32_ALU,
	    `OR1200_OR32_SFXX,
`ifdef OR1200_OR32_CUST5
	    `OR1200_OR32_CUST5,
`endif
	    `OR1200_OR32_NOP:
		except_illegal <= #1 1'b0;

	    // Illegal and OR1200 unsupported instructions
	    default:
	      except_illegal <= #1 1'b1;

	  endcase
	  
	end
end

//
// Decode of alu_op
//
always @(posedge clk or posedge rst) begin
	if (rst)
		alu_op <= #1 `OR1200_ALUOP_NOP;
	else if (!ex_freeze & id_freeze | flushpipe)
		alu_op <= #1 `OR1200_ALUOP_NOP;
	else if (!ex_freeze) begin
	  case (id_insn[31:26])		// synopsys parallel_case
	    
	    // l.j
	    `OR1200_OR32_J:
	      alu_op <= #1 `OR1200_ALUOP_IMM;
	    
	    // j.jal
	    `OR1200_OR32_JAL:
	      alu_op <= #1 `OR1200_ALUOP_IMM;
	    
	    // l.bnf
	    `OR1200_OR32_BNF:
	      alu_op <= #1 `OR1200_ALUOP_NOP;
	    
	    // l.bf
	    `OR1200_OR32_BF:
	      alu_op <= #1 `OR1200_ALUOP_NOP;
	    
	    // l.movhi
	    `OR1200_OR32_MOVHI:
	      alu_op <= #1 `OR1200_ALUOP_MOVHI;
	    
	    // l.mfspr
	    `OR1200_OR32_MFSPR:
	      alu_op <= #1 `OR1200_ALUOP_MFSR;
	    
	    // l.mtspr
	    `OR1200_OR32_MTSPR:
	      alu_op <= #1 `OR1200_ALUOP_MTSR;
	    
	    // l.addi
	    `OR1200_OR32_ADDI:
	      alu_op <= #1 `OR1200_ALUOP_ADD;
	    
	    // l.addic
	    `OR1200_OR32_ADDIC:
	      alu_op <= #1 `OR1200_ALUOP_ADDC;
	    
	    // l.andi
	    `OR1200_OR32_ANDI:
	      alu_op <= #1 `OR1200_ALUOP_AND;
	    
	    // l.ori
	    `OR1200_OR32_ORI:
	      alu_op <= #1 `OR1200_ALUOP_OR;
	    
	    // l.xori
	    `OR1200_OR32_XORI:
	      alu_op <= #1 `OR1200_ALUOP_XOR;
	    
	    // l.muli
`ifdef OR1200_MULT_IMPLEMENTED
	    `OR1200_OR32_MULI:
	      alu_op <= #1 `OR1200_ALUOP_MUL;
`endif
	    
	    // Shift and rotate insns with immediate
	    `OR1200_OR32_SH_ROTI:
	      alu_op <= #1 `OR1200_ALUOP_SHROT;
	    
	    // SFXX insns with immediate
	    `OR1200_OR32_SFXXI:
	      alu_op <= #1 `OR1200_ALUOP_COMP;
	    
	    // ALU instructions except the one with immediate
	    `OR1200_OR32_ALU:
	      alu_op <= #1 id_insn[3:0];
	    
	    // SFXX instructions
	    `OR1200_OR32_SFXX:
	      alu_op <= #1 `OR1200_ALUOP_COMP;

`ifdef OR1200_OR32_CUST5
	    // l.cust5 instructions
	    `OR1200_OR32_CUST5:
	      alu_op <= #1 `OR1200_ALUOP_CUST5;
`endif
	    
	    // Default
	    default: begin
	      alu_op <= #1 `OR1200_ALUOP_NOP;
	    end
	      
	  endcase
	  
	end
end

//
// Decode of mac_op
//
`ifdef OR1200_MAC_IMPLEMENTED
always @(posedge clk or posedge rst) begin
	if (rst)
		mac_op <= #1 `OR1200_MACOP_NOP;
	else if (!ex_freeze & id_freeze | flushpipe)
		mac_op <= #1 `OR1200_MACOP_NOP;
	else if (!ex_freeze)
	  case (id_insn[31:26])		// synopsys parallel_case

	    // l.maci
	    `OR1200_OR32_MACI:
	      mac_op <= #1 `OR1200_MACOP_MAC;

	    // l.nop
	    `OR1200_OR32_MACMSB:
	      mac_op <= #1 id_insn[1:0];

	    // Illegal and OR1200 unsupported instructions
	    default: begin
	      mac_op <= #1 `OR1200_MACOP_NOP;
	    end	      

	  endcase
	else
		mac_op <= #1 `OR1200_MACOP_NOP;
end
`else
assign mac_op = `OR1200_MACOP_NOP;
`endif

//
// Decode of shrot_op
//
always @(posedge clk or posedge rst) begin
	if (rst)
		shrot_op <= #1 `OR1200_SHROTOP_NOP;
	else if (!ex_freeze & id_freeze | flushpipe)
		shrot_op <= #1 `OR1200_SHROTOP_NOP;
	else if (!ex_freeze) begin
		shrot_op <= #1 id_insn[`OR1200_SHROTOP_POS];
	end
end

//
// Decode of rfwb_op
//
always @(posedge clk or posedge rst) begin
	if (rst)
		rfwb_op <= #1 `OR1200_RFWBOP_NOP;
	else  if (!ex_freeze & id_freeze | flushpipe)
		rfwb_op <= #1 `OR1200_RFWBOP_NOP;
	else  if (!ex_freeze) begin
		case (id_insn[31:26])		// synopsys parallel_case

		  // j.jal
		  `OR1200_OR32_JAL:
		    rfwb_op <= #1 `OR1200_RFWBOP_LR;
		  
		  // j.jalr
		  `OR1200_OR32_JALR:
		    rfwb_op <= #1 `OR1200_RFWBOP_LR;
		  
		  // l.movhi
		  `OR1200_OR32_MOVHI:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;
		  
		  // l.mfspr
		  `OR1200_OR32_MFSPR:
		    rfwb_op <= #1 `OR1200_RFWBOP_SPRS;
		  
		  // l.lwz
		  `OR1200_OR32_LWZ:
		    rfwb_op <= #1 `OR1200_RFWBOP_LSU;
		  
		  // l.lbz
		  `OR1200_OR32_LBZ:
		    rfwb_op <= #1 `OR1200_RFWBOP_LSU;
		  
		  // l.lbs
		  `OR1200_OR32_LBS:
		    rfwb_op <= #1 `OR1200_RFWBOP_LSU;
		  
		  // l.lhz
		  `OR1200_OR32_LHZ:
		    rfwb_op <= #1 `OR1200_RFWBOP_LSU;
		  
		  // l.lhs
		  `OR1200_OR32_LHS:
		    rfwb_op <= #1 `OR1200_RFWBOP_LSU;
		  
		  // l.addi
		  `OR1200_OR32_ADDI:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;
		  
		  // l.addic
		  `OR1200_OR32_ADDIC:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;
		  
		  // l.andi
		  `OR1200_OR32_ANDI:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;
		  
		  // l.ori
		  `OR1200_OR32_ORI:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;
		  
		  // l.xori
		  `OR1200_OR32_XORI:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;
		  
		  // l.muli
`ifdef OR1200_MULT_IMPLEMENTED
		  `OR1200_OR32_MULI:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;
`endif
		  
		  // Shift and rotate insns with immediate
		  `OR1200_OR32_SH_ROTI:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;
		  
		  // ALU instructions except the one with immediate
		  `OR1200_OR32_ALU:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;

`ifdef OR1200_OR32_CUST5
		  // l.cust5 instructions
		  `OR1200_OR32_CUST5:
		    rfwb_op <= #1 `OR1200_RFWBOP_ALU;
`endif

		  // Instructions w/o register-file write-back
		  default: begin
		    rfwb_op <= #1 `OR1200_RFWBOP_NOP;
		  end

		endcase
	end
end

//
// Decode of pre_branch_op
//
always @(posedge clk or posedge rst) begin
	if (rst)
		pre_branch_op <= #1 `OR1200_BRANCHOP_NOP;
	else if (flushpipe)
		pre_branch_op <= #1 `OR1200_BRANCHOP_NOP;
	else if (!id_freeze) begin
		case (if_insn[31:26])		// synopsys parallel_case
		  
		  // l.j
		  `OR1200_OR32_J:
		    pre_branch_op <= #1 `OR1200_BRANCHOP_BAL;
		  
		  // j.jal
		  `OR1200_OR32_JAL:
		    pre_branch_op <= #1 `OR1200_BRANCHOP_BAL;
		  
		  // j.jalr
		  `OR1200_OR32_JALR:
		    pre_branch_op <= #1 `OR1200_BRANCHOP_JR;
		  
		  // l.jr
		  `OR1200_OR32_JR:
		    pre_branch_op <= #1 `OR1200_BRANCHOP_JR;
		  
		  // l.bnf
		  `OR1200_OR32_BNF:
		    pre_branch_op <= #1 `OR1200_BRANCHOP_BNF;
		  
		  // l.bf
		  `OR1200_OR32_BF:
		    pre_branch_op <= #1 `OR1200_BRANCHOP_BF;
		  
		  // l.rfe
		  `OR1200_OR32_RFE:
		    pre_branch_op <= #1 `OR1200_BRANCHOP_RFE;
		  
		  // Non branch instructions
		  default: begin
		    pre_branch_op <= #1 `OR1200_BRANCHOP_NOP;
		  end
		endcase
	end
end

//
// Generation of branch_op
//
always @(posedge clk or posedge rst)
	if (rst)
		branch_op <= #1 `OR1200_BRANCHOP_NOP;
	else if (!ex_freeze & id_freeze | flushpipe)
		branch_op <= #1 `OR1200_BRANCHOP_NOP;		
	else if (!ex_freeze)
		branch_op <= #1 pre_branch_op;

//
// Decode of lsu_op
//
always @(posedge clk or posedge rst) begin
	if (rst)
		lsu_op <= #1 `OR1200_LSUOP_NOP;
	else if (!ex_freeze & id_freeze | flushpipe)
		lsu_op <= #1 `OR1200_LSUOP_NOP;
	else if (!ex_freeze)  begin
	  case (id_insn[31:26])		// synopsys parallel_case
	    
	    // l.lwz
	    `OR1200_OR32_LWZ:
	      lsu_op <= #1 `OR1200_LSUOP_LWZ;
	    
	    // l.lbz
	    `OR1200_OR32_LBZ:
	      lsu_op <= #1 `OR1200_LSUOP_LBZ;
	    
	    // l.lbs
	    `OR1200_OR32_LBS:
	      lsu_op <= #1 `OR1200_LSUOP_LBS;
	    
	    // l.lhz
	    `OR1200_OR32_LHZ:
	      lsu_op <= #1 `OR1200_LSUOP_LHZ;
	    
	    // l.lhs
	    `OR1200_OR32_LHS:
	      lsu_op <= #1 `OR1200_LSUOP_LHS;
	    
	    // l.sw
	    `OR1200_OR32_SW:
	      lsu_op <= #1 `OR1200_LSUOP_SW;
	    
	    // l.sb
	    `OR1200_OR32_SB:
	      lsu_op <= #1 `OR1200_LSUOP_SB;
	    
	    // l.sh
	    `OR1200_OR32_SH:
	      lsu_op <= #1 `OR1200_LSUOP_SH;
	    
	    // Non load/store instructions
	    default: begin
	      lsu_op <= #1 `OR1200_LSUOP_NOP;
	    end
	  endcase
	end
end

//
// Decode of comp_op
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		comp_op <= #1 4'd0;
	end else if (!ex_freeze & id_freeze | flushpipe)
		comp_op <= #1 4'd0;
	else if (!ex_freeze)
		comp_op <= #1 id_insn[24:21];
end

//
// Decode of l.sys
//
always @(posedge clk or posedge rst) begin
	if (rst)
		sig_syscall <= #1 1'b0;
	else if (!ex_freeze & id_freeze | flushpipe)
		sig_syscall <= #1 1'b0;
	else if (!ex_freeze) begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
		if (id_insn[31:23] == {`OR1200_OR32_XSYNC, 3'b000})
			$display("Generating sig_syscall");
// synopsys translate_on
`endif
		sig_syscall <= #1 (id_insn[31:23] == {`OR1200_OR32_XSYNC, 3'b000});
	end
end

//
// Decode of l.trap
//
always @(posedge clk or posedge rst) begin
	if (rst)
		sig_trap <= #1 1'b0;
	else if (!ex_freeze & id_freeze | flushpipe)
		sig_trap <= #1 1'b0;
	else if (!ex_freeze) begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
		if (id_insn[31:23] == {`OR1200_OR32_XSYNC, 3'b010})
			$display("Generating sig_trap");
// synopsys translate_on
`endif
		sig_trap <= #1 (id_insn[31:23] == {`OR1200_OR32_XSYNC, 3'b010})
			| du_hwbkpt;
	end
end

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's DC FSM                                             ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Data cache state machine                                    ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_dc_fsm.v,v $
// Revision 1.9  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.8  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.7.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.7  2002/03/29 15:16:55  lampret
// Some of the warnings fixed.
//
// Revision 1.6  2002/03/28 19:10:40  lampret
// Optimized cache controller FSM.
//
// Revision 1.1.1.1  2002/03/21 16:55:45  lampret
// First import of the "new" XESS XSV environment.
//
//
// Revision 1.5  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.4  2002/02/01 19:56:54  lampret
// Fixed combinational loops.
//
// Revision 1.3  2002/01/28 01:15:59  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/19 23:28:46  lampret
// Fixed some synthesis warnings. Configured with caches and MMUs.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

`define OR1200_DCFSM_IDLE	3'd0
`define OR1200_DCFSM_CLOAD	3'd1
`define OR1200_DCFSM_LREFILL3	3'd2
`define OR1200_DCFSM_CSTORE	3'd3
`define OR1200_DCFSM_SREFILL4	3'd4

//
// Data cache FSM for cache line of 16 bytes (4x singleword)
//

module or1200_dc_fsm(
	// Clock and reset
	clk, rst,

	// Internal i/f to top level DC
	dc_en, dcqmem_cycstb_i, dcqmem_ci_i, dcqmem_we_i, dcqmem_sel_i,
	tagcomp_miss, biudata_valid, biudata_error, start_addr, saved_addr,
	dcram_we, biu_read, biu_write, first_hit_ack, first_miss_ack, first_miss_err,
	burst, tag_we, dc_addr
);

//
// I/O
//
input				clk;
input				rst;
input				dc_en;
input				dcqmem_cycstb_i;
input				dcqmem_ci_i;
input				dcqmem_we_i;
input	[3:0]			dcqmem_sel_i;
input				tagcomp_miss;
input				biudata_valid;
input				biudata_error;
input	[31:0]			start_addr;
output	[31:0]			saved_addr;
output	[3:0]			dcram_we;
output				biu_read;
output				biu_write;
output				first_hit_ack;
output				first_miss_ack;
output				first_miss_err;
output				burst;
output				tag_we;
output	[31:0]			dc_addr;

//
// Internal wires and regs
//
reg	[31:0]			saved_addr_r;
reg	[2:0]			state;
reg	[2:0]			cnt;
reg				hitmiss_eval;
reg				store;
reg				load;
reg				cache_inhibit;
wire                tagcomp_miss_wide;
wire				first_store_hit_ack;

//
// Generate of DCRAM write enables
//
assign dcram_we = {4{load & biudata_valid & !cache_inhibit}} | {4{first_store_hit_ack}} & dcqmem_sel_i;
assign tag_we = biu_read & biudata_valid & !cache_inhibit;

//
// BIU read and write
//
assign biu_read = (hitmiss_eval & tagcomp_miss) | (!hitmiss_eval & load);
assign biu_write = store;

assign dc_addr = (biu_read | biu_write) & !hitmiss_eval ? saved_addr : start_addr;
assign saved_addr = saved_addr_r;

//
// Assert for cache hit first word ready
// Assert for store cache hit first word ready
// Assert for cache miss first word stored/loaded OK
// Assert for cache miss first word stored/loaded with an error
//
assign tagcomp_miss_wide = tagcomp_miss | (saved_addr != start_addr);
assign first_hit_ack = (state == `OR1200_DCFSM_CLOAD) & !tagcomp_miss_wide & !cache_inhibit | first_store_hit_ack;
assign first_store_hit_ack = (state == `OR1200_DCFSM_CSTORE) & !tagcomp_miss_wide & biudata_valid & !cache_inhibit;
assign first_miss_ack = ((state == `OR1200_DCFSM_CLOAD) | (state == `OR1200_DCFSM_CSTORE)) & biudata_valid;
assign first_miss_err = ((state == `OR1200_DCFSM_CLOAD) | (state == `OR1200_DCFSM_CSTORE)) & biudata_error;

//
// Assert burst when doing reload of complete cache line
//
assign burst = (state == `OR1200_DCFSM_CLOAD) & tagcomp_miss & !cache_inhibit
		| (state == `OR1200_DCFSM_LREFILL3)
`ifdef OR1200_DC_STORE_REFILL
		| (state == `OR1200_DCFSM_SREFILL4)
`endif
		;

//
// Main DC FSM
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		state <= #1 `OR1200_DCFSM_IDLE;
		saved_addr_r <= #1 32'b0;
		hitmiss_eval <= #1 1'b0;
		store <= #1 1'b0;
		load <= #1 1'b0;
		cnt <= #1 3'b000;
		cache_inhibit <= #1 1'b0;
	end
	else
	case (state)	// synopsys parallel_case
		`OR1200_DCFSM_IDLE :
			if (dc_en & dcqmem_cycstb_i & dcqmem_we_i) begin	// store
				state <= #1 `OR1200_DCFSM_CSTORE;
				saved_addr_r <= #1 start_addr;
				hitmiss_eval <= #1 1'b1;
				store <= #1 1'b1;
				load <= #1 1'b0;
                cache_inhibit <= #1 dcqmem_ci_i;
			end
			else if (dc_en & dcqmem_cycstb_i) begin		// load
				state <= #1 `OR1200_DCFSM_CLOAD;
				saved_addr_r <= #1 start_addr;
				hitmiss_eval <= #1 1'b1;
				store <= #1 1'b0;
				load <= #1 1'b1;
                cache_inhibit <= #1 dcqmem_ci_i;
			end
			else begin							// idle
				hitmiss_eval <= #1 1'b0;
				store <= #1 1'b0;
				load <= #1 1'b0;
				cache_inhibit <= #1 1'b0;
			end
		`OR1200_DCFSM_CLOAD: begin		// load
			if (dcqmem_cycstb_i & dcqmem_ci_i)
				cache_inhibit <= #1 1'b1;
			if (hitmiss_eval)
				saved_addr_r[31:13] <= #1 start_addr[31:13];
			if ((hitmiss_eval & !dcqmem_cycstb_i) ||					// load aborted (usually caused by DMMU)
			    (biudata_error) ||										// load terminated with an error
			    ((cache_inhibit | dcqmem_ci_i) & biudata_valid)) begin	// load from cache-inhibited area
				state <= #1 `OR1200_DCFSM_IDLE;
				hitmiss_eval <= #1 1'b0;
				load <= #1 1'b0;
				cache_inhibit <= #1 1'b0;
			end
			else if (tagcomp_miss & biudata_valid) begin	// load missed, finish current external load and refill
				state <= #1 `OR1200_DCFSM_LREFILL3;
				saved_addr_r[3:2] <= #1 saved_addr_r[3:2] + 1'd1;
				hitmiss_eval <= #1 1'b0;
				cnt <= #1 `OR1200_DCLS-2;
				cache_inhibit <= #1 1'b0;
			end
			else if (!tagcomp_miss_wide & !dcqmem_ci_i) begin	// load hit, finish immediately
				state <= #1 `OR1200_DCFSM_IDLE;
				hitmiss_eval <= #1 1'b0;
				load <= #1 1'b0;
				cache_inhibit <= #1 1'b0;
			end
			else						// load in-progress
				hitmiss_eval <= #1 1'b0;
		end
		`OR1200_DCFSM_LREFILL3 : begin
			if (biudata_valid && (|cnt)) begin		// refill ack, more loads to come
				cnt <= #1 cnt - 3'd1;
				saved_addr_r[3:2] <= #1 saved_addr_r[3:2] + 1'd1;
			end
			else if (biudata_valid) begin			// last load of line refill
				state <= #1 `OR1200_DCFSM_IDLE;
				load <= #1 1'b0;
			end
		end
		`OR1200_DCFSM_CSTORE: begin		// store
			if (dcqmem_cycstb_i & dcqmem_ci_i)
				cache_inhibit <= #1 1'b1;
			if (hitmiss_eval)
				saved_addr_r[31:13] <= #1 start_addr[31:13];
			if ((hitmiss_eval & !dcqmem_cycstb_i) ||	// store aborted (usually caused by DMMU)
			    (biudata_error) ||						// store terminated with an error
			    ((cache_inhibit | dcqmem_ci_i) & biudata_valid)) begin	// store to cache-inhibited area
				state <= #1 `OR1200_DCFSM_IDLE;
				hitmiss_eval <= #1 1'b0;
				store <= #1 1'b0;
				cache_inhibit <= #1 1'b0;
			end
`ifdef OR1200_DC_STORE_REFILL
			else if (tagcomp_miss & biudata_valid) begin	// store missed, finish write-through and doq load refill
				state <= #1 `OR1200_DCFSM_SREFILL4;
				hitmiss_eval <= #1 1'b0;
				store <= #1 1'b0;
				load <= #1 1'b1;
				cnt <= #1 `OR1200_DCLS-1;
				cache_inhibit <= #1 1'b0;
			end
`endif
			else if (biudata_valid) begin			// store hit, finish write-through
				state <= #1 `OR1200_DCFSM_IDLE;
				hitmiss_eval <= #1 1'b0;
				store <= #1 1'b0;
				cache_inhibit <= #1 1'b0;
			end
			else						// store write-through in-progress
				hitmiss_eval <= #1 1'b0;
			end
`ifdef OR1200_DC_STORE_REFILL
		`OR1200_DCFSM_SREFILL4 : begin
			if (biudata_valid && (|cnt)) begin		// refill ack, more loads to come
				cnt <= #1 cnt - 1'd1;
				saved_addr_r[3:2] <= #1 saved_addr_r[3:2] + 1'd1;
			end
			else if (biudata_valid) begin			// last load of line refill
				state <= #1 `OR1200_DCFSM_IDLE;
				load <= #1 1'b0;
			end
		end
`endif
		default:
			state <= #1 `OR1200_DCFSM_IDLE;
	endcase
end

endmodule

//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's DC RAMs                                            ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instatiation of DC RAM blocks.                              ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_dc_ram.v,v $
// Revision 1.6  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.5  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.2.4.2  2003/12/10 15:28:28  simons
// Support for ram with byte selects added.
//
// Revision 1.2.4.1  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.2  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_dc_ram(
	// Reset and clock
	clk, rst,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// Internal i/f
	addr, en, we, datain, dataout
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_DCINDX;

//
// I/O
//
input				clk;
input				rst;
input	[aw-1:0]		addr;
input				en;
input	[3:0]			we;
input	[dw-1:0]		datain;
output	[dw-1:0]		dataout;

`ifdef OR1200_BIST
//
// RAM BIST
//
input				mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;       // bist chain shift control
output				mbist_so_o;
`endif

`ifdef OR1200_NO_DC

//
// Data cache not implemented
//
assign dataout = {dw{1'b0}};
`ifdef OR1200_BIST
assign mbist_so_o = mbist_si_i;
`endif

`else

//
// Instantiation of RAM block
//
`ifdef OR1200_DC_1W_4KB
   or1200_spram_32_bw #
     (
      .aw(10),
      .dw(32)
      )
`endif
`ifdef OR1200_DC_1W_8KB
   or1200_spram_32_bw #
     (
      .aw(11),
      .dw(32)
      )
`endif
   dc_ram
     (
`ifdef OR1200_BIST
      // RAM BIST
      .mbist_si_i(mbist_si_i),
      .mbist_so_o(mbist_so_o),
      .mbist_ctrl_i(mbist_ctrl_i),
`endif
      .clk(clk),
      .ce(en),
      .we(we),
      .addr(addr),
      .di(datain),
      .doq(dataout)
      );
`endif
endmodule // or1200_dc_ram
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's DC TAG RAMs                                        ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instatiation of data cache tag rams.                        ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_dc_tag.v,v $
// Revision 1.5  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.4  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.2.4.1  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.2  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_dc_tag(
	// Clock and reset
	clk, rst,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// Internal i/f
	addr, en, we, datain, tag_v, tag
);

parameter dw = `OR1200_DCTAG_W;
parameter aw = `OR1200_DCTAG;

//
// I/O
//
input				clk;
input				rst;
input	[aw-1:0]		addr;
input				en;
input				we;
input	[dw-1:0]		datain;
output				tag_v;
output	[dw-2:0]		tag;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

`ifdef OR1200_NO_DC

//
// Data cache not implemented
//
assign tag = {dw-1{1'b0}};
assign tag_v = 1'b0;
`ifdef OR1200_BIST
assign mbist_so_o = mbist_si_i;
`endif

`else

//
// Instantiation of TAG RAM block
//
`ifdef OR1200_DC_1W_4KB
   or1200_spram #
     (
      .aw(8),
      .dw(21)
      )
`endif
`ifdef OR1200_DC_1W_8KB
   or1200_spram #
     (
      .aw(9),
      .dw(20)
      )
`endif
   dc_tag0
     (
`ifdef OR1200_BIST
      // RAM BIST
      .mbist_si_i(mbist_si_i),
      .mbist_so_o(mbist_so_o),
      .mbist_ctrl_i(mbist_ctrl_i),
`endif
      .clk(clk),
      .ce(en),
      .we(we),
      .addr(addr),
      .di(datain),
      .doq({tag, tag_v})
      );
`endif

endmodule // or1200_dc_tag
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Data Cache top level                               ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of all DC blocks.                             ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_dc_top.v,v $
// Revision 1.8  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.6.4.2  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.6.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.6  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.5  2002/08/18 19:54:47  lampret
// Added store buffer.
//
// Revision 1.4  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.3  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.10  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.9  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.4  2001/08/13 03:36:20  lampret
// Added cfg regs. Moved all defines into one defines.v file. More cleanup.
//
// Revision 1.3  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/22 03:31:53  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

//
// Data cache
//
module or1200_dc_top(
	// Rst, clk and clock control
	clk, rst,

	// External i/f
	dcsb_dat_o, dcsb_adr_o, dcsb_cyc_o, dcsb_stb_o, dcsb_we_o, dcsb_sel_o, dcsb_cab_o,
	dcsb_dat_i, dcsb_ack_i, dcsb_err_i,

	// Internal i/f
	dc_en,
	dcqmem_adr_i, dcqmem_cycstb_i, dcqmem_ci_i,
	dcqmem_we_i, dcqmem_sel_i, dcqmem_tag_i, dcqmem_dat_i,
	dcqmem_dat_o, dcqmem_ack_o, dcqmem_rty_o, dcqmem_err_o, dcqmem_tag_o,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// SPRs
	spr_cs, spr_write, spr_dat_i
);

parameter dw = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// External I/F
//
output	[dw-1:0]		dcsb_dat_o;
output	[31:0]			dcsb_adr_o;
output				dcsb_cyc_o;
output				dcsb_stb_o;
output				dcsb_we_o;
output	[3:0]			dcsb_sel_o;
output				dcsb_cab_o;
input	[dw-1:0]		dcsb_dat_i;
input				dcsb_ack_i;
input				dcsb_err_i;

//
// Internal I/F
//
input				dc_en;
input	[31:0]			dcqmem_adr_i;
input				dcqmem_cycstb_i;
input				dcqmem_ci_i;
input				dcqmem_we_i;
input	[3:0]			dcqmem_sel_i;
input	[3:0]			dcqmem_tag_i;
input	[dw-1:0]		dcqmem_dat_i;
output	[dw-1:0]		dcqmem_dat_o;
output				dcqmem_ack_o;
output				dcqmem_rty_o;
output				dcqmem_err_o;
output	[3:0]			dcqmem_tag_o;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// SPR access
//
input				spr_cs;
input				spr_write;
input	[31:0]			spr_dat_i;

//
// Internal wires and regs
//
wire				tag_v;
wire	[`OR1200_DCTAG_W-2:0]	tag;
wire	[dw-1:0]		to_dcram;
wire	[dw-1:0]		from_dcram;
wire	[31:0]			saved_addr;
wire	[3:0]			dcram_we;
wire				dctag_we;
wire	[31:0]			dc_addr;
wire				dcfsm_biu_read;
wire				dcfsm_biu_write;
reg				tagcomp_miss;
wire	[`OR1200_DCINDXH:`OR1200_DCLS]	dctag_addr;
wire				dctag_en;
wire				dctag_v; 
wire				dc_inv;
wire				dcfsm_first_hit_ack;
wire				dcfsm_first_miss_ack;
wire				dcfsm_first_miss_err;
wire				dcfsm_burst;
wire				dcfsm_tag_we;
`ifdef OR1200_BIST
//
// RAM BIST
//
wire				mbist_ram_so;
wire				mbist_tag_so;
wire				mbist_ram_si = mbist_si_i;
wire				mbist_tag_si = mbist_ram_so;
assign				mbist_so_o = mbist_tag_so;
`endif

//
// Simple assignments
//
assign dcsb_adr_o = dc_addr;
assign dc_inv = spr_cs & spr_write;
assign dctag_we = dcfsm_tag_we | dc_inv;
assign dctag_addr = dc_inv ? spr_dat_i[`OR1200_DCINDXH:`OR1200_DCLS] : dc_addr[`OR1200_DCINDXH:`OR1200_DCLS];
assign dctag_en = dc_inv | dc_en;
assign dctag_v = ~dc_inv;

//
// Data to BIU is from DCRAM when DC is enabled or from LSU when
// DC is disabled
//
assign dcsb_dat_o = dcqmem_dat_i;

//
// Bypases of the DC when DC is disabled
//
assign dcsb_cyc_o = (dc_en) ? dcfsm_biu_read | dcfsm_biu_write : dcqmem_cycstb_i;
assign dcsb_stb_o = (dc_en) ? dcfsm_biu_read | dcfsm_biu_write : dcqmem_cycstb_i;
assign dcsb_we_o = (dc_en) ? dcfsm_biu_write : dcqmem_we_i;
assign dcsb_sel_o = (dc_en & dcfsm_biu_read & !dcfsm_biu_write & !dcqmem_ci_i) ? 4'b1111 : dcqmem_sel_i;
assign dcsb_cab_o = (dc_en) ? dcsb_cyc_o & dcfsm_burst : 1'b0;
assign dcqmem_rty_o = ~dcqmem_ack_o;
assign dcqmem_tag_o = dcqmem_err_o ? `OR1200_DTAG_BE : dcqmem_tag_i;

//
// DC/LSU normal and error termination
//
assign dcqmem_ack_o = dc_en ? dcfsm_first_hit_ack | dcfsm_first_miss_ack : dcsb_ack_i;
assign dcqmem_err_o = dc_en ? dcfsm_first_miss_err : dcsb_err_i;

//
// Select between claddr generated by DC FSM and addr[3:2] generated by LSU
//
//assign dc_addr = (dcfsm_biu_read | dcfsm_biu_write) ? saved_addr : dcqmem_adr_i;

//
// Select between input data generated by LSU or by BIU
//
assign to_dcram = (dcfsm_biu_read) ? dcsb_dat_i : dcqmem_dat_i;

//
// Select between data generated by DCRAM or passed by BIU
//
assign dcqmem_dat_o = dcfsm_first_miss_ack | !dc_en ? dcsb_dat_i : from_dcram;

//
// Tag comparison
//
always @(tag or saved_addr or tag_v) begin
	if ((tag != saved_addr[31:`OR1200_DCTAGL]) || !tag_v)
		tagcomp_miss = 1'b1;
	else
		tagcomp_miss = 1'b0;
end

//
// Instantiation of DC Finite State Machine
//
or1200_dc_fsm or1200_dc_fsm(
	.clk(clk),
	.rst(rst),
	.dc_en(dc_en),
	.dcqmem_cycstb_i(dcqmem_cycstb_i),
	.dcqmem_ci_i(dcqmem_ci_i),
	.dcqmem_we_i(dcqmem_we_i),
	.dcqmem_sel_i(dcqmem_sel_i),
	.tagcomp_miss(tagcomp_miss),
	.biudata_valid(dcsb_ack_i),
	.biudata_error(dcsb_err_i),
	.start_addr(dcqmem_adr_i),
	.saved_addr(saved_addr),
	.dcram_we(dcram_we),
	.biu_read(dcfsm_biu_read),
	.biu_write(dcfsm_biu_write),
	.first_hit_ack(dcfsm_first_hit_ack),
	.first_miss_ack(dcfsm_first_miss_ack),
	.first_miss_err(dcfsm_first_miss_err),
	.burst(dcfsm_burst),
	.tag_we(dcfsm_tag_we),
	.dc_addr(dc_addr)
);

//
// Instantiation of DC main memory
//
or1200_dc_ram or1200_dc_ram(
	.clk(clk),
	.rst(rst),
`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_ram_si),
	.mbist_so_o(mbist_ram_so),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif
	.addr(dc_addr[`OR1200_DCINDXH:2]),
	.en(dc_en),
	.we(dcram_we),
	.datain(to_dcram),
	.dataout(from_dcram)
);

//
// Instantiation of DC TAG memory
//
or1200_dc_tag or1200_dc_tag(
	.clk(clk),
	.rst(rst),
`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_tag_si),
	.mbist_so_o(mbist_tag_so),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif
	.addr(dctag_addr),
	.en(dctag_en),
	.we(dctag_we),
	.datain({dc_addr[31:`OR1200_DCTAGL], dctag_v}),
	.tag_v(tag_v),
	.tag(tag)
);

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Data TLB                                           ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of DTLB.                                      ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_dmmu_tlb.v,v $
// Revision 1.7  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.6  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.4.4.1  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.4  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.3  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.2  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

//
// Data TLB
//

module or1200_dmmu_tlb(
	// Rst and clk
	clk, rst,

	// I/F for translation
	tlb_en, vaddr, hit, ppn, uwe, ure, swe, sre, ci,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// SPR access
	spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// I/F for translation
//
input				tlb_en;
input	[aw-1:0]		vaddr;
output				hit;
output	[31:`OR1200_DMMU_PS]	ppn;
output				uwe;
output				ure;
output				swe;
output				sre;
output				ci;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// SPR access
//
input				spr_cs;
input				spr_write;
input	[31:0]			spr_addr;
input	[31:0]			spr_dat_i;
output	[31:0]			spr_dat_o;

//
// Internal wires and regs
//
wire	[`OR1200_DTLB_TAG]	vpn;
wire				v;
wire	[`OR1200_DTLB_INDXW-1:0]	tlb_index;
wire				tlb_mr_en;
wire				tlb_mr_we;
wire	[`OR1200_DTLBMRW-1:0]	tlb_mr_ram_in;
wire	[`OR1200_DTLBMRW-1:0]	tlb_mr_ram_out;
wire				tlb_tr_en;
wire				tlb_tr_we;
wire	[`OR1200_DTLBTRW-1:0]	tlb_tr_ram_in;
wire	[`OR1200_DTLBTRW-1:0]	tlb_tr_ram_out;
`ifdef OR1200_BIST
//
// RAM BIST
//
wire				mbist_mr_so;
wire				mbist_tr_so;
wire				mbist_mr_si = mbist_si_i;
wire				mbist_tr_si = mbist_mr_so;
assign				mbist_so_o = mbist_tr_so;
`endif

//
// Implemented bits inside match and translate registers
//
// dtlbwYmrX: vpn 31-19  v 0
// dtlbwYtrX: ppn 31-13  swe 9  sre 8  uwe 7  ure 6
//
// dtlb memory width:
// 19 bits for ppn
// 13 bits for vpn
// 1 bit for valid
// 4 bits for protection
// 1 bit for cache inhibit

//
// Enable for Match registers
//
assign tlb_mr_en = tlb_en | (spr_cs & !spr_addr[`OR1200_DTLB_TM_ADDR]);

//
// Write enable for Match registers
//
assign tlb_mr_we = spr_cs & spr_write & !spr_addr[`OR1200_DTLB_TM_ADDR];

//
// Enable for Translate registers
//
assign tlb_tr_en = tlb_en | (spr_cs & spr_addr[`OR1200_DTLB_TM_ADDR]);

//
// Write enable for Translate registers
//
assign tlb_tr_we = spr_cs & spr_write & spr_addr[`OR1200_DTLB_TM_ADDR];

//
// Output to SPRS unit
//
assign spr_dat_o = (spr_cs & !spr_write & !spr_addr[`OR1200_DTLB_TM_ADDR]) ?
			{vpn, tlb_index, {`OR1200_DTLB_TAGW-7{1'b0}}, 1'b0, 5'b00000, v} : 
		(spr_cs & !spr_write & spr_addr[`OR1200_DTLB_TM_ADDR]) ?
			{ppn, {`OR1200_DMMU_PS-10{1'b0}}, swe, sre, uwe, ure, {4{1'b0}}, ci, 1'b0} :
			32'h00000000;

//
// Assign outputs from Match registers
//
assign {vpn, v} = tlb_mr_ram_out;

//
// Assign to Match registers inputs
//
assign tlb_mr_ram_in = {spr_dat_i[`OR1200_DTLB_TAG], spr_dat_i[`OR1200_DTLBMR_V_BITS]};

//
// Assign outputs from Translate registers
//
assign {ppn, swe, sre, uwe, ure, ci} = tlb_tr_ram_out;

//
// Assign to Translate registers inputs
//
assign tlb_tr_ram_in = {spr_dat_i[31:`OR1200_DMMU_PS],
			spr_dat_i[`OR1200_DTLBTR_SWE_BITS],
			spr_dat_i[`OR1200_DTLBTR_SRE_BITS],
			spr_dat_i[`OR1200_DTLBTR_UWE_BITS],
			spr_dat_i[`OR1200_DTLBTR_URE_BITS],
			spr_dat_i[`OR1200_DTLBTR_CI_BITS]};

//
// Generate hit
//
assign hit = (vpn == vaddr[`OR1200_DTLB_TAG]) & v;

//
// TLB index is normally vaddr[18:13]. If it is SPR access then index is
// spr_addr[5:0].
//
assign tlb_index = spr_cs ? spr_addr[`OR1200_DTLB_INDXW-1:0] : vaddr[`OR1200_DTLB_INDX];

//
// Instantiation of DTLB Match Registers
//
//or1200_spram_64x14 dtlb_mr_ram(
   or1200_spram #
     (
      .aw(6),
      .dw(14)
      )
   dtlb_ram
     (
      .clk(clk),
`ifdef OR1200_BIST
      // RAM BIST
      .mbist_si_i(mbist_mr_si),
      .mbist_so_o(mbist_mr_so),
      .mbist_ctrl_i(mbist_ctrl_i),
`endif
      .ce(tlb_mr_en),
      .we(tlb_mr_we),
      .addr(tlb_index),
      .di(tlb_mr_ram_in),
      .doq(tlb_mr_ram_out)
      );
   
   //
   // Instantiation of DTLB Translate Registers
   //
   //or1200_spram_64x24 dtlb_tr_ram(
   or1200_spram #
     (
      .aw(6),
      .dw(24)
      )
   dtlb_tr_ram
     (
      .clk(clk),
`ifdef OR1200_BIST
      // RAM BIST
      .mbist_si_i(mbist_tr_si),
      .mbist_so_o(mbist_tr_so),
      .mbist_ctrl_i(mbist_ctrl_i),
`endif
      .ce(tlb_tr_en),
      .we(tlb_tr_we),
      .addr(tlb_index),
      .di(tlb_tr_ram_in),
      .doq(tlb_tr_ram_out)
      );
   
endmodule // or1200_dmmu_tlb
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Data MMU top level                                 ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of all DMMU blocks.                           ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_dmmu_top.v,v $
// Revision 1.9  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.7.4.2  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.7.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.7  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.6  2002/03/29 15:16:55  lampret
// Some of the warnings fixed.
//
// Revision 1.5  2002/02/14 15:34:02  simons
// Lapsus fixed.
//
// Revision 1.4  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.3  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.6  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.5  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.1  2001/08/17 08:03:35  lampret
// *** empty log message ***
//
// Revision 1.2  2001/07/22 03:31:53  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

//
// Data MMU
//

module or1200_dmmu_top(
	// Rst and clk
	clk, rst,

	// CPU i/f
	dc_en, dmmu_en, supv, dcpu_adr_i, dcpu_cycstb_i, dcpu_we_i,
	dcpu_tag_o, dcpu_err_o,

	// SPR access
	spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// DC i/f
	qmemdmmu_err_i, qmemdmmu_tag_i, qmemdmmu_adr_o, qmemdmmu_cycstb_o, qmemdmmu_ci_o
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// CPU I/F
//
input				dc_en;
input				dmmu_en;
input				supv;
input	[aw-1:0]		dcpu_adr_i;
input				dcpu_cycstb_i;
input				dcpu_we_i;
output	[3:0]			dcpu_tag_o;
output				dcpu_err_o;

//
// SPR access
//
input				spr_cs;
input				spr_write;
input	[aw-1:0]		spr_addr;
input	[31:0]			spr_dat_i;
output	[31:0]			spr_dat_o;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// DC I/F
//
input				qmemdmmu_err_i;
input	[3:0]			qmemdmmu_tag_i;
output	[aw-1:0]		qmemdmmu_adr_o;
output				qmemdmmu_cycstb_o;
output				qmemdmmu_ci_o;

//
// Internal wires and regs
//
wire				dtlb_spr_access;
wire	[31:`OR1200_DMMU_PS]	dtlb_ppn;
wire				dtlb_hit;
wire				dtlb_uwe;
wire				dtlb_ure;
wire				dtlb_swe;
wire				dtlb_sre;
wire	[31:0]			dtlb_dat_o;
wire				dtlb_en;
wire				dtlb_ci;
wire				fault;
wire				miss;
`ifdef OR1200_NO_DMMU
`else
reg				dtlb_done;
reg	[31:`OR1200_DMMU_PS]	dcpu_vpn_r;
`endif

//
// Implemented bits inside match and translate registers
//
// dtlbwYmrX: vpn 31-10  v 0
// dtlbwYtrX: ppn 31-10  swe 9  sre 8  uwe 7  ure 6
//
// dtlb memory width:
// 19 bits for ppn
// 13 bits for vpn
// 1 bit for valid
// 4 bits for protection
// 1 bit for cache inhibit

`ifdef OR1200_NO_DMMU

//
// Put all outputs in inactive state
//
assign spr_dat_o = 32'h00000000;
assign qmemdmmu_adr_o = dcpu_adr_i;
assign dcpu_tag_o = qmemdmmu_tag_i;
assign qmemdmmu_cycstb_o = dcpu_cycstb_i;
assign dcpu_err_o = qmemdmmu_err_i;
assign qmemdmmu_ci_o = `OR1200_DMMU_CI;
`ifdef OR1200_BIST
assign mbist_so_o = mbist_si_i;
`endif

`else

//
// DTLB SPR access
//
// 0A00 - 0AFF  dtlbmr w0
// 0A00 - 0A3F  dtlbmr w0 [63:0]
//
// 0B00 - 0BFF  dtlbtr w0
// 0B00 - 0B3F  dtlbtr w0 [63:0]
//
assign dtlb_spr_access = spr_cs;

//
// Tags:
//
// OR1200_DTAG_TE - TLB miss Exception
// OR1200_DTAG_PE - Page fault Exception
//
assign dcpu_tag_o = miss ? `OR1200_DTAG_TE : fault ? `OR1200_DTAG_PE : qmemdmmu_tag_i;

//
// dcpu_err_o
//
assign dcpu_err_o = miss | fault | qmemdmmu_err_i;

//
// Assert dtlb_done one clock cycle after new address and dtlb_en must be active.
//
always @(posedge clk or posedge rst)
	if (rst)
		dtlb_done <= #1 1'b0;
	else if (dtlb_en)
		dtlb_done <= #1 dcpu_cycstb_i;
	else
		dtlb_done <= #1 1'b0;

//
// Cut transfer if something goes wrong with translation. Also delayed signals because of translation delay.
//
assign qmemdmmu_cycstb_o = (!dc_en & dmmu_en) ? ~(miss | fault) & dtlb_done & dcpu_cycstb_i : ~(miss | fault) & dcpu_cycstb_i;
//assign qmemdmmu_cycstb_o = (dmmu_en) ? ~(miss | fault) & dcpu_cycstb_i : (miss | fault) ? 1'b0 : dcpu_cycstb_i;

//
// Cache Inhibit
//
assign qmemdmmu_ci_o = dmmu_en ? dtlb_done & dtlb_ci : `OR1200_DMMU_CI;

//
// Register dcpu_adr_i's VPN for use when DMMU is not enabled but PPN is expected to come
// one clock cycle after offset part.
//
always @(posedge clk or posedge rst)
	if (rst)
		dcpu_vpn_r <= #1 {31-`OR1200_DMMU_PS{1'b0}};
	else
		dcpu_vpn_r <= #1 dcpu_adr_i[31:`OR1200_DMMU_PS];

//
// Physical address is either translated virtual address or
// simply equal when DMMU is disabled
//
// assign qmemdmmu_adr_o = dmmu_en ? {dtlb_ppn, dcpu_adr_i[`OR1200_DMMU_PS-1:0]} : {dcpu_vpn_r, dcpu_adr_i[`OR1200_DMMU_PS-1:0]};
assign qmemdmmu_adr_o = dmmu_en ? {dtlb_ppn, dcpu_adr_i[`OR1200_DMMU_PS-1:0]} : dcpu_adr_i;

//
// Output to SPRS unit
//
assign spr_dat_o = dtlb_spr_access ? dtlb_dat_o : 32'h00000000;

//
// Page fault exception logic
//
assign fault = dtlb_done &
			(  (!dcpu_we_i & !supv & !dtlb_ure) // Load in user mode not enabled
			|| (!dcpu_we_i & supv & !dtlb_sre) // Load in supv mode not enabled
			|| (dcpu_we_i & !supv & !dtlb_uwe) // Store in user mode not enabled
			|| (dcpu_we_i & supv & !dtlb_swe) ); // Store in supv mode not enabled

//
// TLB Miss exception logic
//
assign miss = dtlb_done & !dtlb_hit;

//
// DTLB Enable
//
assign dtlb_en = dmmu_en & dcpu_cycstb_i;

//
// Instantiation of DTLB
//
or1200_dmmu_tlb or1200_dmmu_tlb(
	// Rst and clk
        .clk(clk),
	.rst(rst),

        // I/F for translation
        .tlb_en(dtlb_en),
	.vaddr(dcpu_adr_i),
	.hit(dtlb_hit),
	.ppn(dtlb_ppn),
	.uwe(dtlb_uwe),
	.ure(dtlb_ure),
	.swe(dtlb_swe),
	.sre(dtlb_sre),
	.ci(dtlb_ci),

`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_si_i),
	.mbist_so_o(mbist_so_o),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif

        // SPR access
        .spr_cs(dtlb_spr_access),
	.spr_write(spr_write),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_i),
	.spr_dat_o(dtlb_dat_o)
);

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Double-Port Synchronous RAM                         ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/generic_memories/     ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common double-port             ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides behavioral model of generic      ////
////  double-port synchronous RAM.                                ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Michael Unneback, unneback@opencores.org              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_dpram
  (
   // Generic synchronous double-port RAM interface
   clk_a, ce_a, addr_a, do_a,
   clk_b, ce_b, we_b, addr_b, di_b
   );
   
   //
   // Default address and data buses width
   //
   parameter aw = 5;
   parameter dw = 32;
   
   //
   // Generic synchronous double-port RAM interface
   //
   input			clk_a;	// Clock
   input			ce_a;	// Chip enable input
   input [aw-1:0] 		addr_a;	// address bus inputs
   output [dw-1:0] 		do_a;	// output data bus
   input			clk_b;	// Clock
   input			ce_b;	// Chip enable input
   input			we_b;	// Write enable input
   input [aw-1:0] 		addr_b;	// address bus inputs
   input [dw-1:0] 		di_b;	// input data bus
   
   //
   // Internal wires and registers
   //
   
   //
   // Generic double-port synchronous RAM model
   //
   
   //
   // Generic RAM's registers and wires
   //
   reg [dw-1:0] 		mem [(1<<aw)-1:0];	// RAM content
   reg [aw-1:0] 		addr_a_reg;		// RAM address registered
   
   //
   // Data output drivers
   //
   //assign do_a = (oe_a) ? mem[addr_a_reg] : {dw{1'b0}};
   assign do_a = mem[addr_a_reg];
   
   
   //
   // RAM read
   //
   always @(posedge clk_a)
     if (ce_a)
       addr_a_reg <= #1 addr_a;
   
   //
   // RAM write
   //
   always @(posedge clk_b)
     if (ce_b & we_b)
       mem[addr_b] <= #1 di_b;
   
endmodule // or1200_dpram
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Debug Unit                                         ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Basic OR1200 debug unit.                                    ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_du.v,v $
// Revision 1.12  2005/10/19 11:37:56  jcastillo
// Added support for RAMB16 Xilinx4/Spartan3 primitives
//
// Revision 1.11  2005/01/07 09:35:08  andreje
// du_hwbkpt disabled when debug unit not implemented
//
// Revision 1.10  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.9.4.4  2004/02/11 01:40:11  lampret
// preliminary HW breakpoints support in debug unit (by default disabled). To enable define OR1200_DU_HWBKPTS.
//
// Revision 1.9.4.3  2004/01/18 10:08:00  simons
// Error fixed.
//
// Revision 1.9.4.2  2004/01/17 21:14:14  simons
// Errors fixed.
//
// Revision 1.9.4.1  2004/01/15 06:46:38  markom
// interface to debug changed; no more opselect; stb-ack protocol
//
// Revision 1.9  2003/01/22 03:23:47  lampret
// Updated sensitivity list for trace buffer [only relevant for Xilinx FPGAs]
//
// Revision 1.8  2002/09/08 19:31:52  lampret
// Fixed a typo, reported by Taylor Su.
//
// Revision 1.7  2002/07/14 22:17:17  lampret
// Added simple trace buffer [only for Xilinx Virtex target]. Fixed instruction fetch abort when new exception is recognized.
//
// Revision 1.6  2002/03/14 00:30:24  lampret
// Added alternative for critical path in DU.
//
// Revision 1.5  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.4  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.3  2002/01/18 07:56:00  lampret
// No more low/high priority interrupts (PICPR removed). Added tick timer exception. Added exception prefix (SR[EPH]). Fixed single-step bug whenreading NPC.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.12  2001/11/30 18:58:00  simons
// Trap insn couses break after exits ex_insn.
//
// Revision 1.11  2001/11/23 08:38:51  lampret
// Changed DSR/DRR behavior and exception detection.
//
// Revision 1.10  2001/11/20 21:25:44  lampret
// Fixed dbg_is_o assignment width.
//
// Revision 1.9  2001/11/20 18:46:14  simons
// Break point bug fixed
//
// Revision 1.8  2001/11/18 08:36:28  lampret
// For GDB changed single stepping and disabled trap exception.
//
// Revision 1.7  2001/10/21 18:09:53  lampret
// Fixed sensitivity list.
//
// Revision 1.6  2001/10/14 13:12:09  lampret
// MP3 version.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

//
// Debug unit
//

module or1200_du(
	// RISC Internal Interface
	clk, rst,
	dcpu_cycstb_i, dcpu_we_i, dcpu_adr_i, dcpu_dat_lsu,
	dcpu_dat_dc, icpu_cycstb_i,
	ex_freeze, branch_op, ex_insn, id_pc,
	spr_dat_npc, rf_dataw,
	du_dsr, du_stall, du_addr, du_dat_i, du_dat_o,
	du_read, du_write, du_except, du_hwbkpt,
	spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o,

	// External Debug Interface
	dbg_stall_i, dbg_ewt_i,	dbg_lss_o, dbg_is_o, dbg_wp_o, dbg_bp_o,
	dbg_stb_i, dbg_we_i, dbg_adr_i, dbg_dat_i, dbg_dat_o, dbg_ack_o
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// RISC Internal Interface
//
input				clk;		// Clock
input				rst;		// Reset
input				dcpu_cycstb_i;	// LSU status
input				dcpu_we_i;	// LSU status
input	[31:0]			dcpu_adr_i;	// LSU addr
input	[31:0]			dcpu_dat_lsu;	// LSU store data
input	[31:0]			dcpu_dat_dc;	// LSU load data
input	[`OR1200_FETCHOP_WIDTH-1:0]	icpu_cycstb_i;	// IFETCH unit status
input				ex_freeze;	// EX stage freeze
input	[`OR1200_BRANCHOP_WIDTH-1:0]	branch_op;	// Branch op
input	[dw-1:0]		ex_insn;	// EX insn
input	[31:0]			id_pc;		// insn fetch EA
input	[31:0]			spr_dat_npc;	// Next PC (for trace)
input	[31:0]			rf_dataw;	// ALU result (for trace)
output	[`OR1200_DU_DSR_WIDTH-1:0]     du_dsr;		// DSR
output				du_stall;	// Debug Unit Stall
output	[aw-1:0]		du_addr;	// Debug Unit Address
input	[dw-1:0]		du_dat_i;	// Debug Unit Data In
output	[dw-1:0]		du_dat_o;	// Debug Unit Data Out
output				du_read;	// Debug Unit Read Enable
output				du_write;	// Debug Unit Write Enable
input	[12:0]			du_except;	// Exception masked by DSR
output				du_hwbkpt;	// Cause trap exception (HW Breakpoints)
input				spr_cs;		// SPR Chip Select
input				spr_write;	// SPR Read/Write
input	[aw-1:0]		spr_addr;	// SPR Address
input	[dw-1:0]		spr_dat_i;	// SPR Data Input
output	[dw-1:0]		spr_dat_o;	// SPR Data Output

//
// External Debug Interface
//
input			dbg_stall_i;	// External Stall Input
input			dbg_ewt_i;	// External Watchpoint Trigger Input
output	[3:0]		dbg_lss_o;	// External Load/Store Unit Status
output	[1:0]		dbg_is_o;	// External Insn Fetch Status
output	[10:0]		dbg_wp_o;	// Watchpoints Outputs
output			dbg_bp_o;	// Breakpoint Output
input			dbg_stb_i;      // External Address/Data Strobe
input			dbg_we_i;       // External Write Enable
input	[aw-1:0]	dbg_adr_i;	// External Address Input
input	[dw-1:0]	dbg_dat_i;	// External Data Input
output	[dw-1:0]	dbg_dat_o;	// External Data Output
output			dbg_ack_o;	// External Data Acknowledge (not WB compatible)
reg		[dw-1:0]	dbg_dat_o;  // External Data Output
reg					dbg_ack_o;  // External Data Acknowledge (not WB compatible)


//
// Some connections go directly from the CPU through DU to Debug I/F
//
`ifdef OR1200_DU_STATUS_UNIMPLEMENTED
assign dbg_lss_o = 4'b0000;

reg	[1:0]			dbg_is_o;
//
// Show insn activity (temp, must be removed)
//
always @(posedge clk or posedge rst)
	if (rst)
		dbg_is_o <= #1 2'b00;
	else if (!ex_freeze &
		~((ex_insn[31:26] == `OR1200_OR32_NOP) & ex_insn[16]))
		dbg_is_o <= #1 ~dbg_is_o;
`ifdef UNUSED
assign dbg_is_o = 2'b00;
`endif
`else
assign dbg_lss_o = dcpu_cycstb_i ? {dcpu_we_i, 3'b000} : 4'b0000;
assign dbg_is_o = {1'b0, icpu_cycstb_i};
`endif
assign dbg_wp_o = 11'b000_0000_0000;

//
// Some connections go directly from Debug I/F through DU to the CPU
//
assign du_stall = dbg_stall_i;
assign du_addr = dbg_adr_i;
assign du_dat_o = dbg_dat_i;
assign du_read = dbg_stb_i && !dbg_we_i;
assign du_write = dbg_stb_i && dbg_we_i;

reg					dbg_ack;
//
// Generate acknowledge -- just delay stb signal
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		dbg_ack   <= #1 1'b0;
		dbg_ack_o <= #1 1'b0;
    end
	else begin
        dbg_ack   <= #1 dbg_stb_i;
        dbg_ack_o <= #1 dbg_ack;
    end
end

// 
// Register data output
//
always @(posedge clk)
    dbg_dat_o <= #1 du_dat_i;

`ifdef OR1200_DU_IMPLEMENTED

//
// Debug Mode Register 1
//
`ifdef OR1200_DU_DMR1
reg	[24:0]			dmr1;		// DMR1 implemented
`else
wire	[24:0]			dmr1;		// DMR1 not implemented
`endif

//
// Debug Mode Register 2
//
`ifdef OR1200_DU_DMR2
reg	[23:0]			dmr2;		// DMR2 implemented
`else
wire	[23:0]			dmr2;		// DMR2 not implemented
`endif

//
// Debug Stop Register
//
`ifdef OR1200_DU_DSR
reg	[`OR1200_DU_DSR_WIDTH-1:0]	dsr;		// DSR implemented
`else
wire	[`OR1200_DU_DSR_WIDTH-1:0]	dsr;		// DSR not implemented
`endif

//
// Debug Reason Register
//
`ifdef OR1200_DU_DRR
reg	[13:0]			drr;		// DRR implemented
`else
wire	[13:0]			drr;		// DRR not implemented
`endif

//
// Debug Value Register N
//
`ifdef OR1200_DU_DVR0
reg	[31:0]			dvr0;
`else
wire	[31:0]			dvr0;
`endif

//
// Debug Value Register N
//
`ifdef OR1200_DU_DVR1
reg	[31:0]			dvr1;
`else
wire	[31:0]			dvr1;
`endif

//
// Debug Value Register N
//
`ifdef OR1200_DU_DVR2
reg	[31:0]			dvr2;
`else
wire	[31:0]			dvr2;
`endif

//
// Debug Value Register N
//
`ifdef OR1200_DU_DVR3
reg	[31:0]			dvr3;
`else
wire	[31:0]			dvr3;
`endif

//
// Debug Value Register N
//
`ifdef OR1200_DU_DVR4
reg	[31:0]			dvr4;
`else
wire	[31:0]			dvr4;
`endif

//
// Debug Value Register N
//
`ifdef OR1200_DU_DVR5
reg	[31:0]			dvr5;
`else
wire	[31:0]			dvr5;
`endif

//
// Debug Value Register N
//
`ifdef OR1200_DU_DVR6
reg	[31:0]			dvr6;
`else
wire	[31:0]			dvr6;
`endif

//
// Debug Value Register N
//
`ifdef OR1200_DU_DVR7
reg	[31:0]			dvr7;
`else
wire	[31:0]			dvr7;
`endif

//
// Debug Control Register N
//
`ifdef OR1200_DU_DCR0
reg	[7:0]			dcr0;
`else
wire	[7:0]			dcr0;
`endif

//
// Debug Control Register N
//
`ifdef OR1200_DU_DCR1
reg	[7:0]			dcr1;
`else
wire	[7:0]			dcr1;
`endif

//
// Debug Control Register N
//
`ifdef OR1200_DU_DCR2
reg	[7:0]			dcr2;
`else
wire	[7:0]			dcr2;
`endif

//
// Debug Control Register N
//
`ifdef OR1200_DU_DCR3
reg	[7:0]			dcr3;
`else
wire	[7:0]			dcr3;
`endif

//
// Debug Control Register N
//
`ifdef OR1200_DU_DCR4
reg	[7:0]			dcr4;
`else
wire	[7:0]			dcr4;
`endif

//
// Debug Control Register N
//
`ifdef OR1200_DU_DCR5
reg	[7:0]			dcr5;
`else
wire	[7:0]			dcr5;
`endif

//
// Debug Control Register N
//
`ifdef OR1200_DU_DCR6
reg	[7:0]			dcr6;
`else
wire	[7:0]			dcr6;
`endif

//
// Debug Control Register N
//
`ifdef OR1200_DU_DCR7
reg	[7:0]			dcr7;
`else
wire	[7:0]			dcr7;
`endif

//
// Debug Watchpoint Counter Register 0
//
`ifdef OR1200_DU_DWCR0
reg	[31:0]			dwcr0;
`else
wire	[31:0]			dwcr0;
`endif

//
// Debug Watchpoint Counter Register 1
//
`ifdef OR1200_DU_DWCR1
reg	[31:0]			dwcr1;
`else
wire	[31:0]			dwcr1;
`endif

//
// Internal wires
//
wire				dmr1_sel; 	// DMR1 select
wire				dmr2_sel; 	// DMR2 select
wire				dsr_sel; 	// DSR select
wire				drr_sel; 	// DRR select
wire				dvr0_sel,
				dvr1_sel,
				dvr2_sel,
				dvr3_sel,
				dvr4_sel,
				dvr5_sel,
				dvr6_sel,
				dvr7_sel; 	// DVR selects
wire				dcr0_sel,
				dcr1_sel,
				dcr2_sel,
				dcr3_sel,
				dcr4_sel,
				dcr5_sel,
				dcr6_sel,
				dcr7_sel; 	// DCR selects
wire				dwcr0_sel,
				dwcr1_sel; 	// DWCR selects
reg				dbg_bp_r;
`ifdef OR1200_DU_HWBKPTS
reg	[31:0]			match_cond0_ct;
reg	[31:0]			match_cond1_ct;
reg	[31:0]			match_cond2_ct;
reg	[31:0]			match_cond3_ct;
reg	[31:0]			match_cond4_ct;
reg	[31:0]			match_cond5_ct;
reg	[31:0]			match_cond6_ct;
reg	[31:0]			match_cond7_ct;
reg				match_cond0_stb;
reg				match_cond1_stb;
reg				match_cond2_stb;
reg				match_cond3_stb;
reg				match_cond4_stb;
reg				match_cond5_stb;
reg				match_cond6_stb;
reg				match_cond7_stb;
reg				match0;
reg				match1;
reg				match2;
reg				match3;
reg				match4;
reg				match5;
reg				match6;
reg				match7;
reg				wpcntr0_match;
reg				wpcntr1_match;
reg				incr_wpcntr0;
reg				incr_wpcntr1;
reg	[10:0]			wp;
`endif
wire				du_hwbkpt;
`ifdef OR1200_DU_READREGS
reg	[31:0]			spr_dat_o;
`endif
reg	[13:0]			except_stop;	// Exceptions that stop because of DSR
`ifdef OR1200_DU_TB_IMPLEMENTED
wire				tb_enw;
reg	[7:0]			tb_wadr;
reg [31:0]			tb_timstmp;
`endif
wire	[31:0]			tbia_dat_o;
wire	[31:0]			tbim_dat_o;
wire	[31:0]			tbar_dat_o;
wire	[31:0]			tbts_dat_o;

//
// DU registers address decoder
//
`ifdef OR1200_DU_DMR1
assign dmr1_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DMR1));
`endif
`ifdef OR1200_DU_DMR2
assign dmr2_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DMR2));
`endif
`ifdef OR1200_DU_DSR
assign dsr_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DSR));
`endif
`ifdef OR1200_DU_DRR
assign drr_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DRR));
`endif
`ifdef OR1200_DU_DVR0
assign dvr0_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DVR0));
`endif
`ifdef OR1200_DU_DVR1
assign dvr1_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DVR1));
`endif
`ifdef OR1200_DU_DVR2
assign dvr2_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DVR2));
`endif
`ifdef OR1200_DU_DVR3
assign dvr3_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DVR3));
`endif
`ifdef OR1200_DU_DVR4
assign dvr4_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DVR4));
`endif
`ifdef OR1200_DU_DVR5
assign dvr5_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DVR5));
`endif
`ifdef OR1200_DU_DVR6
assign dvr6_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DVR6));
`endif
`ifdef OR1200_DU_DVR7
assign dvr7_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DVR7));
`endif
`ifdef OR1200_DU_DCR0
assign dcr0_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DCR0));
`endif
`ifdef OR1200_DU_DCR1
assign dcr1_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DCR1));
`endif
`ifdef OR1200_DU_DCR2
assign dcr2_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DCR2));
`endif
`ifdef OR1200_DU_DCR3
assign dcr3_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DCR3));
`endif
`ifdef OR1200_DU_DCR4
assign dcr4_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DCR4));
`endif
`ifdef OR1200_DU_DCR5
assign dcr5_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DCR5));
`endif
`ifdef OR1200_DU_DCR6
assign dcr6_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DCR6));
`endif
`ifdef OR1200_DU_DCR7
assign dcr7_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DCR7));
`endif
`ifdef OR1200_DU_DWCR0
assign dwcr0_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DWCR0));
`endif
`ifdef OR1200_DU_DWCR1
assign dwcr1_sel = (spr_cs && (spr_addr[`OR1200_DUOFS_BITS] == `OR1200_DU_DWCR1));
`endif

//
// Decode started exception
//
always @(du_except) begin
	except_stop = 14'b0000_0000_0000;
	casex (du_except)
		13'b1_xxxx_xxxx_xxxx:
			except_stop[`OR1200_DU_DRR_TTE] = 1'b1;
		13'b0_1xxx_xxxx_xxxx: begin
			except_stop[`OR1200_DU_DRR_IE] = 1'b1;
		end
		13'b0_01xx_xxxx_xxxx: begin
			except_stop[`OR1200_DU_DRR_IME] = 1'b1;
		end
		13'b0_001x_xxxx_xxxx:
			except_stop[`OR1200_DU_DRR_IPFE] = 1'b1;
		13'b0_0001_xxxx_xxxx: begin
			except_stop[`OR1200_DU_DRR_BUSEE] = 1'b1;
		end
		13'b0_0000_1xxx_xxxx:
			except_stop[`OR1200_DU_DRR_IIE] = 1'b1;
		13'b0_0000_01xx_xxxx: begin
			except_stop[`OR1200_DU_DRR_AE] = 1'b1;
		end
		13'b0_0000_001x_xxxx: begin
			except_stop[`OR1200_DU_DRR_DME] = 1'b1;
		end
		13'b0_0000_0001_xxxx:
			except_stop[`OR1200_DU_DRR_DPFE] = 1'b1;
		13'b0_0000_0000_1xxx:
			except_stop[`OR1200_DU_DRR_BUSEE] = 1'b1;
		13'b0_0000_0000_01xx: begin
			except_stop[`OR1200_DU_DRR_RE] = 1'b1;
		end
		13'b0_0000_0000_001x: begin
			except_stop[`OR1200_DU_DRR_TE] = 1'b1;
		end
		13'b0_0000_0000_0001:
			except_stop[`OR1200_DU_DRR_SCE] = 1'b1;
		default:
			except_stop = 14'b0000_0000_0000;
	endcase
end

//
// dbg_bp_o is registered
//
assign dbg_bp_o = dbg_bp_r;

//
// Breakpoint activation register
//
always @(posedge clk or posedge rst)
	if (rst)
		dbg_bp_r <= #1 1'b0;
	else if (!ex_freeze)
		dbg_bp_r <= #1 |except_stop
`ifdef OR1200_DU_DMR1_ST
                        | ~((ex_insn[31:26] == `OR1200_OR32_NOP) & ex_insn[16]) & dmr1[`OR1200_DU_DMR1_ST]
`endif
`ifdef OR1200_DU_DMR1_BT
                        | (branch_op != `OR1200_BRANCHOP_NOP) & (branch_op != `OR1200_BRANCHOP_RFE) & dmr1[`OR1200_DU_DMR1_BT]
`endif
			;
        else
                dbg_bp_r <= #1 |except_stop;

//
// Write to DMR1
//
`ifdef OR1200_DU_DMR1
always @(posedge clk or posedge rst)
	if (rst)
		dmr1 <= 25'h000_0000;
	else if (dmr1_sel && spr_write)
`ifdef OR1200_DU_HWBKPTS
		dmr1 <= #1 spr_dat_i[24:0];
`else
		dmr1 <= #1 {1'b0, spr_dat_i[23:22], 22'h00_0000};
`endif
`else
assign dmr1 = 25'h000_0000;
`endif

//
// Write to DMR2
//
`ifdef OR1200_DU_DMR2
always @(posedge clk or posedge rst)
	if (rst)
		dmr2 <= 24'h00_0000;
	else if (dmr2_sel && spr_write)
		dmr2 <= #1 spr_dat_i[23:0];
`else
assign dmr2 = 24'h00_0000;
`endif

//
// Write to DSR
//
`ifdef OR1200_DU_DSR
always @(posedge clk or posedge rst)
	if (rst)
		dsr <= {`OR1200_DU_DSR_WIDTH{1'b0}};
	else if (dsr_sel && spr_write)
		dsr <= #1 spr_dat_i[`OR1200_DU_DSR_WIDTH-1:0];
`else
assign dsr = {`OR1200_DU_DSR_WIDTH{1'b0}};
`endif

//
// Write to DRR
//
`ifdef OR1200_DU_DRR
always @(posedge clk or posedge rst)
	if (rst)
		drr <= 14'b0;
	else if (drr_sel && spr_write)
		drr <= #1 spr_dat_i[13:0];
	else
		drr <= #1 drr | except_stop;
`else
assign drr = 14'b0;
`endif

//
// Write to DVR0
//
`ifdef OR1200_DU_DVR0
always @(posedge clk or posedge rst)
	if (rst)
		dvr0 <= 32'h0000_0000;
	else if (dvr0_sel && spr_write)
		dvr0 <= #1 spr_dat_i[31:0];
`else
assign dvr0 = 32'h0000_0000;
`endif

//
// Write to DVR1
//
`ifdef OR1200_DU_DVR1
always @(posedge clk or posedge rst)
	if (rst)
		dvr1 <= 32'h0000_0000;
	else if (dvr1_sel && spr_write)
		dvr1 <= #1 spr_dat_i[31:0];
`else
assign dvr1 = 32'h0000_0000;
`endif

//
// Write to DVR2
//
`ifdef OR1200_DU_DVR2
always @(posedge clk or posedge rst)
	if (rst)
		dvr2 <= 32'h0000_0000;
	else if (dvr2_sel && spr_write)
		dvr2 <= #1 spr_dat_i[31:0];
`else
assign dvr2 = 32'h0000_0000;
`endif

//
// Write to DVR3
//
`ifdef OR1200_DU_DVR3
always @(posedge clk or posedge rst)
	if (rst)
		dvr3 <= 32'h0000_0000;
	else if (dvr3_sel && spr_write)
		dvr3 <= #1 spr_dat_i[31:0];
`else
assign dvr3 = 32'h0000_0000;
`endif

//
// Write to DVR4
//
`ifdef OR1200_DU_DVR4
always @(posedge clk or posedge rst)
	if (rst)
		dvr4 <= 32'h0000_0000;
	else if (dvr4_sel && spr_write)
		dvr4 <= #1 spr_dat_i[31:0];
`else
assign dvr4 = 32'h0000_0000;
`endif

//
// Write to DVR5
//
`ifdef OR1200_DU_DVR5
always @(posedge clk or posedge rst)
	if (rst)
		dvr5 <= 32'h0000_0000;
	else if (dvr5_sel && spr_write)
		dvr5 <= #1 spr_dat_i[31:0];
`else
assign dvr5 = 32'h0000_0000;
`endif

//
// Write to DVR6
//
`ifdef OR1200_DU_DVR6
always @(posedge clk or posedge rst)
	if (rst)
		dvr6 <= 32'h0000_0000;
	else if (dvr6_sel && spr_write)
		dvr6 <= #1 spr_dat_i[31:0];
`else
assign dvr6 = 32'h0000_0000;
`endif

//
// Write to DVR7
//
`ifdef OR1200_DU_DVR7
always @(posedge clk or posedge rst)
	if (rst)
		dvr7 <= 32'h0000_0000;
	else if (dvr7_sel && spr_write)
		dvr7 <= #1 spr_dat_i[31:0];
`else
assign dvr7 = 32'h0000_0000;
`endif

//
// Write to DCR0
//
`ifdef OR1200_DU_DCR0
always @(posedge clk or posedge rst)
	if (rst)
		dcr0 <= 8'h00;
	else if (dcr0_sel && spr_write)
		dcr0 <= #1 spr_dat_i[7:0];
`else
assign dcr0 = 8'h00;
`endif

//
// Write to DCR1
//
`ifdef OR1200_DU_DCR1
always @(posedge clk or posedge rst)
	if (rst)
		dcr1 <= 8'h00;
	else if (dcr1_sel && spr_write)
		dcr1 <= #1 spr_dat_i[7:0];
`else
assign dcr1 = 8'h00;
`endif

//
// Write to DCR2
//
`ifdef OR1200_DU_DCR2
always @(posedge clk or posedge rst)
	if (rst)
		dcr2 <= 8'h00;
	else if (dcr2_sel && spr_write)
		dcr2 <= #1 spr_dat_i[7:0];
`else
assign dcr2 = 8'h00;
`endif

//
// Write to DCR3
//
`ifdef OR1200_DU_DCR3
always @(posedge clk or posedge rst)
	if (rst)
		dcr3 <= 8'h00;
	else if (dcr3_sel && spr_write)
		dcr3 <= #1 spr_dat_i[7:0];
`else
assign dcr3 = 8'h00;
`endif

//
// Write to DCR4
//
`ifdef OR1200_DU_DCR4
always @(posedge clk or posedge rst)
	if (rst)
		dcr4 <= 8'h00;
	else if (dcr4_sel && spr_write)
		dcr4 <= #1 spr_dat_i[7:0];
`else
assign dcr4 = 8'h00;
`endif

//
// Write to DCR5
//
`ifdef OR1200_DU_DCR5
always @(posedge clk or posedge rst)
	if (rst)
		dcr5 <= 8'h00;
	else if (dcr5_sel && spr_write)
		dcr5 <= #1 spr_dat_i[7:0];
`else
assign dcr5 = 8'h00;
`endif

//
// Write to DCR6
//
`ifdef OR1200_DU_DCR6
always @(posedge clk or posedge rst)
	if (rst)
		dcr6 <= 8'h00;
	else if (dcr6_sel && spr_write)
		dcr6 <= #1 spr_dat_i[7:0];
`else
assign dcr6 = 8'h00;
`endif

//
// Write to DCR7
//
`ifdef OR1200_DU_DCR7
always @(posedge clk or posedge rst)
	if (rst)
		dcr7 <= 8'h00;
	else if (dcr7_sel && spr_write)
		dcr7 <= #1 spr_dat_i[7:0];
`else
assign dcr7 = 8'h00;
`endif

//
// Write to DWCR0
//
`ifdef OR1200_DU_DWCR0
always @(posedge clk or posedge rst)
	if (rst)
		dwcr0 <= 32'h0000_0000;
	else if (dwcr0_sel && spr_write)
		dwcr0 <= #1 spr_dat_i[31:0];
	else if (incr_wpcntr0)
		dwcr0[`OR1200_DU_DWCR_COUNT] <= #1 dwcr0[`OR1200_DU_DWCR_COUNT] + 16'h0001;
`else
assign dwcr0 = 32'h0000_0000;
`endif

//
// Write to DWCR1
//
`ifdef OR1200_DU_DWCR1
always @(posedge clk or posedge rst)
	if (rst)
		dwcr1 <= 32'h0000_0000;
	else if (dwcr1_sel && spr_write)
		dwcr1 <= #1 spr_dat_i[31:0];
	else if (incr_wpcntr1)
		dwcr1[`OR1200_DU_DWCR_COUNT] <= #1 dwcr1[`OR1200_DU_DWCR_COUNT] + 16'h0001;
`else
assign dwcr1 = 32'h0000_0000;
`endif

//
// Read DU registers
//
`ifdef OR1200_DU_READREGS
always @(spr_addr or dsr or drr or dmr1 or dmr2
	or dvr0 or dvr1 or dvr2 or dvr3 or dvr4
	or dvr5 or dvr6 or dvr7
	or dcr0 or dcr1 or dcr2 or dcr3 or dcr4
	or dcr5 or dcr6 or dcr7
	or dwcr0 or dwcr1
`ifdef OR1200_DU_TB_IMPLEMENTED
	or tb_wadr or tbia_dat_o or tbim_dat_o
	or tbar_dat_o or tbts_dat_o
`endif
	)
	casex (spr_addr[`OR1200_DUOFS_BITS]) // synopsys parallel_case
`ifdef OR1200_DU_DVR0
		`OR1200_DU_DVR0:
			spr_dat_o = dvr0;
`endif
`ifdef OR1200_DU_DVR1
		`OR1200_DU_DVR1:
			spr_dat_o = dvr1;
`endif
`ifdef OR1200_DU_DVR2
		`OR1200_DU_DVR2:
			spr_dat_o = dvr2;
`endif
`ifdef OR1200_DU_DVR3
		`OR1200_DU_DVR3:
			spr_dat_o = dvr3;
`endif
`ifdef OR1200_DU_DVR4
		`OR1200_DU_DVR4:
			spr_dat_o = dvr4;
`endif
`ifdef OR1200_DU_DVR5
		`OR1200_DU_DVR5:
			spr_dat_o = dvr5;
`endif
`ifdef OR1200_DU_DVR6
		`OR1200_DU_DVR6:
			spr_dat_o = dvr6;
`endif
`ifdef OR1200_DU_DVR7
		`OR1200_DU_DVR7:
			spr_dat_o = dvr7;
`endif
`ifdef OR1200_DU_DCR0
		`OR1200_DU_DCR0:
			spr_dat_o = {24'h00_0000, dcr0};
`endif
`ifdef OR1200_DU_DCR1
		`OR1200_DU_DCR1:
			spr_dat_o = {24'h00_0000, dcr1};
`endif
`ifdef OR1200_DU_DCR2
		`OR1200_DU_DCR2:
			spr_dat_o = {24'h00_0000, dcr2};
`endif
`ifdef OR1200_DU_DCR3
		`OR1200_DU_DCR3:
			spr_dat_o = {24'h00_0000, dcr3};
`endif
`ifdef OR1200_DU_DCR4
		`OR1200_DU_DCR4:
			spr_dat_o = {24'h00_0000, dcr4};
`endif
`ifdef OR1200_DU_DCR5
		`OR1200_DU_DCR5:
			spr_dat_o = {24'h00_0000, dcr5};
`endif
`ifdef OR1200_DU_DCR6
		`OR1200_DU_DCR6:
			spr_dat_o = {24'h00_0000, dcr6};
`endif
`ifdef OR1200_DU_DCR7
		`OR1200_DU_DCR7:
			spr_dat_o = {24'h00_0000, dcr7};
`endif
`ifdef OR1200_DU_DMR1
		`OR1200_DU_DMR1:
			spr_dat_o = {7'h00, dmr1};
`endif
`ifdef OR1200_DU_DMR2
		`OR1200_DU_DMR2:
			spr_dat_o = {8'h00, dmr2};
`endif
`ifdef OR1200_DU_DWCR0
		`OR1200_DU_DWCR0:
			spr_dat_o = dwcr0;
`endif
`ifdef OR1200_DU_DWCR1
		`OR1200_DU_DWCR1:
			spr_dat_o = dwcr1;
`endif
`ifdef OR1200_DU_DSR
		`OR1200_DU_DSR:
			spr_dat_o = {18'b0, dsr};
`endif
`ifdef OR1200_DU_DRR
		`OR1200_DU_DRR:
			spr_dat_o = {18'b0, drr};
`endif
`ifdef OR1200_DU_TB_IMPLEMENTED
		`OR1200_DU_TBADR:
			spr_dat_o = {24'h000000, tb_wadr};
		`OR1200_DU_TBIA:
			spr_dat_o = tbia_dat_o;
		`OR1200_DU_TBIM:
			spr_dat_o = tbim_dat_o;
		`OR1200_DU_TBAR:
			spr_dat_o = tbar_dat_o;
		`OR1200_DU_TBTS:
			spr_dat_o = tbts_dat_o;
`endif
		default:
			spr_dat_o = 32'h0000_0000;
	endcase
`endif

//
// DSR alias
//
assign du_dsr = dsr;

`ifdef OR1200_DU_HWBKPTS

//
// Compare To What (Match Condition 0)
//
always @(dcr0 or id_pc or dcpu_adr_i or dcpu_dat_dc
	or dcpu_dat_lsu or dcpu_we_i)
	case (dcr0[`OR1200_DU_DCR_CT])		// synopsys parallel_case
		3'b001:	match_cond0_ct = id_pc;		// insn fetch EA
		3'b010:	match_cond0_ct = dcpu_adr_i;	// load EA
		3'b011:	match_cond0_ct = dcpu_adr_i;	// store EA
		3'b100:	match_cond0_ct = dcpu_dat_dc;	// load data
		3'b101:	match_cond0_ct = dcpu_dat_lsu;	// store data
		3'b110:	match_cond0_ct = dcpu_adr_i;	// load/store EA
		default:match_cond0_ct = dcpu_we_i ? dcpu_dat_lsu : dcpu_dat_dc;
	endcase

//
// When To Compare (Match Condition 0)
//
always @(dcr0 or dcpu_cycstb_i)
	case (dcr0[`OR1200_DU_DCR_CT]) 		// synopsys parallel_case
		3'b000:	match_cond0_stb = 1'b0;		//comparison disabled
		3'b001:	match_cond0_stb = 1'b1;		// insn fetch EA
		default:match_cond0_stb = dcpu_cycstb_i; // any load/store
	endcase

//
// Match Condition 0
//
always @(match_cond0_stb or dcr0 or dvr0 or match_cond0_ct)
	casex ({match_cond0_stb, dcr0[`OR1200_DU_DCR_CC]})
		4'b0_xxx,
		4'b1_000,
		4'b1_111: match0 = 1'b0;
		4'b1_001: match0 =
			((match_cond0_ct[31] ^ dcr0[`OR1200_DU_DCR_SC]) ==
			(dvr0[31] ^ dcr0[`OR1200_DU_DCR_SC]));
		4'b1_010: match0 = 
			((match_cond0_ct[31] ^ dcr0[`OR1200_DU_DCR_SC]) <
			(dvr0[31] ^ dcr0[`OR1200_DU_DCR_SC]));
		4'b1_011: match0 = 
			((match_cond0_ct[31] ^ dcr0[`OR1200_DU_DCR_SC]) <=
			(dvr0[31] ^ dcr0[`OR1200_DU_DCR_SC]));
		4'b1_100: match0 = 
			((match_cond0_ct[31] ^ dcr0[`OR1200_DU_DCR_SC]) >
			(dvr0[31] ^ dcr0[`OR1200_DU_DCR_SC]));
		4'b1_101: match0 = 
			((match_cond0_ct[31] ^ dcr0[`OR1200_DU_DCR_SC]) >=
			(dvr0[31] ^ dcr0[`OR1200_DU_DCR_SC]));
		4'b1_110: match0 = 
			((match_cond0_ct[31] ^ dcr0[`OR1200_DU_DCR_SC]) !=
			(dvr0[31] ^ dcr0[`OR1200_DU_DCR_SC]));
	endcase

//
// Watchpoint 0
//
always @(dmr1 or match0)
	case (dmr1[`OR1200_DU_DMR1_CW0])
		2'b00: wp[0] = match0;
		2'b01: wp[0] = match0;
		2'b10: wp[0] = match0;
		2'b11: wp[0] = 1'b0;
	endcase

//
// Compare To What (Match Condition 1)
//
always @(dcr1 or id_pc or dcpu_adr_i or dcpu_dat_dc
	or dcpu_dat_lsu or dcpu_we_i)
	case (dcr1[`OR1200_DU_DCR_CT])		// synopsys parallel_case
		3'b001:	match_cond1_ct = id_pc;		// insn fetch EA
		3'b010:	match_cond1_ct = dcpu_adr_i;	// load EA
		3'b011:	match_cond1_ct = dcpu_adr_i;	// store EA
		3'b100:	match_cond1_ct = dcpu_dat_dc;	// load data
		3'b101:	match_cond1_ct = dcpu_dat_lsu;	// store data
		3'b110:	match_cond1_ct = dcpu_adr_i;	// load/store EA
		default:match_cond1_ct = dcpu_we_i ? dcpu_dat_lsu : dcpu_dat_dc;
	endcase

//
// When To Compare (Match Condition 1)
//
always @(dcr1 or dcpu_cycstb_i)
	case (dcr1[`OR1200_DU_DCR_CT]) 		// synopsys parallel_case
		3'b000:	match_cond1_stb = 1'b0;		//comparison disabled
		3'b001:	match_cond1_stb = 1'b1;		// insn fetch EA
		default:match_cond1_stb = dcpu_cycstb_i; // any load/store
	endcase

//
// Match Condition 1
//
always @(match_cond1_stb or dcr1 or dvr1 or match_cond1_ct)
	casex ({match_cond1_stb, dcr1[`OR1200_DU_DCR_CC]})
		4'b0_xxx,
		4'b1_000,
		4'b1_111: match1 = 1'b0;
		4'b1_001: match1 =
			((match_cond1_ct[31] ^ dcr1[`OR1200_DU_DCR_SC]) ==
			(dvr1[31] ^ dcr1[`OR1200_DU_DCR_SC]));
		4'b1_010: match1 = 
			((match_cond1_ct[31] ^ dcr1[`OR1200_DU_DCR_SC]) <
			(dvr1[31] ^ dcr1[`OR1200_DU_DCR_SC]));
		4'b1_011: match1 = 
			((match_cond1_ct[31] ^ dcr1[`OR1200_DU_DCR_SC]) <=
			(dvr1[31] ^ dcr1[`OR1200_DU_DCR_SC]));
		4'b1_100: match1 = 
			((match_cond1_ct[31] ^ dcr1[`OR1200_DU_DCR_SC]) >
			(dvr1[31] ^ dcr1[`OR1200_DU_DCR_SC]));
		4'b1_101: match1 = 
			((match_cond1_ct[31] ^ dcr1[`OR1200_DU_DCR_SC]) >=
			(dvr1[31] ^ dcr1[`OR1200_DU_DCR_SC]));
		4'b1_110: match1 = 
			((match_cond1_ct[31] ^ dcr1[`OR1200_DU_DCR_SC]) !=
			(dvr1[31] ^ dcr1[`OR1200_DU_DCR_SC]));
	endcase

//
// Watchpoint 1
//
always @(dmr1 or match1 or wp)
	case (dmr1[`OR1200_DU_DMR1_CW1])
		2'b00: wp[1] = match1;
		2'b01: wp[1] = match1 & wp[0];
		2'b10: wp[1] = match1 | wp[0];
		2'b11: wp[1] = 1'b0;
	endcase

//
// Compare To What (Match Condition 2)
//
always @(dcr2 or id_pc or dcpu_adr_i or dcpu_dat_dc
	or dcpu_dat_lsu or dcpu_we_i)
	case (dcr2[`OR1200_DU_DCR_CT])		// synopsys parallel_case
		3'b001:	match_cond2_ct = id_pc;		// insn fetch EA
		3'b010:	match_cond2_ct = dcpu_adr_i;	// load EA
		3'b011:	match_cond2_ct = dcpu_adr_i;	// store EA
		3'b100:	match_cond2_ct = dcpu_dat_dc;	// load data
		3'b101:	match_cond2_ct = dcpu_dat_lsu;	// store data
		3'b110:	match_cond2_ct = dcpu_adr_i;	// load/store EA
		default:match_cond2_ct = dcpu_we_i ? dcpu_dat_lsu : dcpu_dat_dc;
	endcase

//
// When To Compare (Match Condition 2)
//
always @(dcr2 or dcpu_cycstb_i)
	case (dcr2[`OR1200_DU_DCR_CT]) 		// synopsys parallel_case
		3'b000:	match_cond2_stb = 1'b0;		//comparison disabled
		3'b001:	match_cond2_stb = 1'b1;		// insn fetch EA
		default:match_cond2_stb = dcpu_cycstb_i; // any load/store
	endcase

//
// Match Condition 2
//
always @(match_cond2_stb or dcr2 or dvr2 or match_cond2_ct)
	casex ({match_cond2_stb, dcr2[`OR1200_DU_DCR_CC]})
		4'b0_xxx,
		4'b1_000,
		4'b1_111: match2 = 1'b0;
		4'b1_001: match2 =
			((match_cond2_ct[31] ^ dcr2[`OR1200_DU_DCR_SC]) ==
			(dvr2[31] ^ dcr2[`OR1200_DU_DCR_SC]));
		4'b1_010: match2 = 
			((match_cond2_ct[31] ^ dcr2[`OR1200_DU_DCR_SC]) <
			(dvr2[31] ^ dcr2[`OR1200_DU_DCR_SC]));
		4'b1_011: match2 = 
			((match_cond2_ct[31] ^ dcr2[`OR1200_DU_DCR_SC]) <=
			(dvr2[31] ^ dcr2[`OR1200_DU_DCR_SC]));
		4'b1_100: match2 = 
			((match_cond2_ct[31] ^ dcr2[`OR1200_DU_DCR_SC]) >
			(dvr2[31] ^ dcr2[`OR1200_DU_DCR_SC]));
		4'b1_101: match2 = 
			((match_cond2_ct[31] ^ dcr2[`OR1200_DU_DCR_SC]) >=
			(dvr2[31] ^ dcr2[`OR1200_DU_DCR_SC]));
		4'b1_110: match2 = 
			((match_cond2_ct[31] ^ dcr2[`OR1200_DU_DCR_SC]) !=
			(dvr2[31] ^ dcr2[`OR1200_DU_DCR_SC]));
	endcase

//
// Watchpoint 2
//
always @(dmr1 or match2 or wp)
	case (dmr1[`OR1200_DU_DMR1_CW2])
		2'b00: wp[2] = match2;
		2'b01: wp[2] = match2 & wp[1];
		2'b10: wp[2] = match2 | wp[1];
		2'b11: wp[2] = 1'b0;
	endcase

//
// Compare To What (Match Condition 3)
//
always @(dcr3 or id_pc or dcpu_adr_i or dcpu_dat_dc
	or dcpu_dat_lsu or dcpu_we_i)
	case (dcr3[`OR1200_DU_DCR_CT])		// synopsys parallel_case
		3'b001:	match_cond3_ct = id_pc;		// insn fetch EA
		3'b010:	match_cond3_ct = dcpu_adr_i;	// load EA
		3'b011:	match_cond3_ct = dcpu_adr_i;	// store EA
		3'b100:	match_cond3_ct = dcpu_dat_dc;	// load data
		3'b101:	match_cond3_ct = dcpu_dat_lsu;	// store data
		3'b110:	match_cond3_ct = dcpu_adr_i;	// load/store EA
		default:match_cond3_ct = dcpu_we_i ? dcpu_dat_lsu : dcpu_dat_dc;
	endcase

//
// When To Compare (Match Condition 3)
//
always @(dcr3 or dcpu_cycstb_i)
	case (dcr3[`OR1200_DU_DCR_CT]) 		// synopsys parallel_case
		3'b000:	match_cond3_stb = 1'b0;		//comparison disabled
		3'b001:	match_cond3_stb = 1'b1;		// insn fetch EA
		default:match_cond3_stb = dcpu_cycstb_i; // any load/store
	endcase

//
// Match Condition 3
//
always @(match_cond3_stb or dcr3 or dvr3 or match_cond3_ct)
	casex ({match_cond3_stb, dcr3[`OR1200_DU_DCR_CC]})
		4'b0_xxx,
		4'b1_000,
		4'b1_111: match3 = 1'b0;
		4'b1_001: match3 =
			((match_cond3_ct[31] ^ dcr3[`OR1200_DU_DCR_SC]) ==
			(dvr3[31] ^ dcr3[`OR1200_DU_DCR_SC]));
		4'b1_010: match3 = 
			((match_cond3_ct[31] ^ dcr3[`OR1200_DU_DCR_SC]) <
			(dvr3[31] ^ dcr3[`OR1200_DU_DCR_SC]));
		4'b1_011: match3 = 
			((match_cond3_ct[31] ^ dcr3[`OR1200_DU_DCR_SC]) <=
			(dvr3[31] ^ dcr3[`OR1200_DU_DCR_SC]));
		4'b1_100: match3 = 
			((match_cond3_ct[31] ^ dcr3[`OR1200_DU_DCR_SC]) >
			(dvr3[31] ^ dcr3[`OR1200_DU_DCR_SC]));
		4'b1_101: match3 = 
			((match_cond3_ct[31] ^ dcr3[`OR1200_DU_DCR_SC]) >=
			(dvr3[31] ^ dcr3[`OR1200_DU_DCR_SC]));
		4'b1_110: match3 = 
			((match_cond3_ct[31] ^ dcr3[`OR1200_DU_DCR_SC]) !=
			(dvr3[31] ^ dcr3[`OR1200_DU_DCR_SC]));
	endcase

//
// Watchpoint 3
//
always @(dmr1 or match3 or wp)
	case (dmr1[`OR1200_DU_DMR1_CW3])
		2'b00: wp[3] = match3;
		2'b01: wp[3] = match3 & wp[2];
		2'b10: wp[3] = match3 | wp[2];
		2'b11: wp[3] = 1'b0;
	endcase

//
// Compare To What (Match Condition 4)
//
always @(dcr4 or id_pc or dcpu_adr_i or dcpu_dat_dc
	or dcpu_dat_lsu or dcpu_we_i)
	case (dcr4[`OR1200_DU_DCR_CT])		// synopsys parallel_case
		3'b001:	match_cond4_ct = id_pc;		// insn fetch EA
		3'b010:	match_cond4_ct = dcpu_adr_i;	// load EA
		3'b011:	match_cond4_ct = dcpu_adr_i;	// store EA
		3'b100:	match_cond4_ct = dcpu_dat_dc;	// load data
		3'b101:	match_cond4_ct = dcpu_dat_lsu;	// store data
		3'b110:	match_cond4_ct = dcpu_adr_i;	// load/store EA
		default:match_cond4_ct = dcpu_we_i ? dcpu_dat_lsu : dcpu_dat_dc;
	endcase

//
// When To Compare (Match Condition 4)
//
always @(dcr4 or dcpu_cycstb_i)
	case (dcr4[`OR1200_DU_DCR_CT]) 		// synopsys parallel_case
		3'b000:	match_cond4_stb = 1'b0;		//comparison disabled
		3'b001:	match_cond4_stb = 1'b1;		// insn fetch EA
		default:match_cond4_stb = dcpu_cycstb_i; // any load/store
	endcase

//
// Match Condition 4
//
always @(match_cond4_stb or dcr4 or dvr4 or match_cond4_ct)
	casex ({match_cond4_stb, dcr4[`OR1200_DU_DCR_CC]})
		4'b0_xxx,
		4'b1_000,
		4'b1_111: match4 = 1'b0;
		4'b1_001: match4 =
			((match_cond4_ct[31] ^ dcr4[`OR1200_DU_DCR_SC]) ==
			(dvr4[31] ^ dcr4[`OR1200_DU_DCR_SC]));
		4'b1_010: match4 = 
			((match_cond4_ct[31] ^ dcr4[`OR1200_DU_DCR_SC]) <
			(dvr4[31] ^ dcr4[`OR1200_DU_DCR_SC]));
		4'b1_011: match4 = 
			((match_cond4_ct[31] ^ dcr4[`OR1200_DU_DCR_SC]) <=
			(dvr4[31] ^ dcr4[`OR1200_DU_DCR_SC]));
		4'b1_100: match4 = 
			((match_cond4_ct[31] ^ dcr4[`OR1200_DU_DCR_SC]) >
			(dvr4[31] ^ dcr4[`OR1200_DU_DCR_SC]));
		4'b1_101: match4 = 
			((match_cond4_ct[31] ^ dcr4[`OR1200_DU_DCR_SC]) >=
			(dvr4[31] ^ dcr4[`OR1200_DU_DCR_SC]));
		4'b1_110: match4 = 
			((match_cond4_ct[31] ^ dcr4[`OR1200_DU_DCR_SC]) !=
			(dvr4[31] ^ dcr4[`OR1200_DU_DCR_SC]));
	endcase

//
// Watchpoint 4
//
always @(dmr1 or match4 or wp)
	case (dmr1[`OR1200_DU_DMR1_CW4])
		2'b00: wp[4] = match4;
		2'b01: wp[4] = match4 & wp[3];
		2'b10: wp[4] = match4 | wp[3];
		2'b11: wp[4] = 1'b0;
	endcase

//
// Compare To What (Match Condition 5)
//
always @(dcr5 or id_pc or dcpu_adr_i or dcpu_dat_dc
	or dcpu_dat_lsu or dcpu_we_i)
	case (dcr5[`OR1200_DU_DCR_CT])		// synopsys parallel_case
		3'b001:	match_cond5_ct = id_pc;		// insn fetch EA
		3'b010:	match_cond5_ct = dcpu_adr_i;	// load EA
		3'b011:	match_cond5_ct = dcpu_adr_i;	// store EA
		3'b100:	match_cond5_ct = dcpu_dat_dc;	// load data
		3'b101:	match_cond5_ct = dcpu_dat_lsu;	// store data
		3'b110:	match_cond5_ct = dcpu_adr_i;	// load/store EA
		default:match_cond5_ct = dcpu_we_i ? dcpu_dat_lsu : dcpu_dat_dc;
	endcase

//
// When To Compare (Match Condition 5)
//
always @(dcr5 or dcpu_cycstb_i)
	case (dcr5[`OR1200_DU_DCR_CT]) 		// synopsys parallel_case
		3'b000:	match_cond5_stb = 1'b0;		//comparison disabled
		3'b001:	match_cond5_stb = 1'b1;		// insn fetch EA
		default:match_cond5_stb = dcpu_cycstb_i; // any load/store
	endcase

//
// Match Condition 5
//
always @(match_cond5_stb or dcr5 or dvr5 or match_cond5_ct)
	casex ({match_cond5_stb, dcr5[`OR1200_DU_DCR_CC]})
		4'b0_xxx,
		4'b1_000,
		4'b1_111: match5 = 1'b0;
		4'b1_001: match5 =
			((match_cond5_ct[31] ^ dcr5[`OR1200_DU_DCR_SC]) ==
			(dvr5[31] ^ dcr5[`OR1200_DU_DCR_SC]));
		4'b1_010: match5 = 
			((match_cond5_ct[31] ^ dcr5[`OR1200_DU_DCR_SC]) <
			(dvr5[31] ^ dcr5[`OR1200_DU_DCR_SC]));
		4'b1_011: match5 = 
			((match_cond5_ct[31] ^ dcr5[`OR1200_DU_DCR_SC]) <=
			(dvr5[31] ^ dcr5[`OR1200_DU_DCR_SC]));
		4'b1_100: match5 = 
			((match_cond5_ct[31] ^ dcr5[`OR1200_DU_DCR_SC]) >
			(dvr5[31] ^ dcr5[`OR1200_DU_DCR_SC]));
		4'b1_101: match5 = 
			((match_cond5_ct[31] ^ dcr5[`OR1200_DU_DCR_SC]) >=
			(dvr5[31] ^ dcr5[`OR1200_DU_DCR_SC]));
		4'b1_110: match5 = 
			((match_cond5_ct[31] ^ dcr5[`OR1200_DU_DCR_SC]) !=
			(dvr5[31] ^ dcr5[`OR1200_DU_DCR_SC]));
	endcase

//
// Watchpoint 5
//
always @(dmr1 or match5 or wp)
	case (dmr1[`OR1200_DU_DMR1_CW5])
		2'b00: wp[5] = match5;
		2'b01: wp[5] = match5 & wp[4];
		2'b10: wp[5] = match5 | wp[4];
		2'b11: wp[5] = 1'b0;
	endcase

//
// Compare To What (Match Condition 6)
//
always @(dcr6 or id_pc or dcpu_adr_i or dcpu_dat_dc
	or dcpu_dat_lsu or dcpu_we_i)
	case (dcr6[`OR1200_DU_DCR_CT])		// synopsys parallel_case
		3'b001:	match_cond6_ct = id_pc;		// insn fetch EA
		3'b010:	match_cond6_ct = dcpu_adr_i;	// load EA
		3'b011:	match_cond6_ct = dcpu_adr_i;	// store EA
		3'b100:	match_cond6_ct = dcpu_dat_dc;	// load data
		3'b101:	match_cond6_ct = dcpu_dat_lsu;	// store data
		3'b110:	match_cond6_ct = dcpu_adr_i;	// load/store EA
		default:match_cond6_ct = dcpu_we_i ? dcpu_dat_lsu : dcpu_dat_dc;
	endcase

//
// When To Compare (Match Condition 6)
//
always @(dcr6 or dcpu_cycstb_i)
	case (dcr6[`OR1200_DU_DCR_CT]) 		// synopsys parallel_case
		3'b000:	match_cond6_stb = 1'b0;		//comparison disabled
		3'b001:	match_cond6_stb = 1'b1;		// insn fetch EA
		default:match_cond6_stb = dcpu_cycstb_i; // any load/store
	endcase

//
// Match Condition 6
//
always @(match_cond6_stb or dcr6 or dvr6 or match_cond6_ct)
	casex ({match_cond6_stb, dcr6[`OR1200_DU_DCR_CC]})
		4'b0_xxx,
		4'b1_000,
		4'b1_111: match6 = 1'b0;
		4'b1_001: match6 =
			((match_cond6_ct[31] ^ dcr6[`OR1200_DU_DCR_SC]) ==
			(dvr6[31] ^ dcr6[`OR1200_DU_DCR_SC]));
		4'b1_010: match6 = 
			((match_cond6_ct[31] ^ dcr6[`OR1200_DU_DCR_SC]) <
			(dvr6[31] ^ dcr6[`OR1200_DU_DCR_SC]));
		4'b1_011: match6 = 
			((match_cond6_ct[31] ^ dcr6[`OR1200_DU_DCR_SC]) <=
			(dvr6[31] ^ dcr6[`OR1200_DU_DCR_SC]));
		4'b1_100: match6 = 
			((match_cond6_ct[31] ^ dcr6[`OR1200_DU_DCR_SC]) >
			(dvr6[31] ^ dcr6[`OR1200_DU_DCR_SC]));
		4'b1_101: match6 = 
			((match_cond6_ct[31] ^ dcr6[`OR1200_DU_DCR_SC]) >=
			(dvr6[31] ^ dcr6[`OR1200_DU_DCR_SC]));
		4'b1_110: match6 = 
			((match_cond6_ct[31] ^ dcr6[`OR1200_DU_DCR_SC]) !=
			(dvr6[31] ^ dcr6[`OR1200_DU_DCR_SC]));
	endcase

//
// Watchpoint 6
//
always @(dmr1 or match6 or wp)
	case (dmr1[`OR1200_DU_DMR1_CW6])
		2'b00: wp[6] = match6;
		2'b01: wp[6] = match6 & wp[5];
		2'b10: wp[6] = match6 | wp[5];
		2'b11: wp[6] = 1'b0;
	endcase

//
// Compare To What (Match Condition 7)
//
always @(dcr7 or id_pc or dcpu_adr_i or dcpu_dat_dc
	or dcpu_dat_lsu or dcpu_we_i)
	case (dcr7[`OR1200_DU_DCR_CT])		// synopsys parallel_case
		3'b001:	match_cond7_ct = id_pc;		// insn fetch EA
		3'b010:	match_cond7_ct = dcpu_adr_i;	// load EA
		3'b011:	match_cond7_ct = dcpu_adr_i;	// store EA
		3'b100:	match_cond7_ct = dcpu_dat_dc;	// load data
		3'b101:	match_cond7_ct = dcpu_dat_lsu;	// store data
		3'b110:	match_cond7_ct = dcpu_adr_i;	// load/store EA
		default:match_cond7_ct = dcpu_we_i ? dcpu_dat_lsu : dcpu_dat_dc;
	endcase

//
// When To Compare (Match Condition 7)
//
always @(dcr7 or dcpu_cycstb_i)
	case (dcr7[`OR1200_DU_DCR_CT]) 		// synopsys parallel_case
		3'b000:	match_cond7_stb = 1'b0;		//comparison disabled
		3'b001:	match_cond7_stb = 1'b1;		// insn fetch EA
		default:match_cond7_stb = dcpu_cycstb_i; // any load/store
	endcase

//
// Match Condition 7
//
always @(match_cond7_stb or dcr7 or dvr7 or match_cond7_ct)
	casex ({match_cond7_stb, dcr7[`OR1200_DU_DCR_CC]})
		4'b0_xxx,
		4'b1_000,
		4'b1_111: match7 = 1'b0;
		4'b1_001: match7 =
			((match_cond7_ct[31] ^ dcr7[`OR1200_DU_DCR_SC]) ==
			(dvr7[31] ^ dcr7[`OR1200_DU_DCR_SC]));
		4'b1_010: match7 = 
			((match_cond7_ct[31] ^ dcr7[`OR1200_DU_DCR_SC]) <
			(dvr7[31] ^ dcr7[`OR1200_DU_DCR_SC]));
		4'b1_011: match7 = 
			((match_cond7_ct[31] ^ dcr7[`OR1200_DU_DCR_SC]) <=
			(dvr7[31] ^ dcr7[`OR1200_DU_DCR_SC]));
		4'b1_100: match7 = 
			((match_cond7_ct[31] ^ dcr7[`OR1200_DU_DCR_SC]) >
			(dvr7[31] ^ dcr7[`OR1200_DU_DCR_SC]));
		4'b1_101: match7 = 
			((match_cond7_ct[31] ^ dcr7[`OR1200_DU_DCR_SC]) >=
			(dvr7[31] ^ dcr7[`OR1200_DU_DCR_SC]));
		4'b1_110: match7 = 
			((match_cond7_ct[31] ^ dcr7[`OR1200_DU_DCR_SC]) !=
			(dvr7[31] ^ dcr7[`OR1200_DU_DCR_SC]));
	endcase

//
// Watchpoint 7
//
always @(dmr1 or match7 or wp)
	case (dmr1[`OR1200_DU_DMR1_CW7])
		2'b00: wp[7] = match7;
		2'b01: wp[7] = match7 & wp[6];
		2'b10: wp[7] = match7 | wp[6];
		2'b11: wp[7] = 1'b0;
	endcase

//
// Increment Watchpoint Counter 0
//
always @(wp or dmr2)
	if (dmr2[`OR1200_DU_DMR2_WCE0])
		incr_wpcntr0 = |(wp & ~dmr2[`OR1200_DU_DMR2_AWTC]);
	else
		incr_wpcntr0 = 1'b0;

//
// Match Condition Watchpoint Counter 0
//
always @(dwcr0)
	if (dwcr0[`OR1200_DU_DWCR_MATCH] == dwcr0[`OR1200_DU_DWCR_COUNT])
		wpcntr0_match = 1'b1;
	else
		wpcntr0_match = 1'b0;


//
// Watchpoint 8
//
always @(dmr1 or wpcntr0_match or wp)
	case (dmr1[`OR1200_DU_DMR1_CW8])
		2'b00: wp[8] = wpcntr0_match;
		2'b01: wp[8] = wpcntr0_match & wp[7];
		2'b10: wp[8] = wpcntr0_match | wp[7];
		2'b11: wp[8] = 1'b0;
	endcase


//
// Increment Watchpoint Counter 1
//
always @(wp or dmr2)
	if (dmr2[`OR1200_DU_DMR2_WCE1])
		incr_wpcntr1 = |(wp & dmr2[`OR1200_DU_DMR2_AWTC]);
	else
		incr_wpcntr1 = 1'b0;

//
// Match Condition Watchpoint Counter 1
//
always @(dwcr1)
	if (dwcr1[`OR1200_DU_DWCR_MATCH] == dwcr1[`OR1200_DU_DWCR_COUNT])
		wpcntr1_match = 1'b1;
	else
		wpcntr1_match = 1'b0;

//
// Watchpoint 9
//
always @(dmr1 or wpcntr1_match or wp)
	case (dmr1[`OR1200_DU_DMR1_CW9])
		2'b00: wp[9] = wpcntr1_match;
		2'b01: wp[9] = wpcntr1_match & wp[8];
		2'b10: wp[9] = wpcntr1_match | wp[8];
		2'b11: wp[9] = 1'b0;
	endcase

//
// Watchpoint 10
//
always @(dmr1 or dbg_ewt_i or wp)
	case (dmr1[`OR1200_DU_DMR1_CW10])
		2'b00: wp[10] = dbg_ewt_i;
		2'b01: wp[10] = dbg_ewt_i & wp[9];
		2'b10: wp[10] = dbg_ewt_i | wp[9];
		2'b11: wp[10] = 1'b0;
	endcase

`endif

//
// Watchpoints can cause trap exception
//
`ifdef OR1200_DU_HWBKPTS
assign du_hwbkpt = |(wp & dmr2[`OR1200_DU_DMR2_WGB]);
`else
assign du_hwbkpt = 1'b0;
`endif

`ifdef OR1200_DU_TB_IMPLEMENTED
//
// Simple trace buffer
// (right now hardcoded for Xilinx Virtex FPGAs)
//
// Stores last 256 instruction addresses, instruction
// machine words and ALU results
//

//
// Trace buffer write enable
//
assign tb_enw = ~ex_freeze & ~((ex_insn[31:26] == `OR1200_OR32_NOP) & ex_insn[16]);

//
// Trace buffer write address pointer
//
always @(posedge clk or posedge rst)
	if (rst)
		tb_wadr <= #1 8'h00;
	else if (tb_enw)
		tb_wadr <= #1 tb_wadr + 8'd1;

//
// Free running counter (time stamp)
//
always @(posedge clk or posedge rst)
	if (rst)
		tb_timstmp <= #1 32'h00000000;
	else if (!dbg_bp_r)
		tb_timstmp <= #1 tb_timstmp + 32'd1;

//
// Trace buffer RAMs
//

or1200_dpram_256x32 tbia_ram(
	.clk_a(clk),
	.rst_a(rst),
	.addr_a(spr_addr[7:0]),
	.ce_a(1'b1),
	.oe_a(1'b1),
	.do_a(tbia_dat_o),

	.clk_b(clk),
	.rst_b(rst),
	.addr_b(tb_wadr),
	.di_b(spr_dat_npc),
	.ce_b(1'b1),
	.we_b(tb_enw)

);

or1200_dpram_256x32 tbim_ram(
	.clk_a(clk),
	.rst_a(rst),
	.addr_a(spr_addr[7:0]),
	.ce_a(1'b1),
	.oe_a(1'b1),
	.do_a(tbim_dat_o),
	
	.clk_b(clk),
	.rst_b(rst),
	.addr_b(tb_wadr),
	.di_b(ex_insn),
	.ce_b(1'b1),
	.we_b(tb_enw)
);

or1200_dpram_256x32 tbar_ram(
	.clk_a(clk),
	.rst_a(rst),
	.addr_a(spr_addr[7:0]),
	.ce_a(1'b1),
	.oe_a(1'b1),
	.do_a(tbar_dat_o),
	
	.clk_b(clk),
	.rst_b(rst),
	.addr_b(tb_wadr),
	.di_b(rf_dataw),
	.ce_b(1'b1),
	.we_b(tb_enw)
);

or1200_dpram_256x32 tbts_ram(
	.clk_a(clk),
	.rst_a(rst),
	.addr_a(spr_addr[7:0]),
	.ce_a(1'b1),
	.oe_a(1'b1),
	.do_a(tbts_dat_o),

	.clk_b(clk),
	.rst_b(rst),
	.addr_b(tb_wadr),
	.di_b(tb_timstmp),
	.ce_b(1'b1),
	.we_b(tb_enw)
);

`else

assign tbia_dat_o = 32'h0000_0000;
assign tbim_dat_o = 32'h0000_0000;
assign tbar_dat_o = 32'h0000_0000;
assign tbts_dat_o = 32'h0000_0000;

`endif	// OR1200_DU_TB_IMPLEMENTED

`else	// OR1200_DU_IMPLEMENTED

//
// When DU is not implemented, drive all outputs as would when DU is disabled
//
assign dbg_bp_o = 1'b0;
assign du_dsr = {`OR1200_DU_DSR_WIDTH{1'b0}};
assign du_hwbkpt = 1'b0;

//
// Read DU registers
//
`ifdef OR1200_DU_READREGS
assign spr_dat_o = 32'h0000_0000;
`ifdef OR1200_DU_UNUSED_ZERO
`endif
`endif

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Exception logic                                    ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Handles all OR1K exceptions inside CPU block.               ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_except.v,v $
// Revision 1.17  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.16  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.15.4.1  2004/02/11 01:40:11  lampret
// preliminary HW breakpoints support in debug unit (by default disabled). To enable define OR1200_DU_HWBKPTS.
//
// Revision 1.15  2003/04/20 22:23:57  lampret
// No functional change. Only added customization for exception vectors.
//
// Revision 1.14  2002/09/03 22:28:21  lampret
// As per Taylor Su suggestion all case blocks are full case by default and optionally (OR1200_CASE_DEFAULT) can be disabled to increase clock frequncy.
//
// Revision 1.13  2002/08/28 01:44:25  lampret
// Removed some commented RTL. Fixed SR/ESR flag bug.
//
// Revision 1.12  2002/08/22 02:16:45  lampret
// Fixed IMMU bug.
//
// Revision 1.11  2002/08/18 19:54:28  lampret
// Added store buffer.
//
// Revision 1.10  2002/07/14 22:17:17  lampret
// Added simple trace buffer [only for Xilinx Virtex target]. Fixed instruction fetch abort when new exception is recognized.
//
// Revision 1.9  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.8  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.7  2002/01/23 07:52:36  lampret
// Changed default reset values for SR and ESR to match or1ksim's. Fixed flop model in or1200_dpram_32x32 when OR1200_XILINX_RAM32X1D is defined.
//
// Revision 1.6  2002/01/18 14:21:43  lampret
// Fixed 'the NPC single-step fix'.
//
// Revision 1.5  2002/01/18 07:56:00  lampret
// No more low/high priority interrupts (PICPR removed). Added tick timer exception. Added exception prefix (SR[EPH]). Fixed single-step bug whenreading NPC.
//
// Revision 1.4  2002/01/14 21:11:50  lampret
// Changed alignment exception EPCR. Not tested yet.
//
// Revision 1.3  2002/01/14 19:09:57  lampret
// Fixed order of syscall and range exceptions.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.15  2001/11/27 23:13:11  lampret
// Fixed except_stop width and fixed EX PC for 1400444f no-ops.
//
// Revision 1.14  2001/11/23 08:38:51  lampret
// Changed DSR/DRR behavior and exception detection.
//
// Revision 1.13  2001/11/20 18:46:15  simons
// Break point bug fixed
//
// Revision 1.12  2001/11/18 09:58:28  lampret
// Fixed some l.trap typos.
//
// Revision 1.11  2001/11/18 08:36:28  lampret
// For GDB changed single stepping and disabled trap exception.
//
// Revision 1.10  2001/11/13 10:02:21  lampret
// Added 'setpc'. Renamed some signals (except_flushpipe into flushpipe etc)
//
// Revision 1.9  2001/11/10 03:43:57  lampret
// Fixed exceptions.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

`define OR1200_EXCEPTFSM_WIDTH 3
`define OR1200_EXCEPTFSM_IDLE	`OR1200_EXCEPTFSM_WIDTH'd0
`define OR1200_EXCEPTFSM_FLU1 	`OR1200_EXCEPTFSM_WIDTH'd1
`define OR1200_EXCEPTFSM_FLU2 	`OR1200_EXCEPTFSM_WIDTH'd2
`define OR1200_EXCEPTFSM_FLU3 	`OR1200_EXCEPTFSM_WIDTH'd3
`define OR1200_EXCEPTFSM_FLU4 	`OR1200_EXCEPTFSM_WIDTH'd4
`define OR1200_EXCEPTFSM_FLU5 	`OR1200_EXCEPTFSM_WIDTH'd5

//
// Exception recognition and sequencing
//

module or1200_except(
	// Clock and reset
	clk, rst, 

	// Internal i/f
	sig_ibuserr, sig_dbuserr, sig_illegal, sig_align, sig_range, sig_dtlbmiss, sig_dmmufault,
	sig_int, sig_syscall, sig_trap, sig_itlbmiss, sig_immufault, sig_tick,
	branch_taken, genpc_freeze, id_freeze, ex_freeze, wb_freeze, if_stall,
	if_pc, id_pc, lr_sav, flushpipe, extend_flush, except_type, except_start,
	except_started, except_stop, ex_void,
	spr_dat_ppc, spr_dat_npc, datain, du_dsr, epcr_we, eear_we, esr_we, pc_we, epcr, eear,
	esr, sr_we, to_sr, sr, lsu_addr, abort_ex, icpu_ack_i, icpu_err_i, dcpu_ack_i, dcpu_err_i
);

//
// I/O
//
input				clk;
input				rst;
input				sig_ibuserr;
input				sig_dbuserr;
input				sig_illegal;
input				sig_align;
input				sig_range;
input				sig_dtlbmiss;
input				sig_dmmufault;
input				sig_int;
input				sig_syscall;
input				sig_trap;
input				sig_itlbmiss;
input				sig_immufault;
input				sig_tick;
input				branch_taken;
input				genpc_freeze;
input				id_freeze;
input				ex_freeze;
input				wb_freeze;
input				if_stall;
input	[31:0]			if_pc;
output	[31:0]			id_pc;
output	[31:2]			lr_sav;
input	[31:0]			datain;
input   [`OR1200_DU_DSR_WIDTH-1:0]     du_dsr;
input				epcr_we;
input				eear_we;
input				esr_we;
input				pc_we;
output	[31:0]			epcr;
output	[31:0]			eear;
output	[`OR1200_SR_WIDTH-1:0]	esr;
input	[`OR1200_SR_WIDTH-1:0]	to_sr;
input				sr_we;
input	[`OR1200_SR_WIDTH-1:0]	sr;
input	[31:0]			lsu_addr;
output				flushpipe;
output				extend_flush;
output	[`OR1200_EXCEPT_WIDTH-1:0]	except_type;
output				except_start;
output				except_started;
output	[12:0]			except_stop;
input				ex_void;
output	[31:0]			spr_dat_ppc;
output	[31:0]			spr_dat_npc;
output				abort_ex;
input				icpu_ack_i;
input				icpu_err_i;
input				dcpu_ack_i;
input				dcpu_err_i;

//
// Internal regs and wires
//
reg	[`OR1200_EXCEPT_WIDTH-1:0]	except_type;
reg	[31:0]			id_pc;
reg	[31:0]			ex_pc;
reg	[31:0]			wb_pc;
reg	[31:0]			epcr;
reg	[31:0]			eear;
reg	[`OR1200_SR_WIDTH-1:0]		esr;
reg	[2:0]			id_exceptflags;
reg	[2:0]			ex_exceptflags;
reg	[`OR1200_EXCEPTFSM_WIDTH-1:0]	state;
reg				extend_flush;
reg				extend_flush_last;
reg				ex_dslot;
reg				delayed1_ex_dslot;
reg				delayed2_ex_dslot;
wire				except_started;
wire	[12:0]			except_trig;
wire				except_flushpipe;
reg	[2:0]			delayed_iee;
reg	[2:0]			delayed_tee;
wire				int_pending;
wire				tick_pending;

//
// Simple combinatorial logic
//
assign except_started = extend_flush & except_start;
assign lr_sav = ex_pc[31:2];
assign spr_dat_ppc = wb_pc;
assign spr_dat_npc = ex_void ? id_pc : ex_pc;
assign except_start = (except_type != `OR1200_EXCEPT_NONE) & extend_flush;
assign int_pending = sig_int & sr[`OR1200_SR_IEE] & delayed_iee[2] & ~ex_freeze & ~branch_taken & ~ex_dslot;
assign tick_pending = sig_tick & sr[`OR1200_SR_TEE] & ~ex_freeze & ~branch_taken & ~ex_dslot;
assign abort_ex = sig_dbuserr | sig_dmmufault | sig_dtlbmiss | sig_align | sig_illegal;		// Abort write into RF by load & other instructions

//
// Order defines exception detection priority
//
assign except_trig = {
			tick_pending		& ~du_dsr[`OR1200_DU_DSR_TTE],
			int_pending 		& ~du_dsr[`OR1200_DU_DSR_IE],
			ex_exceptflags[1]	& ~du_dsr[`OR1200_DU_DSR_IME],
			ex_exceptflags[0]	& ~du_dsr[`OR1200_DU_DSR_IPFE],
			ex_exceptflags[2]	& ~du_dsr[`OR1200_DU_DSR_BUSEE],
			sig_illegal		& ~du_dsr[`OR1200_DU_DSR_IIE],
			sig_align		& ~du_dsr[`OR1200_DU_DSR_AE],
			sig_dtlbmiss		& ~du_dsr[`OR1200_DU_DSR_DME],
			sig_dmmufault		& ~du_dsr[`OR1200_DU_DSR_DPFE],
			sig_dbuserr		& ~du_dsr[`OR1200_DU_DSR_BUSEE],
			sig_range		& ~du_dsr[`OR1200_DU_DSR_RE],
			sig_trap		& ~du_dsr[`OR1200_DU_DSR_TE] & ~ex_freeze,
			sig_syscall		& ~du_dsr[`OR1200_DU_DSR_SCE] & ~ex_freeze
		};
assign except_stop = {
			tick_pending		& du_dsr[`OR1200_DU_DSR_TTE],
			int_pending 		& du_dsr[`OR1200_DU_DSR_IE],
			ex_exceptflags[1]	& du_dsr[`OR1200_DU_DSR_IME],
			ex_exceptflags[0]	& du_dsr[`OR1200_DU_DSR_IPFE],
			ex_exceptflags[2]	& du_dsr[`OR1200_DU_DSR_BUSEE],
			sig_illegal		& du_dsr[`OR1200_DU_DSR_IIE],
			sig_align		& du_dsr[`OR1200_DU_DSR_AE],
			sig_dtlbmiss		& du_dsr[`OR1200_DU_DSR_DME],
			sig_dmmufault		& du_dsr[`OR1200_DU_DSR_DPFE],
			sig_dbuserr		& du_dsr[`OR1200_DU_DSR_BUSEE],
			sig_range		& du_dsr[`OR1200_DU_DSR_RE],
			sig_trap		& du_dsr[`OR1200_DU_DSR_TE] & ~ex_freeze,
			sig_syscall		& du_dsr[`OR1200_DU_DSR_SCE] & ~ex_freeze
		};

//
// PC and Exception flags pipelines
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		id_pc <= #1 32'd0;
		id_exceptflags <= #1 3'b000;
	end
	else if (flushpipe) begin
		id_pc <= #1 32'h0000_0000;
		id_exceptflags <= #1 3'b000;
	end
	else if (!id_freeze) begin
		id_pc <= #1 if_pc;
		id_exceptflags <= #1 { sig_ibuserr, sig_itlbmiss, sig_immufault };
	end
end

//
// delayed_iee
//
// SR[IEE] should not enable interrupts right away
// when it is restored with l.rfe. Instead delayed_iee
// together with SR[IEE] enables interrupts once
// pipeline is again ready.
//
always @(posedge rst or posedge clk)
	if (rst)
		delayed_iee <= #1 3'b000;
	else if (!sr[`OR1200_SR_IEE])
		delayed_iee <= #1 3'b000;
	else
		delayed_iee <= #1 {delayed_iee[1:0], 1'b1};

//
// delayed_tee
//
// SR[TEE] should not enable tick exceptions right away
// when it is restored with l.rfe. Instead delayed_tee
// together with SR[TEE] enables tick exceptions once
// pipeline is again ready.
//
always @(posedge rst or posedge clk)
	if (rst)
		delayed_tee <= #1 3'b000;
	else if (!sr[`OR1200_SR_TEE])
		delayed_tee <= #1 3'b000;
	else
		delayed_tee <= #1 {delayed_tee[1:0], 1'b1};

//
// PC and Exception flags pipelines
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		ex_dslot <= #1 1'b0;
		ex_pc <= #1 32'd0;
		ex_exceptflags <= #1 3'b000;
		delayed1_ex_dslot <= #1 1'b0;
		delayed2_ex_dslot <= #1 1'b0;
	end
	else if (flushpipe) begin
		ex_dslot <= #1 1'b0;
		ex_pc <= #1 32'h0000_0000;
		ex_exceptflags <= #1 3'b000;
		delayed1_ex_dslot <= #1 1'b0;
		delayed2_ex_dslot <= #1 1'b0;
	end
	else if (!ex_freeze & id_freeze) begin
		ex_dslot <= #1 1'b0;
		ex_pc <= #1 id_pc;
		ex_exceptflags <= #1 3'b000;
		delayed1_ex_dslot <= #1 ex_dslot;
		delayed2_ex_dslot <= #1 delayed1_ex_dslot;
	end
	else if (!ex_freeze) begin
		ex_dslot <= #1 branch_taken;
		ex_pc <= #1 id_pc;
		ex_exceptflags <= #1 id_exceptflags;
		delayed1_ex_dslot <= #1 ex_dslot;
		delayed2_ex_dslot <= #1 delayed1_ex_dslot;
	end
end

//
// PC and Exception flags pipelines
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		wb_pc <= #1 32'd0;
	end
	else if (!wb_freeze) begin
		wb_pc <= #1 ex_pc;
	end
end

//
// Flush pipeline
//
assign flushpipe = except_flushpipe | pc_we | extend_flush;

//
// We have started execution of exception handler:
//  1. Asserted for 3 clock cycles
//  2. Don't execute any instruction that is still in pipeline and is not part of exception handler
//
assign except_flushpipe = |except_trig & ~|state;

//
// Exception FSM that sequences execution of exception handler
//
// except_type signals which exception handler we start fetching in:
//  1. Asserted in next clock cycle after exception is recognized
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		state <= #1 `OR1200_EXCEPTFSM_IDLE;
		except_type <= #1 `OR1200_EXCEPT_NONE;
		extend_flush <= #1 1'b0;
		epcr <= #1 32'b0;
		eear <= #1 32'b0;
		esr <= #1 {1'b1, {`OR1200_SR_WIDTH-2{1'b0}}, 1'b1};
		extend_flush_last <= #1 1'b0;
	end
	else begin
`ifdef OR1200_CASE_DEFAULT
		case (state)	// synopsys parallel_case
`else
		case (state)	// synopsys full_case parallel_case
`endif
			`OR1200_EXCEPTFSM_IDLE:
				if (except_flushpipe) begin
					state <= #1 `OR1200_EXCEPTFSM_FLU1;
					extend_flush <= #1 1'b1;
					esr <= #1 sr_we ? to_sr : sr;
					casex (except_trig)
`ifdef OR1200_EXCEPT_TICK
						13'b1_xxxx_xxxx_xxxx: begin
							except_type <= #1 `OR1200_EXCEPT_TICK;
							epcr <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
						end
`endif
`ifdef OR1200_EXCEPT_INT
						13'b0_1xxx_xxxx_xxxx: begin
							except_type <= #1 `OR1200_EXCEPT_INT;
							epcr <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
						end
`endif
`ifdef OR1200_EXCEPT_ITLBMISS
						13'b0_01xx_xxxx_xxxx: begin
							except_type <= #1 `OR1200_EXCEPT_ITLBMISS;
//
// itlb miss exception and active ex_dslot caused wb_pc to put into eear instead of +4 address of ex_pc (or id_pc since it was equal to ex_pc?)
//							eear <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
//	mmu-icdc-O2 ex_pc only OK when no ex_dslot	eear <= #1 ex_dslot ? ex_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
//	mmu-icdc-O2 ex_pc only OK when no ex_dslot	epcr <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
							eear <= #1 ex_dslot ? ex_pc : ex_pc;
							epcr <= #1 ex_dslot ? wb_pc : ex_pc;
//							eear <= #1 ex_dslot ? ex_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
//							epcr <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
						end
`endif
`ifdef OR1200_EXCEPT_IPF
						13'b0_001x_xxxx_xxxx: begin
							except_type <= #1 `OR1200_EXCEPT_IPF;
//
// ipf exception and active ex_dslot caused wb_pc to put into eear instead of +4 address of ex_pc (or id_pc since it was equal to ex_pc?)
//							eear <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
							eear <= #1 ex_dslot ? ex_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
							epcr <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
						end
`endif
`ifdef OR1200_EXCEPT_BUSERR
						13'b0_0001_xxxx_xxxx: begin
							except_type <= #1 `OR1200_EXCEPT_BUSERR;
							eear <= #1 ex_dslot ? wb_pc : ex_pc;
							epcr <= #1 ex_dslot ? wb_pc : ex_pc;
						end
`endif
`ifdef OR1200_EXCEPT_ILLEGAL
						13'b0_0000_1xxx_xxxx: begin
							except_type <= #1 `OR1200_EXCEPT_ILLEGAL;
							eear <= #1 ex_pc;
							epcr <= #1 ex_dslot ? wb_pc : ex_pc;
						end
`endif
`ifdef OR1200_EXCEPT_ALIGN
						13'b0_0000_01xx_xxxx: begin
							except_type <= #1 `OR1200_EXCEPT_ALIGN;
							eear <= #1 lsu_addr;
							epcr <= #1 ex_dslot ? wb_pc : ex_pc;
						end
`endif
`ifdef OR1200_EXCEPT_DTLBMISS
						13'b0_0000_001x_xxxx: begin
							except_type <= #1 `OR1200_EXCEPT_DTLBMISS;
							eear <= #1 lsu_addr;
							epcr <= #1 ex_dslot ? wb_pc : ex_pc;
						end
`endif
`ifdef OR1200_EXCEPT_DPF
						13'b0_0000_0001_xxxx: begin
							except_type <= #1 `OR1200_EXCEPT_DPF;
							eear <= #1 lsu_addr;
							epcr <= #1 ex_dslot ? wb_pc : ex_pc;
						end
`endif
`ifdef OR1200_EXCEPT_BUSERR
						13'b0_0000_0000_1xxx: begin	// Data Bus Error
							except_type <= #1 `OR1200_EXCEPT_BUSERR;
							eear <= #1 lsu_addr;
							epcr <= #1 ex_dslot ? wb_pc : ex_pc;
						end
`endif
`ifdef OR1200_EXCEPT_RANGE
						13'b0_0000_0000_01xx: begin
							except_type <= #1 `OR1200_EXCEPT_RANGE;
							epcr <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
						end
`endif
`ifdef OR1200_EXCEPT_TRAP			13'b0_0000_0000_001x: begin
							except_type <= #1 `OR1200_EXCEPT_TRAP;
                            epcr <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : ex_pc;
						end
`endif
`ifdef OR1200_EXCEPT_SYSCALL
						13'b0_0000_0000_0001: begin
							except_type <= #1 `OR1200_EXCEPT_SYSCALL;
							epcr <= #1 ex_dslot ? wb_pc : delayed1_ex_dslot ? id_pc : delayed2_ex_dslot ? id_pc : id_pc;
						end
`endif
						default:
							except_type <= #1 `OR1200_EXCEPT_NONE;
					endcase
				end
				else if (pc_we) begin
					state <= #1 `OR1200_EXCEPTFSM_FLU1;
					extend_flush <= #1 1'b1;
				end
				else begin
					if (epcr_we)
						epcr <= #1 datain;
					if (eear_we)
						eear <= #1 datain;
					if (esr_we)
						esr <= #1 {1'b1, datain[`OR1200_SR_WIDTH-2:0]};
				end
			`OR1200_EXCEPTFSM_FLU1:
				if (icpu_ack_i | icpu_err_i | genpc_freeze)
					state <= #1 `OR1200_EXCEPTFSM_FLU2;
			`OR1200_EXCEPTFSM_FLU2:
`ifdef OR1200_EXCEPT_TRAP
			        if (except_type == `OR1200_EXCEPT_TRAP) begin
					state <= #1 `OR1200_EXCEPTFSM_IDLE;
					extend_flush <= #1 1'b0;
					extend_flush_last <= #1 1'b0;
					except_type <= #1 `OR1200_EXCEPT_NONE;
				end
                        	else
`endif
					state <= #1 `OR1200_EXCEPTFSM_FLU3;
			`OR1200_EXCEPTFSM_FLU3:
					begin
						state <= #1 `OR1200_EXCEPTFSM_FLU4;
					end
			`OR1200_EXCEPTFSM_FLU4: begin
					state <= #1 `OR1200_EXCEPTFSM_FLU5;
					extend_flush <= #1 1'b0;
					extend_flush_last <= #1 1'b0; // damjan
				end
`ifdef OR1200_CASE_DEFAULT
			default: begin
`else
			`OR1200_EXCEPTFSM_FLU5: begin
`endif
				if (!if_stall && !id_freeze) begin
					state <= #1 `OR1200_EXCEPTFSM_IDLE;
					except_type <= #1 `OR1200_EXCEPT_NONE;
					extend_flush_last <= #1 1'b0;
				end
			end
		endcase
	end
end

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Freeze logic                                       ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Generates all freezes and stalls inside RISC                ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_freeze.v,v $
// Revision 1.8  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.7  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.6.4.2  2003/12/05 00:09:49  lampret
// No functional change.
//
// Revision 1.6.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.6  2002/07/31 02:04:35  lampret
// MAC now follows software convention (signed multiply instead of unsigned).
//
// Revision 1.5  2002/07/14 22:17:17  lampret
// Added simple trace buffer [only for Xilinx Virtex target]. Fixed instruction fetch abort when new exception is recognized.
//
// Revision 1.4  2002/03/29 15:16:55  lampret
// Some of the warnings fixed.
//
// Revision 1.3  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.10  2001/11/13 10:02:21  lampret
// Added 'setpc'. Renamed some signals (except_flushpipe into flushpipe etc)
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/19 23:28:46  lampret
// Fixed some synthesis warnings. Configured with caches and MMUs.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

`define OR1200_NO_FREEZE	3'd0
`define OR1200_FREEZE_BYDC	3'd1
`define OR1200_FREEZE_BYMULTICYCLE	3'd2
`define OR1200_WAIT_LSU_TO_FINISH	3'd3
`define OR1200_WAIT_IC			3'd4

//
// Freeze logic (stalls CPU pipeline, ifetcher etc.)
//
module or1200_freeze(
	// Clock and reset
	clk, rst,

	// Internal i/f
	multicycle, flushpipe, extend_flush, lsu_stall, if_stall,
	lsu_unstall, du_stall, mac_stall, 
	force_dslot_fetch, abort_ex,
	genpc_freeze, if_freeze, id_freeze, ex_freeze, wb_freeze,
	icpu_ack_i, icpu_err_i
);

//
// I/O
//
input				clk;
input				rst;
input	[`OR1200_MULTICYCLE_WIDTH-1:0]	multicycle;
input				flushpipe;
input				extend_flush;
input				lsu_stall;
input				if_stall;
input				lsu_unstall;
input				force_dslot_fetch;
input				abort_ex;
input				du_stall;
input				mac_stall;
output				genpc_freeze;
output				if_freeze;
output				id_freeze;
output				ex_freeze;
output				wb_freeze;
input				icpu_ack_i;
input				icpu_err_i;

//
// Internal wires and regs
//
wire				multicycle_freeze;
reg	[`OR1200_MULTICYCLE_WIDTH-1:0]	multicycle_cnt;
reg				flushpipe_r;

//
// Pipeline freeze
//
// Rules how to create freeze signals:
// 1. Not overwriting pipeline stages:
// Freze signals at the beginning of pipeline (such as if_freeze) can be asserted more
// often than freeze signals at the of pipeline (such as wb_freeze). In other words, wb_freeze must never
// be asserted when ex_freeze is not. ex_freeze must never be asserted when id_freeze is not etc.
//
// 2. Inserting NOPs in the middle of pipeline only if supported:
// At this time, only ex_freeze (and wb_freeze) can be deassrted when id_freeze (and if_freeze) are asserted.
// This way NOP is asserted from stage ID into EX stage.
//
//assign genpc_freeze = du_stall | flushpipe_r | lsu_stall;
assign genpc_freeze = du_stall | flushpipe_r;
assign if_freeze = id_freeze | extend_flush;
//assign id_freeze = (lsu_stall | (~lsu_unstall & if_stall) | multicycle_freeze | force_dslot_fetch) & ~flushpipe | du_stall;
assign id_freeze = (lsu_stall | (~lsu_unstall & if_stall) | multicycle_freeze | force_dslot_fetch) | du_stall | mac_stall;
assign ex_freeze = wb_freeze;
//assign wb_freeze = (lsu_stall | (~lsu_unstall & if_stall) | multicycle_freeze) & ~flushpipe | du_stall | mac_stall;
assign wb_freeze = (lsu_stall | (~lsu_unstall & if_stall) | multicycle_freeze) | du_stall | mac_stall | abort_ex;

//
// registered flushpipe
//
always @(posedge clk or posedge rst)
	if (rst)
		flushpipe_r <= #1 1'b0;
	else if (icpu_ack_i | icpu_err_i)
//	else if (!if_stall)
		flushpipe_r <= #1 flushpipe;
	else if (!flushpipe)
		flushpipe_r <= #1 1'b0;
		
//
// Multicycle freeze
//
assign multicycle_freeze = |multicycle_cnt;

//
// Multicycle counter
//
always @(posedge clk or posedge rst)
	if (rst)
		multicycle_cnt <= #1 2'b00;
	else if (|multicycle_cnt)
		multicycle_cnt <= #1 multicycle_cnt - 2'd1;
	else if (|multicycle & !ex_freeze)
		multicycle_cnt <= #1 multicycle;

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's generate PC                                        ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  PC, interface to IC.                                        ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_genpc.v,v $
// Revision 1.10  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.9  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.7.4.3  2003/12/17 13:43:38  simons
// Exception prefix configuration changed.
//
// Revision 1.7.4.2  2003/12/04 23:44:31  lampret
// Static exception prefix.
//
// Revision 1.7.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.7  2003/04/20 22:23:57  lampret
// No functional change. Only added customization for exception vectors.
//
// Revision 1.6  2002/03/29 15:16:55  lampret
// Some of the warnings fixed.
//
// Revision 1.5  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.4  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.3  2002/01/18 07:56:00  lampret
// No more low/high priority interrupts (PICPR removed). Added tick timer exception. Added exception prefix (SR[EPH]). Fixed single-step bug whenreading NPC.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.10  2001/11/20 18:46:15  simons
// Break point bug fixed
//
// Revision 1.9  2001/11/18 09:58:28  lampret
// Fixed some l.trap typos.
//
// Revision 1.8  2001/11/18 08:36:28  lampret
// For GDB changed single stepping and disabled trap exception.
//
// Revision 1.7  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.6  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.1  2001/08/09 13:39:33  lampret
// Major clean-up.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_genpc(
	// Clock and reset
	clk, rst,

	// External i/f to IC
	icpu_adr_o, icpu_cycstb_o, icpu_sel_o, icpu_tag_o,
	icpu_rty_i, icpu_adr_i,

	// Internal i/f
	pre_branch_op, branch_op, except_type, except_prefix,
	branch_addrofs, lr_restor, flag, taken, except_start,
	binsn_addr, epcr, spr_dat_i, spr_pc_we, genpc_refetch,
	genpc_freeze, genpc_stop_prefetch, no_more_dslot
);

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// External i/f to IC
//
output	[31:0]			icpu_adr_o;
output				icpu_cycstb_o;
output	[3:0]			icpu_sel_o;
output	[3:0]			icpu_tag_o;
input				icpu_rty_i;
input	[31:0]			icpu_adr_i;

//
// Internal i/f
//
input   [`OR1200_BRANCHOP_WIDTH-1:0]    pre_branch_op;
input	[`OR1200_BRANCHOP_WIDTH-1:0]	branch_op;
input	[`OR1200_EXCEPT_WIDTH-1:0]	except_type;
input					except_prefix;
input	[31:2]			branch_addrofs;
input	[31:0]			lr_restor;
input				flag;
output				taken;
input				except_start;
input	[31:2]			binsn_addr;
input	[31:0]			epcr;
input	[31:0]			spr_dat_i;
input				spr_pc_we;
input				genpc_refetch;
input				genpc_stop_prefetch;
input				genpc_freeze;
input				no_more_dslot;

//
// Internal wires and regs
//
reg     [31:2]      pcreg_default;
wire    [31:0]      pcreg_boot;
reg                 pcreg_select;
reg	[31:2]			pcreg;
reg	[31:0]			pc;
reg				taken;	/* Set to in case of jump or taken branch */
reg				genpc_refetch_r;

//
// Address of insn to be fecthed
//
assign icpu_adr_o = !no_more_dslot & !except_start & !spr_pc_we & (icpu_rty_i | genpc_refetch) ? icpu_adr_i : pc;
// assign icpu_adr_o = !except_start & !spr_pc_we & (icpu_rty_i | genpc_refetch) ? icpu_adr_i : pc;

//
// Control access to IC subsystem
//
// assign icpu_cycstb_o = !genpc_freeze & !no_more_dslot;
assign icpu_cycstb_o = ~(genpc_freeze | (|pre_branch_op && !icpu_rty_i));
//assign icpu_cycstb_o = !(genpc_freeze | genpc_refetch & genpc_refetch_r);
//assign icpu_cycstb_o = !(genpc_freeze | genpc_stop_prefetch);
assign icpu_sel_o = 4'b1111;
assign icpu_tag_o = `OR1200_ITAG_NI;

//
// genpc_freeze_r
//
always @(posedge clk or posedge rst)
	if (rst)
		genpc_refetch_r <= #1 1'b0;
	else if (genpc_refetch)
		genpc_refetch_r <= #1 1'b1;
	else
		genpc_refetch_r <= #1 1'b0;

//
// Async calculation of new PC value. This value is used for addressing the IC.
//
always @(pcreg or branch_addrofs or binsn_addr or flag or branch_op or except_type
	or except_start or lr_restor or epcr or spr_pc_we or spr_dat_i or except_prefix) begin
	casex ({spr_pc_we, except_start, branch_op})	// synopsys parallel_case
		{2'b00, `OR1200_BRANCHOP_NOP}: begin
			pc = {pcreg + 30'd1, 2'b0};
			taken = 1'b0;
		end
		{2'b00, `OR1200_BRANCHOP_J}: begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
			$display("%t: BRANCHOP_J: pc <= branch_addrofs %h", $time, branch_addrofs);
// synopsys translate_on
`endif
			pc = {branch_addrofs, 2'b0};
			taken = 1'b1;
		end
		{2'b00, `OR1200_BRANCHOP_JR}: begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
			$display("%t: BRANCHOP_JR: pc <= lr_restor %h", $time, lr_restor);
// synopsys translate_on
`endif
			pc = lr_restor;
			taken = 1'b1;
		end
		{2'b00, `OR1200_BRANCHOP_BAL}: begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
			$display("%t: BRANCHOP_BAL: pc %h = binsn_addr %h + branch_addrofs %h", $time, binsn_addr + branch_addrofs, binsn_addr, branch_addrofs);
// synopsys translate_on
`endif
			pc = {binsn_addr + branch_addrofs, 2'b0};
			taken = 1'b1;
		end
		{2'b00, `OR1200_BRANCHOP_BF}:
			if (flag) begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
				$display("%t: BRANCHOP_BF: pc %h = binsn_addr %h + branch_addrofs %h", $time, binsn_addr + branch_addrofs, binsn_addr, branch_addrofs);
// synopsys translate_on
`endif
				pc = {binsn_addr + branch_addrofs, 2'b0};
				taken = 1'b1;
			end
			else begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
				$display("%t: BRANCHOP_BF: not taken", $time);
// synopsys translate_on
`endif
				pc = {pcreg + 30'd1, 2'b0};
				taken = 1'b0;
			end
		{2'b00, `OR1200_BRANCHOP_BNF}:
			if (flag) begin
				pc = {pcreg + 30'd1, 2'b0};
`ifdef OR1200_VERBOSE
// synopsys translate_off
				$display("%t: BRANCHOP_BNF: not taken", $time);
// synopsys translate_on
`endif
				taken = 1'b0;
			end
			else begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
				$display("%t: BRANCHOP_BNF: pc %h = binsn_addr %h + branch_addrofs %h", $time, binsn_addr + branch_addrofs, binsn_addr, branch_addrofs);
// synopsys translate_on
`endif
				pc = {binsn_addr + branch_addrofs, 2'b0};
				taken = 1'b1;
			end
		{2'b00, `OR1200_BRANCHOP_RFE}: begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
			$display("%t: BRANCHOP_RFE: pc <= epcr %h", $time, epcr);
// synopsys translate_on
`endif
			pc = epcr;
			taken = 1'b1;
		end
		{2'b01, 3'bxxx}: begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
			$display("Starting exception: %h.", except_type);
// synopsys translate_on
`endif
			pc = {(except_prefix ? `OR1200_EXCEPT_EPH1_P : `OR1200_EXCEPT_EPH0_P), except_type, `OR1200_EXCEPT_V};
			taken = 1'b1;
		end
		default: begin
`ifdef OR1200_VERBOSE
// synopsys translate_off
			$display("l.mtspr writing into PC: %h.", spr_dat_i);
// synopsys translate_on
`endif
			pc = spr_dat_i;
			taken = 1'b0;
		end
	endcase
end

//
// PC register
//
//
always @(posedge clk or posedge rst)
	if (rst) begin
		pcreg_default <= #1 30'd63;
        pcreg_select <= #1 1'b1;
    end
    else if (pcreg_select) begin
        pcreg_default <= #1 pcreg_boot[31:2];
        pcreg_select <= #1 1'b0;
    end
	else if (spr_pc_we) begin
		pcreg_default <= #1 spr_dat_i[31:2];
    end
	else if (no_more_dslot | except_start | !genpc_freeze & !icpu_rty_i & !genpc_refetch) begin
		pcreg_default <= #1 pc[31:2];
    end

assign  pcreg_boot = {(except_prefix ? `OR1200_EXCEPT_EPH1_P : `OR1200_EXCEPT_EPH0_P), `OR1200_EXCEPT_RESET, `OR1200_EXCEPT_V} - 1;

always @(pcreg_boot or pcreg_default or pcreg_select)
    if (pcreg_select)
        pcreg = pcreg_boot[31:2];
    else
        pcreg = pcreg_default ;

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic 32x32 multiplier                                    ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Generic 32x32 multiplier with pipeline stages.              ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_gmultp2_32x32.v,v $
// Revision 1.2  2002/07/31 02:04:35  lampret
// MAC now follows software convention (signed multiply instead of unsigned).
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.4  2001/12/04 05:02:35  lampret
// Added OR1200_GENERIC_MULTP2_32X32 and OR1200_ASIC_MULTP2_32X32
//
// Revision 1.3  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.2  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

// 32x32 multiplier, no input/output registers
// Registers inside Wallace trees every 8 full adder levels,
// with first pipeline after level 4

`ifdef OR1200_GENERIC_MULTP2_32X32

`define OR1200_W 32
`define OR1200_WW 64

module or1200_gmultp2_32x32 ( X, Y, CLK, RST, P );

input   [`OR1200_W-1:0]  X;
input   [`OR1200_W-1:0]  Y;
input           CLK;
input           RST;
output  [`OR1200_WW-1:0]  P;

reg     [`OR1200_WW-1:0]  p0;
reg     [`OR1200_WW-1:0]  p1;
integer 		  xi;
integer 		  yi;

//
// Conversion unsigned to signed
//
always @(X)
	xi <= X;

//
// Conversion unsigned to signed
//
always @(Y)
	yi <= Y;

//
// First multiply stage
//
always @(posedge CLK or posedge RST)
        if (RST)
                p0 <= `OR1200_WW'b0;
        else
                p0 <= #1 xi * yi;

//
// Second multiply stage
//
always @(posedge CLK or posedge RST)
        if (RST)
                p1 <= `OR1200_WW'b0;
        else
                p1 <= #1 p0;

assign P = p1;

endmodule

`endif
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's IC FSM                                             ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Insn cache state machine                                    ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_ic_fsm.v,v $
// Revision 1.10  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.9  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.8.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.8  2003/06/06 02:54:47  lampret
// When OR1200_NO_IMMU and OR1200_NO_IC are not both defined or undefined at the same time, results in a IC bug. Fixed.
//
// Revision 1.7  2002/03/29 15:16:55  lampret
// Some of the warnings fixed.
//
// Revision 1.6  2002/03/28 19:10:40  lampret
// Optimized cache controller FSM.
//
// Revision 1.1.1.1  2002/03/21 16:55:45  lampret
// First import of the "new" XESS XSV environment.
//
//
// Revision 1.5  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.4  2002/02/01 19:56:54  lampret
// Fixed combinational loops.
//
// Revision 1.3  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from ic.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/19 23:28:46  lampret
// Fixed some synthesis warnings. Configured with caches and MMUs.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

`define OR1200_ICFSM_IDLE	2'd0
`define OR1200_ICFSM_CFETCH	2'd1
`define OR1200_ICFSM_LREFILL3	2'd2
`define OR1200_ICFSM_IFETCH	2'd3

//
// Data cache FSM for cache line of 16 bytes (4x singleword)
//

module or1200_ic_fsm(
	// Clock and reset
	clk, rst,

	// Internal i/f to top level IC
	ic_en, icqmem_cycstb_i, icqmem_ci_i,
	tagcomp_miss, biudata_valid, biudata_error, start_addr, saved_addr,
	icram_we, biu_read, first_hit_ack, first_miss_ack, first_miss_err,
	burst, tag_we
);

//
// I/O
//
input				clk;
input				rst;
input				ic_en;
input				icqmem_cycstb_i;
input				icqmem_ci_i;
input				tagcomp_miss;
input				biudata_valid;
input				biudata_error;
input	[31:0]			start_addr;
output	[31:0]			saved_addr;
output	[3:0]			icram_we;
output				biu_read;
output				first_hit_ack;
output				first_miss_ack;
output				first_miss_err;
output				burst;
output				tag_we;

//
// Internal wires and regs
//
reg	[31:0]			saved_addr_r;
reg	[1:0]			state;
reg	[2:0]			cnt;
reg				hitmiss_eval;
reg				load;
reg				cache_inhibit;

//
// Generate of ICRAM write enables
//
assign icram_we = {4{biu_read & biudata_valid & !cache_inhibit}};
assign tag_we = biu_read & biudata_valid & !cache_inhibit;

//
// BIU read and write
//
assign biu_read = (hitmiss_eval & tagcomp_miss) | (!hitmiss_eval & load);

//assign saved_addr = hitmiss_eval ? start_addr : saved_addr_r;
assign saved_addr = saved_addr_r;

//
// Assert for cache hit first word ready
// Assert for cache miss first word stored/loaded OK
// Assert for cache miss first word stored/loaded with an error
//
assign first_hit_ack = (state == `OR1200_ICFSM_CFETCH) & hitmiss_eval & !tagcomp_miss & !cache_inhibit;
assign first_miss_ack = (state == `OR1200_ICFSM_CFETCH) & biudata_valid;
assign first_miss_err = (state == `OR1200_ICFSM_CFETCH) & biudata_error;

//
// Assert burst when doing reload of complete cache line
//
assign burst = (state == `OR1200_ICFSM_CFETCH) & tagcomp_miss & !cache_inhibit
		| (state == `OR1200_ICFSM_LREFILL3);

//
// Main IC FSM
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		state <= #1 `OR1200_ICFSM_IDLE;
		saved_addr_r <= #1 32'b0;
		hitmiss_eval <= #1 1'b0;
		load <= #1 1'b0;
		cnt <= #1 3'b000;
		cache_inhibit <= #1 1'b0;
	end
	else
	case (state)	// synopsys parallel_case
		`OR1200_ICFSM_IDLE :
			if (ic_en & icqmem_cycstb_i) begin		// fetch
				state <= #1 `OR1200_ICFSM_CFETCH;
				saved_addr_r <= #1 start_addr;
				hitmiss_eval <= #1 1'b1;
				load <= #1 1'b1;
                cache_inhibit <= #1 icqmem_ci_i;
			end
			else begin							// idle
				hitmiss_eval <= #1 1'b0;
				load <= #1 1'b0;
				cache_inhibit <= #1 1'b0;
			end
		`OR1200_ICFSM_CFETCH: begin	// fetch
			if (icqmem_cycstb_i & icqmem_ci_i)
				cache_inhibit <= #1 1'b1;
			if (hitmiss_eval)
				saved_addr_r[31:13] <= #1 start_addr[31:13];
			if ((!ic_en) ||
			    (hitmiss_eval & !icqmem_cycstb_i) ||	// fetch aborted (usually caused by IMMU)
			    (biudata_error) ||						// fetch terminated with an error
			    (cache_inhibit & biudata_valid)) begin	// fetch from cache-inhibited page
				state <= #1 `OR1200_ICFSM_IDLE;
				hitmiss_eval <= #1 1'b0;
				load <= #1 1'b0;
				cache_inhibit <= #1 1'b0;
			end
			else if (tagcomp_miss & biudata_valid) begin	// fetch missed, finish current external fetch and refill
				state <= #1 `OR1200_ICFSM_LREFILL3;
				saved_addr_r[3:2] <= #1 saved_addr_r[3:2] + 1'd1;
				hitmiss_eval <= #1 1'b0;
				cnt <= #1 `OR1200_ICLS-2;
				cache_inhibit <= #1 1'b0;
			end
			else if (!tagcomp_miss & !icqmem_ci_i) begin	// fetch hit, finish immediately
				saved_addr_r <= #1 start_addr;
				cache_inhibit <= #1 1'b0;
			end
			else if (!icqmem_cycstb_i) begin	// fetch aborted (usually caused by exception)
				state <= #1 `OR1200_ICFSM_IDLE;
				hitmiss_eval <= #1 1'b0;
				load <= #1 1'b0;
				cache_inhibit <= #1 1'b0;
			end
			else						// fetch in-progress
				hitmiss_eval <= #1 1'b0;
		end
		`OR1200_ICFSM_LREFILL3 : begin
			if (biudata_valid && (|cnt)) begin		// refill ack, more fetchs to come
				cnt <= #1 cnt - 3'd1;
				saved_addr_r[3:2] <= #1 saved_addr_r[3:2] + 1'd1;
			end
			else if (biudata_valid) begin			// last fetch of line refill
				state <= #1 `OR1200_ICFSM_IDLE;
				saved_addr_r <= #1 start_addr;
				hitmiss_eval <= #1 1'b0;
				load <= #1 1'b0;
			end
		end
		default:
			state <= #1 `OR1200_ICFSM_IDLE;
	endcase
end

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's IC RAMs                                            ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of Instruction cache data rams                ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_ic_ram.v,v $
// Revision 1.6  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.5  2004/04/08 11:00:46  simont
// Add support for 512B instruction cache.
//
// Revision 1.4  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.2.4.1  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.2  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.3  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/22 03:31:54  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_ic_ram(
	// Clock and reset
	clk, rst, 

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// Internal i/f
	addr, en, we, datain, dataout
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_ICINDX;

//
// I/O
//
input 				clk;
input				rst;
input	[aw-1:0]		addr;
input				en;
input	[3:0]			we;
input	[dw-1:0]		datain;
output	[dw-1:0]		dataout;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

`ifdef OR1200_NO_IC

//
// Insn cache not implemented
//
assign dataout = {dw{1'b0}};
`ifdef OR1200_BIST
assign mbist_so_o = mbist_si_i;
`endif

`else

//
// Instantiation of IC RAM block
//
`ifdef OR1200_IC_1W_512B
   or1200_spram #
     (
      .aw(9),
      .dw(32)
      )
`endif
`ifdef OR1200_IC_1W_4KB
   or1200_spram #
     (
      .aw(10),
      .dw(32)
      )
`endif
`ifdef OR1200_IC_1W_8KB
   or1200_spram #
     (
      .aw(11),
      .dw(32)
      )
`endif
   ic_ram0
     (
`ifdef OR1200_BIST
      // RAM BIST
      .mbist_si_i(mbist_si_i),
      .mbist_so_o(mbist_so_o),
      .mbist_ctrl_i(mbist_ctrl_i),
`endif
      .clk(clk),
      .ce(en),
      .we(we[0]),
      //.oe(1'b1),
      .addr(addr),
      .di(datain),
      .doq(dataout)
      );   
`endif

endmodule

//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's IC TAGs                                            ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instatiation of instruction cache tag rams                  ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_ic_tag.v,v $
// Revision 1.7  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.6  2004/04/08 11:00:46  simont
// Add support for 512B instruction cache.
//
// Revision 1.5  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.3.4.1  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.3  2002/10/24 22:19:04  mohor
// Signal scanb_eni renamed to scanb_en
//
// Revision 1.2  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_ic_tag(
	// Clock and reset
	clk, rst,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// Internal i/f
	addr, en, we, datain, tag_v, tag
);

parameter dw = `OR1200_ICTAG_W;
parameter aw = `OR1200_ICTAG;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// Internal i/f
//
input	[aw-1:0]		addr;
input				en;
input				we;
input	[dw-1:0]		datain;
output				tag_v;
output	[dw-2:0]		tag;

`ifdef OR1200_NO_IC

//
// Insn cache not implemented
//
assign tag = {dw-1{1'b0}};
assign tag_v = 1'b0;
`ifdef OR1200_BIST
assign mbist_so_o = mbist_si_i;
`endif

`else

//
// Instantiation of TAG RAM block
//
`ifdef OR1200_IC_1W_512B
//or1200_spram_32x24 ic_tag0(
   or1200_spram #
     (
      .aw(5),
      .dw(24)
      )
`endif
`ifdef OR1200_IC_1W_4KB
//or1200_spram_256x21 ic_tag0(
   or1200_spram #
     (
      .aw(8),
      .dw(21)
      )
`endif
`ifdef OR1200_IC_1W_8KB
//or1200_spram_512x20 ic_tag0(
   or1200_spram #
     (
      .aw(9),
      .dw(20)
      )
`endif
   ic_tag0
     (
`ifdef OR1200_BIST
      // RAM BIST
      .mbist_si_i(mbist_si_i),
      .mbist_so_o(mbist_so_o),
      .mbist_ctrl_i(mbist_ctrl_i),
`endif
      .clk(clk),
      .ce(en),
      .we(we),
      //.oe(1'b1),
      .addr(addr),
      .di(datain),
      .doq({tag, tag_v})
      );   
`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Data Cache top level                               ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of all IC blocks.                             ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_ic_top.v,v $
// Revision 1.9  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.7.4.2  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.7.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.7  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.6  2002/03/29 15:16:55  lampret
// Some of the warnings fixed.
//
// Revision 1.5  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.4  2002/02/01 19:56:54  lampret
// Fixed combinational loops.
//
// Revision 1.3  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.10  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from ic.v and ic.v. Fixed CR+LF.
//
// Revision 1.9  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.4  2001/08/13 03:36:20  lampret
// Added cfg regs. Moved all defines into one defines.v file. More cleanup.
//
// Revision 1.3  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/22 03:31:53  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

//
// Data cache
//
module or1200_ic_top(
	// Rst, clk and clock control
	clk, rst,

	// External i/f
	icbiu_dat_o, icbiu_adr_o, icbiu_cyc_o, icbiu_stb_o, icbiu_we_o, icbiu_sel_o, icbiu_cab_o,
	icbiu_dat_i, icbiu_ack_i, icbiu_err_i,

	// Internal i/f
	ic_en,
	icqmem_adr_i, icqmem_cycstb_i, icqmem_ci_i,
	icqmem_sel_i, icqmem_tag_i,
	icqmem_dat_o, icqmem_ack_o, icqmem_rty_o, icqmem_err_o, icqmem_tag_o,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// SPRs
	spr_cs, spr_write, spr_dat_i
);

parameter dw = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// External I/F
//
output	[dw-1:0]		icbiu_dat_o;
output	[31:0]			icbiu_adr_o;
output				icbiu_cyc_o;
output				icbiu_stb_o;
output				icbiu_we_o;
output	[3:0]			icbiu_sel_o;
output				icbiu_cab_o;
input	[dw-1:0]		icbiu_dat_i;
input				icbiu_ack_i;
input				icbiu_err_i;

//
// Internal I/F
//
input				ic_en;
input	[31:0]			icqmem_adr_i;
input				icqmem_cycstb_i;
input				icqmem_ci_i;
input	[3:0]			icqmem_sel_i;
input	[3:0]			icqmem_tag_i;
output	[dw-1:0]		icqmem_dat_o;
output				icqmem_ack_o;
output				icqmem_rty_o;
output				icqmem_err_o;
output	[3:0]			icqmem_tag_o;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// SPR access
//
input				spr_cs;
input				spr_write;
input	[31:0]			spr_dat_i;

//
// Internal wires and regs
//
wire				tag_v;
wire	[`OR1200_ICTAG_W-2:0]	tag;
wire	[dw-1:0]		to_icram;
wire	[dw-1:0]		from_icram;
wire	[31:0]			saved_addr;
wire	[3:0]			icram_we;
wire				ictag_we;
wire	[31:0]			ic_addr;
wire				icfsm_biu_read;
reg				tagcomp_miss;
wire	[`OR1200_ICINDXH:`OR1200_ICLS]	ictag_addr;
wire				ictag_en;
wire				ictag_v; 
wire				ic_inv;
wire				icfsm_first_hit_ack;
wire				icfsm_first_miss_ack;
wire				icfsm_first_miss_err;
wire				icfsm_burst;
wire				icfsm_tag_we;
`ifdef OR1200_BIST
//
// RAM BIST
//
wire				mbist_ram_so;
wire				mbist_tag_so;
wire				mbist_ram_si = mbist_si_i;
wire				mbist_tag_si = mbist_ram_so;
assign				mbist_so_o = mbist_tag_so;
`endif

//
// Simple assignments
//
assign icbiu_adr_o = ic_addr;
assign ic_inv = spr_cs & spr_write;
assign ictag_we = icfsm_tag_we | ic_inv;
assign ictag_addr = ic_inv ? spr_dat_i[`OR1200_ICINDXH:`OR1200_ICLS] : ic_addr[`OR1200_ICINDXH:`OR1200_ICLS];
assign ictag_en = ic_inv | ic_en;
assign ictag_v = ~ic_inv;

//
// Data to BIU is from ICRAM when IC is enabled or from LSU when
// IC is disabled
//
assign icbiu_dat_o = 32'h00000000;

//
// Bypases of the IC when IC is disabled
//
assign icbiu_cyc_o = (ic_en) ? icfsm_biu_read : icqmem_cycstb_i;
assign icbiu_stb_o = (ic_en) ? icfsm_biu_read : icqmem_cycstb_i;
assign icbiu_we_o = 1'b0;
assign icbiu_sel_o = (ic_en & icfsm_biu_read) ? 4'b1111 : icqmem_sel_i;
assign icbiu_cab_o = (ic_en) ? icfsm_burst : 1'b0;
assign icqmem_rty_o = ~icqmem_ack_o & ~icqmem_err_o;
assign icqmem_tag_o = icqmem_err_o ? `OR1200_ITAG_BE : icqmem_tag_i;

//
// CPU normal and error termination
//
assign icqmem_ack_o = ic_en ? (icfsm_first_hit_ack | icfsm_first_miss_ack) : icbiu_ack_i;
assign icqmem_err_o = ic_en ? icfsm_first_miss_err : icbiu_err_i;

//
// Select between claddr generated by IC FSM and addr[3:2] generated by LSU
//
assign ic_addr = (icfsm_biu_read) ? saved_addr : icqmem_adr_i;

//
// Select between input data generated by LSU or by BIU
//
assign to_icram = icbiu_dat_i;

//
// Select between data generated by ICRAM or passed by BIU
//
assign icqmem_dat_o = icfsm_first_miss_ack | !ic_en ? icbiu_dat_i : from_icram;

//
// Tag comparison
//
always @(tag or saved_addr or tag_v) begin
	if ((tag != saved_addr[31:`OR1200_ICTAGL]) || !tag_v)
		tagcomp_miss = 1'b1;
	else
		tagcomp_miss = 1'b0;
end

//
// Instantiation of IC Finite State Machine
//
or1200_ic_fsm or1200_ic_fsm(
	.clk(clk),
	.rst(rst),
	.ic_en(ic_en),
	.icqmem_cycstb_i(icqmem_cycstb_i),
	.icqmem_ci_i(icqmem_ci_i),
	.tagcomp_miss(tagcomp_miss),
	.biudata_valid(icbiu_ack_i),
	.biudata_error(icbiu_err_i),
	.start_addr(icqmem_adr_i),
	.saved_addr(saved_addr),
	.icram_we(icram_we),
	.biu_read(icfsm_biu_read),
	.first_hit_ack(icfsm_first_hit_ack),
	.first_miss_ack(icfsm_first_miss_ack),
	.first_miss_err(icfsm_first_miss_err),
	.burst(icfsm_burst),
	.tag_we(icfsm_tag_we)
);

//
// Instantiation of IC main memory
//
or1200_ic_ram or1200_ic_ram(
	.clk(clk),
	.rst(rst),
`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_ram_si),
	.mbist_so_o(mbist_ram_so),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif
	.addr(ic_addr[`OR1200_ICINDXH:2]),
	.en(ic_en),
	.we(icram_we),
	.datain(to_icram),
	.dataout(from_icram)
);

//
// Instantiation of IC TAG memory
//
or1200_ic_tag or1200_ic_tag(
	.clk(clk),
	.rst(rst),
`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_tag_si),
	.mbist_so_o(mbist_tag_so),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif
	.addr(ictag_addr),
	.en(ictag_en),
	.we(ictag_we),
	.datain({ic_addr[31:`OR1200_ICTAGL], ictag_v}),
	.tag_v(tag_v),
	.tag(tag)
);

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's instruction fetch                                  ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  PC, instruction fetch, interface to IC.                     ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_if.v,v $
// Revision 1.5  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.3  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.2  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.10  2001/11/20 18:46:15  simons
// Break point bug fixed
//
// Revision 1.9  2001/11/18 09:58:28  lampret
// Fixed some l.trap typos.
//
// Revision 1.8  2001/11/18 08:36:28  lampret
// For GDB changed single stepping and disabled trap exception.
//
// Revision 1.7  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.6  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.1  2001/08/09 13:39:33  lampret
// Major clean-up.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_if(
	// Clock and reset
	clk, rst,

	// External i/f to IC
	icpu_dat_i, icpu_ack_i, icpu_err_i, icpu_adr_i, icpu_tag_i,

	// Internal i/f
	if_freeze, if_insn, if_pc, flushpipe,
	if_stall, no_more_dslot, genpc_refetch, rfe,
	except_itlbmiss, except_immufault, except_ibuserr
);

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// External i/f to IC
//
input	[31:0]			icpu_dat_i;
input				icpu_ack_i;
input				icpu_err_i;
input	[31:0]			icpu_adr_i;
input	[3:0]			icpu_tag_i;

//
// Internal i/f
//
input				if_freeze;
output	[31:0]			if_insn;
output	[31:0]			if_pc;
input				flushpipe;
output				if_stall;
input				no_more_dslot;
output				genpc_refetch;
input				rfe;
output				except_itlbmiss;
output				except_immufault;
output				except_ibuserr;

//
// Internal wires and regs
//
reg	[31:0]			insn_saved;
reg	[31:0]			addr_saved;
reg				saved;

//
// IF stage insn
//
assign if_insn = no_more_dslot | rfe ? {`OR1200_OR32_NOP, 26'h041_0000} : saved ? insn_saved : icpu_err_i ? {`OR1200_OR32_NOP, 26'h041_0000} : icpu_ack_i ? icpu_dat_i : {`OR1200_OR32_NOP, 26'h061_0000};
assign if_pc = saved ? addr_saved : icpu_adr_i;
// assign if_stall = !icpu_err_i & !icpu_ack_i & !saved & !no_more_dslot;
assign if_stall = !icpu_err_i & !icpu_ack_i & !saved;
assign genpc_refetch = saved & icpu_ack_i;
assign except_itlbmiss = saved | no_more_dslot ? 1'b0 : icpu_err_i & (icpu_tag_i == `OR1200_ITAG_TE);
assign except_immufault = saved | no_more_dslot ? 1'b0 : icpu_err_i & (icpu_tag_i == `OR1200_ITAG_PE);
assign except_ibuserr = saved | no_more_dslot ? 1'b0 : icpu_err_i & (icpu_tag_i == `OR1200_ITAG_BE);

//
// Flag for saved insn/address
//
always @(posedge clk or posedge rst)
	if (rst)
		saved <= #1 1'b0;
	else if (flushpipe)
		saved <= #1 1'b0;
	else if (icpu_ack_i & if_freeze & !saved)
		saved <= #1 1'b1;
	else if (!if_freeze)
		saved <= #1 1'b0;

//
// Store fetched instruction
//
always @(posedge clk or posedge rst)
	if (rst)
		insn_saved <= #1 {`OR1200_OR32_NOP, 26'h041_0000};
	else if (flushpipe)
		insn_saved <= #1 {`OR1200_OR32_NOP, 26'h041_0000};
	else if (icpu_ack_i & if_freeze & !saved)
		insn_saved <= #1 icpu_dat_i;
	else if (!if_freeze)
		insn_saved <= #1 {`OR1200_OR32_NOP, 26'h041_0000};

//
// Store fetched instruction's address
//
always @(posedge clk or posedge rst)
	if (rst)
		addr_saved <= #1 32'h00000000;
	else if (flushpipe)
		addr_saved <= #1 32'h00000000;
	else if (icpu_ack_i & if_freeze & !saved)
		addr_saved <= #1 icpu_adr_i;
	else if (!if_freeze)
		addr_saved <= #1 icpu_adr_i;

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Instruction TLB                                    ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of ITLB.                                      ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_immu_tlb.v,v $
// Revision 1.9  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.8  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.6.4.1  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.6  2002/10/28 16:34:32  mohor
// RAMs wrong connected to the BIST scan chain.
//
// Revision 1.5  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.4  2002/08/14 06:23:50  lampret
// Disabled ITLB translation when 1) doing access to ITLB SPRs or 2) crossing page. This modification was tested only with parts of IMMU test - remaining test cases needs to be run.
//
// Revision 1.3  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.2  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

//
// Insn TLB
//

module or1200_immu_tlb(
	// Rst and clk
	clk, rst,

	// I/F for translation
	tlb_en, vaddr, hit, ppn, uxe, sxe, ci, 

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// SPR access
	spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// I/F for translation
//
input				tlb_en;
input	[aw-1:0]		vaddr;
output				hit;
output	[31:`OR1200_IMMU_PS]	ppn;
output				uxe;
output				sxe;
output				ci;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// SPR access
//
input				spr_cs;
input				spr_write;
input	[31:0]			spr_addr;
input	[31:0]			spr_dat_i;
output	[31:0]			spr_dat_o;

//
// Internal wires and regs
//
wire	[`OR1200_ITLB_TAG]	vpn;
wire				v;
wire	[`OR1200_ITLB_INDXW-1:0]	tlb_index;
wire				tlb_mr_en;
wire				tlb_mr_we;
wire	[`OR1200_ITLBMRW-1:0]	tlb_mr_ram_in;
wire	[`OR1200_ITLBMRW-1:0]	tlb_mr_ram_out;
wire				tlb_tr_en;
wire				tlb_tr_we;
wire	[`OR1200_ITLBTRW-1:0]	tlb_tr_ram_in;
wire	[`OR1200_ITLBTRW-1:0]	tlb_tr_ram_out;

// BIST
`ifdef OR1200_BIST
wire                        itlb_mr_ram_si;
wire                        itlb_mr_ram_so;
wire                        itlb_tr_ram_si;
wire                        itlb_tr_ram_so;
`endif

//
// Implemented bits inside match and translate registers
//
// itlbwYmrX: vpn 31-19  v 0
// itlbwYtrX: ppn 31-13  uxe 7  sxe 6
//
// itlb memory width:
// 19 bits for ppn
// 13 bits for vpn
// 1 bit for valid
// 2 bits for protection
// 1 bit for cache inhibit

//
// Enable for Match registers
//
assign tlb_mr_en = tlb_en | (spr_cs & !spr_addr[`OR1200_ITLB_TM_ADDR]);

//
// Write enable for Match registers
//
assign tlb_mr_we = spr_cs & spr_write & !spr_addr[`OR1200_ITLB_TM_ADDR];

//
// Enable for Translate registers
//
assign tlb_tr_en = tlb_en | (spr_cs & spr_addr[`OR1200_ITLB_TM_ADDR]);

//
// Write enable for Translate registers
//
assign tlb_tr_we = spr_cs & spr_write & spr_addr[`OR1200_ITLB_TM_ADDR];

//
// Output to SPRS unit
//
assign spr_dat_o = (!spr_write & !spr_addr[`OR1200_ITLB_TM_ADDR]) ?
            {vpn, tlb_index, {`OR1200_ITLB_TAGW-7{1'b0}}, 1'b0, 5'b00000, v} :
		(!spr_write & spr_addr[`OR1200_ITLB_TM_ADDR]) ?
			{ppn, {`OR1200_IMMU_PS-8{1'b0}}, uxe, sxe, {4{1'b0}}, ci, 1'b0} :
			32'h00000000;

//
// Assign outputs from Match registers
//
assign {vpn, v} = tlb_mr_ram_out;

//
// Assign to Match registers inputs
//
assign tlb_mr_ram_in = {spr_dat_i[`OR1200_ITLB_TAG], spr_dat_i[`OR1200_ITLBMR_V_BITS]};

//
// Assign outputs from Translate registers
//
assign {ppn, uxe, sxe, ci} = tlb_tr_ram_out;

//
// Assign to Translate registers inputs
//
assign tlb_tr_ram_in = {spr_dat_i[31:`OR1200_IMMU_PS],
			spr_dat_i[`OR1200_ITLBTR_UXE_BITS],
			spr_dat_i[`OR1200_ITLBTR_SXE_BITS],
			spr_dat_i[`OR1200_ITLBTR_CI_BITS]};

//
// Generate hit
//
assign hit = (vpn == vaddr[`OR1200_ITLB_TAG]) & v;

//
// TLB index is normally vaddr[18:13]. If it is SPR access then index is
// spr_addr[5:0].
//
assign tlb_index = spr_cs ? spr_addr[`OR1200_ITLB_INDXW-1:0] : vaddr[`OR1200_ITLB_INDX];


`ifdef OR1200_BIST
assign itlb_mr_ram_si = mbist_si_i;
assign itlb_tr_ram_si = itlb_mr_ram_so;
assign mbist_so_o = itlb_tr_ram_so;
`endif


//
// Instantiation of ITLB Match Registers
//
   or1200_spram #
     (
      .aw(6),
      .dw(14)
      )
   itlb_mr_ram
     (
      .clk(clk),
`ifdef OR1200_BIST
      // RAM BIST
      .mbist_si_i(itlb_mr_ram_si),
      .mbist_so_o(itlb_mr_ram_so),
      .mbist_ctrl_i(mbist_ctrl_i),
`endif
      .ce(tlb_mr_en),
      .we(tlb_mr_we),
      //.oe(1'b1),
      .addr(tlb_index),
      .di(tlb_mr_ram_in),
      .doq(tlb_mr_ram_out)
      );

//
// Instantiation of ITLB Translate Registers
//
   or1200_spram #
     (
      .aw(6),
      .dw(22)
      )
   itlb_tr_ram
     (
      .clk(clk),
`ifdef OR1200_BIST
      // RAM BIST
      .mbist_si_i(itlb_tr_ram_si),
      .mbist_so_o(itlb_tr_ram_so),
      .mbist_ctrl_i(mbist_ctrl_i),
`endif
      .ce(tlb_tr_en),
      .we(tlb_tr_we),
      //.oe(1'b1),
      .addr(tlb_index),
      .di(tlb_tr_ram_in),
      .doq(tlb_tr_ram_out)
      );
   
endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Instruction MMU top level                          ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of all IMMU blocks.                           ////
////                                                              ////
////  To Do:                                                      ////
////   - cache inhibit                                            ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_immu_top.v,v $
// Revision 1.15  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.14  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.12.4.2  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.12.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.12  2003/06/06 02:54:47  lampret
// When OR1200_NO_IMMU and OR1200_NO_IC are not both defined or undefined at the same time, results in a IC bug. Fixed.
//
// Revision 1.11  2002/10/17 20:04:40  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.10  2002/09/16 03:08:56  lampret
// Disabled cache inhibit atttribute.
//
// Revision 1.9  2002/08/18 19:54:17  lampret
// Added store buffer.
//
// Revision 1.8  2002/08/14 06:23:50  lampret
// Disabled ITLB translation when 1) doing access to ITLB SPRs or 2) crossing page. This modification was tested only with parts of IMMU test - remaining test cases needs to be run.
//
// Revision 1.7  2002/08/12 05:31:30  lampret
// Delayed external access at page crossing.
//
// Revision 1.6  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.5  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.4  2002/02/01 19:56:54  lampret
// Fixed combinational loops.
//
// Revision 1.3  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.6  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.5  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.1  2001/08/17 08:03:35  lampret
// *** empty log message ***
//
// Revision 1.2  2001/07/22 03:31:53  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

//
// Insn MMU
//

module or1200_immu_top(
	// Rst and clk
	clk, rst,

	// CPU i/f
	ic_en, immu_en, supv, icpu_adr_i, icpu_cycstb_i,
	icpu_adr_o, icpu_tag_o, icpu_rty_o, icpu_err_o,

    // SR Interface
    boot_adr_sel_i,

	// SPR access
	spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// QMEM i/f
	qmemimmu_rty_i, qmemimmu_err_i, qmemimmu_tag_i, qmemimmu_adr_o, qmemimmu_cycstb_o, qmemimmu_ci_o
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// CPU I/F
//
input				ic_en;
input				immu_en;
input				supv;
input	[aw-1:0]		icpu_adr_i;
input				icpu_cycstb_i;
output	[aw-1:0]		icpu_adr_o;
output	[3:0]			icpu_tag_o;
output				icpu_rty_o;
output				icpu_err_o;

//
// SR Interface
//
input				boot_adr_sel_i;

//
// SPR access
//
input				spr_cs;
input				spr_write;
input	[aw-1:0]		spr_addr;
input	[31:0]			spr_dat_i;
output	[31:0]			spr_dat_o;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// IC I/F
//
input				qmemimmu_rty_i;
input				qmemimmu_err_i;
input	[3:0]			qmemimmu_tag_i;
output	[aw-1:0]		qmemimmu_adr_o;
output				qmemimmu_cycstb_o;
output				qmemimmu_ci_o;

//
// Internal wires and regs
//
wire				itlb_spr_access;
wire	[31:`OR1200_IMMU_PS]	itlb_ppn;
wire				itlb_hit;
wire				itlb_uxe;
wire				itlb_sxe;
wire	[31:0]			itlb_dat_o;
wire				itlb_en;
wire				itlb_ci;
wire				itlb_done;
wire				fault;
wire				miss;
wire				page_cross;
reg		[31:0]		icpu_adr_default;
wire	[31:0]		icpu_adr_boot;
reg					icpu_adr_select;
reg		[31:0]		icpu_adr_o;
reg	[31:`OR1200_IMMU_PS]	icpu_vpn_r;
`ifdef OR1200_NO_IMMU
`else
reg				itlb_en_r;
reg				dis_spr_access_frst_clk;
reg				dis_spr_access_scnd_clk;
`endif

//
// Implemented bits inside match and translate registers
//
// itlbwYmrX: vpn 31-10  v 0
// itlbwYtrX: ppn 31-10  uxe 7  sxe 6
//
// itlb memory width:
// 19 bits for ppn
// 13 bits for vpn
// 1 bit for valid
// 2 bits for protection
// 1 bit for cache inhibit

//
// icpu_adr_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge rst or posedge clk)
	if (rst) begin
		icpu_adr_default <= #1 32'h0000_0100;
        icpu_adr_select  <= #1 1'b1;
    end
	else if (icpu_adr_select) begin
		icpu_adr_default <= #1 icpu_adr_boot;
        icpu_adr_select  <= #1 1'b0;
    end
    else begin
        icpu_adr_default <= #1 icpu_adr_i;
    end

assign icpu_adr_boot = {(boot_adr_sel_i ? `OR1200_EXCEPT_EPH1_P : `OR1200_EXCEPT_EPH0_P), 12'h100} ;

always @(icpu_adr_boot or icpu_adr_default or icpu_adr_select)
    if (icpu_adr_select)
        icpu_adr_o = icpu_adr_boot ;
    else
        icpu_adr_o = icpu_adr_default ;
`else
Unsupported !!!
`endif

//
// Page cross
//
// Asserted when CPU address crosses page boundary. Most of the time it is zero.
//
assign page_cross = icpu_adr_i[31:`OR1200_IMMU_PS] != icpu_vpn_r;

//
// Register icpu_adr_i's VPN for use when IMMU is not enabled but PPN is expected to come
// one clock cycle after offset part.
//
always @(posedge clk or posedge rst)
	if (rst)
		icpu_vpn_r <= #1 {32-`OR1200_IMMU_PS{1'b0}};
	else
		icpu_vpn_r <= #1 icpu_adr_i[31:`OR1200_IMMU_PS];

`ifdef OR1200_NO_IMMU

//
// Put all outputs in inactive state
//
assign spr_dat_o = 32'h00000000;
assign qmemimmu_adr_o = icpu_adr_i;
assign icpu_tag_o = qmemimmu_tag_i;
assign qmemimmu_cycstb_o = icpu_cycstb_i & ~page_cross;
assign icpu_rty_o = qmemimmu_rty_i;
assign icpu_err_o = qmemimmu_err_i;
assign qmemimmu_ci_o = `OR1200_IMMU_CI;
`ifdef OR1200_BIST
assign mbist_so_o = mbist_si_i;
`endif
`else

//
// ITLB SPR access
//
// 1200 - 12FF  itlbmr w0
// 1200 - 123F  itlbmr w0 [63:0]
//
// 1300 - 13FF  itlbtr w0
// 1300 - 133F  itlbtr w0 [63:0]
//
assign itlb_spr_access = spr_cs & ~dis_spr_access_scnd_clk;

//
// Disable ITLB SPR access
//
// This flops are used to mask ITLB miss/fault exception
// during first & second clock cycles of accessing ITLB SPR. In
// subsequent clock cycles it is assumed that ITLB SPR
// access was accomplished and that normal instruction fetching
// can proceed.
//
// spr_cs sets dis_spr_access_frst_clk and icpu_rty_o clears it.
// dis_spr_access_frst_clk  sets dis_spr_access_scnd_clk and 
// icpu_rty_o clears it.
//
always @(posedge clk or posedge rst)
	if (rst)
		dis_spr_access_frst_clk  <= #1 1'b0;
	else if (!icpu_rty_o)
		dis_spr_access_frst_clk  <= #1 1'b0;
	else if (spr_cs)
		dis_spr_access_frst_clk  <= #1 1'b1;

always @(posedge clk or posedge rst)
	if (rst)
		dis_spr_access_scnd_clk  <= #1 1'b0;
	else if (!icpu_rty_o)
		dis_spr_access_scnd_clk  <= #1 1'b0;
	else if (dis_spr_access_frst_clk)
		dis_spr_access_scnd_clk  <= #1 1'b1;

//
// Tags:
//
// OR1200_DTAG_TE - TLB miss Exception
// OR1200_DTAG_PE - Page fault Exception
//
assign icpu_tag_o = miss ? `OR1200_DTAG_TE : fault ? `OR1200_DTAG_PE : qmemimmu_tag_i;

//
// icpu_rty_o
//
// assign icpu_rty_o = !icpu_err_o & qmemimmu_rty_i;
assign icpu_rty_o = qmemimmu_rty_i | itlb_spr_access & immu_en;

//
// icpu_err_o
//
assign icpu_err_o = miss | fault | qmemimmu_err_i;

//
// Assert itlb_en_r after one clock cycle and when there is no
// ITLB SPR access
//
always @(posedge clk or posedge rst)
	if (rst)
		itlb_en_r <= #1 1'b0;
	else
		itlb_en_r <= #1 itlb_en & ~itlb_spr_access;

//
// ITLB lookup successful
//
assign itlb_done = itlb_en_r & ~page_cross;

//
// Cut transfer if something goes wrong with translation. If IC is disabled,
// use delayed signals.
//
// assign qmemimmu_cycstb_o = (!ic_en & immu_en) ? ~(miss | fault) & icpu_cycstb_i & ~page_cross : (miss | fault) ? 1'b0 : icpu_cycstb_i & ~page_cross; // DL
assign qmemimmu_cycstb_o = immu_en ? ~(miss | fault) & icpu_cycstb_i & ~page_cross & itlb_done : icpu_cycstb_i & ~page_cross;

//
// Cache Inhibit
//
// Cache inhibit is not really needed for instruction memory subsystem.
// If we would doq it, we would doq it like this.
// assign qmemimmu_ci_o = immu_en ? itlb_done & itlb_ci : `OR1200_IMMU_CI;
// However this causes a async combinational loop so we stick to
// no cache inhibit.
assign qmemimmu_ci_o = `OR1200_IMMU_CI;


//
// Physical address is either translated virtual address or
// simply equal when IMMU is disabled
//
assign qmemimmu_adr_o = itlb_done ? {itlb_ppn, icpu_adr_i[`OR1200_IMMU_PS-1:0]} : {icpu_vpn_r, icpu_adr_i[`OR1200_IMMU_PS-1:0]}; // DL: immu_en

reg     [31:0]                  spr_dat_o;
//
// Output to SPRS unit
//
//always @(posedge clk `OR1200_RST_EVENT)
//    if (rst == `OR1200_RST_ACT)
   always @ (posedge clk or posedge rst)
     if (rst)
        spr_dat_o <= #1 32'h0000_0000;
    else if (spr_cs & !dis_spr_access_scnd_clk)
        spr_dat_o <= #1 itlb_dat_o;

//
// Page fault exception logic
//
assign fault = itlb_done &
			(  (!supv & !itlb_uxe)		// Execute in user mode not enabled
			|| (supv & !itlb_sxe));		// Execute in supv mode not enabled

//
// TLB Miss exception logic
//
assign miss = itlb_done & !itlb_hit;

//
// ITLB Enable
//
assign itlb_en = immu_en & icpu_cycstb_i;

//
// Instantiation of ITLB
//
or1200_immu_tlb or1200_immu_tlb(
	// Rst and clk
        .clk(clk),
	.rst(rst),

        // I/F for translation
        .tlb_en(itlb_en),
	.vaddr(icpu_adr_i),
	.hit(itlb_hit),
	.ppn(itlb_ppn),
	.uxe(itlb_uxe),
	.sxe(itlb_sxe),
	.ci(itlb_ci),

`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_si_i),
	.mbist_so_o(mbist_so_o),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif

        // SPR access
        .spr_cs(itlb_spr_access),
	.spr_write(spr_write),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_i),
	.spr_dat_o(itlb_dat_o)
);

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's WISHBONE BIU                                       ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Implements WISHBONE interface                               ////
////                                                              ////
////  To Do:                                                      ////
////   - if biu_cyc/stb are deasserted and wb_ack_i is asserted   ////
////   and this happens even before aborted_r is asssrted,        ////
////   wb_ack_i will be delivered even though transfer is         ////
////   internally considered already aborted. However most        ////
////   wb_ack_i are externally registered and delayed. Normally   ////
////   this shouldn't cause any problems.                         ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_iwb_biu.v,v $
// Revision 1.2  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.1  2003/12/05 00:12:08  lampret
// New wb_biu for iwb interface.
//
// Revision 1.6.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.6  2003/04/07 20:57:46  lampret
// Fixed OR1200_CLKDIV_x_SUPPORTED defines. Fixed order of ifdefs.
//
// Revision 1.5  2002/12/08 08:57:56  lampret
// Added optional support for WB B3 specification (xwb_cti_o, xwb_bte_o). Made xwb_cab_o optional.
//
// Revision 1.4  2002/09/16 03:09:16  lampret
// Fixed a combinational loop.
//
// Revision 1.3  2002/08/12 05:31:37  lampret
// Added optional retry counter for wb_rty_i. Added graceful termination for aborted transfers.
//
// Revision 1.2  2002/07/14 22:17:17  lampret
// Added simple trace buffer [only for Xilinx Virtex target]. Fixed instruction fetch abort when new exception is recognized.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.12  2001/11/22 13:42:51  lampret
// Added wb_cyc_o assignment after it was removed by accident.
//
// Revision 1.11  2001/11/20 21:28:10  lampret
// Added optional sampling of inputs.
//
// Revision 1.10  2001/11/18 11:32:00  lampret
// OR1200_REGISTERED_OUTPUTS can now be enabled.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.3  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/22 03:31:54  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:23  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_iwb_biu(
	// RISC clock, reset and clock control
	clk, rst, clmode,

	// WISHBONE interface
	wb_clk_i, wb_rst_i, wb_ack_i, wb_err_i, wb_rty_i, wb_dat_i,
	wb_cyc_o, wb_adr_o, wb_stb_o, wb_we_o, wb_sel_o, wb_dat_o,
`ifdef OR1200_WB_CAB
	wb_cab_o,
`endif
`ifdef OR1200_WB_B3
	wb_cti_o, wb_bte_o,
`endif

	// Internal RISC bus
	biu_dat_i, biu_adr_i, biu_cyc_i, biu_stb_i, biu_we_i, biu_sel_i, biu_cab_i,
	biu_dat_o, biu_ack_o, biu_err_o
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;

//
// RISC clock, reset and clock control
//
input			clk;		// RISC clock
input			rst;		// RISC reset
input	[1:0]		clmode;		// 00 WB=RISC, 01 WB=RISC/2, 10 N/A, 11 WB=RISC/4

//
// WISHBONE interface
//
input			wb_clk_i;	// clock input
input			wb_rst_i;	// reset input
input			wb_ack_i;	// normal termination
input			wb_err_i;	// termination w/ error
input			wb_rty_i;	// termination w/ retry
input	[dw-1:0]	wb_dat_i;	// input data bus
output			wb_cyc_o;	// cycle valid output
output	[aw-1:0]	wb_adr_o;	// address bus outputs
output			wb_stb_o;	// strobe output
output			wb_we_o;	// indicates write transfer
output	[3:0]		wb_sel_o;	// byte select outputs
output	[dw-1:0]	wb_dat_o;	// output data bus
`ifdef OR1200_WB_CAB
output			wb_cab_o;	// consecutive address burst
`endif
`ifdef OR1200_WB_B3
output	[2:0]		wb_cti_o;	// cycle type identifier
output	[1:0]		wb_bte_o;	// burst type extension
`endif

//
// Internal RISC interface
//
input	[dw-1:0]	biu_dat_i;	// input data bus
input	[aw-1:0]	biu_adr_i;	// address bus
input			biu_cyc_i;	// WB cycle
input			biu_stb_i;	// WB strobe
input			biu_we_i;	// WB write enable
input			biu_cab_i;	// CAB input
input	[3:0]		biu_sel_i;	// byte selects
output	[31:0]		biu_dat_o;	// output data bus
output			biu_ack_o;	// ack output
output			biu_err_o;	// err output

//
// Registers
//
reg	[1:0]		valid_div;	// Used for synchronization
`ifdef OR1200_REGISTERED_OUTPUTS
reg	[aw-1:0]	wb_adr_o;	// address bus outputs
reg			wb_cyc_o;	// cycle output
reg			wb_stb_o;	// strobe output
reg			wb_we_o;	// indicates write transfer
reg	[3:0]		wb_sel_o;	// byte select outputs
`ifdef OR1200_WB_CAB
reg			wb_cab_o;	// CAB output
`endif
`ifdef OR1200_WB_B3
reg	[1:0]		burst_len;	// burst counter
reg	[2:0]		wb_cti_o;	// cycle type identifier
`endif
reg	[dw-1:0]	wb_dat_o;	// output data bus
`endif
`ifdef OR1200_REGISTERED_INPUTS
reg			long_ack_o;	// normal termination
reg			long_err_o;	// error termination
reg	[dw-1:0]	biu_dat_o;	// output data bus
`else
wire			long_ack_o;	// normal termination
wire			long_err_o;	// error termination
`endif
wire			aborted;	// Graceful abort
reg			aborted_r;	// Graceful abort
wire			retry;		// Retry
`ifdef OR1200_WB_RETRY
reg	[`OR1200_WB_RETRY-1:0] retry_cntr;	// Retry counter
`endif
reg			previous_complete;
wire			same_addr;
wire			repeated_access;
reg			repeated_access_ack;
reg	[dw-1:0]	wb_dat_r;	// saved previous data read

//
// WISHBONE I/F <-> Internal RISC I/F conversion
//

//
// Address bus
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_adr_o <= #1 {aw{1'b0}};
	else if ((biu_cyc_i & biu_stb_i) & ~wb_ack_i & ~aborted & ~(wb_stb_o & ~wb_ack_i) | biu_cab_i & (previous_complete | biu_ack_o))
		wb_adr_o <= #1 biu_adr_i;
`else
assign wb_adr_o = biu_adr_i;
`endif

//
// Same access as previous one, store previous read data
//
assign same_addr = wb_adr_o == biu_adr_i;
assign repeated_access = same_addr & previous_complete;
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_dat_r <= #1 32'h0000_0000;
	else if (wb_ack_i)
		wb_dat_r <= #1 wb_dat_i;

always @(posedge clk or posedge rst)
	if (rst)
		repeated_access_ack <= #1 1'b0;
	else if (repeated_access & biu_cyc_i & biu_stb_i)
		repeated_access_ack <= #1 1'b1;
	else
		repeated_access_ack <= #1 1'b0;

//
// Previous access completed
//
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		previous_complete <= #1 1'b1;
	else if (wb_ack_i & biu_cyc_i & biu_stb_i)
		previous_complete <= #1 1'b1;
	else if ((biu_cyc_i & biu_stb_i) & ~wb_ack_i & ~aborted & ~(wb_stb_o & ~wb_ack_i))
		previous_complete <= #1 1'b0;

//
// Input data bus
//
`ifdef OR1200_REGISTERED_INPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		biu_dat_o <= #1 32'h0000_0000;
	else if (wb_ack_i)
		biu_dat_o <= #1 wb_dat_i;
`else
assign biu_dat_o = repeated_access_ack ? wb_dat_r : wb_dat_i;
`endif

//
// Output data bus
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_dat_o <= #1 {dw{1'b0}};
	else if ((biu_cyc_i & biu_stb_i) & ~wb_ack_i & ~aborted)
		wb_dat_o <= #1 biu_dat_i;
`else
assign wb_dat_o = biu_dat_i;
`endif

//
// Valid_div counts RISC clock cycles by modulo 4
// and is used to synchronize external WB i/f to
// RISC clock
//
always @(posedge clk or posedge rst)
	if (rst)
		valid_div <= #1 2'b0;
	else
		valid_div <= #1 valid_div + 1'd1;

//
// biu_ack_o is one RISC clock cycle long long_ack_o.
// long_ack_o is one, two or four RISC clock cycles long because
// WISHBONE can work at 1, 1/2 or 1/4 RISC clock.
//
assign biu_ack_o = (repeated_access_ack | long_ack_o) & ~aborted_r
`ifdef OR1200_CLKDIV_2_SUPPORTED
		& (valid_div[0] | ~clmode[0])
`ifdef OR1200_CLKDIV_4_SUPPORTED
		& (valid_div[1] | ~clmode[1])
`endif
`endif
		;

//
// Acknowledgment of the data to the RISC
//
// long_ack_o
//
`ifdef OR1200_REGISTERED_INPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		long_ack_o <= #1 1'b0;
	else
		long_ack_o <= #1 wb_ack_i & ~aborted;
`else
assign long_ack_o = wb_ack_i;
`endif

//
// biu_err_o is one RISC clock cycle long long_err_o.
// long_err_o is one, two or four RISC clock cycles long because
// WISHBONE can work at 1, 1/2 or 1/4 RISC clock.
//
assign biu_err_o = long_err_o
`ifdef OR1200_CLKDIV_2_SUPPORTED
		& (valid_div[0] | ~clmode[0])
`ifdef OR1200_CLKDIV_4_SUPPORTED
		& (valid_div[1] | ~clmode[1])
`endif
`endif
		;

//
// Error termination
//
// long_err_o
//
`ifdef OR1200_REGISTERED_INPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		long_err_o <= #1 1'b0;
	else
		long_err_o <= #1 wb_err_i & ~aborted;
`else
assign long_err_o = wb_err_i & ~aborted_r;
`endif

//
// Retry counter
//
// Assert 'retry' when 'wb_rty_i' is sampled high and keep it high
// until retry counter doesn't expire
// 
`ifdef OR1200_WB_RETRY
assign retry = wb_rty_i | (|retry_cntr);
`else
assign retry = 1'b0;
`endif
`ifdef OR1200_WB_RETRY
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		retry_cntr <= #1 1'b0;
	else if (wb_rty_i)
		retry_cntr <= #1 {`OR1200_WB_RETRY{1'b1}};
	else if (retry_cntr)
		retry_cntr <= #1 retry_cntr - 7'd1;
`endif

//
// Graceful completion of aborted transfers
//
// Assert 'aborted' when 1) current transfer is in progress (wb_stb_o; which
// we know is only asserted together with wb_cyc_o) 2) and in next WB clock cycle
// wb_stb_o would be deasserted (biu_cyc_i and biu_stb_i are low) 3) and
// there is no termination of current transfer in this WB clock cycle (wb_ack_i
// and wb_err_i are low).
// 'aborted_r' is registered 'aborted' and extended until this "aborted" transfer
// is properly terminated with wb_ack_i/wb_err_i.
// 
assign aborted = wb_stb_o & ~(biu_cyc_i & biu_stb_i) & ~(wb_ack_i | wb_err_i);
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		aborted_r <= #1 1'b0;
	else if (wb_ack_i | wb_err_i)
		aborted_r <= #1 1'b0;
	else if (aborted)
		aborted_r <= #1 1'b1;

//
// WB cyc_o
//
// Either 1) normal transfer initiated by biu_cyc_i (and biu_cab_i if
// bursts are enabled) and possibly suspended by 'retry'
// or 2) extended "aborted" transfer
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_cyc_o <= #1 1'b0;
	else
`ifdef OR1200_NO_BURSTS
		wb_cyc_o <= #1 biu_cyc_i & ~wb_ack_i & ~retry & ~repeated_access | aborted & ~wb_ack_i;
`else
		wb_cyc_o <= #1 biu_cyc_i & ~wb_ack_i & ~retry & ~repeated_access | biu_cab_i | aborted & ~wb_ack_i;
`endif
`else
`ifdef OR1200_NO_BURSTS
assign wb_cyc_o = biu_cyc_i & ~retry;
`else
assign wb_cyc_o = biu_cyc_i | biu_cab_i & ~retry;
`endif
`endif

//
// WB stb_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_stb_o <= #1 1'b0;
	else
       wb_stb_o <= #1 (biu_cyc_i & biu_stb_i) & ~wb_ack_i & ~retry & ~repeated_access & ~repeated_access_ack | aborted & ~wb_ack_i;
`else
assign wb_stb_o = biu_cyc_i & biu_stb_i;
`endif

//
// WB we_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_we_o <= #1 1'b0;
	else
		wb_we_o <= #1 biu_cyc_i & biu_stb_i & biu_we_i | aborted & wb_we_o;
`else
assign wb_we_o = biu_cyc_i & biu_stb_i & biu_we_i;
`endif

//
// WB sel_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_sel_o <= #1 4'b0000;
	else
		wb_sel_o <= #1 biu_sel_i;
`else
assign wb_sel_o = biu_sel_i;
`endif

`ifdef OR1200_WB_CAB
//
// WB cab_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_cab_o <= #1 1'b0;
	else
		wb_cab_o <= #1 biu_cab_i;
`else
assign wb_cab_o = biu_cab_i;
`endif
`endif

`ifdef OR1200_WB_B3
//
// Count burst beats
//
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		burst_len <= #1 2'b00;
	else if (biu_cab_i && burst_len && wb_ack_i)
		burst_len <= #1 burst_len - 1'b1;
	else if (~biu_cab_i)
		burst_len <= #1 2'b11;

//
// WB cti_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_cti_o <= #1 3'b000;	// classic cycle
`ifdef OR1200_NO_BURSTS
	else
		wb_cti_o <= #1 3'b111;	// end-of-burst
`else
	else if (biu_cab_i && burst_len[1])
		wb_cti_o <= #1 3'b010;	// incrementing burst cycle
	else if (biu_cab_i && wb_ack_i)
		wb_cti_o <= #1 3'b111;	// end-of-burst
`endif	// OR1200_NO_BURSTS
`else
Unsupported !!!;
`endif

//
// WB bte_o
//
assign wb_bte_o = 2'b01;	// 4-beat wrap burst

`endif	// OR1200_WB_B3

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Load/Store unit                                    ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Interface between CPU and DC.                               ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_lsu.v,v $
// Revision 1.5  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.4  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.3  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.2  2002/01/18 07:56:00  lampret
// No more low/high priority interrupts (PICPR removed). Added tick timer exception. Added exception prefix (SR[EPH]). Fixed single-step bug whenreading NPC.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.9  2001/11/30 18:59:47  simons
// *** empty log message ***
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_lsu(

	// Internal i/f
	addrbase, addrofs, lsu_op, lsu_datain, lsu_dataout, lsu_stall, lsu_unstall,
        du_stall, except_align, except_dtlbmiss, except_dmmufault, except_dbuserr,

	// External i/f to DC
	dcpu_adr_o, dcpu_cycstb_o, dcpu_we_o, dcpu_sel_o, dcpu_tag_o, dcpu_dat_o,
	dcpu_dat_i, dcpu_ack_i, dcpu_rty_i, dcpu_err_i, dcpu_tag_i
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_REGFILE_ADDR_WIDTH;

//
// I/O
//

//
// Internal i/f
//
input	[31:0]			addrbase;
input	[31:0]			addrofs;
input	[`OR1200_LSUOP_WIDTH-1:0]	lsu_op;
input	[dw-1:0]		lsu_datain;
output	[dw-1:0]		lsu_dataout;
output				lsu_stall;
output				lsu_unstall;
input                           du_stall;
output				except_align;
output				except_dtlbmiss;
output				except_dmmufault;
output				except_dbuserr;

//
// External i/f to DC
//
output	[31:0]			dcpu_adr_o;
output				dcpu_cycstb_o;
output				dcpu_we_o;
output	[3:0]			dcpu_sel_o;
output	[3:0]			dcpu_tag_o;
output	[31:0]			dcpu_dat_o;
input	[31:0]			dcpu_dat_i;
input				dcpu_ack_i;
input				dcpu_rty_i;
input				dcpu_err_i;
input	[3:0]			dcpu_tag_i;

//
// Internal wires/regs
//
reg	[3:0]			dcpu_sel_o;

//
// Internal I/F assignments
//
assign lsu_stall = dcpu_rty_i & dcpu_cycstb_o;
assign lsu_unstall = dcpu_ack_i;
assign except_align = ((lsu_op == `OR1200_LSUOP_SH) | (lsu_op == `OR1200_LSUOP_LHZ) | (lsu_op == `OR1200_LSUOP_LHS)) & dcpu_adr_o[0]
		|  ((lsu_op == `OR1200_LSUOP_SW) | (lsu_op == `OR1200_LSUOP_LWZ) | (lsu_op == `OR1200_LSUOP_LWS)) & |dcpu_adr_o[1:0];
assign except_dtlbmiss = dcpu_err_i & (dcpu_tag_i == `OR1200_DTAG_TE);
assign except_dmmufault = dcpu_err_i & (dcpu_tag_i == `OR1200_DTAG_PE);
assign except_dbuserr = dcpu_err_i & (dcpu_tag_i == `OR1200_DTAG_BE);

//
// External I/F assignments
//
assign dcpu_adr_o = addrbase + addrofs;
assign dcpu_cycstb_o = du_stall | lsu_unstall | except_align ? 1'b0 : |lsu_op;
assign dcpu_we_o = lsu_op[3];
assign dcpu_tag_o = dcpu_cycstb_o ? `OR1200_DTAG_ND : `OR1200_DTAG_IDLE;
always @(lsu_op or dcpu_adr_o)
	casex({lsu_op, dcpu_adr_o[1:0]})
		{`OR1200_LSUOP_SB, 2'b00} : dcpu_sel_o = 4'b1000;
		{`OR1200_LSUOP_SB, 2'b01} : dcpu_sel_o = 4'b0100;
		{`OR1200_LSUOP_SB, 2'b10} : dcpu_sel_o = 4'b0010;
		{`OR1200_LSUOP_SB, 2'b11} : dcpu_sel_o = 4'b0001;
		{`OR1200_LSUOP_SH, 2'b00} : dcpu_sel_o = 4'b1100;
		{`OR1200_LSUOP_SH, 2'b10} : dcpu_sel_o = 4'b0011;
		{`OR1200_LSUOP_SW, 2'b00} : dcpu_sel_o = 4'b1111;
		{`OR1200_LSUOP_LBZ, 2'b00}, {`OR1200_LSUOP_LBS, 2'b00} : dcpu_sel_o = 4'b1000;
		{`OR1200_LSUOP_LBZ, 2'b01}, {`OR1200_LSUOP_LBS, 2'b01} : dcpu_sel_o = 4'b0100;
		{`OR1200_LSUOP_LBZ, 2'b10}, {`OR1200_LSUOP_LBS, 2'b10} : dcpu_sel_o = 4'b0010;
		{`OR1200_LSUOP_LBZ, 2'b11}, {`OR1200_LSUOP_LBS, 2'b11} : dcpu_sel_o = 4'b0001;
		{`OR1200_LSUOP_LHZ, 2'b00}, {`OR1200_LSUOP_LHS, 2'b00} : dcpu_sel_o = 4'b1100;
		{`OR1200_LSUOP_LHZ, 2'b10}, {`OR1200_LSUOP_LHS, 2'b10} : dcpu_sel_o = 4'b0011;
		{`OR1200_LSUOP_LWZ, 2'b00}, {`OR1200_LSUOP_LWS, 2'b00} : dcpu_sel_o = 4'b1111;
		default : dcpu_sel_o = 4'b0000;
	endcase

//
// Instantiation of Memory-to-regfile aligner
//
or1200_mem2reg or1200_mem2reg(
	.addr(dcpu_adr_o[1:0]),
	.lsu_op(lsu_op),
	.memdata(dcpu_dat_i),
	.regdata(lsu_dataout)
);

//
// Instantiation of Regfile-to-memory aligner
//
or1200_reg2mem or1200_reg2mem(
        .addr(dcpu_adr_o[1:0]),
        .lsu_op(lsu_op),
        .regdata(lsu_datain),
        .memdata(dcpu_dat_o)
);

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's mem2reg alignment                                  ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Two versions of Memory to register data alignment.          ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_mem2reg.v,v $
// Revision 1.5  2002/09/03 22:28:21  lampret
// As per Taylor Su suggestion all case blocks are full case by default and optionally (OR1200_CASE_DEFAULT) can be disabled to increase clock frequncy.
//
// Revision 1.4  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.3  2002/03/28 19:14:10  lampret
// Changed define name from OR1200_MEM2REG_FAST to OR1200_IMPL_MEM2REG2
//
// Revision 1.2  2002/01/14 06:18:22  lampret
// Fixed mem2reg bug in FAST implementation. Updated debug unit to work with new genpc/if.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/19 23:28:46  lampret
// Fixed some synthesis warnings. Configured with caches and MMUs.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:03  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_mem2reg(addr, lsu_op, memdata, regdata);

parameter width = `OR1200_OPERAND_WIDTH;

//
// I/O
//
input	[1:0]			addr;
input	[`OR1200_LSUOP_WIDTH-1:0]	lsu_op;
input	[width-1:0]		memdata;
output	[width-1:0]		regdata;


//
// In the past faster implementation of mem2reg (today probably slower)
//
`ifdef OR1200_IMPL_MEM2REG2

`define OR1200_M2R_BYTE0 4'b0000
`define OR1200_M2R_BYTE1 4'b0001
`define OR1200_M2R_BYTE2 4'b0010
`define OR1200_M2R_BYTE3 4'b0011
`define OR1200_M2R_EXTB0 4'b0100
`define OR1200_M2R_EXTB1 4'b0101
`define OR1200_M2R_EXTB2 4'b0110
`define OR1200_M2R_EXTB3 4'b0111
`define OR1200_M2R_ZERO  4'b0000

reg	[7:0]			regdata_hh;
reg	[7:0]			regdata_hl;
reg	[7:0]			regdata_lh;
reg	[7:0]			regdata_ll;
reg	[width-1:0]		aligned;
reg	[3:0]			sel_byte0, sel_byte1,
				sel_byte2, sel_byte3;

assign regdata = {regdata_hh, regdata_hl, regdata_lh, regdata_ll};

//
// Byte select 0
//
always @(addr or lsu_op) begin
	casex({lsu_op[2:0], addr})	// synopsys parallel_case
		{3'b01x, 2'b00}:			// lbz/lbs 0
			sel_byte0 = `OR1200_M2R_BYTE3;	// take byte 3
		{3'b01x, 2'b01},			// lbz/lbs 1
		{3'b10x, 2'b00}:			// lhz/lhs 0
			sel_byte0 = `OR1200_M2R_BYTE2;	// take byte 2
		{3'b01x, 2'b10}:			// lbz/lbs 2
			sel_byte0 = `OR1200_M2R_BYTE1;	// take byte 1
		default:				// all other cases
			sel_byte0 = `OR1200_M2R_BYTE0;	// take byte 0
	endcase
end

//
// Byte select 1
//
always @(addr or lsu_op) begin
	casex({lsu_op[2:0], addr})	// synopsys parallel_case
		{3'b010, 2'bxx}:			// lbz
			sel_byte1 = `OR1200_M2R_ZERO;	// zero extend
		{3'b011, 2'b00}:			// lbs 0
			sel_byte1 = `OR1200_M2R_EXTB3;	// sign extend from byte 3
		{3'b011, 2'b01}:			// lbs 1
			sel_byte1 = `OR1200_M2R_EXTB2;	// sign extend from byte 2
		{3'b011, 2'b10}:			// lbs 2
			sel_byte1 = `OR1200_M2R_EXTB1;	// sign extend from byte 1
		{3'b011, 2'b11}:			// lbs 3
			sel_byte1 = `OR1200_M2R_EXTB0;	// sign extend from byte 0
		{3'b10x, 2'b00}:			// lhz/lhs 0
			sel_byte1 = `OR1200_M2R_BYTE3;	// take byte 3
		default:				// all other cases
			sel_byte1 = `OR1200_M2R_BYTE1;	// take byte 1
	endcase
end

//
// Byte select 2
//
always @(addr or lsu_op) begin
	casex({lsu_op[2:0], addr})	// synopsys parallel_case
		{3'b010, 2'bxx},			// lbz
		{3'b100, 2'bxx}:			// lhz
			sel_byte2 = `OR1200_M2R_ZERO;	// zero extend
		{3'b011, 2'b00},			// lbs 0
		{3'b101, 2'b00}:			// lhs 0
			sel_byte2 = `OR1200_M2R_EXTB3;	// sign extend from byte 3
		{3'b011, 2'b01}:			// lbs 1
			sel_byte2 = `OR1200_M2R_EXTB2;	// sign extend from byte 2
		{3'b011, 2'b10},			// lbs 2
		{3'b101, 2'b10}:			// lhs 0
			sel_byte2 = `OR1200_M2R_EXTB1;	// sign extend from byte 1
		{3'b011, 2'b11}:			// lbs 3
			sel_byte2 = `OR1200_M2R_EXTB0;	// sign extend from byte 0
		default:				// all other cases
			sel_byte2 = `OR1200_M2R_BYTE2;	// take byte 2
	endcase
end

//
// Byte select 3
//
always @(addr or lsu_op) begin
	casex({lsu_op[2:0], addr}) // synopsys parallel_case
		{3'b010, 2'bxx},			// lbz
		{3'b100, 2'bxx}:			// lhz
			sel_byte3 = `OR1200_M2R_ZERO;	// zero extend
		{3'b011, 2'b00},			// lbs 0
		{3'b101, 2'b00}:			// lhs 0
			sel_byte3 = `OR1200_M2R_EXTB3;	// sign extend from byte 3
		{3'b011, 2'b01}:			// lbs 1
			sel_byte3 = `OR1200_M2R_EXTB2;	// sign extend from byte 2
		{3'b011, 2'b10},			// lbs 2
		{3'b101, 2'b10}:			// lhs 0
			sel_byte3 = `OR1200_M2R_EXTB1;	// sign extend from byte 1
		{3'b011, 2'b11}:			// lbs 3
			sel_byte3 = `OR1200_M2R_EXTB0;	// sign extend from byte 0
		default:				// all other cases
			sel_byte3 = `OR1200_M2R_BYTE3;	// take byte 3
	endcase
end

//
// Byte 0
//
always @(sel_byte0 or memdata) begin
`ifdef OR1200_ADDITIONAL_SYNOPSYS_DIRECTIVES
`ifdef OR1200_CASE_DEFAULT
	case(sel_byte0) // synopsys parallel_case infer_mux
`else
	case(sel_byte0) // synopsys full_case parallel_case infer_mux
`endif
`else
`ifdef OR1200_CASE_DEFAULT
	case(sel_byte0) // synopsys parallel_case
`else
	case(sel_byte0) // synopsys full_case parallel_case
`endif
`endif
		`OR1200_M2R_BYTE0: begin
				regdata_ll = memdata[7:0];
			end
		`OR1200_M2R_BYTE1: begin
				regdata_ll = memdata[15:8];
			end
		`OR1200_M2R_BYTE2: begin
				regdata_ll = memdata[23:16];
			end
`ifdef OR1200_CASE_DEFAULT
		default: begin
`else
		`OR1200_M2R_BYTE3: begin
`endif
				regdata_ll = memdata[31:24];
			end
	endcase
end

//
// Byte 1
//
always @(sel_byte1 or memdata) begin
`ifdef OR1200_ADDITIONAL_SYNOPSYS_DIRECTIVES
`ifdef OR1200_CASE_DEFAULT
	case(sel_byte1) // synopsys parallel_case infer_mux
`else
	case(sel_byte1) // synopsys full_case parallel_case infer_mux
`endif
`else
`ifdef OR1200_CASE_DEFAULT
	case(sel_byte1) // synopsys parallel_case
`else
	case(sel_byte1) // synopsys full_case parallel_case
`endif
`endif
		`OR1200_M2R_ZERO: begin
				regdata_lh = 8'h00;
			end
		`OR1200_M2R_BYTE1: begin
				regdata_lh = memdata[15:8];
			end
		`OR1200_M2R_BYTE3: begin
				regdata_lh = memdata[31:24];
			end
		`OR1200_M2R_EXTB0: begin
				regdata_lh = {8{memdata[7]}};
			end
		`OR1200_M2R_EXTB1: begin
				regdata_lh = {8{memdata[15]}};
			end
		`OR1200_M2R_EXTB2: begin
				regdata_lh = {8{memdata[23]}};
			end
`ifdef OR1200_CASE_DEFAULT
		default: begin
`else
		`OR1200_M2R_EXTB3: begin
`endif
				regdata_lh = {8{memdata[31]}};
			end
	endcase
end

//
// Byte 2
//
always @(sel_byte2 or memdata) begin
`ifdef OR1200_ADDITIONAL_SYNOPSYS_DIRECTIVES
`ifdef OR1200_CASE_DEFAULT
	case(sel_byte2) // synopsys parallel_case infer_mux
`else
	case(sel_byte2) // synopsys full_case parallel_case infer_mux
`endif
`else
`ifdef OR1200_CASE_DEFAULT
	case(sel_byte2) // synopsys parallel_case
`else
	case(sel_byte2) // synopsys full_case parallel_case
`endif
`endif
		`OR1200_M2R_ZERO: begin
				regdata_hl = 8'h00;
			end
		`OR1200_M2R_BYTE2: begin
				regdata_hl = memdata[23:16];
			end
		`OR1200_M2R_EXTB0: begin
				regdata_hl = {8{memdata[7]}};
			end
		`OR1200_M2R_EXTB1: begin
				regdata_hl = {8{memdata[15]}};
			end
		`OR1200_M2R_EXTB2: begin
				regdata_hl = {8{memdata[23]}};
			end
`ifdef OR1200_CASE_DEFAULT
		default: begin
`else
		`OR1200_M2R_EXTB3: begin
`endif
				regdata_hl = {8{memdata[31]}};
			end
	endcase
end

//
// Byte 3
//
always @(sel_byte3 or memdata) begin
`ifdef OR1200_ADDITIONAL_SYNOPSYS_DIRECTIVES
`ifdef OR1200_CASE_DEFAULT
	case(sel_byte3) // synopsys parallel_case infer_mux
`else
	case(sel_byte3) // synopsys full_case parallel_case infer_mux
`endif
`else
`ifdef OR1200_CASE_DEFAULT
	case(sel_byte3) // synopsys parallel_case
`else
	case(sel_byte3) // synopsys full_case parallel_case
`endif
`endif
		`OR1200_M2R_ZERO: begin
				regdata_hh = 8'h00;
			end
		`OR1200_M2R_BYTE3: begin
				regdata_hh = memdata[31:24];
			end
		`OR1200_M2R_EXTB0: begin
				regdata_hh = {8{memdata[7]}};
			end
		`OR1200_M2R_EXTB1: begin
				regdata_hh = {8{memdata[15]}};
			end
		`OR1200_M2R_EXTB2: begin
				regdata_hh = {8{memdata[23]}};
			end
`ifdef OR1200_CASE_DEFAULT
		`OR1200_M2R_EXTB3: begin
`else
		`OR1200_M2R_EXTB3: begin
`endif
				regdata_hh = {8{memdata[31]}};
			end
	endcase
end

`else

//
// Straightforward implementation of mem2reg
//

reg	[width-1:0]		regdata;
reg	[width-1:0]		aligned;

//
// Alignment
//
always @(addr or memdata) begin
`ifdef OR1200_ADDITIONAL_SYNOPSYS_DIRECTIVES
	case(addr) // synopsys parallel_case infer_mux
`else
	case(addr) // synopsys parallel_case
`endif
		2'b00:
			aligned = memdata;
		2'b01:
			aligned = {memdata[23:0], 8'b0};
		2'b10:
			aligned = {memdata[15:0], 16'b0};
		2'b11:
			aligned = {memdata[7:0], 24'b0};
	endcase
end

//
// Bytes
//
always @(lsu_op or aligned) begin
`ifdef OR1200_ADDITIONAL_SYNOPSYS_DIRECTIVES
	case(lsu_op) // synopsys parallel_case infer_mux
`else
	case(lsu_op) // synopsys parallel_case
`endif
		`OR1200_LSUOP_LBZ: begin
				regdata[7:0] = aligned[31:24];
				regdata[31:8] = 24'b0;
			end
		`OR1200_LSUOP_LBS: begin
				regdata[7:0] = aligned[31:24];
				regdata[31:8] = {24{aligned[31]}};
			end
		`OR1200_LSUOP_LHZ: begin
				regdata[15:0] = aligned[31:16];
				regdata[31:16] = 16'b0;
			end
		`OR1200_LSUOP_LHS: begin
				regdata[15:0] = aligned[31:16];
				regdata[31:16] = {16{aligned[31]}};
			end
		default:
				regdata = aligned;
	endcase
end

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Top level multiplier and MAC                       ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Multiplier is 32x32 however multiply instructions only      ////
////  use lower 32 bits of the result. MAC is 32x32=64+64.        ////
////                                                              ////
////  To Do:                                                      ////
////   - make signed division better, w/o negating the operands   ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_mult_mac.v,v $
// Revision 1.5  2006/04/09 01:32:29  lampret
// See OR1200_MAC_SHIFTBY in or1200_defines.v for explanation of the change. Since now no more 28 bits shift for l.macrc insns however for backward compatbility it is possible to set arbitry number of shifts.
//
// Revision 1.4  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.3  2003/04/24 00:16:07  lampret
// No functional changes. Added defines to disable implementation of multiplier/MAC
//
// Revision 1.2  2002/09/08 05:52:16  lampret
// Added optional l.div/l.divu insns. By default they are disabled.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.3  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.2  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:38  igorm
// no message
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_mult_mac(
	// Clock and reset
	clk, rst,

	// Multiplier/MAC interface
	ex_freeze, id_macrc_op, macrc_op, a, b, mac_op, alu_op, result, mac_stall_r,

	// SPR interface
	spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o
);

parameter width = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// Multiplier/MAC interface
//
input				ex_freeze;
input				id_macrc_op;
input				macrc_op;
input	[width-1:0]		a;
input	[width-1:0]		b;
input	[`OR1200_MACOP_WIDTH-1:0]	mac_op;
input	[`OR1200_ALUOP_WIDTH-1:0]	alu_op;
output	[width-1:0]		result;
output				mac_stall_r;

//
// SPR interface
//
input				spr_cs;
input				spr_write;
input	[31:0]			spr_addr;
input	[31:0]			spr_dat_i;
output	[31:0]			spr_dat_o;

//
// Internal wires and regs
//
`ifdef OR1200_MULT_IMPLEMENTED
reg	[width-1:0]		result;
reg	[2*width-1:0]		mul_prod_r;
`else
wire	[width-1:0]		result;
wire	[2*width-1:0]		mul_prod_r;
`endif
wire	[2*width-1:0]		mul_prod;
wire	[`OR1200_MACOP_WIDTH-1:0]	mac_op;
`ifdef OR1200_MAC_IMPLEMENTED
reg	[`OR1200_MACOP_WIDTH-1:0]	mac_op_r1;
reg	[`OR1200_MACOP_WIDTH-1:0]	mac_op_r2;
reg	[`OR1200_MACOP_WIDTH-1:0]	mac_op_r3;
reg				mac_stall_r;
reg	[2*width-1:0]		mac_r;
`else
wire	[`OR1200_MACOP_WIDTH-1:0]	mac_op_r1;
wire	[`OR1200_MACOP_WIDTH-1:0]	mac_op_r2;
wire	[`OR1200_MACOP_WIDTH-1:0]	mac_op_r3;
wire				mac_stall_r;
wire	[2*width-1:0]		mac_r;
`endif
wire	[width-1:0]		x;
wire	[width-1:0]		y;
wire				spr_maclo_we;
wire				spr_machi_we;
wire				alu_op_div_divu;
wire				alu_op_div;
reg				div_free;
`ifdef OR1200_IMPL_DIV
wire	[width-1:0]		div_tmp;
reg	[5:0]			div_cntr;
`endif

//
// Combinatorial logic
//
`ifdef OR1200_MAC_IMPLEMENTED
assign spr_maclo_we = spr_cs & spr_write & spr_addr[`OR1200_MAC_ADDR];
assign spr_machi_we = spr_cs & spr_write & !spr_addr[`OR1200_MAC_ADDR];
assign spr_dat_o = spr_addr[`OR1200_MAC_ADDR] ? mac_r[31:0] : mac_r[63:32];
`else
assign spr_maclo_we = 1'b0;
assign spr_machi_we = 1'b0;
assign spr_dat_o = 32'h0000_0000;
`endif
`ifdef OR1200_LOWPWR_MULT
assign x = (alu_op_div & a[31]) ? ~a + 1'b1 : alu_op_div_divu | (alu_op == `OR1200_ALUOP_MUL) | (|mac_op) ? a : 32'h0000_0000;
assign y = (alu_op_div & b[31]) ? ~b + 1'b1 : alu_op_div_divu | (alu_op == `OR1200_ALUOP_MUL) | (|mac_op) ? b : 32'h0000_0000;
`else
assign x = alu_op_div & a[31] ? ~a + 32'b1 : a;
assign y = alu_op_div & b[31] ? ~b + 32'b1 : b;
`endif
`ifdef OR1200_IMPL_DIV
assign alu_op_div = (alu_op == `OR1200_ALUOP_DIV);
assign alu_op_div_divu = alu_op_div | (alu_op == `OR1200_ALUOP_DIVU);
assign div_tmp = mul_prod_r[63:32] - y;
`else
assign alu_op_div = 1'b0;
assign alu_op_div_divu = 1'b0;
`endif

`ifdef OR1200_MULT_IMPLEMENTED

//
// Select result of current ALU operation to be forwarded
// to next instruction and to WB stage
//
always @(alu_op or mul_prod_r or mac_r or a or b)
	casex(alu_op)	// synopsys parallel_case
`ifdef OR1200_IMPL_DIV
		`OR1200_ALUOP_DIV:
			result = a[31] ^ b[31] ? ~mul_prod_r[31:0] + 1'b1 : mul_prod_r[31:0];
		`OR1200_ALUOP_DIVU,
`endif
		`OR1200_ALUOP_MUL: begin
			result = mul_prod_r[31:0];
		end
		default:
`ifdef OR1200_MAC_SHIFTBY
			result = mac_r[`OR1200_MAC_SHIFTBY+31:`OR1200_MAC_SHIFTBY];
`else
			result = mac_r[31:0];
`endif
	endcase

//
// Instantiation of the multiplier
//
`ifdef OR1200_ASIC_MULTP2_32X32
or1200_amultp2_32x32 or1200_amultp2_32x32(
	.X(x),
	.Y(y),
	.RST(rst),
	.CLK(clk),
	.P(mul_prod)
);
`else // OR1200_ASIC_MULTP2_32X32
or1200_gmultp2_32x32 or1200_gmultp2_32x32(
	.X(x),
	.Y(y),
	.RST(rst),
	.CLK(clk),
	.P(mul_prod)
);
`endif // OR1200_ASIC_MULTP2_32X32

//
// Registered output from the multiplier and
// an optional divider
//
always @(posedge rst or posedge clk)
	if (rst) begin
		mul_prod_r <= #1 64'h0000_0000_0000_0000;
		div_free <= #1 1'b1;
`ifdef OR1200_IMPL_DIV
		div_cntr <= #1 6'b00_0000;
`endif
	end
`ifdef OR1200_IMPL_DIV
	else if (|div_cntr) begin
		if (div_tmp[31])
			mul_prod_r <= #1 {mul_prod_r[62:0], 1'b0};
		else
			mul_prod_r <= #1 {div_tmp[30:0], mul_prod_r[31:0], 1'b1};
		div_cntr <= #1 div_cntr - 1'b1;
	end
	else if (alu_op_div_divu && div_free) begin
		mul_prod_r <= #1 {31'b0, x[31:0], 1'b0};
		div_cntr <= #1 6'b10_0000;
		div_free <= #1 1'b0;
	end
`endif // OR1200_IMPL_DIV
	else if (div_free | !ex_freeze) begin
		mul_prod_r <= #1 mul_prod[63:0];
		div_free <= #1 1'b1;
	end

`else // OR1200_MULT_IMPLEMENTED
assign result = {width{1'b0}};
assign mul_prod = {2*width{1'b0}};
assign mul_prod_r = {2*width{1'b0}};
`endif // OR1200_MULT_IMPLEMENTED

`ifdef OR1200_MAC_IMPLEMENTED

//
// Propagation of l.mac opcode
//
always @(posedge clk or posedge rst)
	if (rst)
		mac_op_r1 <= #1 `OR1200_MACOP_WIDTH'b0;
	else
		mac_op_r1 <= #1 mac_op;

//
// Propagation of l.mac opcode
//
always @(posedge clk or posedge rst)
	if (rst)
		mac_op_r2 <= #1 `OR1200_MACOP_WIDTH'b0;
	else
		mac_op_r2 <= #1 mac_op_r1;

//
// Propagation of l.mac opcode
//
always @(posedge clk or posedge rst)
	if (rst)
		mac_op_r3 <= #1 `OR1200_MACOP_WIDTH'b0;
	else
		mac_op_r3 <= #1 mac_op_r2;

//
// Implementation of MAC
//
always @(posedge rst or posedge clk)
	if (rst)
		mac_r <= #1 64'h0000_0000_0000_0000;
`ifdef OR1200_MAC_SPR_WE
	else if (spr_maclo_we)
		mac_r[31:0] <= #1 spr_dat_i;
	else if (spr_machi_we)
		mac_r[63:32] <= #1 spr_dat_i;
`endif
	else if (mac_op_r3 == `OR1200_MACOP_MAC)
		mac_r <= #1 mac_r + mul_prod_r;
	else if (mac_op_r3 == `OR1200_MACOP_MSB)
		mac_r <= #1 mac_r - mul_prod_r;
	else if (macrc_op & !ex_freeze)
		mac_r <= #1 64'h0000_0000_0000_0000;

//
// Stall CPU if l.macrc is in ID and MAC still has to process l.mac instructions
// in EX stage (e.g. inside multiplier)
// This stall signal is also used by the divider.
//
always @(posedge rst or posedge clk)
	if (rst)
		mac_stall_r <= #1 1'b0;
	else
		mac_stall_r <= #1 (|mac_op | (|mac_op_r1) | (|mac_op_r2)) & (id_macrc_op | mac_stall_r)
`ifdef OR1200_IMPL_DIV
				| (|div_cntr)
`endif
				;
`else // OR1200_MAC_IMPLEMENTED
assign mac_stall_r = 1'b0;
assign mac_r = {2*width{1'b0}};
assign mac_op_r1 = `OR1200_MACOP_WIDTH'b0;
assign mac_op_r2 = `OR1200_MACOP_WIDTH'b0;
assign mac_op_r3 = `OR1200_MACOP_WIDTH'b0;
`endif // OR1200_MAC_IMPLEMENTED

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's register file read operands mux                    ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Mux for two register file read operands.                    ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_operandmuxes.v,v $
// Revision 1.2  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.9  2001/11/12 01:45:40  lampret
// Moved flag bit into SR. Changed RF enable from constant enable to dynamic enable for read ports.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:05  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_operandmuxes(
	// Clock and reset
	clk, rst,

	// Internal i/f
	id_freeze, ex_freeze, rf_dataa, rf_datab, ex_forw, wb_forw,
	simm, sel_a, sel_b, operand_a, operand_b, muxed_b
);

parameter width = `OR1200_OPERAND_WIDTH;

//
// I/O
//
input				clk;
input				rst;
input				id_freeze;
input				ex_freeze;
input	[width-1:0]		rf_dataa;
input	[width-1:0]		rf_datab;
input	[width-1:0]		ex_forw;
input	[width-1:0]		wb_forw;
input	[width-1:0]		simm;
input	[`OR1200_SEL_WIDTH-1:0]	sel_a;
input	[`OR1200_SEL_WIDTH-1:0]	sel_b;
output	[width-1:0]		operand_a;
output	[width-1:0]		operand_b;
output	[width-1:0]		muxed_b;

//
// Internal wires and regs
//
reg	[width-1:0]		operand_a;
reg	[width-1:0]		operand_b;
reg	[width-1:0]		muxed_a;
reg	[width-1:0]		muxed_b;
reg				saved_a;
reg				saved_b;

//
// Operand A register
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		operand_a <= #1 32'd0;
		saved_a <= #1 1'b0;
	end else if (!ex_freeze && id_freeze && !saved_a) begin
		operand_a <= #1 muxed_a;
		saved_a <= #1 1'b1;
	end else if (!ex_freeze && !saved_a) begin
		operand_a <= #1 muxed_a;
	end else if (!ex_freeze && !id_freeze)
		saved_a <= #1 1'b0;
end

//
// Operand B register
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		operand_b <= #1 32'd0;
		saved_b <= #1 1'b0;
	end else if (!ex_freeze && id_freeze && !saved_b) begin
		operand_b <= #1 muxed_b;
		saved_b <= #1 1'b1;
	end else if (!ex_freeze && !saved_b) begin
		operand_b <= #1 muxed_b;
	end else if (!ex_freeze && !id_freeze)
		saved_b <= #1 1'b0;
end

//
// Forwarding logic for operand A register
//
always @(ex_forw or wb_forw or rf_dataa or sel_a) begin
`ifdef OR1200_ADDITIONAL_SYNOPSYS_DIRECTIVES
	casex (sel_a)	// synopsys parallel_case infer_mux
`else
	casex (sel_a)	// synopsys parallel_case
`endif
		`OR1200_SEL_EX_FORW:
			muxed_a = ex_forw;
		`OR1200_SEL_WB_FORW:
			muxed_a = wb_forw;
		default:
			muxed_a = rf_dataa;
	endcase
end

//
// Forwarding logic for operand B register
//
always @(simm or ex_forw or wb_forw or rf_datab or sel_b) begin
`ifdef OR1200_ADDITIONAL_SYNOPSYS_DIRECTIVES
	casex (sel_b)	// synopsys parallel_case infer_mux
`else
	casex (sel_b)	// synopsys parallel_case
`endif
		`OR1200_SEL_IMM:
			muxed_b = simm;
		`OR1200_SEL_EX_FORW:
			muxed_b = ex_forw;
		`OR1200_SEL_WB_FORW:
			muxed_b = wb_forw;
		default:
			muxed_b = rf_datab;
	endcase
end

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Programmable Interrupt Controller                  ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  PIC according to OR1K architectural specification.          ////
////                                                              ////
////  To Do:                                                      ////
////   None                                                       ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_pic.v,v $
// Revision 1.4  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.3  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.2  2002/01/18 07:56:00  lampret
// No more low/high priority interrupts (PICPR removed). Added tick timer exception. Added exception prefix (SR[EPH]). Fixed single-step bug whenreading NPC.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:21  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_pic(
	// RISC Internal Interface
	clk, rst, spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o,
	pic_wakeup, intr,
	
	// PIC Interface
	pic_int
);

//
// RISC Internal Interface
//
input		clk;		// Clock
input		rst;		// Reset
input		spr_cs;		// SPR CS
input		spr_write;	// SPR Write
input	[31:0]	spr_addr;	// SPR Address
input	[31:0]	spr_dat_i;	// SPR Write Data
output	[31:0]	spr_dat_o;	// SPR Read Data
output		pic_wakeup;	// Wakeup to the PM
output		intr;		// interrupt
				// exception request

//
// PIC Interface
//
input	[`OR1200_PIC_INTS-1:0]	pic_int;// Interrupt inputs

`ifdef OR1200_PIC_IMPLEMENTED

//
// PIC Mask Register bits (or no register)
//
`ifdef OR1200_PIC_PICMR
reg	[`OR1200_PIC_INTS-1:2]	picmr;	// PICMR bits
`else
wire	[`OR1200_PIC_INTS-1:2]	picmr;	// No PICMR register
`endif

//
// PIC Status Register bits (or no register)
//
`ifdef OR1200_PIC_PICSR
reg	[`OR1200_PIC_INTS-1:0]	picsr;	// PICSR bits
`else
wire	[`OR1200_PIC_INTS-1:0]	picsr;	// No PICSR register
`endif

//
// Internal wires & regs
//
wire		picmr_sel;	// PICMR select
wire		picsr_sel;	// PICSR select
wire	[`OR1200_PIC_INTS-1:0] um_ints;// Unmasked interrupts
reg	[31:0] 	spr_dat_o;	// SPR data out

//
// PIC registers address decoder
//
assign picmr_sel = (spr_cs && (spr_addr[`OR1200_PICOFS_BITS] == `OR1200_PIC_OFS_PICMR)) ? 1'b1 : 1'b0;
assign picsr_sel = (spr_cs && (spr_addr[`OR1200_PICOFS_BITS] == `OR1200_PIC_OFS_PICSR)) ? 1'b1 : 1'b0;

//
// Write to PICMR
//
`ifdef OR1200_PIC_PICMR
always @(posedge clk or posedge rst)
	if (rst)
		picmr <= {1'b1, {`OR1200_PIC_INTS-3{1'b0}}};
	else if (picmr_sel && spr_write) begin
		picmr <= #1 spr_dat_i[`OR1200_PIC_INTS-1:2];
	end
`else
assign picmr = (`OR1200_PIC_INTS)'b1;
`endif

//
// Write to PICSR, both CPU and external ints
//
`ifdef OR1200_PIC_PICSR
always @(posedge clk or posedge rst)
	if (rst)
		picsr <= {`OR1200_PIC_INTS{1'b0}};
	else if (picsr_sel && spr_write) begin
		picsr <= #1 spr_dat_i[`OR1200_PIC_INTS-1:0] | um_ints;
	end else
		picsr <= #1 picsr | um_ints;
`else
assign picsr = pic_int;
`endif

//
// Read PIC registers
//
always @(spr_addr or picmr or picsr)
	case (spr_addr[`OR1200_PICOFS_BITS])	// synopsys parallel_case
`ifdef OR1200_PIC_READREGS
		`OR1200_PIC_OFS_PICMR: begin
					spr_dat_o[`OR1200_PIC_INTS-1:0] = {picmr, 2'b0};
`ifdef OR1200_PIC_UNUSED_ZERO
					spr_dat_o[31:`OR1200_PIC_INTS] = {32-`OR1200_PIC_INTS{1'b0}};
`endif
				end
`endif
		default: begin
				spr_dat_o[`OR1200_PIC_INTS-1:0] = picsr;
`ifdef OR1200_PIC_UNUSED_ZERO
				spr_dat_o[31:`OR1200_PIC_INTS] = {32-`OR1200_PIC_INTS{1'b0}};
`endif
			end
	endcase

//
// Unmasked interrupts
//
assign um_ints = pic_int & {picmr, 2'b11};

//
// Generate intr
//
assign intr = |um_ints;

//
// Assert pic_wakeup when intr is asserted
//
assign pic_wakeup = intr;

`else

//
// When PIC is not implemented, drive all outputs as would when PIC is disabled
//
assign intr = pic_int[1] | pic_int[0];
assign pic_wakeup= intr;

//
// Read PIC registers
//
`ifdef OR1200_PIC_READREGS
assign spr_dat_o[`OR1200_PIC_INTS-1:0] = `OR1200_PIC_INTS'b0;
`ifdef OR1200_PIC_UNUSED_ZERO
assign spr_dat_o[31:`OR1200_PIC_INTS] = 32-`OR1200_PIC_INTS'b0;
`endif
`endif

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Power Management                                   ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  PM according to OR1K architectural specification.           ////
////                                                              ////
////  To Do:                                                      ////
////   - add support for dynamic clock gating                     ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_pm.v,v $
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:21  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_pm(
	// RISC Internal Interface
	clk, rst, pic_wakeup, spr_write, spr_addr, spr_dat_i, spr_dat_o,
	
	// Power Management Interface
	pm_clksd, pm_cpustall, pm_dc_gate, pm_ic_gate, pm_dmmu_gate,
	pm_immu_gate, pm_tt_gate, pm_cpu_gate, pm_wakeup, pm_lvolt
);

//
// RISC Internal Interface
//
input		clk;		// Clock
input		rst;		// Reset
input		pic_wakeup;	// Wakeup from the PIC
input		spr_write;	// SPR Read/Write
input	[31:0]	spr_addr;	// SPR Address
input	[31:0]	spr_dat_i;	// SPR Write Data
output	[31:0]	spr_dat_o;	// SPR Read Data

//
// Power Management Interface
//
input		pm_cpustall;	// Stall the CPU
output	[3:0]	pm_clksd;	// Clock Slowdown factor
output		pm_dc_gate;	// Gate DCache clock
output		pm_ic_gate;	// Gate ICache clock
output		pm_dmmu_gate;	// Gate DMMU clock
output		pm_immu_gate;	// Gate IMMU clock
output		pm_tt_gate;	// Gate Tick Timer clock
output		pm_cpu_gate;	// Gate main RISC/CPU clock
output		pm_wakeup;	// Activate (de-gate) all clocks
output		pm_lvolt;	// Lower operating voltage

`ifdef OR1200_PM_IMPLEMENTED

//
// Power Management Register bits
//
reg	[3:0]	sdf;	// Slow-down factor
reg		dme;	// Doze Mode Enable
reg		sme;	// Sleep Mode Enable
reg		dcge;	// Dynamic Clock Gating Enable

//
// Internal wires
//
wire		pmr_sel; // PMR select

//
// PMR address decoder (partial decoder)
//
`ifdef OR1200_PM_PARTIAL_DECODING
assign pmr_sel = (spr_addr[`OR1200_SPR_GROUP_BITS] == `OR1200_SPRGRP_PM) ? 1'b1 : 1'b0;
`else
assign pmr_sel = ((spr_addr[`OR1200_SPR_GROUP_BITS] == `OR1200_SPRGRP_PM) &&
		  (spr_addr[`OR1200_SPR_OFS_BITS] == `OR1200_PM_OFS_PMR)) ? 1'b1 : 1'b0;
`endif

//
// Write to PMR and also PMR[DME]/PMR[SME] reset when
// pic_wakeup is asserted
//
always @(posedge clk or posedge rst)
	if (rst)
		{dcge, sme, dme, sdf} <= 7'b0;
	else if (pmr_sel && spr_write) begin
		sdf <= #1 spr_dat_i[`OR1200_PM_PMR_SDF];
		dme <= #1 spr_dat_i[`OR1200_PM_PMR_DME];
		sme <= #1 spr_dat_i[`OR1200_PM_PMR_SME];
		dcge <= #1 spr_dat_i[`OR1200_PM_PMR_DCGE];
	end
	else if (pic_wakeup) begin
		dme <= #1 1'b0;
		sme <= #1 1'b0;
	end

//
// Read PMR
//
`ifdef OR1200_PM_READREGS
assign spr_dat_o[`OR1200_PM_PMR_SDF] = sdf;
assign spr_dat_o[`OR1200_PM_PMR_DME] = dme;
assign spr_dat_o[`OR1200_PM_PMR_SME] = sme;
assign spr_dat_o[`OR1200_PM_PMR_DCGE] = dcge;
`ifdef OR1200_PM_UNUSED_ZERO
assign spr_dat_o[`OR1200_PM_PMR_UNUSED] = 25'b0;
`endif
`endif

//
// Generate pm_clksd
//
assign pm_clksd = sdf;

//
// Statically generate all clock gate outputs
// TODO: add dynamic clock gating feature
//
assign pm_cpu_gate = (dme | sme) & ~pic_wakeup;
assign pm_dc_gate = pm_cpu_gate;
assign pm_ic_gate = pm_cpu_gate;
assign pm_dmmu_gate = pm_cpu_gate;
assign pm_immu_gate = pm_cpu_gate;
assign pm_tt_gate = sme & ~pic_wakeup;

//
// Assert pm_wakeup when pic_wakeup is asserted
//
assign pm_wakeup = pic_wakeup;

//
// Assert pm_lvolt when pm_cpu_gate or pm_cpustall are asserted
//
assign pm_lvolt = pm_cpu_gate | pm_cpustall;

`else

//
// When PM is not implemented, drive all outputs as would when PM is disabled
//
assign pm_clksd = 4'b0;
assign pm_cpu_gate = 1'b0;
assign pm_dc_gate = 1'b0;
assign pm_ic_gate = 1'b0;
assign pm_dmmu_gate = 1'b0;
assign pm_immu_gate = 1'b0;
assign pm_tt_gate = 1'b0;
assign pm_wakeup = 1'b1;
assign pm_lvolt = 1'b0;

//
// Read PMR
//
`ifdef OR1200_PM_READREGS
assign spr_dat_o[`OR1200_PM_PMR_SDF] = 4'b0;
assign spr_dat_o[`OR1200_PM_PMR_DME] = 1'b0;
assign spr_dat_o[`OR1200_PM_PMR_SME] = 1'b0;
assign spr_dat_o[`OR1200_PM_PMR_DCGE] = 1'b0;
`ifdef OR1200_PM_UNUSED_ZERO
assign spr_dat_o[`OR1200_PM_PMR_UNUSED] = 25'b0;
`endif
`endif

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Embedded Memory                                    ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Embedded Memory               .                             ////
////                                                              ////
////  To Do:                                                      ////
////   - QMEM and IC/DC muxes can be removed except for cycstb    ////
////     (now are is there for easier debugging)                  ////
////   - currently arbitration is slow and stores take 2 clocks   ////
////     (final debugged version will be faster)                  ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2003 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_qmem_top.v,v $
// Revision 1.3  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.2  2004/04/05 08:40:26  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.1.2.4  2004/01/11 22:45:46  andreje
// Separate instruction and data QMEM decoders, QMEM acknowledge and byte-select added
//
// Revision 1.1.2.3  2003/12/17 13:36:58  simons
// Qmem mbist signals fixed.
//
// Revision 1.1.2.2  2003/12/09 11:46:48  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.1.2.1  2003/07/08 15:45:26  lampret
// Added embedded memory QMEM.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

`define OR1200_QMEMFSM_IDLE	3'd0
`define OR1200_QMEMFSM_STORE	3'd1
`define OR1200_QMEMFSM_LOAD	3'd2
`define OR1200_QMEMFSM_FETCH	3'd3

//
// Embedded memory
//
module or1200_qmem_top(
	// Rst, clk and clock control
	clk, rst,

`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif

	// QMEM and CPU/IMMU
	qmemimmu_adr_i,
	qmemimmu_cycstb_i,
	qmemimmu_ci_i,
	qmemicpu_sel_i, 
	qmemicpu_tag_i, 
	qmemicpu_dat_o,
	qmemicpu_ack_o,
	qmemimmu_rty_o,
	qmemimmu_err_o,
	qmemimmu_tag_o,

	// QMEM and IC
	icqmem_adr_o,
	icqmem_cycstb_o,
	icqmem_ci_o,  
	icqmem_sel_o,
	icqmem_tag_o,
	icqmem_dat_i,
	icqmem_ack_i,
	icqmem_rty_i,
	icqmem_err_i,
	icqmem_tag_i,

	// QMEM and CPU/DMMU
	qmemdmmu_adr_i,
	qmemdmmu_cycstb_i,
	qmemdmmu_ci_i,
	qmemdcpu_we_i,   
	qmemdcpu_sel_i, 
	qmemdcpu_tag_i, 
	qmemdcpu_dat_i, 
	qmemdcpu_dat_o,
	qmemdcpu_ack_o,
	qmemdcpu_rty_o,
	qmemdmmu_err_o,
	qmemdmmu_tag_o,

	// QMEM and DC
	dcqmem_adr_o, dcqmem_cycstb_o, dcqmem_ci_o,
	dcqmem_we_o, dcqmem_sel_o, dcqmem_tag_o, dcqmem_dat_o,
	dcqmem_dat_i, dcqmem_ack_i, dcqmem_rty_i, dcqmem_err_i, dcqmem_tag_i

);

parameter dw = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// QMEM and CPU/IMMU
//
input	[31:0]			qmemimmu_adr_i;
input				qmemimmu_cycstb_i;
input				qmemimmu_ci_i;
input	[3:0]			qmemicpu_sel_i; 
input	[3:0]			qmemicpu_tag_i; 
output	[31:0]			qmemicpu_dat_o;
output				qmemicpu_ack_o;
output				qmemimmu_rty_o;
output				qmemimmu_err_o;
output	[3:0]			qmemimmu_tag_o;

//
// QMEM and IC
//
output	[31:0]			icqmem_adr_o;
output				icqmem_cycstb_o;
output				icqmem_ci_o;
output	[3:0]			icqmem_sel_o;
output	[3:0]			icqmem_tag_o;
input	[31:0]			icqmem_dat_i;
input				icqmem_ack_i;
input				icqmem_rty_i;
input				icqmem_err_i;
input	[3:0]			icqmem_tag_i;

//
// QMEM and CPU/DMMU
//
input	[31:0]			qmemdmmu_adr_i;
input				qmemdmmu_cycstb_i;
input				qmemdmmu_ci_i;
input				qmemdcpu_we_i;
input	[3:0]			qmemdcpu_sel_i; 
input	[3:0]			qmemdcpu_tag_i; 
input	[31:0]			qmemdcpu_dat_i; 
output	[31:0]			qmemdcpu_dat_o;
output				qmemdcpu_ack_o;
output				qmemdcpu_rty_o;
output				qmemdmmu_err_o;
output	[3:0]			qmemdmmu_tag_o;

//
// QMEM and DC
//
output	[31:0]			dcqmem_adr_o;
output				dcqmem_cycstb_o;
output				dcqmem_ci_o;
output				dcqmem_we_o;
output	[3:0]			dcqmem_sel_o;
output	[3:0]			dcqmem_tag_o;
output	[dw-1:0]		dcqmem_dat_o;
input	[dw-1:0]		dcqmem_dat_i;
input				dcqmem_ack_i;
input				dcqmem_rty_i;
input				dcqmem_err_i;
input	[3:0]			dcqmem_tag_i;

`ifdef OR1200_QMEM_IMPLEMENTED

//
// Internal regs and wires
//
wire				iaddr_qmem_hit;
wire				daddr_qmem_hit;
reg	[2:0]			state;
reg				qmem_dack;
reg				qmem_iack;
wire	[31:0]			qmem_di;
wire	[31:0]			qmem_do;
wire				qmem_en;
wire				qmem_we;
`ifdef OR1200_QMEM_BSEL
wire  [3:0]       qmem_sel;
`endif
wire	[31:0]			qmem_addr;
`ifdef OR1200_QMEM_ACK
wire              qmem_ack;
`else
wire              qmem_ack = 1'b1;
`endif

//
// QMEM and CPU/IMMU
//
assign qmemicpu_dat_o = qmem_iack ? qmem_do : icqmem_dat_i;
assign qmemicpu_ack_o = qmem_iack ? 1'b1 : icqmem_ack_i;
assign qmemimmu_rty_o = qmem_iack ? 1'b0 : icqmem_rty_i;
assign qmemimmu_err_o = qmem_iack ? 1'b0 : icqmem_err_i;
assign qmemimmu_tag_o = qmem_iack ? 4'h0 : icqmem_tag_i;

//
// QMEM and IC
//
assign icqmem_adr_o = iaddr_qmem_hit ? 32'h0000_0000 : qmemimmu_adr_i;
assign icqmem_cycstb_o = iaddr_qmem_hit ? 1'b0 : qmemimmu_cycstb_i;
assign icqmem_ci_o = iaddr_qmem_hit ? 1'b0 : qmemimmu_ci_i;
assign icqmem_sel_o = iaddr_qmem_hit ? 4'h0 : qmemicpu_sel_i;
assign icqmem_tag_o = iaddr_qmem_hit ? 4'h0 : qmemicpu_tag_i;

//
// QMEM and CPU/DMMU
//
assign qmemdcpu_dat_o = daddr_qmem_hit ? qmem_do : dcqmem_dat_i;
assign qmemdcpu_ack_o = daddr_qmem_hit ? qmem_dack : dcqmem_ack_i;
assign qmemdcpu_rty_o = daddr_qmem_hit ? ~qmem_dack : dcqmem_rty_i;
assign qmemdmmu_err_o = daddr_qmem_hit ? 1'b0 : dcqmem_err_i;
assign qmemdmmu_tag_o = daddr_qmem_hit ? 4'h0 : dcqmem_tag_i;

//
// QMEM and DC
//
assign dcqmem_adr_o = daddr_qmem_hit ? 32'h0000_0000 : qmemdmmu_adr_i;
assign dcqmem_cycstb_o = daddr_qmem_hit ? 1'b0 : qmemdmmu_cycstb_i;
assign dcqmem_ci_o = daddr_qmem_hit ? 1'b0 : qmemdmmu_ci_i;
assign dcqmem_we_o = daddr_qmem_hit ? 1'b0 : qmemdcpu_we_i;
assign dcqmem_sel_o = daddr_qmem_hit ? 4'h0 : qmemdcpu_sel_i;
assign dcqmem_tag_o = daddr_qmem_hit ? 4'h0 : qmemdcpu_tag_i;
assign dcqmem_dat_o = daddr_qmem_hit ? 32'h0000_0000 : qmemdcpu_dat_i;

//
// Address comparison whether QMEM was hit
//
`ifdef OR1200_QMEM_IADDR
assign iaddr_qmem_hit = (qmemimmu_adr_i & `OR1200_QMEM_IMASK) == `OR1200_QMEM_IADDR;
`else
assign iaddr_qmem_hit = 1'b0;
`endif

`ifdef OR1200_QMEM_DADDR
assign daddr_qmem_hit = (qmemdmmu_adr_i & `OR1200_QMEM_DMASK) == `OR1200_QMEM_DADDR;
`else
assign daddr_qmem_hit = 1'b0;
`endif

//
//
//
assign qmem_en = iaddr_qmem_hit & qmemimmu_cycstb_i | daddr_qmem_hit & qmemdmmu_cycstb_i;
assign qmem_we = qmemdmmu_cycstb_i & daddr_qmem_hit & qmemdcpu_we_i;
`ifdef OR1200_QMEM_BSEL
assign qmem_sel = (qmemdmmu_cycstb_i & daddr_qmem_hit) ? qmemdcpu_sel_i : qmemicpu_sel_i;
`endif
assign qmem_di = qmemdcpu_dat_i;
assign qmem_addr = (qmemdmmu_cycstb_i & daddr_qmem_hit) ? qmemdmmu_adr_i : qmemimmu_adr_i;

//
// QMEM control FSM
//
always @(posedge rst or posedge clk)
	if (rst) begin
		state <= #1 `OR1200_QMEMFSM_IDLE;
		qmem_dack <= #1 1'b0;
		qmem_iack <= #1 1'b0;
	end
	else case (state)	// synopsys parallel_case
		`OR1200_QMEMFSM_IDLE: begin
			if (qmemdmmu_cycstb_i & daddr_qmem_hit & qmemdcpu_we_i & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_STORE;
				qmem_dack <= #1 1'b1;
				qmem_iack <= #1 1'b0;
			end
			else if (qmemdmmu_cycstb_i & daddr_qmem_hit & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_LOAD;
				qmem_dack <= #1 1'b1;
				qmem_iack <= #1 1'b0;
			end
			else if (qmemimmu_cycstb_i & iaddr_qmem_hit & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_FETCH;
				qmem_iack <= #1 1'b1;
				qmem_dack <= #1 1'b0;
			end
		end
		`OR1200_QMEMFSM_STORE: begin
			if (qmemdmmu_cycstb_i & daddr_qmem_hit & qmemdcpu_we_i & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_STORE;
				qmem_dack <= #1 1'b1;
				qmem_iack <= #1 1'b0;
			end
			else if (qmemdmmu_cycstb_i & daddr_qmem_hit & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_LOAD;
				qmem_dack <= #1 1'b1;
				qmem_iack <= #1 1'b0;
			end
			else if (qmemimmu_cycstb_i & iaddr_qmem_hit & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_FETCH;
				qmem_iack <= #1 1'b1;
				qmem_dack <= #1 1'b0;
			end
			else begin
				state <= #1 `OR1200_QMEMFSM_IDLE;
				qmem_dack <= #1 1'b0;
				qmem_iack <= #1 1'b0;
			end
		end
		`OR1200_QMEMFSM_LOAD: begin
			if (qmemdmmu_cycstb_i & daddr_qmem_hit & qmemdcpu_we_i & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_STORE;
				qmem_dack <= #1 1'b1;
				qmem_iack <= #1 1'b0;
			end
			else if (qmemdmmu_cycstb_i & daddr_qmem_hit & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_LOAD;
				qmem_dack <= #1 1'b1;
				qmem_iack <= #1 1'b0;
			end
			else if (qmemimmu_cycstb_i & iaddr_qmem_hit & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_FETCH;
				qmem_iack <= #1 1'b1;
				qmem_dack <= #1 1'b0;
			end
			else begin
				state <= #1 `OR1200_QMEMFSM_IDLE;
				qmem_dack <= #1 1'b0;
				qmem_iack <= #1 1'b0;
			end
		end
		`OR1200_QMEMFSM_FETCH: begin
			if (qmemdmmu_cycstb_i & daddr_qmem_hit & qmemdcpu_we_i & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_STORE;
				qmem_dack <= #1 1'b1;
				qmem_iack <= #1 1'b0;
			end
			else if (qmemdmmu_cycstb_i & daddr_qmem_hit & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_LOAD;
				qmem_dack <= #1 1'b1;
				qmem_iack <= #1 1'b0;
			end
			else if (qmemimmu_cycstb_i & iaddr_qmem_hit & qmem_ack) begin
				state <= #1 `OR1200_QMEMFSM_FETCH;
				qmem_iack <= #1 1'b1;
				qmem_dack <= #1 1'b0;
			end
			else begin
				state <= #1 `OR1200_QMEMFSM_IDLE;
				qmem_dack <= #1 1'b0;
				qmem_iack <= #1 1'b0;
			end
		end
		default: begin
			state <= #1 `OR1200_QMEMFSM_IDLE;
			qmem_dack <= #1 1'b0;
			qmem_iack <= #1 1'b0;
		end
	endcase

//
// Instantiation of embedded memory
//
or1200_spram_2048x32 or1200_qmem_ram(
	.clk(clk),
	.rst(rst),
`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_si_i),
	.mbist_so_o(mbist_so_o),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif
	.addr(qmem_addr[12:2]),
`ifdef OR1200_QMEM_BSEL
	.sel(qmem_sel),
`endif
`ifdef OR1200_QMEM_ACK
  .ack(qmem_ack),
`endif
  .ce(qmem_en),
	.we(qmem_we),
	.oe(1'b1),
	.di(qmem_di),
	.doq(qmem_do)
);

`else  // OR1200_QMEM_IMPLEMENTED

//
// QMEM and CPU/IMMU
//
assign qmemicpu_dat_o = icqmem_dat_i;
assign qmemicpu_ack_o = icqmem_ack_i;
assign qmemimmu_rty_o = icqmem_rty_i;
assign qmemimmu_err_o = icqmem_err_i;
assign qmemimmu_tag_o = icqmem_tag_i;

//
// QMEM and IC
//
assign icqmem_adr_o = qmemimmu_adr_i;
assign icqmem_cycstb_o = qmemimmu_cycstb_i;
assign icqmem_ci_o = qmemimmu_ci_i;
assign icqmem_sel_o = qmemicpu_sel_i;
assign icqmem_tag_o = qmemicpu_tag_i;

//
// QMEM and CPU/DMMU
//
assign qmemdcpu_dat_o = dcqmem_dat_i;
assign qmemdcpu_ack_o = dcqmem_ack_i;
assign qmemdcpu_rty_o = dcqmem_rty_i;
assign qmemdmmu_err_o = dcqmem_err_i;
assign qmemdmmu_tag_o = dcqmem_tag_i;

//
// QMEM and DC
//
assign dcqmem_adr_o = qmemdmmu_adr_i;
assign dcqmem_cycstb_o = qmemdmmu_cycstb_i;
assign dcqmem_ci_o = qmemdmmu_ci_i;
assign dcqmem_we_o = qmemdcpu_we_i;
assign dcqmem_sel_o = qmemdcpu_sel_i;
assign dcqmem_tag_o = qmemdcpu_tag_i;
assign dcqmem_dat_o = qmemdcpu_dat_i;

`ifdef OR1200_BIST
assign mbist_so_o = mbist_si_i;
`endif

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's reg2mem aligner                                    ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Aligns register data to memory alignment.                   ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_reg2mem.v,v $
// Revision 1.2  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/19 23:28:46  lampret
// Fixed some synthesis warnings. Configured with caches and MMUs.
//
// Revision 1.7  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:21  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_reg2mem(addr, lsu_op, regdata, memdata);

parameter width = `OR1200_OPERAND_WIDTH;

//
// I/O
//
input	[1:0]			addr;
input	[`OR1200_LSUOP_WIDTH-1:0]	lsu_op;
input	[width-1:0]		regdata;
output	[width-1:0]		memdata;

//
// Internal regs and wires
//
reg	[7:0]			memdata_hh;
reg	[7:0]			memdata_hl;
reg	[7:0]			memdata_lh;
reg	[7:0]			memdata_ll;

assign memdata = {memdata_hh, memdata_hl, memdata_lh, memdata_ll};

//
// Mux to memdata[31:24]
//
always @(lsu_op or addr or regdata) begin
	casex({lsu_op, addr[1:0]})	// synopsys parallel_case
		{`OR1200_LSUOP_SB, 2'b00} : memdata_hh = regdata[7:0];
		{`OR1200_LSUOP_SH, 2'b00} : memdata_hh = regdata[15:8];
		default : memdata_hh = regdata[31:24];
	endcase
end

//
// Mux to memdata[23:16]
//
always @(lsu_op or addr or regdata) begin
	casex({lsu_op, addr[1:0]})	// synopsys parallel_case
		{`OR1200_LSUOP_SW, 2'b00} : memdata_hl = regdata[23:16];
		default : memdata_hl = regdata[7:0];
	endcase
end

//
// Mux to memdata[15:8]
//
always @(lsu_op or addr or regdata) begin
	casex({lsu_op, addr[1:0]})	// synopsys parallel_case
		{`OR1200_LSUOP_SB, 2'b10} : memdata_lh = regdata[7:0];
		default : memdata_lh = regdata[15:8];
	endcase
end

//
// Mux to memdata[7:0]
//
always @(regdata)
	memdata_ll = regdata[7:0];

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's register file inside CPU                           ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Instantiation of register file memories                     ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_rf.v,v $
// Revision 1.3  2003/04/07 01:21:56  lampret
// RFRAM type always need to be defined.
//
// Revision 1.2  2002/06/08 16:19:09  lampret
// Added generic flip-flop based memory macro instantiation.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.13  2001/11/20 18:46:15  simons
// Break point bug fixed
//
// Revision 1.12  2001/11/13 10:02:21  lampret
// Added 'setpc'. Renamed some signals (except_flushpipe into flushpipe etc)
//
// Revision 1.11  2001/11/12 01:45:40  lampret
// Moved flag bit into SR. Changed RF enable from constant enable to dynamic enable for read ports.
//
// Revision 1.10  2001/11/10 03:43:57  lampret
// Fixed exceptions.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.3  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/22 03:31:54  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:21  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_rf(
	// Clock and reset
	clk, rst,

	// Write i/f
	cy_we_i, cy_we_o, supv, wb_freeze, addrw, dataw, we, flushpipe,

	// Read i/f
	id_freeze, addra, addrb, dataa, datab, rda, rdb,

	// Debug
	spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_REGFILE_ADDR_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// Write i/f
//
input				cy_we_i;
output				cy_we_o;
input				supv;
input				wb_freeze;
input	[aw-1:0]		addrw;
input	[dw-1:0]		dataw;
input				we;
input				flushpipe;

//
// Read i/f
//
input				id_freeze;
input	[aw-1:0]		addra;
input	[aw-1:0]		addrb;
output	[dw-1:0]		dataa;
output	[dw-1:0]		datab;
input				rda;
input				rdb;

//
// SPR access for debugging purposes
//
input				spr_cs;
input				spr_write;
input	[31:0]			spr_addr;
input	[31:0]			spr_dat_i;
output	[31:0]			spr_dat_o;

//
// Internal wires and regs
//
wire	[dw-1:0]		from_rfa;
wire	[dw-1:0]		from_rfb;
reg	[dw:0]			dataa_saved;
reg	[dw:0]			datab_saved;
wire	[aw-1:0]		rf_addra;
wire	[aw-1:0]		rf_addrw;
wire	[dw-1:0]		rf_dataw;
wire				rf_we;
wire				spr_valid;
wire				rf_ena;
wire				rf_enb;
reg				rf_we_allow;

//
// SPR access is valid when spr_cs is asserted and
// SPR address matches GPR addresses
//
assign spr_valid = spr_cs & (spr_addr[10:5] == `OR1200_SPR_RF);

//
// SPR data output is always from RF A
//
assign spr_dat_o = from_rfa;

//
// Operand A comes from RF or from saved A register
//
assign dataa = (dataa_saved[32]) ? dataa_saved[31:0] : from_rfa;

//
// Operand B comes from RF or from saved B register
//
assign datab = (datab_saved[32]) ? datab_saved[31:0] : from_rfb;

//
// RF A read address is either from SPRS or normal from CPU control
//
assign rf_addra = (spr_valid & !spr_write) ? spr_addr[4:0] : addra;

//
// RF write address is either from SPRS or normal from CPU control
//
assign rf_addrw = (spr_valid & spr_write) ? spr_addr[4:0] : addrw;

//
// RF write data is either from SPRS or normal from CPU datapath
//
assign rf_dataw = (spr_valid & spr_write) ? spr_dat_i : dataw;

//
// RF write enable is either from SPRS or normal from CPU control
//
always @(posedge rst or posedge clk)
	if (rst)
		rf_we_allow <= #1 1'b1;
	else if (~wb_freeze)
		rf_we_allow <= #1 ~flushpipe;

assign rf_we = ((spr_valid & spr_write) | (we & ~wb_freeze)) & rf_we_allow & (supv | (|rf_addrw));
assign cy_we_o = cy_we_i && rf_we ;

//
// CS RF A asserted when instruction reads operand A and ID stage
// is not stalled
//
assign rf_ena = rda & ~id_freeze | spr_valid;	// probably works with fixed binutils
// assign rf_ena = 1'b1;			// does not work with single-stepping
//assign rf_ena = ~id_freeze | spr_valid;	// works with broken binutils 

//
// CS RF B asserted when instruction reads operand B and ID stage
// is not stalled
//
assign rf_enb = rdb & ~id_freeze | spr_valid;
// assign rf_enb = 1'b1;
//assign rf_enb = ~id_freeze | spr_valid;	// works with broken binutils 

//
// Stores operand from RF_A into temp reg when pipeline is frozen
//
always @(posedge clk or posedge rst)
	if (rst) begin
		dataa_saved <= #1 33'b0;
	end
	else if (id_freeze & !dataa_saved[32]) begin
		dataa_saved <= #1 {1'b1, from_rfa};
	end
	else if (!id_freeze)
		dataa_saved <= #1 33'b0;

//
// Stores operand from RF_B into temp reg when pipeline is frozen
//
always @(posedge clk or posedge rst)
	if (rst) begin
		datab_saved <= #1 33'b0;
	end
	else if (id_freeze & !datab_saved[32]) begin
		datab_saved <= #1 {1'b1, from_rfb};
	end
	else if (!id_freeze)
		datab_saved <= #1 33'b0;

`ifdef OR1200_RFRAM_TWOPORT

//
// Instantiation of register file two-port RAM A
//
or1200_tpram_32x32 rf_a(
	// Port A
	.clk_a(clk),
	.rst_a(rst),
	.ce_a(rf_ena),
	.we_a(1'b0),
	.oe_a(1'b1),
	.addr_a(rf_addra),
	.di_a(32'h0000_0000),
	.do_a(from_rfa),

	// Port B
	.clk_b(clk),
	.rst_b(rst),
	.ce_b(rf_we),
	.we_b(rf_we),
	.oe_b(1'b0),
	.addr_b(rf_addrw),
	.di_b(rf_dataw),
	.do_b()
);

//
// Instantiation of register file two-port RAM B
//
or1200_tpram_32x32 rf_b(
	// Port A
	.clk_a(clk),
	.rst_a(rst),
	.ce_a(rf_enb),
	.we_a(1'b0),
	.oe_a(1'b1),
	.addr_a(addrb),
	.di_a(32'h0000_0000),
	.do_a(from_rfb),

	// Port B
	.clk_b(clk),
	.rst_b(rst),
	.ce_b(rf_we),
	.we_b(rf_we),
	.oe_b(1'b0),
	.addr_b(rf_addrw),
	.di_b(rf_dataw),
	.do_b()
);

`else

`ifdef OR1200_RFRAM_DUALPORT

//
// Instantiation of register file two-port RAM A
//
   or1200_dpram #
     (
      .aw(5),
      .dw(32)
      )
   rf_a
     (
      // Port A
      .clk_a(clk),
      .ce_a(rf_ena),
      .addr_a(rf_addra),
      .do_a(from_rfa),
      
      // Port B
      .clk_b(clk),
      .ce_b(rf_we),
      .we_b(rf_we),
      .addr_b(rf_addrw),
      .di_b(rf_dataw)
      );

   //
   // Instantiation of register file two-port RAM B
   //
   or1200_dpram #
     (
      .aw(5),
      .dw(32)
      )
   rf_b
     (
      // Port A
      .clk_a(clk),
      .ce_a(rf_enb),
      .addr_a(addrb),
      .do_a(from_rfb),
      
      // Port B
      .clk_b(clk),
      .ce_b(rf_we),
      .we_b(rf_we),
      .addr_b(rf_addrw),
      .di_b(rf_dataw)
      );
   
`else

`ifdef OR1200_RFRAM_GENERIC

//
// Instantiation of generic (flip-flop based) register file
//
or1200_rfram_generic rf_a(
	// Clock and reset
	.clk(clk),
	.rst(rst),

	// Port A
	.ce_a(rf_ena),
	.addr_a(rf_addra),
	.do_a(from_rfa),

	// Port B
	.ce_b(rf_enb),
	.addr_b(addrb),
	.do_b(from_rfb),

	// Port W
	.ce_w(rf_we),
	.we_w(rf_we),
	.addr_w(rf_addrw),
	.di_w(rf_dataw)
);

`else

//
// RFRAM type not specified
//
initial begin
	$display("Define RFRAM type.");
	$finish;
end

`endif
`endif
`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's register file generic memory                       ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Generic (flip-flop based) register file memory              ////
////                                                              ////
////  To Do:                                                      ////
////   - nothing                                                  ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_rfram_generic.v,v $
// Revision 1.3  2004/06/08 18:16:32  lampret
// GPR0 hardwired to zero.
//
// Revision 1.2  2002/09/03 22:28:21  lampret
// As per Taylor Su suggestion all case blocks are full case by default and optionally (OR1200_CASE_DEFAULT) can be disabled to increase clock frequncy.
//
// Revision 1.1  2002/06/08 16:23:30  lampret
// Generic flip-flop based memory macro for register file.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_rfram_generic(
	// Clock and reset
	clk, rst,

	// Port A
	ce_a, addr_a, do_a,

	// Port B
	ce_b, addr_b, do_b,

	// Port W
	ce_w, we_w, addr_w, di_w
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_REGFILE_ADDR_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// Port A
//
input				ce_a;
input	[aw-1:0]		addr_a;
output	[dw-1:0]		do_a;

//
// Port B
//
input				ce_b;
input	[aw-1:0]		addr_b;
output	[dw-1:0]		do_b;

//
// Port W
//
input				ce_w;
input				we_w;
input	[aw-1:0]		addr_w;
input	[dw-1:0]		di_w;

//
// Internal wires and regs
//
reg	[aw-1:0]		intaddr_a;
reg	[aw-1:0]		intaddr_b;
`ifdef OR1200_RFRAM_16REG
reg	[16*dw-1:0]		mem;
`else
reg	[32*dw-1:0]		mem;
`endif
reg	[dw-1:0]		do_a;
reg	[dw-1:0]		do_b;

//
// Write port
//
always @(posedge clk or posedge rst)
	if (rst) begin
		mem <= #1 {512'h0, 512'h0};
	end
	else if (ce_w & we_w)
		case (addr_w)	// synopsys parallel_case
			5'd01: mem[32*1+31:32*1] <= #1 di_w;
			5'd02: mem[32*2+31:32*2] <= #1 di_w;
			5'd03: mem[32*3+31:32*3] <= #1 di_w;
			5'd04: mem[32*4+31:32*4] <= #1 di_w;
			5'd05: mem[32*5+31:32*5] <= #1 di_w;
			5'd06: mem[32*6+31:32*6] <= #1 di_w;
			5'd07: mem[32*7+31:32*7] <= #1 di_w;
			5'd08: mem[32*8+31:32*8] <= #1 di_w;
			5'd09: mem[32*9+31:32*9] <= #1 di_w;
			5'd10: mem[32*10+31:32*10] <= #1 di_w;
			5'd11: mem[32*11+31:32*11] <= #1 di_w;
			5'd12: mem[32*12+31:32*12] <= #1 di_w;
			5'd13: mem[32*13+31:32*13] <= #1 di_w;
			5'd14: mem[32*14+31:32*14] <= #1 di_w;
			5'd15: mem[32*15+31:32*15] <= #1 di_w;
`ifdef OR1200_RFRAM_16REG
`else
			5'd16: mem[32*16+31:32*16] <= #1 di_w;
			5'd17: mem[32*17+31:32*17] <= #1 di_w;
			5'd18: mem[32*18+31:32*18] <= #1 di_w;
			5'd19: mem[32*19+31:32*19] <= #1 di_w;
			5'd20: mem[32*20+31:32*20] <= #1 di_w;
			5'd21: mem[32*21+31:32*21] <= #1 di_w;
			5'd22: mem[32*22+31:32*22] <= #1 di_w;
			5'd23: mem[32*23+31:32*23] <= #1 di_w;
			5'd24: mem[32*24+31:32*24] <= #1 di_w;
			5'd25: mem[32*25+31:32*25] <= #1 di_w;
			5'd26: mem[32*26+31:32*26] <= #1 di_w;
			5'd27: mem[32*27+31:32*27] <= #1 di_w;
			5'd28: mem[32*28+31:32*28] <= #1 di_w;
			5'd29: mem[32*29+31:32*29] <= #1 di_w;
			5'd30: mem[32*30+31:32*30] <= #1 di_w;
			5'd31: mem[32*31+31:32*31] <= #1 di_w;
`endif
			default: mem[32*0+31:32*0] <= #1 32'h0000_0000;
		endcase

//
// Read port A
//
always @(posedge clk or posedge rst)
	if (rst) begin
		intaddr_a <= #1 5'h00;
	end
	else if (ce_a)
		intaddr_a <= #1 addr_a;

always @(mem or intaddr_a)
	case (intaddr_a)	// synopsys parallel_case
		5'd01: do_a = mem[32*1+31:32*1];
		5'd02: do_a = mem[32*2+31:32*2];
		5'd03: do_a = mem[32*3+31:32*3];
		5'd04: do_a = mem[32*4+31:32*4];
		5'd05: do_a = mem[32*5+31:32*5];
		5'd06: do_a = mem[32*6+31:32*6];
		5'd07: do_a = mem[32*7+31:32*7];
		5'd08: do_a = mem[32*8+31:32*8];
		5'd09: do_a = mem[32*9+31:32*9];
		5'd10: do_a = mem[32*10+31:32*10];
		5'd11: do_a = mem[32*11+31:32*11];
		5'd12: do_a = mem[32*12+31:32*12];
		5'd13: do_a = mem[32*13+31:32*13];
		5'd14: do_a = mem[32*14+31:32*14];
		5'd15: do_a = mem[32*15+31:32*15];
`ifdef OR1200_RFRAM_16REG
`else
		5'd16: do_a = mem[32*16+31:32*16];
		5'd17: do_a = mem[32*17+31:32*17];
		5'd18: do_a = mem[32*18+31:32*18];
		5'd19: do_a = mem[32*19+31:32*19];
		5'd20: do_a = mem[32*20+31:32*20];
		5'd21: do_a = mem[32*21+31:32*21];
		5'd22: do_a = mem[32*22+31:32*22];
		5'd23: do_a = mem[32*23+31:32*23];
		5'd24: do_a = mem[32*24+31:32*24];
		5'd25: do_a = mem[32*25+31:32*25];
		5'd26: do_a = mem[32*26+31:32*26];
		5'd27: do_a = mem[32*27+31:32*27];
		5'd28: do_a = mem[32*28+31:32*28];
		5'd29: do_a = mem[32*29+31:32*29];
		5'd30: do_a = mem[32*30+31:32*30];
		5'd31: do_a = mem[32*31+31:32*31];
`endif
		default: do_a = 32'h0000_0000;
	endcase

//
// Read port B
//
always @(posedge clk or posedge rst)
	if (rst) begin
		intaddr_b <= #1 5'h00;
	end
	else if (ce_b)
		intaddr_b <= #1 addr_b;

always @(mem or intaddr_b)
	case (intaddr_b)	// synopsys parallel_case
		5'd01: do_b = mem[32*1+31:32*1];
		5'd02: do_b = mem[32*2+31:32*2];
		5'd03: do_b = mem[32*3+31:32*3];
		5'd04: do_b = mem[32*4+31:32*4];
		5'd05: do_b = mem[32*5+31:32*5];
		5'd06: do_b = mem[32*6+31:32*6];
		5'd07: do_b = mem[32*7+31:32*7];
		5'd08: do_b = mem[32*8+31:32*8];
		5'd09: do_b = mem[32*9+31:32*9];
		5'd10: do_b = mem[32*10+31:32*10];
		5'd11: do_b = mem[32*11+31:32*11];
		5'd12: do_b = mem[32*12+31:32*12];
		5'd13: do_b = mem[32*13+31:32*13];
		5'd14: do_b = mem[32*14+31:32*14];
		5'd15: do_b = mem[32*15+31:32*15];
`ifdef OR1200_RFRAM_16REG
`else
		5'd16: do_b = mem[32*16+31:32*16];
		5'd17: do_b = mem[32*17+31:32*17];
		5'd18: do_b = mem[32*18+31:32*18];
		5'd19: do_b = mem[32*19+31:32*19];
		5'd20: do_b = mem[32*20+31:32*20];
		5'd21: do_b = mem[32*21+31:32*21];
		5'd22: do_b = mem[32*22+31:32*22];
		5'd23: do_b = mem[32*23+31:32*23];
		5'd24: do_b = mem[32*24+31:32*24];
		5'd25: do_b = mem[32*25+31:32*25];
		5'd26: do_b = mem[32*26+31:32*26];
		5'd27: do_b = mem[32*27+31:32*27];
		5'd28: do_b = mem[32*28+31:32*28];
		5'd29: do_b = mem[32*29+31:32*29];
		5'd30: do_b = mem[32*30+31:32*30];
		5'd31: do_b = mem[32*31+31:32*31];
`endif
		default: do_b = 32'h0000_0000;
	endcase

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Store Buffer                                       ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Implements store buffer.                                    ////
////                                                              ////
////  To Do:                                                      ////
////   - byte combining                                           ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_sb.v,v $
// Revision 1.2  2002/08/22 02:18:55  lampret
// Store buffer has been tested and it works. BY default it is still disabled until uClinux confirms correct operation on FPGA board.
//
// Revision 1.1  2002/08/18 19:53:08  lampret
// Added store buffer.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_sb(
	// RISC clock, reset
	clk, rst,

	// Internal RISC bus (DC<->SB)
	dcsb_dat_i, dcsb_adr_i, dcsb_cyc_i, dcsb_stb_i, dcsb_we_i, dcsb_sel_i, dcsb_cab_i,
	dcsb_dat_o, dcsb_ack_o, dcsb_err_o,

	// BIU bus
	sbbiu_dat_o, sbbiu_adr_o, sbbiu_cyc_o, sbbiu_stb_o, sbbiu_we_o, sbbiu_sel_o, sbbiu_cab_o,
	sbbiu_dat_i, sbbiu_ack_i, sbbiu_err_i
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;

//
// RISC clock, reset
//
input			clk;		// RISC clock
input			rst;		// RISC reset

//
// Internal RISC bus (DC<->SB)
//
input	[dw-1:0]	dcsb_dat_i;	// input data bus
input	[aw-1:0]	dcsb_adr_i;	// address bus
input			dcsb_cyc_i;	// WB cycle
input			dcsb_stb_i;	// WB strobe
input			dcsb_we_i;	// WB write enable
input			dcsb_cab_i;	// CAB input
input	[3:0]		dcsb_sel_i;	// byte selects
output	[dw-1:0]	dcsb_dat_o;	// output data bus
output			dcsb_ack_o;	// ack output
output			dcsb_err_o;	// err output

//
// BIU bus
//
output	[dw-1:0]	sbbiu_dat_o;	// output data bus
output	[aw-1:0]	sbbiu_adr_o;	// address bus
output			sbbiu_cyc_o;	// WB cycle
output			sbbiu_stb_o;	// WB strobe
output			sbbiu_we_o;	// WB write enable
output			sbbiu_cab_o;	// CAB input
output	[3:0]		sbbiu_sel_o;	// byte selects
input	[dw-1:0]	sbbiu_dat_i;	// input data bus
input			sbbiu_ack_i;	// ack output
input			sbbiu_err_i;	// err output

`ifdef OR1200_SB_IMPLEMENTED

//
// Internal wires and regs
//
wire	[4+dw+aw-1:0]	fifo_dat_i;	// FIFO data in
wire	[4+dw+aw-1:0]	fifo_dat_o;	// FIFO data out
wire			fifo_wr;
wire			fifo_rd;
wire			fifo_full;
wire			fifo_empty;
wire			sel_sb;
reg			outstanding_store;
reg			fifo_wr_ack;

//
// FIFO data in/out
//
assign fifo_dat_i = {dcsb_sel_i, dcsb_dat_i, dcsb_adr_i};
assign {sbbiu_sel_o, sbbiu_dat_o, sbbiu_adr_o} = sel_sb ? fifo_dat_o : {dcsb_sel_i, dcsb_dat_i, dcsb_adr_i};

//
// Control
//
assign fifo_wr = dcsb_cyc_i & dcsb_stb_i & dcsb_we_i & ~fifo_full & ~fifo_wr_ack;
assign fifo_rd = ~outstanding_store;
assign dcsb_dat_o = sbbiu_dat_i;
assign dcsb_ack_o = sel_sb ? fifo_wr_ack : sbbiu_ack_i;
assign dcsb_err_o = sel_sb ? 1'b0 : sbbiu_err_i;	// SB never returns error
assign sbbiu_cyc_o = sel_sb ? outstanding_store : dcsb_cyc_i;
assign sbbiu_stb_o = sel_sb ? outstanding_store : dcsb_stb_i;
assign sbbiu_we_o = sel_sb ? 1'b1 : dcsb_we_i;
assign sbbiu_cab_o = sel_sb ? 1'b0 : dcsb_cab_i;
assign sel_sb = ~fifo_empty | (fifo_empty & outstanding_store); // | fifo_wr;

//
// Store buffer FIFO instantiation
//
or1200_sb_fifo or1200_sb_fifo (
	.clk_i(clk),
	.rst_i(rst),
	.dat_i(fifo_dat_i),
	.wr_i(fifo_wr),
	.rd_i(fifo_rd),
	.dat_o(fifo_dat_o),
	.full_o(fifo_full),
	.empty_o(fifo_empty)
);

//
// fifo_rd
//
always @(posedge clk or posedge rst)
	if (rst)
		outstanding_store <= #1 1'b0;
	else if (sbbiu_ack_i)
		outstanding_store <= #1 1'b0;
	else if (sel_sb | fifo_wr)
		outstanding_store <= #1 1'b1;

//
// fifo_wr_ack
//
always @(posedge clk or posedge rst)
	if (rst)
		fifo_wr_ack <= #1 1'b0;
	else if (fifo_wr)
		fifo_wr_ack <= #1 1'b1;
	else
		fifo_wr_ack <= #1 1'b0;

`else	// !OR1200_SB_IMPLEMENTED

assign sbbiu_dat_o = dcsb_dat_i;
assign sbbiu_adr_o = dcsb_adr_i;
assign sbbiu_cyc_o = dcsb_cyc_i;
assign sbbiu_stb_o = dcsb_stb_i;
assign sbbiu_we_o = dcsb_we_i;
assign sbbiu_cab_o = dcsb_cab_i;
assign sbbiu_sel_o = dcsb_sel_i;
assign dcsb_dat_o = sbbiu_dat_i;
assign dcsb_ack_o = sbbiu_ack_i;
assign dcsb_err_o = sbbiu_err_i;

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Store Buffer FIFO                                  ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Implementation of store buffer FIFO.                        ////
////                                                              ////
////  To Do:                                                      ////
////   - N/A                                                      ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2002 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_sb_fifo.v,v $
// Revision 1.3  2002/11/06 13:53:41  simons
// SB mem width fixed.
//
// Revision 1.2  2002/08/22 02:18:55  lampret
// Store buffer has been tested and it works. BY default it is still disabled until uClinux confirms correct operation on FPGA board.
//
// Revision 1.1  2002/08/18 19:53:08  lampret
// Added store buffer.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_sb_fifo(
	clk_i, rst_i, dat_i, wr_i, rd_i, dat_o, full_o, empty_o
);

parameter dw = 68;
parameter fw = `OR1200_SB_LOG;
parameter fl = `OR1200_SB_ENTRIES;

//
// FIFO signals
//
input			clk_i;	// Clock
input			rst_i;	// Reset
input	[dw-1:0]	dat_i;	// Input data bus
input			wr_i;	// Write request
input			rd_i;	// Read request
output [dw-1:0]	dat_o;	// Output data bus
output			full_o;	// FIFO full
output			empty_o;// FIFO empty

//
// Internal regs
//
reg	[dw-1:0]	mem [fl-1:0];
reg	[dw-1:0]	dat_o;
reg	[fw+1:0]	cntr;
reg	[fw-1:0]	wr_pntr;
reg	[fw-1:0]	rd_pntr;
reg			empty_o;
reg			full_o;

always @(posedge clk_i or posedge rst_i)
	if (rst_i) begin
		full_o <= #1 1'b0;
		empty_o <= #1 1'b1;
		wr_pntr <= #1 {fw{1'b0}};
		rd_pntr <= #1 {fw{1'b0}};
		cntr <= #1 {fw+2{1'b0}};
		dat_o <= #1 {dw{1'b0}};
	end
	else if (wr_i && rd_i) begin		// FIFO Read and Write
		mem[wr_pntr] <= #1 dat_i;
		if (wr_pntr >= fl-1)
			wr_pntr <= #1 {fw{1'b0}};
		else
			wr_pntr <= #1 wr_pntr + 1'b1;
		if (empty_o) begin
			dat_o <= #1 dat_i;
		end
		else begin
			dat_o <= #1 mem[rd_pntr];
		end
		if (rd_pntr >= fl-1)
			rd_pntr <= #1 {fw{1'b0}};
		else
			rd_pntr <= #1 rd_pntr + 1'b1;
	end
	else if (wr_i && !full_o) begin		// FIFO Write
		mem[wr_pntr] <= #1 dat_i;
		cntr <= #1 cntr + 1'b1;
		empty_o <= #1 1'b0;
		if (cntr >= (fl-1)) begin
			full_o <= #1 1'b1;
			cntr <= #1 fl;
		end
		if (wr_pntr >= fl-1)
			wr_pntr <= #1 {fw{1'b0}};
		else
			wr_pntr <= #1 wr_pntr + 1'b1;
	end
	else if (rd_i && !empty_o) begin	// FIFO Read
		dat_o <= #1 mem[rd_pntr];
		cntr <= #1 cntr - 1'b1;
		full_o <= #1 1'b0;
		if (cntr <= 1) begin
			empty_o <= #1 1'b1;
			cntr <= #1 {fw+2{1'b0}};
		end
		if (rd_pntr >= fl-1)
			rd_pntr <= #1 {fw{1'b0}};
		else
			rd_pntr <= #1 rd_pntr + 1'b1;
	end

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Single-Port Synchronous RAM                         ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/generic_memories/     ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common single-port             ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides behavioral model of generic      ////
////  single-port synchronous RAM.                                ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Michael Unneback, unneback@opencores.org              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_spram
  (
`ifdef OR1200_BIST
   // RAM BIST
   mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif
   // Generic synchronous single-port RAM interface
   clk, ce, we, addr, di, doq
   );
   
   //
   // Default address and data buses width
   //
   parameter aw = 10;
   parameter dw = 32;
   
`ifdef OR1200_BIST
   //
   // RAM BIST
   //
   input mbist_si_i;
   input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
   output 				  mbist_so_o;
`endif
   
   //
   // Generic synchronous single-port RAM interface
   //
   input 				  clk;	// Clock
   input 				  ce;	// Chip enable input
   input 				  we;	// Write enable input
   //input 				  oe;	// Output enable input
   input [aw-1:0] 			  addr;	// address bus inputs
   input [dw-1:0] 			  di;	// input data bus
   output [dw-1:0] 			  doq;	// output data bus
   
   //
   // Internal wires and registers
   //

   //
   // Generic single-port synchronous RAM model
   //
   
   //
   // Generic RAM's registers and wires
   //
`ifdef OR1200_ACTEL   
   reg [dw-1:0] 			  mem [(1<<aw)-1:0] /*synthesis syn_ramstyle = "no_rw_check"*/;
`else
   reg [dw-1:0] 			  mem [(1<<aw)-1:0];
`endif
   reg [aw-1:0] 			  addr_reg;		// RAM address register
   
   //
   // Data output drivers
   //
   //assign doq = (oe) ? mem[addr_reg] : {dw{1'b0}};
   assign doq = mem[addr_reg];
   
   //
   // RAM read address register
   //
   always @(posedge clk)
     if (ce)
       addr_reg <= #1 addr;
   
   //
   // RAM write
   //
   always @(posedge clk)
     if (we && ce)
       mem[addr] <= #1 di;
   
endmodule // or1200_spram
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Single-Port Synchronous RAM with byte write signals ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/generic_memories/     ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common single-port             ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides behavioral model of generic      ////
////  single-port synchronous RAM.                                ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////      - Michael Unneback, unnneback@opencores.org             ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_spram_32_bw
  (
`ifdef OR1200_BIST
   // RAM BIST
   mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif
   // Generic synchronous single-port RAM interface
   clk, ce, we, addr, di, doq
   );

   //
   // Default address and data buses width
   //
   parameter aw = 5;
   parameter dw = 32;

`ifdef OR1200_BIST
   //
   // RAM BIST
   //
   input                   mbist_si_i;
   input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;       // bist chain shift control
   output 				  mbist_so_o;
`endif
   
   //
   // Generic synchronous single-port RAM interface
   //
   input 				  clk;    // Clock
   input 				  ce;     // Chip enable input
   input [(dw/8)-1:0] 			  we;     // Write enable input
   input [aw-1:0] 			  addr;   // address bus inputs
   input [dw-1:0] 			  di;     // input data bus
   output [dw-1:0] 			  doq;     // output data bus
   
   //
   // Generic single-port synchronous RAM model
   //
   
   //
   // Generic RAM's registers and wires
   //
`ifdef OR1200_ACTEL
   reg [7:0] 				  mem_0 [(1<<aw)-1:0] /*synthesis syn_ramstyle = "no_rw_check"*/; // RAM content
   reg [7:0] 				  mem_1 [(1<<aw)-1:0] /*synthesis syn_ramstyle = "no_rw_check"*/; // RAM content
   reg [7:0] 				  mem_2 [(1<<aw)-1:0] /*synthesis syn_ramstyle = "no_rw_check"*/; // RAM content
   reg [7:0] 				  mem_3 [(1<<aw)-1:0] /*synthesis syn_ramstyle = "no_rw_check"*/; // RAM content
`else
   reg [7:0] 				  mem_0 [(1<<aw)-1:0]; // RAM content
   reg [7:0] 				  mem_1 [(1<<aw)-1:0]; // RAM content
   reg [7:0] 				  mem_2 [(1<<aw)-1:0]; // RAM content
   reg [7:0] 				  mem_3 [(1<<aw)-1:0]; // RAM content
`endif
   reg [aw-1:0] 			  addr_reg;            // RAM address register

   //
   // Data output drivers
   //
   //assign doq = (oe) ? {mem_3[addr_reg], mem_2[addr_reg], mem_1[addr_reg], mem_0[addr_reg]} : {32{1'b0}};
   assign doq = {mem_3[addr_reg], mem_2[addr_reg], mem_1[addr_reg], mem_0[addr_reg]};

   //
   // RAM address register
   //
   always @(posedge clk)
     if (ce)
       addr_reg <= #1 addr;

   //
   // RAM write byte 0
   //
   always @(posedge clk)
     if (ce & we[0])
       mem_0[addr] <= #1 di[7:0];
   
   //
   // RAM write byte 1
   //
   always @(posedge clk)
     if (ce & we[1])
       mem_1[addr] <= #1 di[15:8];
   
   //
   // RAM write byte 2
   //
   always @(posedge clk)
     if (ce & we[2])
       mem_2[addr] <= #1 di[23:16];
   
   //
   // RAM write byte 3
   //
   always @(posedge clk)
     if (ce & we[3])
       mem_3[addr] <= #1 di[31:24];
   
endmodule // or1200_spram_32_bw

//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Generic Two-Port Synchronous RAM                            ////
////                                                              ////
////  This file is part of memory library available from          ////
////  http://www.opencores.org/cvsweb.shtml/generic_memories/     ////
////                                                              ////
////  Description                                                 ////
////  This block is a wrapper with common two-port                ////
////  synchronous memory interface for different                  ////
////  types of ASIC and FPGA RAMs. Beside universal memory        ////
////  interface it also provides behavioral model of generic      ////
////  two-port synchronous RAM.                                   ////
////  It should be used in all OPENCORES designs that want to be  ////
////  portable accross different target technologies and          ////
////  independent of target memory.                               ////
////                                                              ////
////  Supported ASIC RAMs are:                                    ////
////  - Artisan Double-Port Sync RAM                              ////
////  - Avant! Two-Port Sync RAM (*)                              ////
////  - Virage 2-port Sync RAM                                    ////
////                                                              ////
////  Supported FPGA RAMs are:                                    ////
////  - Xilinx Virtex RAMB16                                      ////
////  - Xilinx Virtex RAMB4                                       ////
////  - Altera LPM                                                ////
////                                                              ////
////  To Do:                                                      ////
////   - fix Avant!                                               ////
////   - xilinx rams need external tri-state logic                ////
////   - add additional RAMs (VS etc)                             ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_tpram_32x32.v,v $
// Revision 1.5  2005/10/19 11:37:56  jcastillo
// Added support for RAMB16 Xilinx4/Spartan3 primitives
//
// Revision 1.4  2004/06/08 18:15:48  lampret
// Changed behavior of the simulation generic models
//
// Revision 1.3  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.2.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.2  2003/04/07 01:19:07  lampret
// Added Altera LPM RAMs. Changed generic RAM output when OE inactive.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.7  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.6  2001/10/14 13:12:09  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.1  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/30 05:38:02  lampret
// Adding empty directories required by HDL coding guidelines
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_tpram_32x32(
	// Generic synchronous two-port RAM interface
	clk_a, rst_a, ce_a, we_a, oe_a, addr_a, di_a, do_a,
	clk_b, rst_b, ce_b, we_b, oe_b, addr_b, di_b, do_b
);

//
// Default address and data buses width
//
parameter aw = 5;
parameter dw = 32;

//
// Generic synchronous two-port RAM interface
//
input			clk_a;	// Clock
input			rst_a;	// Reset
input			ce_a;	// Chip enable input
input			we_a;	// Write enable input
input			oe_a;	// Output enable input
input 	[aw-1:0]	addr_a;	// address bus inputs
input	[dw-1:0]	di_a;	// input data bus
output	[dw-1:0]	do_a;	// output data bus
input			clk_b;	// Clock
input			rst_b;	// Reset
input			ce_b;	// Chip enable input
input			we_b;	// Write enable input
input			oe_b;	// Output enable input
input 	[aw-1:0]	addr_b;	// address bus inputs
input	[dw-1:0]	di_b;	// input data bus
output	[dw-1:0]	do_b;	// output data bus

//
// Internal wires and registers
//


`ifdef OR1200_ARTISAN_SDP

//
// Instantiation of ASIC memory:
//
// Artisan Synchronous Double-Port RAM (ra2sh)
//
`ifdef UNUSED
art_hsdp_32x32 #(dw, 1<<aw, aw) artisan_sdp(
`else
art_hsdp_32x32 artisan_sdp(
`endif
	.qa(do_a),
	.clka(clk_a),
	.cena(~ce_a),
	.wena(~we_a),
	.aa(addr_a),
	.da(di_a),
	.oena(~oe_a),
	.qb(do_b),
	.clkb(clk_b),
	.cenb(~ce_b),
	.wenb(~we_b),
	.ab(addr_b),
	.db(di_b),
	.oenb(~oe_b)
);

`else

`ifdef OR1200_AVANT_ATP

//
// Instantiation of ASIC memory:
//
// Avant! Asynchronous Two-Port RAM
//
avant_atp avant_atp(
	.web(~we),
	.reb(),
	.oeb(~oe),
	.rcsb(),
	.wcsb(),
	.ra(addr),
	.wa(addr),
	.di(di),
	.doq(doq)
);

`else

`ifdef OR1200_VIRAGE_STP

//
// Instantiation of ASIC memory:
//
// Virage Synchronous 2-port R/W RAM
//
virage_stp virage_stp(
	.QA(do_a),
	.QB(do_b),

	.ADRA(addr_a),
	.DA(di_a),
	.WEA(we_a),
	.OEA(oe_a),
	.MEA(ce_a),
	.CLKA(clk_a),

	.ADRB(adr_b),
	.DB(di_b),
	.WEB(we_b),
	.OEB(oe_b),
	.MEB(ce_b),
	.CLKB(clk_b)
);

`else

`ifdef OR1200_XILINX_RAMB4

//
// Instantiation of FPGA memory:
//
// Virtex/Spartan2
//

//
// Block 0
//
RAMB4_S16_S16 ramb4_s16_s16_0(
	.CLKA(clk_a),
	.RSTA(rst_a),
	.ADDRA(addr_a),
	.DIA(di_a[15:0]),
	.ENA(ce_a),
	.WEA(we_a),
	.DOA(do_a[15:0]),

	.CLKB(clk_b),
	.RSTB(rst_b),
	.ADDRB(addr_b),
	.DIB(di_b[15:0]),
	.ENB(ce_b),
	.WEB(we_b),
	.DOB(do_b[15:0])
);

//
// Block 1
//
RAMB4_S16_S16 ramb4_s16_s16_1(
	.CLKA(clk_a),
	.RSTA(rst_a),
	.ADDRA(addr_a),
	.DIA(di_a[31:16]),
	.ENA(ce_a),
	.WEA(we_a),
	.DOA(do_a[31:16]),

	.CLKB(clk_b),
	.RSTB(rst_b),
	.ADDRB(addr_b),
	.DIB(di_b[31:16]),
	.ENB(ce_b),
	.WEB(we_b),
	.DOB(do_b[31:16])
);

`else

`ifdef OR1200_XILINX_RAMB16

//
// Instantiation of FPGA memory:
//
// Virtex4/Spartan3E
//
// Added By Nir Mor
//

RAMB16_S36_S36 ramb16_s36_s36(
	.CLKA(clk_a),
	.SSRA(rst_a),
	.ADDRA({4'b0000,addr_a}),
	.DIA(di_a),
	.DIPA(4'h0),
	.ENA(ce_a),
	.WEA(we_a),
	.DOA(do_a),
	.DOPA(),

	.CLKB(clk_b),
	.SSRB(rst_b),
	.ADDRB({4'b0000,addr_b}),
	.DIB(di_b),
	.DIPB(4'h0),
	.ENB(ce_b),
	.WEB(we_b),
	.DOB(do_b),
	.DOPB()
);

`else

`ifdef OR1200_ALTERA_LPM_XXX

//
// Instantiation of FPGA memory:
//
// Altera LPM
//
// Added By Jamil Khatib
//
altqpram altqpram_component (
	.wraddress_a (addr_a),
	.inclocken_a (ce_a),
	.wraddress_b (addr_b),
	.wren_a (we_a),
	.inclocken_b (ce_b),
	.wren_b (we_b),
	.inaclr_a (rst_a),
	.inaclr_b (rst_b),
	.inclock_a (clk_a),
	.inclock_b (clk_b),
	.data_a (di_a),
	.data_b (di_b),
	.q_a (do_a),
	.q_b (do_b)
);

defparam altqpram_component.operation_mode = "BIDIR_DUAL_PORT",
	altqpram_component.width_write_a = dw,
	altqpram_component.widthad_write_a = aw,
	altqpram_component.numwords_write_a = dw,
	altqpram_component.width_read_a = dw,
	altqpram_component.widthad_read_a = aw,
	altqpram_component.numwords_read_a = dw,
	altqpram_component.width_write_b = dw,
	altqpram_component.widthad_write_b = aw,
	altqpram_component.numwords_write_b = dw,
	altqpram_component.width_read_b = dw,
	altqpram_component.widthad_read_b = aw,
	altqpram_component.numwords_read_b = dw,
	altqpram_component.indata_reg_a = "INCLOCK_A",
	altqpram_component.wrcontrol_wraddress_reg_a = "INCLOCK_A",
	altqpram_component.outdata_reg_a = "INCLOCK_A",
	altqpram_component.indata_reg_b = "INCLOCK_B",
	altqpram_component.wrcontrol_wraddress_reg_b = "INCLOCK_B",
	altqpram_component.outdata_reg_b = "INCLOCK_B",
	altqpram_component.indata_aclr_a = "INACLR_A",
	altqpram_component.wraddress_aclr_a = "INACLR_A",
	altqpram_component.wrcontrol_aclr_a = "INACLR_A",
	altqpram_component.outdata_aclr_a = "INACLR_A",
	altqpram_component.indata_aclr_b = "NONE",
	altqpram_component.wraddress_aclr_b = "NONE",
	altqpram_component.wrcontrol_aclr_b = "NONE",
	altqpram_component.outdata_aclr_b = "INACLR_B",
	altqpram_component.lpm_hint = "USE_ESB=ON";
	//examplar attribute altqpram_component NOOPT TRUE

`else

//
// Generic two-port synchronous RAM model
//

//
// Generic RAM's registers and wires
//
reg	[dw-1:0]	mem [(1<<aw)-1:0];	// RAM content
reg	[aw-1:0]	addr_a_reg;		// RAM read address register
reg	[aw-1:0]	addr_b_reg;		// RAM read address register

//
// Data output drivers
//
assign do_a = (oe_a) ? mem[addr_a_reg] : {dw{1'b0}};
assign do_b = (oe_b) ? mem[addr_b_reg] : {dw{1'b0}};

//
// RAM write
//
always @(posedge clk_a)
	if (ce_a && we_a)
		mem[addr_a] <= #1 di_a;

//
// RAM write
//
always @(posedge clk_b)
	if (ce_b && we_b)
		mem[addr_b] <= #1 di_b;

//
// RAM read address register
//
always @(posedge clk_a or posedge rst_a)
	if (rst_a)
		addr_a_reg <= #1 {aw{1'b0}};
	else if (ce_a)
		addr_a_reg <= #1 addr_a;

//
// RAM read address register
//
always @(posedge clk_b or posedge rst_b)
	if (rst_b)
		addr_b_reg <= #1 {aw{1'b0}};
	else if (ce_b)
		addr_b_reg <= #1 addr_b;

`endif	// !OR1200_ALTERA_LPM
`endif	// !OR1200_XILINX_RAMB16
`endif	// !OR1200_XILINX_RAMB4
`endif	// !OR1200_VIRAGE_STP
`endif	// !OR1200_AVANT_ATP
`endif	// !OR1200_ARTISAN_SDP

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Tick Timer                                         ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  TT according to OR1K architectural specification.           ////
////                                                              ////
////  To Do:                                                      ////
////   None                                                       ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_tt.v,v $
// Revision 1.5  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.4  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.3  2002/02/12 01:33:47  lampret
// No longer using async rst as sync reset for the counter.
//
// Revision 1.2  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.10  2001/11/13 10:00:49  lampret
// Fixed tick timer interrupt reporting by using TTCR[IP] bit.
//
// Revision 1.9  2001/11/10 03:43:57  lampret
// Fixed exceptions.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:23  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_tt(
	// RISC Internal Interface
	clk, rst, du_stall,
	spr_cs, spr_write, spr_addr, spr_dat_i, spr_dat_o,
	intr
);

//
// RISC Internal Interface
//
input		clk;		// Clock
input		rst;		// Reset
input		du_stall;	// DU stall
input		spr_cs;		// SPR CS
input		spr_write;	// SPR Write
input	[31:0]	spr_addr;	// SPR Address
input	[31:0]	spr_dat_i;	// SPR Write Data
output	[31:0]	spr_dat_o;	// SPR Read Data
output		intr;		// Interrupt output

`ifdef OR1200_TT_IMPLEMENTED

//
// TT Mode Register bits (or no register)
//
`ifdef OR1200_TT_TTMR
reg	[31:0]	ttmr;	// TTMR bits
`else
wire	[31:0]	ttmr;	// No TTMR register
`endif

//
// TT Count Register bits (or no register)
//
`ifdef OR1200_TT_TTCR
reg	[31:0]	ttcr;	// TTCR bits
`else
wire	[31:0]	ttcr;	// No TTCR register
`endif

//
// Internal wires & regs
//
wire		ttmr_sel;	// TTMR select
wire		ttcr_sel;	// TTCR select
wire		match;		// Asserted when TTMR[TP]
				// is equal to TTCR[27:0]
wire		restart;	// Restart counter when asserted
wire		stop;		// Stop counter when asserted
reg	[31:0] 	spr_dat_o;	// SPR data out

//
// TT registers address decoder
//
assign ttmr_sel = (spr_cs && (spr_addr[`OR1200_TTOFS_BITS] == `OR1200_TT_OFS_TTMR)) ? 1'b1 : 1'b0;
assign ttcr_sel = (spr_cs && (spr_addr[`OR1200_TTOFS_BITS] == `OR1200_TT_OFS_TTCR)) ? 1'b1 : 1'b0;

//
// Write to TTMR or update of TTMR[IP] bit
//
`ifdef OR1200_TT_TTMR
always @(posedge clk or posedge rst)
	if (rst)
		ttmr <= 32'b0;
	else if (ttmr_sel && spr_write)
		ttmr <= #1 spr_dat_i;
	else if (ttmr[`OR1200_TT_TTMR_IE])
		ttmr[`OR1200_TT_TTMR_IP] <= #1 ttmr[`OR1200_TT_TTMR_IP] | (match & ttmr[`OR1200_TT_TTMR_IE]);
`else
assign ttmr = {2'b11, 30'b0};	// TTMR[M] = 0x3
`endif

//
// Write to or increment of TTCR
//
`ifdef OR1200_TT_TTCR
always @(posedge clk or posedge rst)
	if (rst)
		ttcr <= 32'b0;
	else if (restart)
		ttcr <= #1 32'b0;
	else if (ttcr_sel && spr_write)
		ttcr <= #1 spr_dat_i;
	else if (!stop)
		ttcr <= #1 ttcr + 32'd1;
`else
assign ttcr = 32'b0;
`endif

//
// Read TT registers
//
always @(spr_addr or ttmr or ttcr)
	case (spr_addr[`OR1200_TTOFS_BITS])	// synopsys parallel_case
`ifdef OR1200_TT_READREGS
		`OR1200_TT_OFS_TTMR: spr_dat_o = ttmr;
`endif
		default: spr_dat_o = ttcr;
	endcase

//
// A match when TTMR[TP] is equal to TTCR[27:0]
//
assign match = (ttmr[`OR1200_TT_TTMR_TP] == ttcr[27:0]) ? 1'b1 : 1'b0;

//
// Restart when match and TTMR[M]==0x1
//
assign restart = match && (ttmr[`OR1200_TT_TTMR_M] == 2'b01);

//
// Stop when match and TTMR[M]==0x2 or when TTMR[M]==0x0 or when RISC is stalled by debug unit
//
assign stop = match & (ttmr[`OR1200_TT_TTMR_M] == 2'b10) | (ttmr[`OR1200_TT_TTMR_M] == 2'b00) | du_stall;

//
// Generate an interrupt request
//
assign intr = ttmr[`OR1200_TT_TTMR_IP];

`else

//
// When TT is not implemented, drive all outputs as would when TT is disabled
//
assign intr = 1'b0;

//
// Read TT registers
//
`ifdef OR1200_TT_READREGS
assign spr_dat_o = 32'b0;
`endif

`endif

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's WISHBONE BIU                                       ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Implements WISHBONE interface                               ////
////                                                              ////
////  To Do:                                                      ////
////   - if biu_cyc/stb are deasserted and wb_ack_i is asserted   ////
////   and this happens even before aborted_r is asssrted,        ////
////   wb_ack_i will be delivered even though transfer is         ////
////   internally considered already aborted. However most        ////
////   wb_ack_i are externally registered and delayed. Normally   ////
////   this shouldn't cause any problems.                         ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_wb_biu.v,v $
// Revision 1.7  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.6.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.6  2003/04/07 20:57:46  lampret
// Fixed OR1200_CLKDIV_x_SUPPORTED defines. Fixed order of ifdefs.
//
// Revision 1.5  2002/12/08 08:57:56  lampret
// Added optional support for WB B3 specification (xwb_cti_o, xwb_bte_o). Made xwb_cab_o optional.
//
// Revision 1.4  2002/09/16 03:09:16  lampret
// Fixed a combinational loop.
//
// Revision 1.3  2002/08/12 05:31:37  lampret
// Added optional retry counter for wb_rty_i. Added graceful termination for aborted transfers.
//
// Revision 1.2  2002/07/14 22:17:17  lampret
// Added simple trace buffer [only for Xilinx Virtex target]. Fixed instruction fetch abort when new exception is recognized.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.12  2001/11/22 13:42:51  lampret
// Added wb_cyc_o assignment after it was removed by accident.
//
// Revision 1.11  2001/11/20 21:28:10  lampret
// Added optional sampling of inputs.
//
// Revision 1.10  2001/11/18 11:32:00  lampret
// OR1200_REGISTERED_OUTPUTS can now be enabled.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.3  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/22 03:31:54  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:23  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_wb_biu(
	// RISC clock, reset and clock control
	clk, rst, clmode,

	// WISHBONE interface
	wb_clk_i, wb_rst_i, wb_ack_i, wb_err_i, wb_rty_i, wb_dat_i,
	wb_cyc_o, wb_adr_o, wb_stb_o, wb_we_o, wb_sel_o, wb_dat_o,
`ifdef OR1200_WB_CAB
	wb_cab_o,
`endif
`ifdef OR1200_WB_B3
	wb_cti_o, wb_bte_o,
`endif

	// Internal RISC bus
	biu_dat_i, biu_adr_i, biu_cyc_i, biu_stb_i, biu_we_i, biu_sel_i, biu_cab_i,
	biu_dat_o, biu_ack_o, biu_err_o
);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;

//
// RISC clock, reset and clock control
//
input			clk;		// RISC clock
input			rst;		// RISC reset
input	[1:0]		clmode;		// 00 WB=RISC, 01 WB=RISC/2, 10 N/A, 11 WB=RISC/4

//
// WISHBONE interface
//
input			wb_clk_i;	// clock input
input			wb_rst_i;	// reset input
input			wb_ack_i;	// normal termination
input			wb_err_i;	// termination w/ error
input			wb_rty_i;	// termination w/ retry
input	[dw-1:0]	wb_dat_i;	// input data bus
output			wb_cyc_o;	// cycle valid output
output	[aw-1:0]	wb_adr_o;	// address bus outputs
output			wb_stb_o;	// strobe output
output			wb_we_o;	// indicates write transfer
output	[3:0]		wb_sel_o;	// byte select outputs
output	[dw-1:0]	wb_dat_o;	// output data bus
`ifdef OR1200_WB_CAB
output			wb_cab_o;	// consecutive address burst
`endif
`ifdef OR1200_WB_B3
output	[2:0]		wb_cti_o;	// cycle type identifier
output	[1:0]		wb_bte_o;	// burst type extension
`endif

//
// Internal RISC interface
//
input	[dw-1:0]	biu_dat_i;	// input data bus
input	[aw-1:0]	biu_adr_i;	// address bus
input			biu_cyc_i;	// WB cycle
input			biu_stb_i;	// WB strobe
input			biu_we_i;	// WB write enable
input			biu_cab_i;	// CAB input
input	[3:0]		biu_sel_i;	// byte selects
output	[31:0]		biu_dat_o;	// output data bus
output			biu_ack_o;	// ack output
output			biu_err_o;	// err output

//
// Registers
//
reg	[1:0]		valid_div;	// Used for synchronization
`ifdef OR1200_REGISTERED_OUTPUTS
reg	[aw-1:0]	wb_adr_o;	// address bus outputs
reg			wb_cyc_o;	// cycle output
reg			wb_stb_o;	// strobe output
reg			wb_we_o;	// indicates write transfer
reg	[3:0]		wb_sel_o;	// byte select outputs
`ifdef OR1200_WB_CAB
reg			wb_cab_o;	// CAB output
`endif
`ifdef OR1200_WB_B3
reg	[1:0]		burst_len;	// burst counter
reg	[2:0]		wb_cti_o;	// cycle type identifier
`endif
reg	[dw-1:0]	wb_dat_o;	// output data bus
`endif
`ifdef OR1200_REGISTERED_INPUTS
reg			long_ack_o;	// normal termination
reg			long_err_o;	// error termination
reg	[dw-1:0]	biu_dat_o;	// output data bus
`else
wire			long_ack_o;	// normal termination
wire			long_err_o;	// error termination
`endif
wire			aborted;	// Graceful abort
reg			aborted_r;	// Graceful abort
wire			retry;		// Retry
`ifdef OR1200_WB_RETRY
reg	[`OR1200_WB_RETRY-1:0] retry_cntr;	// Retry counter
`endif

//
// WISHBONE I/F <-> Internal RISC I/F conversion
//

//
// Address bus
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_adr_o <= #1 {aw{1'b0}};
	else if ((biu_cyc_i & biu_stb_i) & ~wb_ack_i & ~aborted & ~(wb_stb_o & ~wb_ack_i))
		wb_adr_o <= #1 biu_adr_i;
`else
assign wb_adr_o = biu_adr_i;
`endif

//
// Input data bus
//
`ifdef OR1200_REGISTERED_INPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		biu_dat_o <= #1 32'h0000_0000;
	else if (wb_ack_i)
		biu_dat_o <= #1 wb_dat_i;
`else
assign biu_dat_o = wb_dat_i;
`endif

//
// Output data bus
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_dat_o <= #1 {dw{1'b0}};
	else if ((biu_cyc_i & biu_stb_i) & ~wb_ack_i & ~aborted)
		wb_dat_o <= #1 biu_dat_i;
`else
assign wb_dat_o = biu_dat_i;
`endif

//
// Valid_div counts RISC clock cycles by modulo 4
// and is used to synchronize external WB i/f to
// RISC clock
//
always @(posedge clk or posedge rst)
	if (rst)
		valid_div <= #1 2'b0;
	else
		valid_div <= #1 valid_div + 1'd1;

//
// biu_ack_o is one RISC clock cycle long long_ack_o.
// long_ack_o is one, two or four RISC clock cycles long because
// WISHBONE can work at 1, 1/2 or 1/4 RISC clock.
//
assign biu_ack_o = long_ack_o
`ifdef OR1200_CLKDIV_2_SUPPORTED
		& (valid_div[0] | ~clmode[0])
`ifdef OR1200_CLKDIV_4_SUPPORTED
		& (valid_div[1] | ~clmode[1])
`endif
`endif
		;

//
// Acknowledgment of the data to the RISC
//
// long_ack_o
//
`ifdef OR1200_REGISTERED_INPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		long_ack_o <= #1 1'b0;
	else
		long_ack_o <= #1 wb_ack_i & ~aborted;
`else
assign long_ack_o = wb_ack_i & ~aborted_r;
`endif

//
// biu_err_o is one RISC clock cycle long long_err_o.
// long_err_o is one, two or four RISC clock cycles long because
// WISHBONE can work at 1, 1/2 or 1/4 RISC clock.
//
assign biu_err_o = long_err_o
`ifdef OR1200_CLKDIV_2_SUPPORTED
		& (valid_div[0] | ~clmode[0])
`ifdef OR1200_CLKDIV_4_SUPPORTED
		& (valid_div[1] | ~clmode[1])
`endif
`endif
		;

//
// Error termination
//
// long_err_o
//
`ifdef OR1200_REGISTERED_INPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		long_err_o <= #1 1'b0;
	else
		long_err_o <= #1 wb_err_i & ~aborted;
`else
assign long_err_o = wb_err_i & ~aborted_r;
`endif

//
// Retry counter
//
// Assert 'retry' when 'wb_rty_i' is sampled high and keep it high
// until retry counter doesn't expire
// 
`ifdef OR1200_WB_RETRY
assign retry = wb_rty_i | (|retry_cntr);
`else
assign retry = 1'b0;
`endif
`ifdef OR1200_WB_RETRY
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		retry_cntr <= #1 1'b0;
	else if (wb_rty_i)
		retry_cntr <= #1 {`OR1200_WB_RETRY{1'b1}};
	else if (retry_cntr)
		retry_cntr <= #1 retry_cntr - 7'd1;
`endif

//
// Graceful completion of aborted transfers
//
// Assert 'aborted' when 1) current transfer is in progress (wb_stb_o; which
// we know is only asserted together with wb_cyc_o) 2) and in next WB clock cycle
// wb_stb_o would be deasserted (biu_cyc_i and biu_stb_i are low) 3) and
// there is no termination of current transfer in this WB clock cycle (wb_ack_i
// and wb_err_i are low).
// 'aborted_r' is registered 'aborted' and extended until this "aborted" transfer
// is properly terminated with wb_ack_i/wb_err_i.
// 
assign aborted = wb_stb_o & ~(biu_cyc_i & biu_stb_i) & ~(wb_ack_i | wb_err_i);
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		aborted_r <= #1 1'b0;
	else if (wb_ack_i | wb_err_i)
		aborted_r <= #1 1'b0;
	else if (aborted)
		aborted_r <= #1 1'b1;

//
// WB cyc_o
//
// Either 1) normal transfer initiated by biu_cyc_i (and biu_cab_i if
// bursts are enabled) and possibly suspended by 'retry'
// or 2) extended "aborted" transfer
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_cyc_o <= #1 1'b0;
	else
`ifdef OR1200_NO_BURSTS
		wb_cyc_o <= #1 biu_cyc_i & ~wb_ack_i & ~retry | aborted & ~wb_ack_i;
`else
		wb_cyc_o <= #1 biu_cyc_i & ~wb_ack_i & ~retry | biu_cab_i | aborted & ~wb_ack_i;
`endif
`else
`ifdef OR1200_NO_BURSTS
assign wb_cyc_o = biu_cyc_i & ~retry;
`else
assign wb_cyc_o = biu_cyc_i | biu_cab_i & ~retry;
`endif
`endif

//
// WB stb_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_stb_o <= #1 1'b0;
	else
		wb_stb_o <= #1 (biu_cyc_i & biu_stb_i) & ~wb_ack_i & ~retry | aborted & ~wb_ack_i;
`else
assign wb_stb_o = biu_cyc_i & biu_stb_i;
`endif

//
// WB we_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_we_o <= #1 1'b0;
	else
		wb_we_o <= #1 biu_cyc_i & biu_stb_i & biu_we_i | aborted & wb_we_o;
`else
assign wb_we_o = biu_cyc_i & biu_stb_i & biu_we_i;
`endif

//
// WB sel_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_sel_o <= #1 4'b0000;
	else
		wb_sel_o <= #1 biu_sel_i;
`else
assign wb_sel_o = biu_sel_i;
`endif

`ifdef OR1200_WB_CAB
//
// WB cab_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_cab_o <= #1 1'b0;
	else
		wb_cab_o <= #1 biu_cab_i;
`else
assign wb_cab_o = biu_cab_i;
`endif
`endif

`ifdef OR1200_WB_B3
//
// Count burst beats
//
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		burst_len <= #1 2'b00;
	else if (biu_cab_i && burst_len && wb_ack_i)
		burst_len <= #1 burst_len - 1'b1;
	else if (~biu_cab_i)
		burst_len <= #1 2'b11;

//
// WB cti_o
//
`ifdef OR1200_REGISTERED_OUTPUTS
always @(posedge wb_clk_i or posedge wb_rst_i)
	if (wb_rst_i)
		wb_cti_o <= #1 3'b000;	// classic cycle
`ifdef OR1200_NO_BURSTS
	else
		wb_cti_o <= #1 3'b111;	// end-of-burst
`else
	else if (biu_cab_i && burst_len[1])
		wb_cti_o <= #1 3'b010;	// incrementing burst cycle
	else if (biu_cab_i && wb_ack_i)
		wb_cti_o <= #1 3'b111;	// end-of-burst
`endif	// OR1200_NO_BURSTS
`else
Unsupported !!!;
`endif

//
// WB bte_o
//
assign wb_bte_o = 2'b01;	// 4-beat wrap burst

`endif	// OR1200_WB_B3

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's Write-back Mux                                     ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  CPU's write-back stage of the pipeline                      ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_wbmux.v,v $
// Revision 1.3  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.2  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.8  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.7  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:23  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_wbmux(
	// Clock and reset
	clk, rst,

	// Internal i/f
	wb_freeze, rfwb_op,
	muxin_a, muxin_b, muxin_c, muxin_d,
	muxout, muxreg, muxreg_valid
);

parameter width = `OR1200_OPERAND_WIDTH;

//
// I/O
//

//
// Clock and reset
//
input				clk;
input				rst;

//
// Internal i/f
//
input				wb_freeze;
input	[`OR1200_RFWBOP_WIDTH-1:0]	rfwb_op;
input	[width-1:0]		muxin_a;
input	[width-1:0]		muxin_b;
input	[width-1:0]		muxin_c;
input	[width-1:0]		muxin_d;
output	[width-1:0]		muxout;
output	[width-1:0]		muxreg;
output				muxreg_valid;

//
// Internal wires and regs
//
reg	[width-1:0]		muxout;
reg	[width-1:0]		muxreg;
reg				muxreg_valid;

//
// Registered output from the write-back multiplexer
//
always @(posedge clk or posedge rst) begin
	if (rst) begin
		muxreg <= #1 32'd0;
		muxreg_valid <= #1 1'b0;
	end
	else if (!wb_freeze) begin
		muxreg <= #1 muxout;
		muxreg_valid <= #1 rfwb_op[0];
	end
end

//
// Write-back multiplexer
//
always @(muxin_a or muxin_b or muxin_c or muxin_d or rfwb_op) begin
`ifdef OR1200_ADDITIONAL_SYNOPSYS_DIRECTIVES
	case(rfwb_op[`OR1200_RFWBOP_WIDTH-1:1]) // synopsys parallel_case infer_mux
`else
	case(rfwb_op[`OR1200_RFWBOP_WIDTH-1:1]) // synopsys parallel_case
`endif
		2'b00: muxout = muxin_a;
		2'b01: begin
			muxout = muxin_b;
`ifdef OR1200_VERBOSE
// synopsys translate_off
			$display("  WBMUX: muxin_b %h", muxin_b);
// synopsys translate_on
`endif
		end
		2'b10: begin
			muxout = muxin_c;
`ifdef OR1200_VERBOSE
// synopsys translate_off
			$display("  WBMUX: muxin_c %h", muxin_c);
// synopsys translate_on
`endif
		end
		2'b11: begin
			muxout = muxin_d + 32'h8;
`ifdef OR1200_VERBOSE
// synopsys translate_off
			$display("  WBMUX: muxin_d %h", muxin_d + 4'h8);
// synopsys translate_on
`endif
		end
	endcase
end

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200's interface to SPRs                                  ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  Decoding of SPR addresses and access to SPRs                ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_sprs.v,v $
// Revision 1.11  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.9.4.1  2003/12/17 13:43:38  simons
// Exception prefix configuration changed.
//
// Revision 1.9  2002/09/07 05:42:02  lampret
// Added optional SR[CY]. Added define to enable additional (compare) flag modifiers. Defines are OR1200_IMPL_ADDC and OR1200_ADDITIONAL_FLAG_MODIFIERS.
//
// Revision 1.8  2002/08/28 01:44:25  lampret
// Removed some commented RTL. Fixed SR/ESR flag bug.
//
// Revision 1.7  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.6  2002/03/11 01:26:57  lampret
// Changed generation of SPR address. Now it is ORed from base and offset instead of a sum.
//
// Revision 1.5  2002/02/01 19:56:54  lampret
// Fixed combinational loops.
//
// Revision 1.4  2002/01/23 07:52:36  lampret
// Changed default reset values for SR and ESR to match or1ksim's. Fixed flop model in or1200_dpram_32x32 when OR1200_XILINX_RAM32X1D is defined.
//
// Revision 1.3  2002/01/19 09:27:49  lampret
// SR[TEE] should be zero after reset.
//
// Revision 1.2  2002/01/18 07:56:00  lampret
// No more low/high priority interrupts (PICPR removed). Added tick timer exception. Added exception prefix (SR[EPH]). Fixed single-step bug whenreading NPC.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.12  2001/11/23 21:42:31  simons
// Program counter divided to PPC and NPC.
//
// Revision 1.11  2001/11/23 08:38:51  lampret
// Changed DSR/DRR behavior and exception detection.
//
// Revision 1.10  2001/11/12 01:45:41  lampret
// Moved flag bit into SR. Changed RF enable from constant enable to dynamic enable for read ports.
//
// Revision 1.9  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.8  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:36  igorm
// no message
//
// Revision 1.3  2001/08/13 03:36:20  lampret
// Added cfg regs. Moved all defines into one defines.v file. More cleanup.
//
// Revision 1.2  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.1  2001/07/20 00:46:21  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_sprs(
		// Clk & Rst
		clk, rst,

		// Internal CPU interface
		flagforw, flag_we, flag, cyforw, cy_we, carry,
		addrbase, addrofs, dat_i, alu_op, branch_op,
		epcr, eear, esr, except_started,
		to_wbmux, epcr_we, eear_we, esr_we, pc_we, sr_we, to_sr, sr,
		spr_dat_cfgr, spr_dat_rf, spr_dat_npc, spr_dat_ppc, spr_dat_mac,
        boot_adr_sel_i,

		// From/to other RISC units
		spr_dat_pic, spr_dat_tt, spr_dat_pm,
		spr_dat_dmmu, spr_dat_immu, spr_dat_du,
		spr_addr, spr_dat_o, spr_cs, spr_we,

		du_addr, du_dat_du, du_read,
		du_write, du_dat_cpu

);

parameter width = `OR1200_OPERAND_WIDTH;

//
// I/O Ports
//

//
// Internal CPU interface
//
input				clk; 		// Clock
input 				rst;		// Reset
input 				flagforw;	// From ALU
input 				flag_we;	// From ALU
output 				flag;		// SR[F]
input 				cyforw;		// From ALU
input 				cy_we;		// From ALU
output 				carry;		// SR[CY]
input	[width-1:0] 		addrbase;	// SPR base address
input	[15:0] 			addrofs;	// SPR offset
input	[width-1:0]		dat_i;		// SPR write data
input	[`OR1200_ALUOP_WIDTH-1:0]	alu_op;		// ALU operation
input	[`OR1200_BRANCHOP_WIDTH-1:0]	branch_op;	// Branch operation
input	[width-1:0] 		epcr;		// EPCR0
input	[width-1:0] 		eear;		// EEAR0
input	[`OR1200_SR_WIDTH-1:0] 	esr;		// ESR0
input 				except_started; // Exception was started
output	[width-1:0]		to_wbmux;	// For l.mfspr
output				epcr_we;	// EPCR0 write enable
output				eear_we;	// EEAR0 write enable
output				esr_we;		// ESR0 write enable
output				pc_we;		// PC write enable
output 				sr_we;		// Write enable SR
output	[`OR1200_SR_WIDTH-1:0]	to_sr;		// Data to SR
output	[`OR1200_SR_WIDTH-1:0]	sr;		// SR
input	[31:0]			spr_dat_cfgr;	// Data from CFGR
input	[31:0]			spr_dat_rf;	// Data from RF
input	[31:0]			spr_dat_npc;	// Data from NPC
input	[31:0]			spr_dat_ppc;	// Data from PPC   
input	[31:0]			spr_dat_mac;	// Data from MAC
input					boot_adr_sel_i;

//
// To/from other RISC units
//
input	[31:0]			spr_dat_pic;	// Data from PIC
input	[31:0]			spr_dat_tt;	// Data from TT
input	[31:0]			spr_dat_pm;	// Data from PM
input	[31:0]			spr_dat_dmmu;	// Data from DMMU
input	[31:0]			spr_dat_immu;	// Data from IMMU
input	[31:0]			spr_dat_du;	// Data from DU
output	[31:0]			spr_addr;	// SPR Address
output	[31:0]			spr_dat_o;	// Data to unit
output	[31:0]			spr_cs;		// Unit select
output				spr_we;		// SPR write enable

//
// To/from Debug Unit
//
input	[width-1:0]		du_addr;	// Address
input	[width-1:0]		du_dat_du;	// Data from DU to SPRS
input				du_read;	// Read qualifier
input				du_write;	// Write qualifier
output	[width-1:0]		du_dat_cpu;	// Data from SPRS to DU

//
// Internal regs & wires
//
reg	[`OR1200_SR_WIDTH-1:0]	sr_reg;					// SR
reg							sr_reg_bit_eph;			// SR_EPH bit
reg							sr_reg_bit_eph_select;	// SR_EPH select
wire						sr_reg_bit_eph_muxed;	// SR_EPH muxed bit
reg	[`OR1200_SR_WIDTH-1:0]	sr;						// SR
reg					write_spr;	// Write SPR
reg					read_spr;	// Read SPR
reg	[width-1:0]		to_wbmux;	// For l.mfspr
wire				cfgr_sel;	// Select for cfg regs
wire				rf_sel;		// Select for RF
wire				npc_sel;	// Select for NPC
wire				ppc_sel;	// Select for PPC
wire 				sr_sel;		// Select for SR	
wire 				epcr_sel;	// Select for EPCR0
wire 				eear_sel;	// Select for EEAR0
wire 				esr_sel;	// Select for ESR0
wire	[31:0]			sys_data;	// Read data from system SPRs
wire				du_access;	// Debug unit access
wire	[`OR1200_ALUOP_WIDTH-1:0]	sprs_op;	// ALU operation
reg	[31:0]			unqualified_cs;	// Unqualified chip selects

//
// Decide if it is debug unit access
//
assign du_access = du_read | du_write;

//
// Generate sprs opcode
//
assign sprs_op = du_write ? `OR1200_ALUOP_MTSR : du_read ? `OR1200_ALUOP_MFSR : alu_op;

//
// Generate SPR address from base address and offset
// OR from debug unit address
//
assign spr_addr = du_access ? du_addr : addrbase | {16'h0000, addrofs};

//
// SPR is written by debug unit or by l.mtspr
//
assign spr_dat_o = du_write ? du_dat_du : dat_i;

//
// debug unit data input:
//  - write into debug unit SPRs by debug unit itself
//  - read of SPRS by debug unit
//  - write into debug unit SPRs by l.mtspr
//
assign du_dat_cpu = du_write ? du_dat_du : du_read ? to_wbmux : dat_i;

//
// Write into SPRs when l.mtspr
//
assign spr_we = du_write | write_spr;

//
// Qualify chip selects
//
assign spr_cs = unqualified_cs & {32{read_spr | write_spr}};

//
// Decoding of groups
//
always @(spr_addr)
	case (spr_addr[`OR1200_SPR_GROUP_BITS])	// synopsys parallel_case
		`OR1200_SPR_GROUP_WIDTH'd00: unqualified_cs = 32'b00000000_00000000_00000000_00000001;
		`OR1200_SPR_GROUP_WIDTH'd01: unqualified_cs = 32'b00000000_00000000_00000000_00000010;
		`OR1200_SPR_GROUP_WIDTH'd02: unqualified_cs = 32'b00000000_00000000_00000000_00000100;
		`OR1200_SPR_GROUP_WIDTH'd03: unqualified_cs = 32'b00000000_00000000_00000000_00001000;
		`OR1200_SPR_GROUP_WIDTH'd04: unqualified_cs = 32'b00000000_00000000_00000000_00010000;
		`OR1200_SPR_GROUP_WIDTH'd05: unqualified_cs = 32'b00000000_00000000_00000000_00100000;
		`OR1200_SPR_GROUP_WIDTH'd06: unqualified_cs = 32'b00000000_00000000_00000000_01000000;
		`OR1200_SPR_GROUP_WIDTH'd07: unqualified_cs = 32'b00000000_00000000_00000000_10000000;
		`OR1200_SPR_GROUP_WIDTH'd08: unqualified_cs = 32'b00000000_00000000_00000001_00000000;
		`OR1200_SPR_GROUP_WIDTH'd09: unqualified_cs = 32'b00000000_00000000_00000010_00000000;
		`OR1200_SPR_GROUP_WIDTH'd10: unqualified_cs = 32'b00000000_00000000_00000100_00000000;
		`OR1200_SPR_GROUP_WIDTH'd11: unqualified_cs = 32'b00000000_00000000_00001000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd12: unqualified_cs = 32'b00000000_00000000_00010000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd13: unqualified_cs = 32'b00000000_00000000_00100000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd14: unqualified_cs = 32'b00000000_00000000_01000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd15: unqualified_cs = 32'b00000000_00000000_10000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd16: unqualified_cs = 32'b00000000_00000001_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd17: unqualified_cs = 32'b00000000_00000010_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd18: unqualified_cs = 32'b00000000_00000100_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd19: unqualified_cs = 32'b00000000_00001000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd20: unqualified_cs = 32'b00000000_00010000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd21: unqualified_cs = 32'b00000000_00100000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd22: unqualified_cs = 32'b00000000_01000000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd23: unqualified_cs = 32'b00000000_10000000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd24: unqualified_cs = 32'b00000001_00000000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd25: unqualified_cs = 32'b00000010_00000000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd26: unqualified_cs = 32'b00000100_00000000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd27: unqualified_cs = 32'b00001000_00000000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd28: unqualified_cs = 32'b00010000_00000000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd29: unqualified_cs = 32'b00100000_00000000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd30: unqualified_cs = 32'b01000000_00000000_00000000_00000000;
		`OR1200_SPR_GROUP_WIDTH'd31: unqualified_cs = 32'b10000000_00000000_00000000_00000000;
	endcase

//
// SPRs System Group
//

//
// What to write into SR
//
assign to_sr[`OR1200_SR_FO:`OR1200_SR_OV] =
		(except_started) ? sr[`OR1200_SR_FO:`OR1200_SR_OV] :
		(branch_op == `OR1200_BRANCHOP_RFE) ? esr[`OR1200_SR_FO:`OR1200_SR_OV] :
		(write_spr && sr_sel) ? {1'b1, spr_dat_o[`OR1200_SR_FO-1:`OR1200_SR_OV]}:
		sr[`OR1200_SR_FO:`OR1200_SR_OV];
assign to_sr[`OR1200_SR_CY] =
		(except_started) ? sr[`OR1200_SR_CY] :
		(branch_op == `OR1200_BRANCHOP_RFE) ? esr[`OR1200_SR_CY] :
		cy_we ? cyforw :
		(write_spr && sr_sel) ? spr_dat_o[`OR1200_SR_CY] :
		sr[`OR1200_SR_CY];
assign to_sr[`OR1200_SR_F] =
		(except_started) ? sr[`OR1200_SR_F] :
		(branch_op == `OR1200_BRANCHOP_RFE) ? esr[`OR1200_SR_F] :
		flag_we ? flagforw :
		(write_spr && sr_sel) ? spr_dat_o[`OR1200_SR_F] :
		sr[`OR1200_SR_F];
assign to_sr[`OR1200_SR_CE:`OR1200_SR_SM] =
		(except_started) ? {sr[`OR1200_SR_CE:`OR1200_SR_LEE], 2'b00, sr[`OR1200_SR_ICE:`OR1200_SR_DCE], 3'b001} :
		(branch_op == `OR1200_BRANCHOP_RFE) ? esr[`OR1200_SR_CE:`OR1200_SR_SM] :
		(write_spr && sr_sel) ? spr_dat_o[`OR1200_SR_CE:`OR1200_SR_SM]:
		sr[`OR1200_SR_CE:`OR1200_SR_SM];

//
// Selects for system SPRs
//
assign cfgr_sel = (spr_cs[`OR1200_SPR_GROUP_SYS] && (spr_addr[10:4] == `OR1200_SPR_CFGR));
assign rf_sel = (spr_cs[`OR1200_SPR_GROUP_SYS] && (spr_addr[10:5] == `OR1200_SPR_RF));
assign npc_sel = (spr_cs[`OR1200_SPR_GROUP_SYS] && (spr_addr[10:0] == `OR1200_SPR_NPC));
assign ppc_sel = (spr_cs[`OR1200_SPR_GROUP_SYS] && (spr_addr[10:0] == `OR1200_SPR_PPC));
assign sr_sel = (spr_cs[`OR1200_SPR_GROUP_SYS] && (spr_addr[10:0] == `OR1200_SPR_SR));
assign epcr_sel = (spr_cs[`OR1200_SPR_GROUP_SYS] && (spr_addr[10:0] == `OR1200_SPR_EPCR));
assign eear_sel = (spr_cs[`OR1200_SPR_GROUP_SYS] && (spr_addr[10:0] == `OR1200_SPR_EEAR));
assign esr_sel = (spr_cs[`OR1200_SPR_GROUP_SYS] && (spr_addr[10:0] == `OR1200_SPR_ESR));

//
// Write enables for system SPRs
//
assign sr_we = (write_spr && sr_sel) | (branch_op == `OR1200_BRANCHOP_RFE) | flag_we | cy_we;
assign pc_we = (write_spr && (npc_sel | ppc_sel));
assign epcr_we = (write_spr && epcr_sel);
assign eear_we = (write_spr && eear_sel);
assign esr_we = (write_spr && esr_sel);

//
// Output from system SPRs
//
assign sys_data = (spr_dat_cfgr & {32{read_spr & cfgr_sel}}) |
		  (spr_dat_rf & {32{read_spr & rf_sel}}) |
		  (spr_dat_npc & {32{read_spr & npc_sel}}) |
		  (spr_dat_ppc & {32{read_spr & ppc_sel}}) |
		  ({{32-`OR1200_SR_WIDTH{1'b0}},sr} & {32{read_spr & sr_sel}}) |
		  (epcr & {32{read_spr & epcr_sel}}) |
		  (eear & {32{read_spr & eear_sel}}) |
		  ({{32-`OR1200_SR_WIDTH{1'b0}},esr} & {32{read_spr & esr_sel}});

//
// Flag alias
//
assign flag = sr[`OR1200_SR_F];

//
// Carry alias
//
assign carry = sr[`OR1200_SR_CY];

//
// Supervision register
//
always @(posedge clk or posedge rst)
	if (rst)
		sr_reg <= #1 {1'b1, `OR1200_SR_EPH_DEF, {`OR1200_SR_WIDTH-3{1'b0}}, 1'b1};
	else if (except_started)
		sr_reg <= #1 to_sr[`OR1200_SR_WIDTH-1:0];
	else if (sr_we)
		sr_reg <= #1 to_sr[`OR1200_SR_WIDTH-1:0];

always @(posedge clk or posedge rst)
	if (rst) begin
		sr_reg_bit_eph <= #1 `OR1200_SR_EPH_DEF;
		sr_reg_bit_eph_select <= #1 1'b1;
	end
	else if (sr_reg_bit_eph_select) begin
		sr_reg_bit_eph <= #1 boot_adr_sel_i; 
		sr_reg_bit_eph_select <= #1 1'b0;
	end
	else if (sr_we) begin
		sr_reg_bit_eph <= #1 to_sr[`OR1200_SR_EPH];
	end

assign	sr_reg_bit_eph_muxed = (sr_reg_bit_eph_select) ? boot_adr_sel_i : sr_reg_bit_eph;

always @(sr_reg or sr_reg_bit_eph_muxed)
	sr = {sr_reg[`OR1200_SR_WIDTH-1], sr_reg_bit_eph_muxed, sr_reg[`OR1200_SR_WIDTH-3:0]};

//
// MTSPR/MFSPR interface
//
always @(sprs_op or spr_addr or sys_data or spr_dat_mac or spr_dat_pic or spr_dat_pm or
	spr_dat_dmmu or spr_dat_immu or spr_dat_du or spr_dat_tt) begin
	case (sprs_op)	// synopsys parallel_case
		`OR1200_ALUOP_MTSR : begin
			write_spr = 1'b1;
			read_spr = 1'b0;
			to_wbmux = 32'b0;
		end
		`OR1200_ALUOP_MFSR : begin
			casex (spr_addr[`OR1200_SPR_GROUP_BITS]) // synopsys parallel_case
				`OR1200_SPR_GROUP_TT:
					to_wbmux = spr_dat_tt;
				`OR1200_SPR_GROUP_PIC:
					to_wbmux = spr_dat_pic;
				`OR1200_SPR_GROUP_PM:
					to_wbmux = spr_dat_pm;
				`OR1200_SPR_GROUP_DMMU:
					to_wbmux = spr_dat_dmmu;
				`OR1200_SPR_GROUP_IMMU:
					to_wbmux = spr_dat_immu;
				`OR1200_SPR_GROUP_MAC:
					to_wbmux = spr_dat_mac;
				`OR1200_SPR_GROUP_DU:
					to_wbmux = spr_dat_du;
				`OR1200_SPR_GROUP_SYS:
					to_wbmux = sys_data;
				default:
					to_wbmux = 32'b0;
			endcase
			write_spr = 1'b0;
			read_spr = 1'b1;
		end
		default : begin
			write_spr = 1'b0;
			read_spr = 1'b0;
			to_wbmux = 32'b0;
		end
	endcase
end

endmodule
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  OR1200 Top Level                                            ////
////                                                              ////
////  This file is part of the OpenRISC 1200 project              ////
////  http://www.opencores.org/cores/or1k/                        ////
////                                                              ////
////  Description                                                 ////
////  OR1200 Top Level                                            ////
////                                                              ////
////  To Do:                                                      ////
////   - make it smaller and faster                               ////
////                                                              ////
////  Author(s):                                                  ////
////      - Damjan Lampret, lampret@opencores.org                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2000 Authors and OPENCORES.ORG                 ////
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
// $Log: or1200_top.v,v $
// Revision 1.13  2004/06/08 18:17:36  lampret
// Non-functional changes. Coding style fixes.
//
// Revision 1.12  2004/04/05 08:29:57  lampret
// Merged branch_qmem into main tree.
//
// Revision 1.10.4.9  2004/02/11 01:40:11  lampret
// preliminary HW breakpoints support in debug unit (by default disabled). To enable define OR1200_DU_HWBKPTS.
//
// Revision 1.10.4.8  2004/01/17 21:14:14  simons
// Errors fixed.
//
// Revision 1.10.4.7  2004/01/17 19:06:38  simons
// Error fixed.
//
// Revision 1.10.4.6  2004/01/17 18:39:48  simons
// Error fixed.
//
// Revision 1.10.4.5  2004/01/15 06:46:38  markom
// interface to debug changed; no more opselect; stb-ack protocol
//
// Revision 1.10.4.4  2003/12/09 11:46:49  simons
// Mbist nameing changed, Artisan ram instance signal names fixed, some synthesis waning fixed.
//
// Revision 1.10.4.3  2003/12/05 00:08:44  lampret
// Fixed instantiation name.
//
// Revision 1.10.4.2  2003/07/11 01:10:35  lampret
// Added three missing wire declarations. No functional changes.
//
// Revision 1.10.4.1  2003/07/08 15:36:37  lampret
// Added embedded memory QMEM.
//
// Revision 1.10  2002/12/08 08:57:56  lampret
// Added optional support for WB B3 specification (xwb_cti_o, xwb_bte_o). Made xwb_cab_o optional.
//
// Revision 1.9  2002/10/17 20:04:41  lampret
// Added BIST scan. Special VS RAMs need to be used to implement BIST.
//
// Revision 1.8  2002/08/18 19:54:22  lampret
// Added store buffer.
//
// Revision 1.7  2002/07/14 22:17:17  lampret
// Added simple trace buffer [only for Xilinx Virtex target]. Fixed instruction fetch abort when new exception is recognized.
//
// Revision 1.6  2002/03/29 15:16:56  lampret
// Some of the warnings fixed.
//
// Revision 1.5  2002/02/11 04:33:17  lampret
// Speed optimizations (removed duplicate _cyc_ and _stb_). Fixed D/IMMU cache-inhibit attr.
//
// Revision 1.4  2002/02/01 19:56:55  lampret
// Fixed combinational loops.
//
// Revision 1.3  2002/01/28 01:16:00  lampret
// Changed 'void' nop-ops instead of insn[0] to use insn[16]. Debug unit stalls the tick timer. Prepared new flag generation for add and and insns. Blocked DC/IC while they are turned off. Fixed I/D MMU SPRs layout except WAYs. TODO: smart IC invalidate, l.j 2 and TLB ways.
//
// Revision 1.2  2002/01/18 07:56:00  lampret
// No more low/high priority interrupts (PICPR removed). Added tick timer exception. Added exception prefix (SR[EPH]). Fixed single-step bug whenreading NPC.
//
// Revision 1.1  2002/01/03 08:16:15  lampret
// New prefixes for RTL files, prefixed module names. Updated cache controllers and MMUs.
//
// Revision 1.13  2001/11/23 08:38:51  lampret
// Changed DSR/DRR behavior and exception detection.
//
// Revision 1.12  2001/11/20 00:57:22  lampret
// Fixed width of du_except.
//
// Revision 1.11  2001/11/18 08:36:28  lampret
// For GDB changed single stepping and disabled trap exception.
//
// Revision 1.10  2001/10/21 17:57:16  lampret
// Removed params from generic_XX.v. Added translate_off/on in sprs.v and id.v. Removed spr_addr from dc.v and ic.v. Fixed CR+LF.
//
// Revision 1.9  2001/10/14 13:12:10  lampret
// MP3 version.
//
// Revision 1.1.1.1  2001/10/06 10:18:35  igorm
// no message
//
// Revision 1.4  2001/08/13 03:36:20  lampret
// Added cfg regs. Moved all defines into one defines.v file. More cleanup.
//
// Revision 1.3  2001/08/09 13:39:33  lampret
// Major clean-up.
//
// Revision 1.2  2001/07/22 03:31:54  lampret
// Fixed RAM's oen bug. Cache bypass under development.
//
// Revision 1.1  2001/07/20 00:46:21  lampret
// Development version of RTL. Libraries are missing.
//
//

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on
`include "or1200_defines.v"

module or1200_top(
	// System
	clk_i, rst_i, pic_ints_i, clmode_i,

	// Instruction WISHBONE INTERFACE
	iwb_clk_i, iwb_rst_i, iwb_ack_i, iwb_err_i, iwb_rty_i, iwb_dat_i,
	iwb_cyc_o, iwb_adr_o, iwb_stb_o, iwb_we_o, iwb_sel_o, iwb_dat_o,
`ifdef OR1200_WB_CAB
	iwb_cab_o,
`endif
`ifdef OR1200_WB_B3
	iwb_cti_o, iwb_bte_o,
`endif
	// Data WISHBONE INTERFACE
	dwb_clk_i, dwb_rst_i, dwb_ack_i, dwb_err_i, dwb_rty_i, dwb_dat_i,
	dwb_cyc_o, dwb_adr_o, dwb_stb_o, dwb_we_o, dwb_sel_o, dwb_dat_o,
`ifdef OR1200_WB_CAB
	dwb_cab_o,
`endif
`ifdef OR1200_WB_B3
	dwb_cti_o, dwb_bte_o,
`endif

	// External Debug Interface
	dbg_stall_i, dbg_ewt_i,	dbg_lss_o, dbg_is_o, dbg_wp_o, dbg_bp_o,
	dbg_stb_i, dbg_we_i, dbg_adr_i, dbg_dat_i, dbg_dat_o, dbg_ack_o,
	
`ifdef OR1200_BIST
	// RAM BIST
	mbist_si_i, mbist_so_o, mbist_ctrl_i,
`endif
	// Power Management
	pm_cpustall_i,
	pm_clksd_o, pm_dc_gate_o, pm_ic_gate_o, pm_dmmu_gate_o, 
	pm_immu_gate_o, pm_tt_gate_o, pm_cpu_gate_o, pm_wakeup_o, pm_lvolt_o

);

parameter dw = `OR1200_OPERAND_WIDTH;
parameter aw = `OR1200_OPERAND_WIDTH;
parameter ppic_ints = `OR1200_PIC_INTS;

//
// I/O
//

//
// System
//
input			clk_i;
input			rst_i;
input	[1:0]		clmode_i;	// 00 WB=RISC, 01 WB=RISC/2, 10 N/A, 11 WB=RISC/4
input	[ppic_ints-1:0]	pic_ints_i;

//
// Instruction WISHBONE interface
//
input			iwb_clk_i;	// clock input
input			iwb_rst_i;	// reset input
input			iwb_ack_i;	// normal termination
input			iwb_err_i;	// termination w/ error
input			iwb_rty_i;	// termination w/ retry
input	[dw-1:0]	iwb_dat_i;	// input data bus
output			iwb_cyc_o;	// cycle valid output
output	[aw-1:0]	iwb_adr_o;	// address bus outputs
output			iwb_stb_o;	// strobe output
output			iwb_we_o;	// indicates write transfer
output	[3:0]		iwb_sel_o;	// byte select outputs
output	[dw-1:0]	iwb_dat_o;	// output data bus
`ifdef OR1200_WB_CAB
output			iwb_cab_o;	// indicates consecutive address burst
`endif
`ifdef OR1200_WB_B3
output	[2:0]		iwb_cti_o;	// cycle type identifier
output	[1:0]		iwb_bte_o;	// burst type extension
`endif

//
// Data WISHBONE interface
//
input			dwb_clk_i;	// clock input
input			dwb_rst_i;	// reset input
input			dwb_ack_i;	// normal termination
input			dwb_err_i;	// termination w/ error
input			dwb_rty_i;	// termination w/ retry
input	[dw-1:0]	dwb_dat_i;	// input data bus
output			dwb_cyc_o;	// cycle valid output
output	[aw-1:0]	dwb_adr_o;	// address bus outputs
output			dwb_stb_o;	// strobe output
output			dwb_we_o;	// indicates write transfer
output	[3:0]		dwb_sel_o;	// byte select outputs
output	[dw-1:0]	dwb_dat_o;	// output data bus
`ifdef OR1200_WB_CAB
output			dwb_cab_o;	// indicates consecutive address burst
`endif
`ifdef OR1200_WB_B3
output	[2:0]		dwb_cti_o;	// cycle type identifier
output	[1:0]		dwb_bte_o;	// burst type extension
`endif

//
// External Debug Interface
//
input			dbg_stall_i;	// External Stall Input
input			dbg_ewt_i;	// External Watchpoint Trigger Input
output	[3:0]		dbg_lss_o;	// External Load/Store Unit Status
output	[1:0]		dbg_is_o;	// External Insn Fetch Status
output	[10:0]		dbg_wp_o;	// Watchpoints Outputs
output			dbg_bp_o;	// Breakpoint Output
input			dbg_stb_i;      // External Address/Data Strobe
input			dbg_we_i;       // External Write Enable
input	[aw-1:0]	dbg_adr_i;	// External Address Input
input	[dw-1:0]	dbg_dat_i;	// External Data Input
output	[dw-1:0]	dbg_dat_o;	// External Data Output
output			dbg_ack_o;	// External Data Acknowledge (not WB compatible)

`ifdef OR1200_BIST
//
// RAM BIST
//
input mbist_si_i;
input [`OR1200_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;
output mbist_so_o;
`endif

//
// Power Management
//
input			pm_cpustall_i;
output	[3:0]		pm_clksd_o;
output			pm_dc_gate_o;
output			pm_ic_gate_o;
output			pm_dmmu_gate_o;
output			pm_immu_gate_o;
output			pm_tt_gate_o;
output			pm_cpu_gate_o;
output			pm_wakeup_o;
output			pm_lvolt_o;


//
// Internal wires and regs
//

//
// DC to SB
//
wire	[dw-1:0]	dcsb_dat_dc;
wire	[aw-1:0]	dcsb_adr_dc;
wire			dcsb_cyc_dc;
wire			dcsb_stb_dc;
wire			dcsb_we_dc;
wire	[3:0]		dcsb_sel_dc;
wire			dcsb_cab_dc;
wire	[dw-1:0]	dcsb_dat_sb;
wire			dcsb_ack_sb;
wire			dcsb_err_sb;

//
// SB to BIU
//
wire	[dw-1:0]	sbbiu_dat_sb;
wire	[aw-1:0]	sbbiu_adr_sb;
wire			sbbiu_cyc_sb;
wire			sbbiu_stb_sb;
wire			sbbiu_we_sb;
wire	[3:0]		sbbiu_sel_sb;
wire			sbbiu_cab_sb;
wire	[dw-1:0]	sbbiu_dat_biu;
wire			sbbiu_ack_biu;
wire			sbbiu_err_biu;

//
// IC to BIU
//
wire	[dw-1:0]	icbiu_dat_ic;
wire	[aw-1:0]	icbiu_adr_ic;
wire			icbiu_cyc_ic;
wire			icbiu_stb_ic;
wire			icbiu_we_ic;
wire	[3:0]		icbiu_sel_ic;
wire	[3:0]		icbiu_tag_ic;
wire			icbiu_cab_ic;
wire	[dw-1:0]	icbiu_dat_biu;
wire			icbiu_ack_biu;
wire			icbiu_err_biu;
wire	[3:0]		icbiu_tag_biu;

//
// SR Interface
//
wire 			boot_adr_sel = `OR1200_SR_EPH_DEF;

//
// CPU's SPR access to various RISC units (shared wires)
//
wire			supv;
wire	[aw-1:0]	spr_addr;
wire	[dw-1:0]	spr_dat_cpu;
wire	[31:0]		spr_cs;
wire			spr_we;

//
// DMMU and CPU
//
wire			dmmu_en;
wire	[31:0]		spr_dat_dmmu;

//
// DMMU and QMEM
//
wire			qmemdmmu_err_qmem;
wire	[3:0]		qmemdmmu_tag_qmem;
wire	[aw-1:0]	qmemdmmu_adr_dmmu;
wire			qmemdmmu_cycstb_dmmu;
wire			qmemdmmu_ci_dmmu;

//
// CPU and data memory subsystem
//
wire			dc_en;
wire	[31:0]		dcpu_adr_cpu;
wire			dcpu_cycstb_cpu;
wire			dcpu_we_cpu;
wire	[3:0]		dcpu_sel_cpu;
wire	[3:0]		dcpu_tag_cpu;
wire	[31:0]		dcpu_dat_cpu;
wire	[31:0]		dcpu_dat_qmem;
wire			dcpu_ack_qmem;
wire			dcpu_rty_qmem;
wire			dcpu_err_dmmu;
wire	[3:0]		dcpu_tag_dmmu;

//
// IMMU and CPU
//
wire			immu_en;
wire	[31:0]		spr_dat_immu;

//
// CPU and insn memory subsystem
//
wire			ic_en;
wire	[31:0]		icpu_adr_cpu;
wire			icpu_cycstb_cpu;
wire	[3:0]		icpu_sel_cpu;
wire	[3:0]		icpu_tag_cpu;
wire	[31:0]		icpu_dat_qmem;
wire			icpu_ack_qmem;
wire	[31:0]		icpu_adr_immu;
wire			icpu_err_immu;
wire	[3:0]		icpu_tag_immu;
wire			icpu_rty_immu;

//
// IMMU and QMEM
//
wire	[aw-1:0]	qmemimmu_adr_immu;
wire			qmemimmu_rty_qmem;
wire			qmemimmu_err_qmem;
wire	[3:0]		qmemimmu_tag_qmem;
wire			qmemimmu_cycstb_immu;
wire			qmemimmu_ci_immu;

//
// QMEM and IC
//
wire	[aw-1:0]	icqmem_adr_qmem;
wire			icqmem_rty_ic;
wire			icqmem_err_ic;
wire	[3:0]		icqmem_tag_ic;
wire			icqmem_cycstb_qmem;
wire			icqmem_ci_qmem;
wire	[31:0]		icqmem_dat_ic;
wire			icqmem_ack_ic;

//
// QMEM and DC
//
wire	[aw-1:0]	dcqmem_adr_qmem;
wire			dcqmem_rty_dc;
wire			dcqmem_err_dc;
wire	[3:0]		dcqmem_tag_dc;
wire			dcqmem_cycstb_qmem;
wire			dcqmem_ci_qmem;
wire	[31:0]		dcqmem_dat_dc;
wire	[31:0]		dcqmem_dat_qmem;
wire			dcqmem_we_qmem;
wire	[3:0]		dcqmem_sel_qmem;
wire			dcqmem_ack_dc;

//
// Connection between CPU and PIC
//
wire	[dw-1:0]	spr_dat_pic;
wire			pic_wakeup;
wire			sig_int;

//
// Connection between CPU and PM
//
wire	[dw-1:0]	spr_dat_pm;

//
// CPU and TT
//
wire	[dw-1:0]	spr_dat_tt;
wire			sig_tick;

//
// Debug port and caches/MMUs
//
wire	[dw-1:0]	spr_dat_du;
wire			du_stall;
wire	[dw-1:0]	du_addr;
wire	[dw-1:0]	du_dat_du;
wire			du_read;
wire			du_write;
wire	[12:0]		du_except;
wire	[`OR1200_DU_DSR_WIDTH-1:0]     du_dsr;
wire	[dw-1:0]	du_dat_cpu;
wire			du_hwbkpt;

wire			ex_freeze;
wire	[31:0]		ex_insn;
wire	[31:0]		id_pc;
wire	[`OR1200_BRANCHOP_WIDTH-1:0]	branch_op;
wire	[31:0]		spr_dat_npc;
wire	[31:0]		rf_dataw;

`ifdef OR1200_BIST
//
// RAM BIST
//
wire			mbist_immu_so;
wire			mbist_ic_so;
wire			mbist_dmmu_so;
wire			mbist_dc_so;
wire      mbist_qmem_so;
wire			mbist_immu_si = mbist_si_i;
wire			mbist_ic_si = mbist_immu_so;
wire			mbist_qmem_si = mbist_ic_so;
wire			mbist_dmmu_si = mbist_qmem_so;
wire			mbist_dc_si = mbist_dmmu_so;
assign			mbist_so_o = mbist_dc_so;
`endif

wire  [3:0] icqmem_sel_qmem;
wire  [3:0] icqmem_tag_qmem;
wire  [3:0] dcqmem_tag_qmem;

//
// Instantiation of Instruction WISHBONE BIU
//
or1200_iwb_biu iwb_biu(
	// RISC clk, rst and clock control
	.clk(clk_i),
	.rst(rst_i),
	.clmode(clmode_i),

	// WISHBONE interface
	.wb_clk_i(iwb_clk_i),
	.wb_rst_i(iwb_rst_i),
	.wb_ack_i(iwb_ack_i),
	.wb_err_i(iwb_err_i),
	.wb_rty_i(iwb_rty_i),
	.wb_dat_i(iwb_dat_i),
	.wb_cyc_o(iwb_cyc_o),
	.wb_adr_o(iwb_adr_o),
	.wb_stb_o(iwb_stb_o),
	.wb_we_o(iwb_we_o),
	.wb_sel_o(iwb_sel_o),
	.wb_dat_o(iwb_dat_o),
`ifdef OR1200_WB_CAB
	.wb_cab_o(iwb_cab_o),
`endif
`ifdef OR1200_WB_B3
	.wb_cti_o(iwb_cti_o),
	.wb_bte_o(iwb_bte_o),
`endif

	// Internal RISC bus
	.biu_dat_i(icbiu_dat_ic),
	.biu_adr_i(icbiu_adr_ic),
	.biu_cyc_i(icbiu_cyc_ic),
	.biu_stb_i(icbiu_stb_ic),
	.biu_we_i(icbiu_we_ic),
	.biu_sel_i(icbiu_sel_ic),
	.biu_cab_i(icbiu_cab_ic),
	.biu_dat_o(icbiu_dat_biu),
	.biu_ack_o(icbiu_ack_biu),
	.biu_err_o(icbiu_err_biu)
);

//
// Instantiation of Data WISHBONE BIU
//
or1200_wb_biu dwb_biu(
	// RISC clk, rst and clock control
	.clk(clk_i),
	.rst(rst_i),
	.clmode(clmode_i),

	// WISHBONE interface
	.wb_clk_i(dwb_clk_i),
	.wb_rst_i(dwb_rst_i),
	.wb_ack_i(dwb_ack_i),
	.wb_err_i(dwb_err_i),
	.wb_rty_i(dwb_rty_i),
	.wb_dat_i(dwb_dat_i),
	.wb_cyc_o(dwb_cyc_o),
	.wb_adr_o(dwb_adr_o),
	.wb_stb_o(dwb_stb_o),
	.wb_we_o(dwb_we_o),
	.wb_sel_o(dwb_sel_o),
	.wb_dat_o(dwb_dat_o),
`ifdef OR1200_WB_CAB
	.wb_cab_o(dwb_cab_o),
`endif
`ifdef OR1200_WB_B3
	.wb_cti_o(dwb_cti_o),
	.wb_bte_o(dwb_bte_o),
`endif

	// Internal RISC bus
	.biu_dat_i(sbbiu_dat_sb),
	.biu_adr_i(sbbiu_adr_sb),
	.biu_cyc_i(sbbiu_cyc_sb),
	.biu_stb_i(sbbiu_stb_sb),
	.biu_we_i(sbbiu_we_sb),
	.biu_sel_i(sbbiu_sel_sb),
	.biu_cab_i(sbbiu_cab_sb),
	.biu_dat_o(sbbiu_dat_biu),
	.biu_ack_o(sbbiu_ack_biu),
	.biu_err_o(sbbiu_err_biu)
);

//
// Instantiation of IMMU
//
or1200_immu_top or1200_immu_top(
	// Rst and clk
	.clk(clk_i),
	.rst(rst_i),

`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_immu_si),
	.mbist_so_o(mbist_immu_so),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif

	// CPU and IMMU
	.ic_en(ic_en),
	.immu_en(immu_en),
	.supv(supv),
	.icpu_adr_i(icpu_adr_cpu),
	.icpu_cycstb_i(icpu_cycstb_cpu),
	.icpu_adr_o(icpu_adr_immu),
	.icpu_tag_o(icpu_tag_immu),
	.icpu_rty_o(icpu_rty_immu),
	.icpu_err_o(icpu_err_immu),

    // SR Interface
    .boot_adr_sel_i(boot_adr_sel),

	// SPR access
	.spr_cs(spr_cs[`OR1200_SPR_GROUP_IMMU]),
	.spr_write(spr_we),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_cpu),
	.spr_dat_o(spr_dat_immu),

	// QMEM and IMMU
	.qmemimmu_rty_i(qmemimmu_rty_qmem),
	.qmemimmu_err_i(qmemimmu_err_qmem),
	.qmemimmu_tag_i(qmemimmu_tag_qmem),
	.qmemimmu_adr_o(qmemimmu_adr_immu),
	.qmemimmu_cycstb_o(qmemimmu_cycstb_immu),
	.qmemimmu_ci_o(qmemimmu_ci_immu)
);

//
// Instantiation of Instruction Cache
//
or1200_ic_top or1200_ic_top(
	.clk(clk_i),
	.rst(rst_i),

`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_ic_si),
	.mbist_so_o(mbist_ic_so),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif

	// IC and QMEM
	.ic_en(ic_en),
	.icqmem_adr_i(icqmem_adr_qmem),
	.icqmem_cycstb_i(icqmem_cycstb_qmem),
	.icqmem_ci_i(icqmem_ci_qmem),
	.icqmem_sel_i(icqmem_sel_qmem),
	.icqmem_tag_i(icqmem_tag_qmem),
	.icqmem_dat_o(icqmem_dat_ic),
	.icqmem_ack_o(icqmem_ack_ic),
	.icqmem_rty_o(icqmem_rty_ic),
	.icqmem_err_o(icqmem_err_ic),
	.icqmem_tag_o(icqmem_tag_ic),

	// SPR access
	.spr_cs(spr_cs[`OR1200_SPR_GROUP_IC]),
	.spr_write(spr_we),
	.spr_dat_i(spr_dat_cpu),

	// IC and BIU
	.icbiu_dat_o(icbiu_dat_ic),
	.icbiu_adr_o(icbiu_adr_ic),
	.icbiu_cyc_o(icbiu_cyc_ic),
	.icbiu_stb_o(icbiu_stb_ic),
	.icbiu_we_o(icbiu_we_ic),
	.icbiu_sel_o(icbiu_sel_ic),
	.icbiu_cab_o(icbiu_cab_ic),
	.icbiu_dat_i(icbiu_dat_biu),
	.icbiu_ack_i(icbiu_ack_biu),
	.icbiu_err_i(icbiu_err_biu)
);

//
// Instantiation of Instruction Cache
//
or1200_cpu or1200_cpu(
	.clk(clk_i),
	.rst(rst_i),

	// Connection QMEM and IFETCHER inside CPU
	.ic_en(ic_en),
	.icpu_adr_o(icpu_adr_cpu),
	.icpu_cycstb_o(icpu_cycstb_cpu),
	.icpu_sel_o(icpu_sel_cpu),
	.icpu_tag_o(icpu_tag_cpu),
	.icpu_dat_i(icpu_dat_qmem),
	.icpu_ack_i(icpu_ack_qmem),
	.icpu_rty_i(icpu_rty_immu),
	.icpu_adr_i(icpu_adr_immu),
	.icpu_err_i(icpu_err_immu),
	.icpu_tag_i(icpu_tag_immu),

	// Connection CPU to external Debug port
	.ex_freeze(ex_freeze),
	.ex_insn(ex_insn),
	.id_pc(id_pc),
	.branch_op(branch_op),
	.du_stall(du_stall),
	.du_addr(du_addr),
	.du_dat_du(du_dat_du),
	.du_read(du_read),
	.du_write(du_write),
	.du_dsr(du_dsr),
	.du_except(du_except),
	.du_dat_cpu(du_dat_cpu),
	.du_hwbkpt(du_hwbkpt),
	.rf_dataw(rf_dataw),


	// Connection IMMU and CPU internally
	.immu_en(immu_en),

	// Connection QMEM and CPU
	.dc_en(dc_en),
	.dcpu_adr_o(dcpu_adr_cpu),
	.dcpu_cycstb_o(dcpu_cycstb_cpu),
	.dcpu_we_o(dcpu_we_cpu),
	.dcpu_sel_o(dcpu_sel_cpu),
	.dcpu_tag_o(dcpu_tag_cpu),
	.dcpu_dat_o(dcpu_dat_cpu),
        .dcpu_dat_i(dcpu_dat_qmem),
	.dcpu_ack_i(dcpu_ack_qmem),
	.dcpu_rty_i(dcpu_rty_qmem),
	.dcpu_err_i(dcpu_err_dmmu),
	.dcpu_tag_i(dcpu_tag_dmmu),

	// Connection DMMU and CPU internally
	.dmmu_en(dmmu_en),

    // SR Interface
    .boot_adr_sel_i(boot_adr_sel),

	// Connection PIC and CPU's EXCEPT
	.sig_int(sig_int),
	.sig_tick(sig_tick),

	// SPRs
	.supv(supv),
	.spr_addr(spr_addr),
	.spr_dat_cpu(spr_dat_cpu),
	.spr_dat_pic(spr_dat_pic),
	.spr_dat_tt(spr_dat_tt),
	.spr_dat_pm(spr_dat_pm),
	.spr_dat_dmmu(spr_dat_dmmu),
	.spr_dat_immu(spr_dat_immu),
	.spr_dat_du(spr_dat_du),
	.spr_dat_npc(spr_dat_npc),
	.spr_cs(spr_cs),
	.spr_we(spr_we)
);

//
// Instantiation of DMMU
//
or1200_dmmu_top or1200_dmmu_top(
	// Rst and clk
	.clk(clk_i),
	.rst(rst_i),

`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_dmmu_si),
	.mbist_so_o(mbist_dmmu_so),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif

	// CPU i/f
	.dc_en(dc_en),
	.dmmu_en(dmmu_en),
	.supv(supv),
	.dcpu_adr_i(dcpu_adr_cpu),
	.dcpu_cycstb_i(dcpu_cycstb_cpu),
	.dcpu_we_i(dcpu_we_cpu),
	.dcpu_tag_o(dcpu_tag_dmmu),
	.dcpu_err_o(dcpu_err_dmmu),

	// SPR access
	.spr_cs(spr_cs[`OR1200_SPR_GROUP_DMMU]),
	.spr_write(spr_we),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_cpu),
	.spr_dat_o(spr_dat_dmmu),

	// QMEM and DMMU
	.qmemdmmu_err_i(qmemdmmu_err_qmem),
	.qmemdmmu_tag_i(qmemdmmu_tag_qmem),
	.qmemdmmu_adr_o(qmemdmmu_adr_dmmu),
	.qmemdmmu_cycstb_o(qmemdmmu_cycstb_dmmu),
	.qmemdmmu_ci_o(qmemdmmu_ci_dmmu)
);

//
// Instantiation of Data Cache
//
or1200_dc_top or1200_dc_top(
	.clk(clk_i),
	.rst(rst_i),

`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_dc_si),
	.mbist_so_o(mbist_dc_so),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif

	// DC and QMEM
	.dc_en(dc_en),
	.dcqmem_adr_i(dcqmem_adr_qmem),
	.dcqmem_cycstb_i(dcqmem_cycstb_qmem),
	.dcqmem_ci_i(dcqmem_ci_qmem),
	.dcqmem_we_i(dcqmem_we_qmem),
	.dcqmem_sel_i(dcqmem_sel_qmem),
	.dcqmem_tag_i(dcqmem_tag_qmem),
	.dcqmem_dat_i(dcqmem_dat_qmem),
	.dcqmem_dat_o(dcqmem_dat_dc),
	.dcqmem_ack_o(dcqmem_ack_dc),
	.dcqmem_rty_o(dcqmem_rty_dc),
	.dcqmem_err_o(dcqmem_err_dc),
	.dcqmem_tag_o(dcqmem_tag_dc),

	// SPR access
	.spr_cs(spr_cs[`OR1200_SPR_GROUP_DC]),
	.spr_write(spr_we),
	.spr_dat_i(spr_dat_cpu),

	// DC and BIU
	.dcsb_dat_o(dcsb_dat_dc),
	.dcsb_adr_o(dcsb_adr_dc),
	.dcsb_cyc_o(dcsb_cyc_dc),
	.dcsb_stb_o(dcsb_stb_dc),
	.dcsb_we_o(dcsb_we_dc),
	.dcsb_sel_o(dcsb_sel_dc),
	.dcsb_cab_o(dcsb_cab_dc),
	.dcsb_dat_i(dcsb_dat_sb),
	.dcsb_ack_i(dcsb_ack_sb),
	.dcsb_err_i(dcsb_err_sb)
);

//
// Instantiation of embedded memory - qmem
//
or1200_qmem_top or1200_qmem_top(
	.clk(clk_i),
	.rst(rst_i),

`ifdef OR1200_BIST
	// RAM BIST
	.mbist_si_i(mbist_qmem_si),
	.mbist_so_o(mbist_qmem_so),
	.mbist_ctrl_i(mbist_ctrl_i),
`endif

	// QMEM and CPU/IMMU
	.qmemimmu_adr_i(qmemimmu_adr_immu),
	.qmemimmu_cycstb_i(qmemimmu_cycstb_immu),
	.qmemimmu_ci_i(qmemimmu_ci_immu),
	.qmemicpu_sel_i(icpu_sel_cpu),
	.qmemicpu_tag_i(icpu_tag_cpu),
	.qmemicpu_dat_o(icpu_dat_qmem),
	.qmemicpu_ack_o(icpu_ack_qmem),
	.qmemimmu_rty_o(qmemimmu_rty_qmem),
	.qmemimmu_err_o(qmemimmu_err_qmem),
	.qmemimmu_tag_o(qmemimmu_tag_qmem),

	// QMEM and IC
	.icqmem_adr_o(icqmem_adr_qmem),
	.icqmem_cycstb_o(icqmem_cycstb_qmem),
	.icqmem_ci_o(icqmem_ci_qmem),
	.icqmem_sel_o(icqmem_sel_qmem),
	.icqmem_tag_o(icqmem_tag_qmem),
	.icqmem_dat_i(icqmem_dat_ic),
	.icqmem_ack_i(icqmem_ack_ic),
	.icqmem_rty_i(icqmem_rty_ic),
	.icqmem_err_i(icqmem_err_ic),
	.icqmem_tag_i(icqmem_tag_ic),

	// QMEM and CPU/DMMU
	.qmemdmmu_adr_i(qmemdmmu_adr_dmmu),
	.qmemdmmu_cycstb_i(qmemdmmu_cycstb_dmmu),
	.qmemdmmu_ci_i(qmemdmmu_ci_dmmu),
	.qmemdcpu_we_i(dcpu_we_cpu),
	.qmemdcpu_sel_i(dcpu_sel_cpu),
	.qmemdcpu_tag_i(dcpu_tag_cpu),
	.qmemdcpu_dat_i(dcpu_dat_cpu),
	.qmemdcpu_dat_o(dcpu_dat_qmem),
	.qmemdcpu_ack_o(dcpu_ack_qmem),
	.qmemdcpu_rty_o(dcpu_rty_qmem),
	.qmemdmmu_err_o(qmemdmmu_err_qmem),
	.qmemdmmu_tag_o(qmemdmmu_tag_qmem),

	// QMEM and DC
	.dcqmem_adr_o(dcqmem_adr_qmem),
	.dcqmem_cycstb_o(dcqmem_cycstb_qmem),
	.dcqmem_ci_o(dcqmem_ci_qmem),
	.dcqmem_we_o(dcqmem_we_qmem),
	.dcqmem_sel_o(dcqmem_sel_qmem),
	.dcqmem_tag_o(dcqmem_tag_qmem),
	.dcqmem_dat_o(dcqmem_dat_qmem),
	.dcqmem_dat_i(dcqmem_dat_dc),
	.dcqmem_ack_i(dcqmem_ack_dc),
	.dcqmem_rty_i(dcqmem_rty_dc),
	.dcqmem_err_i(dcqmem_err_dc),
	.dcqmem_tag_i(dcqmem_tag_dc)
);

//
// Instantiation of Store Buffer
//
or1200_sb or1200_sb(
	// RISC clock, reset
	.clk(clk_i),
	.rst(rst_i),

	// Internal RISC bus (DC<->SB)
	.dcsb_dat_i(dcsb_dat_dc),
	.dcsb_adr_i(dcsb_adr_dc),
	.dcsb_cyc_i(dcsb_cyc_dc),
	.dcsb_stb_i(dcsb_stb_dc),
	.dcsb_we_i(dcsb_we_dc),
	.dcsb_sel_i(dcsb_sel_dc),
	.dcsb_cab_i(dcsb_cab_dc),
	.dcsb_dat_o(dcsb_dat_sb),
	.dcsb_ack_o(dcsb_ack_sb),
	.dcsb_err_o(dcsb_err_sb),

	// SB and BIU
	.sbbiu_dat_o(sbbiu_dat_sb),
	.sbbiu_adr_o(sbbiu_adr_sb),
	.sbbiu_cyc_o(sbbiu_cyc_sb),
	.sbbiu_stb_o(sbbiu_stb_sb),
	.sbbiu_we_o(sbbiu_we_sb),
	.sbbiu_sel_o(sbbiu_sel_sb),
	.sbbiu_cab_o(sbbiu_cab_sb),
	.sbbiu_dat_i(sbbiu_dat_biu),
	.sbbiu_ack_i(sbbiu_ack_biu),
	.sbbiu_err_i(sbbiu_err_biu)
);

//
// Instantiation of Debug Unit
//
or1200_du or1200_du(
	// RISC Internal Interface
	.clk(clk_i),
	.rst(rst_i),
	.dcpu_cycstb_i(dcpu_cycstb_cpu),
	.dcpu_we_i(dcpu_we_cpu),
	.dcpu_adr_i(dcpu_adr_cpu),
	.dcpu_dat_lsu(dcpu_dat_cpu),
	.dcpu_dat_dc(dcpu_dat_qmem),
	.icpu_cycstb_i(icpu_cycstb_cpu),
	.ex_freeze(ex_freeze),
	.branch_op(branch_op),
	.ex_insn(ex_insn),
	.id_pc(id_pc),
	.du_dsr(du_dsr),

	// For Trace buffer
	.spr_dat_npc(spr_dat_npc),
	.rf_dataw(rf_dataw),

	// DU's access to SPR unit
	.du_stall(du_stall),
	.du_addr(du_addr),
	.du_dat_i(du_dat_cpu),
	.du_dat_o(du_dat_du),
	.du_read(du_read),
	.du_write(du_write),
	.du_except(du_except),
	.du_hwbkpt(du_hwbkpt),

	// Access to DU's SPRs
	.spr_cs(spr_cs[`OR1200_SPR_GROUP_DU]),
	.spr_write(spr_we),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_cpu),
	.spr_dat_o(spr_dat_du),

	// External Debug Interface
	.dbg_stall_i(dbg_stall_i),
	.dbg_ewt_i(dbg_ewt_i),
	.dbg_lss_o(dbg_lss_o),
	.dbg_is_o(dbg_is_o),
	.dbg_wp_o(dbg_wp_o),
	.dbg_bp_o(dbg_bp_o),
	.dbg_stb_i(dbg_stb_i),
	.dbg_we_i(dbg_we_i),
	.dbg_adr_i(dbg_adr_i),
	.dbg_dat_i(dbg_dat_i),
	.dbg_dat_o(dbg_dat_o),
	.dbg_ack_o(dbg_ack_o)
);

//
// Programmable interrupt controller
//
or1200_pic or1200_pic(
	// RISC Internal Interface
	.clk(clk_i),
	.rst(rst_i),
	.spr_cs(spr_cs[`OR1200_SPR_GROUP_PIC]),
	.spr_write(spr_we),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_cpu),
	.spr_dat_o(spr_dat_pic),
	.pic_wakeup(pic_wakeup),
	.intr(sig_int), 

	// PIC Interface
	.pic_int(pic_ints_i)
);

//
// Instantiation of Tick timer
//
or1200_tt or1200_tt(
	// RISC Internal Interface
	.clk(clk_i),
	.rst(rst_i),
	.du_stall(du_stall),
	.spr_cs(spr_cs[`OR1200_SPR_GROUP_TT]),
	.spr_write(spr_we),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_cpu),
	.spr_dat_o(spr_dat_tt),
	.intr(sig_tick)
);

//
// Instantiation of Power Management
//
or1200_pm or1200_pm(
	// RISC Internal Interface
	.clk(clk_i),
	.rst(rst_i),
	.pic_wakeup(pic_wakeup),
	.spr_write(spr_we),
	.spr_addr(spr_addr),
	.spr_dat_i(spr_dat_cpu),
	.spr_dat_o(spr_dat_pm),

	// Power Management Interface
	.pm_cpustall(pm_cpustall_i),
	.pm_clksd(pm_clksd_o),
	.pm_dc_gate(pm_dc_gate_o),
	.pm_ic_gate(pm_ic_gate_o),
	.pm_dmmu_gate(pm_dmmu_gate_o),
	.pm_immu_gate(pm_immu_gate_o),
	.pm_tt_gate(pm_tt_gate_o),
	.pm_cpu_gate(pm_cpu_gate_o),
	.pm_wakeup(pm_wakeup_o),
	.pm_lvolt(pm_lvolt_o)
);


endmodule
