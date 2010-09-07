//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Interrupt-driven Ethernet MAC transmit test code            ////
////                                                              ////
////  Description                                                 ////
////  Transmits packets, testing both 100mbit and 10mbit modes.   ////
////  Expects testbench to be checking each packet sent.          ////   
////  Define, ETH_TX_TEST_LENGTH, set further down, controls how  ////
////  many packets the test will send.                            ////
////                                                              ////
////  Test data comes from pre-calculated array of random values, ////
////  MAC TX buffer pointers are set to addresses in this array,  ////
////  saving copying the data around before transfers.            ////
////                                                              ////
////  Author(s):                                                  ////
////      - jb, jb@orsoc.se, with parts taken from Linux kernel   ////
////        open_eth driver.                                      ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2009 Authors and OPENCORES.ORG                 ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

#include "or32-utils.h"
#include "spr-defs.h"
#include "board.h"
#include "int.h"
#include "uart.h"
#include "open-eth.h"
#include "printf.h"
#include "eth-phy-mii.h"

volatile unsigned tx_done;
volatile unsigned rx_done;
static int next_tx_buf_num;

/* Functions in this file */
void ethmac_setup(void);
/* Interrupt functions */
void oeth_interrupt(void);
static void oeth_rx(void);
static void oeth_tx(void);

/* Defining RTLSIM turns off use of real printf'ing to save time in simulation */
#define RTLSIM

#ifdef RTLSIM
#define printk
#else
#define printk printf
#endif
/* Let the ethernet packets use a space beginning here for buffering */
#define ETH_BUFF_BASE 0x01000000


#define RXBUFF_PREALLOC	1
#define TXBUFF_PREALLOC	1
//#undef RXBUFF_PREALLOC
//#undef TXBUFF_PREALLOC

/* The transmitter timeout
 */
#define TX_TIMEOUT	(2*HZ)

/* Buffer number (must be 2^n) 
 */
#define OETH_RXBD_NUM		16
#define OETH_TXBD_NUM		16
#define OETH_RXBD_NUM_MASK	(OETH_RXBD_NUM-1)
#define OETH_TXBD_NUM_MASK	(OETH_TXBD_NUM-1)

/* Buffer size 
 */
#define OETH_RX_BUFF_SIZE	0x600 - 4
#define OETH_TX_BUFF_SIZE	0x600 - 4

/* OR32 Page size def */
#define PAGE_SHIFT		13
#define PAGE_SIZE		(1UL << PAGE_SHIFT)

/* How many buffers per page 
 */
#define OETH_RX_BUFF_PPGAE	(PAGE_SIZE/OETH_RX_BUFF_SIZE)
#define OETH_TX_BUFF_PPGAE	(PAGE_SIZE/OETH_TX_BUFF_SIZE)

/* How many pages is needed for buffers 
 */
#define OETH_RX_BUFF_PAGE_NUM	(OETH_RXBD_NUM/OETH_RX_BUFF_PPGAE)
#define OETH_TX_BUFF_PAGE_NUM	(OETH_TXBD_NUM/OETH_TX_BUFF_PPGAE)

/* Buffer size  (if not XXBUF_PREALLOC 
 */
#define MAX_FRAME_SIZE		1518

/* The buffer descriptors track the ring buffers.   
 */
struct oeth_private {
  //struct	sk_buff* rx_skbuff[OETH_RXBD_NUM];
  //struct	sk_buff* tx_skbuff[OETH_TXBD_NUM];

  unsigned short	tx_next;			/* Next buffer to be sent */
  unsigned short	tx_last;			/* Next buffer to be checked if packet sent */
  unsigned short	tx_full;			/* Buffer ring fuul indicator */
  unsigned short	rx_cur;				/* Next buffer to be checked if packet received */
  
  oeth_regs	*regs;			/* Address of controller registers. */
  oeth_bd		*rx_bd_base;		/* Address of Rx BDs. */
  oeth_bd		*tx_bd_base;		/* Address of Tx BDs. */
  
