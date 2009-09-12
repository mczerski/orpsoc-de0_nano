/* Support */

#ifndef OR32
#include <sys/time.h>
#endif

#include "spr_defs.h"
#include "time.h"
#include "support.h"
#include "int.h"

#ifdef UART_PRINTF
//#include "snprintf.h"
#include "vfnprintf.h"
#include "uart.h"
#endif


void excpt_dummy();
//void int_main();

unsigned long excpt_buserr = (unsigned long) excpt_dummy;
unsigned long excpt_dpfault = (unsigned long) excpt_dummy;
unsigned long excpt_ipfault = (unsigned long) excpt_dummy;
unsigned long excpt_tick = (unsigned long) excpt_dummy;
unsigned long excpt_align = (unsigned long) excpt_dummy;
unsigned long excpt_illinsn = (unsigned long) excpt_dummy;
unsigned long excpt_int = (unsigned long) int_main;
unsigned long excpt_dtlbmiss = (unsigned long) excpt_dummy;
unsigned long excpt_itlbmiss = (unsigned long) excpt_dummy;
unsigned long excpt_range = (unsigned long) excpt_dummy;
unsigned long excpt_syscall = (unsigned long) excpt_dummy;
unsigned long excpt_break = (unsigned long) excpt_dummy;
unsigned long excpt_trap = (unsigned long) excpt_dummy;


/* Start function, called by reset exception handler.  */
void reset ()
{
  int i = main();
  or32_exit (i);  
}

/* return value by making a syscall */
void or32_exit (int i)
{
  asm("l.add r3,r0,%0": : "r" (i));
  asm("l.nop %0": :"K" (NOP_EXIT));
  while (1);
}

#ifdef UART_PRINTF

static int uart_init_done = 0;

#define PRINTFBUFFER_SIZE 512
char PRINTFBUFFER[PRINTFBUFFER_SIZE]; // Declare a global printf buffer

void printf(const char *fmt, ...)
{
  // init uart if not done already
  if (!uart_init_done)
    {
      uart_init();
      uart_init_done = 1;
    }

  va_list args;
  va_start(args, fmt);
  
  //int str_l = vsnprintf(PRINTFBUFFER, PRINTFBUFFER_SIZE, fmt, args);
  int str_l = vfnprintf(PRINTFBUFFER, PRINTFBUFFER_SIZE, fmt, args);
  
  if (!str_l) return; // no length string - just return
  
  int c=0;
  // now print each char via the UART
  while (c < str_l)
    uart_putc(PRINTFBUFFER[c++]);
  
  va_end(args);
  
}

#else
/* activate printf support in simulator */
void printf(const char *fmt, ...)
{
  va_list args;
  va_start(args, fmt);
  __asm__ __volatile__ ("  l.addi\tr3,%1,0\n \
                           l.addi\tr4,%2,0\n \
                           l.nop %0": :"K" (NOP_PRINTF), "r" (fmt), "r"  (args));
}

#endif





/* print long */
void report(unsigned long value)
{
  asm("l.addi\tr3,%0,0": :"r" (value));
  asm("l.nop %0": :"K" (NOP_REPORT));
}

/* just to satisfy linker */
void __main()
{
}

/* start_TIMER                    */
void start_timer(int x)
{
  init_timer();
}

/* read_TIMER                    */
/*  Returns a value since started in uS */
unsigned int read_timer(int x)
{
  return read_time_us();
}

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


void excpt_dummy() {}
