`include "tap_defines.v"

// synopsys translate_off
`include "timescale.v"
// synopsys translate_on

// TAP controller 
// -------------- 
// Fully JTAG compliant (IEEE Std 1149.1-2001) 
// Includes mandatory BYPASS register and optional ID register 
// Support for external mandatory BOUNDARY SCAN register 
// Support for external optional MEMORY BIST and DEBUG registers 

module tap
(
    // JTAG I/O pads
    tms_pad_i               , // JTAG Test Mode Select pad                    
    tck_pad_i               , // JTAG Test ClocK pad                          
    tck_neg_pad_i           , // JTAG Test ClocK negated pad                          
    trst_neg_pad_i          , // JTAG Test ReSeT negated pad                          
    tdi_pad_i               , // JTAG Test Data Input pad                     
    tdo_pad_o               , // JTAG Test Data Output pad                    
    tdo_padoe_o             , // output enable for JTAG Test Data Output pad 
    // TAP states
    capture_dr_o            ,
    shift_dr_o              ,
    pause_dr_o              , 
    update_dr_o             ,
    run_test_idle_o         , 
    test_logic_reset_o      ,
    // external TAP registers select signals 
    extest_select_o         , 
    sample_preload_select_o ,
    debug_select_o          ,
    mbist_select_o          ,
    // TDO signal for external TAP resgisters 
    tdo_o                   , 
    // TDI signals from external TAP resgisters 
    bscan_tdi_i             , // from boundary scan register 
    debug_tdi_i             , // from debug register (module)
    mbist_tdi_i               // from memory bist register 
) ;


// JTAG I/O pads
input           tms_pad_i               ; // JTAG Test Mode Select pad
input           tck_pad_i               ; // JTAG Test ClocK pad
input           tck_neg_pad_i           ; // JTAG Test ClocK negated pad
input           trst_neg_pad_i          ; // JTAG Test ReSeT negated pad
input           tdi_pad_i               ; // JTAG Test Data Input pad
output          tdo_pad_o               ; // JTAG Test Data Output pad
output          tdo_padoe_o             ; // output enable for JTAG Test Data Output pad 
// TAP states
output          capture_dr_o            ;
output          shift_dr_o              ;
output          pause_dr_o              ;
output          update_dr_o             ;
output          run_test_idle_o         ;
output          test_logic_reset_o      ;
// external TAP registers select signals 
output          extest_select_o         ;
output          sample_preload_select_o ;
output          debug_select_o          ;
output          mbist_select_o          ;
// TDO signal for external TAP resgisters 
output          tdo_o                   ;
// TDI signals from external TAP resgisters 
input           bscan_tdi_i             ; // from boundary scan register 
input           debug_tdi_i             ; // from debug register (module)
input           mbist_tdi_i             ; // from memory bist register  


reg             tdo_pad_o               ;
reg             tdo_padoe_o             ;



// internal signals 
reg             test_logic_reset        ;
reg             run_test_idle           ;
reg             select_dr_scan          ;
reg             capture_dr              ;
reg             shift_dr                ;
reg             exit1_dr                ;
reg             pause_dr                ;
reg             exit2_dr                ;
reg             update_dr               ;
reg             select_ir_scan          ;
reg             capture_ir              ;
reg             shift_ir                ;
reg             exit1_ir                ;
reg             pause_ir                ;
reg             exit2_ir                ;
reg             update_ir               ;

reg     [ 3: 0] jtag_inst_reg           ;
reg     [ 3: 0] latched_jtag_inst_reg   ;
reg     [31: 0] jtag_id_reg             ;
reg             jtag_bypass_reg         ;

reg             extest_select           ;
reg             sample_preload_select   ;
reg             id_reg_select           ;
reg             mbist_select            ;
reg             debug_select            ;
reg             bypass_reg_select       ;

reg             tms_q1                  ;
reg             tms_q2                  ;
reg             tms_q3                  ;
reg             tms_q4                  ;
wire            tms_reset               ;



//=============================================================================
//
// TMS Reset control logic 
//      5 consecutive logic '1' on TMS input causes reset 
//      
//=============================================================================

// registering TMS 
always @(posedge tck_pad_i)
    begin
        tms_q1 <= tms_pad_i ;
        tms_q2 <= tms_q1    ;
        tms_q3 <= tms_q2    ;
        tms_q4 <= tms_q3    ;
    end

// TMS reset 
assign  tms_reset = tms_q1 & tms_q2 & tms_q3 & tms_q4 & tms_pad_i ; 


//=============================================================================
//
// TAP State Machine 
// 
//=============================================================================

// test_logic_reset state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            test_logic_reset <= 1'b1 ;
        else if (tms_reset)
            test_logic_reset <= 1'b1 ;
        else begin
            if (tms_pad_i & (test_logic_reset | select_ir_scan))
                test_logic_reset <= 1'b1 ;
            else
                test_logic_reset <= 1'b0 ;
        end
    end

