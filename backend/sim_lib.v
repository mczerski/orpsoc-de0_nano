`timescale 1 ns / 100 ps
module GND
  (
   output Y
   );
   assign Y = 1'b0;
endmodule // GND
`timescale 1 ns / 100 ps
module VCC
  (
   output Y
   );
   assign Y = 1'b1;
endmodule // VCC
`timescale 1 ns / 100 ps
module CLKDLY
  (
   output GL,
   input CLK, DLYGL0, DLYGL1, DLYGL2,DLYGL3,DLYGL4
   );
   assign GL = ({DLYGL0,DLYGL1,DLYGL2,DLYGL3,DLYGL4}==5'b00000) ? CLK : 1'b0;
endmodule // CLKDLY

`timescale 1 ns / 100 ps
module AND2 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = A & B;

endmodule // AND2
`timescale 1 ns / 100 ps
module AND2A 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !A & B;

endmodule // AND2A
`timescale 1 ns / 100 ps
module AND2B 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !A & !B;

endmodule // AND2B
`timescale 1 ns / 100 ps
module AND3
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = A & B & C;

endmodule // AND3
`timescale 1 ns / 100 ps
module AND3A 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !A & B & C;

endmodule // AND3A
`timescale 1 ns / 100 ps
`timescale 1 ns / 100 ps
module AND3B 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !A & !B & C;

endmodule // AND3B
`timescale 1 ns / 100 ps
module AND3C
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !A & !B & !C;

endmodule // AND3C
`timescale 1 ns / 100 ps
module NAND2 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !(A & B);

endmodule // NAND2
`timescale 1 ns / 100 ps
module NAND2A
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !(!A & B);

endmodule // NAND2A
`timescale 1 ns / 100 ps
module NAND2B
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !(!A & !B);

endmodule // NAND2B
`timescale 1 ns / 100 ps
module NAND3 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(A & B & C);

endmodule // NAND3
`timescale 1 ns / 100 ps
module NAND3A
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(!A & B & C);

endmodule // NAND3A
`timescale 1 ns / 100 ps
module NAND3B
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(!A & !B & C);

endmodule // NAND3B
`timescale 1 ns / 100 ps
module NAND3C
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(!A & !B & !C);

endmodule // NAND3C
`timescale 1 ns / 100 ps
module OR2 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = A | B;

endmodule // OR2
`timescale 1 ns / 100 ps
module OR2A 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !A | B;

endmodule // OR2A
`timescale 1 ns / 100 ps
module OR2B 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !A | !B;

endmodule // OR2B
`timescale 1 ns / 100 ps
module OR3 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = A | B | C;

endmodule // OR3
`timescale 1 ns / 100 ps
module OR3A 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !A | B | C;

endmodule // OR3A
`timescale 1 ns / 100 ps
module OR3B 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !A | !B | C;

endmodule // OR3B
`timescale 1 ns / 100 ps
module OR3C 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !A | !B | !C;

endmodule // OR3C
`timescale 1 ns / 100 ps
module NOR2 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !(A | B);

endmodule // NOR2
`timescale 1 ns / 100 ps
module NOR2A 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !(!A | B);

endmodule // NOR2A
module NOR2B 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !(!A | !B);

endmodule // NOR2B
`timescale 1 ns / 100 ps
module NOR3 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(A | B | C);

endmodule // NOR2
`timescale 1 ns / 100 ps
module NOR3A 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(!A | B | C);

endmodule // NOR3A
`timescale 1 ns / 100 ps
module NOR3B 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(!A | !B | C);

endmodule // NOR3B
`timescale 1 ns / 100 ps
module NOR3C 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(!A | !B | !C);

endmodule // NOR3C
`timescale 1 ns / 100 ps
module XOR2 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = A ^ B;

endmodule // XOR2
`timescale 1 ns / 100 ps
module XOR2A 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !A ^ B;

endmodule // XOR2A
`timescale 1 ns / 100 ps
module XOR2B 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !A ^ !B;

