#include "spr_defs.h"

// Linked from 0x200, so subtract 0x200 from each .org
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
	l.nop
	l.j	_lpint_except
	l.nop

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
	l.j	_syscall_except
	l.nop

.org 0xb00
 
_except_d00:
	l.nop
	l.j	_res1_except
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