// run_test_idle state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            run_test_idle <= 1'b0 ;
        else if (tms_reset)
            run_test_idle <= 1'b0 ;
        else begin
            if (~tms_pad_i & (test_logic_reset | run_test_idle | update_dr | update_ir))
                run_test_idle <= 1'b1 ;
            else
                run_test_idle <= 1'b0 ;
        end
    end

// select_dr_scan state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            select_dr_scan <= 1'b0 ;
        else if (tms_reset)
            select_dr_scan <= 1'b0 ;
        else begin
            if (tms_pad_i & (run_test_idle | update_dr | update_ir))
                select_dr_scan <= 1'b1 ;
            else
                select_dr_scan <= 1'b0 ;
        end
    end

// capture_dr state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            capture_dr <= 1'b0 ;
        else if (tms_reset)
            capture_dr <= 1'b0 ;
        else begin
            if (~tms_pad_i & select_dr_scan)
                capture_dr <= 1'b1 ;
            else
                capture_dr <= 1'b0 ;
        end
    end

// shift_dr state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            shift_dr <= 1'b0 ;
        else if (tms_reset)
            shift_dr <= 1'b0 ;
        else begin
            if (~tms_pad_i & (capture_dr | shift_dr | exit2_dr))
                shift_dr <= 1'b1 ;
            else
                shift_dr <= 1'b0 ;
        end
    end

// exit1_dr state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            exit1_dr <= 1'b0 ;
        else if (tms_reset)
            exit1_dr <= 1'b0 ;
        else begin
            if (tms_pad_i & (capture_dr | shift_dr))
                exit1_dr <= 1'b1 ;
            else
                exit1_dr <= 1'b0 ;
        end
    end

// pause_dr state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            pause_dr <= 1'b0 ;
        else if (tms_reset)
            pause_dr <= 1'b0 ;
        else begin
            if (~tms_pad_i & (exit1_dr | pause_dr))
                pause_dr <= 1'b1 ;
            else
                pause_dr <= 1'b0 ;
        end
    end

// exit2_dr state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            exit2_dr <= 1'b0 ;
        else if (tms_reset)
            exit2_dr <= 1'b0 ;
        else begin
            if (tms_pad_i & pause_dr)
                exit2_dr <= 1'b1 ;
            else
                exit2_dr <= 1'b0 ;
        end
    end

// update_dr state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            update_dr <= 1'b0 ;
        else if (tms_reset)
            update_dr <= 1'b0 ;
        else begin
            if (tms_pad_i & (exit1_dr | exit2_dr))
                update_dr <= 1'b1 ;
            else
                update_dr <= 1'b0 ;
        end
    end

// select_ir_scan state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            select_ir_scan <= 1'b0 ;
        else if (tms_reset)
            select_ir_scan <= 1'b0 ;
        else begin
            if (tms_pad_i & select_dr_scan)
                select_ir_scan <= 1'b1 ;
            else
                select_ir_scan <= 1'b0 ;
        end
    end

// capture_ir state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            capture_ir <= 1'b0 ;
        else if (tms_reset)
            capture_ir <= 1'b0 ;
        else begin
            if (~tms_pad_i & select_ir_scan)
                capture_ir <= 1'b1 ;
            else
                capture_ir <= 1'b0 ;
        end
    end

// shift_ir state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            shift_ir <= 1'b0 ;
        else if (tms_reset)
            shift_ir <= 1'b0 ;
        else begin
            if (~tms_pad_i & (capture_ir | shift_ir | exit2_ir))
                shift_ir <= 1'b1 ;
            else
                shift_ir <= 1'b0 ;
        end
    end

// exit1_ir state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            exit1_ir <= 1'b0 ;
        else if (tms_reset)
            exit1_ir <= 1'b0 ;
        else begin
            if (tms_pad_i & (capture_ir | shift_ir))
                exit1_ir <= 1'b1 ;
            else
                exit1_ir <= 1'b0 ;
        end
    end

// pause_ir state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            pause_ir <= 1'b0 ;
        else if (tms_reset)
            pause_ir <= 1'b0 ;
        else begin
            if (~tms_pad_i & (exit1_ir | pause_ir))
                pause_ir <= 1'b1 ;
            else
                pause_ir <= 1'b0 ;
        end
    end

// exit2_ir state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            exit2_ir <= 1'b0 ;
        else if (tms_reset)
            exit2_ir <= 1'b0 ;
        else begin
            if (tms_pad_i & pause_ir)
                exit2_ir <= 1'b1 ;
            else
                exit2_ir <= 1'b0 ;
        end
    end

// update_ir state
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            update_ir <= 1'b0 ;
        else if (tms_reset)
            update_ir <= 1'b0 ;
        else begin
            if (tms_pad_i & (exit1_ir | exit2_ir))
                update_ir <= 1'b1 ;
            else
                update_ir <= 1'b0 ;
        end
    end


