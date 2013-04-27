//Read the documentation before changing values

`define BIG_ENDIAN
//`define LITLE_ENDIAN

//`define SIM
`define SYN

`define SDC_IRQ_ENABLE

//`define ACTEL
//`define CUSTOM
`define ALTERA
//`define XLINX
//`define SIMULATOR

`ifdef SYN
  `define RESET_CLK_DIV 0
  `define MEM_OFFSET 4
`endif

`ifdef SIM
  `define RESET_CLK_DIV 0
  `define MEM_OFFSET 4
  `include "timescale.v"
`endif

//SD-Clock Defines ---------
//Use bus clock or a seperate clock
//`define SDC_CLK_BUS_CLK
`define SDC_CLK_SEP

// Use of internal clock divider
//`define SDC_CLK_STATIC
`define SDC_CLK_DYNAMIC

//SD DATA-transfer defines---
`define RESET_BLOCK_SIZE 512

`define BLKSIZE_W 12
`define BLKCNT_W 16

//at 512 bytes per block, equal 1024 4 bytes writings with a bus width of 4, add 2 for startbit and Z bit.
//Add 18 for crc, endbit and z.
//`define BIT_BLOCK 1044
`define CRC_OFF 19
//`define BIT_BLOCK_REC 1024
`define BIT_CRC_CYCLE 16


//FIFO defines---------------
`define FIFO_RX_MEM_ADR_SIZE 4

`define FIFO_TX_MEM_ADR_SIZE 4
//---------------------------









