#ifndef _BOARD_H_
#define _BOARD_H_

#define IN_CLK  	      50000000 // Hz

//
// Defines for each core (memory map base, OR1200 interrupt line number, etc.)
//
#define RAM_BASE            0x00000000

#define UART0_BASE  	    0x90000000
#define UART0_IRQ                    2
#define UART0_BAUD_RATE 	115200

#define SPI0_BASE 0xb0000000

//
// OR1200 tick timer period define
//
#define TICKS_PER_SEC   100

#endif