  //	struct net_device_stats stats;
};


// Data array of data to transmit, tx_data_array[]
#include "eth-rxtx-data.h"
int tx_data_pointer;

#define PHYNUM 7

void 
eth_mii_write(char phynum, short regnum, short data)
{
  static volatile oeth_regs *regs = (oeth_regs *)(OETH_REG_BASE);
  regs->miiaddress = (regnum << 8) | phynum;
  regs->miitx_data = data;
  regs->miicommand = OETH_MIICOMMAND_WCTRLDATA;
  regs->miicommand = 0; 
  while(regs->miistatus & OETH_MIISTATUS_BUSY);
}

short 
eth_mii_read(char phynum, short regnum)
{
  static volatile oeth_regs *regs = (oeth_regs *)(OETH_REG_BASE);
  regs->miiaddress = (regnum << 8) | phynum;
  regs->miicommand = OETH_MIICOMMAND_RSTAT;
  regs->miicommand = 0; 
  while(regs->miistatus & OETH_MIISTATUS_BUSY);
  
  return regs->miirx_data;
}
	  

// Wait here until all packets have been transmitted
void wait_until_all_tx_clear(void)
{

  int i;
  volatile oeth_bd *tx_bd;
  tx_bd = (volatile oeth_bd *)OETH_BD_BASE; /* Search from beginning*/

  int some_tx_waiting = 1;
  
  while (some_tx_waiting)
    {
      some_tx_waiting = 0;
      /* Go through the TX buffs, search for unused one */
      for(i = 0; i < OETH_TXBD_NUM; i++) {
	
	if((tx_bd[i].len_status & OETH_TX_BD_READY)) // Looking for buffer ready for transmit
	  some_tx_waiting = 1;
	
      }
    }
  
}


void 
ethphy_set_10mbit(int phynum)
{
  wait_until_all_tx_clear();
  // Hardset PHY to just use 10Mbit mode
  short cr = eth_mii_read(phynum, MII_BMCR);
  cr &= ~BMCR_ANENABLE; // Clear auto negotiate bit
  cr &= ~BMCR_SPEED100; // Clear fast eth. bit
  eth_mii_write(phynum, MII_BMCR, cr);
}


void 
ethphy_set_100mbit(int phynum)
{
  wait_until_all_tx_clear();
  // Hardset PHY to just use 100Mbit mode
  short cr = eth_mii_read(phynum, MII_BMCR);
  cr |= BMCR_ANENABLE; // Clear auto negotiate bit
  cr |= BMCR_SPEED100; // Clear fast eth. bit
  eth_mii_write(phynum, MII_BMCR, cr);
}


