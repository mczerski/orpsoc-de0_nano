#include "spr_defs.h"

/* Defines and macros to help us handle execptions */
#define INT_FRAME_SIZE 144

#include "or32_funcs.S"



#define EXCEPTION_HANDLE(handler) \
	/* First store the SP like it was before execption to a temporary location, we use addr 0x80 */  ;\
	l.sw 	0x80(r0), r1		                        ;\
	l.addi  r1,r1,-(INT_FRAME_SIZE)				;\
        l.sw    GPR12(r1),r12					;\
	l.mfspr r12,r0,SPR_EPCR_BASE				;\
        l.sw    PC(r1),r12					;\
        l.mfspr r12,r0,SPR_ESR_BASE				;\
        l.sw    SR(r1),r12					;\
	l.lwz   r12, 0x80(r0)					;\
	/* Now store the previous SP onto except. stack*/       ;\
	l.sw	SP(r1),r12					;\
	/* save exception r4, set r4 = EA */			;\
	l.sw	GPR4(r1),r4					;\
	l.mfspr r4,r0,SPR_EEAR_BASE				;\
	/* r31:	EA address of handler */			;\
	LOAD_SYMBOL_2_GPR(r12,handler)				;\
	l.mtspr r0,r12,SPR_EPCR_BASE				;\
	l.rfe							;\
	l.nop

	
#define HANDLER_ENTRY(handler)				\
	.global	handler						;\
handler:							;\
        l.sw    GPR2(r1),r2					;\
        l.sw    GPR3(r1),r3					;\
	/*l.sw    GPR4(r1),r4*/					;\
        l.sw    GPR5(r1),r5					;\
        l.sw    GPR6(r1),r6					;\
        l.sw    GPR7(r1),r7					;\
        l.sw    GPR8(r1),r8					;\
        l.sw    GPR9(r1),r9					;\
        l.sw    GPR10(r1),r10					;\
        l.sw    GPR11(r1),r11					;\
        /*l.sw    GPR12(r1),r12*/				;\
        l.sw    GPR13(r1),r13					;\
        l.sw    GPR14(r1),r14					;\
        l.sw    GPR15(r1),r15					;\
        l.sw    GPR16(r1),r16					;\
        l.sw    GPR17(r1),r17					;\
        l.sw    GPR18(r1),r18					;\
        l.sw    GPR19(r1),r19					;\
        l.sw    GPR20(r1),r20					;\
        l.sw    GPR21(r1),r21					;\
        l.sw    GPR22(r1),r22					;\
        l.sw    GPR23(r1),r23					;\
        l.sw    GPR24(r1),r24					;\
        l.sw    GPR25(r1),r25					;\
        l.sw    GPR26(r1),r26					;\
        l.sw    GPR27(r1),r27					;\
        l.sw    GPR28(r1),r28					;\
        l.sw    GPR29(r1),r29					;\
        l.sw    GPR30(r1),r30					;\
        l.sw    GPR31(r1),r31					;\
        l.sw    RESULT(r1),r0					;\

/*
 * We need to disable interrupts at beginning of RESTORE_ALL
 * since interrupt might come in after we've loaded EPC return address
 * and overwrite EPC with address somewhere in RESTORE_ALL
 * which is of course wrong!
 */
	
#define RESTORE_ALL						\
	DISABLE_INTERRUPTS(r3,r4)				;\
	l.lwz   r3,PC(r1)					;\
        l.mtspr r0,r3,SPR_EPCR_BASE				;\
        l.lwz   r3,SR(r1)					;\
        l.mtspr r0,r3,SPR_ESR_BASE				;\
        l.lwz   r2,GPR2(r1)					;\
        l.lwz   r3,GPR3(r1)					;\
        l.lwz   r4,GPR4(r1)					;\
        l.lwz   r5,GPR5(r1)					;\
        l.lwz   r6,GPR6(r1)					;\
        l.lwz   r7,GPR7(r1)					;\
        l.lwz   r8,GPR8(r1)					;\
        l.lwz   r9,GPR9(r1)					;\
        l.lwz   r10,GPR10(r1)					;\
        l.lwz   r11,GPR11(r1)					;\
        l.lwz   r12,GPR12(r1)					;\
        l.lwz   r13,GPR13(r1)					;\
        l.lwz   r14,GPR14(r1)					;\
        l.lwz   r15,GPR15(r1)					;\
        l.lwz   r16,GPR16(r1)					;\
        l.lwz   r17,GPR17(r1)					;\
        l.lwz   r18,GPR18(r1)					;\
        l.lwz   r19,GPR19(r1)					;\
        l.lwz   r20,GPR20(r1)					;\
        l.lwz   r21,GPR21(r1)					;\
        l.lwz   r22,GPR22(r1)					;\
        l.lwz   r23,GPR23(r1)					;\
        l.lwz   r24,GPR24(r1)					;\
        l.lwz   r25,GPR25(r1)					;\
        l.lwz   r26,GPR26(r1)					;\
        l.lwz   r27,GPR27(r1)					;\
        l.lwz   r28,GPR28(r1)					;\
        l.lwz   r29,GPR29(r1)					;\
        l.lwz   r30,GPR30(r1)					;\
        l.lwz   r31,GPR31(r1)					;\
        l.lwz   r1,SP(r1)					;\
	l.rfe
	
	
