`timescale 1ns/10ps
module dbg_crc32_d1 (data, enable, shift, rst, sync_rst, crc_out, clk, crc_match);
input         data;
input         enable;
input         shift;
input         rst;
input         sync_rst;
input         clk;
output        crc_out;
output        crc_match;
reg    [31:0] crc;
wire   [31:0] new_crc;
assign new_crc[0] = data          ^ crc[31];
assign new_crc[1] = data          ^ crc[0]  ^ crc[31];
assign new_crc[2] = data          ^ crc[1]  ^ crc[31];
assign new_crc[3] = crc[2];
assign new_crc[4] = data          ^ crc[3]  ^ crc[31];
assign new_crc[5] = data          ^ crc[4]  ^ crc[31];
assign new_crc[6] = crc[5];
assign new_crc[7] = data          ^ crc[6]  ^ crc[31];
assign new_crc[8] = data          ^ crc[7]  ^ crc[31];
assign new_crc[9] = crc[8];
assign new_crc[10] = data         ^ crc[9]  ^ crc[31];
assign new_crc[11] = data         ^ crc[10] ^ crc[31];
assign new_crc[12] = data         ^ crc[11] ^ crc[31];
assign new_crc[13] = crc[12];
assign new_crc[14] = crc[13];
assign new_crc[15] = crc[14];
assign new_crc[16] = data         ^ crc[15] ^ crc[31];
assign new_crc[17] = crc[16];
assign new_crc[18] = crc[17];
assign new_crc[19] = crc[18];
assign new_crc[20] = crc[19];
assign new_crc[21] = crc[20];
assign new_crc[22] = data         ^ crc[21] ^ crc[31];
assign new_crc[23] = data         ^ crc[22] ^ crc[31];
assign new_crc[24] = crc[23];
assign new_crc[25] = crc[24];
assign new_crc[26] = data         ^ crc[25] ^ crc[31];
assign new_crc[27] = crc[26];
assign new_crc[28] = crc[27];
assign new_crc[29] = crc[28];
assign new_crc[30] = crc[29];
assign new_crc[31] = crc[30];
always @ (posedge clk or posedge rst)
begin
  if(rst)
    crc[31:0] <= #1 32'hffffffff;
  else if(sync_rst)
    crc[31:0] <= #1 32'hffffffff;
  else if(enable)
    crc[31:0] <= #1 new_crc;
  else if (shift)
    crc[31:0] <= #1 {crc[30:0], 1'b0};
end
assign crc_match = (crc == 32'h0);
assign crc_out = crc[31];
endmodule
`timescale 1ns/10ps
module dbg_register (
                      data_in, 
                      data_out, 
                      write, 
                      clk, 
                      reset
                    );
parameter WIDTH = 8; 
parameter RESET_VALUE = 0;
input   [WIDTH-1:0] data_in;
input               write;
input               clk;
input               reset;
output  [WIDTH-1:0] data_out;
reg     [WIDTH-1:0] data_out;
always @ (posedge clk or posedge reset)
begin
  if(reset)
    data_out[WIDTH-1:0] <= #1 RESET_VALUE;
  else if(write)
    data_out[WIDTH-1:0] <= #1 data_in[WIDTH-1:0];
end
endmodule   
`timescale 1ns/10ps
module dbg_cpu_registers  (
                            data_i, 
                            we_i, 
                            tck_i, 
                            bp_i, 
                            rst_i,
                            cpu_clk_i, 
                            ctrl_reg_o,
                            cpu_stall_o, 
                            cpu_rst_o 
                          );
input  [2 -1:0] data_i;
input                   we_i;
input                   tck_i;
input                   bp_i;
input                   rst_i;
input                   cpu_clk_i;
output [2 -1:0]ctrl_reg_o;
output                  cpu_stall_o;
output                  cpu_rst_o;
reg                     cpu_reset;
wire             [2:1]  cpu_op_out;
reg                     stall_bp, stall_bp_csff, stall_bp_tck;
reg                     stall_reg, stall_reg_csff, stall_reg_cpu;
reg                     cpu_reset_csff;
reg                     cpu_rst_o;
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if(rst_i)
    stall_bp <= #1 1'b0;
  else if(bp_i)
    stall_bp <= #1 1'b1;
  else if(stall_reg_cpu)
    stall_bp <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      stall_bp_csff <= #1 1'b0;
      stall_bp_tck  <= #1 1'b0;
    end
  else
    begin
      stall_bp_csff <= #1 stall_bp;
      stall_bp_tck  <= #1 stall_bp_csff;
    end
end
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    begin
      stall_reg_csff <= #1 1'b0;
      stall_reg_cpu  <= #1 1'b0;
    end
  else
    begin
      stall_reg_csff <= #1 stall_reg;
      stall_reg_cpu  <= #1 stall_reg_csff;
    end
end
assign cpu_stall_o = bp_i | stall_bp | stall_reg_cpu;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    stall_reg <= #1 1'b0;
  else if (stall_bp_tck)
    stall_reg <= #1 1'b1;
  else if (we_i)
    stall_reg <= #1 data_i[0];
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    cpu_reset  <= #1 1'b0;
  else if(we_i)
    cpu_reset  <= #1 data_i[1];
end
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    begin
      cpu_reset_csff      <= #1 1'b0; 
      cpu_rst_o           <= #1 1'b0; 
    end
  else
    begin
      cpu_reset_csff      <= #1 cpu_reset;
      cpu_rst_o           <= #1 cpu_reset_csff;
    end
end
assign ctrl_reg_o = {cpu_reset, stall_reg};
endmodule
`timescale 1ns/10ps
module dbg_cpu(
                tck_i,
                tdi_i,
                tdo_o,
                shift_dr_i,
                pause_dr_i,
                update_dr_i,
                cpu_ce_i,
                crc_match_i,
                crc_en_o,
                shift_crc_o,
                rst_i,
                cpu_clk_i,
                cpu_addr_o, cpu_data_i, cpu_data_o, cpu_bp_i, cpu_stall_o, 
                cpu_stb_o,
                cpu_we_o, cpu_ack_i, cpu_rst_o 
              );
