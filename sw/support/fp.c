#include "spr_defs.h"
#include "support.h"
#include "int.h"


/* Set FPU rounding mode */
void fpsetround(unsigned int rm)
{
  mtspr(SPR_FPCSR, rm | (mfspr(SPR_FPCSR) & ~SPR_FPCSR_RM));
}
