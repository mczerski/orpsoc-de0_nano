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

wire spi_flash_mosi, spi_flash_miso, spi_flash_sclk;
wire [1:0] spi_flash_ss;

spi_flash_top #
  (
   .divider(`SPI_FLASH_DIVIDER),
   .divider_len(`SPI_FLASH_DIVIDER_LEN)
   )
spi_flash_top0
  (
   // Wishbone signals
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
   // SPI signals
   .mosi_pad_o(spi_flash_mosi),
   .miso_pad_i(spi_flash_miso),
   .sclk_pad_o(spi_flash_sclk),
   .ss_pad_o(spi_flash_ss)
   );

// external SPI FLASH
assign spi_flash_mosi_pad_o = !spi_flash_ss[0] ? spi_flash_mosi : 1'b1;
assign spi_flash_sclk_pad_o = !spi_flash_ss[0] ? spi_flash_sclk : 1'b1;
assign spi_flash_ss_pad_o   =  spi_flash_ss[0];
assign spi_flash_w_n_pad_o    = 1'b1;
assign spi_flash_hold_n_pad_o = 1'b1;

// external SD FLASH in SPI mode
assign spi_sd_mosi_pad_o = !spi_flash_ss[1] ? spi_flash_mosi : 1'b1;
assign spi_sd_sclk_pad_o = !spi_flash_ss[1] ? spi_flash_sclk : 1'b1;
assign spi_sd_ss_pad_o   =  spi_flash_ss[1];

// input mux
assign spi_flash_miso = !spi_flash_ss[0] ? spi_flash_miso_pad_i :
			!spi_flash_ss[1] ? spi_sd_miso_pad_i :
			1'b0;
