/* 
 * Wrapper for Xilinx MIG'd DDR2 controller
 * The DDR2 controller have 4 wishbone slave interfaces,
 * if more masters than that is needed, arbiters have to be added
 */

module xilinx_ddr2
  (
   // Inputs
    input  [31:0] wbm0_adr_i, 
    input  [1:0]  wbm0_bte_i, 
    input  [2:0]  wbm0_cti_i, 
    input 	      wbm0_cyc_i, 
    input  [31:0] wbm0_dat_i, 
    input  [3:0]  wbm0_sel_i,
  
    input 	      wbm0_stb_i, 
    input 	      wbm0_we_i,
  
   // Outputs
    output 	      wbm0_ack_o, 
    output 	      wbm0_err_o, 
    output 	      wbm0_rty_o, 
    output [31:0] wbm0_dat_o,
  
  
   // Inputs
    input [31:0]  wbm1_adr_i, 
    input [1:0]   wbm1_bte_i, 
    input [2:0]   wbm1_cti_i, 
    input         wbm1_cyc_i, 
    input [31:0]  wbm1_dat_i, 
    input [3:0]   wbm1_sel_i,
  
    input 	      wbm1_stb_i, 
    input 	      wbm1_we_i,
  
   // Outputs
    output 	      wbm1_ack_o, 
    output 	      wbm1_err_o, 
    output 	      wbm1_rty_o, 
    output [31:0] wbm1_dat_o,


  
   // Inputs
    input  [31:0] wbm2_adr_i, 
    input  [1:0]  wbm2_bte_i, 
    input  [2:0]  wbm2_cti_i, 
    input         wbm2_cyc_i, 
    input [31:0]  wbm2_dat_i, 
    input [3:0]   wbm2_sel_i,
  
    input 	      wbm2_stb_i, 
    input 	      wbm2_we_i,
  
   // Outputs
    output 	      wbm2_ack_o, 
    output 	      wbm2_err_o, 
    output 	      wbm2_rty_o, 
    output [31:0] wbm2_dat_o,

   // Inputs
    input [31:0]  wbm3_adr_i, 
    input [1:0]   wbm3_bte_i, 
    input [2:0]   wbm3_cti_i, 
    input         wbm3_cyc_i, 
    input [31:0]  wbm3_dat_i, 
    input [3:0]   wbm3_sel_i,
  
    input         wbm3_stb_i, 
    input         wbm3_we_i,
  
   // Outputs
    output        wbm3_ack_o, 
    output        wbm3_err_o, 
    output        wbm3_rty_o, 
    output [31:0] wbm3_dat_o,

    input 	      wb_clk,
    input 	      wb_rst,

    output [12:0] ddr2_a,
    output [2:0]  ddr2_ba,
    output 	      ddr2_ras_n,
    output 	      ddr2_cas_n,
    output 	      ddr2_we_n,
    output        ddr2_rzq,
    output        ddr2_zio,

    output        ddr2_odt,
    output        ddr2_cke,
    output        ddr2_dm,
    output        ddr2_udm,
   
    inout [15:0]  ddr2_dq,		  
    inout         ddr2_dqs,
    inout         ddr2_dqs_n,
    inout         ddr2_udqs,
    inout         ddr2_udqs_n,
    output        ddr2_ck,
    output        ddr2_ck_n,

    input 	      ddr2_if_clk,
    input 	      ddr2_if_rst
   
   );

   // Wires to the four slaves of the DDR2 interface
   wire [31:0] 	  wbs0_ram_adr_i;
   wire [1:0] 	  wbs0_ram_bte_i;
   wire [2:0] 	  wbs0_ram_cti_i;
   wire 	      wbs0_ram_cyc_i;
   wire [31:0] 	  wbs0_ram_dat_i;
   wire [3:0] 	  wbs0_ram_sel_i;
   wire 	      wbs0_ram_stb_i;
   wire 	      wbs0_ram_we_i;   
   wire 	      wbs0_ram_ack_o;
   wire [31:0] 	  wbs0_ram_dat_o;

   wire [31:0]    wbs1_ram_adr_i;
   wire [1:0]     wbs1_ram_bte_i;
   wire [2:0]     wbs1_ram_cti_i;
   wire           wbs1_ram_cyc_i;
   wire [31:0]    wbs1_ram_dat_i;
   wire [3:0]     wbs1_ram_sel_i;
   wire           wbs1_ram_stb_i;
   wire           wbs1_ram_we_i;
   wire           wbs1_ram_ack_o;
   wire [31:0]    wbs1_ram_dat_o;

   wire [31:0]    wbs2_ram_adr_i;
   wire [1:0]     wbs2_ram_bte_i;
   wire [2:0]     wbs2_ram_cti_i;
   wire           wbs2_ram_cyc_i;
   wire [31:0]    wbs2_ram_dat_i;
   wire [3:0]     wbs2_ram_sel_i;
   wire           wbs2_ram_stb_i;
   wire           wbs2_ram_we_i;   
   wire           wbs2_ram_ack_o;
   wire [31:0]    wbs2_ram_dat_o;

   wire [31:0]    wbs3_ram_adr_i;
   wire [1:0]     wbs3_ram_bte_i;
   wire [2:0]     wbs3_ram_cti_i;
   wire           wbs3_ram_cyc_i;
   wire [31:0]    wbs3_ram_dat_i;
   wire [3:0]     wbs3_ram_sel_i;
   wire           wbs3_ram_stb_i;
   wire           wbs3_ram_we_i;
   wire           wbs3_ram_ack_o;
   wire [31:0]    wbs3_ram_dat_o;

   // assign masters to slaves 
   assign wbs0_ram_adr_i = wbm0_adr_i;
   assign wbs0_ram_bte_i = wbm0_bte_i;
   assign wbs0_ram_cti_i = wbm0_cti_i;
   assign wbs0_ram_cyc_i = wbm0_cyc_i;
   assign wbs0_ram_dat_i = wbm0_dat_i;
   assign wbs0_ram_sel_i = wbm0_sel_i;
   assign wbs0_ram_stb_i = wbm0_stb_i;
   assign wbs0_ram_we_i  = wbm0_we_i;   
   assign wbm0_ack_o     = wbs0_ram_ack_o;
   assign wbm0_dat_o     = wbs0_ram_dat_o;
   assign wbm0_err_o     = 0;   
   assign wbm0_rty_o     = 0;
      
   assign wbs1_ram_adr_i = wbm1_adr_i;
   assign wbs1_ram_bte_i = wbm1_bte_i;
   assign wbs1_ram_cti_i = wbm1_cti_i;
   assign wbs1_ram_cyc_i = wbm1_cyc_i;
   assign wbs1_ram_dat_i = wbm1_dat_i;
   assign wbs1_ram_sel_i = wbm1_sel_i;
   assign wbs1_ram_stb_i = wbm1_stb_i;
   assign wbs1_ram_we_i  = wbm1_we_i;   
   assign wbm1_ack_o     = wbs1_ram_ack_o;
   assign wbm1_dat_o     = wbs1_ram_dat_o;
   assign wbm1_err_o     = 0;   
   assign wbm1_rty_o     = 0;

   assign wbs2_ram_adr_i = wbm2_adr_i;
   assign wbs2_ram_bte_i = wbm2_bte_i;
   assign wbs2_ram_cti_i = wbm2_cti_i;
   assign wbs2_ram_cyc_i = wbm2_cyc_i;
   assign wbs2_ram_dat_i = wbm2_dat_i;
   assign wbs2_ram_sel_i = wbm2_sel_i;
   assign wbs2_ram_stb_i = wbm2_stb_i;
   assign wbs2_ram_we_i  = wbm2_we_i;   
   assign wbm2_ack_o     = wbs2_ram_ack_o;
   assign wbm2_dat_o     = wbs2_ram_dat_o;
   assign wbm2_err_o     = 0;   
   assign wbm2_rty_o     = 0;

   assign wbs3_ram_adr_i = wbm3_adr_i;
   assign wbs3_ram_bte_i = wbm3_bte_i;
   assign wbs3_ram_cti_i = wbm3_cti_i;
   assign wbs3_ram_cyc_i = wbm3_cyc_i;
   assign wbs3_ram_dat_i = wbm3_dat_i;
   assign wbs3_ram_sel_i = wbm3_sel_i;
   assign wbs3_ram_stb_i = wbm3_stb_i;
   assign wbs3_ram_we_i  = wbm3_we_i;   
   assign wbm3_ack_o     = wbs3_ram_ack_o;
   assign wbm3_dat_o     = wbs3_ram_dat_o;
   assign wbm3_err_o     = 0;   
   assign wbm3_rty_o     = 0;

