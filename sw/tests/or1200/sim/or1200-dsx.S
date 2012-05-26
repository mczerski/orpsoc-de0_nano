/*
	Delay-slot exception bit (DSX) test.

	Generate some exceptions in delay slots and not in delay slots
	and confirm the SR[DSX] bit gets set.

	Just synchronous exceptions for now (a bit trickier to test
	asynchronous ones like timer and interrupts.)

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

#define TEST_DSX_AND_RETURN 							; \
	l.mfspr	r3,r0,SPR_EPCR_BASE	/* Get EPC */ 				; \
	l.nop	2                       /* Report PC for diagnostic purpose */ 	; \
	/* Check SR[DSX] was as expected */ 					; \
	l.mfspr	r8,r0,SPR_SR    	/* Get SR */ 				; \
	l.andi	r8,r8,SPR_SR_DSX	/* Clear all bits except DSX */		; \
	l.xor	r8,r8,r10		/* r8 will be >0 if error */ 		; \
	l.sfne	r8,r0								; \
	l.bf	test_fail 							; \
	l.nop									; \
	/* Check if we were in delay slot, if so just advance by 8, else 4 */ 	; \
	l.addi	r3,r3,4			/* Step two instructions past where 	; \
					exception	occurred */ 		; \
	l.srli	r8,r10,11		/* If we were in delay slot, add extra 	; \
					4 to PC (0x2000>>11=4)*/ 		; \
	l.add	r3,r3,r8 							; \
	l.mtspr	r0,r3,SPR_EPCR_BASE 						; \
	l.rfe
	
	
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
	.global	_bus_handler
_bus_handler:
	TEST_DSX_AND_RETURN
	

/* ---[ 0x600: ALIGN error ]------------------------------------------------ */
	.org 0x600
	.global	_align_handler
_align_handler:
	TEST_DSX_AND_RETURN


/* ---[ 0x700: ILLEGAL INSN exception ]------------------------------------- */
	.org 0x700
	.global _illinsn_handler
_illinsn_handler:
	TEST_DSX_AND_RETURN

/* ---[ 0x900: DTLB exception ]--------------------------------------------- */
	.org 0x900
	.global _dtlb_handler
	TEST_DSX_AND_RETURN

/* ---[ 0xe00: TRAP error ]------------------------------------------------ */
	.org 0xe00
	.global	_trap_handler
_trap_handler:
	TEST_DSX_AND_RETURN

	
/* =================================================== [ text section ] === */
	.section  .text

/* =================================================== [ start ] === */	

	.global _start
