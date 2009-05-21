/* Support file for c based tests */
#include "spr_defs.h"
#include "board.h"
#include "mc.h"

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


        .org    0x000
_buserr_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_buserr)
        l.ori   r10,r10,lo(_excpt_buserr)
        l.lwz   r10,0x0(r10)
        l.jr    r10
        l.nop

        .org    0x100
_dpfault_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
/* 
        l.mfspr r3,r0,SPR_EPCR_BASE
        l.addi  r3,r3,-4
        l.mtspr r0,r3,SPR_EPCR_BASE
*/
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_dpfault)
        l.ori   r10,r10,lo(_excpt_dpfault)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x200
_ipfault_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_ipfault)
        l.ori   r10,r10,lo(_excpt_ipfault)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x300
_lpint_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_tick)
        l.ori   r10,r10,lo(_excpt_tick)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x400
_align_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_align)
        l.ori   r10,r10,lo(_excpt_align)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x500
_illinsn_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_illinsn)
        l.ori   r10,r10,lo(_excpt_illinsn)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x600
_hpint_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_int)
        l.ori   r10,r10,lo(_excpt_int)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x700
_dtlbmiss_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
/*
        l.mfspr r3,r0,SPR_EPCR_BASE
        l.addi  r3,r3,-4
        l.mtspr r0,r3,SPR_EPCR_BASE
*/
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_dtlbmiss)
        l.ori   r10,r10,lo(_excpt_dtlbmiss)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x800
_itlbmiss_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_itlbmiss)
        l.ori   r10,r10,lo(_excpt_itlbmiss)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0x900
_range_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_range)
        l.ori   r10,r10,lo(_excpt_range)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0xa00
_syscall_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_syscall)
        l.ori   r10,r10,lo(_excpt_syscall)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0xb00
_break_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
        l.movhi r9,hi(end_except)
        l.ori   r9,r9,lo(end_except)
        l.movhi r10,hi(_excpt_break)
        l.ori   r10,r10,lo(_excpt_break)
        l.lwz   r10,0(r10)
        l.jr    r10
        l.nop

        .org    0xc00
_trap_vector:
        l.addi  r1,r1,-116
        l.sw    0x18(r1),r9
        l.jal   store_regs
        l.nop
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
        l.rfe
        l.nop 