endmodule // XOR2B
`timescale 1 ns / 100 ps
module XOR3 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = A ^ B ^ C;

endmodule // XOR3
`timescale 1 ns / 100 ps
module XOR3A 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !A ^ B ^ C;

endmodule // XOR3A
module XOR3B 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !A ^ !B ^ C;

endmodule // XOR3B
`timescale 1 ns / 100 ps
module XOR3C 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !A ^ !B ^ !C;

endmodule // XOR3C
`timescale 1 ns / 100 ps
module XNOR2 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !(A ^ B);

endmodule // XNOR2
`timescale 1 ns / 100 ps
module XNOR2A 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !(!A ^ B);

endmodule // XNOR2A
`timescale 1 ns / 100 ps
module XNOR2B 
  (
   input  A,B,
   output Y
   );

   assign #1 Y = !(!A ^ !B);

endmodule // XNOR2B
`timescale 1 ns / 100 ps
module XNOR3 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(A ^ B ^ C);

endmodule // XNOR3
`timescale 1 ns / 100 ps
module XNOR3A 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(!A ^ B ^ C);

endmodule // XNOR3A
`timescale 1 ns / 100 ps
module XNOR3B 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(!A ^ !B ^ C);

endmodule // XNOR3B
`timescale 1 ns / 100 ps
module XNOR3C 
  (
   input  A,B,C,
   output Y
   );

   assign #1 Y = !(!A ^ !B ^ !C);

endmodule // XNOR3C
`timescale 1 ns / 100 ps
module MX2
  (
   input A,B,S,
   output Y
   );
   assign #1 Y = !S ? A : B;
endmodule // MX2
module MX2A
  (
   input A,B,S,
   output Y
   );
   assign #1 Y = !S ? !A : B;
endmodule // MX2A
`timescale 1 ns / 100 ps
module MX2B
  (
   input A,B,S,
   output Y
   );
   assign #1 Y = !S ? A : !B;
endmodule // MX2B
`timescale 1 ns / 100 ps
module MX2C
  (
   input A,B,S,
   output Y
   );
   assign #1 Y = !S ? !A : !B;
endmodule // MX2C
`timescale 1 ns / 100 ps
module AO1
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (A & B) | C;
endmodule // AO1
`timescale 1 ns / 100 ps
module AO1A
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (!A & B) | C;
endmodule // AO1A
`timescale 1 ns / 100 ps
module AO1B
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (A & B) | !C;
endmodule // AO1B
`timescale 1 ns / 100 ps
module AO1C
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (!A & B) | !C;
endmodule // AO1C
`timescale 1 ns / 100 ps
module AO1D
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (!A & !B) | C;
endmodule // AO1D
`timescale 1 ns / 100 ps
module AO1E
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (!A & !B) | !C;
endmodule // AO1E
`timescale 1 ns / 100 ps
module AOI1
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((A & B) | C);
endmodule // AOI1
`timescale 1 ns / 100 ps
module AOI1A
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((!A & B) | C);
endmodule // AOI1A
`timescale 1 ns / 100 ps
module AOI1B
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((A & B) | !C);
endmodule // AOI1B
`timescale 1 ns / 100 ps
module AOI1C
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((!A & B) | !C);
endmodule // AOI1C
module AOI1D
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((!A & !B) | C);
endmodule // AOI1D
`timescale 1 ns / 100 ps
module AOI1E
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((!A & !B) | !C);
endmodule // AOI1E
`timescale 1 ns / 100 ps
module AX1
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (!A & B) ^ C;
endmodule // AX1
`timescale 1 ns / 100 ps
module AX1A
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((!A & B) ^ C);
endmodule // AX1A
module AX1B
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (!A & !B) ^ C;
endmodule // AX1B
`timescale 1 ns / 100 ps
module AX1C
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (A & B) ^ C;
endmodule // AX1C
`timescale 1 ns / 100 ps
module AX1D
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((!A & !B) ^ C);
endmodule // AX1D
`timescale 1 ns / 100 ps
module AX1E
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((A & B) ^ C);
endmodule // AX1E
`timescale 1 ns / 100 ps
module OA1
  (
   input A,B,C,
   output Y
   );
  assign #1 Y = (A | B) & C;
