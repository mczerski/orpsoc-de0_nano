module delay #
  (
   parameter depth = 3,
   parameter width = 2
   )
     (
    input [width-1:0] d,
    output [width-1:0] q,
    input    clk,
    input   rst
      );
   reg [width-1:0] dffs [1:depth];
   integer i;
   always @ (posedge clk or posedge rst)
     if (rst)
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
`if COL_SIZE==9
module wb_sdram_ctrl_fsm (
  output reg [14:0] a,
  output reg accept_cmd,
  output reg [2:0] cmd,
  output reg cmd_ack,
  output reg cs_n,
  output reg [1:0] dq_i_ce,
  output reg [16-1:0] dq_o,
  output reg dq_oe,
  output reg [16/8-1:0] dqm,
  output reg ref_ack,
  input wire [31:0] d,
  input dly_100us,
  input end_of_burst,
  input ref_req,
  input sdram_clk,
  input wb_ack,
  input [`WB_ADR_I_HI:`WB_ADR_I_LO] wb_adr_i,
  input wb_cyc,
  input wb_rst,
  input wire [3:0] wb_sel,
  input wb_stb,
  input wb_we 
);
  parameter 
  IDLE            = 17, 
  ACT_ROW         = 12, 
  AREF            = 11, 
  ARF1            = 16, 
  ARF2            = 19, 
  AWAIT_CMD       = 10, 
  BURST_TERMINATE = 6, 
  LMR             = 4, 
  NOP1            = 0, 
  NOP2            = 14, 
  NOP3            = 15, 
  NOP4            = 9, 
  NOP5            = 8, 
  NOP6            = 7, 
  PRE             = 5, 
  PRECHARGE       = 18, 
  READ            = 3, 
  READ_BURST      = 13, 
  WRITE           = 2, 
  WRITE_BURST     = 1; 
  reg [19:0] state;
  reg [19:0] nextstate;
  always @* begin
    nextstate = 20'b00000000000000000000;
    a[14:0] = {2'b00,13'b0000000000000}; 
    accept_cmd = 1'b0; 
    cmd[2:0] = 3'b111; 
    cmd_ack = 1'b0; 
    cs_n = 1'b0; 
    dq_i_ce[1:0] = 2'b00; 
    dq_o[16-1:0] = d[16-1:0]; 
    dq_oe = 1'b0; 
    dqm[16/8-1:0] = {(16/8){1'b0}}; 
    ref_ack = 1'b0; 
    case (1'b1) 
      state[IDLE]           : begin
                                           cs_n = 1'b1;
        if (dly_100us)                     nextstate[PRE] = 1'b1;
        else                               nextstate[IDLE] = 1'b1; 
      end
      state[ACT_ROW]        : begin
                                           a[14:0] = {`BA,`ROW};
                                           cmd[2:0] = 3'b011;
                                           nextstate[NOP5] = 1'b1;
      end
      state[AREF]           : begin
                                           cmd[2:0] = 3'b001;
                                           ref_ack = 1'b1;
                                           nextstate[NOP4] = 1'b1;
      end
      state[ARF1]           : begin
                                           cmd[2:0] = 3'b001;
                                           nextstate[NOP2] = 1'b1;
      end
      state[ARF2]           : begin
                                           cmd[2:0] = 3'b001;
                                           nextstate[NOP3] = 1'b1;
      end
      state[AWAIT_CMD]      : begin
                                           accept_cmd = 1'b1;
                                           cs_n = 1'b1;
        if (ref_req)                       nextstate[AREF] = 1'b1;
        else if (wb_stb & wb_cyc)          nextstate[ACT_ROW] = 1'b1;
        else                               nextstate[AWAIT_CMD] = 1'b1; 
      end
      state[BURST_TERMINATE]: begin
                                           cmd[2:0] = 3'b110;
                                           nextstate[PRECHARGE] = 1'b1;
      end
      state[LMR]            : begin
                                           a[14:0] = {2'b00,3'b000,1'b1,2'b00,3'd2,1'b0,3'b000};
                                           cmd[2:0] = 3'b000;
                                           nextstate[AWAIT_CMD] = 1'b1;
      end
      state[NOP1]           :              nextstate[ARF1] = 1'b1;
      state[NOP2]           :              nextstate[ARF2] = 1'b1;
      state[NOP3]           :              nextstate[LMR] = 1'b1;
      state[NOP4]           :              nextstate[AWAIT_CMD] = 1'b1;
      state[NOP5]           : if (wb_we)   nextstate[WRITE_BURST] = 1'b1;
                              else         nextstate[READ_BURST] = 1'b1;
      state[NOP6]           : if (wb_ack)  nextstate[AWAIT_CMD] = 1'b1;
                              else         nextstate[NOP6] = 1'b1; 
      state[PRE]            : begin
                                           a[14:0] = {2'b00,13'b0010000000000};
                                           cmd[2:0] = 3'b010;
                                           nextstate[NOP1] = 1'b1;
      end
      state[PRECHARGE]      : begin
                                           a[14:0] = {2'b00,13'b0010000000000};
                                           cmd[2:0] = 3'b010;
                                           nextstate[NOP6] = 1'b1;
      end
      state[READ]           : begin
                                           cmd_ack = 1'b1;
                                           dq_i_ce[1:0] = 2'b01;
        if (!end_of_burst)                 nextstate[READ_BURST] = 1'b1;
        else                               nextstate[BURST_TERMINATE] = 1'b1;
      end
      state[READ_BURST]     : begin
                                           a[14:0] = {`BA,{,wb_adr_i[9:1],1'b0};
                                           cmd[2:0] = 3'b101;
                                           dq_i_ce[1:0] = 2'b10;
                                           nextstate[READ] = 1'b1;
      end
      state[WRITE]          : begin
                                           cmd_ack = 1'b1;
                                           dq_o[16-1:0] = d[15:0];
                                           dq_oe = 1'b1;
                                           dqm[16/8-1:0] = !wb_sel[1:0];
        if (!end_of_burst)                 nextstate[WRITE_BURST] = 1'b1;
        else                               nextstate[BURST_TERMINATE] = 1'b1;
      end
      state[WRITE_BURST]    : begin
                                           a[14:0] = {`BA,{,wb_adr_i[9:1],1'b0};
                                           cmd[2:0] = 3'b100;
                                           dq_o[16-1:0] = d[31:16];
                                           dq_oe = 1'b1;
                                           dqm[16/8-1:0] = !wb_sel[3:2];
                                           nextstate[WRITE] = 1'b1;
      end
    endcase
  end
  always @(posedge sdram_clk or posedge wb_rst) begin
    if (wb_rst)
      state <= 20'b00000000000000000001 << IDLE;
    else
      state <= nextstate;
  end
  reg [119:0] statename;
  always @* begin
    case (1)
      state[IDLE]           : statename = "IDLE";
      state[ACT_ROW]        : statename = "ACT_ROW";
      state[AREF]           : statename = "AREF";
      state[ARF1]           : statename = "ARF1";
      state[ARF2]           : statename = "ARF2";
      state[AWAIT_CMD]      : statename = "AWAIT_CMD";
      state[BURST_TERMINATE]: statename = "BURST_TERMINATE";
      state[LMR]            : statename = "LMR";
      state[NOP1]           : statename = "NOP1";
      state[NOP2]           : statename = "NOP2";
      state[NOP3]           : statename = "NOP3";
      state[NOP4]           : statename = "NOP4";
      state[NOP5]           : statename = "NOP5";
      state[NOP6]           : statename = "NOP6";
      state[PRE]            : statename = "PRE";
      state[PRECHARGE]      : statename = "PRECHARGE";
      state[READ]           : statename = "READ";
      state[READ_BURST]     : statename = "READ_BURST";
      state[WRITE]          : statename = "WRITE";
      state[WRITE_BURST]    : statename = "WRITE_BURST";
      default        :        statename = "XXXXXXXXXXXXXXX";
    endcase
  end
endmodule
`if COL_SIZE==9
module wb_sdram_ctrl
  (
    input [31:0] wb_dat_i,
    output reg [31:0] wb_dat_o,
    input [3:0]       wb_sel_i,
    input [`WB_ADR_I_HI:`WB_ADR_I_LO]      wb_adr_i,
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
   wire	  cmd_ack;
   wire   end_of_burst;
   assign end_of_burst = (wb_cti_i == 3'b111) | (wb_cti_i == 3'b000);
   reg [4-1:0] burst_counter;
   wire [1:0]  sdr_ba;
   wire [12:0] sdr_a;
   wire [16/8-1:0]  dq_i_ce1,dq_i_ce2;
   reg 	       sdr_dq_oe_reg;
   wire [16-1:0] sdr_dq_i, sdr_dq_o;
   wire [16/8-1:0] sdr_dqm;
   reg [12:0] counter;
   wire       counter_zf; 
   assign counter_zf = (counter==13'd0);    
   always @ (posedge wb_clk or posedge wb_rst)
     if (wb_rst)
       counter <= 12'd4095;
     else if (counter_zf)
       counter <= 12'd390;
     else
       counter <= counter - 1;
   always @ (posedge wb_clk or posedge wb_rst)
     if (wb_rst)
       ref_req <= 1'b0;
     else
       if (counter_zf)
	 ref_req <= 1'b1;
       else if (ref_ack)
	 ref_req <= 1'b0;
   always @ (posedge sdram_clk or posedge wb_rst)
     if (wb_rst)
       burst_counter <= 0;
     else
       if (rd_ack)
	 burst_counter <= burst_counter + 1;
       else
	 burst_counter <= wb_adr_i[5:2];
   wb_sdram_ctrl_fsm fsm0
     (
      .dly_100us(counter_zf),
      .ref_req(ref_req),
      .ref_ack(ref_ack),
      .accept_cmd(),
      .wb_stb(wb_stb_i),
      .wb_cyc(wb_cyc_i),
      .wb_we(wb_we_i),
      .wb_ack(wb_ack_o), 
      .end_of_burst(end_of_burst),
      .cmd_ack(cmd_ack),
      .wb_sel(wb_sel_i),
      .wb_adr_i({wb_adr_i[`WB_ADR_I_HI:`WB_ADR_I_LO+3],burst_counter}),
      .a({sdr_ba,sdr_a}),
      .cmd({ras, cas, we}),
      .cs_n(sdr_cs_n),
      .sdram_clk(sdram_clk),
      .wb_rst(wb_rst)
      );
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
	  sdr_cs_n_o <= sdr_cs_n;	  
	  {sdr_ras_n_o, sdr_cas_n_o, sdr_we_n_o} <= {ras, cas, we};
	  {sdr_ba_o,sdr_a_o} <= {sdr_ba,sdr_a};
	  sdr_dqm_o <= sdr_dqm;
       end
   assign sdr_cke_o = 1'b1;
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
      .width(16/8)
      )
   delay0
     (
      .d(dq_i_ce1),
      .q(dq_i_ce2),
      .clk(sdram_clk),
      .rst(wb_rst)
      );
   delay #
     (
      .depth(2+2),
      .width(1)
      )
   delay1
     (
      .d(cmd_ack),
      .q(wb_ack_o),
      .clk(sdram_clk),
      .rst(wb_rst)
      );
   always @ (posedge sdram_clk or posedge wb_rst)
     if (wb_rst)
       begin
	  wb_dat_o <= 32'd0;
       end
     else
       begin
	  if (dq_i_ce2[1])
	    wb_dat_o[31:16] <= sdr_dq_i;
	  if (dq_i_ce2[0])
	    wb_dat_o[15:0] <= sdr_dq_i;
       end
endmodule 
