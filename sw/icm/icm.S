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
.global _icm_test

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
	l.addi	r6,r0,0

	/* Store array */
	/* r4 pointer */
	/* r5 loop counter */
	l.movhi	r4,hi(_icm_var)
	l.ori	r4,r4,lo(_icm_var)
	l.addi	r5,r0,6
loop1:	l.sw	0(r4),r4
	l.addi	r4,r4,4
	l.sfeq	r5,r0
	l.bnf	loop1
	l.addi	r5,r5,-1

	/* Check array */
	/* r4 pointer */
	/* r5 loop counter */
	/* r6 chksum */
	/* r7 tmp loaded value */
	l.movhi	r4,hi(_icm_var)
	l.ori	r4,r4,lo(_icm_var)
	l.addi	r5,r0,6
loop2:	l.lwz	r7,0(r4)
	l.addi	r4,r4,4
	l.add	r6,r6,r7
	l.sfeq	r5,r0
	l.bnf	loop2
	l.addi	r5,r5,-1

	/* Run from ICM */
	l.jal	_icm_test
	l.addi	r6,r6,50

	l.add	r3,r0,r6
	l.jal	_report

	l.nop
	l.jal	_or32_exit
	l.nop
	l.nop

.section .data,"ax"

_ram_var:
.space 100

.section .icm,"ax"

_icm_var:
.space 100

_icm_test:
	l.addi	r6,r6,1
	l.movhi	r4,hi(_ram_var)
	l.ori	r4,r4,lo(_ram_var)
	l.lwz	r5,0(r4)
	l.sw	0(r4),r5
	l.j	_icm_test_jmptest
	l.addi	r6,r6,5

_icm_test_jmptest:
	l.nop
	l.sw	4(r4),r5
	l.sw	8(r4),r5
	l.sw	12(r4),r5
	l.sw	16(r4),r5

	/* Store array */
	/* r4 pointer */
	/* r5 loop counter */
	l.movhi	r4,hi(_icm_var)
	l.ori	r4,r4,lo(_icm_var)
	l.movhi	r4,hi(0x00100000)
	l.ori	r4,r4,lo(0x00100000)
	l.addi	r5,r0,6
loop3:	l.sw	0(r4),r4
	l.addi	r4,r4,4
	l.sfeq	r5,r0
	l.bnf	loop3
	l.addi	r5,r5,-1

	/* Check array */
	/* r4 pointer */
	/* r5 loop counter */
	/* r6 chksum */
	/* r7 tmp loaded value */
	l.movhi	r4,hi(_icm_var)
	l.ori	r4,r4,lo(_icm_var)
	l.addi	r5,r0,6
loop4:
/*	l.lwz	r7,0(r4)*/
	l.add	r7,r0,r0
	l.addi	r4,r4,4
	l.add	r6,r6,r7
	l.sfeq	r5,r0
	l.bnf	loop4
	l.addi	r5,r5,-1

	l.nop
	l.jr	r9
	l.addi	r6,r6,20

