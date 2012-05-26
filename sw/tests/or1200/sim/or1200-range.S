/*
	OR1200 Range exception test

	Very basic, testing, checking that the EPC value is correct
	for generated range exceptions.

	Julius Baxter <juliusbaxter at gmail.com>
	
*/
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2012 Authors and OPENCORES.ORG                 ////
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
#include "spr-defs.h"
#include "board.h"
#include "or1200-defines.h"
	
/* =================================================== [ exceptions ] === */
	.section .vectors, "ax"


/* ---[ 0x100: RESET exception ]----------------------------------------- */
        .org 0x100 	
	l.movhi r0, 0
	/* Clear status register */
	l.ori 	r1, r0, SPR_SR_SM
	l.mtspr r0, r1, SPR_SR
	/* Clear timer  */
	l.mtspr r0, r0, SPR_TTMR
	/* Init the stack */
	.global stack
	l.movhi r1, hi(stack)
	l.ori 	r1, r1, lo(stack)
	l.addi  r2, r0, -3
	l.and   r1, r1, r2
	// Clear r10 -used to remember if we've run the
	// test with cache eanbeld yet.
	l.movhi	r10, 0
	/* Jump to program initialisation code */
	.global _start
	l.movhi r4, hi(_start)
	l.ori 	r4, r4, lo(_start)
	l.jr    r4
	l.nop

/* ---[ 0x700: ILLEGAL INSN exception ]------------------------------------- */
	.org 0x700
	l.nop 0x1	


/* ---[ 0xB00: RANGE exception ]-------------------------------------------- */
	.org 0xb00
	l.mfspr r3,r0,SPR_EPCR_BASE
	l.nop	2
	// Check the PC
	l.ori	r6,r0,0x7fff // Use this as a mask for the PC
	l.and	r7,r6,r3 // just take the bottom 15 bits, should be enough
	// Test 1 should be at
	l.sfeqi	r5,1
	l.bf	test1
	l.nop
	l.sfeqi	r5,2
	l.bf	test2
	l.nop

test1:
	l.sfnei	r7,0xf08 // test 1 trigger insn PC
	l.bf	fail
	l.nop
	// set the PC to step over the range exception
	l.addi	r3,r3,4
	l.mtspr	r0,r3,SPR_EPCR_BASE
	l.nop 	2
	l.j	return
	l.nop
test2:
	l.sfnei	r7,0xf10 // test 2 - in delay slot, so PC should be of
	// preceeding l.j insn
	l.bf	fail
	l.nop
	// set the PC to step over the branch and range exception
	l.addi	r3,r3,8
	l.mtspr	r0,r3,SPR_EPCR_BASE
	l.j	return
	l.nop

return:	
	// Clear the OV flag
	l.mfspr r3,r0,SPR_ESR_BASE
	l.xori	r3,r3,SPR_SR_OV
	l.mtspr	r0,r3,SPR_ESR_BASE
	l.rfe


	.org 0xf00
ov_tests:	
	// Cause some range exceptions at known PC
	// Trigger a range execption
	l.movhi	r2,0x4000

	// Test 1
	l.ori	r5,r0,1
	// Should have 0x40000000 + 0x40000000, at PC 0xf08
	l.add	r4,r2,r2

	// Test 2 - delay slot
	l.ori	r5,r0,2
	l.j	a_place
	// Should have 0x40000000 + 0x40000000, at PC 0xf10 (insn before as
	// we're in delay slot)
	l.add	r4,r2,r2
a_place:
	l.nop
	// Check if we've run with cache yet - if so then
	// r10 will contain nonzero
	l.sfeq	r10,r0
	l.bnf	pass
	l.nop
	// Init caches and restart
	l.jal 	_cache_init
	l.nop
	l.j	_start
	l.ori	r10,r0,1

pass:	
	l.movhi	r3,0
	l.nop 1


/* =================================================== [ text section ] === */
	.section  .text

/* =================================================== [ start ] === */	

	.global _start
_start:
	// Set up SR to have range exception enabled
	l.mfspr	r3, r0, SPR_SR
	l.nop	0x2
	l.ori	r3,r3,SPR_SR_OVE
	l.nop	0x2
	l.mtspr	r0,r3,SPR_SR

	// Now jump to the tests
	l.movhi	r1,hi(ov_tests)
	l.ori	r1,r1,lo(ov_tests)
	l.jr	r1
	l.nop
	
fail:
	l.nop 	2
	l.ori	r3,r0,1
	l.nop	1
