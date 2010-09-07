#include "spr-defs.h"
#include "board.h"

/* ======================================================= [ macros ] === */


#define CLEAR_GPR(gpr) \
	l.or    gpr, r0, r0
    
#define ENTRY(symbol)    \
	.global symbol ; \
symbol:

#define LOAD_SYMBOL_2_GPR(gpr,symbol)  \
	.global symbol ;               \
	l.movhi gpr, hi(symbol) ;      \
	l.ori   gpr, gpr, lo(symbol)

	// Really goes to configurable interrupt handler
#define UNHANDLED_EXCEPTION            \
	l.addi  r1, r1, -128;          \
	l.sw    4(r1), r3;             \
	l.sw    8(r1), r4;             \
	l.mfspr r3,r0,SPR_NPC;          \
	l.mfspr r4,r0,SPR_EPCR_BASE;   \
	l.j default_exception_handler; \
	l.nop



	

/* =================================================== [ exceptions ] === */
	.section .vectors, "ax"


/* ---[ 0x100: RESET exception ]----------------------------------------- */
        .org 0x100 	
	l.movhi r0, 0
	/* Clear status register, set supervisor mode */
	l.ori r1, r0, SPR_SR_SM
	l.mtspr r0, r1, SPR_SR
	/* Clear timer  */
	l.mtspr r0, r0, SPR_TTMR
	/* Early Stack initilization */
	LOAD_SYMBOL_2_GPR(r1, _stack)
	l.addi  r2, r0, -3
	l.and   r1, r1, r2

	/* Jump to program initialisation code */
	LOAD_SYMBOL_2_GPR(r4, _start)
	l.jr    r4
	l.nop

/* ---[ 0x200: BUS exception ]------------------------------------------- */
	.org 0x200
	UNHANDLED_EXCEPTION

/* ---[ 0x300: Data Page Fault exception ]------------------------------- */
	.org 0x300
	UNHANDLED_EXCEPTION
	
/* ---[ 0x400: Insn Page Fault exception ]------------------------------- */
	.org 0x400
	UNHANDLED_EXCEPTION

/* ---[ 0x500: Timer exception ]----------------------------------------- */
	.org 0x500
	UNHANDLED_EXCEPTION

/* ---[ 0x600: Aligment exception ]-------------------------------------- */
	.org 0x600
	UNHANDLED_EXCEPTION
	
/* ---[ 0x700: Illegal insn exception ]---------------------------------- */
	.org 0x700
	UNHANDLED_EXCEPTION

/* ---[ 0x800: External interrupt exception ]---------------------------- */
	.org 0x800
	UNHANDLED_EXCEPTION

/* ---[ 0x900: DTLB miss exception ]------------------------------------- */
	.org 0x900
	UNHANDLED_EXCEPTION
	
/* ---[ 0xa00: ITLB miss exception ]------------------------------------- */
	.org 0xa00
	UNHANDLED_EXCEPTION
	
		
/* ---[ 0xb00: Range exception ]----------------------------------------- */
	.org 0xb00
	UNHANDLED_EXCEPTION
	

/* ---[ 0xc00: Syscall exception ]--------------------------------------- */
	.org 0xc00
	UNHANDLED_EXCEPTION
	

/* ---[ 0xd00: Trap exception ]------------------------------------------ */
	.org 0xd00
	UNHANDLED_EXCEPTION
	

/* ---[ 0xe00: Trap exception ]------------------------------------------ */
	.org 0xe00
	UNHANDLED_EXCEPTION
	
	
/* ---[ 0xf00: Reserved exceptions ]------------------------------------- */
	.org 0xf00
	UNHANDLED_EXCEPTION
/*	
	.org 0x1000
	UNHANDLED_EXCEPTION
	
	.org 0x1100
	UNHANDLED_EXCEPTION
	
	.org 0x1200
	UNHANDLED_EXCEPTION
	
	.org 0x1300
	UNHANDLED_EXCEPTION
	
	.org 0x1400
	UNHANDLED_EXCEPTION
	
	.org 0x1500
	UNHANDLED_EXCEPTION
	
	.org 0x1600
	UNHANDLED_EXCEPTION
	
	.org 0x1700
	UNHANDLED_EXCEPTION
	
	.org 0x1800
	UNHANDLED_EXCEPTION
	
	.org 0x1900
	UNHANDLED_EXCEPTION
	
	.org 0x1a00
	UNHANDLED_EXCEPTION
	
	.org 0x1b00
	UNHANDLED_EXCEPTION
	
	.org 0x1c00
	UNHANDLED_EXCEPTION
	
	.org 0x1d00
	UNHANDLED_EXCEPTION
	
	.org 0x1e00
	UNHANDLED_EXCEPTION
	
	.org 0x1f00
	UNHANDLED_EXCEPTION
*/

