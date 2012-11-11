# Pin assignments for Terasic touch-LCD add on attached to JP1

set_location_assignment PIN_F13 -to vga0_hsync_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_hsync_pad_o
set_location_assignment PIN_T15 -to vga0_vsync_pad_o
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_vsync_pad_o

# Red pixel data
set_location_assignment PIN_P14 -to vga0_r_pad_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_r_pad_o[4]
set_location_assignment PIN_N16 -to vga0_r_pad_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_r_pad_o[5]
set_location_assignment PIN_P16 -to vga0_r_pad_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_r_pad_o[6]
set_location_assignment PIN_L15 -to vga0_r_pad_o[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_r_pad_o[7]

# Blue pixel data
set_location_assignment PIN_R11 -to vga0_b_pad_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_b_pad_o[4]
set_location_assignment PIN_T11 -to vga0_b_pad_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_b_pad_o[5]
set_location_assignment PIN_T12 -to vga0_b_pad_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_b_pad_o[6]
set_location_assignment PIN_T13 -to vga0_b_pad_o[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_b_pad_o[7]

# Green pixel data
set_location_assignment PIN_K16 -to vga0_g_pad_o[4]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_g_pad_o[4]
set_location_assignment PIN_N11 -to vga0_g_pad_o[5]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_g_pad_o[5]
set_location_assignment PIN_P9 -to vga0_g_pad_o[6]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_g_pad_o[6]
set_location_assignment PIN_R10 -to vga0_g_pad_o[7]
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to vga0_g_pad_o[7]
