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

  // Methods to generate the call and return list during execution
  void callLog();

  // Method to calculate performance of the sim
  void perfSummary();

  // Method to print out the command-line switches for this module's options  
  void printSwitches();

  // Method to print out the usage for each option
  void printUsage();

  // The ports
  sc_in<bool>   clk;

private:

#define DEFAULT_PROF_FILE "sim.profile"

  // Special NOP instructions
  static const uint32_t NOP_NOP    = 0x15000000;  //!< Normal nop instruction
  static const uint32_t NOP_EXIT   = 0x15000001;  //!< End of simulation
  static const uint32_t NOP_REPORT = 0x15000002;  //!< Simple report
  static const uint32_t NOP_PRINTF = 0x15000003;  //!< Simprintf instruction
  static const uint32_t NOP_PUTC   = 0x15000004;  //!< Putc instruction

  // Variables for processor status output
  ofstream statusFile;
  ofstream profileFile;
  int logging_enabled;
  int exit_perf_summary_enabled;
  int insn_count;
  long long cycle_count;
  
  //! Time measurement variable - for calculating performance of the sim
  clock_t start;

  //! The accessor for the Orpsoc instance
  OrpsocAccess *accessor;

  //! The memory loading object
  MemoryLoad *memoryload;

};	// Or1200MonitorSC ()

#endif	// OR1200_MONITOR_SC__H
