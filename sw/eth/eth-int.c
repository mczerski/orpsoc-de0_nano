//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Interrupt-driven Ethernet test code                         ////
////                                                              ////
////  Description                                                 ////
////  ORPSoC test software                                        ////
////                                                              ////
////  To Do:                                                      ////
////      - It's a simple test for now, but could be adapted for  ////
////        standalone use.                                       ////
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

#include "support.h"
#include "board.h"
#include "spr_defs.h"
#include "int.h"
#include "uart.h"
#include "open_eth.h"

#include "ethphy_micrel.h"

/* Dummy exception functions */
void buserr_except(){}
void dpf_except(){}
void ipf_except(){}
void lpint_except(){}
void align_except(){}
void illegal_except(){}
void hpint_except(){}
void dtlbmiss_except(){}
void itlbmiss_except(){}
void range_except(){}
void syscall_except(){}
void fpu_except(){}
void trap_except(){}
void res2_except(){}

volatile unsigned tx_done;

/* Functions in this file */
void ethmac_setup(void);
void oeth_printregs(void);
void ethphy_init(void);
void oeth_dump_bds();
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
#define OETH_RXBD_NUM		8
#define OETH_TXBD_NUM		8
#define OETH_RXBD_NUM_MASK	(OETH_RXBD_NUM-1)
#define OETH_TXBD_NUM_MASK	(OETH_TXBD_NUM-1)

/* Buffer size 
 */
#define OETH_RX_BUFF_SIZE	2048
#define OETH_TX_BUFF_SIZE	2048

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


void oeth_printregs(void)
{
	volatile oeth_regs *regs;
	regs = (oeth_regs *)(OETH_REG_BASE);
	
        printk("Oeth regs: Mode Register : 0x%lx\n",(unsigned long) regs->moder);          /* Mode Register */
        printk("Oeth regs: Interrupt Source Register 0x%lx\n", (unsigned long) regs->int_src);        /* Interrupt Source Register */
        printk("Oeth regs: Interrupt Mask Register 0x%lx\n",(unsigned long) regs->int_mask);       /* Interrupt Mask Register */
        printk("Oeth regs: Back to Bak Inter Packet Gap Register 0x%lx\n",(unsigned long) regs->ipgt);           /* Back to Bak Inter Packet Gap Register */
        printk("Oeth regs: Non Back to Back Inter Packet Gap Register 1 0x%lx\n",(unsigned long) regs->ipgr1);          /* Non Back to Back Inter Packet Gap Register 1 */
        printk("Oeth regs: Non Back to Back Inter Packet Gap Register 2 0x%lx\n",(unsigned long) regs->ipgr2);          /* Non Back to Back Inter Packet Gap Register 2 */
        printk("Oeth regs: Packet Length Register (min. and max.) 0x%lx\n",(unsigned long) regs->packet_len);     /* Packet Length Register (min. and max.) */
        printk("Oeth regs: Collision and Retry Configuration Register 0x%lx\n",(unsigned long) regs->collconf);       /* Collision and Retry Configuration Register */
        printk("Oeth regs: Transmit Buffer Descriptor Number Register 0x%lx\n",(unsigned long) regs->tx_bd_num);      /* Transmit Buffer Descriptor Number Register */
        printk("Oeth regs: Control Module Mode Register 0x%lx\n",(unsigned long) regs->ctrlmoder);      /* Control Module Mode Register */
        printk("Oeth regs: MII Mode Register 0x%lx\n",(unsigned long) regs->miimoder);       /* MII Mode Register */
        printk("Oeth regs: MII Command Register 0x%lx\n",(unsigned long) regs->miicommand);     /* MII Command Register */
        printk("Oeth regs: MII Address Register 0x%lx\n",(unsigned long) regs->miiaddress);     /* MII Address Register */
        printk("Oeth regs: MII Transmit Data Register 0x%lx\n",(unsigned long) regs->miitx_data);     /* MII Transmit Data Register */
        printk("Oeth regs: MII Receive Data Register 0x%lx\n",(unsigned long) regs->miirx_data);     /* MII Receive Data Register */
        printk("Oeth regs: MII Status Register 0x%lx\n",(unsigned long) regs->miistatus);      /* MII Status Register */
        printk("Oeth regs: MAC Individual Address Register 0 0x%lx\n",(unsigned long) regs->mac_addr0);      /* MAC Individual Address Register 0 */
        printk("Oeth regs: MAC Individual Address Register 1 0x%lx\n",(unsigned long) regs->mac_addr1);      /* MAC Individual Address Register 1 */
        printk("Oeth regs: Hash Register 0 0x%lx\n",(unsigned long) regs->hash_addr0);     /* Hash Register 0 */
        printk("Oeth regs: Hash Register 1  0x%lx\n",(unsigned long) regs->hash_addr1);     /* Hash Register 1 */    
	
}