endmodule // OA1
`timescale 1 ns / 100 ps
module OA1A
  (
   input A,B,C,
   output Y
   );
  assign #1 Y = (!A | B) & C;
endmodule // OA1A
`timescale 1 ns / 100 ps
module OA1B
  (
   input A,B,C,
   output Y
   );
  assign #1 Y = (A | B) & !C;
endmodule // OA1B
`timescale 1 ns / 100 ps
module OA1C
  (
   input A,B,C,
   output Y
   );
  assign #1 Y = (!A | B) & !C;
endmodule // OA1C
`timescale 1 ns / 100 ps
module CLKINT
  (
   input A,
   output Y
   );
   assign #1 Y = A;
endmodule // CLKINT
`timescale 1 ns / 100 ps
module OAI1
  (
   input A,B,C,
   output Y
   );
  assign #1 Y = !((A | B) & C);
endmodule // OAI1
`timescale 1 ns / 100 ps
module XA1B
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = (A ^ B) & !C;
endmodule // XA1B
`timescale 1 ns / 100 ps
module XAI1
  (
   input A,B,C,
   output Y
   );
   assign #1 Y = !((A ^ B) & C);
endmodule // XAI1
/////////////////////////////////////////////////////////////////////////////////
// DFF
`timescale 1 ns / 100 ps
module DFN1C0
  (
   output reg Q,
   input D,CLR,CLK
   );
   always @ (posedge CLK or negedge CLR)
     if (!CLR)
       Q <= #1 1'b0;
     else
       Q <= #1 D;
endmodule // DFN1C0
`timescale 1 ns / 100 ps
module DFN1C1
  (
   output reg Q,
   input D,CLR,CLK
   );
   always @ (posedge CLK or posedge CLR)
     if (CLR)
       Q <= #1 1'b0;
     else
       Q <= #1 D;
endmodule // DFN1C1
`timescale 1 ns / 100 ps
module DFN1P0
  (
   output reg Q,
   input D,PRE,CLK
   );
   always @ (posedge CLK or negedge PRE)
     if (!PRE)
       Q <= #1 1'b1;
     else
       Q <= #1 D;
endmodule // DFN1P1
`timescale 1 ns / 100 ps
module DFN1P1
  (
   output reg Q,
   input D,PRE,CLK
   );
   always @ (posedge CLK or posedge PRE)
     if (PRE)
       Q <= #1 1'b1;
     else
       Q <= #1 D;
endmodule // DFN1P1
`timescale 1 ns / 100 ps
module DFN1E0C1
  (
   output reg Q,
   input D,E,CLR,CLK
   );
   always @ (posedge CLK or posedge CLR)
     if (CLR)
       Q <= #1 1'b0;
     else if (!E)
       Q <= #1 D;
endmodule // DFN1E0C1
`timescale 1 ns / 100 ps
module DFN1E1C1
  (
   output reg Q,
   input D,E,CLR,CLK
   );
   always @ (posedge CLK or posedge CLR)
     if (CLR)
       Q <= #1 1'b0;
     else if (E)
       Q <= #1 D;
endmodule // DFN1E0C1
`timescale 1 ns / 100 ps
module DFN1E0P1
  (
   output reg Q,
   input D,E,PRE,CLK
   );
   always @ (posedge CLK or posedge PRE)
     if (PRE)
       Q <= #1 1'b1;
     else if (!E)
       Q <= #1 D;
endmodule // DFN1E0P1
`timescale 1 ns / 100 ps
module DFN1E1P1
  (
   output reg Q,
   input D,E,PRE,CLK
   );
   always @ (posedge CLK or posedge PRE)
     if (PRE)
       Q <= #1 1'b1;
     else if (E)
       Q <= #1 D;
endmodule // DFN1E1P1
