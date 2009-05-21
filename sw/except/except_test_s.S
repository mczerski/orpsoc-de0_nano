/* Support file for c based tests */

#include "spr_defs.h"
#include "board.h"
#include "mc.h"

        .global _except_basic
        .global _lo_dmmu_en
        .global _lo_immu_en
        .global _call
        .global _call_with_int
        .global _load_acc_32
        .global _load_acc_16
        .global _store_acc_32
        .global _store_acc_16
        .global _load_b_acc_32
        .global _trap
        .global _b_trap
        .global _range
        .global _b_range
        .global _int_trigger
        .global _int_loop
        .global _jump_back

	.section .vectors, "ax"
        .extern _reset_support
        .extern _c_reset
        .extern _excpt_buserr
        .extern _excpt_dpfault
        .extern _excpt_ipfault
        .extern _excpt_tick
        .extern _excpt_align
        .extern _excpt_illinsn
        .extern _excpt_int
        .extern _excpt_dtlbmiss
        .extern _excpt_itlbmiss
        .extern _excpt_range
        .extern _excpt_syscall
        .extern _excpt_break
        .extern _excpt_trap

	// Assuming .vectors is defined from 0x200 in the linker script
        .org    0x000
_buserr_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_buserr)
        l.ori   r10,r10,lo(_excpt_buserr)
        l.lwz   r10,0x0(r10)
        l.jr    r10
        l.nop

        .org    0x100
_dpfault_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_dpfault)
        l.ori   r10,r10,lo(_excpt_dpfault)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x200
_ipfault_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_ipfault)
        l.ori   r10,r10,lo(_excpt_ipfault)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x300
_tick_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_tick)
        l.ori   r10,r10,lo(_excpt_tick)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x400
_align_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_align)
        l.ori   r10,r10,lo(_excpt_align)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x500
_illinsn_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_illinsn)
        l.ori   r10,r10,lo(_excpt_illinsn)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x600
_int_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_int)
        l.ori   r10,r10,lo(_excpt_int)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x700
_dtlbmiss_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_dtlbmiss)
        l.ori   r10,r10,lo(_excpt_dtlbmiss)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x800
_itlbmiss_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_itlbmiss)
        l.ori   r10,r10,lo(_excpt_itlbmiss)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x900
_range_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_range)
        l.ori   r10,r10,lo(_excpt_range)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0xa00
_syscall_vector:
	l.nop
        l.addi  r3,r3,4

        l.mfspr r4,r0,SPR_SR
        l.andi  r4,r4,7
        l.add   r6,r0,r4
        
        l.mfspr r4,r0,SPR_EPCR_BASE
        l.movhi r5,hi(_sys1)
        l.ori r5,r5,lo(_sys1)
        l.sub r5,r4,r5
        
        l.mfspr r4,r0,SPR_ESR_BASE  /* ESR - set supvisor mode */
        l.ori r4,r4,SPR_SR_SM
        l.mtspr r0,r4,SPR_ESR_BASE  
        
        l.movhi r4,hi(_sys2)
        l.ori r4,r4,lo(_sys2)
        l.mtspr r0,r4,SPR_EPCR_BASE
        
        l.rfe
        l.addi  r3,r3,8

        .org    0xb00
_break_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_break)
        l.ori   r10,r10,lo(_excpt_break)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0xc00
_trap_vector:
	l.nop
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop

        l.mfspr r3,r0,SPR_EPCR_BASE
        l.movhi r4,hi(_except_pc)
        l.ori   r4,r4,lo(_except_pc)
        l.sw    0(r4),r3

        l.mfspr r3,r0,SPR_EEAR_BASE
        l.movhi r4,hi(_except_ea)
        l.ori   r4,r4,lo(_except_ea)
        l.sw    0(r4),r3

        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_trap)
        l.ori   r10,r10,lo(_excpt_trap)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

store_regs:
        l.sw    0x00(r1),r3
        l.sw    0x04(r1),r4
        l.sw    0x08(r1),r5
        l.sw    0x0c(r1),r6
        l.sw    0x10(r1),r7
        l.sw    0x14(r1),r8
        l.sw    0x1c(r1),r10
        l.sw    0x20(r1),r11
        l.sw    0x24(r1),r12
        l.sw    0x28(r1),r13
        l.sw    0x2c(r1),r14
        l.sw    0x30(r1),r15
        l.sw    0x34(r1),r16
        l.sw    0x38(r1),r17
        l.sw    0x3c(r1),r18
        l.sw    0x40(r1),r19
        l.sw    0x44(r1),r20
        l.sw    0x48(r1),r21
        l.sw    0x4c(r1),r22
        l.sw    0x50(r1),r23
        l.sw    0x54(r1),r24
        l.sw    0x58(r1),r25
        l.sw    0x5c(r1),r26
        l.sw    0x60(r1),r27
        l.sw    0x64(r1),r28
        l.sw    0x68(r1),r29
        l.sw    0x6c(r1),r30
        l.sw    0x70(r1),r31
        l.jr    r9
        l.nop

