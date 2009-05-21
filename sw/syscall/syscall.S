#include "../support/spr_defs.h"

.global _main
.global _syscall_except

.section .vectors, "ax" // section begins at 0x200, so 0xa00 will be at 0xc00
.org 0xa00
_syscall_except:
	l.addi r11,r11,20
	l.addi r11,r11,21
	l.rfe
	l.addi r11,r11,22
	l.addi r11,r11,23
	l.nop

.section .text
_main:
	l.nop
	l.addi r11,r0,1
_loop:
	l.addi r11,r11,1
	l.addi r11,r11,2
	l.sys 13
	l.addi r11,r11,3
	l.addi r11,r11,4
	l.addi r11,r11,5
	l.nop
	l.nop
	l.nop
        l.movhi r9,hi(0xdeadde74)
        l.ori   r9,r9,lo(0xdeadde74)
	l.add	r3,r11,r9
	l.jal	_report
	l.nop
	l.jal	_or32_exit
	l.nop