static int last_char;

void spin_cursor(void)
{
#ifdef RTLSIM
  return;
#endif
  volatile unsigned int i; // So the loop doesn't get optimised away
  printk(" \r");
  if (last_char == 0)
    printk("/");
  else if (last_char == 1)
    printk("-");
  else if (last_char == 2)
    printk("\\");
  else if (last_char == 3)
    printk("|");
  else if (last_char == 4)
    printk("/");
  else if (last_char == 5)
    printk("-");
  else if (last_char == 6)
    printk("\\");
  else if (last_char == 7)
    {
      printk("|");
	  last_char=-1;
    }
  
  last_char++;
  
  for(i=0;i<20000;i++);

}

#define PHYNUM 0

/* Scan the MIIM bus for PHYs */
void scan_ethphys(void)
{
  unsigned int phynum,regnum, i;
  
  volatile oeth_regs *regs;
  regs = (oeth_regs *)(OETH_REG_BASE);
  
  regs->miitx_data = 0;
 
  for(phynum=0;phynum<32;phynum++)
    {
      for (regnum=0;regnum<8;regnum++)
	{
	  printk("scan_ethphys: phy %d r%d ",phynum, regnum);
	  
	  /* Now actually perform the read on the MIIM bus*/
	  regs->miiaddress = (regnum << 8) | phynum; /* Basic Control Register */
	  regs->miicommand = OETH_MIICOMMAND_RSTAT;
	  
	  while(!(regs->miistatus & OETH_MIISTATUS_BUSY)); /* Wait for command to be registered*/
	
	  regs->miicommand = 0;
	  
	  while(regs->miistatus & OETH_MIISTATUS_BUSY);
	  
	  printk("%x\n",regs->miirx_data);
	}
    }
}

	  
void ethmac_scanstatus(void)
{
  volatile oeth_regs *regs;
  regs = (oeth_regs *)(OETH_REG_BASE);

  
  //printk("Oeth: regs->miistatus %x regs->miirx_data %x\n",regs->miistatus, regs->miirx_data);
  regs->miiaddress = 0;
  regs->miitx_data = 0;
  regs->miicommand = OETH_MIICOMMAND_SCANSTAT;
  //printk("Oeth: regs->miiaddress %x regs->miicommand %x\n",regs->miiaddress, regs->miicommand);  
  //regs->miicommand = 0; 
  volatile int i; for(i=0;i<1000;i++);
   while(regs->miistatus & OETH_MIISTATUS_BUSY) ;
   //spin_cursor(); 
   //printk("\r"); 
   or32_exit(0);
}
	  
