create_clock -name "eth0_tx_clk"  -period 40.000ns  [get_ports {eth0_tx_clk}] 
create_clock -name "eth0_rx_clk"  -period 40.000ns  [get_ports {eth0_rx_clk}]
set_false_path -from [get_clocks {clkgen0|pll0|altpll_component|auto_generated|pll1|clk[1]}] -to [get_clocks {eth0_tx_clk}]
set_false_path -from [get_clocks {clkgen0|pll0|altpll_component|auto_generated|pll1|clk[1]}] -to [get_clocks {eth0_rx_clk}]
