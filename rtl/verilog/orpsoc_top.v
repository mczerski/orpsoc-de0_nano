//////////////////////////////////////////////////////////////////////
////                                                              ////
////  orpsoc_top.v                                                ////
////                                                              ////
////  This file is part of the ORPSoCv2 project                   ////
////  http://opencores.org/openrisc/?orpsocv2                     ////
////                                                              ////
////  This is the top level RTL file for ORPSoCv2                 ////
////                                                              ////
////  Author(s):                                                  ////
////       - Michael Unneback, unneback@opencores.org             ////
////        ORSoC AB          michael.unneback@orsoc.se           ////
////       - Julius Baxter, julius.baxter@orsoc.se                ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2008, 2009 Authors                             ////
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


module orpsoc_top
  (
    output spi_sd_sclk_pad_o  ,
    output spi_sd_ss_pad_o    ,
    input  spi_sd_miso_pad_i  ,
    output spi_sd_mosi_pad_o  ,
`ifdef USE_SDRAM
   // SDRAM bus signals
    inout [15:0] mem_dat_pad_io,
    output [12:0] mem_adr_pad_o ,
    output [1:0]  mem_dqm_pad_o ,
    output [1:0]  mem_ba_pad_o  ,
    output 	  mem_cs_pad_o  ,
    output 	  mem_ras_pad_o ,
    output 	  mem_cas_pad_o ,
    output 	  mem_we_pad_o  ,
    output 	  mem_cke_pad_o ,
   // SPI bus signals for flash memory
    output 	  spi_flash_sclk_pad_o  ,
    output 	  spi_flash_ss_pad_o    ,
    input 	  spi_flash_miso_pad_i  ,
    output 	  spi_flash_mosi_pad_o  ,  
    output 	  spi_flash_w_n_pad_o   ,
    output 	  spi_flash_hold_n_pad_o,
`endif //  `ifdef USE_SDRAM
`ifdef USE_ETHERNET_IO
    output [1:1]  eth_sync_pad_o,
    output [1:1]  eth_tx_pad_o,
    input [1:1]   eth_rx_pad_i,
    input 	  eth_clk_pad_i,
    inout [1:1]   eth_md_pad_io,
    output [1:1]  eth_mdc_pad_o,   
`endif //  `ifdef USE_ETHERNET_IO
    output 	  spi1_mosi_pad_o,
    input 	  spi1_miso_pad_i,
    output 	  spi1_ss_pad_o  ,
    output 	  spi1_sclk_pad_o,
`ifdef DISABLE_IOS_FOR_VERILATOR
    output [8-1:0] gpio_a_pad_io,
`else   
    inout [8-1:0]  gpio_a_pad_io,
`endif
    input 	   uart0_srx_pad_i ,  
    output 	   uart0_stx_pad_o ,
    input 	   dbg_tdi_pad_i,
    input 	   dbg_tck_pad_i,
    input 	   dbg_tms_pad_i,  
    output 	   dbg_tdo_pad_o,
    input 	   rst_pad_i,
    output 	   rst_pad_o,
    input 	   clk_pad_i
   ) 
  ;
   wire 	   wb_rst;
   wire 	   wb_clk, clk50, clk100, dbg_tck;
   wire 	   pll_lock;
   wire 	   mem_io_req, mem_io_gnt, mem_io_busy;
   wire [15:0] 	   mem_dat_pad_i, mem_dat_pad_o;
   wire [30:0] 	   pic_ints;
   wire 	   spi3_irq, spi2_irq, spi1_irq, spi0_irq, uart0_irq;
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
   wire [31:0] 	   wbs_rom_dat_o;
   wire [31:0] 	   wbs_rom_dat_i;
   wire [31:0] 	   wbs_rom_adr_i;
   wire [3:0] 	   wbs_rom_sel_i;
   wire [1:0] 	   wbs_rom_bte_i;
   wire [2:0] 	   wbs_rom_cti_i;
   wire 	   wbs_rom_stb_i;
   wire 	   wbs_rom_cyc_i;
   wire 	   wbs_rom_ack_o;
   parameter wbs_rom_err_o = 1'b0;
   parameter wbs_rom_rty_o = 1'b0;
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
   wire [31:0] 	   wbs_ds2_dat_o;
   wire [31:0] 	   wbs_ds2_dat_i;
   wire [31:0] 	   wbs_ds2_adr_i;
   wire [3:0] 	   wbs_ds2_sel_i;
   wire [1:0] 	   wbs_ds2_bte_i;
   wire [2:0] 	   wbs_ds2_cti_i;
   wire 	   wbs_ds2_stb_i;
   wire 	   wbs_ds2_cyc_i;
   wire 	   wbs_ds2_ack_o;
   parameter wbs_ds2_err_o = 1'b0;
   parameter wbs_ds2_rty_o = 1'b0;
   wire [31:0] 	   wbs_ds3_dat_o;
   wire [31:0] 	   wbs_ds3_dat_i;
   wire [31:0] 	   wbs_ds3_adr_i;
   wire [3:0] 	   wbs_ds3_sel_i;
   wire [1:0] 	   wbs_ds3_bte_i;
   wire [2:0] 	   wbs_ds3_cti_i;
   wire 	   wbs_ds3_stb_i;
   wire 	   wbs_ds3_cyc_i;
   wire 	   wbs_ds3_ack_o;
   parameter wbs_ds3_err_o = 1'b0;
   parameter wbs_ds3_rty_o = 1'b0;

   wire 	   eth_clk;
   wire [1:1] 	   eth_int;
   /*
    // Crossbar arbiter.
    
    wb_conbus_top
     #(.s0_addr_w(4), .s0_addr(4'h0), // MC
       .s1_addr_w(4), .s1_addr(4'hf), // ROM
       .s27_addr_w(8), 
       .s2_addr(8'h92),              // ETH Slave
       .s3_addr(8'hb0),              // SPI
       .s4_addr(8'h90),              // UART
       .s5_addr(8'hc0),              // DS1
       .s6_addr(8'hd0),              // DS2
       .s7_addr(8'he0))              // DS3       
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
      .s1_dat_i				(wbs_rom_dat_o),
      .s1_ack_i				(wbs_rom_ack_o),
      .s1_err_i				(wbs_rom_err_o),
      .s1_rty_i				(wbs_rom_rty_o),
      // Outputs
      .s1_dat_o				(wbs_rom_dat_i),
      .s1_adr_o				(wbs_rom_adr_i),
      .s1_sel_o				(wbs_rom_sel_i),
      .s1_we_o				(wbs_rom_we_i),
      .s1_cyc_o				(wbs_rom_cyc_i),
      .s1_stb_o				(wbs_rom_stb_i),
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
      .s6_dat_i				(wbs_ds2_dat_o),
      .s6_ack_i				(wbs_ds2_ack_o),
      .s6_err_i				(1'b0),
      .s6_rty_i				(1'b0),
      // Outputs
      .s6_dat_o				(wbs_ds2_dat_i),
      .s6_adr_o				(wbs_ds2_adr_i),
      .s6_sel_o				(wbs_ds2_sel_i),
      .s6_we_o				(wbs_ds2_we_i),
      .s6_cyc_o				(wbs_ds2_cyc_i),
      .s6_stb_o				(wbs_ds2_stb_i),
      .s6_cab_o				(),

      // Slave 7
      // Inputs
      .s7_dat_i				(wbs_ds3_dat_o),
      .s7_ack_i				(wbs_ds3_ack_o),
      .s7_err_i				(1'b0),
      .s7_rty_i				(1'b0),
      // Outputs
      .s7_dat_o				(wbs_ds3_dat_i),
      .s7_adr_o				(wbs_ds3_adr_i),
      .s7_sel_o				(wbs_ds3_sel_i),
      .s7_we_o				(wbs_ds3_we_i),
      .s7_cyc_o				(wbs_ds3_cyc_i),
      .s7_stb_o				(wbs_ds3_stb_i),
      .s7_cab_o				(),
      
      // Inputs
      .clk_i				(wb_clk),
      .rst_i				(wb_rst));
    
   // Tie all cycle type identifiers (CTI) and burst type extension (BTE) signals low
   // Not supported by this arbiter.
   assign wbs_eth1_cfg_bte_i = 0;
   assign wbs_eth1_cfg_cti_i = 0;
   assign wbs_rom_bte_i = 0;
   assign wbs_rom_cti_i = 0;
   assign wbs_spi_flash_bte_i = 0;
   assign wbs_spi_flash_cti_i = 0;
   assign wbs_mc_m_bte_i = 0;
   assign wbs_mc_m_cti_i = 0;
   assign wbs_uart0_bte_i = 0;
   assign wbs_uart0_cti_i = 0;
   assign wbs_ds1_bte_i = 0;
   assign wbs_ds1_cti_i = 0;
   assign wbs_ds2_bte_i = 0;
   assign wbs_ds2_cti_i = 0;
   assign wbs_ds3_bte_i = 0;
   assign wbs_ds3_cti_i = 0;   
    */

   // Switch arbiter
   
   wb_switch_b3
     #(
       .slave0_sel_width(4),
       .slave0_sel_addr(4'h0),  // Main memory
       .slave1_sel_width(4),
       .slave1_sel_addr(4'hf),  // ROM
       .slave2_sel_width(8),
       .slave2_sel_addr(8'h92), // Ethernet Slave
       .slave3_sel_width(8),
       .slave3_sel_addr(8'hb0), // SPI
       .slave4_sel_width(8),
       .slave4_sel_addr(8'h90)  // UART
       )
   wb_switch0
     (
      // Master 0
      // Inputs
      .wbm0_dat_o			(wbm_or12_i_dat_o),
      .wbm0_adr_o			(wbm_or12_i_adr_o),
      .wbm0_sel_o			(wbm_or12_i_sel_o),
      .wbm0_we_o			(wbm_or12_i_we_o),
      .wbm0_cyc_o			(wbm_or12_i_cyc_o),
      .wbm0_stb_o			(wbm_or12_i_stb_o),
      .wbm0_cti_o			(wbm_or12_i_cti_o),
      .wbm0_bte_o			(wbm_or12_i_bte_o),
      // Outputs
      .wbm0_dat_i			(wbm_or12_i_dat_i),
      .wbm0_ack_i			(wbm_or12_i_ack_i),
      .wbm0_err_i			(wbm_or12_i_err_i),
      .wbm0_rty_i			(wbm_or12_i_rty_i),
      
      // Master 1
      // Inputs
      .wbm1_dat_o			(wbm_or12_debug_dat_o),
      .wbm1_adr_o			(wbm_or12_debug_adr_o),
      .wbm1_sel_o			(wbm_or12_debug_sel_o),
      .wbm1_we_o			(wbm_or12_debug_we_o),
      .wbm1_cyc_o			(wbm_or12_debug_cyc_o),
      .wbm1_stb_o			(wbm_or12_debug_stb_o),
      .wbm1_cti_o			(wbm_or12_debug_cti_o),
      .wbm1_bte_o			(wbm_or12_debug_bte_o),
      // Outputs
      .wbm1_dat_i			(wbm_or12_debug_dat_i),
      .wbm1_ack_i			(wbm_or12_debug_ack_i),
      .wbm1_err_i			(wbm_or12_debug_err_i),
      .wbm1_rty_i			(wbm_or12_debug_rty_i),

      // Master 2
      // Inputs
      .wbm2_dat_o			(wbm_or12_d_dat_o),
      .wbm2_adr_o			(wbm_or12_d_adr_o),
      .wbm2_sel_o			(wbm_or12_d_sel_o),
      .wbm2_we_o			(wbm_or12_d_we_o),
      .wbm2_cyc_o			(wbm_or12_d_cyc_o),
      .wbm2_stb_o			(wbm_or12_d_stb_o),
      .wbm2_cti_o			(wbm_or12_d_cti_o),
      .wbm2_bte_o			(wbm_or12_d_bte_o),
      // Outputs
      .wbm2_dat_i			(wbm_or12_d_dat_i),
      .wbm2_ack_i			(wbm_or12_d_ack_i),
      .wbm2_err_i			(wbm_or12_d_err_i),
      .wbm2_rty_i			(wbm_or12_d_rty_i),

      // Master 3
      // Inputs
      .wbm3_dat_o			(wbm_eth1_dat_o),
      .wbm3_adr_o			(wbm_eth1_adr_o),
      .wbm3_sel_o			(wbm_eth1_sel_o),
      .wbm3_we_o			(wbm_eth1_we_o),
      .wbm3_cyc_o			(wbm_eth1_cyc_o),
      .wbm3_stb_o			(wbm_eth1_stb_o),
      .wbm3_cti_o			(wbm_eth1_cti_o),
      .wbm3_bte_o			(wbm_eth1_bte_o),
      // Outputs
      .wbm3_dat_i			(wbm_eth1_dat_i),
      .wbm3_ack_i			(wbm_eth1_ack_i),
      .wbm3_err_i			(wbm_eth1_err_i),
      .wbm3_rty_i			(wbm_eth1_rty_i),

      // Slave 0
      // Inputs
      .wbs0_dat_o			(wbs_mc_m_dat_o),
      .wbs0_ack_o			(wbs_mc_m_ack_o),
      .wbs0_err_o			(wbs_mc_m_err_o),
      .wbs0_rty_o			(wbs_mc_m_rty_o),
      // Outputs
      .wbs0_dat_i			(wbs_mc_m_dat_i),
      .wbs0_adr_i			(wbs_mc_m_adr_i),
      .wbs0_sel_i			(wbs_mc_m_sel_i),
      .wbs0_we_i			(wbs_mc_m_we_i),
      .wbs0_cyc_i			(wbs_mc_m_cyc_i),
      .wbs0_stb_i			(wbs_mc_m_stb_i),
      .wbs0_cti_i			(wbs_mc_m_cti_i),
      .wbs0_bte_i			(wbs_mc_m_bte_i),

      // No other slaves have burst capability, dont forward CTI or BTE
      
      // Slave 1
      // Inputs
      .wbs1_dat_o			(wbs_rom_dat_o),
      .wbs1_ack_o			(wbs_rom_ack_o),
      .wbs1_err_o			(wbs_rom_err_o),
      .wbs1_rty_o			(wbs_rom_rty_o),
      // Outputs
      .wbs1_dat_i			(wbs_rom_dat_i),
      .wbs1_adr_i			(wbs_rom_adr_i),
      .wbs1_sel_i			(wbs_rom_sel_i),
      .wbs1_we_i			(wbs_rom_we_i),
      .wbs1_cyc_i			(wbs_rom_cyc_i),
      .wbs1_stb_i			(wbs_rom_stb_i),
      //.wbs1_cab_i			(),

      // Slave 2
      // Inputs
      .wbs2_dat_o			(wbs_eth1_cfg_dat_o),
      .wbs2_ack_o			(wbs_eth1_cfg_ack_o),
      .wbs2_err_o			(wbs_eth1_cfg_err_o),
      .wbs2_rty_o			(wbs_eth1_cfg_rty_o),
      // Outputs
      .wbs2_dat_i			(wbs_eth1_cfg_dat_i),
      .wbs2_adr_i			(wbs_eth1_cfg_adr_i),
      .wbs2_sel_i			(wbs_eth1_cfg_sel_i),
      .wbs2_we_i			(wbs_eth1_cfg_we_i),
      .wbs2_cyc_i			(wbs_eth1_cfg_cyc_i),
      .wbs2_stb_i			(wbs_eth1_cfg_stb_i),
      //.wbs2_cab_i			(),

      // Slave 3
      // Inputs
      .wbs3_dat_o			(wbs_spi_flash_dat_o),
      .wbs3_ack_o			(wbs_spi_flash_ack_o),
      .wbs3_err_o			(wbs_spi_flash_err_o),
      .wbs3_rty_o			(wbs_spi_flash_rty_o),
      // Outputs
      .wbs3_dat_i			(wbs_spi_flash_dat_i),
      .wbs3_adr_i			(wbs_spi_flash_adr_i),
      .wbs3_sel_i			(wbs_spi_flash_sel_i),
      .wbs3_we_i			(wbs_spi_flash_we_i),
      .wbs3_cyc_i			(wbs_spi_flash_cyc_i),
      .wbs3_stb_i			(wbs_spi_flash_stb_i),
      //.wbs3_cab_i			(),

      // Slave 4
      // Inputs
      .wbs4_dat_o			(wbs_uart0_dat_o),
      .wbs4_ack_o			(wbs_uart0_ack_o),
      .wbs4_err_o			(wbs_uart0_err_o),
      .wbs4_rty_o			(wbs_uart0_rty_o),
      // Outputs
      .wbs4_dat_i			(wbs_uart0_dat_i),
      .wbs4_adr_i			(wbs_uart0_adr_i),
      .wbs4_sel_i			(wbs_uart0_sel_i),
      .wbs4_we_i			(wbs_uart0_we_i),
      .wbs4_cyc_i			(wbs_uart0_cyc_i),
      .wbs4_stb_i			(wbs_uart0_stb_i),
      //.wbs4_cab_i			(),
      
      // Inputs
      .wb_clk			(wb_clk),
      .wb_rst			(wb_rst));
   

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
   OR1K_startup OR1K_startup0
     (
      .wb_adr_i(wbs_rom_adr_i[6:2]),
      .wb_stb_i(wbs_rom_stb_i),
      .wb_cyc_i(wbs_rom_cyc_i),
      .wb_dat_o(wbs_rom_dat_o),
      .wb_ack_o(wbs_rom_ack_o),
      .wb_clk(wb_clk),
      .wb_rst(wb_rst)
      );
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


`ifdef USE_SDRAM
   wb_sdram_ctrl wb_sdram_ctrl0
     (
      .wb_dat_i(wbs_mc_m_dat_i),
      .wb_dat_o(wbs_mc_m_dat_o),
      .wb_sel_i(wbs_mc_m_sel_i),
      .wb_adr_i(wbs_mc_m_adr_i[24:2]),
      .wb_we_i (wbs_mc_m_we_i),
      .wb_cti_i(wbs_mc_m_cti_i),
      .wb_stb_i(wbs_mc_m_stb_i),
      .wb_cyc_i(wbs_mc_m_cyc_i),
      .wb_ack_o(wbs_mc_m_ack_o),
      .sdr_cke_o(mem_cke_pad_o),   
      .sdr_cs_n_o(mem_cs_pad_o),  
      .sdr_ras_n_o(mem_ras_pad_o), 
      .sdr_cas_n_o(mem_cas_pad_o), 
      .sdr_we_n_o(mem_we_pad_o),  
      .sdr_a_o(mem_adr_pad_o),
      .sdr_ba_o(mem_ba_pad_o),
      .sdr_dq_io(mem_dat_pad_io),
      .sdr_dqm_o(mem_dqm_pad_o),
      .sdram_clk(wb_clk),
      .wb_clk(wb_clk),
      .wb_rst(wb_rst)
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
   
`else // !`ifdef USE_SDRAM


   parameter ram_wb_dat_width = 32;
   parameter ram_wb_adr_width = 25;
   //parameter ram_wb_mem_size  = 2097152; // 8MB
   parameter ram_wb_mem_size  = 8388608; // 32MB -- for linux test
   /*
   ram_wb
     #
     (
      .dat_width(ram_wb_dat_width),
      .adr_width(ram_wb_adr_width),
      .mem_size(ram_wb_mem_size)
      )
   ram_wb0
     (
      .dat_i(wbs_mc_m_dat_i),
      .dat_o(wbs_mc_m_dat_o),
      .sel_i(wbs_mc_m_sel_i),
      .adr_i(wbs_mc_m_adr_i[ram_wb_adr_width-1:2]),
      .we_i (wbs_mc_m_we_i),
      .cti_i(wbs_mc_m_cti_i),
      .stb_i(wbs_mc_m_stb_i),
      .cyc_i(wbs_mc_m_cyc_i),
      .ack_o(wbs_mc_m_ack_o),
      .clk_i(wb_clk),
      .rst_i(wb_rst)
      );
    */

   // New Wishbone B3 RAM
   wb_ram_b3
     #
     (
      .dw(ram_wb_dat_width),
      .aw(ram_wb_adr_width),
      .mem_size(ram_wb_mem_size)
      )
   ram_wb0
     (
      .wb_dat_i(wbs_mc_m_dat_i),
      .wb_dat_o(wbs_mc_m_dat_o),
      .wb_sel_i(wbs_mc_m_sel_i),
      .wb_adr_i(wbs_mc_m_adr_i[ram_wb_adr_width-1:0]),
      .wb_we_i (wbs_mc_m_we_i),
      .wb_bte_i(wbs_mc_m_bte_i),
      .wb_cti_i(wbs_mc_m_cti_i),
      .wb_stb_i(wbs_mc_m_stb_i),
      .wb_cyc_i(wbs_mc_m_cyc_i),
      .wb_ack_o(wbs_mc_m_ack_o),
      .wb_clk_i(wb_clk),
      .wb_rst_i(wb_rst)
      );

   
`endif // !`ifdef USE_SDRAM

   assign wbs_mc_m_err_o = 1'b0;

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
      .srx_pad_i  (uart0_srx_pad_i),
      .stx_pad_o  (uart0_stx_pad_o),
      .cts_pad_i  (1'b0),
      .rts_pad_o  ( ),
      .dtr_pad_o  ( ),
      .dcd_pad_i  (1'b0),
      .dsr_pad_i  (1'b0),
      .ri_pad_i   (1'b0)
      );
   assign gpio_a_pad_io[7:0] = 8'hfe;

`ifdef USE_ETHERNET   
   wire 	   m1tx_clk;
   wire [3:0] 	   m1txd;
   wire 	   m1txen;
   wire 	   m1txerr;
   wire 	   m1rx_clk;
   wire [3:0] 	   m1rxd;
   wire 	   m1rxdv;
   wire 	   m1rxerr;
   wire 	   m1coll;
   wire 	   m1crs;   
   wire [10:1] 	   state;
   wire 	   sync;
   wire [1:1] 	   rx, tx;
   wire [1:1] 	   mdc_o, md_i, md_o, md_oe;
   smii_sync smii_sync1
     (
      .sync(sync),
      .state(state),
      .clk(eth_clk),
      .rst(wb_rst)
      );
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
      .mtx_clk_pad_i(m1tx_clk),
      .mtxd_pad_o(m1txd),
      .mtxen_pad_o(m1txen),
      .mtxerr_pad_o(m1txerr),
      .mrx_clk_pad_i(m1rx_clk),
      .mrxd_pad_i(m1rxd),
      .mrxdv_pad_i(m1rxdv),
      .mrxerr_pad_i(m1rxerr),
      .mcoll_pad_i(m1coll),
      .mcrs_pad_i(m1crs),
      .mdc_pad_o(mdc_o[1]),
      .md_pad_i(md_i[1]),
      .md_pad_o(md_o[1]),
      .md_padoe_o(md_oe[1]),
      .int_o(eth_int[1])
      );

 `ifdef USE_ETHERNET_IO
   iobuftri iobuftri1
     (
      .i(md_o[1]),
      .oe(md_oe[1]),
      .o(md_i[1]),
      .pad(eth_md_pad_io[1])
      );
   obuf obuf1
     (
      .i(mdc_o[1]),
      .pad(eth_mdc_pad_o[1])
      );
   smii_txrx smii_txrx1
     (
      .tx(tx[1]),
      .rx(rx[1]),
      .mtx_clk(m1tx_clk),
      .mtxd(m1txd),
      .mtxen(m1txen),
      .mtxerr(m1txerr),
      .mrx_clk(m1rx_clk),
      .mrxd(m1rxd),
      .mrxdv(m1rxdv),
      .mrxerr(m1rxerr),
      .mcoll(m1coll),
      .mcrs(m1crs),
      .state(state),
      .clk(eth_clk),
      .rst(wb_rst)
      );

   obufdff obufdff_sync1
     (
      .d(sync),
      .pad(eth_sync_pad_o[1]),
      .clk(eth_clk),
      .rst(wb_rst)
      );
   obufdff obufdff_tx1
     (
      .d(tx[1]),
      .pad(eth_tx_pad_o[1]),
      .clk(eth_clk),
      .rst(wb_rst)
      );
   ibufdff ibufdff_rx1
     (
      .pad(eth_rx_pad_i[1]),
      .q(rx[1]),
      .clk(eth_clk),
      .rst(wb_rst)
      );
 `endif // `ifdef USE_ETHERNET_IO

`else // !`ifdef USE_ETHERNET
   // If ethernet core is disabled, still ack anyone who tries
   // to access its config port. This allows linux to boot in
   // the verilated ORPSoC.
   reg 		   wbs_eth1_cfg_ack_r;
   always @(posedge wb_clk) 
     wbs_eth1_cfg_ack_r <= (wbs_eth1_cfg_cyc_i & wbs_eth1_cfg_stb_i);
   
   // Tie off WB arbitor inputs
   assign wbs_eth1_cfg_dat_o = 0;
   assign wbs_eth1_cfg_ack_o = wbs_eth1_cfg_ack_r;
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
   dummy_slave 
     # ( .value(32'hd0000000))
   ds2
     ( 
       .dat_o(wbs_ds2_dat_o), 
       .stb_i(wbs_ds2_stb_i), 
       .cyc_i(wbs_ds2_cyc_i), 
       .ack_o(wbs_ds2_ack_o), 
       .clk(wb_clk), 
       .rst(wb_rst) 
       );
   dummy_slave 
     # ( .value(32'he0000000))
   ds3
     ( 
       .dat_o(wbs_ds3_dat_o), 
       .stb_i(wbs_ds3_stb_i), 
       .cyc_i(wbs_ds3_cyc_i), 
       .ack_o(wbs_ds3_ack_o), 
       .clk(wb_clk), 
       .rst(wb_rst) 
       );
   /*
   clk_gen iclk_gen 
     (
      .POWERDOWN (1'b1),
      .CLKA (clk_pad_i),
      .LOCK (pll_lock),
      .GLA(wb_clk),
      .GLB(),
      .GLC()
      );
   */
   generic_pll iclk_gen
     (
      // Outputs
      .clk1x(wb_clk), 
      .clk2x(), 
      .clkdiv(), 
      .locked(pll_lock),
      // Inputs
      .clk_in(clk_pad_i), 
      .rst_in(~rst_pad_i)
      );
   

   assign rst_pad_o = pll_lock;
   assign wb_rst = ~(pll_lock & rst_pad_i);
   assign dbg_tck = dbg_tck_pad_i;
`ifdef USE_ETHERNET_IO   
   assign eth_clk = eth_clk_pad_i;
`else
   assign eth_clk = 0;   
`endif
   
endmodule
