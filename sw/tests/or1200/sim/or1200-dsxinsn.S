/*
	Test correct delay-slot exception bit (DSX) behavior on
	instruction-fetch related exceptions.

	The only case where DSX is set on instruction-fetch related
	exception is when instructions in delay slots occur in a new
	page which needs to be mapped.

	In this test we will trigger an instruction MMU miss for an
	instruction in a delay slot. To do this, we need to have a
	branch instruction as the very last instruction of a page,
	with the delay slot instruction being on a new unmapped page.
	
	Set r10 to hold whether we are expecting SR[DSX] to be set or
	not. Exceptions will advance the PC by 0x8 to step over both
	the jump/branch and instruction causing an exception.

	Julius Baxter <juliusbaxter@gmail.com>
	
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
	/* Jump to program initialisation code */
	.global _start
	l.movhi r4, hi(_start)
	l.ori 	r4, r4, lo(_start)
	l.jr    r4
	l.nop
  
/* ---[ 0x200: BUS error ]------------------------------------------------ */
	.org 0x200
	l.j	test_fail
	l.nop
	
/* ---[ 0x600: ALIGN error ]------------------------------------------------ */
	.org 0x600
	l.j	test_fail
	l.nop
	
/* ---[ 0x700: ILLEGAL INSN exception ]------------------------------------- */
	.org 0x700
	l.j	test_fail
	l.nop

/* ---[ 0x900: DTLB exception ]--------------------------------------------- */
	.org 0x900
	l.j	test_fail
	l.nop

/* ---[ 0xa00: itlb miss ]---------------------------------------------- */
        .org 0xa00

	/* First check if we're expecting a miss in a delay slot - check r10 */
	l.mfspr	r3,r0,SPR_EEAR_BASE	/* Get EPC */ 				
	l.nop	2                       /* Report PC for diagnostic purpose */ 	
	/* Check SR[DSX] was as expected */ 					
	l.mfspr	r8,r0,SPR_SR    	/* Get SR */ 				
	l.andi	r8,r8,SPR_SR_DSX	/* Clear all bits except DSX */		
	l.xor	r8,r8,r10		/* r8 will be >0 if error */ 		
	l.sfne	r8,r0								
	l.bf	test_fail 							
	l.nop									
	
	/* Simple itlb miss handler - install 1-1 mappings on misses */
	l.mfspr	r12,r0,SPR_EEAR_BASE /* Get the PC of the exception */
	l.srli	r13,r12,13 /* Get the page number, divide by 8K, store in r13 */
	/* Set up the match registers */
	l.movhi	r14,hi(SPR_ITLBMR_VPN)
	l.ori	r14,r14,lo(SPR_ITLBMR_VPN)
	l.and	r14,r12,r14 /* Mask in the VPN */
	l.ori	r15,r14,SPR_ITLBMR_V /* Set this match as valid */
	/* Write it into the appropriate match register, way 0 only */
	l.mtspr	r13,r15,SPR_ITLBMR_BASE(0)
	/* Set up the translate register - no restrictions */
	l.ori	r15,r14,ITLB_PR_NOLIMIT
	/* Write it into the appropriate translate register  */
	l.mtspr	r13,r15,SPR_ITLBTR_BASE(0)
	/* MMU setup should now be complete, let's go back */
	l.rfe	
	
/* ---[ 0xe00: TRAP error ]------------------------------------------------ */
	.org 0xe00
	l.j	test_fail
	l.nop
	
/* =================================================== [ text section ] === */
	.section  .text

/* =================================================== [ start ] === */	

	.global _start
_start:
	/* First initialise the instruction MMU */
	
	l.mfspr	r3,r0,SPR_IMMUCFGR
	l.andi	r4,r3,SPR_IMMUCFGR_NTS
	l.srli	r4,r4,SPR_IMMUCFGR_NTS_OFF
	l.ori	r6,r0,1
	l.sll	r3,r6,r4
	
	/* Setup the IMMU's TLBs - invalidate them */
	l.movhi r4, hi(SPR_ITLBMR_BASE(0))
	l.ori r4, r4, lo(SPR_ITLBMR_BASE(0))

	/* ITLB invalidate loop */
