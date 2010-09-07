//
// Or1200 Monitor
//
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2009, 2010 Authors and OPENCORES.ORG           ////
////                                                              ////
//// This source file may be used and distributed without         ////
//// restriction provided that this copyright statement is not    ////
//// removed from the file and that any derivative work contains  ////
//// the original copyright notice and the associated disclaimer. ////
////                                                              ////
//// This source file is free software; you can redistribute it   ////
//// and/or modify it under the terms of the GNU Lesser General   ////
//// Public License as published by the Free Software Foundation; ////
//// either version 2.1 of the License, or (at your option) any   ////
//// later version.                                               ////
////                                                              ////
//// This source is distributed in the hope that it will be       ////
//// useful, but WITHOUT ANY WARRANTY; without even the implied   ////
//// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR      ////
//// PURPOSE.  See the GNU Lesser General Public License for more ////
//// details.                                                     ////
////                                                              ////
//// You should have received a copy of the GNU Lesser General    ////
//// Public License along with this source; if not, download it   ////
//// from http://www.opencores.org/lgpl.shtml                     ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

`include "timescale.v"
`include "or1200_defines.v"

//
// Top of OR1200 inside test bench
//
`ifndef OR1200_TOP
 `define OR1200_TOP orpsoc_testbench.dut.i_or1k.i_or1200_top
 `include "orpsoc_testbench_defines.v"
`else
 `include `TESTBENCH_DEFINES
`endif
//
// Enable display_arch_state task
//
//`define OR1200_DISPLAY_ARCH_STATE

//
// Top of OR1200 inside test bench
//
`define CPU or1200
`define CPU_cpu or1200_cpu
`define CPU_rf or1200_rf
`define CPU_except or1200_except
`define CPU_ctrl or1200_ctrl
`define CPU_sprs or1200_sprs

module or1200_monitor;

   integer fexe;
   reg [23:0] ref;
   integer    fspr;
   integer    fgeneral;
   integer    flookup;
   integer    r3;
   integer    insns;


   //
   // Initialization
   //
   initial begin
      ref = 0;
      fexe = $fopen({`TEST_RESULTS_DIR,`TEST_NAME_STRING,"-executed.log"});
      $timeformat (-9, 2, " ns", 12);
      fspr = $fopen({`TEST_RESULTS_DIR,`TEST_NAME_STRING,"-sprs.log"});
      fgeneral = $fopen({`TEST_RESULTS_DIR,`TEST_NAME_STRING,"-general.log"});
      flookup = $fopen({`TEST_RESULTS_DIR,`TEST_NAME_STRING,"-lookup.log"});
      insns = 0;

   end

   //
   // Get GPR
   //
   task get_gpr;
      input	[4:0]	gpr_no;
      output [31:0] 	gpr;
      integer 		j;
      begin

 `ifdef OR1200_RFRAM_GENERIC
	 for(j = 0; j < 32; j = j + 1) begin
	    gpr[j] = `OR1200_TOP.`CPU_cpu.`CPU_rf.rf_a.mem[gpr_no*32+j];
	 end
	 
 `else
	 //gpr = `OR1200_TOP.`CPU_cpu.`CPU_rf.rf_a.mem[gpr_no];
	 gpr = `OR1200_TOP.`CPU_cpu.`CPU_rf.rf_a.get_gpr(gpr_no);
	 
 `endif


      end
   endtask

   //
   // Write state of the OR1200 registers into a file
   //
   // Limitation: only a small subset of register file RAMs
   // are supported
   //
   task display_arch_state;
      reg [5:0] i;
      reg [31:0] r;
      integer 	 j;
      begin
