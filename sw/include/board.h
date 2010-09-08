#ifndef _BOARD_H_
#define _BOARD_H_

#define IN_CLK  	      50000000 // Hz
//#define IN_CLK  	      32000000 // Hz
//#define IN_CLK  	      30000000 // HZ
//#define IN_CLK  	      25000000 // HZ
//#define IN_CLK  	      24000000 // HZ
//#define IN_CLK  	      20000000 // HZ
//#define IN_CLK  	      18000000 // HZ
//#define IN_CLK  	      16000000 // HZ

//
// Defines for each core (memory map base, OR1200 interrupt line number, etc.)
//
#define SDRAM_BASE                 0x0
//#define MT48LC32M16A2 // 64MB SDRAM part
#define MT48LC16M16A2 // 32MB SDRAM part
//#define MT48LC4M16A2 // 8MB SDRAM part

#define UART0_BASE  	    0x90000000
#define UART0_IRQ                    2
#define UART0_BAUD_RATE 	115200

#define SPI0_BASE           0xb0000000
#define SPI0_IRQ                     6

#define ETH0_BASE            0x92000000
#define ETH0_IRQ                      4

#define ETH_MACADDR0	           0x00
#define ETH_MACADDR1	           0x12
#define ETH_MACADDR2  	           0x34
#define ETH_MACADDR3	           0x56
#define ETH_MACADDR4  	           0x78
#define ETH_MACADDR5	           0x9a


//
// OR1200 tick timer period define
//
#define TICKS_PER_SEC   100

#endif
