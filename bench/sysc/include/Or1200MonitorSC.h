// ----------------------------------------------------------------------------

// SystemC OpenRISC 1200 Monitor: definition

// Copyright (C) 2008  Embecosm Limited <info@embecosm.com>

// Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>
// Contributor Julius Baxter <jb@orsoc.se>

// This file is part of the cycle accurate model of the OpenRISC 1000 based
// system-on-chip, ORPSoC, built using Verilator.

// This program is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.

// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
// FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
// License for more details.

// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// ----------------------------------------------------------------------------

// $Id$

#ifndef OR1200_MONITOR_SC__H
#define OR1200_MONITOR_SC__H

#include <fstream>
#include <ctime>

#include "systemc.h"

#include "OrpsocAccess.h"
#include "MemoryLoad.h"

//! Monitor for special l.nop instructions

//! This class is based on the or1200_monitor.v of the Verilog test bench. It
//! wakes up on each posedge clock to check for "special" l.nop instructions,
//! which need processing.

class Or1200MonitorSC
  : public sc_core::sc_module
{
public:

  // Constructor
  Or1200MonitorSC (sc_core::sc_module_name  name,
		   OrpsocAccess            *_accessor,
		   MemoryLoad              *_memoryload,
		   int argc, 
		   char *argv[]);

  // Method to check instructions
  void  checkInstruction();

  // Methods to setup and output state of processor to a file
  void displayState();
  void displayStateBinary();

  // Methods to generate the call and return list during execution
  void callLog();

  // Method to calculate performance of the sim
  void perfSummary();

  // Method to print out the command-line switches for this module's options  
  void printSwitches();

  // Method to print out the usage for each option
  void printUsage();
  
  // Method to dump simulation's RAM contents at finish
  void memdump();

  // Method used for monitoring and logging transactions on the system bus
  //void busMonitor();
  
  // Method to do simulator assisted printf'ing
  void simPrintf(uint32_t stackaddr, uint32_t regparam);



  // The ports
  sc_in<bool>   clk;

private:

#define DEFAULT_EXEC_LOG_FILE "or1200_exec.log"
#define DEFAULT_PROF_FILE "sim.profile"
#define DEFAULT_MEMDUMP_FILE "vorpsoc_ram.dump"
#define DEFAULT_BUS_LOG_FILE "bus_trans.log"

  // Special NOP instructions
  static const uint32_t NOP_NOP    = 0x15000000;  //!< Normal nop instruction
  static const uint32_t NOP_EXIT   = 0x15000001;  //!< End of simulation
  static const uint32_t NOP_REPORT = 0x15000002;  //!< Simple report
  static const uint32_t NOP_PRINTF = 0x15000003;  //!< Simprintf instruction
  static const uint32_t NOP_PUTC   = 0x15000004;  //!< Putc instruction
  static const uint32_t NOP_CNT_RESET = 0x15000005; //!< Reset statistics counters
  static const uint32_t NOP_CNT_RESET1 = 0x15000007;	    /* Reset statistics counter 1 */
  static const uint32_t NOP_CNT_RESET2 = 0x15000008;	    /* Reset statistics counter 2 */
  static const uint32_t NOP_CNT_RESET3 = 0x15000009;	    /* Reset statistics counter 3 */
  static const uint32_t NOP_MEM_STATS_RESET  = 0x15000010; //!< Reset memory statistics counters
  static const uint32_t NOP_CNT_RESET_DIFFERENCE = 0x15000006; //!< Reset stats counters, print 

  // Variables for processor status output
  ofstream statusFile;
  ofstream profileFile;
  bool profiling_enabled;
  bool logging_enabled;
  bool logfile_name_provided;
  bool logging_regs;
  bool binary_log_format;
  bool exit_perf_summary_enabled;
  bool monitor_for_crash;
  int lookslikewevecrashed_count, crash_monitor_buffer_head;
#define CRASH_MONITOR_BUFFER_SIZE 32
  uint32_t crash_monitor_buffer[CRASH_MONITOR_BUFFER_SIZE][2]; //PC, Insn
  bool wait_for_stall_cmd_response;
  unsigned long long insn_count, insn_count_rst;
  unsigned long long cycle_count, cycle_count_rst;
  unsigned long long cycles_1, cycles_2, cycles_3; // Cycle counters for l.nop insns
  ofstream memdumpFile;
  string memdumpFileName;
  bool do_memdump;
  int memdump_start_addr, memdump_end_addr;
  bool bus_trans_log_enabled, bus_trans_log_name_provided, bus_trans_log_start_delay_enable;
  sc_time bus_trans_log_start_delay;
  enum busLogStates { BUS_LOG_IDLE, BUS_LOG_WAIT_FOR_ACK };
  ofstream busTransLog;

  //! Time measurement variable - for calculating performance of the sim
  clock_t start;

  //! The accessor for the Orpsoc instance
  OrpsocAccess *accessor;

  //! The memory loading object
  MemoryLoad *memoryload;  

};	// Or1200MonitorSC ()

#endif	// OR1200_MONITOR_SC__H