// Linked from 0x200, so add 0x200 to the .org for the physical address
.section .vectors, "ax" 

/*
.org 0x100
 
_reset:
	l.nop
	l.j	_reset_except
	l.nop
*/
.org 0x000
 
_except_200:
	l.nop
	l.j	_buserr_except
	l.nop

.org 0x100
 
_except_300:
	l.nop
	l.j	_dpf_except
	l.nop

.org 0x200
 
_except_400:
	l.nop
	l.j	_ipf_except
	l.nop

.org 0x300

_except_500:	
#if 0
	l.nop
	l.j	_lpint_except
	l.nop
#else
	/* First unset the timer interrupt bit */
	l.addi  r1,r1,-8	
	l.sw 0(r1),r31 		
	l.sw 4(r1),r30 		
	l.mfspr r31,r0,SPR_TTMR	 /* want to clear SPR_TTMR_IP bit from this reg*/
	l.movhi r30,hi(SPR_TTMR_IP) 
	l.ori r30,r30,lo(SPR_TTMR_IP) 
	l.xor r31, r31, r30	      
	l.mtspr r0,r31,SPR_TTMR	      
	l.lwz r31,0(r1)		      
	l.lwz r30,4(r1)		      
	l.addi r1, r1, 8	      
	EXCEPTION_HANDLE(_timer_handler)	
#endif	

.org 0x400
 
_except_600:
	l.nop
	l.j	_align_except
	l.nop

.org 0x500
 
_except_700:
	l.nop
	l.j	_illegal_except
	l.nop

.org 0x600
 
_except_800:
	l.nop
	l.j	_hpint_except
	l.nop

.org 0x700
 
_except_900:
	l.nop
	l.j	_dtlbmiss_except
	l.nop

.org 0x800
 
_except_a00:
	l.nop
	l.j	_itlbmiss_except
	l.nop

.org 0x900
 
_except_b00:
	l.nop
	l.j	_range_except
	l.nop

.org 0xa00
 
_except_c00:
	l.nop
/*	l.j	_syscall_except*/
	EXCEPTION_HANDLE(_syscall_handler)	
	l.nop

.org 0xb00
 
_except_d00:
	l.nop
	l.j	_fpu_except
	l.nop

.org 0xc00
 
_except_e00:
	l.nop
	l.j	_trap_except
	l.nop

.org 0xd00
 
_except_f00:
	l.nop
	l.j	_res2_except
	l.nop

.section .text, "ax" 

/* ---[ 0x500: Timer exception ]----------------------------------------- */
	HANDLER_ENTRY(_timer_handler)
	l.addi r3,r1,0
	LOAD_SYMBOL_2_GPR(r8,_timer_interrupt)
        l.jalr r8
	l.nop
	l.j    _ret_from_intr
	l.nop
	
/* ---[ End of Timer exception ]----------------------------------------- */
/* ---[ 0xC00: syscall exception ]--------------------------------------- */
	HANDLER_ENTRY(_syscall_handler)
	/* r4 holds the EEAR address of the fault, load the original r4 */
	l.lwz	r4,GPR4(r1)
	ENABLE_INTERRUPTS(r9)		// enable interrupts, r9 is temp

	/*	LOAD_SYMBOL_2_GPR(r30,_syscall_interrupt)*/
	/* For now we ONLY do write syscall, number 4 */
	l.sfnei r11,4
	l.bf _syscall_finish
	l.nop

	LOAD_SYMBOL_2_GPR(r30,_sys_write)	
        l.jalr r30
	l.addi  r8,r1,0                 // regs pointer
_syscall_finish:	
	l.sw    GPR11(r1),r11           // save return value
        l.sw    RESULT(r1),r11          // save result

	DISABLE_INTERRUPTS(r3,r4)
	
	l.j    _ret_from_intr
	l.nop
/* ---[ End of syscall exception ]--------------------------------------- */	

ENTRY(_ret_from_intr)
	l.addi  r4,r1,INT_FRAME_SIZE
	RESTORE_ALL
/*	
	// i386 version:	
	// GET_CURRENT(%ebx)

ENTRY(_ret_from_exception)
	l.lwz	r4,SR(r1)
        l.andi	r3,r4,SPR_SR_SM
        l.sfeqi	r3,0
        l.bnf	_restore_all
	l.nop

ENTRY(_restore_all)
	// we need to save KSP here too
	// or else fork's 'eat' stack space
	l.addi  r4,r1,INT_FRAME_SIZE
        l.sw    (TI_KSP)(r10),r4
	RESTORE_ALL
*/
