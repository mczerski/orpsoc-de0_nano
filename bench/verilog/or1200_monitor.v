//////////////////////////////////////////////////////////////////////
////                                                              ////
////  or1200_monitor                                              ////
////                                                              ////
////  OR1200 processor monitor module                             ////
////                                                              ////
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
`include "orpsoc-testbench-defines.v"
`include "test-defines.v"

//
// Top of TB
//
`define TB_TOP orpsoc_testbench
			 
//
// Top of DUT
//
`define DUT_TOP `TB_TOP.dut
			 
//
// Top of OR1200 inside test bench
//
`define OR1200_TOP `DUT_TOP.or1200_top0

//
// Define to enable lookup file generation
//
//`define OR1200_MONITOR_LOOKUP

//
// Define to enable SPR access log file generation
//
//`define OR1200_MONITOR_SPRS

//
// Enable logging of state during execution
//
//`define OR1200_MONITOR_EXEC_STATE

//
// Enable disassembly of instructions in execution state log
//
//`define OR1200_MONITOR_PRINT_DISASSEMBLY

// Can either individually enable things above, or usually have the scripts
// running the simulation pass the PROCESSOR_MONITOR_ENABLE_LOGS define to
// enable them all.

`ifdef PROCESSOR_MONITOR_ENABLE_LOGS
 `define OR1200_MONITOR_EXEC_STATE
 `define OR1200_MONITOR_SPRS
 `define OR1200_MONITOR_LOOKUP
`endif

//
// Memory coherence checking (double check instruction in fetch stage against
// what is in memory.)
//
//`define MEM_COHERENCE_CHECK

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
`ifdef OR1200_MONITOR_SPRS   
   integer    fspr;
`endif   
   integer    fgeneral;
`ifdef OR1200_MONITOR_LOOKUP
   integer    flookup;
`endif   
   integer    r3;
   integer    insns;


   //
   // Initialization
   //
   initial begin
      ref = 0;
`ifdef OR1200_MONITOR_EXEC_STATE      
      fexe = $fopen({"../out/",`TEST_NAME_STRING,"-executed.log"});