void ethmac_setup(void)
{
  // from arch/or32/drivers/open_eth.c
  volatile oeth_regs *regs;
  
  regs = (oeth_regs *)(OETH_REG_BASE);
  
  /* Reset MII mode module */
  regs->miimoder = OETH_MIIMODER_RST; /* MII Reset ON */
  regs->miimoder &= ~OETH_MIIMODER_RST; /* MII Reset OFF */
  regs->miimoder = 0x64; /* Clock divider for MII Management interface */
  
  /* Reset the controller.
   */
  regs->moder = OETH_MODER_RST;	/* Reset ON */
  regs->moder &= ~OETH_MODER_RST;	/* Reset OFF */
  
  /* Setting TXBD base to OETH_TXBD_NUM.
   */
  regs->tx_bd_num = OETH_TXBD_NUM;
  
  
  /* Set min/max packet length 
   */
  regs->packet_len = 0x00400600;
  
  /* Set IPGT register to recomended value 
   */
  regs->ipgt = 0x12;
  
  /* Set IPGR1 register to recomended value 
   */
  regs->ipgr1 = 0x0000000c;
  
  /* Set IPGR2 register to recomended value 
   */
  regs->ipgr2 = 0x00000012;
  
  /* Set COLLCONF register to recomended value 
   */
  regs->collconf = 0x000f003f;
  
  /* Set control module mode 
   */
#if 0
  regs->ctrlmoder = OETH_CTRLMODER_TXFLOW | OETH_CTRLMODER_RXFLOW;
#else
  regs->ctrlmoder = 0;
#endif
  
  /* Clear MIIM registers */
  regs->miitx_data = 0;
  regs->miiaddress = 0;
  regs->miicommand = 0;
  
  regs->mac_addr1 = ETH_MACADDR0 << 8 | ETH_MACADDR1;
  regs->mac_addr0 = ETH_MACADDR2 << 24 | ETH_MACADDR3 << 16 | ETH_MACADDR4 << 8 | ETH_MACADDR5;
  
  /* Clear all pending interrupts 
   */
  regs->int_src = 0xffffffff;
  
  /* Promisc, IFG, CRCEn
   */
  regs->moder |= OETH_MODER_PRO | OETH_MODER_PAD | OETH_MODER_IFG | OETH_MODER_CRCEN | OETH_MODER_FULLD;
  
  /* Enable interrupt sources.
   */

  regs->int_mask = OETH_INT_MASK_TXB 	| 
    OETH_INT_MASK_TXE 	| 
    OETH_INT_MASK_RXF 	| 
    OETH_INT_MASK_RXE 	|
    OETH_INT_MASK_BUSY 	|
    OETH_INT_MASK_TXC	|
    OETH_INT_MASK_RXC;

  // Buffer setup stuff
  volatile oeth_bd *tx_bd, *rx_bd;
  int i,j,k;
  
  /* Initialize TXBD pointer
   */
  tx_bd = (volatile oeth_bd *)OETH_BD_BASE;
  
  /* Initialize RXBD pointer
   */
  rx_bd = ((volatile oeth_bd *)OETH_BD_BASE) + OETH_TXBD_NUM;
  
  /* Preallocated ethernet buffer setup */
  unsigned long mem_addr = ETH_BUFF_BASE; /* Defined at top */

 // Setup TX Buffers
  for(i = 0; i < OETH_TXBD_NUM; i++) {
      //tx_bd[i].len_status = OETH_TX_BD_PAD | OETH_TX_BD_CRC | OETH_RX_BD_IRQ;
      tx_bd[i].len_status = OETH_TX_BD_PAD | OETH_TX_BD_CRC;
      tx_bd[i].addr = mem_addr;
      mem_addr += OETH_TX_BUFF_SIZE;
  }
  tx_bd[OETH_TXBD_NUM - 1].len_status |= OETH_TX_BD_WRAP;

  // Setup RX buffers
  for(i = 0; i < OETH_RXBD_NUM; i++) {
    rx_bd[i].len_status = OETH_RX_BD_EMPTY | OETH_RX_BD_IRQ; // Init. with IRQ
    rx_bd[i].addr = mem_addr;
    mem_addr += OETH_RX_BUFF_SIZE;
  }
  rx_bd[OETH_RXBD_NUM - 1].len_status |= OETH_RX_BD_WRAP; // Last buffer wraps

  /* Enable JUST the transmiter 
   */
  regs->moder &= ~(OETH_MODER_RXEN | OETH_MODER_TXEN);
  regs->moder |= /*OETH_MODER_RXEN |*/ OETH_MODER_TXEN;

  next_tx_buf_num = 0; // init tx buffer pointer

  return;
}



