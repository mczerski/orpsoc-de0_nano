module OR1K_startup_rom
  (
    input  [6:0] addr,
    output [31:0] dout,
    input 	clk
   );

   wire [31:0] 	rom [0:31];
   
   assign rom[ 0] = 32'h18000000;
   assign rom[ 1] = 32'hA8200000;
   assign rom[ 2] = 32'h1880B000;
   assign rom[ 3] = 32'hA8A00520;
   assign rom[ 4] = 32'hA8600001;
   assign rom[ 5] = 32'h04000014;
   assign rom[ 6] = 32'hD4041818;
   assign rom[ 7] = 32'h04000012;
   assign rom[ 8] = 32'hD4040000;
   assign rom[ 9] = 32'hE0431804;
   assign rom[10] = 32'h0400000F;
   assign rom[11] = 32'h9C210008;
   assign rom[12] = 32'h0400000D;
   assign rom[13] = 32'hE1031804;
   assign rom[14] = 32'hE4080000;
   assign rom[15] = 32'h0FFFFFFB;
   assign rom[16] = 32'hD4081800;
   assign rom[17] = 32'h04000008;
   assign rom[18] = 32'h9C210004;
   assign rom[19] = 32'hD4011800;
   assign rom[20] = 32'hE4011000;
   assign rom[21] = 32'h0FFFFFFC;
   assign rom[22] = 32'hA8C00100;
   assign rom[23] = 32'h44003000;
   assign rom[24] = 32'hD4040018;
   assign rom[25] = 32'hD4042810;
   assign rom[26] = 32'h84640010;
   assign rom[27] = 32'hBC030520;
   assign rom[28] = 32'h13FFFFFE;
   assign rom[29] = 32'h15000000;
   assign rom[30] = 32'h44004800;
   assign rom[31] = 32'h84640000;

   reg [6:0] 	addr_reg;

   always @ (posedge clk)
     addr_reg <= addr;

   /*
   always @ (*)
     case (addr_reg[1:0])
       2'b00 : dout <= rom[addr_reg[6:2]][31:24];
       2'b01 : dout <= rom[addr_reg[6:2]][23:16];
       2'b10 : dout <= rom[addr_reg[6:2]][15: 8];
       2'b11 : dout <= rom[addr_reg[6:2]][ 7: 0];
     endcase
    */

   assign dout = rom[addr_reg];
   
endmodule // OR1K_startup_rom