void ethphy_init(void)
{
  volatile int i;
  
  volatile oeth_regs *regs;
  regs = (oeth_regs *)(OETH_REG_BASE);

  /* Init the Micrel KSZ80001L PHY */
  /* First reset it */
  
/*   printk("Oeth: regs->miistatus %x regs->miirx_data %x\n",regs->miistatus, regs->miirx_data); */
/*   regs->miiaddress = (MICREL_KSZ8001_BCR_ADR << 8); /\* PHY's Basic Control Register *\/ */
/*   regs->miitx_data = MICREL_KSZ8001_BCR_RESET; */
/*   regs->miicommand = OETH_MIICOMMAND_WCTRLDATA; */
/*   printk("Oeth: regs->miiaddress %x regs->miicommand %x\n",regs->miiaddress, regs->miicommand);  */
/*   regs->miicommand = 0; */
/*   while(regs->miistatus & OETH_MIISTATUS_BUSY) */
/*     spin_cursor(); */
/*   printk("\r"); */
  

  printk("Oeth: Reading PHY r0 (status reg)\n");
  regs->miiaddress = MICREL_KSZ8001_BCR_ADR<<8 | PHYNUM; /* Basic Control Register */
  regs->miitx_data = 0;
  regs->miicommand = OETH_MIICOMMAND_RSTAT;

  while(!(regs->miistatus & OETH_MIISTATUS_BUSY)); /* Wait for command to be registered*/
  regs->miicommand = 0;

  while(regs->miistatus & OETH_MIISTATUS_BUSY)
    spin_cursor();
  printk("\r");
  
/*   while (regs->miirx_data & MICREL_KSZ8001_BCR_RESET) */
/*     { */
/*       regs->miiaddress = MICREL_KSZ8001_BCR_ADR<<8; /\* Basic Control Register *\/ */
/*       regs->miitx_data = 0; */
/*       regs->miicommand = OETH_MIICOMMAND_RSTAT; */
/*       regs->miicommand = 0; */
/*       while(regs->miistatus & OETH_MIISTATUS_BUSY) */
/* 	spin_cursor(); */
/*     } */
/*   printk("\r"); */

  printk("\nOeth: PHY r0 value: %x\n",regs->miirx_data);
  
  /* PHY reset and confirmed as such */
  
  /* Now read the link status */
  regs->miiaddress = MICREL_KSZ8001_BSR_ADR<<8 | PHYNUM; /* Basic Status Register */
  regs->miitx_data = 0;
  regs->miicommand = OETH_MIICOMMAND_RSTAT;
  while(!(regs->miistatus & OETH_MIISTATUS_BUSY)); /* Wait for command to be registered*/
  regs->miicommand = 0;
  
  while(regs->miistatus & OETH_MIISTATUS_BUSY)
    spin_cursor();

  printk("\r");
  printk("Oeth: PHY BSR: 0x%x\n",regs->miirx_data & 0xffff);
  
  /* Read the operation mode */
  regs->miiaddress = MICREL_KSZ8001_100BTPCR_ADR<<8 | PHYNUM; /* 100BASE-TX */
  regs->miitx_data = 0;
  regs->miicommand = OETH_MIICOMMAND_RSTAT;
  while(!(regs->miistatus & OETH_MIISTATUS_BUSY)); /* Wait for command to be registered*/
  regs->miicommand = 0;
  while(regs->miistatus & OETH_MIISTATUS_BUSY)
    spin_cursor();
  printk("\r");
  printk("Oeth: PHY 100BASE-TX PHY Control Register: 0x%x\n",regs->miirx_data);


  /* Read the PHY identification register 1 */
  regs->miiaddress = MICREL_KSZ8001_PI1_ADR<<8 | PHYNUM; /* PI1 */
  regs->miitx_data = 0;
  regs->miicommand = OETH_MIICOMMAND_RSTAT;
  while(!(regs->miistatus & OETH_MIISTATUS_BUSY)); /* Wait for command to be registered*/
  regs->miicommand = 0;
  while(regs->miistatus & OETH_MIISTATUS_BUSY)
    spin_cursor();
  printk("\r");
  printk("Oeth: PHY PHY Identifier I: 0x%x\n",regs->miirx_data);

  /* Read the PHY identification register 2 */
  regs->miiaddress = MICREL_KSZ8001_PI2_ADR<<8 | PHYNUM; /* PI2 */
  regs->miitx_data = 0;
  regs->miicommand = OETH_MIICOMMAND_RSTAT;
  while(!(regs->miistatus & OETH_MIISTATUS_BUSY)); /* Wait for command to be registered*/
  regs->miicommand = 0;
  while(regs->miistatus & OETH_MIISTATUS_BUSY)
    spin_cursor();
  printk("\r");
  printk("Oeth: PHY PHY Identifier II: 0x%x\n",regs->miirx_data);


}


