///////////////////////////////////////////////////////////////////////////
// ML501 ORPSoCv2 build defines
///////////////////////////////////////////////////////////////////////////
//
// Uncomment the `defines to enable them
//
// Note the synthesis scripts may need to be altered (mainly the UCF for
// place and route) depending on the configuration.
//
///////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////
// Memory
///////////////////////////////////////////////////////////////////////////
//
// Memory configuration options:
//
// On-Chip startup/low memory RAM is optional
// The main memory controllers are mutually exclusive (ie. only one enabled at a time)
//
// Main memory options (select only of the following):  
//  
//                        On-Chip Xilinx RAMBs (~64KByte, resource use depending)
//                        ZBT SSRAM (1MByte, 200Mhz)
//                        DDR2 SDRAM (256MByte, 266Mhz)
// It is recommended the startup memory is used with only the ZBT SSRAM or DDR2
//
// See the RTL file, boards/xilinx/ml501/rtl/ml501_mc.v, for specifics
//
///////////////////////////////////////////////////////////////////////////

// Use on-chip memory as a boot-ROM
`define ML501_MEMORY_STARTUP
`ifdef ML501_MEMORY_STARTUP
// Define the size of the onchip low/startup memory
// 4KByte
//`define ML501_MEMORY_STARTUP_ADDR_SPAN 16'h1000
//`define ML501_MEMORY_STARTUP_ADDR_WIDTH 12
// 8KByte
//`define ML501_MEMORY_STARTUP_ADDR_SPAN 16'h2000
//`define ML501_MEMORY_STARTUP_ADDR_WIDTH 13
// 32KByte
 `define ML501_MEMORY_STARTUP_ADDR_SPAN 16'h8000
 `define ML501_MEMORY_STARTUP_ADDR_WIDTH 15
`endif

// Main memory configuration

// On-chip SRAM (Xilinx RAMB36s)
//`define ML501_MEMORY_ONCHIP
`ifdef ML501_MEMORY_ONCHIP
// 64KByte = 16 on-chip RAMs (4KByte per RAMB36) of the xc5vlx50's 48 BlockRAMs
 `define ML501_MEMORY_ONCHIP_SIZE_BYTES (64*1024)
 `define ML501_MEMORY_ONCHIP_ADDRESS_WIDTH 16
`endif

// Use the ZBT SSRAM controller
//`define ML501_MEMORY_SSRAM
`ifdef ML501_MEMORY_SSRAM
 `define tsramtrace #750  /* 1500ps roundtrip */
`endif

// Use the DDR2 SDRAM controller
`define ML501_MEMORY_DDR2

///////////////////////////////////////////////////////////////////////////
// Peripherals
///////////////////////////////////////////////////////////////////////////

// Include the OpenCores Ethernet MAC
`define USE_ETHERNET

