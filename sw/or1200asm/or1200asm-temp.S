
#include "spr-defs.h"
#include "board.h"
#include "or1200-defines.h"
	
	
/* =================================================== [ exceptions ] === */
	.section .vectors, "ax"


/* ---[ 0x100: RESET exception ]----------------------------------------- */
        .org 0x100 	
	l.movhi r0, 0
	/* Clear status register */
	l.ori r1, r0, SPR_SR_SM
	l.mtspr r0, r1, SPR_SR
	/* Clear timer  */
	l.mtspr r0, r0, SPR_TTMR

	/* Jump to program initialisation code */
	.global _start
	l.movhi r4, hi(_start)
	l.ori r4, r4, lo(_start)
	l.jr    r4
	l.nop


/* =================================================== [ text ] === */
	.section .text

/* =================================================== [ start ] === */	

	.global _start
_start:	

	/* Instruction cache enable */
	/* Check if IC present and skip enabling otherwise */
	l.mfspr r24,r0,SPR_UPR
	l.andi  r26,r24,SPR_UPR_ICP
	l.sfeq  r26,r0
	l.bf    .L8
	l.nop
	
	/* Disable IC */
	l.mfspr r6,r0,SPR_SR
	l.addi  r5,r0,-1
	l.xori  r5,r5,SPR_SR_ICE
	l.and   r5,r6,r5
	l.mtspr r0,r5,SPR_SR
	
	/* Establish cache block size
	If BS=0, 16;
	If BS=1, 32;
	r14 contain block size
	*/
	l.mfspr r24,r0,SPR_ICCFGR
	l.andi  r26,r24,SPR_ICCFGR_CBS
	l.srli  r28,r26,7
	l.ori   r30,r0,16
	l.sll   r14,r30,r28
	
	/* Establish number of cache sets
	r16 contains number of cache sets
	r28 contains log(# of cache sets)
	*/
	l.andi  r26,r24,SPR_ICCFGR_NCS
	l.srli  r28,r26,3
	l.ori   r30,r0,1
	l.sll   r16,r30,r28
	
	/* Invalidate IC */
	l.addi  r6,r0,0
	l.sll   r5,r14,r28
	
.L7:
	l.mtspr r0,r6,SPR_ICBIR
	l.sfne  r6,r5
	l.bf    .L7
	l.add   r6,r6,r14
	
	/* Enable IC */
	l.mfspr r6,r0,SPR_SR
	l.ori   r6,r6,SPR_SR_ICE
	l.mtspr r0,r6,SPR_SR
	l.nop
	l.nop
	l.nop
	l.nop
	l.nop
	l.nop
	l.nop
	l.nop

.L8:
	/* Data cache enable */
        /* Check if DC present and skip enabling otherwise */
        l.mfspr r24,r0,SPR_UPR
        l.andi  r26,r24,SPR_UPR_DCP
        l.sfeq  r26,r0
        l.bf    .L10
        l.nop
        /* Disable DC */
        l.mfspr r6,r0,SPR_SR
        l.addi  r5,r0,-1
        l.xori  r5,r5,SPR_SR_DCE
	l.and   r5,r6,r5
        l.mtspr r0,r5,SPR_SR
        /* Establish cache block size
           If BS=0, 16;
           If BS=1, 32;
           r14 contain block size
        */
        l.mfspr r24,r0,SPR_DCCFGR
        l.andi  r26,r24,SPR_DCCFGR_CBS
        l.srli  r28,r26,7
        l.ori   r30,r0,16
        l.sll   r14,r30,r28
        /* Establish number of cache sets
           r16 contains number of cache sets
           r28 contains log(# of cache sets)
        */
	l.andi  r26,r24,SPR_DCCFGR_NCS
	l.srli  r28,r26,3
        l.ori   r30,r0,1
        l.sll   r16,r30,r28
        /* Invalidate DC */
        l.addi  r6,r0,0
        l.sll   r5,r14,r28
.L9:
        l.mtspr r0,r6,SPR_DCBIR
        l.sfne  r6,r5
        l.bf    .L9
	l.add   r6,r6,r14
        /* Enable DC */
        l.mfspr r6,r0,SPR_SR
        l.ori   r6,r6,SPR_SR_DCE
        l.mtspr r0,r6,SPR_SR
.L10:
	// Kick off test
	l.jal   _main
	l.nop
	


/* =================================================== [ main ] === */
	
	.global _main	
_main:

	/* Some single precision normalized numbers */
#define FP_S_P_ZERO    (0x00000000)	/* Positive zero */
#define FP_S_N_ZERO    (0x80000000)	/* Negative zero */
#define  FP_S_0_5      (0x3f000000)	/* +0.5 */
#define  FP_S_ONE      (0x3f800000)	/* +1.0 */
#define  FP_S_1_5      (0x3fc00000)	/* +1.5 */
#define  FP_S_TWO      (0x40000000)	/* +2.0 */
#define  FP_S_THREE    (0x40400000)	/* +3.0 */
#define FP_S_P_INF     (0x7f800000)	/* Positive infinity */
#define FP_S_N_INF     (0xff800000)	/* Negative infinity */
	

#define FP_S_P_NAN     (0x7fc00000)	/* Positive qNaN */
#define FP_S_N_NAN     (0xffc00000)	/* Negative qNaN */

#define LOAD_CONST(reg,val)						 \
	l.movhi	reg,hi(val)						;\
	l.ori	reg,reg,lo(val)

#define SET_RM(rm)						 \
	l.mfspr r4, r0, SPR_FPCSR 				;\
	/* Clear rounding mode bits */				;\
	l.ori 	r4, r4, SPR_FPCSR_RM				;\
	l.xori 	r4, r4, SPR_FPCSR_RM				;\
	/* Set desired rounding mode bits */			;\
	l.ori r4, r4, rm					;\
	l.mtspr r0, r4, SPR_FPCSR

	
	SET_RM	(FPCSR_RM_RN)
	
	// Tests that were failing from or1200asm-fp
	/*
	LOAD_CONST(r4, FP_S_ONE)
	lf.div.s r3, r4, r4
	l.nop 0x2

	LOAD_CONST(r5, FP_S_TWO)
	lf.div.s r3, r5, r4
	l.nop 0x2

	LOAD_CONST(r6, FP_S_THREE)
	lf.div.s r3, r6, r5
	l.nop 0x2

	LOAD_CONST(r7, FP_S_P_ZERO)
	lf.div.s r3, r7, r4
	l.nop 0x2

	LOAD_CONST(r8, FP_S_N_ZERO)
	lf.div.s r3, r8, r5
	l.nop 0x2
	*/
	/*
	// Tests failing in testfloat:
	// 1 / infinity should= 0
	LOAD_CONST(r4,FP_S_P_INF)
	LOAD_CONST(r5,FP_S_ONE)
	lf.div.s r4, r5, r4

	// inf / 0 should= inf
	LOAD_CONST(r4,FP_S_P_INF)
	LOAD_CONST(r5,FP_S_P_ZERO)
	lf.div.s r3, r4, r5
	l.nop 0x2
	
	// 1.0 / qNaN = NaN
	LOAD_CONST(r6, FP_S_P_NAN)
	LOAD_CONST(r5,FP_S_ONE)	
	lf.div.s r3, r5, r6	
	*/
	
	lf.add.s r3, r5, r4
	lf.sub.s r3, r5, r4
	lf.mul.s r3, r5, r4
	lf.div.s r3, r5, r4
	lf.itof.s r3, r5
	lf.ftoi.s r3, r5
	lf.sfgt.s r3, r5

	l.nop 0x1

	