# Pin assignments for Terasic ETH 0 port add on attached to JP1

set_location_assignment PIN_T9 -to eth0_crs
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_col
set_location_assignment PIN_R9 -to eth0_col
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_crs
set_location_assignment PIN_G15 -to eth0_tx_data[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_dv
set_location_assignment PIN_G16 -to eth0_tx_data[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_md_pad_io
set_location_assignment PIN_F16 -to eth0_tx_data[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_mdc_pad_o
set_location_assignment PIN_D14 -to eth0_tx_data[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_rx_clk
set_location_assignment PIN_D16 -to eth0_tx_en
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_rx_data[3]
set_location_assignment PIN_C16 -to eth0_tx_clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_rx_data[2]
set_location_assignment PIN_B16 -to eth0_tx_er
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_rx_data[1]
set_location_assignment PIN_M16 -to eth0_rx_er
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_rx_data[0]
set_location_assignment PIN_E15 -to eth0_rx_clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_rx_er
set_location_assignment PIN_E16 -to eth0_dv
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_tx_clk
set_location_assignment PIN_A14 -to eth0_rx_data[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_tx_data[3]
set_location_assignment PIN_C14 -to eth0_rx_data[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_tx_data[2]
set_location_assignment PIN_C15 -to eth0_rx_data[2]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_tx_data[1]
set_location_assignment PIN_D15 -to eth0_rx_data[3]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_tx_data[0]
set_location_assignment PIN_F15 -to eth0_mdc_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_tx_en
set_location_assignment PIN_F14 -to eth0_md_pad_io
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to eth0_tx_er
