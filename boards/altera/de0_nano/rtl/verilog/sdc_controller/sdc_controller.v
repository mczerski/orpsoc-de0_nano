`include "sd_defines.v"
//////////////////////////////////////////////////////////////////////
////                                                              ////
////  sd_controller.v                                             ////
////                                                              ////
////  This file is part of the SD Card IP core project            ////
////  http://www.opencores.org/?do=project&who=sdcard_mass_storage_controller  ////
////                                                              ////
////  Author(s):                                                  ////
////      - Adam Edvardsson (adam.edvardsson@orsoc.se)            ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2009 Authors                                   ////
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

module sdc_controller(
           // WISHBONE common
           wb_clk_i, wb_rst_i, wb_dat_i, wb_dat_o,
           // WISHBONE slave
           wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i, wb_ack_o,
           // WISHBONE master
           m_wb_adr_o, m_wb_sel_o, m_wb_we_o,
           m_wb_dat_o, m_wb_dat_i, m_wb_cyc_o,
           m_wb_stb_o, m_wb_ack_i,
           m_wb_cti_o, m_wb_bte_o,
           //SD BUS
           sd_cmd_dat_i,sd_cmd_out_o, sd_cmd_oe_o, //card_detect,
           sd_dat_dat_i, sd_dat_out_o, sd_dat_oe_o, sd_clk_o_pad,
           sd_clk_i_pad,
           int_a, int_b, int_c
       );

input wb_clk_i;
input wb_rst_i;
input [31:0] wb_dat_i;
output [31:0] wb_dat_o;
//input card_detect;
input [7:0] wb_adr_i;
input [3:0] wb_sel_i;
input wb_we_i;
input wb_cyc_i;
input wb_stb_i;
output wb_ack_o;
output [31:0] m_wb_adr_o;
output [3:0] m_wb_sel_o;
output m_wb_we_o;
input [31:0] m_wb_dat_i;
output [31:0] m_wb_dat_o;
output m_wb_cyc_o;
output m_wb_stb_o;
input m_wb_ack_i;
output [2:0] m_wb_cti_o;
output [1:0] m_wb_bte_o;
input wire [3:0] sd_dat_dat_i;
output wire [3:0] sd_dat_out_o;
output wire sd_dat_oe_o;
input wire sd_cmd_dat_i;
output wire sd_cmd_out_o;
output wire sd_cmd_oe_o;
output sd_clk_o_pad;
input wire sd_clk_i_pad;
output int_a, int_b, int_c;

//SD clock
wire sd_clk_i; //Sd_clk provided to the system
wire sd_clk_o; //Sd_clk used in the system

wire go_idle;
wire cmd_start;
wire [1:0] cmd_setting;
wire cmd_start_tx;
wire [39:0] cmd;
wire [119:0] cmd_response;
wire cmd_crc_ok;
wire cmd_index_ok;
wire cmd_finish;

wire d_write;
wire d_read;
wire [31:0] data_in_rx_fifo;
wire [31:0] data_out_tx_fifo;
wire start_tx_fifo;
wire start_rx_fifo;
wire tx_fifo_empty;
wire tx_fifo_full;
wire rx_fifo_full;
wire data_busy;
wire data_crc_ok;
wire rd_fifo;
wire we_fifo;

wire data_start_rx;
wire data_start_tx;
wire cmd_int_rst;
wire data_int_rst;

//wb accessible registers
wire [31:0] argument_reg;
wire [13:0] command_reg;
wire [15:0] timeout_reg;
wire [0:0] software_reset_reg;
wire [15:0] time_out_reg;
wire [31:0] response_0_reg;
wire [31:0] response_1_reg;
wire [31:0] response_2_reg;
wire [31:0] response_3_reg;
wire [11:0] block_size_reg;
wire [15:0] controll_setting_reg;
wire [4:0] cmd_int_status_reg;
wire [2:0] data_int_status_reg;
wire [4:0] cmd_int_enable_reg;
wire [2:0] data_int_enable_reg;
wire [`BLKCNT_W-1:0] block_count_reg;
wire [31:0] dma_addr_reg;
wire [7:0] clock_divider_reg;

