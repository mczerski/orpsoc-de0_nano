#include "spr-defs.h"
#include "or1200-utils.h"
#include "board.h" // For timer rate (IN_CLK, TICKS_PER_SEC)

/* For writing into SPR. */
void mtspr(unsigned long spr, unsigned long value)
{	
  asm("l.mtspr\t\t%0,%1,0": : "r" (spr), "r" (value));
}

/* For reading SPR. */
unsigned long mfspr(unsigned long spr)
{	
  unsigned long value;
  asm("l.mfspr\t\t%0,%1,0" : "=r" (value) : "r" (spr));
  return value;
}

/* Print out a character via simulator */
void sim_putc(unsigned char c)
{
  asm("l.addi\tr3,%0,0": :"r" (c));
  asm("l.nop %0": :"K" (NOP_PUTC));
}

/* print long */
void report(unsigned long value)
{
  asm("l.addi\tr3,%0,0": :"r" (value));
  asm("l.nop %0": :"K" (NOP_REPORT));
}

/* Loops/exits simulation */
void exit (int i)
{
  asm("l.add r3,r0,%0": : "r" (i));
  asm("l.nop %0": :"K" (NOP_EXIT));
  while (1);
}

/* Enable user interrupts */
void
cpu_enable_user_interrupts(void)
{
  /* Enable interrupts in supervisor register */
  mtspr (SPR_SR, mfspr (SPR_SR) | SPR_SR_IEE);
}

/* Tick timer variable */
unsigned long timer_ticks;

/* Tick timer functions */
/* Enable tick timer and interrupt generation */
void enable_timer(void)
{
  mtspr(SPR_SR, SPR_SR_TEE | mfspr(SPR_SR));
  mtspr(SPR_TTMR, SPR_TTMR_IE | SPR_TTMR_RT | ((IN_CLK/TICKS_PER_SEC) & SPR_TTMR_PERIOD));
}

/* Disable tick timer and interrupt generation */
void disable_timer(void)
{
  // Disable timer: clear it all!
  mtspr (SPR_SR, mfspr (SPR_SR) & ~SPR_SR_TEE);
  mtspr(SPR_TTMR, 0);

}

/* Timer increment - called by interrupt routine */
void timer_tick(void)
{
  timer_ticks++;
  mtspr(SPR_TTMR, SPR_TTMR_IE | SPR_TTMR_RT | ((IN_CLK/TICKS_PER_SEC) & SPR_TTMR_PERIOD));
}

/* Reset tick counter */
void clear_timer_ticks(void)
{
  timer_ticks=0;
}

/* Get tick counter */
unsigned long get_timer_ticks(void)
{
  return timer_ticks;
}

/* Wait for 10ms */
void wait_10ms(void)
{
  unsigned long first_time = get_timer_ticks();
  while (first_time == get_timer_ticks());    
}
  
