set_global_assignment -name RESERVE_FLASH_NCE_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DATA0_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DATA1_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_global_assignment -name RESERVE_DCLK_AFTER_CONFIGURATION "USE AS REGULAR IO"
set_location_assignment PIN_C1 -to spi0_mosi_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_mosi_o
set_location_assignment PIN_H2 -to spi0_miso_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_miso_i
set_location_assignment PIN_H1 -to spi0_sck_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_sck_o
set_location_assignment PIN_D2 -to spi0_ss_o[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to spi0_ss_o[0]