/* Setup buffer descriptors with data */
/* length is in BYTES */
void tx_packet(void* data, int length)
{
  volatile oeth_regs *regs;
  regs = (oeth_regs *)(OETH_REG_BASE);
  
  volatile oeth_bd *tx_bd;
  volatile int i;

   tx_bd = (volatile oeth_bd *)OETH_BD_BASE;
   tx_bd = (struct oeth_bd*) &tx_bd[next_tx_buf_num];
   
   // If it's in use - wait
   while ((tx_bd->len_status & OETH_TX_BD_IRQ));

   /* Clear all of the status flags.
   */
   tx_bd->len_status &= ~OETH_TX_BD_STATS;
  
  /* If the frame is short, tell CPM to pad it.
   */
  #define ETH_ZLEN        60   /* Min. octets in frame sans FCS */
  if (length <= ETH_ZLEN)
    tx_bd->len_status |= OETH_TX_BD_PAD;
  else
    tx_bd->len_status &= ~OETH_TX_BD_PAD;
  
#ifdef _ETH_RXTX_DATA_H_
  // Set the address pointer to the place
  // in memory where the data is and transmit from there
  
  tx_bd->addr = (char*) &tx_data_array[tx_data_pointer&~(0x3)];

  tx_data_pointer += length;
  if (tx_data_pointer > (255*1024))
    tx_data_pointer = 0;
  

#else
  if (data){
    //Copy the data into the transmit buffer, byte at a time 
    char* data_p = (char*) data;
    char* data_b = (char*) tx_bd->addr;
    for(i=0;i<length;i++)
      {
	data_b[i] = data_p[i];
      }
  }
#endif    

  /* Set the length of the packet's data in the buffer descriptor */
  tx_bd->len_status = (tx_bd->len_status & 0x0000ffff) | 
    ((length&0xffff) << 16);

  /* Send it on its way.  Tell controller its ready, interrupt when sent
  * and to put the CRC on the end.
  */
  tx_bd->len_status |= (OETH_TX_BD_READY  | OETH_TX_BD_CRC | OETH_TX_BD_IRQ);
  
  next_tx_buf_num = (next_tx_buf_num + 1) & OETH_TXBD_NUM_MASK;

  return;

}

/* enable RX, loop waiting for arrived packets and print them out */
void oeth_monitor_rx(void)
{
  volatile oeth_regs *regs;
  regs = (oeth_regs *)(OETH_REG_BASE);

  /* Set RXEN in MAC MODER */
  regs->moder = OETH_MODER_RXEN | regs->moder;  

  
  volatile oeth_bd *rx_bd; 
  rx_bd = ((volatile oeth_bd *)OETH_BD_BASE) + OETH_TXBD_NUM;

  volatile int i;
  
  while (1)
    {
  
      for(i=0;i<OETH_RXBD_NUM;i++)
	{
	  if (!(rx_bd[i].len_status & OETH_RX_BD_EMPTY)) /* Not empty */
	    {
	      // Something in this buffer!
	      printk("Oeth: RX in buf %d - len_status: 0x%lx\n",i, rx_bd[i].len_status);
	      /* Clear recieved bit */
	      rx_bd[i].len_status |=  OETH_RX_BD_EMPTY;	      
	      printk("\t end of packet\n\n");
	    }
	}
    }
}


char broadcast_ping_packet[] =  {
  0xff,0xff,0xff,0xff,0xff,0xff, /*SRC MAC*/
  0x00, 0x12, 0x34, 0x56, 0x78, 0x9a, /*SRC MAC*/
  0x08,0x00,
  0x45,
  0x00,
  0x00,0x54,
  0x00,0x00,
  0x40,
  0x00,
  0x40,
  0x01,
  0xef,0xef,
  0xc0,0xa8,0x64,0x58, /* Source IP */
  0xc0,0xa8,0x64,0xff, /* Dest. IP */
  /* ICMP Message body */
  0x08,0x00,0x7d,0x65,0xa7,0x20,0x00,0x01,0x68,0x25,0xa5,0x4a,0xcf,0x05,0x0c,0x00,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f,0x10,0x11,0x12,0x13,0x14,0x15,0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f,0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29,0x2a,0x2b,0x2c,0x2d,0x2e,0x2f,0x30,0x31,0x32,0x33,0x34,0x35,0x36,0x37};


