//////////////////////////////////////////////////////////////////////
////                                                              ////
////  ORPSoC on Xilinx ML501                                      ////
////                                                              ////
////  Description                                                 ////
////  ORPSoC on Xilinx ML501 board toplevel file                  ////
////                                                              ////
////  To Do:                                                      ////
////  Check to see if system works with both SSRAM and DDR2 RAM   ////
////  are enabled.                                                ////
////  Add ethernet MAC controller.                                ////
////                                                              ////
////  Author(s):                                                  ////
////      - Julius Baxter, julius.baxter@orsoc.se                 ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2010 Authors and OPENCORES.ORG                 ////
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

// ml501 board toplevel RTL
`timescale 1ps/1ps
`include "ml501_defines.v"
module ml501
  (
   // Clocks and reset
    input 	   sys_clk_in_p, // 200Mhz diff. pair
    input 	   sys_clk_in_n,
    input 	   sys_clk_in, // 100Mhz user clock
    input 	   sys_rst_in,
    output 	   usr_rst_out, // User controlled reset signal
    input 	   usr_rst_in,

`ifdef ML501_MEMORY_SSRAM
   // ZBT SSRAM
    output 	   sram_clk,
    input 	   sram_clk_fb,
    output [21:1]  sram_flash_addr,
    inout [31:0]   sram_flash_data,
    output 	   sram_cen,
    output 	   sram_flash_oe_n,    
    output 	   sram_flash_we_n,
    output [3:0]   sram_bw,
    output 	   sram_adv_ld_n,
    output 	   sram_mode,
`endif //  `ifdef ML501_MEMORY_SSRAM

`ifdef ML501_MEMORY_DDR2
   // DDR2 SDRAM
    output [12:0]  ddr2_a,
    output [1:0]   ddr2_ba,
    output 	   ddr2_ras_n,
    output 	   ddr2_cas_n,
    output 	   ddr2_we_n,
    output [1:0]   ddr2_cs_n,
    output [1:0]   ddr2_odt,
    output [1:0]   ddr2_cke,
    output [7:0]   ddr2_dm,
   
    inout [63:0]   ddr2_dq,			  
    inout [7:0]    ddr2_dqs,
    inout [7:0]    ddr2_dqs_n,
    output [1:0]   ddr2_ck,
    output [1:0]   ddr2_ck_n,
`endif //  `ifdef ML501_MEMORY_DDR2
   
`ifdef USE_ETHERNET
    input 	   phy_tx_clk,
    output [3:0]   phy_tx_data,
    output 	   phy_tx_en,
    output 	   phy_tx_er,
   
    input 	   phy_rx_clk,
    input [3:0]    phy_rx_data,
    input 	   phy_dv,
    input 	   phy_rx_er,
   
    input 	   phy_col,
    input 	   phy_crs,
   
    output 	   phy_smi_clk,
    inout 	   phy_smi_data,

    output 	   phy_rst_n,
`endif //  `ifdef USE_ETHERNET
   
   // JTAG debug
    input 	   dbg_tdi_pad_i,
    input 	   dbg_tck_pad_i,
    input 	   dbg_tms_pad_i,  
    output 	   dbg_tdo_pad_o,
   
   // Uart
    input 	   uart0_RX,
    output 	   uart0_TX,
   // Duplicates of the UART signals, this time to the USB debug cable
    input 	   uart0_RX_expheader,  
    output 	   uart0_TX_expheader,

   // GPIO
    inout [25:0]  gpio
   ) 
  ;

   wire 	   wb_rst;
   wire 	   wb_clk;
   wire 	   sys_clk_in_200;
   wire 	   clk_200;   
   wire [30:0] 	   pic_ints;
   wire 	   uart0_irq;
   wire 	   eth0_int_o;
   parameter [31:0] wbm_or12_i_dat_o = 32'h0;
   wire [31:0] 	   wbm_or12_i_adr_o;
   wire [3:0] 	   wbm_or12_i_sel_o;
   wire 	   wbm_or12_i_we_o;
   wire [1:0] 	   wbm_or12_i_bte_o;
   wire [2:0] 	   wbm_or12_i_cti_o;
   wire 	   wbm_or12_i_stb_o;
   wire 	   wbm_or12_i_cyc_o;
   wire [31:0] 	   wbm_or12_i_dat_i;
   wire 	   wbm_or12_i_ack_i;
   wire 	   wbm_or12_i_err_i;
   wire 	   wbm_or12_i_rty_i;
   wire [31:0] 	   wbm_or12_debug_dat_o;
   wire [31:0] 	   wbm_or12_debug_adr_o;
   wire [3:0] 	   wbm_or12_debug_sel_o;
   wire 	   wbm_or12_debug_we_o;
   wire [1:0] 	   wbm_or12_debug_bte_o;
   wire [2:0] 	   wbm_or12_debug_cti_o;
   wire 	   wbm_or12_debug_stb_o;
   wire 	   wbm_or12_debug_cyc_o;
   wire [31:0] 	   wbm_or12_debug_dat_i;
   wire 	   wbm_or12_debug_ack_i;
   wire 	   wbm_or12_debug_err_i;
   wire 	   wbm_or12_debug_rty_i;
   wire [31:0] 	   wbm_or12_d_dat_o;
   wire [31:0] 	   wbm_or12_d_adr_o;
   wire [3:0] 	   wbm_or12_d_sel_o;
   wire 	   wbm_or12_d_we_o;
   wire [1:0] 	   wbm_or12_d_bte_o;
   wire [2:0] 	   wbm_or12_d_cti_o;
   wire 	   wbm_or12_d_stb_o;
   wire 	   wbm_or12_d_cyc_o;
   wire [31:0] 	   wbm_or12_d_dat_i;
   wire 	   wbm_or12_d_ack_i;
   wire 	   wbm_or12_d_err_i;
   wire 	   wbm_or12_d_rty_i;
   wire [31:0] 	   wbm_eth1_dat_o;
   wire [31:0] 	   wbm_eth1_adr_o;
   wire [3:0] 	   wbm_eth1_sel_o;
   wire 	   wbm_eth1_we_o;
   wire [1:0] 	   wbm_eth1_bte_o;
   wire [2:0] 	   wbm_eth1_cti_o;
   wire 	   wbm_eth1_stb_o;
   wire 	   wbm_eth1_cyc_o;
   wire [31:0] 	   wbm_eth1_dat_i;
   wire 	   wbm_eth1_ack_i;
   wire 	   wbm_eth1_err_i;
   wire 	   wbm_eth1_rty_i;
   wire [31:0] 	   wbs_eth1_cfg_dat_o;
   wire [31:0] 	   wbs_eth1_cfg_dat_i;
   wire [31:0] 	   wbs_eth1_cfg_adr_i;
   wire [3:0] 	   wbs_eth1_cfg_sel_i;
   wire [1:0] 	   wbs_eth1_cfg_bte_i;
   wire [2:0] 	   wbs_eth1_cfg_cti_i;
   wire 	   wbs_eth1_cfg_stb_i;
   wire 	   wbs_eth1_cfg_cyc_i;
   wire 	   wbs_eth1_cfg_ack_o;
   wire 	   wbs_eth1_cfg_err_o;
   parameter wbs_eth1_cfg_rty_o = 1'b0;
   wire [31:0] 	   wbs_mc_m_dat_o;
   wire [31:0] 	   wbs_mc_m_dat_i;
   wire [31:0] 	   wbs_mc_m_adr_i;
   wire [3:0] 	   wbs_mc_m_sel_i;
   wire [1:0] 	   wbs_mc_m_bte_i;
   wire [2:0] 	   wbs_mc_m_cti_i;
   wire 	   wbs_mc_m_stb_i;
   wire 	   wbs_mc_m_cyc_i;
   wire 	   wbs_mc_m_ack_o;
   wire 	   wbs_mc_m_err_o;
   parameter wbs_mc_m_rty_o = 1'b0;
   wire [31:0] 	   wbs_spi_flash_dat_o;
   wire [31:0] 	   wbs_spi_flash_dat_i;
   wire [31:0] 	   wbs_spi_flash_adr_i;
   wire [3:0] 	   wbs_spi_flash_sel_i;
   wire [1:0] 	   wbs_spi_flash_bte_i;
   wire [2:0] 	   wbs_spi_flash_cti_i;
   wire 	   wbs_spi_flash_stb_i;
   wire 	   wbs_spi_flash_cyc_i;
   wire 	   wbs_spi_flash_ack_o;
   parameter wbs_spi_flash_err_o = 1'b0;
   parameter wbs_spi_flash_rty_o = 1'b0;
   wire [31:0] 	   wbs_uart0_dat_o;
   wire [31:0] 	   wbs_uart0_dat_i;
   wire [31:0] 	   wbs_uart0_adr_i;
   wire [3:0] 	   wbs_uart0_sel_i;
   wire [1:0] 	   wbs_uart0_bte_i;
   wire [2:0] 	   wbs_uart0_cti_i;
   wire 	   wbs_uart0_stb_i;
   wire 	   wbs_uart0_cyc_i;
   wire 	   wbs_uart0_ack_o;
   parameter wbs_uart0_err_o = 1'b0;
   parameter wbs_uart0_rty_o = 1'b0;
   wire [31:0] 	   wbs_ds1_dat_o;
   wire [31:0] 	   wbs_ds1_dat_i;
   wire [31:0] 	   wbs_ds1_adr_i;
   wire [3:0] 	   wbs_ds1_sel_i;
   wire [1:0] 	   wbs_ds1_bte_i;
   wire [2:0] 	   wbs_ds1_cti_i;
   wire 	   wbs_ds1_stb_i;
   wire 	   wbs_ds1_cyc_i;
   wire 	   wbs_ds1_ack_o;
   parameter wbs_ds1_err_o = 1'b0;
   parameter wbs_ds1_rty_o = 1'b0;
   wire [31:0] 	   wbs_usrrst_dat_o;
   wire [31:0] 	   wbs_usrrst_dat_i;
   wire [31:0] 	   wbs_usrrst_adr_i;
   wire [3:0] 	   wbs_usrrst_sel_i;
   wire [1:0] 	   wbs_usrrst_bte_i;
   wire [2:0] 	   wbs_usrrst_cti_i;
   wire 	   wbs_usrrst_stb_i;
   wire 	   wbs_usrrst_cyc_i;
   wire 	   wbs_usrrst_ack_o;
   parameter wbs_usrrst_err_o = 1'b0;
   parameter wbs_usrrst_rty_o = 1'b0;
   wire [31:0] 	   wbs_lfsr_dat_o;
   wire [31:0] 	   wbs_lfsr_dat_i;
   wire [31:0] 	   wbs_lfsr_adr_i;
   wire [3:0] 	   wbs_lfsr_sel_i;
   wire [1:0] 	   wbs_lfsr_bte_i;
   wire [2:0] 	   wbs_lfsr_cti_i;
   wire 	   wbs_lfsr_stb_i;
   wire 	   wbs_lfsr_cyc_i;
   wire 	   wbs_lfsr_ack_o;
   parameter wbs_lfsr_err_o = 1'b0;
   parameter wbs_lfsr_rty_o = 1'b0;
   wire [31:0] 	   wbs_gpio_dat_o;
   wire [31:0] 	   wbs_gpio_dat_i;
   wire [31:0] 	   wbs_gpio_adr_i;
   wire [3:0] 	   wbs_gpio_sel_i;
   wire [1:0] 	   wbs_gpio_bte_i;
   wire [2:0] 	   wbs_gpio_cti_i;
   wire 	   wbs_gpio_stb_i;
   wire 	   wbs_gpio_cyc_i;
   wire 	   wbs_gpio_ack_o;
   parameter wbs_gpio_err_o = 1'b0;
   parameter wbs_gpio_rty_o = 1'b0;

   wire 	   eth_clk;
   wire [1:1] 	   eth_int;

   /* DCM0 wires */
   wire 	   dcm0_clk0_prebufg, dcm0_clk0;
   wire 	   dcm0_clkfx_prebufg, dcm0_clkfx;
   wire 	   dcm0_clkdv_prebufg, dcm0_clkdv;
   wire 	   dcm0_rst, dcm0_locked;


   wb_conbus_top
     #(.s0_addr_w(4), .s0_addr(4'h0), // MC
       .s1_addr_w(4), .s1_addr(4'h8), // GPIO
       .s27_addr_w(8), 
       .s2_addr(8'h92),              // ETH Slave
       .s3_addr(8'hb0),              // SPI
       .s4_addr(8'h90),              // UART
       .s5_addr(8'hc0),              // DS1
       .s6_addr(8'he0),              // User Reset
       .s7_addr(8'h1f))              // LFSR       
   wb_conbus
     (
      // Master 0
      // Inputs
      .m0_dat_i				(wbm_or12_i_dat_o),
      .m0_adr_i				(wbm_or12_i_adr_o),
      .m0_sel_i				(wbm_or12_i_sel_o),
      .m0_we_i				(wbm_or12_i_we_o),
      .m0_cyc_i				(wbm_or12_i_cyc_o),
      .m0_stb_i				(wbm_or12_i_stb_o),
      .m0_cab_i				(1'b0),
      // Outputs
      .m0_dat_o				(wbm_or12_i_dat_i),
      .m0_ack_o				(wbm_or12_i_ack_i),
      .m0_err_o				(wbm_or12_i_err_i),
      .m0_rty_o				(wbm_or12_i_rty_i),

      // Master 1
      // Inputs
      .m1_dat_i				(wbm_or12_debug_dat_o),
      .m1_adr_i				(wbm_or12_debug_adr_o),
      .m1_sel_i				(wbm_or12_debug_sel_o),
      .m1_we_i				(wbm_or12_debug_we_o),
      .m1_cyc_i				(wbm_or12_debug_cyc_o),
      .m1_stb_i				(wbm_or12_debug_stb_o),
      .m1_cab_i				(1'b0),
      // Outputs
      .m1_dat_o				(wbm_or12_debug_dat_i),
      .m1_ack_o				(wbm_or12_debug_ack_i),
      .m1_err_o				(wbm_or12_debug_err_i),
      .m1_rty_o				(wbm_or12_debug_rty_i),

      // Master 2
      // Inputs
      .m2_dat_i				(wbm_or12_d_dat_o),
      .m2_adr_i				(wbm_or12_d_adr_o),
      .m2_sel_i				(wbm_or12_d_sel_o),
      .m2_we_i				(wbm_or12_d_we_o),
      .m2_cyc_i				(wbm_or12_d_cyc_o),
      .m2_stb_i				(wbm_or12_d_stb_o),
      .m2_cab_i				(1'b0),
      // Outputs
      .m2_dat_o				(wbm_or12_d_dat_i),
      .m2_ack_o				(wbm_or12_d_ack_i),
      .m2_err_o				(wbm_or12_d_err_i),
      .m2_rty_o				(wbm_or12_d_rty_i),

      // Master 3
      // Inputs
      .m3_dat_i				(wbm_eth1_dat_o),
      .m3_adr_i				(wbm_eth1_adr_o),
      .m3_sel_i				(wbm_eth1_sel_o),
      .m3_we_i				(wbm_eth1_we_o),
      .m3_cyc_i				(wbm_eth1_cyc_o),
      .m3_stb_i				(wbm_eth1_stb_o),
      .m3_cab_i				(1'b0),
      // Outputs
      .m3_dat_o				(wbm_eth1_dat_i),
      .m3_ack_o				(wbm_eth1_ack_i),
      .m3_err_o				(wbm_eth1_err_i),
      .m3_rty_o				(wbm_eth1_rty_i),
      
      // Master 4
      // Inputs
      .m4_dat_i				(0),
      .m4_adr_i				(0),
      .m4_sel_i				(4'h0),
      .m4_we_i				(1'b0),
      .m4_cyc_i				(1'b0),
      .m4_stb_i				(1'b0),
      .m4_cab_i				(1'b0),
      // Outputs
      //.m4_dat_o				(),
      //.m4_ack_o				(),
      //.m4_err_o				(),
      //.m4_rty_o				(),
      
      // Master 5
      // Inputs
      .m5_dat_i				(0),
      .m5_adr_i				(0),
      .m5_sel_i				(4'h0),
      .m5_we_i				(1'b0),
      .m5_cyc_i				(1'b0),
      .m5_stb_i				(1'b0),
      .m5_cab_i				(1'b0),
      // Outputs
      //.m5_dat_o				(),
      //.m5_ack_o				(),
      //.m5_err_o				(),
      //.m5_rty_o				(),

      // Master 6
      // Inputs
      .m6_dat_i				(0),
      .m6_adr_i				(0),
      .m6_sel_i				(4'h0),
      .m6_we_i				(1'b0),
      .m6_cyc_i				(1'b0),
      .m6_stb_i				(1'b0),
      .m6_cab_i				(1'b0),
      // Outputs
      //.m6_dat_o				(),
      //.m6_ack_o				(),
      //.m6_err_o				(),
      //.m6_rty_o				(),

      // Master 7
      // Inputs
      .m7_dat_i				(0),
      .m7_adr_i				(0),
      .m7_sel_i				(4'h0),
      .m7_we_i				(1'b0),
      .m7_cyc_i				(1'b0),
      .m7_stb_i				(1'b0),
      .m7_cab_i				(1'b0),
      // Outputs
      //.m7_dat_o				(),
      //.m7_ack_o				(),
      //.m7_err_o				(),
      //.m7_rty_o				(),


      // Slave 0
      // Inputs
      .s0_dat_i				(wbs_mc_m_dat_o),
      .s0_ack_i				(wbs_mc_m_ack_o),
      .s0_err_i				(wbs_mc_m_err_o),
      .s0_rty_i				(wbs_mc_m_rty_o),
      // Outputs
      .s0_dat_o				(wbs_mc_m_dat_i),
      .s0_adr_o				(wbs_mc_m_adr_i),
      .s0_sel_o				(wbs_mc_m_sel_i),
      .s0_we_o				(wbs_mc_m_we_i),
      .s0_cyc_o				(wbs_mc_m_cyc_i),
      .s0_stb_o				(wbs_mc_m_stb_i),
      //.s0_cab_o				(),

      // Slave 1
      // Inputs
      .s1_dat_i				(wbs_gpio_dat_o),
      .s1_ack_i				(wbs_gpio_ack_o),
      .s1_err_i				(wbs_gpio_err_o),
      .s1_rty_i				(wbs_gpio_rty_o),
      // Outputs
      .s1_dat_o				(wbs_gpio_dat_i),
      .s1_adr_o				(wbs_gpio_adr_i),
      .s1_sel_o				(wbs_gpio_sel_i),
      .s1_we_o				(wbs_gpio_we_i),
      .s1_cyc_o				(wbs_gpio_cyc_i),
      .s1_stb_o				(wbs_gpio_stb_i),
      //.s1_cab_o				(),

      // Slave 2
      // Inputs
      .s2_dat_i				(wbs_eth1_cfg_dat_o),
      .s2_ack_i				(wbs_eth1_cfg_ack_o),
      .s2_err_i				(wbs_eth1_cfg_err_o),
      .s2_rty_i				(wbs_eth1_cfg_rty_o),
      // Outputs
      .s2_dat_o				(wbs_eth1_cfg_dat_i),
      .s2_adr_o				(wbs_eth1_cfg_adr_i),
      .s2_sel_o				(wbs_eth1_cfg_sel_i),
      .s2_we_o				(wbs_eth1_cfg_we_i),
      .s2_cyc_o				(wbs_eth1_cfg_cyc_i),
      .s2_stb_o				(wbs_eth1_cfg_stb_i),
      //.s2_cab_o				(),

      // Slave 3
      // Inputs
      .s3_dat_i				(wbs_spi_flash_dat_o),
      .s3_ack_i				(wbs_spi_flash_ack_o),
      .s3_err_i				(wbs_spi_flash_err_o),
      .s3_rty_i				(wbs_spi_flash_rty_o),
      // Outputs
      .s3_dat_o				(wbs_spi_flash_dat_i),
      .s3_adr_o				(wbs_spi_flash_adr_i),
      .s3_sel_o				(wbs_spi_flash_sel_i),
      .s3_we_o				(wbs_spi_flash_we_i),
      .s3_cyc_o				(wbs_spi_flash_cyc_i),
      .s3_stb_o				(wbs_spi_flash_stb_i),
      //.s3_cab_o				(),

      // Slave 4
      // Inputs
      .s4_dat_i				(wbs_uart0_dat_o),
      .s4_ack_i				(wbs_uart0_ack_o),
      .s4_err_i				(wbs_uart0_err_o),
      .s4_rty_i				(wbs_uart0_rty_o),
      // Outputs
      .s4_dat_o				(wbs_uart0_dat_i),
      .s4_adr_o				(wbs_uart0_adr_i),
      .s4_sel_o				(wbs_uart0_sel_i),
      .s4_we_o				(wbs_uart0_we_i),
      .s4_cyc_o				(wbs_uart0_cyc_i),
      .s4_stb_o				(wbs_uart0_stb_i),
      //.s4_cab_o				(),

      // Slave 5
      // Inputs
      .s5_dat_i				(wbs_ds1_dat_o),
      .s5_ack_i				(wbs_ds1_ack_o),
      .s5_err_i				(1'b0),
      .s5_rty_i				(1'b0),
      // Outputs
      .s5_dat_o				(wbs_ds1_dat_i),
      .s5_adr_o				(wbs_ds1_adr_i),
      .s5_sel_o				(wbs_ds1_sel_i),
      .s5_we_o				(wbs_ds1_we_i),
      .s5_cyc_o				(wbs_ds1_cyc_i),
      .s5_stb_o				(wbs_ds1_stb_i),
      .s5_cab_o				(),
      
      // Slave 6
      // Inputs
      .s6_dat_i				(wbs_usrrst_dat_o),
      .s6_ack_i				(wbs_usrrst_ack_o),
      .s6_err_i				(1'b0),
      .s6_rty_i				(1'b0),
      // Outputs
      .s6_dat_o				(wbs_usrrst_dat_i),
      .s6_adr_o				(wbs_usrrst_adr_i),
      .s6_sel_o				(wbs_usrrst_sel_i),
      .s6_we_o				(wbs_usrrst_we_i),
      .s6_cyc_o				(wbs_usrrst_cyc_i),
      .s6_stb_o				(wbs_usrrst_stb_i),
      .s6_cab_o				(),

      // Slave 7
      // Inputs
      .s7_dat_i				(wbs_lfsr_dat_o),
      .s7_ack_i				(wbs_lfsr_ack_o),
      .s7_err_i				(1'b0),
      .s7_rty_i				(1'b0),
      // Outputs
      .s7_dat_o				(wbs_lfsr_dat_i),
      .s7_adr_o				(wbs_lfsr_adr_i),
      .s7_sel_o				(wbs_lfsr_sel_i),
      .s7_we_o				(wbs_lfsr_we_i),
      .s7_cyc_o				(wbs_lfsr_cyc_i),
      .s7_stb_o				(wbs_lfsr_stb_i),
      .s7_cab_o				(),
      
      // Inputs
      .clk_i				(wb_clk),
      .rst_i				(wb_rst));

   // Tie all cycle type identifiers (CTI) and burst type extension (BTE) signals low
   // Not supported by this arbiter.
   assign wbs_eth1_cfg_bte_i = 0;
   assign wbs_eth1_cfg_cti_i = 0;

   assign wbs_gpio_bte_i = 0;
   assign wbs_gpio_cti_i = 0;
   assign wbs_spi_flash_bte_i = 0;
   assign wbs_spi_flash_cti_i = 0;
   assign wbs_mc_m_bte_i = 0;
   assign wbs_mc_m_cti_i = 0;
   assign wbs_uart0_bte_i = 0;
   assign wbs_uart0_cti_i = 0;
   assign wbs_ds1_bte_i = 0;
   assign wbs_ds1_cti_i = 0;
   assign wbs_usrrst_bte_i = 0;
   assign wbs_usrrst_cti_i = 0;
   assign wbs_lfsr_bte_i = 0;
   assign wbs_lfsr_cti_i = 0;   

   // Programmable interrupt controller lines (aka. IRQ lines)
   assign 	 pic_ints[30] = 1'b0;
   assign 	 pic_ints[29] = 1'b0;
   assign 	 pic_ints[28] = 1'b0;
   assign 	 pic_ints[27] = 1'b0;
   assign 	 pic_ints[26] = 1'b0;
   assign 	 pic_ints[25] = 1'b0;
   assign 	 pic_ints[24] = 1'b0;
   assign 	 pic_ints[23] = 1'b0;
   assign 	 pic_ints[22] = 1'b0;
   assign 	 pic_ints[21] = 1'b0;
   assign 	 pic_ints[20] = 1'b0;
   assign 	 pic_ints[19] = 1'b0;
   assign 	 pic_ints[18] = 1'b0;
   assign 	 pic_ints[17] = 1'b0;
   assign 	 pic_ints[16] = 1'b0;
   assign 	 pic_ints[15] = 1'b0;
   assign 	 pic_ints[14] = 1'b0;
   assign 	 pic_ints[13] = 1'b0;
   assign 	 pic_ints[12] = 1'b0;
   assign 	 pic_ints[11] = 1'b0;
   assign 	 pic_ints[10] = 1'b0;
   assign 	 pic_ints[9]  = 1'b0;
   assign 	 pic_ints[8]  = 1'b0;
   assign 	 pic_ints[7] = 1'b0;
   assign 	 pic_ints[6] = 1'b0;
   assign 	 pic_ints[5] = 1'b0;
   assign 	 pic_ints[4] = eth_int[1]; /* IRQ4, just like in Linux. Added jb 090716 */
   assign 	 pic_ints[3] = 1'b0;
   assign 	 pic_ints[2] = uart0_irq;
   assign 	 pic_ints[1] = 1'b0;
   assign 	 pic_ints[0] = 1'b0;
   or1k_top i_or1k
     (
      .clk_i      (wb_clk),
      .rst_i      (wb_rst), 
      .pic_ints_i (pic_ints[19:0]),
      .iwb_clk_i  (wb_clk), 
      .iwb_rst_i  (wb_rst), 
      .iwb_ack_i  (wbm_or12_i_ack_i), 
      .iwb_err_i  (wbm_or12_i_err_i), 
      .iwb_rty_i  (wbm_or12_i_rty_i), 
      .iwb_dat_i  (wbm_or12_i_dat_i),
      .iwb_cyc_o  (wbm_or12_i_cyc_o), 
      .iwb_adr_o  (wbm_or12_i_adr_o), 
      .iwb_stb_o  (wbm_or12_i_stb_o), 
      .iwb_we_o   (wbm_or12_i_we_o ), 
      .iwb_sel_o  (wbm_or12_i_sel_o), 
      .iwb_cti_o  (wbm_or12_i_cti_o), 
      .iwb_bte_o  (wbm_or12_i_bte_o),
      .dwb_clk_i  (wb_clk), 
      .dwb_rst_i  (wb_rst), 
      .dwb_ack_i  (wbm_or12_d_ack_i), 
      .dwb_err_i  (wbm_or12_d_err_i), 
      .dwb_rty_i  (wbm_or12_d_rty_i), 
      .dwb_dat_i  (wbm_or12_d_dat_i),
      .dwb_cyc_o  (wbm_or12_d_cyc_o), 
      .dwb_adr_o  (wbm_or12_d_adr_o), 
      .dwb_stb_o  (wbm_or12_d_stb_o), 
      .dwb_we_o   (wbm_or12_d_we_o), 
      .dwb_sel_o  (wbm_or12_d_sel_o), 
      .dwb_dat_o  (wbm_or12_d_dat_o),
      .dwb_cti_o  (wbm_or12_d_cti_o), 
      .dwb_bte_o  (wbm_or12_d_bte_o),
      .dbgwb_clk_i (wb_clk), 
      .dbgwb_rst_i (wb_rst), 
      .dbgwb_ack_i (wbm_or12_debug_ack_i), 
      .dbgwb_err_i (wbm_or12_debug_err_i), 
      .dbgwb_dat_i (wbm_or12_debug_dat_i),
      .dbgwb_cyc_o (wbm_or12_debug_cyc_o), 
      .dbgwb_adr_o (wbm_or12_debug_adr_o), 
      .dbgwb_stb_o (wbm_or12_debug_stb_o), 
      .dbgwb_we_o  (wbm_or12_debug_we_o), 
      .dbgwb_sel_o (wbm_or12_debug_sel_o), 
      .dbgwb_dat_o (wbm_or12_debug_dat_o),
      .dbgwb_cti_o (wbm_or12_debug_cti_o), 
      .dbgwb_bte_o (wbm_or12_debug_bte_o),  
      .tms_pad_i   (dbg_tms_pad_i), 
      .tck_pad_i   (dbg_tck),
      .tdi_pad_i   (dbg_tdi_pad_i),
      .tdo_pad_o   (dbg_tdo_pad_o),
      .tdo_padoe_o (             )             
      );

`ifdef USE_SPI_FLASH   
   
   wire 	   spi_flash_mosi, spi_flash_miso, spi_flash_sclk;
   wire [1:0] 	   spi_flash_ss;
   spi_flash_top #
     (
      .divider(0),
      .divider_len(2)
      )
   spi_flash_top0
     (
      .wb_clk_i(wb_clk), 
      .wb_rst_i(wb_rst),
      .wb_adr_i(wbs_spi_flash_adr_i[4:2]),
      .wb_dat_i(wbs_spi_flash_dat_i), 
      .wb_dat_o(wbs_spi_flash_dat_o),
      .wb_sel_i(wbs_spi_flash_sel_i),
      .wb_we_i(wbs_spi_flash_we_i),
      .wb_stb_i(wbs_spi_flash_stb_i), 
      .wb_cyc_i(wbs_spi_flash_cyc_i),
      .wb_ack_o(wbs_spi_flash_ack_o), 
      .mosi_pad_o(spi_flash_mosi),
      .miso_pad_i(spi_flash_miso),
      .sclk_pad_o(spi_flash_sclk),
      .ss_pad_o(spi_flash_ss)
      );

   // SPI flash memory signals
   assign spi_flash_mosi_pad_o = !spi_flash_ss[0] ? spi_flash_mosi : 1'b1;
   assign spi_flash_sclk_pad_o = !spi_flash_ss[0] ? spi_flash_sclk : 1'b1;
   assign spi_flash_ss_pad_o   =  spi_flash_ss[0];
   assign spi_flash_w_n_pad_o    = 1'b1;
   assign spi_flash_hold_n_pad_o = 1'b1;
   assign spi_sd_mosi_pad_o = !spi_flash_ss[1] ? spi_flash_mosi : 1'b1;
   assign spi_sd_sclk_pad_o = !spi_flash_ss[1] ? spi_flash_sclk : 1'b1;
   assign spi_sd_ss_pad_o   =  spi_flash_ss[1];
   assign spi_flash_miso = !spi_flash_ss[0] ? spi_flash_miso_pad_i :
			   !spi_flash_ss[1] ? spi_sd_miso_pad_i :
			   1'b0;
   
`else // !`ifdef USE_SPI_FLASH


   dummy_slave
     # ( .value(32'hb0000000))
   ds_spi
     ( 
       .dat_o(wbs_spi_flash_dat_o), 
       .stb_i(wbs_spi_flash_stb_i), 
       .cyc_i(wbs_spi_flash_cyc_i), 
       .ack_o(wbs_spi_flash_ack_o), 
       .clk(wb_clk), 
       .rst(wb_rst) 
       );

`endif // !`ifdef USE_SPI_FLASH

   /* Memory module */
   ml501_mc ml501_mc0
     (
      .wb_dat_i(wbs_mc_m_dat_i),
      .wb_dat_o(wbs_mc_m_dat_o),
      .wb_sel_i(wbs_mc_m_sel_i),
      .wb_adr_i(wbs_mc_m_adr_i),
      .wb_we_i (wbs_mc_m_we_i),
      .wb_stb_i(wbs_mc_m_stb_i),
      .wb_cyc_i(wbs_mc_m_cyc_i),
      .wb_ack_o(wbs_mc_m_ack_o),
      
`ifdef ML501_MEMORY_SSRAM
      .sram_clk(sram_clk),
      .sram_addr(sram_flash_addr),
      .sram_ce_l(sram_cen),
      .sram_oe_l(sram_flash_oe_n),
      .sram_we_l(sram_flash_we_n),
      .sram_bw_l(sram_bw),
      .sram_adv_ld_l(sram_adv_ld_n),
      .sram_mode(sram_mode),
      .sram_clk_fb(sram_clk_fb),
      .sram_dq_io(sram_flash_data),
`endif //  `ifdef ML501_MEMORY_SSRAM

`ifdef ML501_MEMORY_DDR2
      .ddr2_a(ddr2_a[12:0]),
      .ddr2_ba(ddr2_ba[1:0]),
      .ddr2_ras_n(ddr2_ras_n),
      .ddr2_cas_n(ddr2_cas_n),
      .ddr2_we_n(ddr2_we_n),
      .ddr2_cs_n(ddr2_cs_n),
      .ddr2_odt(ddr2_odt),
      .ddr2_cke(ddr2_cke),
      .ddr2_dm(ddr2_dm[7:0]),
      .ddr2_ck(ddr2_ck[1:0]),
      .ddr2_ck_n(ddr2_ck_n[1:0]),
      .ddr2_dq(ddr2_dq[63:0]),
      .ddr2_dqs(ddr2_dqs[7:0]),
      .ddr2_dqs_n(ddr2_dqs_n[7:0]),
//      .ddr2_if_clk(clk_200),
      .ddr2_if_clk(dcm0_clkfx),
`endif //  `ifdef ML501_MEMORY_DDR2

      .clk_200(clk_200),
      .wb_clk(wb_clk),
      .wb_rst(wb_rst)
      );

   assign wbs_mc_m_err_o = 1'b0;

   // Wires for duplication
   wire 	   uart_rx, uart_tx;
   assign uart_rx = uart0_RX & uart0_RX_expheader;
   
   assign uart0_TX = uart_tx;
   assign uart0_TX_expheader = uart_tx;
   
   uart_top 
     #( 32, 5) 
   i_uart_0_top
     (
      .wb_dat_o   (wbs_uart0_dat_o),
      .wb_dat_i   (wbs_uart0_dat_i),
      .wb_sel_i   (wbs_uart0_sel_i),
      .wb_adr_i   (wbs_uart0_adr_i[4:0]),
      .wb_we_i    (wbs_uart0_we_i),
      .wb_stb_i   (wbs_uart0_stb_i),
      .wb_cyc_i   (wbs_uart0_cyc_i),
      .wb_ack_o   (wbs_uart0_ack_o),
      .wb_clk_i   (wb_clk),
      .wb_rst_i   (wb_rst),
      .int_o      (uart0_irq),
      .srx_pad_i  (uart_rx),
      .stx_pad_o  (uart_tx),
      .cts_pad_i  (1'b0),
      .rts_pad_o  ( ),
      .dtr_pad_o  ( ),
      .dcd_pad_i  (1'b0),
      .dsr_pad_i  (1'b0),
      .ri_pad_i   (1'b0)
      );

   

`ifdef USE_ETHERNET   

   wire 	   phy_smi_data_i, phy_smi_data_o, phy_smi_data_dir;
   
   
   eth_top eth_top1
     (
      .wb_clk_i(wb_clk),
      .wb_rst_i(wb_rst),
      .wb_dat_i(wbs_eth1_cfg_dat_i),
      .wb_dat_o(wbs_eth1_cfg_dat_o),
      .wb_adr_i(wbs_eth1_cfg_adr_i[11:2]),
      .wb_sel_i(wbs_eth1_cfg_sel_i),
      .wb_we_i(wbs_eth1_cfg_we_i),
      .wb_cyc_i(wbs_eth1_cfg_cyc_i),
      .wb_stb_i(wbs_eth1_cfg_stb_i),
      .wb_ack_o(wbs_eth1_cfg_ack_o),
      .wb_err_o(wbs_eth1_cfg_err_o),

      .m_wb_adr_o(wbm_eth1_adr_o),
      .m_wb_sel_o(wbm_eth1_sel_o),
      .m_wb_we_o(wbm_eth1_we_o),
      .m_wb_dat_o(wbm_eth1_dat_o),
      .m_wb_dat_i(wbm_eth1_dat_i),
      .m_wb_cyc_o(wbm_eth1_cyc_o),
      .m_wb_stb_o(wbm_eth1_stb_o),
      .m_wb_ack_i(wbm_eth1_ack_i),
      .m_wb_err_i(wbm_eth1_err_i),
      .m_wb_cti_o(wbm_eth1_cti_o),
      .m_wb_bte_o(wbm_eth1_bte_o),
      
      .mtx_clk_pad_i(phy_tx_clk),
      .mtxd_pad_o(phy_tx_data),
      .mtxen_pad_o(phy_tx_en),
      .mtxerr_pad_o(phy_tx_er),
      .mrx_clk_pad_i(phy_rx_clk),
      .mrxd_pad_i(phy_rx_data),
      .mrxdv_pad_i(phy_dv),
      .mrxerr_pad_i(phy_rx_er),
      .mcoll_pad_i(phy_col),
      .mcrs_pad_i(phy_crs),
      .mdc_pad_o(phy_smi_clk),
      .md_pad_i(phy_smi_data_i),
      .md_pad_o(phy_smi_data_o),
      .md_padoe_o(phy_smi_data_dir),
      .int_o(eth_int[1])
      );

   // Xilinx primitive
   IOBUF iobuf_phy_smi_data
     (
      // Outputs
      .O                                 (phy_smi_data_i),
      // Inouts
      .IO                                (phy_smi_data),
      // Inputs
      .I                                 (phy_smi_data_o),
      .T                                 (!phy_smi_data_dir));

   assign phy_rst_n = !wb_rst;
   
   
`else // !`ifdef USE_ETHERNET
   // If ethernet core is disabled, still ack anyone who tries
   // to access its config port. This allows linux to boot in
   // the verilated ORPSoC.
   
   dummy_slave
     # ( .value(32'h92000000))
   ds_eth1_cfg
     ( 
       .dat_o(wbs_eth1_cfg_dat_o), 
       .stb_i(wbs_eth1_cfg_stb_i), 
       .cyc_i(wbs_eth1_cfg_cyc_i), 
       .ack_o(wbs_eth1_cfg_ack_o), 
       .clk(wb_clk), 
       .rst(wb_rst) 
       );
   assign wbs_eth1_cfg_err_o = 0;
   

   // Tie off ethernet master ctrl signals
   assign wbm_eth1_adr_o = 0;
   assign wbm_eth1_sel_o = 0;
   assign wbm_eth1_we_o = 0;
   assign wbm_eth1_dat_o = 0;
   assign wbm_eth1_cyc_o = 0;
   assign wbm_eth1_stb_o = 0;
   assign wbm_eth1_cti_o = 0;
   assign wbm_eth1_bte_o = 0;
   
`endif //  `ifdef USE_ETHERNET
   
   ml501_gpio ml501_gpio0
     (
      // WB
      .dat_o				(wbs_gpio_dat_o),
      .dat_i				(wbs_gpio_dat_i),
      .ack_o				(wbs_gpio_ack_o),
      .adr_i				(wbs_gpio_adr_i[2:0]),
      .sel_i				(wbs_gpio_sel_i[3:0]),
      .stb_i				(wbs_gpio_stb_i),
      .cyc_i				(wbs_gpio_cyc_i),
      .we_i				(wbs_gpio_we_i),
      
      .gpio				(gpio),
      // Inputs
      .clk				(wb_clk),
      .rst				(wb_rst));

   defparam ml501_gpio0.gpio_width = 26;
   
   
   wb_lfsr lfsr0
     (
      // Outputs
      .wb_dat_o				(wbs_lfsr_dat_o),
      .wb_ack_o				(wbs_lfsr_ack_o),
      // Inputs
      .wb_clk				(wb_clk),
      .wb_rst				(wb_rst),
      .wb_adr_i				(wbs_lfsr_adr_i[2:0]),
      .wb_dat_i				(wbs_lfsr_dat_i),
      .wb_cyc_i				(wbs_lfsr_cyc_i),
      .wb_stb_i				(wbs_lfsr_stb_i),
      .wb_we_i				(wbs_lfsr_we_i));
   

   dummy_slave
     # ( .value(32'hc0000000))
   ds1 
     ( 
       .dat_o(wbs_ds1_dat_o), 
       .stb_i(wbs_ds1_stb_i), 
       .cyc_i(wbs_ds1_cyc_i), 
       .ack_o(wbs_ds1_ack_o), 
       .clk(wb_clk), 
       .rst(wb_rst) 
       );

   usr_rst usr_rst0
     (
      // Outputs
      .usr_rst_out			(usr_rst_out),
      // Inputs
      .wb_clk                           (wb_clk),
      .wb_rst				(wb_rst),
      .wb_cyc_i				(wbs_usrrst_cyc_i),
      .wb_stb_i				(wbs_usrrst_stb_i),
      .wb_ack_o                         (wbs_usrrst_ack_o));
   
   assign 	   wbs_usrrst_dat_o = 0;
   
   /* Reset and clock stuff */
   reset_debounce reset_debounce0
     (
      .sys_rst_in(sys_rst_in),
      .usr_rst_in(usr_rst_in),
      .sys_clk_in(sys_clk_in),
      .dcm0_clk(dcm0_clk0),
      .dcm0_locked(dcm0_locked),
      .rst_dcm0(dcm0_rst),
      .rst(wb_rst)
      );
   
   /* DCM providing main system/Wishbone clock */
   DCM_BASE dcm0
     (
      // Outputs
      .CLK0                              (dcm0_clk0_prebufg),
      .CLK180                            (),
      .CLK270                            (),
      .CLK2X180                          (),
      .CLK2X                             (),
      .CLK90                             (),
      .CLKDV                             (dcm0_clkdv_prebufg),
      .CLKFX180                          (),
      .CLKFX                             (dcm0_clkfx_prebufg),
      .LOCKED                            (dcm0_locked),
      // Inputs
      .CLKFB                             (dcm0_clk0),
      .CLKIN                             (sys_clk_in_200),
      .RST                               (dcm0_rst));
   
   // Generate 266 MHz from CLKFX
   defparam    dcm0.CLKFX_MULTIPLY    = 4;
   defparam    dcm0.CLKFX_DIVIDE      = 3;
   
   // Generate 50 MHz from CLKDV
   defparam    dcm0.CLKDV_DIVIDE      = 4.0;

   BUFG dcm0_clk0_bufg
     (// Outputs
      .O                                 (dcm0_clk0),
      // Inputs
      .I                                 (dcm0_clk0_prebufg));

   BUFG dcm0_clkfx_bufg
     (// Outputs
      .O                                 (dcm0_clkfx),
      // Inputs
      .I                                 (dcm0_clkfx_prebufg));

   BUFG dcm0_clkdv_bufg
     (// Outputs
      .O                                 (dcm0_clkdv),
      // Inputs
      .I                                 (dcm0_clkdv_prebufg));

   IBUFGDS_LVPECL_25 sys_clk_in_ibufds
     (
      .O(sys_clk_in_200),
      .I(sys_clk_in_p),
      .IB(sys_clk_in_n));

   assign wb_clk = dcm0_clkdv;
   assign dbg_tck = dbg_tck_pad_i;
   //assign clk_200 = sys_clk_in_200;
   assign clk_200 = dcm0_clk0;
   
   
endmodule
