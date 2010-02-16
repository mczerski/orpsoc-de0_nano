#ifndef _BOARD_H_
#define _BOARD_H_

#define MC_ENABLED	    0

#define IC 	    1
#define IC_SIZE         8192
#define DC 	    0
#define DC_SIZE         8192


//#define IN_CLK  	      25000000
#define IN_CLK  	      50000000

#define TICKS_PER_SEC   100

#define STACK_SIZE	    0x10000

#define UART_BAUD_RATE 	115200

#define UART_BASE  	    0x90000000
#define UART_IRQ        19

//#define SPI_BASE        0xa0000000

//#define ETH_BASE        0xD0000000
//#define IRQ_ETH_0             (4)       /* interrupt source for Ethernet dvice 0 */

#define ETH_DATA_BASE  0xa8000000 /*  Address for ETH_DATA */
#define BOARD_DEF_IP	  0x0a010185
#define BOARD_DEF_MASK	0xff000000
#define BOARD_DEF_GW  	0x0a010101

#define ETH_MACADDR0	  0x00
#define ETH_MACADDR1	  0x12
#define ETH_MACADDR2  	0x34
#define ETH_MACADDR3	  0x56
#define ETH_MACADDR4  	0x78
#define ETH_MACADDR5	  0x9a


#endif