char big_broadcast_ping_packet[] =  {
  0xff,0xff,0xff,0xff,0xff,0xff, /*SRC MAC*/
  0x00, 0x12, 0x34, 0x56, 0x78, 0x9a, /*SRC MAC*/
  0x08,0x00,
  0x45,
  0x00,
  //  0x00,0x54, /* length */
  0x05,0x1c, /* length */
  0x00,0x00,
  0x40,
  0x00,
  0x40,
  0x01,
  0xee,0xf5,
  0xc0,0xa8,0x64,0x9b, /* Source IP */
  0xc0,0xa8,0x64,0xff, /* Dest. IP */
  /* ICMP Message body */
  0x08,0x00,0x7d,0x65,0xa7,0x20,0x00,0x01,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,
  15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,
  40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,
  65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,
  90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,
  130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,
  149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,
  168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,
  187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,
  206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,
  225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,
  244,245,246,247,248,249,250,251,252,253,254,255,
  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,
  15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,
  40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,
  65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,
  90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,
  130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,
  149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,
  168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,
  187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,
  206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,
  225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,
  244,245,246,247,248,249,250,251,252,253,254,255,
  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,
  15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,
  40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,
  65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,
  90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,
  130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,
  149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,
  168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,
  187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,
  206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,
  225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,
  244,245,246,247,248,249,250,251,252,253,254,255,
  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,
  15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,
  40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,
  65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,
  90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,
  130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,
  149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,
  168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,
  187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,
  206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,
  225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,
  244,245,246,247,248,249,250,251,252,253,254,255,
  0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,
  15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,
  40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,
  65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,
  90,91,92,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,
  111,112,113,114,115,116,117,118,119,120,121,122,123,124,125,126,127,128,129,
  130,131,132,133,134,135,136,137,138,139,140,141,142,143,144,145,146,147,148,
  149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,
  168,169,170,171,172,173,174,175,176,177,178,179,180,181,182,183,184,185,186,
  187,188,189,190,191,192,193,194,195,196,197,198,199,200,201,202,203,204,205,
  206,207,208,209,210,211,212,213,214,215,216,217,218,219,220,221,222,223,224,
  225,226,227,228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,
  244,245,246,247,248,249,250,251,252,253,254,255};


  /* This should be 98 bytes big */
  char ping_packet[] = {
    0x00, 0x24, 0xe8, 0x91, 0x7c, 0x0d, /*DST MAC*/
    //0xff, 0xff, 0xff, 0xff, 0xff, 0xff, /*DST MAC*/
    0x00, 0x12, 0x34, 0x56, 0x78, 0x9a, /*SRC MAC*/
    0x08, 0x00, /*TYPE*/
    /* IP */
    0x45, /* Version, header length*/
    0x00, /* Differentiated services field */  
    0x00, 0x54, /* Total length */
    0x00, 0x00, /* Identification */
    0x40, /* Flags */
    0x00, /* Fragment offset */
    0x40, /* Time to live */
    0x01, /* Protocol (0x01 = ICMP */
    0xef, 0xf3, /* Header checksum */
    //0xc0, 0xa8, 0x64, 0xDE, /* Source IP */
    0xc0, 0xa8, 0x0, 0x58, /* Source IP */
    //0xa, 0x1, 0x1, 0x3, /* Source IP */
    0xc0, 0xa8, 0x64, 0x69, /* Dest. IP */
    0xc0, 0xa8, 0x0, 0xb, /* Dest. IP */
    //0xa, 0x1, 0x1, 0x1, /* Dest. IP */
    /* ICMP Message body */
    0x08, 0x00, 0x9a, 0xd4, 0xc8, 0x18, 0x00, 0x01, 0xd9, 0x8c, 0x54, 
    0x4a, 0x7b, 0x37, 0x01, 0x00, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 
    0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 
    0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 
    0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 
    0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37
  };


/* The interrupt handler.
 */
