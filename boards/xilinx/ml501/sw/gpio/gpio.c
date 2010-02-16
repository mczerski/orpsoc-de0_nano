// Small app to print a hello world
#include "spr_defs.h"
#include "board.h"
#include "uart.h"


#define GPIO_BASE 0x80000000
#define GPIO_DATA (GPIO_BASE)
#define GPIO_DIR (GPIO_BASE | 0x4)


#ifdef SYNTHESIS
#define LOOP_DELAY 200000
#else
#define LOOP_DELAY 20
#endif

void
gpio ()
{
  int i,j;
  
  volatile int* gpio_dir = (volatile int*) GPIO_DIR;
  volatile int* gpio_data = (volatile int*) GPIO_DATA;

  // bottom byte to out
  *gpio_dir = 0x000000ff;

  uart_init();

  while (1) {
    i = 0;
    while (i <= 7) {
      *gpio_data =  1<<i;
      
      i++;
      j = LOOP_DELAY;
      while (j--)
	{
	  if (uart_check_for_char()) 
	    {
	      uart_putc(uart_getc());
	      *gpio_data = 0xff;
	    }
	}
    }
    
    while (i > 0) {
      i--;
      *gpio_data =  1<<i;
      
      j = LOOP_DELAY;
      while (j--)
	{
	  if (uart_check_for_char()) 
	    {
	      uart_putc(uart_getc());
	      *gpio_data = 0xff;
	    }
	}
    }
    
    /* Report and exit for sim */
    asm("l.movhi\tr3, hi(0xdeaddead)\n \
       l.ori\tr3,r3, lo(0xdeaddead)\n			\
       l.nop\t%0\n					\
       l.nop\t%1": :"K" (NOP_REPORT), "K" (NOP_EXIT));
    
  
  
  }
  
  
}