end_except:
        l.lwz   r3,0x00(r1)
        l.lwz   r4,0x04(r1)
        l.lwz   r5,0x08(r1)
        l.lwz   r6,0x0c(r1)
        l.lwz   r7,0x10(r1)
        l.lwz   r8,0x14(r1)
        l.lwz   r9,0x18(r1)
        l.lwz   r10,0x1c(r1)
        l.lwz   r11,0x20(r1)
        l.lwz   r12,0x24(r1)
        l.lwz   r13,0x28(r1)
        l.lwz   r14,0x2c(r1)
        l.lwz   r15,0x30(r1)
        l.lwz   r16,0x34(r1)
        l.lwz   r17,0x38(r1)
        l.lwz   r18,0x3c(r1)
        l.lwz   r19,0x40(r1)
        l.lwz   r20,0x44(r1)
        l.lwz   r21,0x48(r1)
        l.lwz   r22,0x4c(r1)
        l.lwz   r23,0x50(r1)
        l.lwz   r24,0x54(r1)
        l.lwz   r25,0x58(r1)
        l.lwz   r26,0x5c(r1)
        l.lwz   r27,0x60(r1)
        l.lwz   r28,0x64(r1)
        l.lwz   r29,0x68(r1)
        l.lwz   r30,0x6c(r1)
        l.lwz   r31,0x70(r1)
        l.addi  r1,r1,116
        l.mtspr r0,r9,SPR_EPCR_BASE
        l.rfe
        l.nop 

  .section .text

_except_basic:
_sys1:
        l.addi  r3,r0,-2  /* Enable exceptiom recognition and external interrupt,set user mode */
        l.mfspr r4,r0,SPR_SR
        l.and   r4,r4,r3
        l.ori   r4,r4,(SPR_SR_IEE|SPR_SR_TEE)
        l.mtspr r0,r4,SPR_SR
        
        l.addi  r3,r0,0
        l.sys   1
        l.addi  r3,r3,2

_sys2:
        l.addi  r11,r0,0
        
        l.mfspr r4,r0,SPR_SR  /* Check SR */
        l.andi  r4,r4,(SPR_SR_IEE|SPR_SR_TEE|SPR_SR_SM)
        l.sfeqi r4,(SPR_SR_IEE|SPR_SR_TEE|SPR_SR_SM)
        l.bf    1f
        l.nop
        l.addi  r11,r11,1
1:
        l.sfeqi r3,4          /* Check if l.sys or l.rfe has delay slot */
        l.bf    1f
        l.nop
        l.addi  r11,r11,2
1:
        l.sfeqi r5,0x1c       /* Check the EPCR */
        l.bf    1f
        l.nop
        l.addi  r11,r11,4
1:
        l.sfeqi r6,SPR_SR_SM  /* Check the SR when exception is taken */
        l.bf    1f
        l.nop
        l.addi  r11,r11,8
1:
        l.jr    r9
        l.nop

_lo_dmmu_en:
        l.mfspr r3,r0,SPR_SR
        l.ori   r3,r3,SPR_SR_DME
        l.mtspr r0,r3,SPR_ESR_BASE
        l.mtspr r0,r9,SPR_EPCR_BASE
        l.rfe
        l.nop
  
_lo_immu_en:
        l.mfspr r3,r0,SPR_SR
        l.ori   r3,r3,SPR_SR_IME
        l.mtspr r0,r3,SPR_ESR_BASE
        l.mtspr r0,r9,SPR_EPCR_BASE
        l.rfe
        l.nop
 
_call:
        l.addi  r11,r0,0
        l.jr    r3
        l.nop

_call_with_int:
        l.mfspr r8,r0,SPR_SR
        l.ori   r8,r8,SPR_SR_TEE
        l.mtspr r0,r8,SPR_ESR_BASE
        l.mtspr r0,r3,SPR_EPCR_BASE
        l.rfe

_load_acc_32:
        l.movhi r11,hi(0x12345678)
        l.ori   r11,r11,lo(0x12345678)
        l.lwz   r11,0(r4)
        l.jr    r9
        l.nop

_load_acc_16:
        l.movhi r11,hi(0x12345678)
        l.ori   r11,r11,lo(0x12345678)
        l.lhz   r11,0(r4)
        l.jr    r9
        l.nop

_store_acc_32:
        l.movhi r3,hi(0x12345678)
        l.ori   r3,r3,lo(0x12345678)
        l.sw    0(r4),r3
        l.jr    r9
        l.nop

_store_acc_16:
        l.movhi r3,hi(0x12345678)
        l.ori   r3,r3,lo(0x12345678)
        l.sh    0(r4),r3
        l.jr    r9
        l.nop

_load_b_acc_32:
        l.movhi r11,hi(0x12345678)
        l.ori   r11,r11,lo(0x12345678)
        l.jr    r9
        l.lwz   r11,0(r4)

_b_trap:
        l.jr    r9
_trap: 
        l.trap  1
        l.jr    r9
        l.nop

_b_range:
        l.jr    r9
_range: 
        l.addi  r3,r0,-1
        l.jr    r9
        l.nop

_int_trigger:
        l.addi  r11,r0,0
        l.mfspr r3,r0,SPR_SR
        l.ori   r3,r3,SPR_SR_TEE
        l.mtspr r0,r3,SPR_SR
        l.addi  r11,r11,1

_int_loop:
        l.j     _int_loop
        l.lwz   r5,0(r4);

_jump_back:
        l.addi  r11,r0,0
        l.jr    r9
        l.addi  r11,r11,1