`ifdef OR1200_DISPLAY_ARCH_STATE
	 ref = ref + 1;
	 $fdisplay(flookup, "Instruction %d: %t", insns, $time);
	 $fwrite(fexe, "\nEXECUTED(%d): %h:  %h", insns, `OR1200_TOP.`CPU_cpu.`CPU_except.wb_pc, `OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn);
	 for(i = 0; i < 32; i = i + 1) begin
	    if (i % 4 == 0)
	      $fdisplay(fexe);
	    get_gpr(i, r);
	    $fwrite(fexe, "GPR%d: %h  ", i, r);
	 end
	 $fdisplay(fexe);
	 r = `OR1200_TOP.`CPU_cpu.`CPU_sprs.sr;
	 $fwrite(fexe, "SR   : %h  ", r);
	 r = `OR1200_TOP.`CPU_cpu.`CPU_sprs.epcr;
	 $fwrite(fexe, "EPCR0: %h  ", r);
	 r = `OR1200_TOP.`CPU_cpu.`CPU_sprs.eear;
	 $fwrite(fexe, "EEAR0: %h  ", r);
	 r = `OR1200_TOP.`CPU_cpu.`CPU_sprs.esr;
	 $fdisplay(fexe, "ESR0 : %h", r);
`endif //  `ifdef OR1200_DISPLAY_ARCH_STATE
`ifdef OR1200_DISPLAY_EXECUTED
	 ref = ref + 1;
	 $fdisplay(flookup, "Instruction %d: %t", insns, $time);
	 $fwrite(fexe, "\nEXECUTED(%d): %h:  %h", insns, `OR1200_TOP.`CPU_cpu.`CPU_except.wb_pc, `OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn);
`endif
	 insns = insns + 1;
end
   endtask // display_arch_state

   /* Keep a trace buffer of the last lot of instructions and addresses 
    * "executed",as read from the writeback stage, and cause a $finish if we hit
    * an instruction that is invalid, such as all zeros.
    * Currently, only breaks on an all zero instruction, but should probably be 
    * made to break for anything with an X in it too. And of course ideally this
    * shouldn't be needed - but is handy if someone changes something and stops
    * the test continuing forever.
    */
   integer num_nul_inst;
   initial num_nul_inst = 0;
      
   task monitor_for_crash;
