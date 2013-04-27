`include "sd_defines.v"

module sd_fifo_filler(
           input wb_clk,
           input rst,
           //WB Signals
           output [31:0] wbm_adr_o,
           output wbm_we_o,
           output [31:0] wbm_dat_o,
           input [31:0] wbm_dat_i,
           output wbm_cyc_o,
           output wbm_stb_o,
           input wbm_ack_i,
           //Data Master Control signals
           input en_rx_i,
           input en_tx_i,
           input [31:0] adr_i,
           //Data Serial signals
           input sd_clk,
           input [31:0] dat_i,
           output [31:0] dat_o,
           input wr_i,
           input rd_i,
           output sd_full_o,
           output sd_empty_o,
           output wb_full_o,
           output wb_empty_o
       );

wire reset_fifo;
wire fifo_rd;
reg [31:0] offset;
reg fifo_rd_ack;
reg fifo_rd_reg;

assign fifo_rd = wbm_cyc_o & wbm_ack_i;
assign reset_fifo = !en_rx_i & !en_tx_i;

assign wbm_we_o = en_rx_i & !wb_empty_o;
assign wbm_cyc_o = en_rx_i ? en_rx_i & !wb_empty_o : en_tx_i & !wb_full_o;
assign wbm_stb_o = en_rx_i ? wbm_cyc_o & fifo_rd_ack : wbm_cyc_o;

sd_async_fifo #(32, `FIFO_RX_MEM_ADR_SIZE) fifo (
    .a_d(dat_i),
    .a_wr(wr_i),
    .a_fifo_full(sd_full_o),
    .a_q(dat_o),
    .a_rd(rd_i),
    .a_fifo_empty(sd_empty_o),
    .a_clk(sd_clk),
    .a_rst(rst | reset_fifo),
    .b_d(wbm_dat_i),
    .b_wr(en_tx_i & wbm_cyc_o & wbm_stb_o & wbm_ack_i),
    .b_fifo_full(wb_full_o),
    .b_q(wbm_dat_o),
    .b_rd(en_rx_i & wbm_cyc_o & wbm_ack_i),
    .b_fifo_empty(wb_empty_o),
    .b_clk(wb_clk),
    .b_rst(rst | reset_fifo)
    );

assign wbm_adr_o = adr_i+offset;

always @(posedge wb_clk or posedge rst)
    if (rst) begin
        offset <= 0;
        fifo_rd_reg <= 0;
        fifo_rd_ack <= 1;
    end
    else begin
        fifo_rd_reg <= fifo_rd;
        fifo_rd_ack <= fifo_rd_reg | !fifo_rd;
        if (wbm_cyc_o & wbm_stb_o & wbm_ack_i)
            offset <= offset + `MEM_OFFSET;
        else if (reset_fifo)
            offset <= 0;
    end

endmodule


