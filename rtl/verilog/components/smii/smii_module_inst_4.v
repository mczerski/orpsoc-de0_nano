`for (i=1;i<=SMII;i++)
wire 	     m::`i::tx_clk;
wire [3:0] 	     m::`i::txd;
wire 	     m::`i::txen;
wire 	     m::`i::txerr;
wire 	     m::`i::rx_clk;
wire [3:0] 	     m::`i::rxd;
wire 	     m::`i::rxdv;
wire 	     m::`i::rxerr;
wire 	     m::`i::coll;
wire 	     m::`i::crs;   
`endfor
wire [1:10] 	     state;   
wire              sync;
wire [1:4]    rx, tx;
wire [1:4]    mdc_o, md_i, md_o, md_oe;
smii_sync smii_sync1
  (
   .sync(sync),
   .state(state),
   .clk(eth_clk),
   .rst(wb_rst)
   );
obufdff obufdff_sync
  (
   .d(sync),
   .pad(eth_sync_pad_o),
   .clk(eth_clk),
   .rst(wb_rst)
   );
`for (i=1;i<=SMII;i++)
eth_top eth_top::`i
	(
	 .wb_clk_i(wb_clk),
	 .wb_rst_i(wb_rst),
	 .wb_dat_i(wbs_eth::`i::_cfg_dat_i),
	 .wb_dat_o(wbs_eth::`i::_cfg_dat_o),
	 .wb_adr_i(wbs_eth::`i::_cfg_adr_i[11:2]),
	 .wb_sel_i(wbs_eth::`i::_cfg_sel_i),
	 .wb_we_i(wbs_eth::`i::_cfg_we_i),
	 .wb_cyc_i(wbs_eth::`i::_cfg_cyc_i),
	 .wb_stb_i(wbs_eth::`i::_cfg_stb_i),
	 .wb_ack_o(wbs_eth::`i::_cfg_ack_o),
	 .wb_err_o(wbs_eth::`i::_cfg_err_o),
	 .m_wb_adr_o(wbm_eth::`i::_adr_o),
	 .m_wb_sel_o(wbm_eth::`i::_sel_o),
	 .m_wb_we_o(wbm_eth::`i::_we_o),
	 .m_wb_dat_o(wbm_eth::`i::_dat_o),
	 .m_wb_dat_i(wbm_eth::`i::_dat_i),
	 .m_wb_cyc_o(wbm_eth::`i::_cyc_o),
	 .m_wb_stb_o(wbm_eth::`i::_stb_o),
	 .m_wb_ack_i(wbm_eth::`i::_ack_i),
	 .m_wb_err_i(wbm_eth::`i::_err_i),
	 .m_wb_cti_o(wbm_eth::`i::_cti_o),
	 .m_wb_bte_o(wbm_eth::`i::_bte_o),
	 .mtx_clk_pad_i(m::`i::tx_clk),
	 .mtxd_pad_o(m::`i::txd),
	 .mtxen_pad_o(m::`i::txen),
	 .mtxerr_pad_o(m::`i::txerr),
	 .mrx_clk_pad_i(m::`i::rx_clk),
	 .mrxd_pad_i(m::`i::rxd),
	 .mrxdv_pad_i(m::`i::rxdv),
	 .mrxerr_pad_i(m::`i::rxerr),
	 .mcoll_pad_i(m::`i::coll),
	 .mcrs_pad_i(m::`i::crs),
	 .mdc_pad_o(mdc_o[`i]),
	 .md_pad_i(md_i[`i]),
	 .md_pad_o(md_o[`i]),
	 .md_padoe_o(md_oe[`i]),
	 .int_o(eth_int[`i])
	 );
iobuftri iobuftri::`i
  (
   .i(md_o[`i]),
   .oe(md_oe[`i]),
   .o(md_i[`i]),
   .pad(eth_md_pad_io[`i])
   );
obuf obuf::`i
  (
   .i(mdc_o[`i]),
   .pad(eth_mdc_pad_o[`i])
   );
smii_txrx smii_txrx::`i
  (
   .tx(tx[`i]),
   .rx(rx[`i]),
   .mtx_clk(m::`i::tx_clk),
   .mtxd(m::`i::txd),
   .mtxen(m::`i::txen),
   .mtxerr(m::`i::txerr),
   .mrx_clk(m::`i::rx_clk),
   .mrxd(m::`i::rxd),
   .mrxdv(m::`i::rxdv),
   .mrxerr(m::`i::rxerr),
   .mcoll(m::`i::coll),
   .mcrs(m::`i::crs),
   .state(state),
   .clk(eth_clk),
   .rst(wb_rst)
   );
obufdff obufdff_tx::`i
  (
   .d(tx[`i]),
   .pad(eth_tx_pad_o[`i]),
   .clk(eth_clk),
   .rst(wb_rst)
   );
ibufdff ibufdff_rx::`i
  (
   .pad(eth_rx_pad_i[`i]),
   .q(rx[`i]),
   .clk(eth_clk),
   .rst(wb_rst)
   );
`endfor