//sd_clk_o to be used i set here
`ifdef SDC_CLK_BUS_CLK
assign sd_clk_i = wb_clk_i;
`endif 
`ifdef SDC_CLK_SEP
assign sd_clk_i = sd_clk_i_pad;
`endif
`ifdef SDC_CLK_STATIC
assign sd_clk_o = sd_clk_i;
`endif
`ifdef SDC_CLK_DYNAMIC
sd_clock_divider clock_divider_1(
                     .CLK (sd_clk_i),
                     .DIVIDER (clock_divider_reg),
                     .RST  (wb_rst_i | software_reset_reg[0]),
                     .SD_CLK  (sd_clk_o)
                 );
`endif

assign sd_clk_o_pad  = sd_clk_o ;

sd_cmd_master sd_cmd_master0(
           .sd_clk       (sd_clk_o),
           .rst          (wb_rst_i | software_reset_reg[0]),
           .start_i      (cmd_start),
           .int_status_rst_i(cmd_int_rst),
           .setting_o    (cmd_setting),
           .start_xfr_o  (cmd_start_tx),
           .go_idle_o    (go_idle),
           .cmd_o        (cmd),
           .response_i   (cmd_response),
           .crc_ok_i     (cmd_crc_ok),
           .index_ok_i   (cmd_index_ok),
           .busy_i       (!sd_dat_dat_i[0]),
           .finish_i     (cmd_finish),
           //input card_detect,
           .argument_i   (argument_reg),
           .command_i    (command_reg),
           .timeout_i    (timeout_reg),
           .int_status_o (cmd_int_status_reg),
           .response_0_o (response_0_reg),
           .response_1_o (response_1_reg),
           .response_2_o (response_2_reg),
           .response_3_o (response_3_reg)
       );
       
sd_cmd_serial_host cmd_serial_host0(
                       .sd_clk     (sd_clk_o),
                       .rst        (wb_rst_i | software_reset_reg[0] | go_idle),
                       .setting_i  (cmd_setting),
                       .cmd_i      (cmd),
                       .start_i    (cmd_start_tx),
                       .finish_o   (cmd_finish),
                       .response_o (cmd_response),
                       .crc_ok_o   (cmd_crc_ok),
                       .index_ok_o (cmd_index_ok),
                       .cmd_dat_i  (sd_cmd_dat_i),
                       .cmd_out_o  (sd_cmd_out_o),
                       .cmd_oe_o   (sd_cmd_oe_o)
                   );
                   
sd_data_master sd_data_master0(
           .sd_clk           (sd_clk_o),
           .rst              (wb_rst_i | software_reset_reg[0]),
           .start_tx_i       (data_start_tx),
           .start_rx_i       (data_start_rx),
           .d_write_o        (d_write),
           .d_read_o         (d_read),
           .start_tx_fifo_o  (start_tx_fifo),
           .start_rx_fifo_o  (start_rx_fifo),
           .tx_fifo_empty_i  (tx_fifo_empty),
           .tx_fifo_full_i   (tx_fifo_full),
           .rx_fifo_full_i   (rx_fifo_full),
           .xfr_complete_i   (!data_busy),
           .crc_ok_i         (data_crc_ok),
           .int_status_o     (data_int_status_reg),
           .int_status_rst_i (data_int_rst)
       );

