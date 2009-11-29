/* Floating point instruction set test  (single precision only)*/
	
#include "../support/spr_defs.h"

#define REPORT_REG(reg) \
	l.or r3, reg, reg 	;\
	l.movhi r1,hi(_tmp_stack) ;\
	l.ori	r1,r1,lo(_tmp_stack) ;\
	l.jal	_report		     ;\
	l.nop

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
_trap_except:
_res2_except:


_fpu_except:
	l.mfspr r10, r0, SPR_FPCSR
	REPORT_REG(r10)
	l.sw 0(r0), r10
	l.addi r10, r0, 0x6
	l.ori r10, r0, SPR_FPCSR_FPEE
	l.mtspr r0, r10, SPR_FPCSR
	l.rfe
	l.nop

_main:
	l.nop	
	l.j	_fpu
	l.nop

_fpu:
	l.addi r10, r0, 0x6
	l.mtspr r0, r10, SPR_FPCSR
	l.nop
	
_itof:
	l.addi r5,r0, 0x468
	lf.itof.s r6, r5
	REPORT_REG(r6)	
	l.addi r5,r0, 0x1431
	lf.itof.s r7, r5
	REPORT_REG(r7)

_ftoi:
	l.movhi r6, hi(0x44500F2B) /* decimal 832.237 */
	l.ori r6, r6, lo(0x44500F2B)
	lf.ftoi.s r5, r6
	REPORT_REG(r5)
	l.movhi r7, hi(0xC44547E1) /* decimal -789.1231 */
	l.ori r7, r7, lo(0xC44547E1)
	lf.ftoi.s r5, r7
	REPORT_REG(r5)
	
_add:
	lf.add.s r8, r6, r7
	REPORT_REG(r8)
_sub:
	lf.sub.s r8, r6, r7
	REPORT_REG(r8)
_div:
	lf.div.s r8, r6, r7
	REPORT_REG(r8)
_mul:
	lf.mul.s r8, r6, r7
	REPORT_REG(r8)

_cmp_eq:
	l.movhi r6, hi(0x39B9C157) /* decimal 3.543E-4 */
	l.ori r6, r6, lo(0x39B9C157)
	l.movhi r7, hi(0x39BA1F4B) /* decimal 3.55E-4 */
	l.ori r7, r7, lo(0x39BA1F4B)
	lf.sfeq.s r6, r7
	l.bf _finish
	l.ori r3, r0, 1

	l.movhi r6, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r6, r6, lo(0x42B1C71C)
	l.movhi r7, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r7, r7, lo(0x42B1C71C)
	lf.sfeq.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 1


	l.movhi r6, hi(0xCA8325AB) /* decimal -4297429.5 */
	l.ori r6, r6, lo(0xCA8325AB)
	l.movhi r7, hi(0x4A8325AB) /* decimal  4297429.5*/
	l.ori r7, r7, lo(0x4A8325AB)
	lf.sfeq.s r6, r7
	l.bf _finish
	l.ori r3, r0, 1

_cmp_neq:
	l.movhi r6, hi(0x39B9C157) /* decimal 3.543E-4 */
	l.ori r6, r6, lo(0x39B9C157)
	l.movhi r7, hi(0x39BA1F4B) /* decimal 3.55E-4 */
	l.ori r7, r7, lo(0x39BA1F4B)
	lf.sfne.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 2

	l.movhi r6, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r6, r6, lo(0x42B1C71C)
	l.movhi r7, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r7, r7, lo(0x42B1C71C)
	lf.sfne.s r6, r7
	l.bf _finish
	l.ori r3, r0, 2

	l.movhi r6, hi(0xCA8325AB) /* decimal -4297429.5 */
	l.ori r6, r6, lo(0xCA8325AB)
	l.movhi r7, hi(0x4A8325AB) /* decimal  4297429.5*/
	l.ori r7, r7, lo(0x4A8325AB)
	lf.sfne.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 2


_cmp_gt:

	l.movhi r6, hi(0x39B9C157) /* decimal 3.543E-4 */
	l.ori r6, r6, lo(0x39B9C157)
	l.movhi r7, hi(0x39BA1F4B) /* decimal 3.55E-4 */
	l.ori r7, r7, lo(0x39BA1F4B)

	lf.sfgt.s r6, r7
	l.bf _finish
	l.ori r3, r0, 3
	

	l.movhi r6, hi(0x474C763C) /* decimal 52342.234 */
	l.ori r6, r6, lo(0x474C763C)
	l.movhi r7, hi(0x33137F6E) /* decimal 3.4342E-8 */
	l.ori r7, r7, lo(0x33137F6E)

	lf.sfgt.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 3

	lf.sfgt.s r7, r6
	l.bf _finish
	l.ori r3, r0, 3


	l.movhi r6, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r6, r6, lo(0x42B1C71C)
	l.movhi r7, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r7, r7, lo(0x42B1C71C)
	lf.sfgt.s r6, r7
	l.bf _finish
	l.ori r3, r0, 3

	l.movhi r6, hi(0xCA8325AB) /* decimal -4297429.5 */
	l.ori r6, r6, lo(0xCA8325AB)
	l.movhi r7, hi(0x4A8325AB) /* decimal  4297429.5*/
	l.ori r7, r7, lo(0x4A8325AB)
	lf.sfgt.s r6, r7
	l.bf _finish
	l.ori r3, r0, 3

	lf.sfgt.s r7, r6
	l.bnf _finish
	l.ori r3, r0, 3


