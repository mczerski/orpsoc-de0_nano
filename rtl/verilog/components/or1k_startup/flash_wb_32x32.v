module flash_wb_1k (
	wb_adr_i, wb_cyc_i, wb_stb_i, wb_dat_o, wb_ack_o, clk, rst );

input  [4:0]  wb_adr_i;
input         wb_cyc_i;
input         wb_stb_i;
output [31:0] wb_dat_o;
reg    [31:0] wb_dat_o;
output        wb_ack_o;
reg           wb_ack_o;
input         clk;
input         rst;

reg [3:0]     counter;
wire [7:0]    do;

parameter [31:0] NOP = 32'h15000000;

always @ (posedge rst or posedge clk)
if (rst)
	counter <= 4'd0;
else
	if (wb_cyc_i & wb_stb_i & !wb_ack_o)
		counter <= counter + 4'd1;

always @ (posedge rst or posedge clk)
if (rst)
	wb_ack_o <= 1'b0;
else
	wb_ack_o <= (counter == 4'd15);

always @ (posedge rst or posedge clk)
if (rst)
	wb_dat_o <= NOP;
else
	case (counter)	
	4'd15: wb_dat_o[31:24] <= do;
	4'd11: wb_dat_o[23:16] <= do;
	4'd7: wb_dat_o[15: 8] <= do;
	4'd3: wb_dat_o[ 7: 0] <= do;
	endcase


flash flash0 (
	.CLK  (counter[1] ^ counter[0]),
	.ADDR ({wb_adr_i,counter[3:2]}),
	.DOUT (do));

endmodule	