// debug_if_from_mod_synchronization_module.v
// debug_if_defines.v
module debug_if_from_mod_synchronization_module 
(
    src_rst_i       ,
    src_clr_i       ,
    src_clk_i       ,
    src_clk_en_i    ,
    src_mux_comb_i  ,
    src_i           ,
    src_o           ,
    sff_rst_i       ,
    sff_clr_i       ,
    sff_clk_i       ,
    sff_clk_en_i    ,
    sff_o           ,
    dst_rst_i       ,
    dst_clr_i       ,
    dst_clk_i       ,
    dst_clk_en_i    ,
    dst_o            
) ;
parameter width         = 1             ;   // Width parameter of Input and Output signals 
parameter rst_val       = 0             ;   // Reset value parameter of Flip-Flop Output signals 
input                   src_rst_i       ;   // Source reset 
input                   src_clr_i       ;   // Source clear 
input                   src_clk_i       ;   // Source clock 
input                   src_clk_en_i    ;   // Source clock enable for source Flip-Flop 
input                   src_mux_comb_i  ;   // Source multiplexer select for combinatorial source input (i.e. from input PAD) 
input   [width - 1: 0]  src_i           ;   // Source input 
output  [width - 1: 0]  src_o           ;   // Source output - not synchronized 
input                   sff_rst_i       ;   // Synchronizer reset (i.e. same as destination reset) 
input                   sff_clr_i       ;   // Synchronizer clear
input                   sff_clk_i       ;   // Synchronizer clock (i.e. same as destination clock)  
input                   sff_clk_en_i    ;   // Synchronizer clok enable for synchronizer Flip-Flop  
output  [width - 1: 0]  sff_o           ;   // Synchronizer output  
input                   dst_rst_i       ;   // Destination reset 
input                   dst_clr_i       ;   // Destination clear 
input                   dst_clk_i       ;   // Destination clock 
input                   dst_clk_en_i    ;   // Destination clock enable for destination Flip-Flop  
output  [width - 1: 0]  dst_o           ;   // Destination output  
reg     [width - 1: 0]  src_o           ; 
reg     [width - 1: 0]  sff_o           ; 
reg     [width - 1: 0]  dst_o           ; 
reg     [width - 1: 0]  src             ; 
reg     [width - 1: 0]  sff_i           ;
always @(posedge src_clk_i undefined)
begin
    if (src_rst_i == undefined)
        src <= rst_val ;
    else if (src_clr_i)
        src <= rst_val ;
    else if (src_clk_en_i)
        src <= src_i ;
end
always @(src_i or src or src_mux_comb_i)
begin
    if (src_mux_comb_i)
        src_o = src_i ;
    else
        src_o = src ;
end
always @(src_o)
    sff_i = src_o ;
always @(posedge sff_clk_i or posedge sff_rst_i)
begin
    if (sff_rst_i)
        sff_o <= rst_val ;
    else if (sff_clr_i)
        sff_o <= rst_val ;
    else if (sff_clk_en_i)
        sff_o <= sff_i ;
end
always @(posedge dst_clk_i or posedge dst_rst_i)
begin
    if (dst_rst_i)
        dst_o <= rst_val ;
    else if (dst_clr_i)
        dst_o <= rst_val ;
    else if (dst_clk_en_i)
        dst_o <= sff_o ;
end
endmodule // debug_if_synchronization_module 
// debug_if_to_mod_synchronization_module.v
// debug_if_defines.v
module debug_if_to_mod_synchronization_module 
(
    src_rst_i       ,
    src_clr_i       ,
    src_clk_i       ,
    src_clk_en_i    ,
    src_mux_comb_i  ,
    src_i           ,
    src_o           ,
    sff_rst_i       ,
    sff_clr_i       ,
    sff_clk_i       ,
    sff_clk_en_i    ,
    sff_o           ,
    dst_rst_i       ,
    dst_clr_i       ,
    dst_clk_i       ,
    dst_clk_en_i    ,
    dst_o            
) ;
parameter width         = 1             ;   // Width parameter of Input and Output signals 
parameter rst_val       = 0             ;   // Reset value parameter of Flip-Flop Output signals 
input                   src_rst_i       ;   // Source reset 
input                   src_clr_i       ;   // Source clear 
input                   src_clk_i       ;   // Source clock 
input                   src_clk_en_i    ;   // Source clock enable for source Flip-Flop 
input                   src_mux_comb_i  ;   // Source multiplexer select for combinatorial source input (i.e. from input PAD) 
input   [width - 1: 0]  src_i           ;   // Source input 
output  [width - 1: 0]  src_o           ;   // Source output - not synchronized 
input                   sff_rst_i       ;   // Synchronizer reset (i.e. same as destination reset) 
input                   sff_clr_i       ;   // Synchronizer clear
input                   sff_clk_i       ;   // Synchronizer clock (i.e. same as destination clock)  
input                   sff_clk_en_i    ;   // Synchronizer clok enable for synchronizer Flip-Flop  
output  [width - 1: 0]  sff_o           ;   // Synchronizer output  
input                   dst_rst_i       ;   // Destination reset 
input                   dst_clr_i       ;   // Destination clear 
input                   dst_clk_i       ;   // Destination clock 
input                   dst_clk_en_i    ;   // Destination clock enable for destination Flip-Flop  
output  [width - 1: 0]  dst_o           ;   // Destination output  
reg     [width - 1: 0]  src_o           ; 
reg     [width - 1: 0]  sff_o           ; 
reg     [width - 1: 0]  dst_o           ; 
reg     [width - 1: 0]  src             ; 
reg     [width - 1: 0]  sff_i           ;
always @(posedge src_clk_i or posedge src_rst_i)
begin
    if (src_rst_i)
        src <= rst_val ;
    else if (src_clr_i)
        src <= rst_val ;
    else if (src_clk_en_i)
        src <= src_i ;
end
always @(src_i or src or src_mux_comb_i)
begin
    if (src_mux_comb_i)
        src_o = src_i ;
    else
        src_o = src ;
end
always @(src_o)
    sff_i = src_o ;
always @(posedge sff_clk_i undefined)
begin
    if (sff_rst_i == undefined)
        sff_o <= rst_val ;
    else if (sff_clr_i)
        sff_o <= rst_val ;
    else if (sff_clk_en_i)
        sff_o <= sff_i ;
end
always @(posedge dst_clk_i undefined)
begin
    if (dst_rst_i == undefined)
        dst_o <= rst_val ;
    else if (dst_clr_i)
        dst_o <= rst_val ;
    else if (dst_clk_en_i)
        dst_o <= sff_o ;
