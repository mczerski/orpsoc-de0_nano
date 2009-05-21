`timescale 1ns/1ns
module delay #
  (
   parameter depth = 3,
   parameter width = 2
   )
   (
    input [width-1:0]  d,
    output [width-1:0] q,
    input 	       clear,
    input 	       clk,
    input 	       rst
    );
   reg [width-1:0] dffs [1:depth];
   integer i;
   always @ (posedge clk or posedge rst)
     if (rst)
       for ( i=1; i < depth+1; i= i + 1)
	 dffs[i] <= {depth{1'b0}};
     else
       if (clear)
	 for ( i=1; i < depth+1; i= i + 1)
	   dffs[i] <= {depth{1'b0}};
       else
	 begin
	    dffs[1] <= d;	  
	    for ( i=2; i < depth+1; i= i + 1)
	      dffs[i] <= dffs[i-1];
	 end
   assign q = dffs[depth];
endmodule 
 `timescale 1ns/1ns
module wb_sdram_ctrl_fsm (
  output reg [14:0] a,
  output reg accept_cmd,
  output reg [2:0] cmd,
  output reg cs_n,
  output reg rd_ack,
  output reg ref_ack,
  output reg wr_ack,
  input clear,
  input dly_100us,
  input end_of_burst,
  input ref_req,
  input sdram_clk,
  input wb_ack,
  input [24:1] wb_adr_i,
  input wb_cyc,
  input wb_rst,
  input wb_stb,
  input wb_we 
);
  parameter 
  IDLE           = 17, 
  ACT_ROW        = 12, 
  AREF           = 10, 
  ARF1           = 16, 
  ARF2           = 18, 
  AWAIT_CMD      = 9, 
  LMR            = 3, 
  NOP1           = 0, 
  NOP2           = 13, 
  NOP3           = 14, 
  NOP4           = 8, 
  NOP5           = 7, 
  PRE            = 5, 
  PRECHARGECLEAR = 15, 
  PRECHARGERD    = 6, 
  PRECHARGETERM  = 4, 
  PRECHARGEWR    = 11, 
  READ           = 2, 
  WRITE          = 1; 
  reg [18:0] state;
  reg [18:0] nextstate;
  always @* begin
    nextstate = 19'b0000000000000000000;
    a[14:0] = {2'b00,13'b0000000000000}; 
    accept_cmd = 1'b0; 
    cmd[2:0] = 3'b111; 
    cs_n = 1'b0; 
    rd_ack = 1'b0; 
    ref_ack = 1'b0; 
    wr_ack = 1'b0; 
    case (1'b1) 
      state[IDLE]          : begin
                                                cs_n = 1'b1;
        if (dly_100us)                          nextstate[PRE] = 1'b1;
        else                                    nextstate[IDLE] = 1'b1; 
      end
      state[ACT_ROW]       : begin
                                                a[14:0] = {wb_adr_i[24:23],wb_adr_i[22:10]};
                                                cmd[2:0] = 3'b011;
                                                nextstate[NOP4] = 1'b1;
      end
      state[AREF]          : begin
                                                cmd[2:0] = 3'b001;
                                                ref_ack = 1'b1;
                                                nextstate[AWAIT_CMD] = 1'b1;
      end
      state[ARF1]          : begin
                                                cmd[2:0] = 3'b001;
                                                nextstate[NOP2] = 1'b1;
      end
      state[ARF2]          : begin
                                                cmd[2:0] = 3'b001;
                                                nextstate[NOP3] = 1'b1;
      end
      state[AWAIT_CMD]     : begin
                                                accept_cmd = 1'b1;
                                                cs_n = 1'b1;
        if (ref_req)                            nextstate[AREF] = 1'b1;
        else if (wb_stb & wb_cyc)               nextstate[ACT_ROW] = 1'b1;
        else                                    nextstate[AWAIT_CMD] = 1'b1; 
      end
      state[LMR]           : begin
                                                a[14:0] = {2'b00,3'b000,1'b1,2'b00,3'd2,1'b0,3'b000};
                                                cmd[2:0] = 3'b000;
                                                nextstate[AWAIT_CMD] = 1'b1;
      end
      state[NOP1]          :                    nextstate[ARF1] = 1'b1;
      state[NOP2]          :                    nextstate[ARF2] = 1'b1;
      state[NOP3]          :                    nextstate[LMR] = 1'b1;
      state[NOP4]          : if (wb_we)         nextstate[WRITE] = 1'b1;
                             else               nextstate[READ] = 1'b1;
      state[NOP5]          : begin
        if (clear)                              nextstate[ACT_ROW] = 1'b1;
        else if (wb_ack | (!wb_cyc & !wb_stb))  nextstate[AWAIT_CMD] = 1'b1;
        else                                    nextstate[NOP5] = 1'b1; 
      end
      state[PRE]           : begin
                                                a[14:0] = {2'b00,13'b0010000000000};
                                                cmd[2:0] = 3'b010;
                                                nextstate[NOP1] = 1'b1;
      end
      state[PRECHARGECLEAR]: begin
                                                a[14:0] = {2'b00,13'b0010000000000};
                                                accept_cmd = 1'b1;
                                                cmd[2:0] = 3'b010;
                                                nextstate[ACT_ROW] = 1'b1;
      end
      state[PRECHARGERD]   : begin
                                                a[14:0] = {2'b00,13'b0010000000000};
                                                cmd[2:0] = 3'b010;
        if (clear)                              nextstate[ACT_ROW] = 1'b1;
        else                                    nextstate[NOP5] = 1'b1;
      end
      state[PRECHARGETERM] : begin
                                                a[14:0] = {2'b00,13'b0010000000000};
                                                cmd[2:0] = 3'b010;
                                                nextstate[AWAIT_CMD] = 1'b1;
      end
      state[PRECHARGEWR]   : begin
                                                a[14:0] = {2'b00,13'b0010000000000};
                                                cmd[2:0] = 3'b010;
                                                nextstate[AWAIT_CMD] = 1'b1;
      end
      state[READ]          : begin
                                                a[14:0] = {wb_adr_i[24:23],{4'b0000,wb_adr_i[9:1]}};
                                                cmd[2:0] = 3'b101;
                                                rd_ack = 1'b1;
        if (!wb_cyc & !wb_stb)                  nextstate[PRECHARGETERM] = 1'b1;
        else if (clear)                         nextstate[PRECHARGECLEAR] = 1'b1;
        else if (end_of_burst)                  nextstate[PRECHARGERD] = 1'b1;
        else                                    nextstate[READ] = 1'b1; 
      end
      state[WRITE]         : begin
                                                a[14:0] = {wb_adr_i[24:23],{4'b0000,wb_adr_i[9:1]}};
                                                cmd[2:0] = 3'b100;
                                                wr_ack = 1'b1;
        if (end_of_burst)                       nextstate[PRECHARGEWR] = 1'b1;
        else                                    nextstate[WRITE] = 1'b1; 
      end
    endcase
  end
  always @(posedge sdram_clk or posedge wb_rst) begin
    if (wb_rst)
      state <= 19'b0000000000000000001 << IDLE;
    else
      state <= nextstate;
  end
  reg [111:0] statename;
  always @* begin
    case (1)
      state[IDLE]          : statename = "IDLE";
      state[ACT_ROW]       : statename = "ACT_ROW";
      state[AREF]          : statename = "AREF";
      state[ARF1]          : statename = "ARF1";
      state[ARF2]          : statename = "ARF2";
      state[AWAIT_CMD]     : statename = "AWAIT_CMD";
      state[LMR]           : statename = "LMR";
      state[NOP1]          : statename = "NOP1";
      state[NOP2]          : statename = "NOP2";
      state[NOP3]          : statename = "NOP3";
      state[NOP4]          : statename = "NOP4";
      state[NOP5]          : statename = "NOP5";
      state[PRE]           : statename = "PRE";
      state[PRECHARGECLEAR]: statename = "PRECHARGECLEAR";
      state[PRECHARGERD]   : statename = "PRECHARGERD";
      state[PRECHARGETERM] : statename = "PRECHARGETERM";
      state[PRECHARGEWR]   : statename = "PRECHARGEWR";
      state[READ]          : statename = "READ";
      state[WRITE]         : statename = "WRITE";
      default       :        statename = "XXXXXXXXXXXXXX";
    endcase
  end
endmodule
`timescale 1ns/1ns
`timescale 1ns/1ns
module wb_sdram_ctrl_fifo
  (
    input [16-1:0]      d_i,
    input 			    we_i,
    input 			    clear,
    input 			    clk_i,
    output [32-1:0]     wb_dat_o,
    input 			    wb_cyc_i,
    input 			    wb_stb_i,
    output 			    wb_ack_o,
    input 			    wb_clk,
    input 			    rst
   );
   reg [32-1:0] ram [0:3];
   reg [16-1:0] tmp;
   reg [2-1:0] 		    adr_i;
   wire [2-1:0] 		    adr_i_next;
   reg [2-1:0] 		    adr_o;
   wire [2-1:0] 		    adr_o_next;
   reg 					    a0;
   always @ (posedge clk_i or posedge rst)
     if (rst)
       a0 <= 1'b0;
     else
       if (clear)
	 a0 <= 1'b0;
       else if (we_i)
	 a0 <= ~a0;
   always @ (posedge clk_i or posedge rst)
     if (rst)
       tmp <= 16'd0;
     else
       tmp <= d_i;
   assign adr_i_next = (adr_i==3) ? 2'd0 : adr_i + 2'd1;
   always @ (posedge clk_i or posedge rst)
     if (rst)
       adr_i <= 2'd0;
     else
       if (clear)
	 adr_i <= 2'd0;
       else if (we_i & a0)
         adr_i <= adr_i_next;
   assign adr_o_next = (adr_o==3) ? 2'd0 : adr_o + 2'd1;
   always @ (posedge clk_i or posedge rst)
     if (rst)
       adr_o <= {2{1'b0}};
     else
       if (clear)
	 adr_o <= 2'd0;
       else if (wb_cyc_i & wb_stb_i & !(adr_i==adr_o))
         adr_o <= adr_o_next;   
   assign wb_ack_o = wb_cyc_i & wb_stb_i & !(adr_i==adr_o);
   always @ (posedge clk_i)
     if (we_i & (a0==1'b1))
	 ram[adr_i] <= {tmp,d_i};
   assign wb_dat_o = ram[adr_o];
endmodule 
 `timescale 1ns/1ns
module wb_sdram_ctrl
  (
    input [31:0]      wb_dat_i,
    output [31:0]     wb_dat_o,
    input [3:0]       wb_sel_i,
    input [24:2]      wb_adr_i,
    input 	      wb_we_i,
    input [2:0]       wb_cti_i,
    input 	      wb_stb_i,
    input 	      wb_cyc_i,
    output  	      wb_ack_o,
    output 	      sdr_cke_o,   
    output reg	      sdr_cs_n_o,  
    output reg	      sdr_ras_n_o, 
    output reg	      sdr_cas_n_o, 
    output reg	      sdr_we_n_o,  
    output reg [12:0] sdr_a_o,
    output reg  [1:0] sdr_ba_o,
    inout [16-1:0] sdr_dq_io,
    output reg [16/8-1:0] sdr_dqm_o,
    input sdram_clk,
    input wb_clk,
    input wb_rst
   );
   reg    ref_req;
   wire   ref_ack;
   wire	  rd_ack, rd_ack_o, wr_ack, wr_ack_o, cmd_ack;
   reg [2-1:0] ba;
   reg [13-1:0] row;
   wire   terminate, adr_fail, clear;
   wire   end_of_burst;
   wire   burst_counter_set;
   reg [9-1:0]  burst_counter;   
   wire [2:0] burst_counter_next;
   reg [2:0] 	burst_counter_init;
   wire 		fifo_we;
   wire [1:0]  sdr_ba;
   wire [12:0] sdr_a;
   reg 	       sdr_dq_oe_reg;
   wire [16-1:0] sdr_dq_i, sdr_dq_o;
   wire [16/8-1:0] sdr_dqm;
   reg [12:0] counter;
   wire       counter_zf; 
   assign counter_zf = (counter==13'd0);    
   always @ (posedge wb_clk or posedge wb_rst)
     if (wb_rst)
       counter <= 13'd4095;
     else if (counter_zf)
       counter <= 13'd390;
     else
       counter <= counter - 13'd1;
   always @ (posedge wb_clk or posedge wb_rst)
     if (wb_rst)
       ref_req <= 1'b0;
     else
       if (counter_zf)
	 ref_req <= 1'b1;
       else if (ref_ack)
	 ref_req <= 1'b0;
   assign burst_counter_next = burst_counter[2:0] + {{2{1'b0}},1'b1};
   always @ (posedge sdram_clk or posedge wb_rst)
     if (wb_rst)
       begin
	  ba <= 2'd0;
	  row <= 13'd0;	  
	  burst_counter_init <= 2'd0;
	  burst_counter <= 9'd0;
       end
     else
       if (burst_counter_set)
	 begin
	    ba <= wb_adr_i[24:23];
	    row <= wb_adr_i[22:10];	    
	    burst_counter_init <= {wb_adr_i[2-1+2:2],1'b0};	    
	    burst_counter <= {wb_adr_i[9+2:2],1'b0};
	 end
       else if (rd_ack | wr_ack)
	 begin
	    burst_counter[2:0] <= burst_counter_next;	    
	 end
   assign end_of_burst = (wb_cti_i==3'b000) ? (burst_counter[0]==1'b1) : (burst_counter_next == burst_counter_init);
   wb_sdram_ctrl_fsm fsm0
     (
      .dly_100us(counter_zf),
      .ref_req(ref_req),
      .ref_ack(ref_ack),
      .accept_cmd(burst_counter_set),
      .rd_ack(rd_ack),
      .wr_ack(wr_ack),
      .clear(clear),
      .wb_stb(wb_stb_i),
      .wb_cyc(wb_cyc_i),
      .wb_we(wb_we_i),
      .wb_ack(wb_ack_o & ((wb_cti_i==3'b000) | (wb_cti_i==3'b111))),
      .end_of_burst(end_of_burst),
      .wb_adr_i({wb_adr_i[24:23],wb_adr_i[22:10],burst_counter}),
      .a({sdr_ba,sdr_a}),
      .cmd({ras, cas, we}),
      .cs_n(sdr_cs_n),
      .sdram_clk(sdram_clk),
      .wb_rst(wb_rst)
      );
   assign sdr_dqm = ((burst_counter[0]==1'b0) & wr_ack) ? ~wb_sel_i[3:2] : 
		    ((burst_counter[0]==1'b1) & wr_ack) ? ~wb_sel_i[1:0] :
		    2'b00;
   always @ (posedge sdram_clk or posedge wb_rst)
     if (wb_rst)
       begin
	  sdr_cs_n_o <= 1'b1;
	  {sdr_ras_n_o, sdr_cas_n_o, sdr_we_n_o} <= 3'b111;	  
	  {sdr_ba_o,sdr_a_o} <= 15'd0;
	  sdr_dqm_o <= {16/8{1'b0}};
       end
     else
       begin
	  sdr_cs_n_o <= #1 sdr_cs_n;	  
	  {sdr_ras_n_o, sdr_cas_n_o, sdr_we_n_o} <= #1 {ras, cas, we};
	  {sdr_ba_o,sdr_a_o} <= #1 {sdr_ba,sdr_a};
	  sdr_dqm_o <= #1 sdr_dqm;
  end
   assign sdr_cke_o = 1'b1;
   assign sdr_dq_o = (burst_counter[0]==1'b0) ? wb_dat_i[31:16] : wb_dat_i[15:0];
   assign sdr_dq_oe = wr_ack;
   reg [16-1:0] sdr_dq_o_reg;
   always @ (posedge sdram_clk or posedge wb_rst)
     if (wb_rst)
       {sdr_dq_oe_reg,sdr_dq_o_reg} <= {1'b0,16'd0};
     else
       {sdr_dq_oe_reg,sdr_dq_o_reg} <= {sdr_dq_oe,sdr_dq_o};
   assign #1 sdr_dq_io = sdr_dq_oe_reg ? sdr_dq_o_reg : {16{1'bz}};
   assign #1 sdr_dq_i = sdr_dq_io;
   delay #
     (
      .depth(2+1),
      .width(1)
      )
   delay1
     (
      .d(rd_ack),
      .q(fifo_we),
      .clear(clear | terminate),
      .clk(sdram_clk),
      .rst(wb_rst)
      );
   assign wr_ack_o = wr_ack & burst_counter[0];
   wb_sdram_ctrl_fifo fifo
     (
      .d_i(sdr_dq_i),
      .we_i(fifo_we),
      .clear(clear | terminate),
      .clk_i(sdram_clk),
      .wb_dat_o(wb_dat_o),
      .wb_cyc_i(wb_cyc_i),
      .wb_stb_i(wb_stb_i),
      .wb_ack_o(rd_ack_o),
      .wb_clk(wb_clk),
      .rst(wb_rst)
   );
   assign terminate = ~wb_cyc_i & ~wb_stb_i;
   assign adr_fail = ~(wb_adr_i[24:4]=={ba,row,burst_counter[9-1:3]});
   assign clear = adr_fail & rd_ack_o;
   assign wb_ack_o = (rd_ack_o & !adr_fail) | wr_ack_o;
endmodule 