//=============================================================================
//
// JTAG Instruction Register (jtag_inst_reg) 
//      
//=============================================================================

// jtag_inst_reg
always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            jtag_inst_reg <= 4'b0 ;
        else if (capture_ir)
            jtag_inst_reg <= 4'b0101 ; // This value is fixed for easier fault detection
        else if (shift_ir)
            jtag_inst_reg <= {tdi_pad_i, jtag_inst_reg[3:1]} ;
    end

// latched_jtag_inst_reg 
always @(posedge tck_neg_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            latched_jtag_inst_reg <= `TAP_IDCODE ;   // IDCODE selected after reset
        else if (test_logic_reset)
            latched_jtag_inst_reg <= `TAP_IDCODE ;   // IDCODE selected 
        else if (update_ir)
            latched_jtag_inst_reg <= jtag_inst_reg ;
    end


//=============================================================================
//
// JTAG ID Register (jtag_id_reg) 
//      
//=============================================================================

always @(posedge tck_pad_i)
    begin
        if (id_reg_select & shift_dr)
            jtag_id_reg <= {tdi_pad_i, jtag_id_reg[31:1]} ;
        else
            jtag_id_reg <= `TAP_IDCODE_VALUE ;
    end


//=============================================================================
//
// JTAG Bypass Register (jtag_bypass_reg) 
//      
//=============================================================================

always @(posedge tck_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            jtag_bypass_reg <= 1'b0 ;
        else if (capture_dr)
            jtag_bypass_reg <= 1'b0 ;
        else if (shift_dr)
            jtag_bypass_reg <= tdi_pad_i ;
    end


//=============================================================================
//
// TAP register selection  
//      
//=============================================================================

always @(latched_jtag_inst_reg)
    begin
        extest_select           = 1'b0 ;
        sample_preload_select   = 1'b0 ;
        id_reg_select           = 1'b0 ;
        mbist_select            = 1'b0 ;
        debug_select            = 1'b0 ;
        bypass_reg_select       = 1'b0 ;
    
        case (latched_jtag_inst_reg) 
            `TAP_EXTEST         : extest_select         = 1'b1 ; // External test
            `TAP_SAMPLE_PRELOAD : sample_preload_select = 1'b1 ; // Sample preload
            `TAP_IDCODE         : id_reg_select         = 1'b1 ; // ID Code
            `TAP_MBIST          : mbist_select          = 1'b1 ; // Mbist test
            `TAP_DEBUG          : debug_select          = 1'b1 ; // Debug
            `TAP_BYPASS         : bypass_reg_select     = 1'b1 ; // BYPASS
            default             : bypass_reg_select     = 1'b1 ; // BYPASS
        endcase
    end


//=============================================================================
//
// Multiplexing JTAG TDO 
//      JTAG outputs have to be registered on falling edge of TCK 
//      
//=============================================================================

// JTAG Test Data Output 
always @(posedge tck_neg_pad_i or posedge trst_neg_pad_i)
    begin
        if (trst_neg_pad_i)
            tdo_pad_o <= 1'b1 ;
        else begin
            if (shift_ir)
                tdo_pad_o <= jtag_inst_reg[0] ;
            else begin
                case (latched_jtag_inst_reg)
                    `TAP_IDCODE         : tdo_pad_o <= jtag_id_reg      ;
                    `TAP_DEBUG          : tdo_pad_o <= debug_tdi_i      ;
                    `TAP_SAMPLE_PRELOAD : tdo_pad_o <= bscan_tdi_i      ;
                    `TAP_EXTEST         : tdo_pad_o <= bscan_tdi_i      ;
                    `TAP_MBIST          : tdo_pad_o <= mbist_tdi_i      ;
                    default             : tdo_pad_o <= jtag_bypass_reg  ;
                endcase
            end
        end
    end

// output enable for JTAG Test Data Output 
always @(posedge tck_neg_pad_i)
    begin
        tdo_padoe_o <= shift_ir | shift_dr ;
    end


//=============================================================================
//
// Output assignments for external TAP registers 
//      External registers need to know when they are selected and in which 
//      specific state TAP controller is when operating with Data Register. 
//      
//=============================================================================

// TAP data register state assignments 
assign  capture_dr_o        = capture_dr        ;
assign  shift_dr_o          = shift_dr          ;
assign  pause_dr_o          = pause_dr          ;
assign  update_dr_o         = update_dr         ;
assign  run_test_idle_o     = run_test_idle     ;
assign  test_logic_reset_o  = test_logic_reset  ;

// external TAP register select assignments 
assign  extest_select_o         = extest_select         ;
assign  sample_preload_select_o = sample_preload_select ;
assign  mbist_select_o          = mbist_select          ;
assign  debug_select_o          = debug_select          ;

// TDO for external TAP register assignment 
assign  tdo_o = tdi_pad_i ;



endmodule
