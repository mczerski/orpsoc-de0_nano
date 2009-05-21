module OR1K_startup
  (
    input [6:2]       wb_adr_i,
    input 	      wb_stb_i,
    input 	      wb_cyc_i,
    output reg [31:0] wb_dat_o,
    output reg 	      wb_ack_o,
    input 	      wb_clk,
    input 	      wb_rst
   );
   
   reg [3:0] 	      counter;
   wire [7:0] 	      do;
   
   parameter [31:0] NOP = 32'h15000000;
   
   always @ (posedge wb_clk or posedge wb_rst)
     if (wb_rst)
       counter <= 4'd0;
     else
       if (!wb_cyc_i)
	 counter <= 4'd0;
       else if (wb_cyc_i & wb_stb_i & !wb_ack_o)
	 counter <= counter + 4'd1;
   
   always @ (posedge wb_clk or posedge wb_rst)
     if (wb_rst)
       wb_ack_o <= 1'b0;
     else
       wb_ack_o <= (counter == 4'd15);

   always @ (posedge wb_clk or posedge wb_rst)
     if (wb_rst)
       wb_dat_o <= NOP;
     else
       case (counter)	
	 4'd15: wb_dat_o[31:24] <= do;
	 4'd11: wb_dat_o[23:16] <= do;
	 4'd7 : wb_dat_o[15: 8] <= do;
	 4'd3 : wb_dat_o[ 7: 0] <= do;
       endcase

   flash flash0 
     (
      .CLK  (counter[1] ^ counter[0]),
      .ADDR ({wb_adr_i,counter[3:2]}),
      .DOUT (do)
      );
   
endmodule // OR1K_startup