`define OR1200_MONITOR_CRASH_TRACE_SIZE 32
      //Trace buffer of 32 instructions
      reg [31:0] insn_trace [0:`OR1200_MONITOR_CRASH_TRACE_SIZE-1];
      //Trace buffer of the addresses of those instructions
      reg [31:0] addr_trace [0:`OR1200_MONITOR_CRASH_TRACE_SIZE-1]; 
      integer i;
      
     begin
	if (`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn == 32'h00000000)
	  num_nul_inst = num_nul_inst + 1;
	else
	  num_nul_inst = 0; // Reset it

	if (num_nul_inst == 1000) // Sat a loop a bit too long...
	  begin
	     $fdisplay(fgeneral, "ERROR - no instruction at PC %h", 
		       `OR1200_TOP.`CPU_cpu.`CPU_except.wb_pc);
	     $fdisplay(fgeneral, "Crash trace: Last %d instructions: ",
		       `OR1200_MONITOR_CRASH_TRACE_SIZE);

	     $fdisplay(fgeneral, "PC\t\tINSTR");
	     for(i=`OR1200_MONITOR_CRASH_TRACE_SIZE-1;i>=0;i=i-1) begin
		$fdisplay(fgeneral, "%h\t%h",addr_trace[i], insn_trace[i]);
	     end
	     #100 $finish;
	  end
	else
	  begin
	     for(i=`OR1200_MONITOR_CRASH_TRACE_SIZE-1;i>0;i=i-1) begin
		insn_trace[i] = insn_trace[i-1];
		addr_trace[i] = addr_trace[i-1];
	     end
	     insn_trace[0] = `OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn;
	     addr_trace[0] = `OR1200_TOP.`CPU_cpu.`CPU_except.wb_pc;
	  end
	
     end
   endtask // monitor_for_crash
   

   //
   // Write state of the OR1200 registers into a file; version for exception
   //
   task display_arch_state_except;
      reg [5:0] i;
      reg [31:0] r;
      integer 	 j;
      begin
`ifdef OR1200_DISPLAY_ARCH_STATE
	 ref = ref + 1;
	 $fdisplay(flookup, "Instruction %d: %t", insns, $time);
	 $fwrite(fexe, "\nEXECUTED(%d): %h:  %h  (exception)", insns, `OR1200_TOP.`CPU_cpu.`CPU_except.ex_pc, `OR1200_TOP.`CPU_cpu.`CPU_ctrl.ex_insn);
	 for(i = 0; i < 32; i = i + 1) begin
	    if (i % 4 == 0)
	      $fdisplay(fexe);
	    get_gpr(i, r);
	    $fwrite(fexe, "GPR%d: %h  ", i, r);
	 end
	 $fdisplay(fexe);
	 r = `OR1200_TOP.`CPU_cpu.`CPU_sprs.sr;
	 $fwrite(fexe, "SR   : %h  ", r);
	 r = `OR1200_TOP.`CPU_cpu.`CPU_sprs.epcr;
	 $fwrite(fexe, "EPCR0: %h  ", r);
	 r = `OR1200_TOP.`CPU_cpu.`CPU_sprs.eear;
	 $fwrite(fexe, "EEAR0: %h  ", r);
	 r = `OR1200_TOP.`CPU_cpu.`CPU_sprs.esr;
	 $fdisplay(fexe, "ESR0 : %h", r);
         insns = insns + 1;
`endif //  `ifdef OR1200_DISPLAY_ARCH_STATE
`ifdef OR1200_DISPLAY_EXECUTED
	 ref = ref + 1;
	 $fdisplay(flookup, "Instruction %d: %t", insns, $time);
	 $fwrite(fexe, "\nEXECUTED(%d): %h:  %h  (exception)", insns, 
		 `OR1200_TOP.`CPU_cpu.`CPU_except.ex_pc, 
		 `OR1200_TOP.`CPU_cpu.`CPU_ctrl.ex_insn);
	 insns = insns + 1;
`endif
	 
end
   endtask

   integer iwb_progress;
   reg [31:0] iwb_progress_addr;
   //
   // WISHBONE bus checker
   //
   always @(posedge `OR1200_TOP.iwb_clk_i)
     if (`OR1200_TOP.iwb_rst_i) begin
	iwb_progress = 0;
	iwb_progress_addr = `OR1200_TOP.iwb_adr_o;
     end
     else begin
	if (`OR1200_TOP.iwb_cyc_o && (iwb_progress != 2)) begin
	   iwb_progress = 1;
	end
	if (`OR1200_TOP.iwb_stb_o) begin
	   if (iwb_progress >= 1) begin
	      if (iwb_progress == 1)
		iwb_progress_addr = `OR1200_TOP.iwb_adr_o; 
	      iwb_progress = 2;
	   end
	   else begin
	      $fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.iwb_stb_o raised without `OR1200_TOP.iwb_cyc_o, at %t\n", $time);
	      #100 $finish;
	   end
	end
	if (`OR1200_TOP.iwb_ack_i & `OR1200_TOP.iwb_err_i) begin
	   $fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.iwb_ack_i and `OR1200_TOP.iwb_err_i raised at the same time, at %t\n", $time);
	end
	if ((iwb_progress == 2) && (iwb_progress_addr != `OR1200_TOP.iwb_adr_o)) begin
	   $fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.iwb_adr_o changed while waiting for `OR1200_TOP.iwb_err_i/`OR1200_TOP.iwb_ack_i, at %t\n", $time);
	   #100 $finish;
	end
	if (`OR1200_TOP.iwb_ack_i | `OR1200_TOP.iwb_err_i)
	  if (iwb_progress == 2) begin
	     iwb_progress = 0;
	     iwb_progress_addr = `OR1200_TOP.iwb_adr_o;
	  end
	  else begin
	     $fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.iwb_ack_i/`OR1200_TOP.iwb_err_i raised without `OR1200_TOP.iwb_cyc_i/`OR1200_TOP.iwb_stb_i, at %t\n", $time);
	     #100 $finish;
	  end
	if ((iwb_progress == 2) && !`OR1200_TOP.iwb_stb_o) begin
	   $fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.iwb_stb_o lowered without `OR1200_TOP.iwb_err_i/`OR1200_TOP.iwb_ack_i, at %t\n", $time);
	   #100 $finish;
	end
     end

   integer dwb_progress;
reg [31:0] dwb_progress_addr;
//
// WISHBONE bus checker
//
always @(posedge `OR1200_TOP.dwb_clk_i)
  if (`OR1200_TOP.dwb_rst_i)
    dwb_progress = 0;
  else begin
     if (`OR1200_TOP.dwb_cyc_o && (dwb_progress != 2))
       dwb_progress = 1;
     if (`OR1200_TOP.dwb_stb_o)
       if (dwb_progress >= 1) begin
	  if (dwb_progress == 1)
	    dwb_progress_addr = `OR1200_TOP.dwb_adr_o; 
	  dwb_progress = 2;
       end
       else begin
	  $fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.dwb_stb_o raised without `OR1200_TOP.dwb_cyc_o, at %t\n", $time);
	  #100 $finish;
       end
     if (`OR1200_TOP.dwb_ack_i & `OR1200_TOP.dwb_err_i) begin
	$fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.dwb_ack_i and `OR1200_TOP.dwb_err_i raised at the same time, at %t\n", $time);
     end
     if ((dwb_progress == 2) && (dwb_progress_addr != `OR1200_TOP.dwb_adr_o)) begin
	$fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.dwb_adr_o changed while waiting for `OR1200_TOP.dwb_err_i/`OR1200_TOP.dwb_ack_i, at %t\n", $time);
	#100 $finish;
     end
     if (`OR1200_TOP.dwb_ack_i | `OR1200_TOP.dwb_err_i)
       if (dwb_progress == 2) begin
	  dwb_progress = 0;
	  dwb_progress_addr = `OR1200_TOP.dwb_adr_o;
       end
       else begin
	  $fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.dwb_ack_i/`OR1200_TOP.dwb_err_i raised without `OR1200_TOP.dwb_cyc_i/`OR1200_TOP.dwb_stb_i, at %t\n", $time);
	  #100 $finish;
       end
     if ((dwb_progress == 2) && !`OR1200_TOP.dwb_stb_o) begin
	$fdisplay(fgeneral, "WISHBONE protocol violation: `OR1200_TOP.dwb_stb_o lowered without `OR1200_TOP.dwb_err_i/`OR1200_TOP.dwb_ack_i, at %t\n", $time);
	#100 $finish;
     end
       end

//
// Hooks for:
// - displaying registers
// - end of simulation
// - access to SPRs
//
   always @(posedge `OR1200_TOP.`CPU_cpu.`CPU_ctrl.clk)
     if (!`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_freeze) begin
//	#2;
	if (((`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn[31:26] != `OR1200_OR32_NOP)
	     | !`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn[16])
	    & !(`OR1200_TOP.`CPU_cpu.`CPU_except.except_flushpipe & 
		`OR1200_TOP.`CPU_cpu.`CPU_except.ex_dslot))
	  begin
	     display_arch_state;
	     monitor_for_crash;
	  end
	else
	  if (`OR1200_TOP.`CPU_cpu.`CPU_except.except_flushpipe)
	    display_arch_state_except;
	// small hack to stop simulation (l.nop 1):
	if (`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn == 32'h1500_0001) begin
	   get_gpr(3, r3);
	   $fdisplay(fgeneral, "%t: l.nop exit (%h)", $time, r3);
	   $finish;
	end
	// debug if test (l.nop 10)
	if (`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn == 32'h1500_000a) begin
	   $fdisplay(fgeneral, "%t: l.nop dbg_if_test", $time);
`ifdef DBG_IF_MODEL
	   xess_top.i_xess_fpga.dbg_if_model.dbg_if_test_go = 1;
`endif
	end
	// simulation reports (l.nop 2)
	if (`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn == 32'h1500_0002) begin 
	   get_gpr(3, r3);
	   $fdisplay(fgeneral, "%t: l.nop report (%h)", $time, r3);
	end
	// simulation printfs (l.nop 3)
	if (`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn == 32'h1500_0003) begin 
	   get_gpr(3, r3);
	   $fdisplay(fgeneral, "%t: l.nop printf (%h)", $time, r3);
	end
	if (`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn == 32'h1500_0004) begin 
	   // simulation putc (l.nop 4)
	   get_gpr(3, r3);
	   $write("%c", r3);
	   $fdisplay(fgeneral, "%t: l.nop putc (%c)", $time, r3);
	end
	if (`OR1200_TOP.`CPU_cpu.alu_op/*`CPU_sprs.sprs_op*/ == 
	    `OR1200_ALUOP_MTSR)  // l.mtspr
	  $fdisplay(fspr, "%t: Write to SPR : [%h] <- %h", $time,
		    `OR1200_TOP.`CPU_cpu.alu_op/*`CPU_sprs.spr_addr*/, 
		    `OR1200_TOP.`CPU_cpu.`CPU_sprs.spr_dat_o);
	if (`OR1200_TOP.`CPU_cpu.alu_op/*`CPU_sprs.sprs_op*/ == 
	    `OR1200_ALUOP_MFSR)  // l.mfspr
	  $fdisplay(fspr, "%t: Read from SPR: [%h] -> %h", $time,
		    `OR1200_TOP.`CPU_cpu.`CPU_sprs.spr_addr, 
		    `OR1200_TOP.`CPU_cpu.`CPU_sprs.to_wbmux);
     end


`ifdef VERSATILE_SDRAM
 `define SDRAM_TOP design_testbench.sdram0
   // Bit selects to define the bank
   // 32 MB part with 4 banks
 `define SDRAM_BANK_SEL_BITS 24:23
 `define SDRAM_WORD_SEL_TOP_BIT 22
   // Gets instruction word from correct bank
   task get_insn_from_sdram;
      input [31:0] addr;
      output [31:0] insn;
      reg [`SDRAM_WORD_SEL_TOP_BIT-1:0] word_addr;
 
      begin
	 word_addr = addr[`SDRAM_WORD_SEL_TOP_BIT:2];	 
	 if (addr[`SDRAM_BANK_SEL_BITS] == 2'b00)
	   begin
	      
	      //$display("%t: get_insn_from_sdram bank0, word 0x%h, (%h and %h in SDRAM)", $time, word_addr, `SDRAM_TOP.Bank0[{word_addr,1'b0}], `SDRAM_TOP.Bank0[{word_addr,1'b1}]);	      
	      insn[15:0] = `SDRAM_TOP.Bank0[{word_addr,1'b1}];
	      insn[31:16] = `SDRAM_TOP.Bank0[{word_addr,1'b0}];
	   end
      end
      
   endtask // get_insn_from_sdram
`endif //  `ifdef VERSATILE_SDRAM

`ifdef XILINX_DDR2
 `define DDR2_TOP design_testbench.gen_cs[0]
   // Gets instruction word from correct bank
   task get_insn_from_xilinx_ddr2;
      input [31:0] addr;
      output [31:0] insn;
      reg [16*8-1:0] ddr2_array_line0,ddr2_array_line1,ddr2_array_line2,ddr2_array_line3;
      integer 	     word_in_line_num;      
      begin
	// Get our 4 128-bit chunks (8 half-words in each!! Confused yet?), 16 words total
	 `DDR2_TOP.gen[0].u_mem0.memory_read(addr[28:27],addr[26:13],{addr[12:6],3'd0},ddr2_array_line0);
	 `DDR2_TOP.gen[1].u_mem0.memory_read(addr[28:27],addr[26:13],{addr[12:6],3'd0},ddr2_array_line1);
	 `DDR2_TOP.gen[2].u_mem0.memory_read(addr[28:27],addr[26:13],{addr[12:6],3'd0},ddr2_array_line2);
	 `DDR2_TOP.gen[3].u_mem0.memory_read(addr[28:27],addr[26:13],{addr[12:6],3'd0},ddr2_array_line3);
	 case (addr[5:2])
	   4'h0:
	     begin
		insn[15:0] = ddr2_array_line0[15:0];
		insn[31:16] = ddr2_array_line1[15:0];
	     end
	   4'h1:
	     begin
		insn[15:0] = ddr2_array_line2[15:0];
		insn[31:16] = ddr2_array_line3[15:0];
	     end
	   4'h2:
	     begin
		insn[15:0] = ddr2_array_line0[31:16];
		insn[31:16] = ddr2_array_line1[31:16];
	     end
	   4'h3:
	     begin
		insn[15:0] = ddr2_array_line2[31:16];
		insn[31:16] = ddr2_array_line3[31:16];
	     end
	   4'h4:
	     begin
		insn[15:0] = ddr2_array_line0[47:32];
		insn[31:16] = ddr2_array_line1[47:32];
	     end
	   4'h5:
	     begin
		insn[15:0] = ddr2_array_line2[47:32];
		insn[31:16] = ddr2_array_line3[47:32];
	     end
	   4'h6:
	     begin
		insn[15:0] = ddr2_array_line0[63:48];
		insn[31:16] = ddr2_array_line1[63:48];
	     end
	   4'h7:
	     begin
		insn[15:0] = ddr2_array_line2[63:48];
		insn[31:16] = ddr2_array_line3[63:48];
	     end
	   4'h8:
	     begin
		insn[15:0] = ddr2_array_line0[79:64];
		insn[31:16] = ddr2_array_line1[79:64];
	     end
	   4'h9:
	     begin
		insn[15:0] = ddr2_array_line2[79:64];
		insn[31:16] = ddr2_array_line3[79:64];
	     end
	   4'ha:
	     begin
		insn[15:0] = ddr2_array_line0[95:80];
		insn[31:16] = ddr2_array_line1[95:80];
	     end
	   4'hb:
	     begin
		insn[15:0] = ddr2_array_line2[95:80];
		insn[31:16] = ddr2_array_line3[95:80];
	     end
	   4'hc:
	     begin
		insn[15:0] = ddr2_array_line0[111:96];
		insn[31:16] = ddr2_array_line1[111:96];
	     end
	   4'hd:
	     begin
		insn[15:0] = ddr2_array_line2[111:96];
		insn[31:16] = ddr2_array_line3[111:96];
	     end
	   4'he:
	     begin
		insn[15:0] = ddr2_array_line0[127:112];
		insn[31:16] = ddr2_array_line1[127:112];
	     end
	   4'hf:
	     begin
		insn[15:0] = ddr2_array_line2[127:112];
		insn[31:16] = ddr2_array_line3[127:112];
	     end	   
	 endcase // case (addr[5:2])
      end
   endtask // get_insn_from_xilinx_ddr2
`endif   
   
   
   task get_insn_from_memory;
      input [31:0] id_pc;
      output [31:0] insn;
      begin
	 // do a decode of which server we should look in
	 case (id_pc[31:28])
`ifdef VERSATILE_SDRAM
	   4'h0:
	     get_insn_from_sdram(id_pc, insn);
`endif
`ifdef XILINX_DDR2
	   4'h0:
	     get_insn_from_xilinx_ddr2(id_pc, insn);
`endif	   
	   4'hf:
	     // Flash isn't stored in a memory, it's an FSM so just skip/ignore
	     insn = `OR1200_TOP.`CPU_cpu.`CPU_ctrl.id_insn;
	   default:
	     begin
		$fdisplay(fgeneral, "%t: Unknown memory server for address 0x%h", $time,id_pc);
		insn = 32'hxxxxxxxx; // Unknown server
	     end
	 endcase // case (id_pc[31:28])
      end
   endtask // get_insn_from_memory
   

    reg [31:0] mem_word;
   reg [31:0] last_addr = 0;
   reg [31:0] last_mem_word;

//`define TRIGGER_FOR_CHECK (`OR1200_TOP.`CPU_cpu.`CPU_ctrl.id_void === 1'b0)
   // Disabled:
`define TRIGGER_FOR_CHECK 0
`define INSN_TO_CHECK `OR1200_TOP.`CPU_cpu.`CPU_ctrl.id_insn
`define PC_TO_CHECK `OR1200_TOP.`CPU_cpu.`CPU_except.id_pc
   
   // Check instruction in decode stage is what is in the RAM
   always @(posedge `OR1200_TOP.`CPU_cpu.`CPU_ctrl.clk)
     begin
	if (`TRIGGER_FOR_CHECK)
	  begin
	     // Check if it's a new PC - will also get triggered if the
	     // instruction has changed since we last checked it
	     if ((`PC_TO_CHECK !== last_addr) ||
		 (last_mem_word != `INSN_TO_CHECK))
	       begin
		  // Decode stage not void, check instruction
		  // get PC
		  get_insn_from_memory(`PC_TO_CHECK, mem_word);

		  // Debugging output to prove it's doing something!
		  //$display("%t: Checking instruction for address 0x%h - memory had 0x%h, CPU had 0x%h", $time, `PC_TO_CHECK, mem_word, `INSN_TO_CHECK);
		  
		  if (mem_word !== `INSN_TO_CHECK)
		    begin
		       $fdisplay(fgeneral, "%t: Instruction mismatch for address 0x%h - memory had 0x%h, CPU had 0x%h", $time, `PC_TO_CHECK, mem_word, `INSN_TO_CHECK);
		       #20
			 $finish;		  
		    end
		  last_addr = `PC_TO_CHECK;
		  last_mem_word = mem_word;		  
	       end // if (`PC_TO_CHECK !== last_addr)
	  end
     end // always @ (posedge `OR1200_TOP.`CPU_cpu.`CPU_ctrl.clk)
      



   
endmodule