/* ========================================================= [ entry ] === */
	.section .text

ENTRY(_start)

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

	/* Initialise stack */
/*	LOAD_SYMBOL_2_GPR(r1, _stack)
	l.addi  r2, r0, -3
	l.and   r1, r1, r2
*/	
	/* Clear BSS */
        LOAD_SYMBOL_2_GPR(r28, ___bss_start)
        LOAD_SYMBOL_2_GPR(r30, __end)
1:
        l.sw    (0)(r28), r0
        l.sfltu r28, r30
        l.bf    1b
        l.addi  r28, r28, 4


	/* Initialise UART in a C function */
	/*l.jal    _uart_init
	l.nop*/
        

	/* Jump to main program entry point (argc = argv = 0) */
	CLEAR_GPR(r3)
	CLEAR_GPR(r4)
	l.jal   _main
	l.nop
	
	/* If program exits, call exit routine */
	l.addi  r3, r11, 0
	l.jal   _exit
	l.nop


/* ====================================== [ default exception handler ] === */

default_exception_handler:
	l.sw    0x00(r1), r2
	l.sw    0x0c(r1), r5
	l.sw    0x10(r1), r6
	l.sw    0x14(r1), r7
	l.sw    0x18(r1), r8
	l.sw    0x1c(r1), r9
	l.sw    0x20(r1), r10
	l.sw    0x24(r1), r11
	l.sw    0x28(r1), r12
	l.sw    0x2c(r1), r13
	l.sw    0x30(r1), r14
	l.sw    0x34(r1), r15
	l.sw    0x38(r1), r16
	l.sw    0x3c(r1), r17
	l.sw    0x40(r1), r18
	l.sw    0x44(r1), r19
	l.sw    0x48(r1), r20
	l.sw    0x4c(r1), r21
	l.sw    0x50(r1), r22
	l.sw    0x54(r1), r23
	l.sw    0x58(r1), r24
	l.sw    0x5c(r1), r25
	l.sw    0x60(r1), r26
	l.sw    0x64(r1), r27
	l.sw    0x68(r1), r28
	l.sw    0x6c(r1), r29
	l.sw    0x70(r1), r30
	l.sw    0x74(r1), r31
	l.sw    0x78(r1), r32
	
	l.jal   _default_exception_handler_c
	l.nop
	
	l.lwz    r2, 0x00(r1)
	l.lwz    r3, 0x04(r1)
	l.lwz    r4, 0x08(r1)
	l.lwz    r5, 0x0c(r1)
	l.lwz    r6, 0x10(r1)
	l.lwz    r7, 0x14(r1)
	l.lwz    r8, 0x18(r1)
	l.lwz    r9, 0x1c(r1)
	l.lwz    r10, 0x20(r1)
	l.lwz    r11, 0x24(r1)
	l.lwz    r12, 0x28(r1)
	l.lwz    r13, 0x2c(r1)
	l.lwz    r14, 0x30(r1)
	l.lwz    r15, 0x34(r1)
	l.lwz    r16, 0x38(r1)
	l.lwz    r17, 0x3c(r1)
	l.lwz    r18, 0x40(r1)
	l.lwz    r19, 0x44(r1)
	l.lwz    r20, 0x48(r1)
	l.lwz    r21, 0x4c(r1)
	l.lwz    r22, 0x50(r1)
	l.lwz    r23, 0x54(r1)
	l.lwz    r24, 0x58(r1)
	l.lwz    r25, 0x5c(r1)
	l.lwz    r26, 0x60(r1)
	l.lwz    r27, 0x64(r1)
	l.lwz    r28, 0x68(r1)
	l.lwz    r29, 0x6c(r1)
	l.lwz    r30, 0x70(r1)
	l.lwz    r31, 0x74(r1)
	l.lwz    r32, 0x78(r1)

	l.addi  r1, r1, 128

	l.rfe
	l.nop

