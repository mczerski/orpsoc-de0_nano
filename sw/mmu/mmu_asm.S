#include "spr_defs.h"

    .global _lo_dmmu_en
    .global _lo_immu_en
    .global _testjump

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
 
_testjump:
    l.movhi r5,0x4800
    l.ori   r5,r5,0x4800
    l.sw    0x0(r3),r5
    l.movhi r5,0x1500
    l.ori   r5,r5,0x0000
    l.sw    0x4(r3),r5
    l.or    r5,r0,r9
    l.jalr  r4
    l.nop
    l.or    r9,r0,r5
    l.jr    r9
    l.nop   