/*    
   reg [3:0] 	  input_select, last_selected;
   wire 	  arb_for_wbm0, arb_for_wbm1, arb_for_wbm2, arb_for_wbm3;
   // Wires allowing selection of new input
   assign arb_for_wbm0 = (last_selected[1] | last_selected[2] | last_selected[3] | 
			  !wbm1_cyc_i | !wbm2_cyc_i | !wbm3_cyc_i) & !(|input_select);
   assign arb_for_wbm1 = (last_selected[0] | last_selected[2] | last_selected[3] | 
			  !wbm0_cyc_i | !wbm2_cyc_i | !wbm3_cyc_i) & !(|input_select);
   assign arb_for_wbm2 = (last_selected[0] | last_selected[1] | last_selected[3] | 
			  !wbm0_cyc_i | !wbm1_cyc_i | !wbm3_cyc_i) & !(|input_select);
   assign arb_for_wbm3 = (last_selected[0] | last_selected[1] | last_selected[2] | 
			  !wbm0_cyc_i | !wbm1_cyc_i | !wbm2_cyc_i) & !(|input_select);
   
   // Master select logic
   always @(posedge wb_clk)
     if (wb_rst)
       input_select <= 0;
     else if ((input_select[0] & !wbm0_cyc_i) | (input_select[1] & !wbm1_cyc_i)
	        | (input_select[2] & !wbm2_cyc_i) | (input_select[3] & !wbm3_cyc_i))
       input_select <= 0;
     else if (wbm0_cyc_i & arb_for_wbm0)
       input_select <= 4'b0001;
     else if (wbm1_cyc_i & arb_for_wbm1)
       input_select <= 4'b0010;
     else if (wbm2_cyc_i & arb_for_wbm2)
       input_select <= 4'b0100;
     else if (wbm3_cyc_i & arb_for_wbm3)
       input_select <= 4'b1000;
   
   always @(posedge wb_clk)
     if (wb_rst)
       last_selected <= 4'b1111;
     else if (wbm0_cyc_i & arb_for_wbm0)
       last_selected <= 4'b0001;
     else if (wbm1_cyc_i & arb_for_wbm1)
       last_selected <= 4'b0010;
     else if (wbm2_cyc_i & arb_for_wbm2)
       last_selected <= 4'b0100;
     else if (wbm3_cyc_i & arb_for_wbm3)
       last_selected <= 4'b1000;

   // Mux input signals to RAM (default to wbm0)
   assign wbs_ram_adr_i = (input_select[3]) ? wbm3_adr_i : 
                          (input_select[2]) ? wbm2_adr_i : 
                          (input_select[1]) ? wbm1_adr_i : 
                          (input_select[0]) ? wbm0_adr_i : 0;
   assign wbs_ram_bte_i = (input_select[3]) ? wbm3_bte_i : 
                          (input_select[2]) ? wbm2_bte_i : 
                          (input_select[1]) ? wbm1_bte_i : 
                          (input_select[0]) ? wbm0_bte_i : 0;
   assign wbs_ram_cti_i = (input_select[3]) ? wbm3_cti_i : 
                          (input_select[2]) ? wbm2_cti_i : 
                          (input_select[1]) ? wbm1_cti_i : 
                          (input_select[0]) ? wbm0_cti_i : 0;
   assign wbs_ram_cyc_i = (input_select[3]) ? wbm3_cyc_i : 
                          (input_select[2]) ? wbm2_cyc_i : 
                          (input_select[1]) ? wbm1_cyc_i : 
                          (input_select[0]) ? wbm0_cyc_i : 0;
   assign wbs_ram_dat_i = (input_select[3]) ? wbm3_dat_i : 
                          (input_select[2]) ? wbm2_dat_i : 
                          (input_select[1]) ? wbm1_dat_i : 
                          (input_select[0]) ? wbm0_dat_i : 0;
   assign wbs_ram_sel_i = (input_select[3]) ? wbm3_sel_i : 
                          (input_select[2]) ? wbm2_sel_i : 
                          (input_select[1]) ? wbm1_sel_i : 
                          (input_select[0]) ? wbm0_sel_i : 0;
   assign wbs_ram_stb_i = (input_select[3]) ? wbm3_stb_i : 
                          (input_select[2]) ? wbm2_stb_i : 
                          (input_select[1]) ? wbm1_stb_i : 
                          (input_select[0]) ? wbm0_stb_i : 0;
   assign wbs_ram_we_i  = (input_select[3]) ? wbm3_we_i  :
                          (input_select[2]) ? wbm2_we_i  :
                          (input_select[1]) ? wbm1_we_i  : 
                          (input_select[0]) ? wbm0_we_i : 0;

   // Output from RAM, gate the ACK, ERR, RTY signals appropriately
   assign wbm0_dat_o = wbs_ram_dat_o;
   assign wbm0_ack_o = wbs_ram_ack_o & input_select[0];
   assign wbm0_err_o = 0;   
   assign wbm0_rty_o = 0;

   assign wbm1_dat_o = wbs_ram_dat_o;
   assign wbm1_ack_o = wbs_ram_ack_o & input_select[1];
   assign wbm1_err_o = 0;
   assign wbm1_rty_o = 0;

   assign wbm2_dat_o = wbs_ram_dat_o;
   assign wbm2_ack_o = wbs_ram_ack_o & input_select[2];
   assign wbm2_err_o = 0;
   assign wbm2_rty_o = 0;

   assign wbm3_dat_o = wbs_ram_dat_o;
   assign wbm3_ack_o = wbs_ram_ack_o & input_select[3];
   assign wbm3_err_o = 0;
   assign wbm3_rty_o = 0;
*/
    xilinx_ddr2_if xilinx_ddr2_if0
     (

      .wb0_dat_o			(wbs0_ram_dat_o),
      .wb0_ack_o			(wbs0_ram_ack_o),
      .wb0_adr_i			(wbs0_ram_adr_i[31:0]),
      .wb0_stb_i			(wbs0_ram_stb_i),
      .wb0_cti_i			(wbs0_ram_cti_i),
      .wb0_bte_i			(wbs0_ram_bte_i),
      .wb0_cyc_i			(wbs0_ram_cyc_i),
      .wb0_we_i				(wbs0_ram_we_i),
      .wb0_sel_i			(wbs0_ram_sel_i[3:0]),
      .wb0_dat_i			(wbs0_ram_dat_i[31:0]),

      .wb1_dat_o            (wbs1_ram_dat_o),
      .wb1_ack_o            (wbs1_ram_ack_o),
      .wb1_adr_i            (wbs1_ram_adr_i[31:0]),
      .wb1_stb_i            (wbs1_ram_stb_i),
      .wb1_cti_i            (wbs1_ram_cti_i),
      .wb1_bte_i            (wbs1_ram_bte_i),
      .wb1_cyc_i            (wbs1_ram_cyc_i),
      .wb1_we_i             (wbs1_ram_we_i),
      .wb1_sel_i            (wbs1_ram_sel_i[3:0]),
      .wb1_dat_i            (wbs1_ram_dat_i[31:0]),

      .wb2_dat_o            (wbs2_ram_dat_o),
      .wb2_ack_o            (wbs2_ram_ack_o),
      .wb2_adr_i            (wbs2_ram_adr_i[31:0]),
      .wb2_stb_i            (wbs2_ram_stb_i),
      .wb2_cti_i            (wbs2_ram_cti_i),
      .wb2_bte_i            (wbs2_ram_bte_i),
      .wb2_cyc_i            (wbs2_ram_cyc_i),
      .wb2_we_i             (wbs2_ram_we_i),
      .wb2_sel_i            (wbs2_ram_sel_i[3:0]),
      .wb2_dat_i            (wbs2_ram_dat_i[31:0]),

      .wb3_dat_o            (wbs3_ram_dat_o),
      .wb3_ack_o            (wbs3_ram_ack_o),
      .wb3_adr_i            (wbs3_ram_adr_i[31:0]),
      .wb3_stb_i            (wbs3_ram_stb_i),
      .wb3_cti_i            (wbs3_ram_cti_i),
      .wb3_bte_i            (wbs3_ram_bte_i),
      .wb3_cyc_i            (wbs3_ram_cyc_i),
      .wb3_we_i             (wbs3_ram_we_i),
      .wb3_sel_i            (wbs3_ram_sel_i[3:0]),
      .wb3_dat_i            (wbs3_ram_dat_i[31:0]),

      .ddr2_a				(ddr2_a[12:0]),
      .ddr2_ba				(ddr2_ba),
      .ddr2_ras_n			(ddr2_ras_n),
      .ddr2_cas_n			(ddr2_cas_n),
      .ddr2_we_n			(ddr2_we_n),
      .ddr2_rzq	    		(ddr2_rzq),
      .ddr2_zio 			(ddr2_zio),
      .ddr2_odt				(ddr2_odt),
      .ddr2_cke				(ddr2_cke),
      .ddr2_dm				(ddr2_dm),
      .ddr2_udm				(ddr2_udm),
      .ddr2_ck				(ddr2_ck),
      .ddr2_ck_n			(ddr2_ck_n),
      .ddr2_dq				(ddr2_dq),
      .ddr2_dqs				(ddr2_dqs),
      .ddr2_dqs_n			(ddr2_dqs_n),
      .ddr2_udqs			(ddr2_udqs),
      .ddr2_udqs_n			(ddr2_udqs_n),

      .ddr2_if_clk      	(ddr2_if_clk),
      .ddr2_if_rst          (ddr2_if_rst),
      .wb_clk				(wb_clk),
      .wb_rst				(wb_rst));

endmodule //xilinx_ddr2