void ethmac_setup(void)
{
  // from arch/or32/drivers/open_eth.c
  volatile oeth_regs *regs;
  
  regs = (oeth_regs *)(OETH_REG_BASE);
  
  /*printk("\nbefore reset\n\n");
    oeth_printregs();*/

  /* Reset MII mode module */
  regs->miimoder = OETH_MIIMODER_RST; /* MII Reset ON */
  regs->miimoder &= ~OETH_MIIMODER_RST; /* MII Reset OFF */
  regs->miimoder = 0x64; /* Clock divider for MII Management interface */
  
  /* Reset the controller.
   */
  regs->moder = OETH_MODER_RST;	/* Reset ON */
  regs->moder &= ~OETH_MODER_RST;	/* Reset OFF */
  
  //printk("\nafter reset\n\n");
  //oeth_printregs();
  
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
  
  printk("\nafter config\n\n");
  oeth_printregs();

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

  /* Setup for TX buffers*/
  for(i = 0, k = 0; i < OETH_TX_BUFF_PAGE_NUM; i++) {
    for(j = 0; j < OETH_TX_BUFF_PPGAE; j++, k++) {
      //tx_bd[k].len_status = OETH_TX_BD_PAD | OETH_TX_BD_CRC | OETH_RX_BD_IRQ;
      tx_bd[k].len_status = OETH_TX_BD_PAD | OETH_TX_BD_CRC;
      tx_bd[k].addr = mem_addr;
      mem_addr += OETH_TX_BUFF_SIZE;
    }
  }
  tx_bd[OETH_TXBD_NUM - 1].len_status |= OETH_TX_BD_WRAP;

  /* Setup for RX buffers */
  for(i = 0, k = 0; i < OETH_RX_BUFF_PAGE_NUM; i++) {
    for(j = 0; j < OETH_RX_BUFF_PPGAE; j++, k++) {
      rx_bd[k].len_status = OETH_RX_BD_EMPTY | OETH_RX_BD_IRQ; /* Enable interrupt */
      rx_bd[k].addr = mem_addr;
      mem_addr += OETH_RX_BUFF_SIZE;
    }
  }
  rx_bd[OETH_RXBD_NUM - 1].len_status |= OETH_RX_BD_WRAP; /* Final buffer has wrap bit set */

  /* Enable receiver and transmiter 
   */
  regs->moder |= OETH_MODER_RXEN | OETH_MODER_TXEN;

  return;
}

/* Find the next available transmit buffer */
struct oeth_bd* get_next_tx_bd()
{
  int i;
  volatile oeth_bd *tx_bd;
  tx_bd = (volatile oeth_bd *)OETH_BD_BASE; /* Search from beginning*/
  
  /* Go through the TX buffs, search for unused one */
  for(i = 0; i < OETH_TXBD_NUM; i++) {
    if(!(tx_bd[i].len_status & OETH_TX_BD_READY)) /* Looking for buffer NOT ready for transmit. ie we can manipulate it */
      {
	printk("Oeth: Using TX_bd at 0x%lx\n",(unsigned long)&tx_bd[i]);
	return (struct oeth_bd*) &tx_bd[i];
      }
  }

  printk("No free tx buffers\n");
  /* Set to null our returned buffer */
  tx_bd = (volatile oeth_bd *) 0;
  return (struct oeth_bd*) tx_bd;
  
}