input         tck_i;
input         tdi_i;
output        tdo_o;
input         shift_dr_i;
input         pause_dr_i;
input         update_dr_i;
input         cpu_ce_i;
input         crc_match_i;
output        crc_en_o;
output        shift_crc_o;
input         rst_i;
input         cpu_clk_i;
output [31:0] cpu_addr_o;
output [31:0] cpu_data_o;
input         cpu_bp_i;
output        cpu_stall_o;
input  [31:0] cpu_data_i;
output        cpu_stb_o;
output        cpu_we_o;
input         cpu_ack_i;
output        cpu_rst_o;
reg           cpu_stb_o;
wire          cpu_reg_stall;
reg           tdo_o;
reg           cpu_ack_q;
reg           cpu_ack_csff;
reg           cpu_ack_tck;
reg    [31:0] cpu_dat_tmp, cpu_data_dsff;
reg    [31:0] cpu_addr_dsff;
reg           cpu_we_dsff;
reg    [52 -1 :0] dr;
wire          enable;
wire          cmd_cnt_en;
reg     [3 -1:0] cmd_cnt;
wire          cmd_cnt_end;
reg           cmd_cnt_end_q;
reg           addr_len_cnt_en;
reg     [5:0] addr_len_cnt;
wire          addr_len_cnt_end;
reg           addr_len_cnt_end_q;
reg           crc_cnt_en;
reg     [6 -1:0] crc_cnt;
wire          crc_cnt_end;
reg           crc_cnt_end_q;
reg           data_cnt_en;
reg    [19:0] data_cnt;
reg    [16:0] data_cnt_limit;
wire          data_cnt_end;
reg           data_cnt_end_q;
reg           crc_match_reg;
reg    [3'd4 -1:0] acc_type;
reg    [6'd32 -1:0] adr;
reg    [5'd16 -1:0] len;
reg    [5'd16:0]    len_var;
wire   [2 -1:0]ctrl_reg;
reg           start_rd_tck;
reg           rd_tck_started;
reg           start_rd_csff;
reg           start_cpu_rd;
reg           start_cpu_rd_q;
reg           start_wr_tck;
reg           start_wr_csff;
reg           start_cpu_wr;
reg           start_cpu_wr_q;
reg           status_cnt_en;
wire          status_cnt_end;
wire          half, long;
reg           half_q, long_q;
reg [3 -1:0] status_cnt;
reg [3'd4 -1:0] status;
reg           cpu_overrun, cpu_overrun_csff, cpu_overrun_tck;
reg           underrun_tck;
reg           busy_cpu;
reg           busy_tck;
reg           cpu_end;
reg           cpu_end_rst;
reg           cpu_end_rst_csff;
reg           cpu_end_csff;
reg           cpu_end_tck, cpu_end_tck_q;
reg           busy_csff;
reg           latch_data;
reg           update_dr_csff, update_dr_cpu;
wire [2 -1:0] cpu_reg_data_i;
wire                          cpu_reg_we;
reg           set_addr, set_addr_csff, set_addr_cpu, set_addr_cpu_q;
wire   [31:0] input_data;
wire          len_eq_0;
wire          crc_cnt_31;
reg           fifo_full;
reg     [7:0] mem [0:3];
reg           cpu_ce_csff;
reg           mem_ptr_init;
reg [3'd4 -1: 0] curr_cmd;
wire          curr_cmd_go;
reg           curr_cmd_go_q;
wire          curr_cmd_wr_comm;
wire          curr_cmd_wr_ctrl;
wire          curr_cmd_rd_comm;
wire          curr_cmd_rd_ctrl;
wire          acc_type_read;
wire          acc_type_write;
assign enable = cpu_ce_i & shift_dr_i;
assign crc_en_o = enable & crc_cnt_end & (~status_cnt_end);
assign shift_crc_o = enable & status_cnt_end;  
assign curr_cmd_go      = (curr_cmd == 4'h0) && cmd_cnt_end;
assign curr_cmd_wr_comm = (curr_cmd == 4'h2) && cmd_cnt_end;
assign curr_cmd_wr_ctrl = (curr_cmd == 4'h4) && cmd_cnt_end;
assign curr_cmd_rd_comm = (curr_cmd == 4'h1) && cmd_cnt_end;
assign curr_cmd_rd_ctrl = (curr_cmd == 4'h3) && cmd_cnt_end;
assign acc_type_read    = (acc_type == 4'h6);
assign acc_type_write   = (acc_type == 4'h2);
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      latch_data <= #1 1'b0;
      dr <= #1 {52{1'b0}};
    end
  else if (curr_cmd_rd_comm && crc_cnt_31)  
    begin
      dr[52 -1:0] <= #1 {acc_type, adr, len};
    end
  else if (curr_cmd_rd_ctrl && crc_cnt_31)  
    begin
      dr[52 -1:0] <= #1 {ctrl_reg, {52 -2{1'b0}}};
    end
  else if (acc_type_read && curr_cmd_go && crc_cnt_31)  
    begin
      dr[31:0] <= #1 input_data[31:0];
      latch_data <= #1 1'b1;
    end
  else if (acc_type_read && curr_cmd_go && crc_cnt_end) 
    begin
      case (acc_type)  
        4'h6: begin
                      if(long & (~long_q))
                        begin
                          dr[31:0] <= #1 input_data[31:0];
                          latch_data <= #1 1'b1;
                        end
                      else
                        begin
                          dr[31:0] <= #1 {dr[30:0], 1'b0};
                          latch_data <= #1 1'b0;
                        end
                    end
      endcase
    end
  else if (enable && (!addr_len_cnt_end))
    begin
      dr <= #1 {dr[52 -2:0], tdi_i};
    end
end
assign cmd_cnt_en = enable & (~cmd_cnt_end);
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    cmd_cnt <= #1 {3{1'b0}};
  else if (update_dr_i)
    cmd_cnt <= #1 {3{1'b0}};
  else if (cmd_cnt_en)
    cmd_cnt <= #1 cmd_cnt + 1'b1;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    curr_cmd <= #1 {3'd4{1'b0}};
  else if (update_dr_i)
    curr_cmd <= #1 {3'd4{1'b0}};
  else if (cmd_cnt == (3'd4 -1))
    curr_cmd <= #1 {dr[3'd4-2 :0], tdi_i};
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    curr_cmd_go_q <= #1 1'b0;
  else
    curr_cmd_go_q <= #1 curr_cmd_go;
end
always @ (enable or cmd_cnt_end or addr_len_cnt_end or curr_cmd_wr_comm or curr_cmd_wr_ctrl or curr_cmd_rd_comm or curr_cmd_rd_ctrl or crc_cnt_end)
begin
  if (enable && (!addr_len_cnt_end))
    begin
      if (cmd_cnt_end && (curr_cmd_wr_comm || curr_cmd_wr_ctrl))
        addr_len_cnt_en = 1'b1;
      else if (crc_cnt_end && (curr_cmd_rd_comm || curr_cmd_rd_ctrl))
        addr_len_cnt_en = 1'b1;
      else
        addr_len_cnt_en = 1'b0;
    end
  else
    addr_len_cnt_en = 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    addr_len_cnt <= #1 6'h0;
  else if (update_dr_i)
    addr_len_cnt <= #1 6'h0;
  else if (addr_len_cnt_en)
    addr_len_cnt <= #1 addr_len_cnt + 1'b1;
end
always @ (enable or data_cnt_end or cmd_cnt_end or curr_cmd_go or acc_type_write or acc_type_read or crc_cnt_end)
begin
  if (enable && (!data_cnt_end))
    begin
      if (cmd_cnt_end && curr_cmd_go && acc_type_write)
        data_cnt_en = 1'b1;
      else if (crc_cnt_end && curr_cmd_go && acc_type_read)
        data_cnt_en = 1'b1;
      else
        data_cnt_en = 1'b0;
    end
  else
    data_cnt_en = 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    data_cnt <= #1 {19{1'b0}};
  else if (update_dr_i)
    data_cnt <= #1 {19{1'b0}};
  else if (data_cnt_en)
    data_cnt <= #1 data_cnt + 1'b1;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    data_cnt_limit <= #1 {16{1'b0}};
  else if (update_dr_i)
    data_cnt_limit <= #1 len + 1'b1;
end
always @ (enable or crc_cnt_end or curr_cmd_rd_comm or curr_cmd_rd_ctrl or curr_cmd_wr_comm or curr_cmd_wr_ctrl or curr_cmd_go or addr_len_cnt_end or data_cnt_end or acc_type_write or acc_type_read or cmd_cnt_end)
begin
  if (enable && (!crc_cnt_end) && cmd_cnt_end)
    begin
      if (addr_len_cnt_end && (curr_cmd_wr_comm || curr_cmd_wr_ctrl))
        crc_cnt_en = 1'b1;
      else if (data_cnt_end && curr_cmd_go && acc_type_write)
        crc_cnt_en = 1'b1;
      else if (cmd_cnt_end && (curr_cmd_go && acc_type_read || curr_cmd_rd_comm || curr_cmd_rd_ctrl))
        crc_cnt_en = 1'b1;
      else
        crc_cnt_en = 1'b0;
    end
  else
    crc_cnt_en = 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    crc_cnt <= #1 {6{1'b0}};
  else if(crc_cnt_en)
    crc_cnt <= #1 crc_cnt + 1'b1;
  else if (update_dr_i)
    crc_cnt <= #1 {6{1'b0}};
end
assign cmd_cnt_end      = cmd_cnt      == 3'd4;
assign addr_len_cnt_end = addr_len_cnt == 52;
assign crc_cnt_end      = crc_cnt      == 6'd32;
assign crc_cnt_31       = crc_cnt      == 6'd31;
assign data_cnt_end     = (data_cnt    == {data_cnt_limit, 3'b000});
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      crc_cnt_end_q       <= #1 1'b0;
      cmd_cnt_end_q       <= #1 1'b0;
      data_cnt_end_q      <= #1 1'b0;
      addr_len_cnt_end_q  <= #1 1'b0;
    end
  else
    begin
      crc_cnt_end_q       <= #1 crc_cnt_end;
      cmd_cnt_end_q       <= #1 cmd_cnt_end;
      data_cnt_end_q      <= #1 data_cnt_end;
      addr_len_cnt_end_q  <= #1 addr_len_cnt_end;
    end
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    status_cnt <= #1 {3{1'b0}};
  else if (update_dr_i)
    status_cnt <= #1 {3{1'b0}};
  else if (status_cnt_en)
    status_cnt <= #1 status_cnt + 1'b1;
end
always @ (enable or status_cnt_end or crc_cnt_end or curr_cmd_rd_comm or curr_cmd_rd_ctrl or
          curr_cmd_wr_comm or curr_cmd_wr_ctrl or curr_cmd_go or acc_type_write or 
          acc_type_read or data_cnt_end or addr_len_cnt_end)
begin
  if (enable && (!status_cnt_end))
    begin
      if (crc_cnt_end && (curr_cmd_wr_comm || curr_cmd_wr_ctrl))
        status_cnt_en = 1'b1;
      else if (crc_cnt_end && curr_cmd_go && acc_type_write)
        status_cnt_en = 1'b1;
      else if (data_cnt_end && curr_cmd_go && acc_type_read)
        status_cnt_en = 1'b1;
      else if (addr_len_cnt_end && (curr_cmd_rd_comm || curr_cmd_rd_ctrl))
        status_cnt_en = 1'b1;
      else
        status_cnt_en = 1'b0;
    end
  else
    status_cnt_en = 1'b0;
end
assign status_cnt_end = status_cnt == 3'd4;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      acc_type  <= #1 {3'd4{1'b0}};
      adr       <= #1 {6'd32{1'b0}};
      len       <= #1 {5'd16{1'b0}};
      set_addr  <= #1 1'b0;
    end
  else if(crc_cnt_end && (!crc_cnt_end_q) && crc_match_i && curr_cmd_wr_comm)
    begin
      acc_type  <= #1 dr[3'd4 + 6'd32 + 5'd16 -1 : 6'd32 + 5'd16];
      adr       <= #1 dr[6'd32 + 5'd16 -1 : 5'd16];
      len       <= #1 dr[5'd16 -1:0];
      set_addr  <= #1 1'b1;
    end
  else if(cpu_end_tck)               
    begin
      adr  <= #1 cpu_addr_dsff;
    end
  else
    set_addr <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    crc_match_reg <= #1 1'b0;
  else if(crc_cnt_end & (~crc_cnt_end_q))
    crc_match_reg <= #1 crc_match_i;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    len_var <= #1 {1'b0, {5'd16{1'b0}}};
  else if(update_dr_i)
    len_var <= #1 len + 1'b1;
  else if (start_rd_tck)
    begin
      if (len_var > 'd4)
        len_var <= #1 len_var - 3'd4; 
      else
        len_var <= #1 {1'b0, {5'd16{1'b0}}};
    end
end
assign len_eq_0 = len_var == 'h0;
assign half = data_cnt[3:0] == 4'd15;
assign long = data_cnt[4:0] == 5'd31;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      half_q <= #1  1'b0;
      long_q <= #1  1'b0;
    end
  else
    begin
      half_q <= #1 half;
      long_q <= #1 long;
    end
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      start_wr_tck <= #1 1'b0;
      cpu_dat_tmp <= #1 32'h0;
    end
  else if (curr_cmd_go && acc_type_write)
    begin
      if (long_q)
        begin
          start_wr_tck <= #1 1'b1;
          cpu_dat_tmp <= #1 dr[31:0];
        end
      else
        begin
          start_wr_tck <= #1 1'b0;
        end
    end
  else
    start_wr_tck <= #1 1'b0;
end
always @ (posedge cpu_clk_i)
begin
  cpu_data_dsff <= #1 cpu_dat_tmp;
end
assign cpu_data_o = cpu_data_dsff;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    start_rd_tck <= #1 1'b0;
  else if (curr_cmd_go && (!curr_cmd_go_q) && acc_type_read)              
    start_rd_tck <= #1 1'b1;
  else if ((!start_rd_tck) && curr_cmd_go && acc_type_read  && (!len_eq_0) && (!fifo_full) && (!rd_tck_started) && (!cpu_ack_tck))
    start_rd_tck <= #1 1'b1;
  else
    start_rd_tck <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    rd_tck_started <= #1 1'b0;
  else if (update_dr_i || cpu_end_tck && (!cpu_end_tck_q))
    rd_tck_started <= #1 1'b0;
  else if (start_rd_tck)
    rd_tck_started <= #1 1'b1;
end
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    begin
      start_rd_csff   <= #1 1'b0;
      start_cpu_rd    <= #1 1'b0;
      start_cpu_rd_q  <= #1 1'b0;
      start_wr_csff   <= #1 1'b0;
      start_cpu_wr    <= #1 1'b0;
      start_cpu_wr_q  <= #1 1'b0;
      set_addr_csff   <= #1 1'b0;
      set_addr_cpu    <= #1 1'b0;
      set_addr_cpu_q  <= #1 1'b0;
      cpu_ack_q       <= #1 1'b0;
    end
  else
    begin
      start_rd_csff   <= #1 start_rd_tck;
      start_cpu_rd    <= #1 start_rd_csff;
      start_cpu_rd_q  <= #1 start_cpu_rd;
      start_wr_csff   <= #1 start_wr_tck;
      start_cpu_wr    <= #1 start_wr_csff;
      start_cpu_wr_q  <= #1 start_cpu_wr;
      set_addr_csff   <= #1 set_addr;
      set_addr_cpu    <= #1 set_addr_csff;
      set_addr_cpu_q  <= #1 set_addr_cpu;
      cpu_ack_q       <= #1 cpu_ack_i;
    end
end
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    cpu_stb_o <= #1 1'b0;
  else if (cpu_ack_i)
    cpu_stb_o <= #1 1'b0;
  else if ((start_cpu_wr && (!start_cpu_wr_q)) || (start_cpu_rd && (!start_cpu_rd_q)))
    cpu_stb_o <= #1 1'b1;
end
assign cpu_stall_o = cpu_stb_o | cpu_reg_stall;
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    cpu_addr_dsff <= #1 32'h0;
  else if (set_addr_cpu && (!set_addr_cpu_q)) 
    cpu_addr_dsff <= #1 adr;
  else if (cpu_ack_i && (!cpu_ack_q))
    cpu_addr_dsff <= #1 cpu_addr_dsff + 3'd4;
end
assign cpu_addr_o = cpu_addr_dsff;
always @ (posedge cpu_clk_i)
begin
  cpu_we_dsff <= #1 curr_cmd_go && acc_type_write;
end
assign cpu_we_o = cpu_we_dsff;
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    cpu_end <= #1 1'b0;
  else if (cpu_ack_i && (!cpu_ack_q))
    cpu_end <= #1 1'b1;
  else if (cpu_end_rst)
    cpu_end <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      cpu_end_csff  <= #1 1'b0;
      cpu_end_tck   <= #1 1'b0;
      cpu_end_tck_q <= #1 1'b0;
    end
  else
    begin
      cpu_end_csff  <= #1 cpu_end;
      cpu_end_tck   <= #1 cpu_end_csff;
      cpu_end_tck_q <= #1 cpu_end_tck;
    end
end
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    begin
      cpu_end_rst_csff <= #1 1'b0;
      cpu_end_rst      <= #1 1'b0;
    end
  else
    begin
      cpu_end_rst_csff <= #1 cpu_end_tck;
      cpu_end_rst      <= #1 cpu_end_rst_csff;
    end
end
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    busy_cpu <= #1 1'b0;
  else if (cpu_end_rst)
    busy_cpu <= #1 1'b0;
  else if (cpu_stb_o)
    busy_cpu <= #1 1'b1;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      busy_csff       <= #1 1'b0;
      busy_tck        <= #1 1'b0;
      update_dr_csff  <= #1 1'b0;
      update_dr_cpu   <= #1 1'b0;
    end
  else
    begin
      busy_csff       <= #1 busy_cpu;
      busy_tck        <= #1 busy_csff;
      update_dr_csff  <= #1 update_dr_i;
      update_dr_cpu   <= #1 update_dr_csff;
    end
end
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    cpu_overrun <= #1 1'b0;
  else if(start_cpu_wr && (!start_cpu_wr_q) && cpu_ack_i)
    cpu_overrun <= #1 1'b1;
  else if(update_dr_cpu) 
    cpu_overrun <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    underrun_tck <= #1 1'b0;
  else if(latch_data && (!fifo_full) && (!data_cnt_end))
    underrun_tck <= #1 1'b1;
  else if(update_dr_i) 
    underrun_tck <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      cpu_overrun_csff <= #1 1'b0;
      cpu_overrun_tck  <= #1 1'b0;
      cpu_ack_csff     <= #1 1'b0;
      cpu_ack_tck      <= #1 1'b0;
    end
  else
    begin
      cpu_overrun_csff <= #1 cpu_overrun;
      cpu_overrun_tck  <= #1 cpu_overrun_csff;
      cpu_ack_csff     <= #1 cpu_ack_i;
      cpu_ack_tck      <= #1 cpu_ack_csff;
    end
end
always @ (posedge cpu_clk_i or posedge rst_i)
begin
  if (rst_i)
    begin
      cpu_ce_csff  <= #1 1'b0;
      mem_ptr_init      <= #1 1'b0;
    end
  else
    begin
      cpu_ce_csff  <= #1  cpu_ce_i;
      mem_ptr_init      <= #1 ~cpu_ce_csff;
    end
end
always @ (posedge cpu_clk_i)
begin
  if (cpu_ack_i && (!cpu_ack_q))
    begin
      mem[0] <= #1 cpu_data_i[31:24];
      mem[1] <= #1 cpu_data_i[23:16];
      mem[2] <= #1 cpu_data_i[15:08];
      mem[3] <= #1 cpu_data_i[07:00];
    end
end
assign input_data = {mem[0], mem[1], mem[2], mem[3]};
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    fifo_full <= #1 1'h0;
  else if (update_dr_i)
    fifo_full <= #1 1'h0;
  else if (cpu_end_tck && (!cpu_end_tck_q) && (!latch_data) && (!fifo_full))  
    fifo_full <= #1 1'b1;
  else if (!(cpu_end_tck && (!cpu_end_tck_q)) && latch_data && (fifo_full))  
    fifo_full <= #1 1'h0;
end
always @ (pause_dr_i or busy_tck or crc_cnt_end or crc_cnt_end_q or curr_cmd_wr_comm or curr_cmd_wr_ctrl or curr_cmd_go or acc_type_write or acc_type_read or crc_match_i or data_cnt_end or dr or data_cnt_end_q or crc_match_reg or status_cnt_en or status or addr_len_cnt_end or addr_len_cnt_end_q or curr_cmd_rd_comm or curr_cmd_rd_ctrl)
begin
  if (pause_dr_i)
    begin
    tdo_o = busy_tck;
    end
  else if (crc_cnt_end && (!crc_cnt_end_q) && (curr_cmd_wr_comm || curr_cmd_wr_ctrl || curr_cmd_go && acc_type_write ))
    begin
      tdo_o = ~crc_match_i;
    end
  else if (curr_cmd_go && acc_type_read && crc_cnt_end && (!data_cnt_end))
    begin
      tdo_o = dr[31];
    end
  else if (curr_cmd_go && acc_type_read && data_cnt_end && (!data_cnt_end_q))
    begin
      tdo_o = ~crc_match_reg;
    end
  else if ((curr_cmd_rd_comm || curr_cmd_rd_ctrl) && addr_len_cnt_end && (!addr_len_cnt_end_q))
    begin
      tdo_o = ~crc_match_reg;
    end
  else if ((curr_cmd_rd_comm || curr_cmd_rd_ctrl) && crc_cnt_end && (!addr_len_cnt_end))
    begin
      tdo_o = dr[3'd4 + 6'd32 + 5'd16 -1];
    end
  else if (status_cnt_en)
    begin
      tdo_o = status[3];
    end
  else
    begin
      tdo_o = 1'b0;
    end
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
    status <= #1 {3'd4{1'b0}};
    end
  else if(crc_cnt_end && (!crc_cnt_end_q) && (!(curr_cmd_go && acc_type_read)))
    begin
    status <= #1 {1'b0, 1'b0, cpu_overrun_tck, crc_match_i};
    end
  else if (data_cnt_end && (!data_cnt_end_q) && curr_cmd_go && acc_type_read)
    begin
    status <= #1 {1'b0, 1'b0, underrun_tck, crc_match_reg};
    end
  else if (addr_len_cnt_end && (!addr_len_cnt_end) && (curr_cmd_rd_comm || curr_cmd_rd_ctrl))
    begin
    status <= #1 {1'b0, 1'b0, 1'b0, crc_match_reg};
    end
  else if (shift_dr_i && (!status_cnt_end))
    begin
    status <= #1 {status[3'd4 -2:0], status[3'd4 -1]};
    end
end
assign cpu_reg_we = crc_cnt_end && (!crc_cnt_end_q) && crc_match_i && curr_cmd_wr_ctrl;
assign cpu_reg_data_i = dr[52 -1:52 -2];
dbg_cpu_registers i_dbg_cpu_registers 
  (
    .data_i          (cpu_reg_data_i), 
    .we_i            (cpu_reg_we),
    .tck_i           (tck_i),
    .bp_i            (cpu_bp_i),
    .rst_i           (rst_i),
    .cpu_clk_i       (cpu_clk_i),
    .ctrl_reg_o      (ctrl_reg),
    .cpu_stall_o     (cpu_reg_stall),
    .cpu_rst_o       (cpu_rst_o)
  );
endmodule
`timescale 1ns/10ps
module dbg_wb(
                tck_i,
                tdi_i,
                tdo_o,
                shift_dr_i,
                pause_dr_i,
                update_dr_i,
                wishbone_ce_i,
                crc_match_i,
                crc_en_o,
                shift_crc_o,
                rst_i,
                wb_clk_i,
                wb_adr_o, wb_dat_o, wb_dat_i, wb_cyc_o, wb_stb_o, wb_sel_o,
                wb_we_o, wb_ack_i, wb_cab_o, wb_err_i, wb_cti_o, wb_bte_o 
              );
input         tck_i;
input         tdi_i;
output        tdo_o;
input         shift_dr_i;
input         pause_dr_i;
input         update_dr_i;
input         wishbone_ce_i;
input         crc_match_i;
output        crc_en_o;
output        shift_crc_o;
input         rst_i;
input         wb_clk_i;
output [31:0] wb_adr_o;
output [31:0] wb_dat_o;
input  [31:0] wb_dat_i;
output        wb_cyc_o;
output        wb_stb_o;
output  [3:0] wb_sel_o;
output        wb_we_o;
input         wb_ack_i;
output        wb_cab_o;
input         wb_err_i;
output  [2:0] wb_cti_o;
output  [1:0] wb_bte_o;
reg           wb_cyc_o;
reg           tdo_o;
reg    [31:0] wb_dat_tmp, wb_dat_dsff;
reg    [31:0] wb_adr_dsff;
reg     [3:0] wb_sel_dsff;
reg           wb_we_dsff;
reg    [(3'd4 + 6'd32 + 5'd16) -1 :0] dr;
wire          enable;
wire          cmd_cnt_en;
reg     [3 -1:0] cmd_cnt;
wire          cmd_cnt_end;
reg           cmd_cnt_end_q;
reg           addr_len_cnt_en;
reg     [5:0] addr_len_cnt;
wire          addr_len_cnt_end;
reg           addr_len_cnt_end_q;
reg           crc_cnt_en;
reg     [6 -1:0] crc_cnt;
wire          crc_cnt_end;
reg           crc_cnt_end_q;
reg           data_cnt_en;
reg    [(5'd16 + 3):0] data_cnt;
reg    [5'd16:0] data_cnt_limit;
wire          data_cnt_end;
reg           data_cnt_end_q;
reg           crc_match_reg;
reg    [3'd4 -1:0] acc_type;
reg    [6'd32 -1:0] adr;
reg    [5'd16 -1:0] len;
reg    [5'd16:0]    len_var;
reg           start_rd_tck;
reg           rd_tck_started;
reg           start_rd_csff;
reg           start_wb_rd;
reg           start_wb_rd_q;
reg           start_wr_tck;
reg           start_wr_csff;
reg           start_wb_wr;
reg           start_wb_wr_q;
reg           status_cnt_en;
wire          status_cnt_end;
wire          byte, half, long;
reg           byte_q, half_q, long_q;
reg [3 -1:0] status_cnt;
reg [3'd4 -1:0] status;
reg           wb_error, wb_error_csff, wb_error_tck;
reg           wb_overrun, wb_overrun_csff, wb_overrun_tck;
reg           underrun_tck;
reg           busy_wb;
reg           busy_tck;
reg           wb_end;
reg           wb_end_rst;
reg           wb_end_rst_csff;
reg           wb_end_csff;
reg           wb_end_tck, wb_end_tck_q;
reg           busy_csff;
reg           latch_data;
reg           update_dr_csff, update_dr_wb;
reg           set_addr, set_addr_csff, set_addr_wb, set_addr_wb_q;
wire   [31:0] input_data;
wire          len_eq_0;
wire          crc_cnt_31;
reg     [1:0] ptr;
reg     [2:0] fifo_cnt;
wire          fifo_full;
wire          fifo_empty;
reg     [7:0] mem [0:3];
reg     [2:0] mem_ptr_dsff;
reg           wishbone_ce_csff;
reg           mem_ptr_init;
reg [3'd4 -1: 0] curr_cmd;
wire          curr_cmd_go;
reg           curr_cmd_go_q;
wire          curr_cmd_wr_comm;
wire          curr_cmd_rd_comm;
wire          acc_type_read;
wire          acc_type_write;
wire          acc_type_8bit;
wire          acc_type_16bit;
wire          acc_type_32bit;
assign enable = wishbone_ce_i & shift_dr_i;
assign crc_en_o = enable & crc_cnt_end & (~status_cnt_end);
assign shift_crc_o = enable & status_cnt_end;  
assign curr_cmd_go      = (curr_cmd == 4'h0) && cmd_cnt_end;
assign curr_cmd_wr_comm = (curr_cmd == 4'h2) && cmd_cnt_end;
assign curr_cmd_rd_comm = (curr_cmd == 4'h1) && cmd_cnt_end;
assign acc_type_read    = (acc_type == 4'h4  || acc_type == 4'h5  || acc_type == 4'h6);
assign acc_type_write   = (acc_type == 4'h0 || acc_type == 4'h1 || acc_type == 4'h2);
assign acc_type_8bit    = (acc_type == 4'h4  || acc_type == 4'h0);
assign acc_type_16bit   = (acc_type == 4'h5 || acc_type == 4'h1);
assign acc_type_32bit   = (acc_type == 4'h6 || acc_type == 4'h2);
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    ptr <= #1 2'h0;
  else if (update_dr_i)
    ptr <= #1 2'h0;
  else if (curr_cmd_go && acc_type_read && crc_cnt_31) 
    ptr <= #1 ptr + 1'b1;
  else if (curr_cmd_go && acc_type_read && byte && (!byte_q))
    ptr <= ptr + 1'd1;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      latch_data <= #1 1'b0;
      dr <= #1 {(3'd4 + 6'd32 + 5'd16){1'b0}};
    end
  else if (curr_cmd_rd_comm && crc_cnt_31)  
    begin
      dr[3'd4 + 6'd32 + 5'd16 -1:0] <= #1 {acc_type, adr, len};
    end
  else if (acc_type_read && curr_cmd_go && crc_cnt_31)  
    begin
      dr[31:0] <= #1 input_data[31:0];
      latch_data <= #1 1'b1;
    end
  else if (acc_type_read && curr_cmd_go && crc_cnt_end) 
    begin
      if (acc_type == 4'h4)
        begin
          if(byte & (~byte_q))
            begin
              case (ptr)    
                2'b00 : dr[31:24] <= #1 input_data[31:24];
                2'b01 : dr[31:24] <= #1 input_data[23:16];
                2'b10 : dr[31:24] <= #1 input_data[15:8];
                2'b11 : dr[31:24] <= #1 input_data[7:0];
              endcase
              latch_data <= #1 1'b1;
            end
          else
            begin
              dr[31:24] <= #1 {dr[30:24], 1'b0};
              latch_data <= #1 1'b0;
            end
        end
      else if (acc_type == 4'h5)
        begin
          if(half & (~half_q))
            begin
              if (ptr[1])
                dr[31:16] <= #1 input_data[15:0];
              else
                dr[31:16] <= #1 input_data[31:16];
              latch_data <= #1 1'b1;
            end
          else
            begin
              dr[31:16] <= #1 {dr[30:16], 1'b0};
              latch_data <= #1 1'b0;
            end
        end
      else if (acc_type == 4'h6)
        begin
          if(long & (~long_q))
            begin
              dr[31:0] <= #1 input_data[31:0];
              latch_data <= #1 1'b1;
            end
          else
            begin
              dr[31:0] <= #1 {dr[30:0], 1'b0};
              latch_data <= #1 1'b0;
            end
        end
    end
  else if (enable && (!addr_len_cnt_end))
    begin
      dr <= #1 {dr[(3'd4 + 6'd32 + 5'd16) -2:0], tdi_i};
    end
end
assign cmd_cnt_en = enable & (~cmd_cnt_end);
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    cmd_cnt <= #1 {3{1'b0}};
  else if (update_dr_i)
    cmd_cnt <= #1 {3{1'b0}};
  else if (cmd_cnt_en)
    cmd_cnt <= #1 cmd_cnt + 1'b1;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    curr_cmd <= #1 {3'd4{1'b0}};
  else if (update_dr_i)
    curr_cmd <= #1 {3'd4{1'b0}};
  else if (cmd_cnt == (3'd4 -1))
    curr_cmd <= #1 {dr[3'd4-2 :0], tdi_i};
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    curr_cmd_go_q <= #1 1'b0;
  else
    curr_cmd_go_q <= #1 curr_cmd_go;
end
always @ (enable or cmd_cnt_end or addr_len_cnt_end or curr_cmd_wr_comm or curr_cmd_rd_comm or crc_cnt_end)
begin
  if (enable && (!addr_len_cnt_end))
    begin
      if (cmd_cnt_end && curr_cmd_wr_comm)
        addr_len_cnt_en = 1'b1;
      else if (crc_cnt_end && curr_cmd_rd_comm)
        addr_len_cnt_en = 1'b1;
      else
        addr_len_cnt_en = 1'b0;
    end
  else
    addr_len_cnt_en = 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    addr_len_cnt <= #1 6'h0;
  else if (update_dr_i)
    addr_len_cnt <= #1 6'h0;
  else if (addr_len_cnt_en)
    addr_len_cnt <= #1 addr_len_cnt + 1'b1;
end
always @ (enable or data_cnt_end or cmd_cnt_end or curr_cmd_go or acc_type_write or acc_type_read or crc_cnt_end)
begin
  if (enable && (!data_cnt_end))
    begin
      if (cmd_cnt_end && curr_cmd_go && acc_type_write)
        data_cnt_en = 1'b1;
      else if (crc_cnt_end && curr_cmd_go && acc_type_read)
        data_cnt_en = 1'b1;
      else
        data_cnt_en = 1'b0;
    end
  else
    data_cnt_en = 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    data_cnt <= #1 {(5'd16 + 3){1'b0}};
  else if (update_dr_i)
    data_cnt <= #1 {(5'd16 + 3){1'b0}};
  else if (data_cnt_en)
    data_cnt <= #1 data_cnt + 1'b1;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    data_cnt_limit <= #1 {5'd16{1'b0}};
  else if (update_dr_i)
    data_cnt_limit <= #1 len + 1'b1;
end
always @ (enable or crc_cnt_end or curr_cmd_rd_comm or curr_cmd_wr_comm or curr_cmd_go or addr_len_cnt_end or data_cnt_end or acc_type_write or acc_type_read or cmd_cnt_end)
begin
  if (enable && (!crc_cnt_end) && cmd_cnt_end)
    begin
      if (addr_len_cnt_end && curr_cmd_wr_comm)
        crc_cnt_en = 1'b1;
      else if (data_cnt_end && curr_cmd_go && acc_type_write)
        crc_cnt_en = 1'b1;
      else if (cmd_cnt_end && (curr_cmd_go && acc_type_read || curr_cmd_rd_comm))
        crc_cnt_en = 1'b1;
      else
        crc_cnt_en = 1'b0;
    end
  else
    crc_cnt_en = 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    crc_cnt <= #1 {6{1'b0}};
  else if(crc_cnt_en)
    crc_cnt <= #1 crc_cnt + 1'b1;
  else if (update_dr_i)
    crc_cnt <= #1 {6{1'b0}};
end
assign cmd_cnt_end      = cmd_cnt      == 3'd4;
assign addr_len_cnt_end = addr_len_cnt == (3'd4 + 6'd32 + 5'd16);
assign crc_cnt_end      = crc_cnt      == 6'd32;
assign crc_cnt_31       = crc_cnt      == 6'd31;
assign data_cnt_end     = (data_cnt    == {data_cnt_limit, 3'b000});
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      crc_cnt_end_q       <= #1 1'b0;
      cmd_cnt_end_q       <= #1 1'b0;
      data_cnt_end_q      <= #1 1'b0;
      addr_len_cnt_end_q  <= #1 1'b0;
    end
  else
    begin
      crc_cnt_end_q       <= #1 crc_cnt_end;
      cmd_cnt_end_q       <= #1 cmd_cnt_end;
      data_cnt_end_q      <= #1 data_cnt_end;
      addr_len_cnt_end_q  <= #1 addr_len_cnt_end;
    end
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    status_cnt <= #1 {3{1'b0}};
  else if (update_dr_i)
    status_cnt <= #1 {3{1'b0}};
  else if (status_cnt_en)
    status_cnt <= #1 status_cnt + 1'b1;
end
always @ (enable or status_cnt_end or crc_cnt_end or curr_cmd_rd_comm or curr_cmd_wr_comm or curr_cmd_go or acc_type_write or acc_type_read or data_cnt_end or addr_len_cnt_end)
begin
  if (enable && (!status_cnt_end))
    begin
      if (crc_cnt_end && curr_cmd_wr_comm)
        status_cnt_en = 1'b1;
      else if (crc_cnt_end && curr_cmd_go && acc_type_write)
        status_cnt_en = 1'b1;
      else if (data_cnt_end && curr_cmd_go && acc_type_read)
        status_cnt_en = 1'b1;
      else if (addr_len_cnt_end && curr_cmd_rd_comm)
        status_cnt_en = 1'b1;
      else
        status_cnt_en = 1'b0;
    end
  else
    status_cnt_en = 1'b0;
end
assign status_cnt_end = status_cnt == 3'd4;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      acc_type  <= #1 {3'd4{1'b0}};
      adr       <= #1 {6'd32{1'b0}};
      len       <= #1 {5'd16{1'b0}};
      set_addr  <= #1 1'b0;
    end
  else if(crc_cnt_end && (!crc_cnt_end_q) && crc_match_i && curr_cmd_wr_comm)
    begin
      acc_type  <= #1 dr[3'd4 + 6'd32 + 5'd16 -1 : 6'd32 + 5'd16];
      adr       <= #1 dr[6'd32 + 5'd16 -1 : 5'd16];
      len       <= #1 dr[5'd16 -1:0];
      set_addr  <= #1 1'b1;
    end
  else if(wb_end_tck)               
    begin
      adr  <= #1 wb_adr_dsff;
    end
  else
    set_addr <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    crc_match_reg <= #1 1'b0;
  else if(crc_cnt_end & (~crc_cnt_end_q))
    crc_match_reg <= #1 crc_match_i;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    len_var <= #1 {1'b0, {5'd16{1'b0}}};
  else if(update_dr_i)
    len_var <= #1 len + 1'b1;
  else if (start_rd_tck)
    begin
      case (acc_type)  
        4'h4 : 
                    if (len_var > 'd1)
                      len_var <= #1 len_var - 1'd1;
                    else
                      len_var <= #1 {1'b0, {5'd16{1'b0}}};
        4'h5: 
                    if (len_var > 'd2)
                      len_var <= #1 len_var - 2'd2; 
                    else
                      len_var <= #1 {1'b0, {5'd16{1'b0}}};
        4'h6: 
                    if (len_var > 'd4)
                      len_var <= #1 len_var - 3'd4; 
                    else
                      len_var <= #1 {1'b0, {5'd16{1'b0}}};
        default:      len_var <= #1 {1'bx, {5'd16{1'bx}}};
      endcase
    end
end
assign len_eq_0 = len_var == 'h0;
assign byte = data_cnt[2:0] == 3'd7;
assign half = data_cnt[3:0] == 4'd15;
assign long = data_cnt[4:0] == 5'd31;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      byte_q <= #1  1'b0;
      half_q <= #1  1'b0;
      long_q <= #1  1'b0;
    end
  else
    begin
      byte_q <= #1 byte;
      half_q <= #1 half;
      long_q <= #1 long;
    end
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      start_wr_tck <= #1 1'b0;
      wb_dat_tmp <= #1 32'h0;
    end
  else if (curr_cmd_go && acc_type_write)
    begin
      case (acc_type)  
        4'h0  : begin
                        if (byte_q)
                          begin
                            start_wr_tck <= #1 1'b1;
                            wb_dat_tmp <= #1 {4{dr[7:0]}};
                          end
                        else
                          begin
                            start_wr_tck <= #1 1'b0;
                          end
                      end
        4'h1 : begin
                        if (half_q)
                          begin
                            start_wr_tck <= #1 1'b1;
                            wb_dat_tmp <= #1 {2{dr[15:0]}};
                          end
                        else
                          begin
                            start_wr_tck <= #1 1'b0;
                          end
                      end
        4'h2 : begin
                        if (long_q)
                          begin
                            start_wr_tck <= #1 1'b1;
                            wb_dat_tmp <= #1 dr[31:0];
                          end
                        else
                          begin
                            start_wr_tck <= #1 1'b0;
                          end
                      end
      endcase
    end
  else
    start_wr_tck <= #1 1'b0;
end
always @ (posedge wb_clk_i)
begin
  wb_dat_dsff <= #1 wb_dat_tmp;
end
assign wb_dat_o = wb_dat_dsff;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    start_rd_tck <= #1 1'b0;
  else if (curr_cmd_go && (!curr_cmd_go_q) && acc_type_read)              
    start_rd_tck <= #1 1'b1;
  else if ((!start_rd_tck) && curr_cmd_go && acc_type_read  && (!len_eq_0) && (!fifo_full) && (!rd_tck_started))
    start_rd_tck <= #1 1'b1;
  else
    start_rd_tck <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    rd_tck_started <= #1 1'b0;
  else if (update_dr_i || wb_end_tck && (!wb_end_tck_q))
    rd_tck_started <= #1 1'b0;
  else if (start_rd_tck)
    rd_tck_started <= #1 1'b1;
end
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    begin
      start_rd_csff   <= #1 1'b0;
      start_wb_rd     <= #1 1'b0;
      start_wb_rd_q   <= #1 1'b0;
      start_wr_csff   <= #1 1'b0;
      start_wb_wr     <= #1 1'b0;
      start_wb_wr_q   <= #1 1'b0;
      set_addr_csff   <= #1 1'b0;
      set_addr_wb     <= #1 1'b0;
      set_addr_wb_q   <= #1 1'b0;
    end
  else
    begin
      start_rd_csff   <= #1 start_rd_tck;
      start_wb_rd     <= #1 start_rd_csff;
      start_wb_rd_q   <= #1 start_wb_rd;
      start_wr_csff   <= #1 start_wr_tck;
      start_wb_wr     <= #1 start_wr_csff;
      start_wb_wr_q   <= #1 start_wb_wr;
      set_addr_csff   <= #1 set_addr;
      set_addr_wb     <= #1 set_addr_csff;
      set_addr_wb_q   <= #1 set_addr_wb;
    end
end
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    wb_cyc_o <= #1 1'b0;
  else if ((start_wb_wr && (!start_wb_wr_q)) || (start_wb_rd && (!start_wb_rd_q)))
    wb_cyc_o <= #1 1'b1;
  else if (wb_ack_i || wb_err_i)
    wb_cyc_o <= #1 1'b0;
end
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    wb_adr_dsff <= #1 32'h0;
  else if (set_addr_wb && (!set_addr_wb_q)) 
    wb_adr_dsff <= #1 adr;
  else if (wb_ack_i)
    begin
      if ((acc_type == 4'h0) || (acc_type == 4'h4))
        wb_adr_dsff <= #1 wb_adr_dsff + 1'd1;
      else if ((acc_type == 4'h1) || (acc_type == 4'h5))
        wb_adr_dsff <= #1 wb_adr_dsff + 2'd2;
      else
        wb_adr_dsff <= #1 wb_adr_dsff + 3'd4;
    end
end
assign wb_adr_o = wb_adr_dsff;
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    wb_sel_dsff[3:0] <= #1 4'h0;
  else
    begin
      case ({wb_adr_dsff[1:0], acc_type_8bit, acc_type_16bit, acc_type_32bit}) 
        {2'd0, 3'b100} : wb_sel_dsff[3:0] <= #1 4'h8;
        {2'd0, 3'b010} : wb_sel_dsff[3:0] <= #1 4'hC;
        {2'd0, 3'b001} : wb_sel_dsff[3:0] <= #1 4'hF;
        {2'd1, 3'b100} : wb_sel_dsff[3:0] <= #1 4'h4;
        {2'd2, 3'b100} : wb_sel_dsff[3:0] <= #1 4'h2;
        {2'd2, 3'b010} : wb_sel_dsff[3:0] <= #1 4'h3;
        {2'd3, 3'b100} : wb_sel_dsff[3:0] <= #1 4'h1;
        default:         wb_sel_dsff[3:0] <= #1 4'hx;
      endcase
    end
end
assign wb_sel_o = wb_sel_dsff;
always @ (posedge wb_clk_i)
begin
  wb_we_dsff <= #1 curr_cmd_go && acc_type_write;
end
assign wb_we_o = wb_we_dsff;
assign wb_cab_o = 1'b0;
assign wb_stb_o = wb_cyc_o;
assign wb_cti_o = 3'h0;     
assign wb_bte_o = 2'h0;     
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    wb_end <= #1 1'b0;
  else if (wb_ack_i || wb_err_i)
    wb_end <= #1 1'b1;
  else if (wb_end_rst)
    wb_end <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      wb_end_csff  <= #1 1'b0;
      wb_end_tck   <= #1 1'b0;
      wb_end_tck_q <= #1 1'b0;
    end
  else
    begin
      wb_end_csff  <= #1 wb_end;
      wb_end_tck   <= #1 wb_end_csff;
      wb_end_tck_q <= #1 wb_end_tck;
    end
end
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    begin
      wb_end_rst_csff <= #1 1'b0;
      wb_end_rst      <= #1 1'b0;
    end
  else
    begin
      wb_end_rst_csff <= #1 wb_end_tck;
      wb_end_rst      <= #1 wb_end_rst_csff;
    end
end
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    busy_wb <= #1 1'b0;
  else if (wb_end_rst)
    busy_wb <= #1 1'b0;
  else if (wb_cyc_o)
    busy_wb <= #1 1'b1;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      busy_csff       <= #1 1'b0;
      busy_tck        <= #1 1'b0;
      update_dr_csff  <= #1 1'b0;
      update_dr_wb    <= #1 1'b0;
    end
  else
    begin
      busy_csff       <= #1 busy_wb;
      busy_tck        <= #1 busy_csff;
      update_dr_csff  <= #1 update_dr_i;
      update_dr_wb    <= #1 update_dr_csff;
    end
end
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    wb_error <= #1 1'b0;
  else if(wb_err_i)
    wb_error <= #1 1'b1;
  else if(update_dr_wb) 
    wb_error <= #1 1'b0;
end
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    wb_overrun <= #1 1'b0;
  else if(start_wb_wr && (!start_wb_wr_q) && wb_cyc_o)
    wb_overrun <= #1 1'b1;
  else if(update_dr_wb) 
    wb_overrun <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    underrun_tck <= #1 1'b0;
  else if(latch_data && fifo_empty && (!data_cnt_end))
    underrun_tck <= #1 1'b1;
  else if(update_dr_i) 
    underrun_tck <= #1 1'b0;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      wb_error_csff   <= #1 1'b0;
      wb_error_tck    <= #1 1'b0;
      wb_overrun_csff <= #1 1'b0;
      wb_overrun_tck  <= #1 1'b0;
    end
  else
    begin
      wb_error_csff   <= #1 wb_error;
      wb_error_tck    <= #1 wb_error_csff;
      wb_overrun_csff <= #1 wb_overrun;
      wb_overrun_tck  <= #1 wb_overrun_csff;
    end
end
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    begin
      wishbone_ce_csff  <= #1 1'b0;
      mem_ptr_init      <= #1 1'b0;
    end
  else
    begin
      wishbone_ce_csff  <= #1  wishbone_ce_i;
      mem_ptr_init      <= #1 ~wishbone_ce_csff;
    end
end
always @ (posedge wb_clk_i or posedge rst_i)
begin
  if (rst_i)
    mem_ptr_dsff <= #1 3'h0;
  else if(mem_ptr_init)
    mem_ptr_dsff <= #1 3'h0;
  else if (wb_ack_i)
    begin
      if (acc_type == 4'h4)
        mem_ptr_dsff <= #1 mem_ptr_dsff + 1'd1;
      else if (acc_type == 4'h5)
        mem_ptr_dsff <= #1 mem_ptr_dsff + 2'd2;
    end
end
always @ (posedge wb_clk_i)
begin
  if (wb_ack_i)
    begin
      case (wb_sel_dsff)    
        4'b1000  :  mem[mem_ptr_dsff[1:0]] <= #1 wb_dat_i[31:24];            
        4'b0100  :  mem[mem_ptr_dsff[1:0]] <= #1 wb_dat_i[23:16];            
        4'b0010  :  mem[mem_ptr_dsff[1:0]] <= #1 wb_dat_i[15:08];            
        4'b0001  :  mem[mem_ptr_dsff[1:0]] <= #1 wb_dat_i[07:00];            
        4'b1100  :                                                      
                    begin
                      mem[mem_ptr_dsff[1:0]]      <= #1 wb_dat_i[31:24];
                      mem[mem_ptr_dsff[1:0]+1'b1] <= #1 wb_dat_i[23:16];
                    end
        4'b0011  :                                                      
                    begin
                      mem[mem_ptr_dsff[1:0]]      <= #1 wb_dat_i[15:08];
                      mem[mem_ptr_dsff[1:0]+1'b1] <= #1 wb_dat_i[07:00];
                    end
        4'b1111  :                                                      
                    begin
                      mem[0] <= #1 wb_dat_i[31:24];
                      mem[1] <= #1 wb_dat_i[23:16];
                      mem[2] <= #1 wb_dat_i[15:08];
                      mem[3] <= #1 wb_dat_i[07:00];
                    end
        default  :                                                      
                    begin
                      mem[0] <= #1 8'hxx;
                      mem[1] <= #1 8'hxx;
                      mem[2] <= #1 8'hxx;
                      mem[3] <= #1 8'hxx;
                    end
      endcase
    end
end
assign input_data = {mem[0], mem[1], mem[2], mem[3]};
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    fifo_cnt <= #1 3'h0;
  else if (update_dr_i)
    fifo_cnt <= #1 3'h0;
  else if (wb_end_tck && (!wb_end_tck_q) && (!latch_data) && (!fifo_full))  
    begin
      case (acc_type)  
        4'h4 : fifo_cnt <= #1 fifo_cnt + 1'd1;
        4'h5: fifo_cnt <= #1 fifo_cnt + 2'd2;
        4'h6: fifo_cnt <= #1 fifo_cnt + 3'd4;
        default:        fifo_cnt <= #1 3'bxxx;
      endcase
    end
  else if (!(wb_end_tck && (!wb_end_tck_q)) && latch_data && (!fifo_empty))  
    begin
      case (acc_type)  
        4'h4 : fifo_cnt <= #1 fifo_cnt - 1'd1;
        4'h5: fifo_cnt <= #1 fifo_cnt - 2'd2;
        4'h6: fifo_cnt <= #1 fifo_cnt - 3'd4;
        default:        fifo_cnt <= #1 3'bxxx;
      endcase
    end
end
assign fifo_full  = fifo_cnt == 3'h4;
assign fifo_empty = fifo_cnt == 3'h0;
always @ (pause_dr_i or busy_tck or crc_cnt_end or crc_cnt_end_q or curr_cmd_wr_comm or 
          curr_cmd_rd_comm or curr_cmd_go or acc_type_write or acc_type_read or crc_match_i
          or data_cnt_end or dr or data_cnt_end_q or crc_match_reg or status_cnt_en or status 
          or addr_len_cnt_end or addr_len_cnt_end_q)
begin
  if (pause_dr_i)
    begin
    tdo_o = busy_tck;
    end
  else if (crc_cnt_end && (!crc_cnt_end_q) && (curr_cmd_wr_comm || curr_cmd_go && acc_type_write ))
    begin
      tdo_o = ~crc_match_i;
    end
  else if (curr_cmd_go && acc_type_read && crc_cnt_end && (!data_cnt_end))
    begin
      tdo_o = dr[31];
    end
  else if (curr_cmd_go && acc_type_read && data_cnt_end && (!data_cnt_end_q))
    begin
      tdo_o = ~crc_match_reg;
    end
  else if (curr_cmd_rd_comm && addr_len_cnt_end && (!addr_len_cnt_end_q))
    begin
      tdo_o = ~crc_match_reg;
    end
  else if (curr_cmd_rd_comm && crc_cnt_end && (!addr_len_cnt_end))
    begin
      tdo_o = dr[3'd4 + 6'd32 + 5'd16 -1];
    end
  else if (status_cnt_en)
    begin
      tdo_o = status[3];
    end
  else
    begin
      tdo_o = 1'b0;
    end
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
    status <= #1 {3'd4{1'b0}};
    end
  else if(crc_cnt_end && (!crc_cnt_end_q) && (!(curr_cmd_go && acc_type_read)))
    begin
    status <= #1 {1'b0, wb_error_tck, wb_overrun_tck, crc_match_i};
    end
  else if (data_cnt_end && (!data_cnt_end_q) && curr_cmd_go && acc_type_read)
    begin
    status <= #1 {1'b0, wb_error_tck, underrun_tck, crc_match_reg};
    end
  else if (addr_len_cnt_end && (!addr_len_cnt_end) && curr_cmd_rd_comm)
    begin
    status <= #1 {1'b0, 1'b0, 1'b0, crc_match_reg};
    end
  else if (shift_dr_i && (!status_cnt_end))
    begin
    status <= #1 {status[3'd4 -2:0], status[3'd4 -1]};
    end
end
endmodule
`timescale 1ns/10ps
module dbg_top(
                tck_i,
                tdi_i,
                tdo_o,
                rst_i,
                shift_dr_i,
                pause_dr_i,
                update_dr_i,
                debug_select_i
                ,
                wb_clk_i,
                wb_adr_o,
                wb_dat_o,
                wb_dat_i,
                wb_cyc_o,
                wb_stb_o,
                wb_sel_o,
                wb_we_o,
                wb_ack_i,
                wb_cab_o,
                wb_err_i,
                wb_cti_o,
                wb_bte_o
                ,
                cpu0_clk_i, 
                cpu0_addr_o, 
                cpu0_data_i, 
                cpu0_data_o,
                cpu0_bp_i,
                cpu0_stall_o,
                cpu0_stb_o,
                cpu0_we_o,
                cpu0_ack_i,
                cpu0_rst_o
              );
input   tck_i;
input   tdi_i;
output  tdo_o;
input   rst_i;
input   shift_dr_i;
input   pause_dr_i;
input   update_dr_i;
input   debug_select_i;
input         wb_clk_i;
output [31:0] wb_adr_o;
output [31:0] wb_dat_o;
input  [31:0] wb_dat_i;
output        wb_cyc_o;
output        wb_stb_o;
output  [3:0] wb_sel_o;
output        wb_we_o;
input         wb_ack_i;
output        wb_cab_o;
input         wb_err_i;
output  [2:0] wb_cti_o;
output  [1:0] wb_bte_o;
reg           wishbone_module;
reg           wishbone_ce;
wire          tdi_wb;
wire          tdo_wb;
wire          crc_en_wb;
wire          shift_crc_wb;
input         cpu0_clk_i; 
output [31:0] cpu0_addr_o; 
input  [31:0] cpu0_data_i; 
output [31:0] cpu0_data_o;
input         cpu0_bp_i;
output        cpu0_stall_o;
output        cpu0_stb_o;
output        cpu0_we_o;
input         cpu0_ack_i;
output        cpu0_rst_o;
reg           cpu0_debug_module;
reg           cpu0_ce;
wire          cpu0_tdi;
wire          cpu0_tdo;
wire          cpu0_crc_en;
wire          cpu0_shift_crc;
wire          cpu1_crc_en = 1'b0;
wire          cpu1_shift_crc = 1'b0;
reg [3 -1:0]        data_cnt;
reg [6 -1:0]         crc_cnt;
reg [3 -1:0]      status_cnt;
reg [4 + 1 -1:0]  module_dr;
reg [4 -1:0] module_id; 
wire module_latch_en;
wire data_cnt_end;
wire crc_cnt_end;
wire status_cnt_end;
reg  crc_cnt_end_q;
reg  module_select;
reg  module_select_error;
wire crc_out;
wire crc_match;
wire data_shift_en;
wire selecting_command;
reg tdo_o;
wire shift_crc;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    data_cnt <= #1 {3{1'b0}};
  else if(shift_dr_i & (~data_cnt_end))
    data_cnt <= #1 data_cnt + 1'b1;
  else if (update_dr_i)
    data_cnt <= #1 {3{1'b0}};
end
assign data_cnt_end = data_cnt == 4 + 1;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    crc_cnt <= #1 {6{1'b0}};
  else if(shift_dr_i & data_cnt_end & (~crc_cnt_end) & module_select)
    crc_cnt <= #1 crc_cnt + 1'b1;
  else if (update_dr_i)
    crc_cnt <= #1 {6{1'b0}};
end
assign crc_cnt_end = crc_cnt == 32;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    crc_cnt_end_q  <= #1 1'b0;
  else
    crc_cnt_end_q  <= #1 crc_cnt_end;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    status_cnt <= #1 {3{1'b0}};
  else if(shift_dr_i & crc_cnt_end & (~status_cnt_end))
    status_cnt <= #1 status_cnt + 1'b1;
  else if (update_dr_i)
    status_cnt <= #1 {3{1'b0}};
end
assign status_cnt_end = status_cnt == 3'd4;
assign selecting_command = shift_dr_i & (data_cnt == 3'h0) & debug_select_i;
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    module_select <= #1 1'b0;
  else if(selecting_command & tdi_i)       
    module_select <= #1 1'b1;
  else if (update_dr_i)
    module_select <= #1 1'b0;
end
always @ (module_id)
begin
  cpu0_debug_module  <= #1 1'b0;
  wishbone_module   <= #1 1'b0;
  module_select_error    <= #1 1'b0;
  case (module_id)                
      4'h1     :   cpu0_debug_module   <= #1 1'b1;
      4'h0 :   wishbone_module     <= #1 1'b1;
    default                          :   module_select_error <= #1 1'b1; 
  endcase
end
assign module_latch_en = module_select & crc_cnt_end & (~crc_cnt_end_q);
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    module_id <= {4{1'b1}};
  else if(module_latch_en & crc_match)
    module_id <= #1 module_dr[4 + 1 -2:0];
end
assign data_shift_en = shift_dr_i & (~data_cnt_end);
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    module_dr <= #1 4 + 1'h0;
  else if (data_shift_en)
    module_dr[4 + 1 -1:0] <= #1 {module_dr[4 + 1 -2:0], tdi_i};
end
dbg_crc32_d1 i_dbg_crc32_d1_in
             ( 
              .data       (tdi_i),
              .enable     (shift_dr_i),
              .shift      (1'b0),
              .rst        (rst_i),
              .sync_rst   (update_dr_i),
              .crc_out    (),
              .clk        (tck_i),
              .crc_match  (crc_match)
             );
reg tdo_module_select;
wire crc_en;
wire crc_en_dbg;
reg crc_started;
assign crc_en = crc_en_dbg | crc_en_wb | cpu1_crc_en | cpu0_crc_en;
assign crc_en_dbg = shift_dr_i & crc_cnt_end & (~status_cnt_end);
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    crc_started <= #1 1'b0;
  else if (crc_en)
    crc_started <= #1 1'b1;
  else if (update_dr_i)
    crc_started <= #1 1'b0;
end
reg tdo_tmp;
dbg_crc32_d1 i_dbg_crc32_d1_out
             ( 
              .data       (tdo_tmp),
              .enable     (crc_en), 
              .shift      (shift_dr_i & crc_started & (~crc_en)),
              .rst        (rst_i),
              .sync_rst   (update_dr_i),
              .crc_out    (crc_out),
              .clk        (tck_i),
              .crc_match  ()
             );
always @ (status_cnt or crc_match or module_select_error or crc_out)
begin
  case (status_cnt)                    
    3'd0  : begin
                        tdo_module_select = ~crc_match;
                      end
    3'd1  : begin
                        tdo_module_select = module_select_error;
                      end
    3'd2  : begin
                        tdo_module_select = 1'b0;
                      end
    3'd3  : begin
                        tdo_module_select = 1'b0;
                      end
    3'd4  : begin
                        tdo_module_select = crc_out;
                      end
     default : begin    tdo_module_select = 1'b0; end			
  endcase
end
assign shift_crc = shift_crc_wb | cpu1_shift_crc | cpu0_shift_crc;
always @ (shift_crc or crc_out or tdo_module_select
 or wishbone_ce or tdo_wb
 or cpu0_ce or cpu0_tdo
         )
begin
  if (shift_crc)          
    tdo_tmp = crc_out;
  else if (wishbone_ce)   
    tdo_tmp = tdo_wb;
  else if (cpu0_ce)        
    tdo_tmp = cpu0_tdo;
  else
    tdo_tmp = tdo_module_select;
end
always @ (negedge tck_i)
begin
  tdo_o <= #1 tdo_tmp;
end
always @ (posedge tck_i or posedge rst_i)
begin
  if (rst_i)
    begin
      wishbone_ce <= #1 1'b0;
      cpu0_ce <= #1 1'b0;
    end
  else if(selecting_command & (~tdi_i))
    begin
      if (wishbone_module)      
        wishbone_ce <= #1 1'b1;
      if (cpu0_debug_module)     
        cpu0_ce <= #1 1'b1;
    end
  else if (update_dr_i)
    begin
      wishbone_ce <= #1 1'b0;
      cpu0_ce <= #1 1'b0;
    end
end
assign tdi_wb  = wishbone_ce & tdi_i;
assign cpu0_tdi = cpu0_ce & tdi_i;
dbg_wb i_dbg_wb (
                  .tck_i            (tck_i),
                  .tdi_i            (tdi_wb),
                  .tdo_o            (tdo_wb),
                  .shift_dr_i       (shift_dr_i),
                  .pause_dr_i       (pause_dr_i),
                  .update_dr_i      (update_dr_i),
                  .wishbone_ce_i    (wishbone_ce),
                  .crc_match_i      (crc_match),
                  .crc_en_o         (crc_en_wb),
                  .shift_crc_o      (shift_crc_wb),
                  .rst_i            (rst_i),
                  .wb_clk_i         (wb_clk_i),
                  .wb_adr_o         (wb_adr_o), 
                  .wb_dat_o         (wb_dat_o),
                  .wb_dat_i         (wb_dat_i),
                  .wb_cyc_o         (wb_cyc_o),
                  .wb_stb_o         (wb_stb_o),
                  .wb_sel_o         (wb_sel_o),
                  .wb_we_o          (wb_we_o),
                  .wb_ack_i         (wb_ack_i),
                  .wb_cab_o         (wb_cab_o),
                  .wb_err_i         (wb_err_i),
                  .wb_cti_o         (wb_cti_o),
                  .wb_bte_o         (wb_bte_o)
            );
dbg_cpu i_dbg_cpu_or1k (
                  .tck_i            (tck_i),
                  .tdi_i            (cpu0_tdi),
                  .tdo_o            (cpu0_tdo),
                  .shift_dr_i       (shift_dr_i),
                  .pause_dr_i       (pause_dr_i),
                  .update_dr_i      (update_dr_i),
                  .cpu_ce_i         (cpu0_ce),
                  .crc_match_i      (crc_match),
                  .crc_en_o         (cpu0_crc_en),
                  .shift_crc_o      (cpu0_shift_crc),
                  .rst_i            (rst_i),
                  .cpu_clk_i        (cpu0_clk_i), 
                  .cpu_addr_o       (cpu0_addr_o), 
                  .cpu_data_i       (cpu0_data_i), 
                  .cpu_data_o       (cpu0_data_o),
                  .cpu_bp_i         (cpu0_bp_i),
                  .cpu_stall_o      (cpu0_stall_o),
                  .cpu_stb_o        (cpu0_stb_o),
                  .cpu_we_o         (cpu0_we_o),
                  .cpu_ack_i        (cpu0_ack_i),
                  .cpu_rst_o        (cpu0_rst_o)
              );
endmodule
