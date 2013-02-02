create_clock -name "eth0_tx_clk"  -period 40.000ns  [get_ports {eth0_tx_clk}] 
create_clock -name "eth0_rx_clk"  -period 40.000ns  [get_ports {eth0_rx_clk}] 