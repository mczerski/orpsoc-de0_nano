create_generated_clock -name sd_clk -source {clkgen0|pll0|altpll_component|auto_generated|pll1|clk[1]} -divide_by 2 [get_registers {sdc_controller:sdc_controller_0|sd_clock_divider:clock_divider_1|SD_CLK_O}]
set_clock_groups -exclusive -group {sd_clk} -group {clkgen0|pll0|altpll_component|auto_generated|pll1|clk[1]}