/* print packet contents */
static void
oeth_print_packet(unsigned long add, int len)
{
	int i;
	printk("ipacket: add = %lx len = %d\n", add, len);
	for(i = 0; i < len; i++) {
  		if(!(i % 16))
    			printk("\n");
  		printk(" %.2x", *(((unsigned char *)add) + i));
	}
	printk("\n");
}

/* Setup buffer descriptors with data */
/* length is in BYTES */
void tx_packet(void* data, int length)
{
  volatile oeth_regs *regs;
  regs = (oeth_regs *)(OETH_REG_BASE);
  
  volatile oeth_bd *tx_bd;
  volatile int i;
  
  if((tx_bd = (volatile oeth_bd *) get_next_tx_bd()) == NULL)
    {
      printk("No more TX buffers available\n");
      return;
    }
  printk("Oeth: TX_bd buffer address: 0x%lx\n",(unsigned long) tx_bd->addr);
  
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
  
  printk("Oeth: Copying %d bytes from 0x%lx to TX_bd buffer at 0x%lx\n",length,(unsigned long) data,(unsigned long) tx_bd->addr);
  
  /* Copy the data into the transmit buffer, byte at a time */
  char* data_p = (char*) data;
  char* data_b = (char*) tx_bd->addr;
  for(i=0;i<length;i++)
    {
      *(data_b+i) = *(data_p+i);
    }
  printk("Oeth: Data copied to buffer\n");
  
  /* Set the length of the packet's data in the buffer descriptor */
  tx_bd->len_status = (tx_bd->len_status & 0x0000ffff) | 
    ((length&0xffff) << 16);

  //oeth_print_packet(tx_bd->addr, (tx_bd->len_status >> 16));

  /* Send it on its way.  Tell controller its ready, interrupt when sent
   * and to put the CRC on the end.
   */
  tx_bd->len_status |= (OETH_TX_BD_READY  | OETH_TX_BD_CRC | OETH_TX_BD_IRQ);

  oeth_dump_bds();

  printk("Oeth: MODER addr: 0x%x\n", regs->moder);

  printk("Oeth: TXBD Status 0x%x\n", tx_bd->len_status);
  
  i=0;

  /* Wait for BD READY bit to be cleared, indicating it's been sent */
  /* Not if we've got interrupts enabled. */
  /*
  while (OETH_TX_BD_READY &  tx_bd->len_status)
    {
#ifndef RTLSIM
      //for(i=0;i<40000;i++);
      //printk("Oeth: TXBD Status 0x%x\n", tx_bd->len_status);
      //oeth_printregs();
      spin_cursor();
      if (i++%64==63) {oeth_dump_bds();}
#endif
    }
  */

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
	      oeth_print_packet(rx_bd[i].addr, rx_bd[i].len_status >> 16);
	      /* Clear recieved bit */
	      rx_bd[i].len_status |=  OETH_RX_BD_EMPTY;	      
	      printk("\t end of packet\n\n");
	    }
	}
    }
}

/* Print out all buffer descriptors */
void oeth_dump_bds()
{
  unsigned long* bd_base = (unsigned long*) OETH_BD_BASE;

  int i;
  for(i=0;i<OETH_TXBD_NUM;i++)
    {
      printk("oeth: tx_bd%d: len_status: %lx ",i,*bd_base++);
      printk("addr: %lx\n", *bd_base++);
    }

  for(i=0;i<OETH_RXBD_NUM;i++)
    {
      printk("oeth: rx_bd%d: len_status: %lx ",i,*bd_base++);
      printk("addr: %lx\n", *bd_base++);
    }
  
}



void send_packet()
{
  /* This should be 98 bytes big */
  char ping_packet[] = {
    0x00, 0x24, 0xe8, 0x91, 0x7c, 0x0d, /*DST MAC*/
    0x00, 0xe0, 0x18, 0x73, 0x1d, 0x05, /*SRC MAC*/
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
    0xc0, 0xa8, 0x64, 0xfb, /* Source IP */
    0xc0, 0xa8, 0x64, 0x69, /* Dest. IP */
    /* ICMP Message body */
    0x08, 0x00, 0x9a, 0xd4, 0xc8, 0x18, 0x00, 0x01, 0xd9, 0x8c, 0x54, 
    0x4a, 0x7b, 0x37, 0x01, 0x00, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 
    0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 
    0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f, 0x20, 0x21, 0x22, 0x23, 
    0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2d, 0x2e, 
    0x2f, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37
  };

  /*Send packet */
  tx_packet((void*) ping_packet, 98);

}

