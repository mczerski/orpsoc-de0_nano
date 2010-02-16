// Small app to print a hello world
#include "spr_defs.h"
#include "board.h"
#include "uart.h"

void
boot ()
{
  char *helloworld = "\n\tHello World from the OpenRISC on Xilinx ML501\n\n";

  uart_init();

  int i=0;
  while (helloworld[i])
    uart_putc(helloworld[i++]);

#ifndef SYNTHESIS
  /* Report and exit for sim */
  asm("l.movhi\tr3, hi(0xdeaddead)\n \
       l.ori\tr3,r3, lo(0xdeaddead)\n \
       l.nop\t%0\n \
       l.nop\t%1": :"K" (NOP_REPORT), "K" (NOP_EXIT));
#endif
  
  // Echo characters back
  while (1)
    uart_putc(uart_getc());
  
}

