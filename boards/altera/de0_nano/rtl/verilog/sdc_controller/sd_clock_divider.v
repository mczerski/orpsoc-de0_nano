`include "sd_defines.v"//nononw
module sd_clock_divider (
           input CLK,
           input [7:0] DIVIDER,
           input RST,
           output SD_CLK
       );

reg [7:0] ClockDiv;
reg SD_CLK_O;
`ifdef SYN
  `ifdef ACTEL
CLKINT CLKA
       (.A (SD_CLK_O),
        .Y (SD_CLK)
       );
  `else //ACTEL

//assign SD_CLK = DIVIDER[7] ? CLK : SD_CLK_O;
assign SD_CLK = SD_CLK_O;
  `endif //ACTEL

 `endif //SYN

 `ifdef SIM
//assign SD_CLK = DIVIDER[7] ? CLK : SD_CLK_O;
assign SD_CLK = SD_CLK_O;
`endif //SIM

always @ (posedge CLK or posedge RST)
begin
    if (RST) begin
        ClockDiv <=8'b0000_0000;
        SD_CLK_O  <= 0;
    end
    else if (ClockDiv == DIVIDER )begin
        ClockDiv  <= 0;
        SD_CLK_O <=  ~SD_CLK_O;
    end else begin
        ClockDiv  <= ClockDiv + 8'h1;
        SD_CLK_O <=  SD_CLK_O;
    end
end

endmodule


