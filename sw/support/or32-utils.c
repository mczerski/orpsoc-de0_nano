#include "spr-defs.h"
#include "or32-utils.h"
#include "board.h" // For timer stuff

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


/* Simple C functions */

/* memcpy */

void* memcpy( void* s1, void* s2, size_t n)
{
  char* r1 = s1;
  const char* r2 = s2;
#ifdef __BCC__
  while (n--) {
    *r1++ = *r2++;
  }
#else
  while (n) {
    *r1++ = *r2++;
    --n;
  }
#endif
  return s1;
}

/* strlen */
size_t strlen(const char*s)
{
  const char* p;
  for (p=s; *p; p++);
  return p - s;
}

/* memchr */
void *memchr(const void *s, int c, size_t n)
{
         const unsigned char *r = (const unsigned char *) s;
#ifdef __BCC__
        /* bcc can optimize the counter if it thinks it is a pointer... */
        const char *np = (const char *) n;
#else
# define np n
#endif

        while (np) {
                if (*r == ((unsigned char)c)) {
                        return (void *) r;     /* silence the warning */
                }
                ++r;
                --np;
        }

        return NULL;
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
  

/* --------------------------------------------------------------------------*/
/*!Pseudo-random number generator

   This should return pseudo-random numbers, based on a Galois LFSR

   @return The next pseudo-random number                                     */
/* --------------------------------------------------------------------------*/
unsigned long int
rand ()
{
  static unsigned long int lfsr = RAND_LFSR_SEED;
  static int period = 0;
  /* taps: 32 31 29 1; characteristic polynomial: x^32 + x^31 + x^29 + x + 1 */
  lfsr = (lfsr >> 1) ^ (unsigned long int)((0 - (lfsr & 1u)) & 0xd0000001u); 
  ++period;
  return lfsr;
}


