#include "support.h"
#include "board.h"
#include "spr_defs.h"

/* Tick timer period */
#define SYS_CLKS_PER_TICK (IN_CLK/TICKS_PER_SEC)
#define USEC_PER_SEC (1000000)
#define USEC_PER_MSEC (1000)
#define MSEC_PER_SEC (1000)
#define USEC_PER_TICK (USEC_PER_SEC/TICKS_PER_SEC)

unsigned long tick_period = SYS_CLKS_PER_TICK;
unsigned long usec, msec, sec;

/* Start the timer, enabling interrupt, self-restart and set the period */
void 
init_timer(void)
{
  /* enable counter interrupt */
  mtspr(SPR_SR,(mfspr(SPR_SR)|SPR_SR_TEE));
  
  /* Set counter period, enable timer and interrupt */
  /* SPR_TTMR_RT bit makes timer reset and restart itself automatically */
  /* This will start it, too. */
  mtspr(SPR_TTMR, SPR_TTMR_IE | SPR_TTMR_RT | (SYS_CLKS_PER_TICK & SPR_TTMR_PERIOD));
  usec = 0, msec=0, sec=0;
}

/* Update timecounters */
void 
timer_interrupt(void)
{
  /* Update our time counters */
  usec += USEC_PER_TICK;
  if (usec >= USEC_PER_MSEC ){ usec -= USEC_PER_MSEC; msec++; }
  if (msec >= MSEC_PER_SEC ){ msec -= MSEC_PER_SEC; sec++; }
}

/* Return time in microseconds */
unsigned int 
read_time_us(void)
{
  return ((sec*((MSEC_PER_SEC*USEC_PER_MSEC)))+(msec*(USEC_PER_MSEC))+usec);
}