_cmp_ge:

	/*This fails?!*/
	l.movhi r6, hi(0x39B9C157) /* decimal 3.543E-4 */
	l.ori r6, r6, lo(0x39B9C157)
	l.movhi r7, hi(0x39BA1F4B) /* decimal 3.55E-4 */
	l.ori r7, r7, lo(0x39BA1F4B)
	lf.sfge.s r7, r6
	l.bnf _finish
	l.ori r3, r0, 4

	lf.sfge.s r6, r7
	l.bf _finish
	l.ori r3, r0, 4

	l.movhi r6, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r6, r6, lo(0x42B1C71C)
	l.movhi r7, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r7, r7, lo(0x42B1C71C)
	lf.sfge.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 4

	l.movhi r6, hi(0xCA8325AB) /* decimal -4297429.5 */
	l.ori r6, r6, lo(0xCA8325AB)
	l.movhi r7, hi(0x4A8325AB) /* decimal  4297429.5*/
	l.ori r7, r7, lo(0x4A8325AB)
	lf.sfge.s r6, r7
	l.bf _finish
	l.ori r3, r0, 4

	lf.sfge.s r7, r6
	l.bnf _finish
	l.ori r3, r0, 4



_cmp_lt:
	l.movhi r6, hi(0x39B9C157) /* decimal 3.543E-4 */
	l.ori r6, r6, lo(0x39B9C157)
	l.movhi r7, hi(0x39BA1F4B) /* decimal 3.55E-4 */
	l.ori r7, r7, lo(0x39BA1F4B)
	lf.sflt.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 5

	l.movhi r6, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r6, r6, lo(0x42B1C71C)
	l.movhi r7, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r7, r7, lo(0x42B1C71C)
	lf.sflt.s r6, r7
	l.bf _finish
	l.ori r3, r0, 5
	
	l.movhi r6, hi(0xCA8325AB) /* decimal -4297429.5 */
	l.ori r6, r6, lo(0xCA8325AB)
	l.movhi r7, hi(0x4A8325AB) /* decimal  4297429.5*/
	l.ori r7, r7, lo(0x4A8325AB)
	lf.sflt.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 5

	lf.sflt.s r7, r6
	l.bf _finish
	l.ori r3, r0, 5

_cmp_le:

	l.movhi r6, hi(0x39B9C157) /* decimal 3.543E-4 */
	l.ori r6, r6, lo(0x39B9C157)
	l.movhi r7, hi(0x39BA1F4B) /* decimal 3.55E-4 */
	l.ori r7, r7, lo(0x39BA1F4B)
	lf.sfle.s r7, r6
	l.bf _finish
	l.ori r3, r0, 6

	lf.sfle.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 6

	l.movhi r6, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r6, r6, lo(0x42B1C71C)
	l.movhi r7, hi(0x42B1C71C) /* decimal 88.888885 */
	l.ori r7, r7, lo(0x42B1C71C)
	lf.sfle.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 6

	l.movhi r6, hi(0xCA8325AB) /* decimal -4297429.5 */
	l.ori r6, r6, lo(0xCA8325AB)
	l.movhi r7, hi(0x4A8325AB) /* decimal  4297429.5*/
	l.ori r7, r7, lo(0x4A8325AB)
	lf.sfle.s r6, r7
	l.bnf _finish
	l.ori r3, r0, 6

	lf.sfle.s r7, r6
	l.bf _finish
	l.ori r3, r0, 6


excpt_test:
	l.addi r10, r0, 0x6
	/* Now set the exception generation bit */
	l.ori r10, r0, SPR_FPCSR_FPEE
	l.mtspr r0, r10, SPR_FPCSR
	l.nop

div0_excpt:
	lf.div.s r3, r6, r0
	l.nop
	l.nop
	l.lwz r10, 0(r0)
	l.andi r10, r10, SPR_FPCSR_DZF
	l.sfgtu r10, r0
	l.bnf _finish
	l.ori r3, r0, 16
	


_success_report:
	l.movhi r6, hi(0xdeaddead)
	l.ori r6, r6, lo(0xdeaddead)
	REPORT_REG(r6)
	
	l.ori r3, r0, 15

_finish:
	l.jal	_or32_exit
	l.nop

