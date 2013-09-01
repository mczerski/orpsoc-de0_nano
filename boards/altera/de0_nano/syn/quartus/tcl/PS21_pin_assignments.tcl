# Pin assignments for Terasic PS2 1 port add on attached to JP1

set_location_assignment PIN_E9 -to ps21_dat
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ps21_dat
set_location_assignment PIN_D9 -to ps21_clk
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ps21_clk