void printstring(char* string)
{
 while (*string) uart_putc(*string++);	
}



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
#endif
	
	
	/* Get the interrupt events that caused us to be here.
	 */
	int_events = regs->int_src;
	regs->int_src = int_events;

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
#ifdef RTLSIM
	  report(0);
#else
	printk("\neth interrupt called but nothing serviced\n");
#endif
	else /* Something happened ... either RX or TX */
#ifdef RTLSIM
	  report(0xdeaddead);
#else
	    printk(" | serviced 0x%x\n", serviced);
#endif

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
      if(!(rx_bdp[i].len_status & OETH_RX_BD_EMPTY)){ /* Looking for NOT empty buffers desc. */
	/* Check status for errors.
	 */
	if (rx_bdp[i].len_status & (OETH_RX_BD_TOOLONG | OETH_RX_BD_SHORT)) {
	  bad = 1;
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_DRIBBLE) {
	  bad = 1;
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_CRCERR) {
	  bad = 1;
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_OVERRUN) {
	  bad = 1;
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_MISS) {
	  
	}
	if (rx_bdp[i].len_status & OETH_RX_BD_LATECOL) {
	  bad = 1;
	}
	
	if (bad) {
	  rx_bdp[i].len_status &= ~OETH_RX_BD_STATS;
	  rx_bdp[i].len_status |= OETH_RX_BD_EMPTY;

	  continue;
	}
	else {
	  
	  /* Process the incoming frame.
	   */
	  pkt_len = rx_bdp[i].len_status >> 16;
	  
	  /* Do something here with the data - copy it into userspace, perhaps. */

#ifdef RTLSIM
	  report(pkt_len);
#else
	  oeth_print_packet(rx_bdp[i].addr, rx_bdp[i].len_status >> 16);
	  printk("\t end of packet\n\n");
#endif
	  
	  /* finish up */
	  rx_bdp[i].len_status &= ~OETH_RX_BD_STATS; /* Clear stats */
	  rx_bdp[i].len_status |= OETH_RX_BD_EMPTY; /* Mark RX BD as empty */
	  
	  
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
	  tx_done = 1;

	  printk("T%d",i);
	  
	}
    }
  return;  
}



int main ()
{
  /* Install interrupt handler */
  excpt_int = (unsigned long)int_main;

  /* Initialise handler vector */
  int_init();

  /* Install ethernet interrupt handler, it is enabled here too */
  int_add(IRQ_ETH_0, oeth_interrupt, 0);

  /* Enable interrupts in supervisor register */
  mtspr (SPR_SR, mfspr (SPR_SR) | SPR_SR_IEE);
    
  last_char=0; /* Variable init for spin_cursor() */

#ifndef RTLSIM
  uart_init(); // init the UART before we can printf
  printf("\n\teth interrupts test\n\n");
#endif
  
  ethmac_setup(); /* Configure MAC, TX/RX BDs and enable RX and TX in MODER */
  
  //scan_ethphys(); /* Scan MIIM bus for PHYs */
  //ethphy_init(); /* Attempt reset and configuration of PHY via MIIM */
  //ethmac_scanstatus(); /* Enable scanning of status register via MIIM */

  //oeth_monitor_rx();

  /* clear tx_done, the tx interrupt handler will set it when it's been transmitted */
  tx_done = 0;

  send_packet();

  while(tx_done==0);

#ifdef RTLSIM
  report(0xdeaddead);
  or32_exit(0);
#else
  while(1)
    spin_cursor();
#endif

}