void
oeth_interrupt(void)
{

  volatile oeth_regs *regs;
  regs = (oeth_regs *)(OETH_REG_BASE);

  uint	int_events;
  int serviced;
  
	serviced = 0;

	/* Get the interrupt events that caused us to be here.
	 */
	int_events = regs->int_src;
	regs->int_src = int_events;


#ifndef RTLSIM
	printk(".");
	
	printk("\n=tx_ | %x | %x | %x | %x | %x | %x | %x | %x\n",
	       ((oeth_bd *)(OETH_BD_BASE))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+8))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+16))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+24))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+32))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+40))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+48))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+56))->len_status);
	
	printk("=rx_ | %x | %x | %x | %x | %x | %x | %x | %x\n",
	       ((oeth_bd *)(OETH_BD_BASE+64))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+64+8))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+64+16))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+64+24))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+64+32))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+64+40))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+64+48))->len_status,
	       ((oeth_bd *)(OETH_BD_BASE+64+56))->len_status);

	printk("=int | txb %d | txe %d | rxb %d | rxe %d | busy %d\n",
	       (int_events & OETH_INT_TXB) > 0,
	       (int_events & OETH_INT_TXE) > 0,
	       (int_events & OETH_INT_RXF) > 0,
	       (int_events & OETH_INT_RXE) > 0,
	       (int_events & OETH_INT_BUSY) > 0);
#endif
	
	
	
	/* Handle receive event in its own function.
	 */
	if (int_events & (OETH_INT_RXF | OETH_INT_RXE)) {
		serviced |= 0x1; 
		oeth_rx();
	}

	/* Handle transmit event in its own function.
	 */
	if (int_events & (OETH_INT_TXB | OETH_INT_TXE)) {
		serviced |= 0x2;
		oeth_tx();
		serviced |= 0x2;
		
	}

	/* Check for receive busy, i.e. packets coming but no place to
	 * put them. 
	 */
	if (int_events & OETH_INT_BUSY) {
		serviced |= 0x4;
#ifndef RTLSIM
		printk("b");
#endif
		if (!(int_events & (OETH_INT_RXF | OETH_INT_RXE)))
		  oeth_rx();
	}


#if 0
	if (serviced == 0) {
		void die(const char * str, struct pt_regs * regs, long err);
		int show_stack(unsigned long *esp);
		printk("!");
//		printk("unserviced irq\n");
//		show_stack(NULL);
//		die("unserviced irq\n", regs, 801);
	}
#endif

	if (serviced == 0)
	  printk("\neth interrupt called but nothing serviced\n");
	
	else /* Something happened ... either RX or TX */
	  printk(" | serviced 0x%x\n", serviced);
	
	return;
}



static void
oeth_rx(void)
{
  volatile oeth_regs *regs;
  regs = (oeth_regs *)(OETH_REG_BASE);

  volatile oeth_bd *rx_bdp;
  int	pkt_len, i;
  int	bad = 0;
  
  rx_bdp = ((oeth_bd *)OETH_BD_BASE) + OETH_TXBD_NUM;
  
  printk("r");
  

  /* Find RX buffers marked as having received data */
  for(i = 0; i < OETH_RXBD_NUM; i++)
    {
      bad=0;
      if(!(rx_bdp[i].len_status & OETH_RX_BD_EMPTY)){ /* Looking for NOT empty buffers desc. */
	/* Check status for errors.
	 */
	if (rx_bdp[i].len_status & (OETH_RX_BD_TOOLONG | OETH_RX_BD_SHORT)) {
	  bad = 1;
	  report(0xbaad0001);
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_DRIBBLE) {
	  bad = 1;
	  report(0xbaad0002);
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_CRCERR) {
	  bad = 1;
	  report(0xbaad0003);
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_OVERRUN) {
	  bad = 1;
	  report(0xbaad0004);
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_MISS) {
	  report(0xbaad0005);
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_LATECOL) {
	  bad = 1;
	  report(0xbaad0006);
	}
	if (bad) {
	  rx_bdp[i].len_status &= ~OETH_RX_BD_STATS;
	  rx_bdp[i].len_status |= OETH_RX_BD_EMPTY;
	  exit(0xbaaaaaad);
	  
	  continue;
	}
	else {
	  /* Process the incoming frame.
	   */
	  pkt_len = rx_bdp[i].len_status >> 16;
	  
	  /* Do something here with the data - copy it into userspace, perhaps*/
	  printk("\t end of packet\n\n");

 
	  /* finish up */
	  rx_bdp[i].len_status &= ~OETH_RX_BD_STATS; /* Clear stats */
	  rx_bdp[i].len_status |= OETH_RX_BD_EMPTY; /* Mark RX BD as empty */
	  rx_done++;	  
	}	
      }
    }
}