1:
	l.mtspr r4, r0, 0x0
	l.addi r4, r4, 0x1
	l.sfeq r3, r0
	l.bnf 1b
	l.addi r3, r3, -1

	/* Enable MMU - we should get a miss for this page */
	l.movhi	r10,0 /* Clear r10 - not expecting to be in a delay slot
			when this TLB miss occurs */
	
	.extern lo_immu_en
	/* Now enable the IMMU */
	l.movhi r4, hi(lo_immu_en)
	l.ori r4, r4, lo(lo_immu_en)
	l.jalr r4
	l.nop

	/* Copy the 2 instructions from the ljr9_function function to
	places which should cause TLB misses in the delay slot */
	l.movhi	r6,hi(ljr9_function)
	l.ori	r6,r6,lo(ljr9_function)

	/* r13 should have the page number we're in from the TLB miss we caused
	when enabling the immu. Take that and add 16 to determine the page
	boundary we'll play with */
	l.addi	r4,r13,16

	/* Calculate the physical address for this page */
	l.slli	r8,r4,13

	/* Copy our function to the last 2 instructions of the page before */
	l.lwz	r1,0(r6)
	l.sw	-8(r8),r1
	l.lwz	r1,4(r6)
	l.sw	-4(r8),r1

	/* Call it - we should _not_ have DSX set on the itbl miss */
	l.movhi	r10,0
	l.addi	r1,r8,-8

	/* Report value */
	l.or	r3,r1,r1
	l.nop	2

	l.jalr	r1
	l.nop
	
	/* Tests finish */

	/* Now do what we've done for the miss but put delay slot instruction
	in the new page */

	/* Calculate the physical address for this page */
	l.slli	r8,r4,13

	/* Copy our function to the last 2 instructions of the page before */
	l.lwz	r1,0(r6)
	l.sw	-4(r8),r1
	l.lwz	r1,4(r6)
	l.sw	0(r8),r1

	/* Clear insn cache for this area (need to if it's enabled so we
	don't get the cached instructions from the previous test) */
	l.mtspr r0,r8,SPR_ICBIR
	l.addi	r1,r8,-4
	l.mtspr r0,r1,SPR_ICBIR

	/* Jump to (r8-0x4) - we _should_ have DSX set on the itbl miss as
	the jump instruction will be on the last instruction of the previous
	page (already mapped in ITLB) and the delay slot will be the first
	instruction on the next page, which is unmapped at this stage and
	should cause an ITLB miss*/
	l.ori	r10,r0,SPR_SR_DSX
	l.addi	r1,r8,-4

	/* Report value */
	l.or	r3,r1,r1
	l.nop	2

	l.jalr	r1
	l.nop
	

	/* TODO - track and check the number of TLB misses we should
	have incurred */
	
	/* Now repeat the tests with caches enabled if they weren't */
	l.mfspr	r1,r0,SPR_SR
	l.andi	r1,r1,SPR_SR_ICE
	l.sfeq	r0,r1  /* Set flag if caches not enabled */
	l.bf	restart_with_caches_enabled
	l.nop
	
test_ok:
	l.movhi	r3,0x8000
	l.ori	r3,r3,0x000d
	l.nop	2
	l.or	r3,r0,r0
	l.nop	1

test_fail:
	l.movhi	r3,0xbaaa
	l.ori	r3,r3,0xaaad
	l.nop	2
	l.ori	r3,r0,1
	l.nop	1

restart_with_caches_enabled:
	
	/* Disable IMMU before restart*/
        l.mfspr r3,r0,SPR_SR
        l.xori  r3,r3,SPR_SR_IME
        l.mtspr r0,r3,SPR_ESR_BASE
	l.movhi	r9,hi(.L1)
	l.ori	r9,r9,lo(.L1)
        l.mtspr r0,r9,SPR_EPCR_BASE
        l.rfe
.L1:	
	l.jal 	_cache_init
	l.nop

	/* Actually we won't want dcache enabled as we'll be reading
	and writing instructions around the shop so will not want them
	being cached */
        l.mfspr r3,r0,SPR_SR
        l.xori  r3,r3,SPR_SR_DCE
        l.mtspr r0,r3,SPR_SR
	
	l.j     _start
	l.nop

	/* A simple function, which we will copy the instructions of
	to different parts of memory */
ljr9_function:
	l.jr	r9
	l.nop

