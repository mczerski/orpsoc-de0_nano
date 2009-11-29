/* Basic instruction set test */
#include "../support/spr_defs.h"

.global _main
.global _buserr_except
.global _dpf_except
.global _ipf_except
.global _lpint_except
.global _align_except
.global _illegal_except
.global _hpint_except
.global _dtlbmiss_except
.global _itlbmiss_except
.global _range_except
.global _syscall_except
.global _fpu_except
.global _trap_except
.global _res2_except


        .section .stack
        .space 0x1000
_tmp_stack:



  .section .text

_buserr_except:
_dpf_except:
_ipf_except:
_lpint_except:
_align_except:
_illegal_except:
_hpint_except:
_dtlbmiss_except:
_itlbmiss_except:
_range_except:
_syscall_except:
_fpu_except:
_trap_except:
_res2_except:

_main:
	l.nop
	l.j	_regs
	l.nop
	
_regs:
	l.addi	r1,r0,0x1
	l.addi	r2,r1,0x2
	l.addi	r3,r2,0x4
	l.addi	r4,r3,0x8
	l.addi	r5,r4,0x10
	l.addi	r6,r5,0x20
	l.addi	r7,r6,0x40
	l.addi	r8,r7,0x80
	l.addi	r9,r8,0x100
	l.addi	r10,r9,0x200
	l.addi	r11,r10,0x400
	l.addi	r12,r11,0x800
	l.addi	r13,r12,0x1000
	l.addi	r14,r13,0x2000
	l.addi	r15,r14,0x4000
	l.addi	r16,r15,0x8000

	l.sub	r31,r0,r1
	l.sub	r30,r31,r2
	l.sub	r29,r30,r3
	l.sub	r28,r29,r4
	l.sub	r27,r28,r5
	l.sub	r26,r27,r6
	l.sub	r25,r26,r7
	l.sub	r24,r25,r8
	l.sub	r23,r24,r9
	l.sub	r22,r23,r10
	l.sub	r21,r22,r11
	l.sub	r20,r21,r12
	l.sub	r19,r20,r13
	l.sub	r18,r19,r14
	l.sub	r17,r18,r15
	l.sub	r16,r17,r16
	l.movhi r31,0x0000
	l.ori	r31,r31,0x0040

	l.mtspr	r0,r16,0x1234	/* Should be 0xffff0012 */

	l.sw	0(r31),r16

_mem:	l.movhi	r3,0x1234
	l.ori	r3,r3,0x5678

	l.sw	4(r31),r3

	l.lbz	r4,4(r31)
	l.add	r8,r8,r4
	l.sb	11(r31),r4
	l.lbz	r4,5(r31)
	l.add	r8,r8,r4
	l.sb	10(r31),r4
	l.lbz	r4,6(r31)
	l.add	r8,r8,r4
	l.sb	9(r31),r4
	l.lbz	r4,7(r31)
	l.add	r8,r8,r4
	l.sb	8(r31),r4

	l.lbs   r4,8(r31)
        l.add   r8,r8,r4
        l.sb    7(r31),r4
        l.lbs   r4,9(r31)
        l.add   r8,r8,r4
        l.sb    6(r31),r4
        l.lbs   r4,10(r31)
        l.add   r8,r8,r4
        l.sb    5(r31),r4
        l.lbs   r4,11(r31)
        l.add   r8,r8,r4
        l.sb    4(r31),r4
	
	l.lhz   r4,4(r31)
        l.add   r8,r8,r4
        l.sh    10(r31),r4
        l.lhz   r4,6(r31)
        l.add   r8,r8,r4
        l.sh    8(r31),r4

	l.lhs   r4,8(r31)
        l.add   r8,r8,r4
        l.sh    6(r31),r4
        l.lhs   r4,10(r31)
        l.add   r8,r8,r4
        l.sh    4(r31),r4

	l.lwz	r4,4(r31)
	l.add   r8,r8,r4

	l.mtspr r0,r8,0x1234   /* Should be 0x12352af7 */

	l.lwz	r9,0(r31)
	l.add	r8,r9,r8
	l.sw	0(r31),r8
	
_arith:
	l.addi	r3,r0,1
	l.addi	r4,r0,2
	l.addi	r5,r0,-1
	l.addi	r6,r0,-1
	l.addi	r8,r0,0
	
	l.sub	r7,r5,r3
	l.sub	r8,r3,r5
	l.add	r8,r8,r7
	
#	l.div	r7,r7,r4
	l.add	r9,r3,r4
	l.mul	r7,r9,r7