sd_data_serial_host sd_data_serial_host0(
                        .sd_clk         (sd_clk_o),
                        .rst            (wb_rst_i | software_reset_reg[0]),
                        .data_in        (data_out_tx_fifo),
                        .rd             (rd_fifo),
                        .data_out       (data_in_rx_fifo),
                        .we             (we_fifo),
                        .DAT_oe_o       (sd_dat_oe_o),
                        .DAT_dat_o      (sd_dat_out_o),
                        .DAT_dat_i      (sd_dat_dat_i),
                        .blksize        (block_size_reg),
                        .bus_4bit       (controll_setting_reg[0]),
                        .blkcnt         (block_count_reg),
                        .start          ({d_read, d_write}),
                        .busy           (data_busy),
                        .crc_ok         (data_crc_ok)
                    );
       
sd_fifo_filler sd_fifo_filler0(
            .wb_clk    (wb_clk_i),
            .rst       (wb_rst_i | software_reset_reg[0]),
            .wbm_adr_o (m_wb_adr_o),
            .wbm_we_o  (m_wb_we_o),
            .wbm_dat_o (m_wb_dat_o),
            .wbm_dat_i (m_wb_dat_i),
            .wbm_cyc_o (m_wb_cyc_o),
            .wbm_stb_o (m_wb_stb_o),
            .wbm_ack_i (m_wb_ack_i),
            .en_rx_i   (start_rx_fifo),
            .en_tx_i   (start_tx_fifo),
            .adr_i     (dma_addr_reg),
            .sd_clk    (sd_clk_o),
            .dat_i     (data_in_rx_fifo),
            .dat_o     (data_out_tx_fifo),
            .wr_i      (we_fifo),
            .rd_i      (rd_fifo),
            .sd_empty_o   (tx_fifo_empty),
            .sd_full_o   (rx_fifo_full),
            .wb_empty_o   (),
            .wb_full_o    (tx_fifo_full)
        );

sd_controller_wb sd_controller_wb0(
                     .wb_clk_i                       (wb_clk_i),
                     .wb_rst_i                       (wb_rst_i),
                     .wb_dat_i                       (wb_dat_i),
                     .wb_dat_o                       (wb_dat_o),
                     .wb_adr_i                       (wb_adr_i),
                     .wb_sel_i                       (wb_sel_i),
                     .wb_we_i                        (wb_we_i),
                     .wb_stb_i                       (wb_stb_i),
                     .wb_cyc_i                       (wb_cyc_i),
                     .wb_ack_o                       (wb_ack_o),
                     .cmd_start                      (cmd_start),
                     .data_start_tx                  (data_start_tx),
                     .data_start_rx                  (data_start_rx),
                     .data_int_rst                   (data_int_rst),
                     .cmd_int_rst                    (cmd_int_rst),
                     .argument_reg                   (argument_reg),
                     .command_reg                    (command_reg),
                     .response_0_reg                 (response_0_reg),
                     .response_1_reg                 (response_1_reg),
                     .response_2_reg                 (response_2_reg),
                     .response_3_reg                 (response_3_reg),
                     .software_reset_reg             (software_reset_reg),
                     .timeout_reg                    (timeout_reg),
                     .block_size_reg                 (block_size_reg),
                     .controll_setting_reg           (controll_setting_reg),
                     .cmd_int_status_reg             (cmd_int_status_reg),
                     .cmd_int_enable_reg             (cmd_int_enable_reg),
                     .clock_divider_reg              (clock_divider_reg),
                     .block_count_reg                (block_count_reg),
                     .dma_addr_reg                   (dma_addr_reg),
                     .data_int_status_reg            (data_int_status_reg),
                     .data_int_enable_reg            (data_int_enable_reg)
                 );

assign m_wb_cti_o = 3'b000;
assign m_wb_bte_o = 2'b00;

`ifdef SDC_IRQ_ENABLE
assign int_a =  |(cmd_int_status_reg & cmd_int_enable_reg);
assign int_b =  |(data_int_status_reg & data_int_enable_reg);
assign int_c =  0;
`else
assign int_a = 0;
assign int_b = 0;
assign int_c = 0;
`endif

assign m_wb_sel_o = 4'b1111;

endmodule
