// Small app to print a hello world
#include "spr_defs.h"
#include "board.h"
#include "uart.h"

#ifdef SYNTHESIS
#define print_string(x) i=0; while (x[i]) uart_putc(x[i++]);
#else
#define print_string(x) 
#endif

#ifndef MEM_TEST_BASE
#define MEM_TEST_BASE 0x2000
#endif


#ifndef MEM_TEST_LENGTH
 #ifdef SYNTHESIS
  #define MEM_TEST_LENGTH (((1024*1024*255)/4) - (MEM_TEST_BASE/4))
 #else
  #define MEM_TEST_LENGTH 64
 #endif
#endif


#define LFSR_BASE 0x1f000000
#define LFSR_REG (LFSR_BASE + 0)
#define LFSR_CONTROL_REG (LFSR_BASE + 4)
#define LFSR_CONTROL_ENABLE (1 << 0)
#define LFSR_CONTROL_RESET (1 << 1)

void lfsr_reset()
{
  volatile unsigned int * lfsr_control = (volatile unsigned int*) LFSR_CONTROL_REG;
  *lfsr_control = (LFSR_CONTROL_RESET);
}  

void lfsr_enable()
{
  volatile unsigned int * lfsr_control = (volatile unsigned int*) LFSR_CONTROL_REG;
  *lfsr_control = (LFSR_CONTROL_ENABLE);
}  

void lfsr_set(unsigned int val)
{
  volatile unsigned int * lfsr_reg = (volatile int*) LFSR_REG;
  *lfsr_reg = val ;
}

unsigned int lfsr_read()
{
  volatile unsigned int * lfsr_reg = (volatile int*) LFSR_REG;
  return *lfsr_reg;
}

unsigned int lfsr_read_shift()
{
  volatile unsigned int * lfsr_reg = (volatile int*) LFSR_REG;
  unsigned int lfsr_val = *lfsr_reg;
  lfsr_enable();
  return lfsr_val;
}




void
memtest ()
{

#ifdef SYNTHESIS
  uart_init();
#endif

  int i;
  volatile unsigned int * extmem = (volatile unsigned int*) MEM_TEST_BASE;
  
  char* starting = "\n\n* Starting memtest *\nClearing memory\n"; print_string(starting);
  
  // Clear memory
  for (i=0;i<MEM_TEST_LENGTH;i++)
    extmem[i] = 0;
  
  char* cleared = "Memory cleared\nVerifying\n"; print_string(cleared);
  char *clear_error = "Error verifying zeroed memory\n";
  // Read data
  for (i=0;i<MEM_TEST_LENGTH;i++)
    {
      if (!(extmem[i]==0))
	{
	  /* Report the failed addr and exit for sim */
	  asm("l.add\tr3, r0, %2\n \
           l.nop\t%0\n \
           l.nop\t%1": :"K" (NOP_REPORT), "K" (NOP_EXIT), "r" (i));
	  print_string(clear_error);
	  while(1);
	}
    }
  
  char* random_pattern_write = "Filling RAM with random pattern\n"; print_string(random_pattern_write);
  
  lfsr_reset();
  
  // Write data
  for (i=0;i<MEM_TEST_LENGTH;i++)
    extmem[i] = lfsr_read_shift();
  
  char* reading_random_pattern = "Pattern written\nVerifying and inverting pattern\n"; print_string(reading_random_pattern);
  char *random_pattern_error = "Error verifying random pattern\n";
  
  lfsr_reset();

  // Read data
  for (i=0;i<MEM_TEST_LENGTH;i++)
    {
      if (lfsr_read() != extmem[i])
	{
	  /* Report the failed addr and exit for sim */
	  asm("l.add\tr3, r0, %2\n \
           l.nop\t%0\n \
           l.nop\t%1": :"K" (NOP_REPORT), "K" (NOP_EXIT), "r" (i));
	  print_string(random_pattern_error);
	  while(1);
	}
      extmem[i] = ~extmem[i];
      lfsr_enable(); // Shift to next value
    }
  

  char* reading_inverted_pattern = "Random pattern verified\nVerifying inverting pattern\n"; print_string(reading_inverted_pattern);
  char *random_invert_pattern_error = "Error verifying inverted random pattern\n";
  
  lfsr_reset();
  
  // Read data
  for (i=0;i<MEM_TEST_LENGTH;i++)
    {
      if ((~lfsr_read()) != extmem[i])
	{
	  /* Report the failed addr and exit for sim */
	  asm("l.add\tr3, r0, %2\n \
           l.nop\t%0\n							\
           l.nop\t%1": :"K" (NOP_REPORT), "K" (NOP_EXIT), "r" (i));
	  print_string(random_invert_pattern_error);
	  while(1);
	}
      lfsr_enable(); // Shift to next value
    }


  char* good = "Memory test OK\n"; print_string(good);

#ifdef SYNTHESIS
  //  Fill memory with each 4-byte cell's number
  for (i=0;i<MEM_TEST_LENGTH;i++)
    extmem[i] = i;
  char* newline = "\n.\n"; print_string(newline);
#endif

  /* Report and exit for sim */
  asm("l.movhi\tr3, hi(0xdeaddead)\n \
       l.ori\tr3,r3, lo(0xdeaddead)\n			\
       l.nop\t%0\n					\
       l.nop\t%1": :"K" (NOP_REPORT), "K" (NOP_EXIT));
  

  while(1);
}

