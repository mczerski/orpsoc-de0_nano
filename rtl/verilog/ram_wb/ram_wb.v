module ram_wb
  (
   // Inputs
   wbm0_adr_i, wbm0_bte_i, wbm0_cti_i, wbm0_cyc_i, wbm0_dat_i, wbm0_sel_i, 
   wbm0_stb_i, wbm0_we_i,
   // Outputs
   wbm0_ack_o, wbm0_err_o, wbm0_rty_o, wbm0_dat_o,
  
   // Inputs
   wbm1_adr_i, wbm1_bte_i, wbm1_cti_i, wbm1_cyc_i, wbm1_dat_i, wbm1_sel_i, 
   wbm1_stb_i, wbm1_we_i,
   // Outputs
   wbm1_ack_o, wbm1_err_o, wbm1_rty_o, wbm1_dat_o,

   // Clock, reset
   wb_clk_i, wb_rst_i
   );
   // Bus parameters
   parameter dw = 32;
   parameter aw = 32;
   // Memory parameters
   parameter mem_span = 32'h0000_0400;
   parameter adr_width_for_span = 11; //(log2(mem_span));


   input [aw-1:0]	wbm0_adr_i;
   input [1:0] 		wbm0_bte_i;
   input [2:0] 		wbm0_cti_i;
   input 		wbm0_cyc_i;
   input [dw-1:0] 	wbm0_dat_i;
   input [3:0] 		wbm0_sel_i;
   input 		wbm0_stb_i;
   input 		wbm0_we_i;
   
   output 		wbm0_ack_o;
   output 		wbm0_err_o;
   output 		wbm0_rty_o;
   output [dw-1:0] 	wbm0_dat_o;

   input [aw-1:0]	wbm1_adr_i;
   input [1:0] 		wbm1_bte_i;
   input [2:0] 		wbm1_cti_i;
   input 		wbm1_cyc_i;
   input [dw-1:0] 	wbm1_dat_i;
   input [3:0] 		wbm1_sel_i;
   input 		wbm1_stb_i;
   input 		wbm1_we_i;
   
   output 		wbm1_ack_o;
   output 		wbm1_err_o;
   output 		wbm1_rty_o;
   output [dw-1:0] 	wbm1_dat_o;
   

   input 		wb_clk_i;
   input 		wb_rst_i;

   // Internal wires to actual RAM
   wire [aw-1:0] 	wb_ram_adr_i;
   wire [1:0] 		wb_ram_bte_i;
   wire [2:0] 		wb_ram_cti_i;
   wire 		wb_ram_cyc_i;
   wire [dw-1:0] 	wb_ram_dat_i;
   wire [3:0] 		wb_ram_sel_i;
   wire 		wb_ram_stb_i;
   wire 		wb_ram_we_i;
   
   wire 		wb_ram_ack_o;
   wire 		wb_ram_err_o;
   wire 		wb_ram_rty_o;
   wire [dw-1:0] 	wb_ram_dat_o;

   reg [1:0] 		input_select, last_selected;
   wire 		arb_for_wbm0, arb_for_wbm1;
   // Wires allowing selection of new input
   assign arb_for_wbm0 = (last_selected[1] | !wbm1_cyc_i) & !(|input_select);
   assign arb_for_wbm1 = (last_selected[0] | !wbm0_cyc_i) & !(|input_select);
   
   // Master select logic
   always @(posedge wb_clk_i)
     if (wb_rst_i)
       input_select <= 0;
     else if ((input_select[0] & !wbm0_cyc_i) | (input_select[1] & !wbm1_cyc_i))
       input_select <= 0;
     else if (!(&input_select) & wbm0_cyc_i & arb_for_wbm0)
       input_select <= 2'b01;
     else if (!(&input_select) & wbm1_cyc_i & arb_for_wbm1)
       input_select <= 2'b10;
   
   always @(posedge wb_clk_i)
     if (wb_rst_i)
       last_selected <= 0;
     else if (!(&input_select) & wbm0_cyc_i & arb_for_wbm0)
       last_selected <= 2'b01;
     else if (!(&input_select) & wbm1_cyc_i & arb_for_wbm1)
       last_selected <= 2'b10;

   // Mux input signals to RAM (default to wbm0)
   assign wb_ram_adr_i = (input_select[1]) ? wbm1_adr_i : 
			 (input_select[0]) ? wbm0_adr_i : 0;
   assign wb_ram_bte_i = (input_select[1]) ? wbm1_bte_i : 
			 (input_select[0]) ? wbm0_bte_i : 0;
   assign wb_ram_cti_i = (input_select[1]) ? wbm1_cti_i : 
			 (input_select[0]) ? wbm0_cti_i : 0;
   assign wb_ram_cyc_i = (input_select[1]) ? wbm1_cyc_i : 
			 (input_select[0]) ? wbm0_cyc_i : 0;
   assign wb_ram_dat_i = (input_select[1]) ? wbm1_dat_i : 
			 (input_select[0]) ? wbm0_dat_i : 0;
   assign wb_ram_sel_i = (input_select[1]) ? wbm1_sel_i : 
			 (input_select[0]) ? wbm0_sel_i : 0;
   assign wb_ram_stb_i = (input_select[1]) ? wbm1_stb_i : 
			 (input_select[0]) ? wbm0_stb_i : 0;
   assign wb_ram_we_i  = (input_select[1]) ? wbm1_we_i  : 
			 (input_select[0]) ? wbm0_we_i : 0;

   // Output from RAM, gate the ACK, ERR, RTY signals appropriately
   assign wbm0_dat_o = wb_ram_dat_o;
   assign wbm0_ack_o = wb_ram_ack_o & input_select[0];
   assign wbm0_err_o = wb_ram_err_o & input_select[0];
   assign wbm0_rty_o = wb_ram_rty_o & input_select[0];

   assign wbm1_dat_o = wb_ram_dat_o;
   assign wbm1_ack_o = wb_ram_ack_o & input_select[1];
   assign wbm1_err_o = wb_ram_err_o & input_select[1];
   assign wbm1_rty_o = wb_ram_rty_o & input_select[1];
   
   ram_wb_b3 ram_wb_b3_0
     (
      // Outputs
      .wb_ack_o				(wb_ram_ack_o),
      .wb_err_o				(wb_ram_err_o),
      .wb_rty_o				(wb_ram_rty_o),
      .wb_dat_o				(wb_ram_dat_o),
      // Inputs
      .wb_adr_i				(wb_ram_adr_i),
      .wb_bte_i				(wb_ram_bte_i),
      .wb_cti_i				(wb_ram_cti_i),
      .wb_cyc_i				(wb_ram_cyc_i),
      .wb_dat_i				(wb_ram_dat_i),
      .wb_sel_i				(wb_ram_sel_i),
      .wb_stb_i				(wb_ram_stb_i),
      .wb_we_i				(wb_ram_we_i),
      .wb_clk_i				(wb_clk_i),
      .wb_rst_i				(wb_rst_i));

   defparam ram_wb_b3_0.aw = aw;
   defparam ram_wb_b3_0.dw = dw;
   defparam ram_wb_b3_0.mem_span = mem_span;
   defparam ram_wb_b3_0.adr_width_for_span = adr_width_for_span;

endmodule // ram_wb


