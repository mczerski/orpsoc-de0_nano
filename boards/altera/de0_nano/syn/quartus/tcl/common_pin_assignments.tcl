set_location_assignment PIN_J15 -to rst_n_pad_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to rst_n_pad_i
set_location_assignment PIN_R8 -to sys_clk_pad_i
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to sys_clk_pad_i
set_location_assignment PIN_G5 -to VCC

set_location_assignment PIN_G5 -to g_sensor_cs_n
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g_sensor_cs_n

set_location_assignment PIN_M2 -to g_sensor_int
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to g_sensor_int

