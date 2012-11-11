# Pin assignments for Terasic SPI 0 port add on attached to JP1 (Flash SPI)

set_location_assignment PIN_E6 -to spi0_hold_n_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_hold_n_o
set_location_assignment PIN_D5 -to spi0_miso_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_miso_i
set_location_assignment PIN_D6 -to spi0_mosi_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_mosi_o
set_location_assignment PIN_C6 -to spi0_sck_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_sck_o
set_location_assignment PIN_A6 -to spi0_w_n_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_ss_o[0]
set_location_assignment PIN_B5 -to spi0_ss_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_w_n_o