static void
oeth_tx(void)
{
  volatile oeth_bd *tx_bd;
  int i;
  
  tx_bd = (volatile oeth_bd *)OETH_BD_BASE; /* Search from beginning*/
  
  /* Go through the TX buffs, search for one that was just sent */
  for(i = 0; i < OETH_TXBD_NUM; i++)
    {
      /* Looking for buffer NOT ready for transmit. and IRQ enabled */
      if( (!(tx_bd[i].len_status & (OETH_TX_BD_READY))) && (tx_bd[i].len_status & (OETH_TX_BD_IRQ)) )
	{
	  /* Single threaded so no chance we have detected a buffer that has had its IRQ bit set but not its BD_READ flag. Maybe this won't work in linux */
	  tx_bd[i].len_status &= ~OETH_TX_BD_IRQ;

	  /* Probably good to check for TX errors here */
	  
	  /* set our test variable */
	  tx_done++;

	  printk("T%d",i);
	  
	}
    }
  return;  
}

// A function and defines to fill and transmit a packet
#define MAX_TX_BUFFER 1532
static char tx_buffer[MAX_TX_BUFFER];
static unsigned long tx_data = 0x2ef2e242;
static inline char gen_next_tx_byte(void)
{
  // Bit of LFSR action
  tx_data = ((~(((((tx_data&(1<<25))>>25)^((tx_data&(1<<13))>>13))^((tx_data&(1<<2))>>2)))&0x01) | (tx_data<<1));
  //tx_data++;
  return (char) tx_data & 0xff;
}

void
fill_and_tx_packet(int size)
{
  int i;
  char tx_byte;


  volatile oeth_regs *regs;
  regs = (oeth_regs *)(OETH_REG_BASE);
  
  volatile oeth_bd *tx_bd;
  
  tx_bd = (volatile oeth_bd *)OETH_BD_BASE;
  tx_bd = (struct oeth_bd*) &tx_bd[next_tx_buf_num];


  // If it's in use - wait
  while ((tx_bd->len_status & OETH_TX_BD_IRQ));

#ifndef _ETH_RXTX_DATA_H_  
  /* Copy the data into the transmit buffer, byte at a time */
  char* data_b = (char*) tx_bd->addr;
  for(i=0;i<size;i++)
    {
      data_b[i] = gen_next_tx_byte();
    }
#endif

   tx_packet((void*)0, size);
}

//#define WAIT_PACKET_TX(x) while(tx_done<x)
#define WAIT_PACKET_TX(x)

int main ()
{
  tx_data_pointer = 0;  
  
  /* Initialise handler vector */
  int_init();

  /* Install ethernet interrupt handler, it is enabled here too */
  int_add(ETH0_IRQ, oeth_interrupt, 0);

  /* Enable interrupts in supervisor register */
  mtspr (SPR_SR, mfspr (SPR_SR) | SPR_SR_IEE);
    
  ethmac_setup(); /* Configure MAC, TX/RX BDs and enable RX and TX in MODER */

  /* clear tx_done, the tx interrupt handler will set it when it's been transmitted */
  tx_done = 0;
  rx_done = 0;

  int i;
  ethphy_set_100mbit(0);

#ifndef ETH_TX_TEST_LENGTH
# define ETH_TX_TEST_LENGTH  128
  //# define ETH_TX_TEST_LENGTH  OETH_TX_BUFF_SIZE
#endif

  for(i=5;i<ETH_TX_TEST_LENGTH;i+=1)
    fill_and_tx_packet(i);
  
  ethphy_set_10mbit(0);
  for(i=5;i<ETH_TX_TEST_LENGTH;i+=1)
    fill_and_tx_packet(i);
 
  exit(0x8000000d);

  
}