#	l.divu	r7,r7,r4
	l.add	r8,r8,r7

	l.mtspr r0,r8,0x1234   /* Should be 0x7ffffffe */

	l.lwz	r9,0(r31)
	l.add	r8,r9,r8
	l.sw	0(r31),r8
	
_log:
	l.addi  r3,r0,1
        l.addi  r4,r0,2
        l.addi	r5,r0,-1
        l.addi	r6,r0,-1
        l.addi	r8,r0,0 

	l.andi	r8,r8,1
	l.and	r8,r8,r3

	l.xori	r8,r5,0xa5a5
	l.xor	r8,r8,r5

	l.ori	r8,r8,2
	l.or	r8,r8,r4

	l.mtspr r0,r8,0x1234   /* Should be 0xffffa5a7 */

	l.lwz	r9,0(r31)
	l.add	r8,r9,r8
	l.sw	0(r31),r8

_shift:
	l.addi  r3,r0,1
        l.addi  r4,r0,2
        l.addi  r5,r0,-1
        l.addi  r6,r0,-1
        l.addi  r8,r0,0

	l.slli	r8,r5,6
	l.sll	r8,r8,r4
	
	l.srli	r8,r8,6
	l.srl	r8,r8,r4
	
	l.srai	r8,r8,2
	l.sra	r8,r8,r4	

	l.mtspr r0,r8,0x1234   /* Should be 0x000fffff */

	l.lwz	r9,0(r31)
	l.add	r8,r9,r8
	l.sw	0(r31),r8
	
_flag:
	l.addi  r3,r0,1
        l.addi  r4,r0,-2
        l.addi  r8,r0,0

	l.sfeq	r3,r3
	l.mfspr	r5,r0,17
	l.andi	r4,r5,0x200
	l.add	r8,r8,r4

	l.sfeq  r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfeqi r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfeqi r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4 
	
	l.sfne  r3,r3
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfne  r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4 

	l.sfnei r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfnei r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfgtu r3,r3
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfgtu r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfgtui 	r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfgtui	r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfgeu r3,r3
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfgeu r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfgeui        r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfgeui        r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfltu r3,r3
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfltu r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfltui        r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfltui        r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfleu r3,r3
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfleu r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfleui        r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfleui        r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfgts r3,r3
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfgts r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfgtsi        r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfgtsi        r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfges r3,r3
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfges r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfgesi        r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfgesi        r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sflts r3,r3
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sflts r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfltsi        r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfltsi        r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.sfles r3,r3
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sfles r3,r4
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sflesi        r3,1
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4
 
        l.sflesi        r3,-2
        l.mfspr r5,r0,17
        l.andi  r4,r5,0x200
        l.add   r8,r8,r4

	l.mtspr r0,r8,0x1234   /* Should be 0x00002800 */

	l.lwz	r9,0(r31)
	l.add	r8,r9,r8
	l.sw	0(r31),r8

_jump:
	l.addi	r8,r0,0

	l.j	_T1
	l.addi	r8,r8,1

_T2:	l.or	r10,r0,r9
	l.jalr	r10
	l.addi	r8,r8,1

_T1:	l.jal	_T2
	l.addi	r8,r8,1

	l.sfeqi	r0,0
	l.bf	_T3
	l.addi	r8,r8,1

_T3:	l.sfeqi	r0,1
	l.bf	_T4
	l.addi	r8,r8,1
	
	l.addi	r8,r8,1

_T4:	l.sfeqi r0,0
        l.bnf    _T5
        l.addi  r8,r8,1

	l.addi	r8,r8,1

_T5:	l.sfeqi r0,1
        l.bnf    _T6
        l.addi  r8,r8,1
 
        l.addi  r8,r8,1

_T6:	l.movhi r3,hi(_T7)
        l.ori  r3,r3,lo(_T7)
	l.mtspr r0,r3,32
	l.mfspr r5,r0,17
	l.mtspr r0,r5,64
	l.rfe
	l.addi  r8,r8,1

	l.addi  r8,r8,1

_T7:	l.mtspr r0,r8,0x1234   /* Should be 0x00000000a */

	l.lwz	r9,0(r31)
	l.add	r8,r9,r8
	l.sw	0(r31),r8

	l.lwz	r9,0(r31)
	l.movhi	r3,0xcc69
	l.ori	r3,r3,0xe5fb
	l.add	r3,r8,r3	/* Should be 0xdeaddead */

	/* and where is stack supposed to be ??? */
	l.movhi r1,hi(_tmp_stack)
	l.ori	r1,r1,lo(_tmp_stack)
	l.jal	_report

	l.nop
	l.jal	_or32_exit
	l.nop
	l.nop