`endif      
      $timeformat (-9, 2, " ns", 12);
`ifdef OR1200_MONITOR_SPRS      
      fspr = $fopen({"../out/",`TEST_NAME_STRING,"-sprs.log"});
`endif      
      fgeneral = $fopen({"../out/",`TEST_NAME_STRING,"-general.log"});
`ifdef OR1200_MONITOR_LOOKUP      
      flookup = $fopen({"../out/",`TEST_NAME_STRING,"-lookup.log"});
`endif      
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
`ifdef OR1200_MONITOR_EXEC_STATE
	 ref = ref + 1;
 `ifdef OR1200_MONITOR_LOOKUP	 
	 $fdisplay(flookup, "Instruction %d: %t", insns, $time);
 `endif	 
	 $fwrite(fexe, "\nEXECUTED(%d): %h:  %h", insns, 
		 `OR1200_TOP.`CPU_cpu.`CPU_except.wb_pc, 
		 `OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn);
 `ifdef OR1200_MONITOR_PRINT_DISASSEMBLY
	 $fwrite(fexe,"\t");	 
	 // Decode the instruction, print it out
	 or1200_print_op(`OR1200_TOP.`CPU_cpu.`CPU_ctrl.wb_insn);
 `endif	 
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
`endif //  `ifdef OR1200_MONITOR_EXEC_STATE
`ifdef OR1200_DISPLAY_EXECUTED
	 ref = ref + 1;
 `ifdef OR1200_MONITOR_LOOKUP	 
	 $fdisplay(flookup, "Instruction %d: %t", insns, $time);
 `endif	 
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
`ifdef OR1200_MONITOR_EXEC_STATE
	 ref = ref + 1;
 `ifdef OR1200_MONITOR_LOOKUP	 
	 $fdisplay(flookup, "Instruction %d: %t", insns, $time);
 `endif	 
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
`endif //  `ifdef OR1200_MONITOR_EXEC_STATE
`ifdef OR1200_DISPLAY_EXECUTED
	 ref = ref + 1;
 `ifdef OR1200_MONITOR_LOOKUP	 
	 $fdisplay(flookup, "Instruction %d: %t", insns, $time);
 `endif	 
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
`ifdef OR1200_MONITOR_SPRS	
	if (`OR1200_TOP.`CPU_cpu.`CPU_sprs.spr_we)
	  $fdisplay(fspr, "%t: Write to SPR : [%h] <- %h", $time,
		    `OR1200_TOP.`CPU_cpu.`CPU_sprs.spr_addr,
		    `OR1200_TOP.`CPU_cpu.`CPU_sprs.spr_dat_o);
	if ((|`OR1200_TOP.`CPU_cpu.`CPU_sprs.spr_cs) & 
	    !`OR1200_TOP.`CPU_cpu.`CPU_sprs.spr_we)
	  $fdisplay(fspr, "%t: Read from SPR: [%h] -> %h", $time,
		    `OR1200_TOP.`CPU_cpu.`CPU_sprs.spr_addr, 
		    `OR1200_TOP.`CPU_cpu.`CPU_sprs.to_wbmux);
`endif	
     end


`ifdef RAM_WB
 `define RAM_WB_TOP `DUT_TOP.wb_ram_b3_0
   task get_insn_from_wb_ram;
      input [31:0] addr;
      output [31:0] insn;
      begin
	 insn = `RAM_WB_TOP.mem[addr[31:2]];
      end
   endtask // get_insn_from_wb_ram
`endif
   
`ifdef VERSATILE_SDRAM
 `define SDRAM_TOP `TB_TOP.sdram0
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
 `define DDR2_TOP `TB_TOP.gen_cs[0]
   // Gets instruction word from correct bank
   task get_insn_from_xilinx_ddr2;
      input [31:0] addr;
      output [31:0] insn;
      reg [16*8-1:0] ddr2_array_line0,ddr2_array_line1,ddr2_array_line2,
		     ddr2_array_line3;
      integer 	     word_in_line_num;      
      begin
	// Get our 4 128-bit chunks (8 half-words in each!! Confused yet?), 
	// 16 words total
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
`ifdef RAM_WB
	   4'h0:
	     get_insn_from_wb_ram(id_pc, insn);
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

`ifdef MEM_COHERENCE_CHECK
 `define MEM_COHERENCE_TRIGGER (`OR1200_TOP.`CPU_cpu.`CPU_ctrl.id_void === 1'b0)

`define INSN_TO_CHECK `OR1200_TOP.`CPU_cpu.`CPU_ctrl.id_insn
`define PC_TO_CHECK `OR1200_TOP.`CPU_cpu.`CPU_except.id_pc
   
   // Check instruction in decode stage is what is in the RAM
   always @(posedge `OR1200_TOP.`CPU_cpu.`CPU_ctrl.clk)
     begin
	if (`MEM_COHERENCE_TRIGGER)
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
      
`endif //  `ifdef MEM_COHERENCE_CHECK
  

   /////////////////////////////////////////////////////////////////////////
   // Instruction decode task
   /////////////////////////////////////////////////////////////////////////


`define OR32_OPCODE_POS 31:26
`define OR32_J_BR_IMM_POS 25:0
`define OR32_RD_POS 25:21
`define OR32_RA_POS 20:16
`define OR32_RB_POS 15:11
`define OR32_ALU_OP_POS 3:0
   
`define OR32_SHROT_OP_POS 7:6
`define OR32_SHROTI_IMM_POS 5:0
`define OR32_SF_OP 25:21
   
`define OR32_XSYNC_OP_POS 25:21  


// Switch between outputting to execution file or STD out for instruction
// decoding task.
//`define PRINT_OP_WRITE $write(
`define PRINT_OP_WRITE $fwrite(fexe,
   
   task or1200_print_op;
      input [31:0] insn;

      reg [5:0]    opcode;
      
      reg [25:0]   j_imm;
      reg [25:0]   br_imm;
      
      reg [4:0]    rD_num, rA_num, rB_num;
      reg [31:0]   rA_val, rB_val;
      reg [15:0]   imm_16bit;
      reg [10:0]   imm_split16bit;      
      
      reg [3:0]    alu_op;
      reg [1:0]    shrot_op;

      reg [5:0]    shroti_imm;

    reg [5:0] 	   sf_op;
			       
    reg [5:0] 	   xsync_op;	   
      
      begin
	 // Instruction opcode
	 opcode = insn[`OR32_OPCODE_POS];
	 // Immediates for jump or branch instructions
	 j_imm = insn[`OR32_J_BR_IMM_POS];
	 br_imm = insn[`OR32_J_BR_IMM_POS];
	 // Register numbers (D, A and B)
	 rD_num = insn[`OR32_RD_POS];
	 rA_num = insn[`OR32_RA_POS];	 
	 rB_num = insn[`OR32_RB_POS];
	 // Bottom 16 bits when used as immediates in various instructions
	 imm_16bit = insn[15:0];
	 // Bottom 11 bits used as immediates for l.sX instructions

	 // Split 16-bit immediate for l.mtspr/l.sX instructions
	 imm_split16bit = {insn[25:21],insn[10:0]};
	 // ALU op for ALU instructions
	 alu_op = insn[`OR32_ALU_OP_POS];
	 // Shift-rotate op for SHROT ALU instructions
	 shrot_op = insn[`OR32_SHROT_OP_POS];
	 shroti_imm = insn[`OR32_SHROTI_IMM_POS];

	 // Set flag op
	 sf_op = insn[`OR32_SF_OP];
	 
         // Xsync/syscall/trap opcode
         xsync_op = insn[`OR32_XSYNC_OP_POS];
			       
	 case (opcode)
	   `OR1200_OR32_J:
	     begin	      
		`PRINT_OP_WRITE"l.j 0x%h", {j_imm,2'b00});	      
	     end
	   
	   `OR1200_OR32_JAL:
	     begin
		`PRINT_OP_WRITE"l.jal 0x%h", {j_imm,2'b00});
	     end

	   `OR1200_OR32_BNF:
	     begin
		`PRINT_OP_WRITE"l.bnf 0x%h", {br_imm,2'b00});	      
	     end
	   
	   `OR1200_OR32_BF:
	     begin
		`PRINT_OP_WRITE"l.bf 0x%h", {br_imm,2'b00});
	     end
	   
	   `OR1200_OR32_RFE:
	     begin
		`PRINT_OP_WRITE"l.rfe");	      
	     end
	   
	   `OR1200_OR32_JR:
	     begin
		`PRINT_OP_WRITE"l.jr r%0d",rB_num);
	     end
	   
	   `OR1200_OR32_JALR:
	     begin
		`PRINT_OP_WRITE"l.jalr r%0d",rB_num);
	     end
	   
	   `OR1200_OR32_LWZ:
	     begin
		`PRINT_OP_WRITE"l.lwz r%0d,0x%0h(r%0d)",rD_num,imm_16bit,rA_num);
	     end
	   
	   `OR1200_OR32_LBZ:
	     begin
		`PRINT_OP_WRITE"l.lbz r%0d,0x%0h(r%0d)",rD_num,imm_16bit,rA_num);
	     end
	   
	   `OR1200_OR32_LBS:
	     begin
		`PRINT_OP_WRITE"l.lbs r%0d,0x%0h(r%0d)",rD_num,imm_16bit,rA_num);
	     end
	   
	   `OR1200_OR32_LHZ:
	     begin
		`PRINT_OP_WRITE"l.lhz r%0d,0x%0h(r%0d)",rD_num,imm_16bit,rA_num);
	     end
	   
	   `OR1200_OR32_LHS:
	     begin
		`PRINT_OP_WRITE"l.lhs r%0d,0x%0h(r%0d)",rD_num,imm_16bit,rA_num);
	     end
	   
	   `OR1200_OR32_SW:
	     begin
		`PRINT_OP_WRITE"l.sw 0x%0h(r%0d),r%0d",imm_split16bit,rA_num,rB_num);
	     end
	   
	   `OR1200_OR32_SB:
	     begin
		`PRINT_OP_WRITE"l.sb 0x%0h(r%0d),r%0d",imm_split16bit,rA_num,rB_num);
	     end
	   
	   `OR1200_OR32_SH:
	     begin
		`PRINT_OP_WRITE"l.sh 0x%0h(r%0d),r%0d",imm_split16bit,rA_num,rB_num);	      
	     end
	   
	   `OR1200_OR32_MFSPR:
	     begin
		`PRINT_OP_WRITE"l.mfspr r%0d,r%0d,0x%h",rD_num,rA_num,imm_16bit,);	
	     end	      

	   `OR1200_OR32_MTSPR:
	     begin
		`PRINT_OP_WRITE"l.mtspr r%0d,r%0d,0x%h",rA_num,rB_num,imm_split16bit);	
	     end
	   
	   `OR1200_OR32_MOVHI:
	     begin
		if (!insn[16])
		  `PRINT_OP_WRITE"l.movhi r%0d,0x%h",rD_num,imm_16bit);
		else
		  `PRINT_OP_WRITE"l.macrc r%0d",rD_num);
	     end
	   
	   `OR1200_OR32_ADDI:
	     begin
		`PRINT_OP_WRITE"l.addi r%0d,r%0d,0x%h",rD_num,rA_num,imm_16bit);
	     end
	   
	   `OR1200_OR32_ADDIC:
	     begin
		`PRINT_OP_WRITE"l.addic r%0d,r%0d,0x%h",rD_num,rA_num,imm_16bit);
	     end
	   
	   `OR1200_OR32_ANDI:
	     begin
		`PRINT_OP_WRITE"l.andi r%0d,r%0d,0x%h",rD_num,rA_num,imm_16bit);
	     end	     
	   
	   `OR1200_OR32_ORI:
	     begin
		`PRINT_OP_WRITE"l.ori r%0d,r%0d,0x%h",rD_num,rA_num,imm_16bit);
	     end	     

	   `OR1200_OR32_XORI:
	     begin
		`PRINT_OP_WRITE"l.xori r%0d,r%0d,0x%h",rD_num,rA_num,imm_16bit);
	     end	     

	   `OR1200_OR32_MULI:
	     begin
		`PRINT_OP_WRITE"l.muli r%0d,r%0d,0x%h",rD_num,rA_num,imm_16bit);
	     end
	   
	   `OR1200_OR32_ALU:
	     begin
		case(alu_op)
		  `OR1200_ALUOP_ADD:
		    `PRINT_OP_WRITE"l.add ");		
		  `OR1200_ALUOP_ADDC:
		    `PRINT_OP_WRITE"l.addc ");		
		  `OR1200_ALUOP_SUB:
		    `PRINT_OP_WRITE"l.sub ");		
		  `OR1200_ALUOP_AND:
		    `PRINT_OP_WRITE"l.and ");		
		  `OR1200_ALUOP_OR:
		    `PRINT_OP_WRITE"l.or ");		
		  `OR1200_ALUOP_XOR:
		    `PRINT_OP_WRITE"l.xor ");		
		  `OR1200_ALUOP_MUL:
		    `PRINT_OP_WRITE"l.mul ");		
		  `OR1200_ALUOP_SHROT:
		    begin
		       case(shrot_op)
			 `OR1200_SHROTOP_SLL:
			   `PRINT_OP_WRITE"l.sll ");
			 `OR1200_SHROTOP_SRL:
			   `PRINT_OP_WRITE"l.srl ");
			 `OR1200_SHROTOP_SRA:
			   `PRINT_OP_WRITE"l.sra ");
			 `OR1200_SHROTOP_ROR:
			   `PRINT_OP_WRITE"l.ror ");
		       endcase // case (shrot_op)
		    end
		  `OR1200_ALUOP_DIV:
		    `PRINT_OP_WRITE"l.div ");		
		  `OR1200_ALUOP_DIVU:
		    `PRINT_OP_WRITE"l.divu ");		
		  `OR1200_ALUOP_CMOV:
		    `PRINT_OP_WRITE"l.cmov ");		
		endcase // case (alu_op)
		`PRINT_OP_WRITE"r%0d,r%0d,r%0d",rD_num,rA_num,rB_num);
	     end
	   
	   `OR1200_OR32_SH_ROTI:
	     begin
		case(shrot_op)
		  `OR1200_SHROTOP_SLL:
		    `PRINT_OP_WRITE"l.slli ");
		  `OR1200_SHROTOP_SRL:
		    `PRINT_OP_WRITE"l.srli ");
		  `OR1200_SHROTOP_SRA:
		    `PRINT_OP_WRITE"l.srai ");
		  `OR1200_SHROTOP_ROR:
		    `PRINT_OP_WRITE"l.rori ");
		endcase // case (shrot_op)
		`PRINT_OP_WRITE"r%0d,r%0d,0x%h",rD_num,rA_num,shroti_imm);		
	     end
	   
	   `OR1200_OR32_SFXXI:
	     begin
		case(sf_op[2:0])
		  `OR1200_COP_SFEQ:
		    `PRINT_OP_WRITE"l.sfeqi ");
		  `OR1200_COP_SFNE:
		    `PRINT_OP_WRITE"l.sfnei ");
		  `OR1200_COP_SFGT:
		    begin
		       if (sf_op[`OR1200_SIGNED_COMPARE])
			 `PRINT_OP_WRITE"l.sfgtsi ");
		       else
			 `PRINT_OP_WRITE"l.sfgtui ");
		    end
		  `OR1200_COP_SFGE:
		    begin
		       if (sf_op[`OR1200_SIGNED_COMPARE])
			 `PRINT_OP_WRITE"l.sfgesi ");
		       else
			 `PRINT_OP_WRITE"l.sfgeui ");
		    end
		  `OR1200_COP_SFLT:
		    begin
		       if (sf_op[`OR1200_SIGNED_COMPARE])
			 `PRINT_OP_WRITE"l.sfltsi ");
		       else
			 `PRINT_OP_WRITE"l.sfltui ");
		    end
		  `OR1200_COP_SFLE:
		    begin
		       if (sf_op[`OR1200_SIGNED_COMPARE])
			 `PRINT_OP_WRITE"l.sflesi ");
		       else
			 `PRINT_OP_WRITE"l.sfleui ");
		    end		  
		endcase // case (sf_op[2:0])
		
		`PRINT_OP_WRITE"r%0d,0x%h",rA_num, imm_16bit);
		
	     end // case: `OR1200_OR32_SFXXI

	   `OR1200_OR32_SFXX:
	     begin
		case(sf_op[2:0])
		  `OR1200_COP_SFEQ:
		    `PRINT_OP_WRITE"l.sfeq ");
		  `OR1200_COP_SFNE:
		    `PRINT_OP_WRITE"l.sfne ");
		  `OR1200_COP_SFGT:
		    begin
		       if (sf_op[`OR1200_SIGNED_COMPARE])
			 `PRINT_OP_WRITE"l.sfgts ");
		       else
			 `PRINT_OP_WRITE"l.sfgtu ");
		    end
		  `OR1200_COP_SFGE:
		    begin
		       if (sf_op[`OR1200_SIGNED_COMPARE])
			 `PRINT_OP_WRITE"l.sfges ");
		       else
			 `PRINT_OP_WRITE"l.sfgeu ");
		    end
		  `OR1200_COP_SFLT:
		    begin
		       if (sf_op[`OR1200_SIGNED_COMPARE])
			 `PRINT_OP_WRITE"l.sflts ");
		       else
			 `PRINT_OP_WRITE"l.sfltu ");
		    end
		  `OR1200_COP_SFLE:
		    begin
		       if (sf_op[`OR1200_SIGNED_COMPARE])
			 `PRINT_OP_WRITE"l.sfles ");
		       else
			 `PRINT_OP_WRITE"l.sfleu ");
		    end
		  
		endcase // case (sf_op[2:0])
		
		`PRINT_OP_WRITE"r%0d,r%0d",rA_num, rB_num);
		
	     end
	   
	   `OR1200_OR32_MACI:
	     begin
		`PRINT_OP_WRITE"l.maci r%0d,0x%h",rA_num,imm_16bit);
	     end

	   `OR1200_OR32_MACMSB:
	     begin
		if(insn[3:0] == 4'h1)
		  `PRINT_OP_WRITE"l.mac ");	      
		else if(insn[3:0] == 4'h2)
		  `PRINT_OP_WRITE"l.msb ");
		
		`PRINT_OP_WRITE"r%0d,r%0d",rA_num,rB_num);
	     end

	   `OR1200_OR32_NOP:
	     begin
		`PRINT_OP_WRITE"l.nop 0x%0h",imm_16bit);
	     end
	   
	   `OR1200_OR32_XSYNC:
	     begin
		case (xsync_op)
		  5'd0:
		    `PRINT_OP_WRITE"l.sys 0x%h",imm_16bit);
		  5'd8:
		    `PRINT_OP_WRITE"l.trap 0x%h",imm_16bit);
		  5'd16:
		    `PRINT_OP_WRITE"l.msync");
		  5'd20:
		    `PRINT_OP_WRITE"l.psync");
		  5'd24:
		    `PRINT_OP_WRITE"l.csync");
		  default:
		    begin
		       $display("%t: Instruction with opcode 0x%h has bad specific type information: 0x%h",$time,opcode,insn);
		       `PRINT_OP_WRITE"%t: Instruction with opcode 0x%h has has bad specific type information: 0x%h",$time,opcode,insn);
		    end
		endcase // case (xsync_op)
	     end
	   
	   default:
	     begin
		$display("%t: Unknown opcode 0x%h",$time,opcode);
		`PRINT_OP_WRITE"%t: Unknown opcode 0x%h",$time,opcode);
	     end
	   
	 endcase // case (opcode)
	 
      end
   endtask // or1200_print_op


   
endmodule