_start:
	/* r2 is test counter - put in r3 and will be printed out for each
	successful call to test_func */
	l.movhi	r2,0

	l.movhi r9,hi(test_fail)
	l.ori   r9,r9,lo(test_fail)

	/* Alignment exception tests */
	
	/* This test should _NOT_ set DSX, so clear r10 */
	l.movhi	r10,0
	/* Should cause an alignment error */
	l.lwz	r1,1(r0)

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfeq	r0,r0
	l.bf	test_func
	/* Should cause an alignment error */
	l.lwz	r1,1(r0)

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfne	r0,r0
	l.bnf	test_func
	/* Should cause an alignment error */
	l.lwz	r1,1(r0)

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.j	test_func
	/* Should cause an alignment error */
	l.lwz	r1,1(r0)

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.jal	test_func
	/* Should cause an alignment error */
	l.lwz	r1,1(r0)

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jr	r5
	/* Should cause an alignment error */
	l.lwz	r1,1(r0)

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jalr	r5
	/* Should cause an alignment error */
	l.lwz	r1,1(r0)

	/* Make some calls to the functions which will trigger exceptions
	   to check that the DSX bit is not set */
	l.ori	r10,r0,0
	l.jal	align_func
	l.nop

	
	/* Illegal instruction exception tests */

	/* This test should _NOT_ set DSX, so clear r10 */
	l.movhi	r10,0
	/* Should cause an illegal insn error */
	.word 0xef000000

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfeq	r0,r0
	l.bf	test_func
	/* Should cause an illegal insn error */
	.word 0xef000000

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfne	r0,r0
	l.bnf	test_func
	/* Should cause an illegal insn error */
	.word 0xef000000
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.j	test_func
	/* Should cause an illegal insn error */
	.word 0xef000000
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.jal	test_func
	/* Should cause an illegal insn error */
	.word 0xef000000
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jr	r5
	/* Should cause an illegal insn error */
	.word 0xef000000
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jalr	r5
	/* Should cause an illegal insn error */
	.word 0xef000000

	/* Make some calls to the functions which will trigger exceptions
	   to check that the DSX bit is not set */
	l.ori	r10,r0,0
	l.jal	illegal_insn_func
	l.nop

	/* Bus error exceptions */

	/* This test should _NOT_ set DSX, so clear r10 */
	l.movhi	r10,0
	/* This should cause a bus error */
	l.lwz	r1,-4(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfeq	r0,r0
	l.bf	test_func
	/* This should cause a bus error */
	l.lwz	r1,-4(r0)

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfne	r0,r0
	l.bnf	test_func
	/* This should cause a bus error */
	l.lwz	r1,-4(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.j	test_func
	/* This should cause a bus error */
	l.lwz	r1,-4(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.jal	test_func
	/* This should cause a bus error */
	l.lwz	r1,-4(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jr	r5
	/* This should cause a bus error */
	l.lwz	r1,-4(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jalr	r5
	/* This should cause a bus error */
	l.lwz	r1,-4(r0)

	/* Make some calls to the functions which will trigger exceptions
	   to check that the DSX bit is not set */
	l.ori	r10,r0,0
	l.jal	bus_err_func
	l.nop

	/* Trap instruction exception tests */

	/* This test should _NOT_ set DSX, so clear r10 */
	l.movhi	r10,0
	/* Should cause an trap error */
	l.trap 0

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfeq	r0,r0
	l.bf	test_func
	/* Should cause an trap error */
	l.trap 0

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfne	r0,r0
	l.bnf	test_func
	/* Should cause an trap error */
	l.trap 0
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.j	test_func
	/* Should cause an trap error */
	l.trap 0
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.jal	test_func
	/* Should cause an trap error */
	l.trap 0
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jr	r5
	/* Should cause an trap error */
	l.trap 0
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jalr	r5
	/* Should cause an trap error */
	l.trap 0

	/* Make some calls to the functions which will trigger exceptions
	   to check that the DSX bit is not set */
	l.ori	r10,r0,0
	l.jal	trap_func
	l.nop

	/* DMMU miss test */

	/* Check if we have a DMMU */
	l.mfspr	r3,r0,SPR_UPR
	l.andi  r3,r3,SPR_UPR_DMP
	l.sfeq	r3,r0
	/* Flag set if no DMMU */
	l.bf    dmmu_test_done
	l.nop
	
	/* Just enabling the DMMU with no valid match match registers should
	be enough to determine number of DMMU entries - hold this value in r3 */
	l.mfspr	r3,r0,SPR_DMMUCFGR
	l.andi	r4,r3,SPR_DMMUCFGR_NTS
	l.srli	r4,r4,SPR_DMMUCFGR_NTS_OFF
	l.ori	r6,r0,1
	l.sll	r3,r6,r4
	
	/* Setup the Data MMU's TLBS - invalidate them */
	l.movhi r4, hi(SPR_DTLBMR_BASE(0))
	l.ori r4, r4, lo(SPR_DTLBMR_BASE(0))

	/* DTLB invalidate loop */
1:
	l.mtspr r4, r0, 0x0
	l.addi r4, r4, 0x1
	l.sfeq r3, r0
	l.bnf 1b
	l.addi r3, r3, -1

	.extern lo_dmmu_en
	/* Now enable the DMMU */
	l.movhi r4, hi(lo_dmmu_en)
	l.ori r4, r4, lo(lo_dmmu_en)
	l.jalr r4
	l.nop

	/* Now any data access should cause a miss */

	/* This test should _NOT_ set DSX, so clear r10 */
	l.movhi	r10,0
	/* This should cause a DLTB miss */
	l.lwz	r1,0(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfeq	r0,r0
	l.bf	test_func
	/* This should cause a DLTB miss */
	l.lwz	r1,0(r0)

	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.sfne	r0,r0
	l.bnf	test_func
	/* This should cause a DLTB miss */
	l.lwz	r1,0(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.j	test_func
	/* This should cause a DLTB miss */
	l.lwz	r1,0(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.jal	test_func
	/* This should cause a DLTB miss */
	l.lwz	r1,0(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jr	r5
	/* This should cause a DLTB miss */
	l.lwz	r1,0(r0)
	
	/* This test should_ set DSX, so put SPR_SR_DSX in r10 */
	l.ori	r10,r0,SPR_SR_DSX
	l.movhi	r5,hi(test_func)
	l.ori	r5,r5,lo(test_func)
	l.jalr	r5
	/* This should cause a DLTB miss */
	l.lwz	r1,0(r0)

	/* Make some calls to the functions which will trigger exceptions
	   to check that the DSX bit is not set */
	l.ori	r10,r0,0
	l.jal	dtlb_func
	l.nop

	/* Now disable DMMU */
        l.mfspr r3,r0,SPR_SR
        l.xori  r3,r3,SPR_SR_DME
        l.mtspr r0,r3,SPR_ESR_BASE
	l.movhi	r9,hi(dmmu_test_done)
	l.ori	r9,r9,lo(dmmu_test_done)
        l.mtspr r0,r9,SPR_EPCR_BASE
        l.rfe
	
dmmu_test_done:	

	/* Check if we have an instruction cache */
	l.mfspr	r3,r0,SPR_UPR
	l.andi  r3,r3,SPR_UPR_ICP
	l.sfeq	r3,r0
	/* Flag set if no icache */
	l.bf    test_ok
	l.nop

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

test_func:
	/* A test function to call, just return */
	l.jr	r9
	l.nop	2 	/* print out whatever is in r3 */

test_fail:
	l.movhi	r3,0xbaaa
	l.ori	r3,r3,0xaaad
	l.nop	2
	l.ori	r3,r0,1
	l.nop	1

align_func:
	/* DSX should _not_ be set on exception here */
	l.lwz	r1,1(r0)
	l.jr	r9
	l.nop

illegal_insn_func:
	/* DSX should _not_ be set on exception here */	
	.word 0xef000000
	l.jr	r9
	l.nop

bus_err_func:
	/* DSX should _not_ be set on exception here */	
	l.lwz	r1,-4(r0)
	l.jr	r9
	l.nop

trap_func:
	/* DSX should _not_ be set on exception here */	
	l.trap  0
	l.jr	r9
	l.nop

dtlb_func:
	/* DSX should _not_ be set on exception here */	
	l.lwz	r1,0(r0)
	l.jr	r9
	l.nop

restart_with_caches_enabled:
	l.jal 	_cache_init
	l.nop
	l.j     _start
	l.nop
