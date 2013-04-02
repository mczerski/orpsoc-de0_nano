create_generated_clock -name "sd_clk" -source [get_nets {wb_clk}] -divide_by 2 [get_registers {sdc_controller:sdc_controller_0|sd_clock_divider:clock_divider_1|SD_CLK_O}]
