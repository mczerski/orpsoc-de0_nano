# Pin assignments for Terasic USB 0 port add on attached to JP1

set_location_assignment PIN_C3 -to usb0dat_pad_io[0]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb0dat_pad_io[0]
set_location_assignment PIN_A3 -to usb0dat_pad_io[1]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb0dat_pad_io[1]
set_location_assignment PIN_D3 -to usb0ctrl_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb0ctrl_pad_o
set_location_assignment PIN_B4 -to usb0fullspeed_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to usb0fullspeed_pad_o