end
endmodule // debug_if_synchronization_module 
// debug_if_crc.v
// debug_if_defines.v
// synopsys translate_off
// timescale.v
`timescale 1ns/10ps
// synopsys translate_on
module debug_if_crc
(
    clk_i       , // TAP clock 
    rst_i       , // TAP reset 
    clear_i     , // clear CRC register 
    enable_i    , // enable CRC calculation 
    shift_i     , // shift CRC register 
    data_i      , // serial DATA input 
    crc_msb_o   , // serial CRC output 
    crc_ok_o      // CRC status 
) ;
input           clk_i       ;
input           rst_i       ;
input           clear_i     ;
input           enable_i    ;
input           shift_i     ;
input           data_i      ;
output          crc_msb_o   ;
output          crc_ok_o    ;
reg     [ 7: 0] crc_reg         ;
wire    [ 7: 0] crc_poly        ;
wire            poly_sel        ;
wire            crc_reg_msb     ;
wire            crc_poly_msb    ;
assign  crc_poly = 8'h83 ;
assign  crc_reg_msb  = crc_reg [7] ;
assign  crc_poly_msb = crc_poly[7] ;
assign  poly_sel = (data_i) ^^ (crc_poly_msb && crc_reg_msb) ;
always @(posedge clk_i or posedge rst_i)
    begin
        if (rst_i)
            crc_reg <= 8'h00;
        else if (clear_i) 
            crc_reg <= 8'h00;
        else if (enable_i) begin
            crc_reg[7] <= crc_reg[6] ^ (crc_poly[6] & poly_sel) ;
            crc_reg[6] <= crc_reg[5] ^ (crc_poly[5] & poly_sel) ;
            crc_reg[5] <= crc_reg[4] ^ (crc_poly[4] & poly_sel) ;
            crc_reg[4] <= crc_reg[3] ^ (crc_poly[3] & poly_sel) ;
            crc_reg[3] <= crc_reg[2] ^ (crc_poly[2] & poly_sel) ;
            crc_reg[2] <= crc_reg[1] ^ (crc_poly[1] & poly_sel) ;
            crc_reg[1] <= crc_reg[0] ^ (crc_poly[0] & poly_sel) ;
            crc_reg[0] <= poly_sel ;
        end
        else if (shift_i)
            crc_reg[7:0] <= {crc_reg[6:0], 1'b0} ; 
    end
assign  crc_ok_o  = ~(|crc_reg) ;
assign  crc_msb_o = crc_reg_msb ;
endmodule
// debug_if_bus_module.v
// debug_if_defines.v
// synopsys translate_off
// timescale.v
`timescale 1ns/10ps
// synopsys translate_on
module debug_if_bus_module 
(
    tck_pad_i           , // JTAG Test ClocK pad                          
    trst_neg_pad_i      , // JTAG Test ReSeT negated pad                          
    mod_tap_reset_i     ,
    mod_clear_i         ,
    mod_sync_cmd_i      ,
    mod_sync_stat_i     ,
    mod_synced_cmd_o    ,
    mod_synced_stat_o   ,
    mod_command_i       , 
    mod_byte_sel_i      , 
    mod_address_i       , 
    mod_write_data_i    ,
    mod_read_data_o     ,
    mod_bus_ack_o       ,
    mod_bus_rty_o       ,
    mod_bus_err_o       ,
    wb_clk_i            , 
    wb_rst_i            , 
    wb_cyc_o            , 
    wb_stb_o            , 
    wb_we_o             , 
    wb_sel_o            , 
    wb_adr_o            , 
    wb_dat_o            , 
    wb_dat_i            , 
    wb_ack_i            , 
    wb_rty_i            , 
    wb_err_i            ,
    cpu_bp_i            , 
    cpu_stall_o         , 
    cpu_rst_o             
) ;
input           tck_pad_i           ; // JTAG Test ClocK pad         
input           trst_neg_pad_i      ; // JTAG Test ReSeT negated pad 
input           mod_tap_reset_i     ;
input           mod_clear_i         ;
input           mod_sync_cmd_i      ; 
input           mod_sync_stat_i     ; 
output          mod_synced_cmd_o    ; 
output          mod_synced_stat_o   ; 
input   [ 3: 0] mod_command_i       ;  
input   [ 3: 0] mod_byte_sel_i      ;  
input   [31: 0] mod_address_i       ;  
input   [31: 0] mod_write_data_i    ; 
output  [31: 0] mod_read_data_o     ; 
output          mod_bus_ack_o       ; 
output          mod_bus_rty_o       ; 
output          mod_bus_err_o       ; 
input           wb_clk_i            ; 
input           wb_rst_i            ; 
output          wb_cyc_o            ; 
output          wb_stb_o            ; 
output          wb_we_o             ; 
output  [ 3: 0] wb_sel_o            ; 
output  [31: 0] wb_adr_o            ; 
output  [31: 0] wb_dat_o            ; 
input   [31: 0] wb_dat_i            ; 
input           wb_ack_i            ; 
input           wb_rty_i            ; 
input           wb_err_i            ;
input           cpu_bp_i            ; 
output          cpu_stall_o         ; 
output          cpu_rst_o           ; 
reg             wb_cyc_o            ; 
reg             wb_stb_o            ; 
reg             wb_we_o             ; 
wire    [ 3: 0] src_mod_sync            ;
wire    [ 3: 0] dst_mod_sync            ;
wire            dst_mod_sync_cmd        ;
wire            dst_mod_sync_stat       ;
wire            wb_mod_clear            ;
wire            wb_tap_reset            ;
reg             dst_mod_sync_cmd_d1     ;
reg             dst_mod_sync_cmd_d2     ;
reg             dst_mod_sync_stat_d     ;
wire    [ 1: 0] src_mod_synced          ;
wire    [ 1: 0] dst_mod_synced          ;
wire            dst_mod_synced_cmd      ;
wire            dst_mod_synced_stat     ;
reg             dst_mod_synced_stat_d   ;
wire    [71: 0] src_mod_data            ;
wire    [71: 0] dst_mod_data            ;
wire            dst_mod_data_sync_en    ;
wire    [ 3: 0] dst_command             ;
wire    [ 3: 0] dst_byte_sel            ;
wire    [31: 0] dst_address             ;
wire    [31: 0] dst_write_data          ;
wire    [34: 0] src_wb_data             ;
wire    [34: 0] dst_wb_data             ;
wire            dst_wb_data_clk_en      ;
reg             mod_clear_d             ;
wire            command_valid           ;
reg             status_ready            ;
reg             src_wb_ack              ;
reg             src_wb_rty              ;
reg             src_wb_err              ;
reg             cpu_stall_reg           ;
reg             cpu_reset_reg           ;
reg     [31: 0] src_wb_rdat             ;
assign  src_mod_sync[3:0]   = {mod_tap_reset_i, mod_clear_i, mod_sync_stat_i, mod_sync_cmd_i} ;
debug_if_to_mod_synchronization_module #(4, 8) i_debug_if_to_mod_synchronization_module  // #(width, reset) value 
(
    .src_rst_i      (   trst_neg_pad_i      ),
    .src_clr_i      (   mod_tap_reset_i     ),
    .src_clk_i      (   tck_pad_i           ),
    .src_clk_en_i   (   1'b1                ),
    .src_mux_comb_i (   1'b0                ),
    .src_i          (   src_mod_sync        ),
    .src_o          (                       ),
    .sff_rst_i      (   wb_rst_i            ),
    .sff_clr_i      (   1'b0                ), 
    .sff_clk_i      (   wb_clk_i            ),
    .sff_clk_en_i   (   1'b1                ),
    .sff_o          (                       ),
    .dst_rst_i      (   wb_rst_i            ),
    .dst_clr_i      (   1'b0                ),
    .dst_clk_i      (   wb_clk_i            ),
    .dst_clk_en_i   (   1'b1                ),
    .dst_o          (   dst_mod_sync        ) 
) ;
assign  dst_mod_sync_cmd  = dst_mod_sync[0] ;
assign  dst_mod_sync_stat = dst_mod_sync[1] ;
assign  wb_mod_clear      = dst_mod_sync[2] ;
assign  wb_tap_reset      = dst_mod_sync[3] ;
always @(posedge wb_clk_i undefined)
    begin
        if (wb_rst_i == undefined) begin
            dst_mod_sync_cmd_d1 <= 1'b0 ;
            dst_mod_sync_cmd_d2 <= 1'b0 ;
            dst_mod_sync_stat_d <= 1'b0 ;
        end
        else begin
            dst_mod_sync_cmd_d1 <= dst_mod_sync_cmd    ;
            dst_mod_sync_cmd_d2 <= dst_mod_sync_cmd_d1 ;
            if (dst_mod_sync_stat && !dst_mod_sync_stat_d && status_ready)
                dst_mod_sync_stat_d <= 1'b1 ;
            else if (!dst_mod_sync_stat)
                dst_mod_sync_stat_d <= 1'b0 ;
        end
    end
assign  src_mod_synced[1:0] = {dst_mod_sync_stat_d, dst_mod_sync_cmd_d1} ;
debug_if_from_mod_synchronization_module #(2, 0) i_debug_if_from_mod_synchronization_module  // #(width, reset) value 
(
    .src_rst_i      (   wb_rst_i            ),
    .src_clr_i      (   1'b0                ),
    .src_clk_i      (   wb_clk_i            ),
    .src_clk_en_i   (   1'b1                ),
    .src_mux_comb_i (   1'b0                ),
    .src_i          (   src_mod_synced      ),
    .src_o          (                       ),
    .sff_rst_i      (   trst_neg_pad_i      ), 
    .sff_clr_i      (   mod_tap_reset_i     ),
    .sff_clk_i      (   tck_pad_i           ),
    .sff_clk_en_i   (   1'b1                ),
    .sff_o          (                       ),
    .dst_rst_i      (   trst_neg_pad_i      ),
    .dst_clr_i      (   mod_tap_reset_i     ),
    .dst_clk_i      (   tck_pad_i           ),
    .dst_clk_en_i   (   1'b1                ),
    .dst_o          (   dst_mod_synced      ) 
) ;
assign  dst_mod_synced_cmd  = dst_mod_synced[0] ;
assign  dst_mod_synced_stat = dst_mod_synced[1] ;
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i) 
            dst_mod_synced_stat_d <= 1'b0 ;
        else if (mod_tap_reset_i)
            dst_mod_synced_stat_d <= 1'b0 ;
        else
            dst_mod_synced_stat_d <= dst_mod_synced_stat ;
    end
assign  mod_synced_cmd_o  = dst_mod_synced_cmd    ;
assign  mod_synced_stat_o = dst_mod_synced_stat_d ;
assign  src_mod_data[71:0]   = {mod_command_i[3:0],  mod_byte_sel_i[3:0], 
                                mod_address_i[31:0], mod_write_data_i[31:0]} ;
assign  dst_mod_data_sync_en = dst_mod_sync_cmd && !dst_mod_sync_cmd_d1 ;
debug_if_to_mod_synchronization_module #(72, 0) i1_debug_if_to_mod_synchronization_module // #(width, reset) value 
(
    .src_rst_i      (   1'b1                            ),
    .src_clr_i      (   1'b1                            ),
    .src_clk_i      (   1'b1                            ),
    .src_clk_en_i   (   1'b1                            ),
    .src_mux_comb_i (   1'b1                            ),
    .src_i          (   src_mod_data                    ),
    .src_o          (                                   ),
    .sff_rst_i      (   wb_rst_i                        ), 
    .sff_clr_i      (   1'b0                            ),
    .sff_clk_i      (   wb_clk_i                        ),
    .sff_clk_en_i   (   dst_mod_data_sync_en            ),
    .sff_o          (   dst_mod_data                    ),
    .dst_rst_i      (   undefined    ),
    .dst_clr_i      (   1'b1                            ),
    .dst_clk_i      (   1'b1                            ),
    .dst_clk_en_i   (   1'b1                            ),
    .dst_o          (                                   ) 
) ;
assign  dst_command   [ 3:0] = dst_mod_data[71:68] ;
assign  dst_byte_sel  [ 3:0] = dst_mod_data[67:64] ;
assign  dst_address   [31:0] = dst_mod_data[63:32] ;
assign  dst_write_data[31:0] = dst_mod_data[31: 0] ;
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i) 
            mod_clear_d <= 1'b1 ;
        else if (mod_tap_reset_i)
            mod_clear_d <= 1'b1 ;
        else
            mod_clear_d <= mod_clear_i ;
    end
assign  src_wb_data[ 2:0]  = mod_clear_i ? 3'h0 : {src_wb_ack, src_wb_rty, src_wb_err} ;
assign  src_wb_data[34:3]  = src_wb_rdat[31:0] ;
assign  dst_wb_data_clk_en = (dst_mod_synced_stat && !dst_mod_synced_stat_d) || 
                             (mod_clear_i         && !mod_clear_d) ;
debug_if_from_mod_synchronization_module #(35, 0) i1_debug_if_from_mod_synchronization_module  // #(width, reset) value 
(
    .src_rst_i      (   undefined  ),
    .src_clr_i      (   1'b1                            ),
    .src_clk_i      (   1'b1                            ),
    .src_clk_en_i   (   1'b1                            ),
    .src_mux_comb_i (   1'b1                            ),
    .src_i          (   src_wb_data                     ),
    .src_o          (                                   ),
    .sff_rst_i      (   trst_neg_pad_i                  ),
    .sff_clr_i      (   mod_tap_reset_i                 ), 
    .sff_clk_i      (   tck_pad_i                       ),
    .sff_clk_en_i   (   dst_wb_data_clk_en              ),
    .sff_o          (   dst_wb_data                     ),
    .dst_rst_i      (   1'b1                            ),
    .dst_clr_i      (   1'b1                            ),
    .dst_clk_i      (   1'b1                            ),
    .dst_clk_en_i   (   1'b1                            ),
    .dst_o          (                                   ) 
) ;
assign  mod_read_data_o = dst_wb_data[34:3] ;
assign  mod_bus_ack_o   = dst_wb_data[2]    ;
assign  mod_bus_rty_o   = dst_wb_data[1]    ;
assign  mod_bus_err_o   = dst_wb_data[0]    ;
assign  command_valid = dst_mod_sync_cmd_d1 && !dst_mod_sync_cmd_d2 ;
always @(posedge wb_clk_i undefined)
    begin
        if (wb_rst_i == undefined) 
            status_ready <= 1'b0 ;
        else if (wb_tap_reset) 
            status_ready <= 1'b0 ;
        else begin
            if (command_valid)
                status_ready <= 1'b0 ;
            else if ( (dst_command[3:0] == 4'd04) || 
                      (dst_command[3:0] == 4'd05)      || 
                      (dst_command[3:0] == 4'd06)       ||
                      (((dst_command[3:0] == 4'd02) ||
                        (dst_command[3:0] == 4'd03)) && 
                       (wb_stb_o && (wb_ack_i || wb_rty_i || wb_err_i))) )
                status_ready <= 1'b1 ;
        end
    end
assign  wb_sel_o = dst_byte_sel  [ 3:0] ;
assign  wb_adr_o = dst_address   [31:0] ;
assign  wb_dat_o = dst_write_data[31:0] ;
always @(posedge wb_clk_i undefined)
    begin
        if (wb_rst_i == undefined) begin
            wb_cyc_o <= 1'b0 ;
            wb_stb_o <= 1'b0 ;
            wb_we_o  <= 1'b0 ;
        end
        else if (wb_tap_reset) begin
            wb_cyc_o <= 1'b0 ;
            wb_stb_o <= 1'b0 ;
            wb_we_o  <= 1'b0 ;
        end
        else begin
            if (wb_ack_i || wb_rty_i || wb_err_i || 
                (command_valid && 
                 (dst_command[3:0] == 4'd04))) begin
                wb_cyc_o <= 1'b0 ;
                wb_stb_o <= 1'b0 ;
            end
            else if (command_valid && 
                     ((dst_command[3:0] == 4'd02) || 
                      (dst_command[3:0] == 4'd03))) begin
                wb_cyc_o <= 1'b1 ;
                wb_stb_o <= 1'b1 ;
            end
            if (command_valid && (dst_command[3:0] == 4'd02)) 
                wb_we_o  <= 1'b1 ;
            else if (command_valid && (dst_command[3:0] == 4'd03))
                wb_we_o  <= 1'b0 ;
        end
    end
always @(posedge wb_clk_i undefined)
    begin
        if (wb_rst_i == undefined) begin
            src_wb_ack <= 1'b0 ;
            src_wb_rty <= 1'b0 ;
            src_wb_err <= 1'b0 ;
        end
        else if (wb_tap_reset) begin
            src_wb_ack <= 1'b0 ;
            src_wb_rty <= 1'b0 ;
            src_wb_err <= 1'b0 ;
        end
        else if (wb_stb_o && (wb_ack_i || wb_rty_i || wb_err_i)) begin
            src_wb_ack <= wb_ack_i ;
            src_wb_rty <= wb_rty_i ;
            src_wb_err <= wb_err_i ;
        end
        else if (command_valid) begin
            src_wb_ack <= 1'b0 ;
            src_wb_rty <= 1'b0 ;
            src_wb_err <= 1'b0 ;
        end
        else if (wb_mod_clear) begin
            src_wb_ack <= 1'b0 ;
            src_wb_rty <= 1'b0 ;
            src_wb_err <= 1'b0 ;
        end
    end
always @(posedge wb_clk_i undefined)
    begin
        if (wb_rst_i == undefined) begin
            cpu_stall_reg <= 1'b0 ;
            cpu_reset_reg <= 1'b0 ;
        end
        else if (wb_tap_reset) begin
            cpu_stall_reg <= 1'b0 ;
            cpu_reset_reg <= 1'b0 ;
        end
        else begin
            if (cpu_bp_i)
                cpu_stall_reg <= 1'b1 ;
            else if (command_valid && (dst_command[3:0] == 4'd05))
                cpu_stall_reg <= dst_write_data[0] ; 
            if (command_valid && (dst_command[3:0] == 4'd05))
                cpu_reset_reg <= dst_write_data[1] ;
        end
    end
assign  cpu_stall_o = cpu_stall_reg || cpu_bp_i ;
assign  cpu_rst_o   = cpu_reset_reg ;
always @(posedge wb_clk_i/* undefined*/)
    begin
        if (wb_rst_i == undefined)
            src_wb_rdat[31:0] <= 32'h0 ;
        else if (wb_tap_reset)
            src_wb_rdat[31:0] <= 32'h0 ;
        else begin
            if (wb_stb_o && wb_ack_i && (dst_command[3:0] == 4'd03))
                src_wb_rdat[31:0] <= wb_dat_i ;
            else if (command_valid && (dst_command[3:0] == 4'd06))
                src_wb_rdat[31:0] <= 32'h0 | (cpu_reset_reg << 1) | 
                                             (cpu_stall_reg << 0) ;
        end
    end
endmodule
// debug_if.v
// debug_if_defines.v
// synopsys translate_off
// timescale.v
`timescale 1ns/10ps
// synopsys translate_on
module debug_if
(
    tck_pad_i       , // JTAG Test ClocK pad                          
    trst_neg_pad_i  , // JTAG Test ReSeT negated pad                          
    tdi_i           , // TAP TDO signal 
    tdo_o           , // DEBUG TDO signal 
    debug_select_i  , 
    capture_dr_i    , 
    shift_dr_i      , 
    pause_dr_i      , 
    update_dr_i     , 
    mod_wb_clk_i    , 
    mod_wb_rst_i    , 
    mod_wb_cyc_o    , 
    mod_wb_stb_o    , 
    mod_wb_we_o     , 
    mod_wb_sel_o    , 
    mod_wb_adr_o    , 
    mod_wb_dat_o    , 
    mod_wb_dat_i    , 
    mod_wb_ack_i    , 
    mod_wb_rty_i    , 
    mod_wb_err_i    ,
    mod_cpu_bp_i    , 
    mod_cpu_stall_o , 
    mod_cpu_rst_o     
) ;
input           tck_pad_i           ; // JTAG Test ClocK pad         
input           trst_neg_pad_i      ; // JTAG Test ReSeT negated pad 
input           tdi_i               ; // TAP TDO signal 
output          tdo_o               ; // DEBUG TDO signal 
input           debug_select_i      ;
input           capture_dr_i        ;
input           shift_dr_i          ;
input           pause_dr_i          ;
input           update_dr_i         ;
input   [   (4'd1+1)-1: 0] mod_wb_clk_i ;
input   [   (4'd1+1)-1: 0] mod_wb_rst_i ;
output  [   (4'd1+1)-1: 0] mod_wb_cyc_o ;
output  [   (4'd1+1)-1: 0] mod_wb_stb_o ;
output  [   (4'd1+1)-1: 0] mod_wb_we_o  ;
output  [ 4*(4'd1+1)-1: 0] mod_wb_sel_o ;
output  [32*(4'd1+1)-1: 0] mod_wb_adr_o ;
output  [32*(4'd1+1)-1: 0] mod_wb_dat_o ;
input   [32*(4'd1+1)-1: 0] mod_wb_dat_i ;
input   [   (4'd1+1)-1: 0] mod_wb_ack_i ;
input   [   (4'd1+1)-1: 0] mod_wb_rty_i ;
input   [   (4'd1+1)-1: 0] mod_wb_err_i ;
input   [   (4'd1+1)-1: 0] mod_cpu_bp_i    ;
output  [   (4'd1+1)-1: 0] mod_cpu_stall_o ;
output  [   (4'd1+1)-1: 0] mod_cpu_rst_o   ;
reg             tdo_o               ; 
reg     [ 6: 0] shift_cnt           ;
reg     [79: 0] shift_reg           ;
wire            latch_module_valid  ;
wire            latch_cancel_valid  ;
wire            latch_reg_valid     ;
reg     [15: 0] cs_module           ;
reg     [ 3: 0] cs_modnum           ;
reg     [ 3: 0] command             ;
reg     [ 3: 0] byte_sel            ;
reg     [31: 0] address             ;
reg     [31: 0] write_data          ;
reg     [31: 0] read_data           ;
wire            bus_ack             ;
wire            bus_rty             ;
wire            bus_err             ;
wire    [ 7: 0] impl_ver            ;
wire    [ 7: 0] debug_ver           ;
wire    [23: 0] status              ;
reg             stat_crc_err        ;
reg             stat_overrun        ;
reg             stat_wrong_mod      ;
reg             stat_bus_err        ;
reg             stat_bus_rty        ;
reg             stat_bus_ack        ;
wire            stat_hw_busy        ;
wire            stat_hw_sync        ;
reg             stat_hw_busy_reg    ;
reg             stat_hw_sync_reg    ;
reg             stat_wrong_cmd      ;
wire            crc_out_clear       ; 
wire            crc_out_enable      ; 
wire            crc_out_shift       ; 
wire            crc_in_clear        ; 
wire            crc_in_enable       ; 
wire            crc_in_shift        ; 
wire            crc_out_msb         ; 
wire            crc_in_ok           ; 
reg             crc_in_ok_reg       ; 
reg     [2:0] cur_state ;
reg     [2:0] nxt_state ;
reg             tap_reset           ;
reg             sync_cmd            ;
reg             sync_stat           ;
wire            synced_cmd          ;
wire            synced_stat         ;
reg             synced_stat_d       ;
wire            mod_tap_reset       ;
wire    [15: 0] mod_clear           ;
wire    [15: 0] mod_sync_cmd        ;
wire    [15: 0] mod_sync_stat       ;
wire    [15: 0] mod_synced_cmd      ;
wire    [15: 0] mod_synced_stat     ;
wire   [511: 0] mod_read_data       ;
wire    [15: 0] mod_bus_ack         ;
wire    [15: 0] mod_bus_rty         ;
wire    [15: 0] mod_bus_err         ;
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            shift_cnt <= 7'd0 ;
        else if (!debug_select_i)
            shift_cnt <= 7'd0 ;
        else begin
            if (capture_dr_i)
                shift_cnt <= 7'd0 ;
            else if (shift_dr_i && (shift_cnt < 7'd82))
                shift_cnt <= shift_cnt + 1'b1 ;
        end
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            shift_reg[79:0] <= 80'h0 ;
        else if (!debug_select_i)
            shift_reg[79:0] <= 80'h0 ;
        else begin
            if (capture_dr_i) begin
                shift_reg[79:72] <= 8'h0 ;
                shift_reg[71:40] <= read_data[31:0] ;
                shift_reg[39:16] <= status   [23:0] ;
                shift_reg[15: 8] <= impl_ver [ 7:0] ;
                shift_reg[ 7: 0] <= debug_ver[ 7:0] ;
            end
            else if (shift_dr_i) 
                shift_reg[79:0] <= {tdi_i, shift_reg[79:1]} ;
        end
    end
always @(shift_cnt or shift_reg or crc_out_msb)
    begin
        if ((shift_cnt >= 7'd72) && (shift_cnt < 7'd80))
            tdo_o = crc_out_msb ;
        else
            tdo_o = shift_reg[0] ;
    end
assign  latch_module_valid = crc_in_ok_reg &&  
            (shift_reg[3:0] == 4'd01) && !stat_hw_busy_reg && 
            (shift_reg[43:40] <= 4'd1) ;
assign  latch_cancel_valid = crc_in_ok_reg &&  
            (shift_reg[3:0] == 4'd04) && !stat_hw_sync_reg ;
assign  latch_reg_valid = crc_in_ok_reg &&  
            (((shift_reg[3:0] == 4'd02  ) && !stat_hw_busy_reg) || 
             ((shift_reg[3:0] == 4'd03   ) && !stat_hw_busy_reg) || 
             ((shift_reg[3:0] == 4'd05) && !stat_hw_busy_reg) || 
             ((shift_reg[3:0] == 4'd06 ) && !stat_hw_busy_reg)) ;
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i) begin
            cs_module[15:0] <= 16'h1 ; 
            cs_modnum       <=  4'd0 ;
        end
        else if (!debug_select_i) begin
            cs_module[15:0] <= 16'h1 ; 
            cs_modnum       <=  4'd0 ;
        end
        else if (update_dr_i && latch_module_valid) begin
            case (shift_reg[43:40]) 
            4'd15 : cs_module[15:0] <= 16'h8000 ;
            4'd14 : cs_module[15:0] <= 16'h4000 ;
            4'd13 : cs_module[15:0] <= 16'h2000 ;
            4'd12 : cs_module[15:0] <= 16'h1000 ;
            4'd11 : cs_module[15:0] <= 16'h0800 ;
            4'd10 : cs_module[15:0] <= 16'h0400 ;
            4'd09  : cs_module[15:0] <= 16'h0200 ;
            4'd08  : cs_module[15:0] <= 16'h0100 ;
            4'd07  : cs_module[15:0] <= 16'h0080 ;
            4'd06  : cs_module[15:0] <= 16'h0040 ;
            4'd05  : cs_module[15:0] <= 16'h0020 ;
            4'd04  : cs_module[15:0] <= 16'h0010 ;
            4'd03  : cs_module[15:0] <= 16'h0008 ;
            4'd02  : cs_module[15:0] <= 16'h0004 ;
            4'd01  : cs_module[15:0] <= 16'h0002 ;
            4'd00  : cs_module[15:0] <= 16'h0001 ;
            default                 : cs_module[15:0] <= 16'hxxxx ;
            endcase
            case (shift_reg[43:40]) 
            4'd15 : cs_modnum <= 4'd15 ;
            4'd14 : cs_modnum <= 4'd14 ;
            4'd13 : cs_modnum <= 4'd13 ;
            4'd12 : cs_modnum <= 4'd12 ;
            4'd11 : cs_modnum <= 4'd11 ;
            4'd10 : cs_modnum <= 4'd10 ;
            4'd09  : cs_modnum <= 4'd9  ;
            4'd08  : cs_modnum <= 4'd8  ;
            4'd07  : cs_modnum <= 4'd7  ;
            4'd06  : cs_modnum <= 4'd6  ;
            4'd05  : cs_modnum <= 4'd5  ;
            4'd04  : cs_modnum <= 4'd4  ;
            4'd03  : cs_modnum <= 4'd3  ;
            4'd02  : cs_modnum <= 4'd2  ;
            4'd01  : cs_modnum <= 4'd1  ;
            4'd00  : cs_modnum <= 4'd0  ;
            default                 : cs_modnum <= 4'hx  ;
            endcase
        end
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            command[3:0] <= 4'd04 ;
        else if (!debug_select_i)
            command[3:0] <= 4'd04 ;
        else if (update_dr_i && (latch_reg_valid || latch_cancel_valid)) 
            command[3:0] <= shift_reg[3:0] ;
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            byte_sel[3:0] <= 4'h0 ;
        else if (!debug_select_i)
            byte_sel[3:0] <= 4'h0 ;
        else if (debug_select_i && update_dr_i && latch_reg_valid) 
            byte_sel[3:0] <= shift_reg[7:4] ;
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            address[31:0] <= 32'h0 ;
        else if (!debug_select_i)
            address[31:0] <= 32'h0 ;
        else if (debug_select_i && update_dr_i && latch_reg_valid) 
            address[31:0] <= shift_reg[39:8] ;
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            write_data[31:0] <= 32'h0 ;
        else if (!debug_select_i)
            write_data[31:0] <= 32'h0 ;
        else if (debug_select_i && update_dr_i && latch_reg_valid) 
            write_data[31:0] <= shift_reg[71:40] ;
    end
assign  impl_ver[7:0] = 8'h00 ;
assign  debug_ver[7:0] = 8'h03 ;
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            stat_crc_err <= 1'b0 ;
        else if (!debug_select_i)
            stat_crc_err <= 1'b0 ;
        else begin
            if (update_dr_i && crc_in_ok_reg)
                stat_crc_err <= 1'b0 ;
            else if (update_dr_i) 
                stat_crc_err <= 1'b1 ;
        end
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            stat_overrun <= 1'b0 ;
        else if (!debug_select_i)
            stat_overrun <= 1'b0 ;
        else begin
            if (update_dr_i && 
                (((shift_reg[3:0] == 4'd02  ) && stat_hw_busy_reg) || 
                 ((shift_reg[3:0] == 4'd03   ) && stat_hw_busy_reg) || 
                 ((shift_reg[3:0] == 4'd05) && stat_hw_busy_reg) || 
                 ((shift_reg[3:0] == 4'd06 ) && stat_hw_busy_reg) || 
                 ((shift_reg[3:0] == 4'd01   ) && stat_hw_busy_reg) || 
                 ((shift_reg[3:0] == 4'd04) && stat_hw_sync_reg)))
                stat_overrun <= 1'b1 ;
            else if (update_dr_i) 
                stat_overrun <= 1'b0 ;
        end
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            stat_wrong_mod <= 1'b0 ;
        else if (!debug_select_i)
            stat_wrong_mod <= 1'b0 ;
        else begin
            if (update_dr_i && 
                (shift_reg[3:0] == 4'd01) && 
                (shift_reg[43:40] > 4'd1))
                stat_wrong_mod <= 1'b1 ;
            else if (update_dr_i)
                stat_wrong_mod <= 1'b0 ;
        end
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i) begin
            stat_bus_ack <= 1'b0 ;
            stat_bus_rty <= 1'b0 ;
            stat_bus_err <= 1'b0 ;
        end
        else if (!debug_select_i) begin
            stat_bus_ack <= 1'b0 ;
            stat_bus_rty <= 1'b0 ;
            stat_bus_err <= 1'b0 ;
        end
        else begin
            if (update_dr_i && !stat_hw_busy_reg) begin
                stat_bus_ack <= 1'b0 ;
                stat_bus_rty <= 1'b0 ;
                stat_bus_err <= 1'b0 ;
            end
            else if (synced_stat && !synced_stat_d) begin
                stat_bus_ack <= bus_ack ;
                stat_bus_rty <= bus_rty ;
                stat_bus_err <= bus_err ;
            end
        end
    end
assign  stat_hw_busy = sync_cmd || synced_cmd || sync_stat || synced_stat ;
assign  stat_hw_sync = sync_cmd || synced_cmd ;
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i) begin
            stat_hw_busy_reg <= 1'b0 ;
            stat_hw_sync_reg <= 1'b0 ;
        end
        else if (!debug_select_i) begin
            stat_hw_busy_reg <= 1'b0 ;
            stat_hw_sync_reg <= 1'b0 ;
        end
        else begin
            if (capture_dr_i) begin
                stat_hw_busy_reg <= stat_hw_busy ;
                stat_hw_sync_reg <= stat_hw_sync ;
            end
        end
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            stat_wrong_cmd <= 1'b0 ;
        else if (!debug_select_i)
            stat_wrong_cmd <= 1'b0 ;
        else begin
            if (update_dr_i && 
                ((shift_reg[3:0] == 4'd00      ) || 
                 (shift_reg[3:0] == 4'd02  ) || 
                 (shift_reg[3:0] == 4'd03   ) || 
                 (shift_reg[3:0] == 4'd05) || 
                 (shift_reg[3:0] == 4'd06 ) || 
                 (shift_reg[3:0] == 4'd01   ) || 
                 (shift_reg[3:0] == 4'd04)))
                stat_wrong_cmd <= 1'b0 ;
            else if (update_dr_i) 
                stat_wrong_cmd <= 1'b1 ;
        end
    end
assign  status[0]   = stat_crc_err   ;
assign  status[1]   = stat_overrun   ;
assign  status[2] = stat_wrong_mod ;
assign  status[3]   = stat_bus_err   ;
assign  status[4]   = stat_bus_rty   ;
assign  status[5]   = stat_bus_ack   ;
assign  status[6]   = stat_hw_busy   ;
assign  status[7] = stat_wrong_cmd ;
assign  status[23:8] = 'h0 ;
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            synced_stat_d <= 1'b0 ;
        else if (!debug_select_i)
            synced_stat_d <= 1'b0 ;
        else
            synced_stat_d <= synced_stat ;
    end
assign  crc_out_clear   = capture_dr_i ;
assign  crc_out_enable  = debug_select_i && shift_dr_i && (shift_cnt <  7'd72) ;
assign  crc_out_shift   = debug_select_i && shift_dr_i && (shift_cnt >= 7'd72) ;
assign  crc_in_clear    = capture_dr_i ;
assign  crc_in_enable   = debug_select_i && shift_dr_i ;
assign  crc_in_shift    = 1'b0 ;
debug_if_crc i_debug_if_crc_out
(
    .clk_i          (   tck_pad_i       ), // TAP clock 
    .rst_i          (   trst_neg_pad_i  ), // TAP reset 
    .clear_i        (   crc_out_clear   ), // clear CRC register 
    .enable_i       (   crc_out_enable  ), // enable CRC calculation 
    .shift_i        (   crc_out_shift   ), // shift CRC register 
    .data_i         (   shift_reg[0]    ), // serial DATA input 
    .crc_msb_o      (   crc_out_msb     ), // serial CRC output 
    .crc_ok_o       (                   )  // CRC status 
) ;
debug_if_crc i_debug_if_crc_in
(
    .clk_i          (   tck_pad_i       ), // TAP clock 
    .rst_i          (   trst_neg_pad_i  ), // TAP reset 
    .clear_i        (   crc_in_clear    ), // clear CRC register 
    .enable_i       (   crc_in_enable   ), // enable CRC calculation 
    .shift_i        (   crc_in_shift    ), // shift CRC register 
    .data_i         (   tdi_i           ), // serial DATA input 
    .crc_msb_o      (                   ), // serial CRC output 
    .crc_ok_o       (   crc_in_ok       )  // CRC status 
) ;
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            crc_in_ok_reg <= 1'b1 ;
        else if (!debug_select_i)
            crc_in_ok_reg <= 1'b1 ;
        else
            crc_in_ok_reg <= crc_in_ok ;
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            cur_state <= 3'h0 ;
        else if (!debug_select_i)
            cur_state <= 3'h0 ;
        else
            cur_state <= nxt_state ;
    end
always @(cur_state or synced_cmd or synced_stat or 
         update_dr_i or latch_reg_valid or latch_cancel_valid)
    begin
        case (cur_state)
        3'h4 : 
            begin
                if (synced_cmd) begin
                    nxt_state = 3'h1 ;
                    sync_cmd  = 1'b0 ;
                end
                else begin
                    nxt_state = 3'h4 ;
                    sync_cmd  = 1'b1 ;
                end
                sync_stat = 1'b0 ;
            end
        3'h1 :
            begin
                if (!synced_cmd) begin
                    nxt_state = 3'h2 ;
                    sync_stat = 1'b1 ;
                end
                else begin
                    nxt_state = 3'h1 ;
                    sync_stat = 1'b0 ;
                end
                sync_cmd  = 1'b0 ;
            end
        3'h2 :
            begin
                if (synced_stat) begin
                    nxt_state = 3'h3 ;
                    sync_cmd  = 1'b0 ;
                    sync_stat = 1'b0 ;
                end
                else if (update_dr_i && latch_cancel_valid) begin
                    nxt_state = 3'h4 ;
                    sync_cmd  = 1'b1 ;
                    sync_stat = 1'b0 ;
                end
                else begin
                    nxt_state = 3'h2 ;
                    sync_cmd  = 1'b0 ;
                    sync_stat = 1'b1 ;
                end
            end
        3'h3 :
            begin
                if (!synced_stat) begin
                    nxt_state = 3'h0 ;
                    sync_cmd  = 1'b0 ;
                end
                else if (update_dr_i && latch_cancel_valid) begin
                    nxt_state = 3'h4 ;
                    sync_cmd  = 1'b1 ;
                end
                else begin
                    nxt_state = 3'h3 ;
                    sync_cmd  = 1'b0 ;
                end
                sync_stat = 1'b0 ;
            end
        default : // 3'h0 
            begin
                if (update_dr_i && (latch_reg_valid || latch_cancel_valid)) begin
                    nxt_state = 3'h4 ;
                    sync_cmd  = 1'b1 ;
                end
                else begin
                    nxt_state = 3'h0 ;
                    sync_cmd  = 1'b0 ;
                end
                sync_stat = 1'b0 ;
            end
        endcase 
    end
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            tap_reset <= 1'b1 ;
        else if (!debug_select_i)
            tap_reset <= 1'b1 ;
        else
            tap_reset <= 1'b0 ;
    end
assign  mod_tap_reset       = tap_reset ;
assign  mod_clear    [15:0] = ~cs_module[15:0] ;
assign  mod_sync_cmd [15:0] = {16{sync_cmd}}  & cs_module[15:0] ;
assign  mod_sync_stat[15:0] = {16{sync_stat}} & cs_module[15:0] ;
assign  synced_cmd          = |mod_synced_cmd [15:0] ;
assign  synced_stat         = |mod_synced_stat[15:0] ;
always @(cs_modnum or mod_read_data)
    begin
        case (cs_modnum[3:0]) 
        4'd15 : read_data = mod_read_data[32] ;
        4'd14 : read_data = mod_read_data[32] ;
        4'd13 : read_data = mod_read_data[32] ;
        4'd12 : read_data = mod_read_data[32] ;
        4'd11 : read_data = mod_read_data[32] ;
        4'd10 : read_data = mod_read_data[32] ;
        4'd09  : read_data = mod_read_data[32]  ;
        4'd08  : read_data = mod_read_data[32]  ;
        4'd07  : read_data = mod_read_data[32]  ;
        4'd06  : read_data = mod_read_data[32]  ;
        4'd05  : read_data = mod_read_data[32]  ;
        4'd04  : read_data = mod_read_data[32]  ;
        4'd03  : read_data = mod_read_data[32]  ;
        4'd02  : read_data = mod_read_data[32]  ;
        4'd01  : read_data = mod_read_data[32]  ;
        4'd00  : read_data = mod_read_data[32]  ;
        default                 : read_data = 32'hxxxx_xxxx ;
        endcase
    end
assign  bus_ack = |mod_bus_ack[15:0] ;
assign  bus_rty = |mod_bus_rty[15:0] ;
assign  bus_err = |mod_bus_err[15:0] ;
debug_if_bus_module i0_debug_if_bus_module
(
    .tck_pad_i          (   tck_pad_i                                       ),
    .trst_neg_pad_i     (   trst_neg_pad_i                                  ),
    .mod_tap_reset_i    (   mod_tap_reset                                   ),
    .mod_clear_i        (   mod_clear      [4'd00]         ),
    .mod_sync_cmd_i     (   mod_sync_cmd   [4'd00]         ),
    .mod_sync_stat_i    (   mod_sync_stat  [4'd00]         ),
    .mod_synced_cmd_o   (   mod_synced_cmd [4'd00]         ),
    .mod_synced_stat_o  (   mod_synced_stat[4'd00]         ),
    .mod_command_i      (   command        [ 3:0]                           ), 
    .mod_byte_sel_i     (   byte_sel       [ 3:0]                           ), 
    .mod_address_i      (   address        [31:0]                           ), 
    .mod_write_data_i   (   write_data     [31:0]                           ),
    .mod_read_data_o    (   mod_read_data  [32]   ),
    .mod_bus_ack_o      (   mod_bus_ack    [4'd00]         ),
    .mod_bus_rty_o      (   mod_bus_rty    [4'd00]         ),
    .mod_bus_err_o      (   mod_bus_err    [4'd00]         ),
    .wb_clk_i           (   mod_wb_clk_i   [4'd00]         ), 
    .wb_rst_i           (   mod_wb_rst_i   [4'd00]         ), 
    .wb_cyc_o           (   mod_wb_cyc_o   [4'd00]         ), 
    .wb_stb_o           (   mod_wb_stb_o   [4'd00]         ), 
    .wb_we_o            (   mod_wb_we_o    [4'd00]         ), 
    .wb_sel_o           (   mod_wb_sel_o   [4]   ), 
    .wb_adr_o           (   mod_wb_adr_o   [32]   ), 
    .wb_dat_o           (   mod_wb_dat_o   [32]   ), 
    .wb_dat_i           (   mod_wb_dat_i   [32]   ), 
    .wb_ack_i           (   mod_wb_ack_i   [4'd00]         ), 
    .wb_rty_i           (   mod_wb_rty_i   [4'd00]         ), 
    .wb_err_i           (   mod_wb_err_i   [4'd00]         ),
    .cpu_bp_i           (   mod_cpu_bp_i   [4'd00]         ), 
    .cpu_stall_o        (   mod_cpu_stall_o[4'd00]         ), 
    .cpu_rst_o          (   mod_cpu_rst_o  [4'd00]         )  
) ;
debug_if_bus_module i1_debug_if_bus_module
(
    .tck_pad_i          (   tck_pad_i                                       ),
    .trst_neg_pad_i     (   trst_neg_pad_i                                  ),
    .mod_tap_reset_i    (   mod_tap_reset                                   ),
    .mod_clear_i        (   mod_clear      [4'd01]         ),
    .mod_sync_cmd_i     (   mod_sync_cmd   [4'd01]         ),
    .mod_sync_stat_i    (   mod_sync_stat  [4'd01]         ),
    .mod_synced_cmd_o   (   mod_synced_cmd [4'd01]         ),
    .mod_synced_stat_o  (   mod_synced_stat[4'd01]         ),
    .mod_command_i      (   command        [ 3:0]                           ), 
    .mod_byte_sel_i     (   byte_sel       [ 3:0]                           ), 
    .mod_address_i      (   address        [31:0]                           ), 
    .mod_write_data_i   (   write_data     [31:0]                           ),
    .mod_read_data_o    (   mod_read_data  [32]   ),
    .mod_bus_ack_o      (   mod_bus_ack    [4'd01]         ),
    .mod_bus_rty_o      (   mod_bus_rty    [4'd01]         ),
    .mod_bus_err_o      (   mod_bus_err    [4'd01]         ),
    .wb_clk_i           (   mod_wb_clk_i   [4'd01]         ), 
    .wb_rst_i           (   mod_wb_rst_i   [4'd01]         ), 
    .wb_cyc_o           (   mod_wb_cyc_o   [4'd01]         ), 
    .wb_stb_o           (   mod_wb_stb_o   [4'd01]         ), 
    .wb_we_o            (   mod_wb_we_o    [4'd01]         ), 
    .wb_sel_o           (   mod_wb_sel_o   [4]   ), 
    .wb_adr_o           (   mod_wb_adr_o   [32]   ), 
    .wb_dat_o           (   mod_wb_dat_o   [32]   ), 
    .wb_dat_i           (   mod_wb_dat_i   [32]   ), 
    .wb_ack_i           (   mod_wb_ack_i   [4'd01]         ), 
    .wb_rty_i           (   mod_wb_rty_i   [4'd01]         ), 
    .wb_err_i           (   mod_wb_err_i   [4'd01]         ),
    .cpu_bp_i           (   mod_cpu_bp_i   [4'd01]         ), 
    .cpu_stall_o        (   mod_cpu_stall_o[4'd01]         ), 
    .cpu_rst_o          (   mod_cpu_rst_o  [4'd01]         )  
) ;
    assign  mod_synced_cmd [4'd02]         =  1'b0 ; 
    assign  mod_synced_stat[4'd02]         =  1'b0 ; 
    assign  mod_read_data  [32]   = 32'h0 ; 
    assign  mod_bus_ack    [4'd02]         =  1'b0 ; 
    assign  mod_bus_rty    [4'd02]         =  1'b0 ; 
    assign  mod_bus_err    [4'd02]         =  1'b0 ; 
    assign  mod_synced_cmd [4'd03]         =  1'b0 ; 
    assign  mod_synced_stat[4'd03]         =  1'b0 ; 
    assign  mod_read_data  [32]   = 32'h0 ; 
    assign  mod_bus_ack    [4'd03]         =  1'b0 ; 
    assign  mod_bus_rty    [4'd03]         =  1'b0 ; 
    assign  mod_bus_err    [4'd03]         =  1'b0 ; 
    assign  mod_synced_cmd [4'd04]         =  1'b0 ; 
    assign  mod_synced_stat[4'd04]         =  1'b0 ; 
    assign  mod_read_data  [32]   = 32'h0 ; 
    assign  mod_bus_ack    [4'd04]         =  1'b0 ; 
    assign  mod_bus_rty    [4'd04]         =  1'b0 ; 
    assign  mod_bus_err    [4'd04]         =  1'b0 ; 
    assign  mod_synced_cmd [4'd05]         =  1'b0 ; 
    assign  mod_synced_stat[4'd05]         =  1'b0 ; 
    assign  mod_read_data  [32]   = 32'h0 ; 
    assign  mod_bus_ack    [4'd05]         =  1'b0 ; 
    assign  mod_bus_rty    [4'd05]         =  1'b0 ; 
    assign  mod_bus_err    [4'd05]         =  1'b0 ; 
    assign  mod_synced_cmd [4'd06]         =  1'b0 ; 
    assign  mod_synced_stat[4'd06]         =  1'b0 ; 
    assign  mod_read_data  [32]   = 32'h0 ; 
    assign  mod_bus_ack    [4'd06]         =  1'b0 ; 
    assign  mod_bus_rty    [4'd06]         =  1'b0 ; 
    assign  mod_bus_err    [4'd06]         =  1'b0 ; 
    assign  mod_synced_cmd [4'd07]         =  1'b0 ; 
    assign  mod_synced_stat[4'd07]         =  1'b0 ; 
    assign  mod_read_data  [32]   = 32'h0 ; 
    assign  mod_bus_ack    [4'd07]         =  1'b0 ; 
    assign  mod_bus_rty    [4'd07]         =  1'b0 ; 
    assign  mod_bus_err    [4'd07]         =  1'b0 ; 
    assign  mod_synced_cmd [4'd08]         =  1'b0 ; 
    assign  mod_synced_stat[4'd08]         =  1'b0 ; 
    assign  mod_read_data  [32]   = 32'h0 ; 
    assign  mod_bus_ack    [4'd08]         =  1'b0 ; 
    assign  mod_bus_rty    [4'd08]         =  1'b0 ; 
    assign  mod_bus_err    [4'd08]         =  1'b0 ; 
    assign  mod_synced_cmd [4'd09]         =  1'b0 ; 
    assign  mod_synced_stat[4'd09]         =  1'b0 ; 
    assign  mod_read_data  [32]   = 32'h0 ; 
    assign  mod_bus_ack    [4'd09]         =  1'b0 ; 
    assign  mod_bus_rty    [4'd09]         =  1'b0 ; 
    assign  mod_bus_err    [4'd09]         =  1'b0 ; 
    assign  mod_synced_cmd [4'd10]        =  1'b0 ; 
    assign  mod_synced_stat[4'd10]        =  1'b0 ; 
    assign  mod_read_data  [32]  = 32'h0 ; 
    assign  mod_bus_ack    [4'd10]        =  1'b0 ; 
    assign  mod_bus_rty    [4'd10]        =  1'b0 ; 
    assign  mod_bus_err    [4'd10]        =  1'b0 ; 
    assign  mod_synced_cmd [4'd11]        =  1'b0 ; 
    assign  mod_synced_stat[4'd11]        =  1'b0 ; 
    assign  mod_read_data  [32]  = 32'h0 ; 
    assign  mod_bus_ack    [4'd11]        =  1'b0 ; 
    assign  mod_bus_rty    [4'd11]        =  1'b0 ; 
    assign  mod_bus_err    [4'd11]        =  1'b0 ; 
    assign  mod_synced_cmd [4'd12]        =  1'b0 ; 
    assign  mod_synced_stat[4'd12]        =  1'b0 ; 
    assign  mod_read_data  [32]  = 32'h0 ; 
    assign  mod_bus_ack    [4'd12]        =  1'b0 ; 
    assign  mod_bus_rty    [4'd12]        =  1'b0 ; 
    assign  mod_bus_err    [4'd12]        =  1'b0 ; 
    assign  mod_synced_cmd [4'd13]        =  1'b0 ; 
    assign  mod_synced_stat[4'd13]        =  1'b0 ; 
    assign  mod_read_data  [32]  = 32'h0 ; 
    assign  mod_bus_ack    [4'd13]        =  1'b0 ; 
    assign  mod_bus_rty    [4'd13]        =  1'b0 ; 
    assign  mod_bus_err    [4'd13]        =  1'b0 ; 
    assign  mod_synced_cmd [4'd14]        =  1'b0 ; 
    assign  mod_synced_stat[4'd14]        =  1'b0 ; 
    assign  mod_read_data  [32]  = 32'h0 ; 
    assign  mod_bus_ack    [4'd14]        =  1'b0 ; 
    assign  mod_bus_rty    [4'd14]        =  1'b0 ; 
    assign  mod_bus_err    [4'd14]        =  1'b0 ; 
    assign  mod_synced_cmd [4'd15]        =  1'b0 ; 
    assign  mod_synced_stat[4'd15]        =  1'b0 ; 
    assign  mod_read_data  [32]  = 32'h0 ; 
    assign  mod_bus_ack    [4'd15]        =  1'b0 ; 
    assign  mod_bus_rty    [4'd15]        =  1'b0 ; 
    assign  mod_bus_err    [4'd15]        =  1'b0 ; 
endmodule
