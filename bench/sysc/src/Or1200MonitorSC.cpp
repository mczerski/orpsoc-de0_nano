// ----------------------------------------------------------------------------

// SystemC OpenRISC 1200 Monitor: implementation

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

#include <iostream>
#include <iomanip>
#include <fstream>
#include <sys/types.h>
#include <netinet/in.h>
using namespace std;

#include "Or1200MonitorSC.h"
#include "OrpsocMain.h"

#include <errno.h>
int monitor_to_gdb_pipe[2][2]; // [0][] - monitor to gdb, [1][] - gdb to monitor, [][0] - read, [][1] - write

SC_HAS_PROCESS( Or1200MonitorSC );

//! Constructor for the OpenRISC 1200 monitor

//! @param[in] name  Name of this module, passed to the parent constructor.
//! @param[in] accessor  Accessor class for this Verilated ORPSoC model

Or1200MonitorSC::Or1200MonitorSC (sc_core::sc_module_name   name,
				  OrpsocAccess             *_accessor,
				  MemoryLoad               *_memoryload,
				  int argc, 
				  char *argv[]) :
  sc_module (name),
  accessor (_accessor),
  memoryload(_memoryload)
{
  string logfileDefault(DEFAULT_EXEC_LOG_FILE);
  string logfileNameString;
  logging_enabled = false;
  logfile_name_provided = false;
  profiling_enabled = false; 
  string profileFileName(DEFAULT_PROF_FILE); 
  memdumpFileName = (DEFAULT_MEMDUMP_FILE);
  int memdump_start = 0; int memdump_end = 0;
  do_memdump = false; // Default is not to do a dump of RAM at finish
  logging_regs = true; // Execution log includes register values by default
  bool rsp_server_enabled = false;
  wait_for_stall_cmd_response = false; // Default
  insn_count = insn_count_rst = 0;
  cycle_count = cycle_count_rst = 0;

  exit_perf_summary_enabled = true; // Simulation exit performance summary is 
                                    // on by default. Turn off with "-q" on the 
                                    // cmd line
  monitor_for_crash = false;
  lookslikewevecrashed_count = crash_monitor_buffer_head = 0;

  bus_trans_log_enabled = bus_trans_log_name_provided = 
    bus_trans_log_start_delay_enable = false; // Default
  string bus_trans_default_log_name(DEFAULT_BUS_LOG_FILE);
  string bus_trans_log_file;

  // Parse the command line options
  bool cmdline_name_found = false;
  if (argc > 1)
    {
      // Search through the command line parameters for the "-log" option
      for(int i=1; i < argc; i++)
	{
	  if ((strcmp(argv[i], "-l")==0) ||
	      (strcmp(argv[i], "--log")==0))
	    {
	      logging_enabled = true;
	      binary_log_format = false;
	      if (i+1 < argc)
		if(argv[i+1][0] != '-')
		  {
		    logfileNameString = (argv[i+1]);
		    logfile_name_provided = true;
		  }
	      if (!logfile_name_provided)
		logfileNameString = logfileDefault;
	    }
	  else if ((strcmp(argv[i], "--log-noregs")==0))
	    {
	      logging_regs = false;
	    }
	  else if ((strcmp(argv[i], "-b")==0) ||
		   (strcmp(argv[i], "--binlog")==0))
	    {
	      logging_enabled = true;
	      binary_log_format = true;
	      if (i+1 < argc)
		if(argv[i+1][0] != '-')
		  {
		    logfileNameString = (argv[i+1]);
		    logfile_name_provided = true;
		  }
	      if (!logfile_name_provided)
		logfileNameString = logfileDefault;

	    }
	  else if ((strcmp(argv[i], "-c")==0) ||
		   (strcmp(argv[i], "--crash-monitor")==0))
	    {
	      monitor_for_crash = true;
	    }
	  else if ((strcmp(argv[i], "-q")==0) ||
		   (strcmp(argv[i], "--quiet")==0))
	    {
	      exit_perf_summary_enabled = false;
	    }
	  else if ((strcmp(argv[i], "-p")==0) ||
		   (strcmp(argv[i], "--profile")==0))
	    {
	      profiling_enabled = true;
	      // Check for !end of command line and that next thing is not a 
	      // command
	      if ((i+1 < argc)){
		if(argv[i+1][0] != '-')
		  profileFileName = (argv[i+1]);
	      }
	    }
	  else if ( (strcmp(argv[i], "-r")==0) ||
		    (strcmp(argv[i], "--rsp")==0) )
	    {
	      // We need to detect this here too
	      rsp_server_enabled = true;
	    }
				
	  else if ((strcmp(argv[i], "-m")==0) ||
		   (strcmp(argv[i], "--memdump")==0))
	    {
	      do_memdump = true;
	      // Check for !end of command line and that next thing is not a 
	      // command or a memory address
	      if (i+1 < argc)
		{
		  if((argv[i+1][0] != '-') && (strncmp("0x", argv[i+1],2) != 0))
		    {
		      // Hopefully this is the filename we want to use.
		      // All addresses should have preceeding hex identifier 0x
		      memdumpFileName = argv[i+1];
		      // We've used this next index, can safely increment i
		      i++;
		    }
		}
	      if (i+1 < argc)
		{
		  if((argv[i+1][0] != '-') && (strncmp("0x", argv[i+1],2) == 0))
		    {
		      // Hopefully this is is the start address
		      // All addresses should have preceeding hex identifier 0x
		      sscanf( argv[i+1], "0x%x", &memdump_start);		
		      i++;
		    }
		}
	      if (i+1 < argc) 
		{
		  if((argv[i+1][0] != '-') && (strncmp("0x", argv[i+1],2) == 0))
		    {
		      // Hopefully this is is the end address
		      // All addresses should have preceeding hex identifier 0x
		      sscanf( argv[i+1], "0x%x", &memdump_end);
		      i++;
		    }
		}
	    }
	  else if ((strcmp(argv[i], "-u")==0) ||
		   (strcmp(argv[i], "--bus-log")==0))
	    {
	      bus_trans_log_enabled = true;
	      if (i+1 < argc)
		if(argv[i+1][0] != '-')
		  {
		    bus_trans_log_file = (argv[i+1]);
		    bus_trans_log_name_provided = true;
		  }
	      
	      if (!bus_trans_log_name_provided)
		bus_trans_log_file = bus_trans_default_log_name;
	      
	      // check for a log start delay
	      if (i+2 < argc)
		if(argv[i+2][0] != '-')
		  {
		    // We have a bus transaction log start delay
		    bus_trans_log_start_delay_enable = true;
		    int time_val = atoi(argv[i+2]);
		    sc_time log_start_time(time_val,SC_NS);
		    bus_trans_log_start_delay = log_start_time;
		  }
	    }
	}
    }

  
  if (!rsp_server_enabled)
    {
      monitor_to_gdb_pipe[0][0] = monitor_to_gdb_pipe[0][1] = NULL;
      monitor_to_gdb_pipe[1][0] = monitor_to_gdb_pipe[1][1] = NULL;
    }

    
  // checkInstruction monitors the bus for special NOP instructionsl
  SC_METHOD (checkInstruction);
  sensitive << clk.pos();
  dont_initialize();

  
  if (profiling_enabled)
    {
      
      profileFile.open(profileFileName.c_str(), ios::out); // Open profiling log file
      if(profileFile.is_open())
	{
	  // If the file was opened OK, then enabled logging and print a message.
	  profiling_enabled = true;
	  cout << "* Execution profiling enabled. Logging to " << profileFileName << endl;
	}
      
      // Setup profiling function
      SC_METHOD (callLog);
      sensitive << clk.pos();
      dont_initialize();
      start = clock();
    }

  if(logging_enabled)
    {      
      
      /* Now open the file */
      if (binary_log_format)
	statusFile.open(logfileNameString.c_str(), ios::out | ios::binary);
      else
	statusFile.open(logfileNameString.c_str(), ios::out );
      
      /* Check the open() */
      if(statusFile.is_open() && binary_log_format)
	{
	  cout << "* Processor execution logged in binary format to file: " << logfileNameString << endl;
	  /* Write out a byte indicating whether there's register values too */
	  statusFile.write((char*)&logging_regs, 1);
	  
	}
      else if (statusFile.is_open() && !binary_log_format)
	cout << "* Processor execution logged to file: " << logfileNameString << endl;
      else
	/* Couldn't open */
	logging_enabled = false;
      
    }  
  
  if (logging_enabled)
    { 
      if (binary_log_format)
	{
	  SC_METHOD (displayStateBinary);
	}
      else
	{
	  SC_METHOD (displayState);
	}
      sensitive << clk.pos();
      dont_initialize();
      start = clock();
      
    }

  if (monitor_for_crash)
    {
      cout << "* Crash monitor enabled" << endl;
    }

  // Check sizes we were given from memory dump command line options first
  if (do_memdump)
    {
      if ((memdump_start > ORPSOC_SRAM_SIZE) || (memdump_end > ORPSOC_SRAM_SIZE) || 
	  ((memdump_start > memdump_end) && (memdump_end != 0)))
	{
	  do_memdump = false;
	  cout << "* Memory dump addresses range incorrect. Limit of memory is 0x" << hex <<  ORPSOC_SRAM_SIZE << ". Memory dumping disabled." << endl;
	}
    }
  
  if (do_memdump)
    {
      // Were we given dump addresses? If not, we dump all of the memory
      // Size of memory isn't clearly defined in any one place. This could lead to
      // big problems when changing size of the RAM in simulation.

      if (memdump_start == 0 && memdump_end == 0)
	memdump_end = ORPSOC_SRAM_SIZE;
      
      if (memdump_start != 0 && memdump_end == 0)
	{
	  // Probably just got the single memorydump param
	  // Interpet as a length from 0
	  memdump_end = memdump_start;
	  memdump_start = 0;
	}

      if (memdump_start & 0x3) memdump_start &= ~0x3; // word-align the start address      
      if (memdump_end & 0x3) memdump_end = (memdump_end+4) & ~0x3; // word-align the start address
      
      memdump_start_addr = memdump_start;
      memdump_end_addr = memdump_end;      
    }

  if (bus_trans_log_enabled)
    {
      // Setup log file and register the bus monitoring function
      busTransLog.open(bus_trans_log_file.c_str(), ios::out );

      if (busTransLog.is_open())
	{
	  cout << "* System bus transactions logged to file: " << 
	    bus_trans_log_file;
	  
	  if (bus_trans_log_start_delay_enable)
	    cout << ", on at " << bus_trans_log_start_delay.to_string();
	  cout << endl;
	}
      else
	/* Couldn't open */
	bus_trans_log_enabled = false;
    }

  if (bus_trans_log_enabled)
    {
      // Setup profiling function
      SC_METHOD (busMonitor);
      sensitive << clk.pos();
      dont_initialize();
    }
  
}	// Or1200MonitorSC ()

//! Print usage for the options of this module
void 
Or1200MonitorSC::printUsage()
{
  printf("\nLogging and diagnostic options:\n");
  printf("  -p, --profile [<file>]Enable execution profiling output to <file> (default is\n\t\t\t"DEFAULT_PROF_FILE")\n");
  printf("  -l, --log <file>\tLog processor execution to <file>\n");
  printf("      --log-noregs\tLog excludes register contents\n");

  printf("  -b, --binlog <file>\tGenerate binary format execution log (faster, smaller)\n");

  printf("  -q, --quiet\t\tDisable the performance summary at end of simulation\n");
  printf("  -m, --memdump <file> <0xstartaddr> <0xendaddr>\n\t\t\tDump data between <0xstartaddr> and <0xendaddr> from\n\t\t\tthe system's RAM to <file> in binary format on exit\n");
  printf("  -c, --crash-monitor\tDetect when the processor has crashed and exit\n");
  printf("  -u, --bus-log <file> <val>\n\t\t\tLog the wishbone bus transactions to <file>, opt. start\n\t\t\tafter <val> ns\n\n");

}

//! Method to handle special instrutions

//! These are l.nop instructions with constant values. At present the
//! following are implemented:

//! - l.nop 1  Terminate the program
//! - l.nop 2  Report the value in R3
//! - l.nop 3  Printf the string with the arguments in R3, etc
//! - l.nop 4  Print a character

//#define OR1200_OR32_NOP_BITS_31_TO_26               6'b000101
#define OR1200_OR32_NOP               0x14000000

extern int SIM_RUNNING;
void
Or1200MonitorSC::checkInstruction()
{
  uint32_t  r3;
  double    ts;
  uint32_t current_WbInsn, current_WbPC;
  
  cycle_count++;  

  /* Check if this counts as an "executed" instruction */
  if (!accessor->getWbFreeze())
    {
      // Cache writeback stage instruction
      current_WbInsn = accessor->getWbInsn();
      
      if ((((current_WbInsn & 0xfc000000) != (uint32_t) OR1200_OR32_NOP) || !(current_WbInsn & (1<<16))) && !(accessor->getExceptFlushpipe() && accessor->getExDslot()))	
	insn_count++;
      else
	// Exception version
	if (accessor->getExceptFlushpipe())
	  insn_count++;
    }
  
  // Check the instruction when the freeze signal is low.
  if ((!accessor->getWbFreeze()) && (accessor->getExceptType() == 0))
    {
      // Do something if we have l.nop
      switch (current_WbInsn)
	{
	case NOP_EXIT:
	  r3 = accessor->getGpr (3);
	  ts = sc_time_stamp().to_seconds() * 1000000000.0;
	  std::cout << std::fixed << std::setprecision (2) << ts;
	  std::cout << " ns: Exiting (" << r3 << ")" << std::endl;
	  perfSummary();
	  if (logging_enabled) statusFile.close();
	  if (profiling_enabled) profileFile.close();
	  if (bus_trans_log_enabled) busTransLog.close();
	  memdump();
	  SIM_RUNNING=0;
	  sc_stop();
	  break;

	case NOP_REPORT:
	  ts = sc_time_stamp().to_seconds() * 1000000000.0;
	  r3 = accessor->getGpr (3);
	  std::cout << std::fixed << std::setprecision (2) << ts;
	  std::cout << " ns: report (" << hex << r3 << ")" << std::endl;
	  break;

	case NOP_PRINTF:
	  ts = sc_time_stamp().to_seconds() * 1000000000.0;
	  std::cout << std::fixed << std::setprecision (2) << ts;
	  std::cout << " ns: printf" << std::endl;
	  break;

	case NOP_PUTC:
	  r3 = accessor->getGpr (3);
	  std::cout << (char)r3 << std::flush;
	  break;
	case NOP_CNT_RESET:
	  std::cout << "****************** counters reset ******************" << endl;
	  std::cout << "since last reset: cycles " << cycle_count - cycle_count_rst << ", insn #" << insn_count - insn_count_rst << endl;
	  std::cout << "****************** counters reset ******************" << endl;
	  cycle_count_rst = cycle_count;
	  insn_count_rst = insn_count;
	  /* 3 separate counters we'll use for various things */
	case NOP_CNT_RESET1: 
	  std::cout << "**** counter1 cycles: " << std::setfill('0') << std::setw(10) << cycle_count - cycles_1 << " resetting ********" << endl;
	  cycles_1 = cycle_count;
	  break;
	case NOP_CNT_RESET2: 
	  std::cout << "**** counter2 cycles: " << std::setfill('0') << std::setw(10) << cycle_count - cycles_2 << " resetting ********" << endl;
	  cycles_2 = cycle_count;
	  break;
	case NOP_CNT_RESET3: 
	  std::cout << "**** counter3 cycles: " << std::setfill('0') << std::setw(10) << cycle_count - cycles_3 << " resetting ********" << endl;
	  cycles_3 = cycle_count;
	  break;
	default:
	  break;
	}
      
      if (monitor_for_crash)
	{
	  current_WbPC = accessor->getWbPC();
	  // Look at current instruction
	  if (current_WbInsn == 0x00000000)
	    {	  
	      // Looks like we've jumped somewhere incorrectly
	      lookslikewevecrashed_count++;
	    }
#define CRASH_MONITOR_LOG_BAD_INSNS 1
#if CRASH_MONITOR_LOG_BAD_INSNS
	  
	  /* Log so-called "bad" instructions, or at least instructions we
	  executed, no matter if they caused us to increment 
	  lookslikewevecrashed_count, this way we get them in our list too */
	  if (((current_WbInsn & 0xfc000000) != (uint32_t) OR1200_OR32_NOP) || !(current_WbInsn & (1<<16)))
	    {
	      crash_monitor_buffer[crash_monitor_buffer_head][0] = current_WbPC;
	      crash_monitor_buffer[crash_monitor_buffer_head][1] = current_WbInsn;
	      /* Circular buffer */
	      if(crash_monitor_buffer_head < CRASH_MONITOR_BUFFER_SIZE-1)
		crash_monitor_buffer_head++;
	      else
		crash_monitor_buffer_head = 0;
	  
	    }

#else
	  else if (((current_WbInsn & 0xfc000000) != (uint32_t) OR1200_OR32_NOP) || !(current_WbInsn & (1<<16)))
	  {

	      crash_monitor_buffer[crash_monitor_buffer_head][0] = current_WbPC;
	      crash_monitor_buffer[crash_monitor_buffer_head][1] = current_WbInsn;
	      /* Circular buffer */
	      if(crash_monitor_buffer_head < CRASH_MONITOR_BUFFER_SIZE-1)
		crash_monitor_buffer_head++;
	      else
		crash_monitor_buffer_head = 0;
	      
	      /* Reset this */
	      lookslikewevecrashed_count  = 0;
	    }
#endif	  
	  if (wait_for_stall_cmd_response)
	    {
	      // We've already crashed, and we're issued a command to stall the
	      // processor to the system C debug unit interface, and we're
	      // waiting for this debug unit to send back the message that we've
	      // stalled.
	      char readChar;
	      int n = read(monitor_to_gdb_pipe[1][0], &readChar, sizeof(char));
	      if (!( ((n < 0) && (errno == EAGAIN)) || (n==0) ))
		wait_for_stall_cmd_response = false; // We got response
	      lookslikewevecrashed_count = 0;
	      
	    }
	  else if (lookslikewevecrashed_count > 0)
	    {
	      
	      if (lookslikewevecrashed_count >= CRASH_MONITOR_BUFFER_SIZE/4)
		{
		  /* Probably crashed. Bail out, print out buffer */
		  std::cout << "********************************************************************************"<< endl;
		  std::cout << "* Looks like processor crashed. Printing last " << CRASH_MONITOR_BUFFER_SIZE << " instructions executed:" << endl;
		  
		  int crash_monitor_buffer_head_end = (crash_monitor_buffer_head > 0) ? crash_monitor_buffer_head - 1 : CRASH_MONITOR_BUFFER_SIZE-1;
		  while (crash_monitor_buffer_head != crash_monitor_buffer_head_end)
		    {
		      std::cout << "* PC: " << std::setfill('0') << hex << std::setw(8) << crash_monitor_buffer[crash_monitor_buffer_head][0] << "  INSN: " << std::setfill('0') << hex << std::setw(8) << crash_monitor_buffer[crash_monitor_buffer_head][1] << endl;
		      
		      if(crash_monitor_buffer_head < CRASH_MONITOR_BUFFER_SIZE-1)
			crash_monitor_buffer_head++;
		      else
			crash_monitor_buffer_head = 0;
		    }
		  std::cout << "********************************************************************************"<< endl;
		  
		  if ( (monitor_to_gdb_pipe[0][0] != NULL))
		    {
		      // If GDB server is running, we'll pass control back to
		      // the debugger instead of just quitting.
		      char interrupt = 0x3; // Arbitrary
		      write(monitor_to_gdb_pipe[0][1],&interrupt,sizeof(char));
		      wait_for_stall_cmd_response = true;
		      lookslikewevecrashed_count = 0;
		      std::cout << "* Stalling processor and returning control to GDB"<< endl;
		      // Problem: the debug unit interface's stalling the processor over the simulated JTAG bus takes a while, in the meantime this monitor will continue running and keep triggering the crash detection code. We must somehow wait until the processor is stalled, or circumvent this crash detection output until we detect that the processor is stalled.
		      // Solution: Added another pipe, when we want to wait for preocssor to stall, we set wait_for_stall_cmd_response=true, then each time we get back to this monitor function we simply poll the pipe until we're stalled. (A blocking read didn't work - this function never yielded and the RSP server handling function never got called).
		      wait_for_stall_cmd_response = true;
		      
		    }
		  else
		    {
		      // Close down sim end exit
		      ts = sc_time_stamp().to_seconds() * 1000000000.0;
		      std::cout << std::fixed << std::setprecision (2) << ts;
		      std::cout << " ns: Exiting (" << r3 << ")" << std::endl;
		      perfSummary();
		      if (logging_enabled) statusFile.close();
		      if (profiling_enabled) profileFile.close();
		      if (bus_trans_log_enabled) busTransLog.close();
		      memdump();
		      SIM_RUNNING=0;
		      sc_stop();
		    }
		}
	    }
	}      
    }
}	// checkInstruction()


//! Method to log execution in terms of calls and returns

void
Or1200MonitorSC::callLog()
{
  uint32_t  exinsn, delaypc; 
  uint32_t o_a; // operand a
  uint32_t o_b; // operand b
  struct label_entry *tmp;
  
  // Instructions should be valid when freeze is low and there are no exceptions
  //if (!accessor->getExFreeze())
  if ((!accessor->getWbFreeze()) && (accessor->getExceptType() == 0))
    {
      //exinsn = accessor->getExInsn();// & 0x3ffffff;
      exinsn = accessor->getWbInsn();
      // Check the instruction
      switch((exinsn >> 26) & 0x3f) { // Check Opcode - top 6 bits
      case 0x1:
	/* Instruction: l.jal */
	o_a = (exinsn >> 0) & 0x3ffffff;
	if(o_a & 0x02000000) o_a |= 0xfe000000;
	
	//delaypc = accessor->getExPC() + (o_a * 4); // PC we're jumping to
	delaypc = accessor->getWbPC() + (o_a * 4); // PC we're jumping to
	// Now we have info about where we're jumping to. Output the info, with label if possible
	// We print the PC we're jumping from + 8 which is the return address
	if ( tmp = memoryload->get_label (delaypc) )
	  profileFile << "+" << std::setfill('0') << hex << std::setw(8) << cycle_count << " " << hex << std::setw(8) << accessor->getWbPC() + 8 << " " << hex << std::setw(8) << delaypc << " " << tmp->name << endl;
	else
	  profileFile << "+" << std::setfill('0') << hex << std::setw(8) << cycle_count << " " << hex << std::setw(8) << accessor->getWbPC() + 8 << " " << hex << std::setw(8) << delaypc << " @" << hex << std::setw(8) << delaypc << endl;
	
	break;
      case 0x11:
	/* Instruction: l.jr */
	// Bits 15-11 contain register number
	o_b = (exinsn >> 11) & 0x1f;
	if (o_b == 9) // l.jr r9 is typical return
	  {
	    // Now get the value in this register
	    delaypc = accessor->getGpr(o_b);
	    // Output this jump
	    profileFile << "-" << std::setfill('0') << hex << std::setw(8) << cycle_count << " "  << hex << std::setw(8) << delaypc << endl;
	  }
	break;
      case 0x12:
	/* Instruction: l.jalr */
	o_b = (exinsn >> 11) & 0x1f;
	// Now get the value in this register
	delaypc = accessor->getGpr(o_b);
	// Now we have info about where we're jumping to. Output the info, with label if possible
	// We print the PC we're jumping from + 8 which is the return address
	if ( tmp = memoryload->get_label (delaypc) )
	  profileFile << "+" << std::setfill('0') << hex << std::setw(8) << cycle_count << " " << hex << std::setw(8) << accessor->getWbPC() + 8 << " " << hex << std::setw(8) << delaypc << " " << tmp->name << endl;
	else
	  profileFile << "+" << std::setfill('0') << hex << std::setw(8) << cycle_count << " " << hex << std::setw(8) << accessor->getWbPC() + 8 << " " << hex << std::setw(8) << delaypc << " @" << hex << std::setw(8) << delaypc << endl;
	
	break;

      }
    }
}	// callLog()


//! Method to output the state of the processor

//! This function will output to a file, if enabled, the status of the processor
//! This copies what the verilog testbench module, or1200_monitor does in it its
//! process which calls the display_arch_state tasks. This is designed to be 
//! identical to that process, so the output is identical

void
Or1200MonitorSC::displayState()
{
  // Output the state if we're not frozen and not flushing during a delay slot
  if (!accessor->getWbFreeze())
    {
      if ((((accessor->getWbInsn() & 0xfc000000) != (uint32_t) OR1200_OR32_NOP) || !(accessor->getWbInsn() & (1<<16))) && !(accessor->getExceptFlushpipe() && accessor->getExDslot()))
	{
	  // Print PC, instruction
	  statusFile << "\nEXECUTED("<< std::setfill(' ') << std::setw(11) << dec << insn_count << "): " << std::setfill('0') << hex << std::setw(8) << accessor->getWbPC() << ":  " << hex << std::setw(8) << accessor->getWbInsn() <<  endl;
	}
      // Exception version
      else if (accessor->getExceptFlushpipe())
	{
	  // Print PC, instruction, indicate it caused an exception
	  statusFile << "\nEXECUTED("<< std::setfill(' ') << std::setw(11) << dec << insn_count << "): " << std::setfill('0') << hex << std::setw(8) << accessor->getExPC() << ":  " << hex << std::setw(8) << accessor->getExInsn() << "  (exception)" << endl;
	}
      else
	return;
    }
  else
    return;
  
  if (logging_regs)
    {
      // Print general purpose register contents
      for (int i=0; i<32; i++)
	{
	  if ((i%4 == 0)&&(i>0)) statusFile << endl;
	  statusFile << std::setfill('0');
	  statusFile << "GPR" << dec << std::setw(2) << i << ": " <<  hex << std::setw(8) << (uint32_t) accessor->getGpr(i) << "  ";		
	}
      statusFile << endl;
      
      statusFile << "SR   : " <<  hex << std::setw(8) << (uint32_t) accessor->getSprSr() << "  ";
      statusFile << "EPCR0: " <<  hex << std::setw(8) << (uint32_t) accessor->getSprEpcr() << "  ";
      statusFile << "EEAR0: " <<  hex << std::setw(8) << (uint32_t) accessor->getSprEear() << "  ";	
      statusFile << "ESR0 : " <<  hex << std::setw(8) << (uint32_t) accessor->getSprEsr() << endl;
      
    }
  
  return;
  
}	// displayState()

//! Method to output the state of the processor in binary format
//! File format is simply first byte indicating whether register
//! data is included, and then structs of the following type
struct s_binary_output_buffer{
  long long insn_count;
  uint32_t pc;
  uint32_t insn;
  char exception;
  uint32_t regs[32];
  uint32_t sr;
  uint32_t epcr0; 
  uint32_t eear0; 
  uint32_t eser0;
} __attribute__((__packed__));

struct s_binary_output_buffer_sans_regs{
  long long insn_count;
  uint32_t pc;
  uint32_t insn;
  char exception;
} __attribute__((__packed__));
  
void
Or1200MonitorSC::displayStateBinary()
{
  struct s_binary_output_buffer outbuf;
  
  // Output the state if we're not frozen and not flushing during a delay slot
  if (!accessor->getWbFreeze())
    {
      if ((((accessor->getWbInsn() & 0xfc000000) != (uint32_t) OR1200_OR32_NOP) || !(accessor->getWbInsn() & (1<<16))) && !(accessor->getExceptFlushpipe() && accessor->getExDslot()))
	{
	  outbuf.insn_count = insn_count;
	  outbuf.pc = (uint32_t) accessor->getWbPC();
	  outbuf.insn = (uint32_t) accessor->getWbInsn();
	  outbuf.exception = 0;
	}
      // Exception version
      else if (accessor->getExceptFlushpipe())
	{
	  outbuf.insn_count = insn_count;
	  outbuf.pc = (uint32_t) accessor->getExPC();
	  outbuf.insn = (uint32_t) accessor->getExInsn();
	  outbuf.exception = 1;
	}
      else
	return;
    }
  else
    return;
  
  if (logging_regs)
    {
      // Print general purpose register contents
      for (int i=0; i<32; i++)
	  outbuf.regs[i] = (uint32_t) accessor->getGpr(i);

      outbuf.sr = (uint32_t) accessor->getSprSr();
      outbuf.epcr0 = (uint32_t) accessor->getSprEpcr();
      outbuf.eear0 = (uint32_t) accessor->getSprEear();
      outbuf.eser0 = (uint32_t) accessor->getSprEsr();
      
      statusFile.write((char*)&outbuf, sizeof(struct s_binary_output_buffer));
      
    }
  else
    statusFile.write((char*)&outbuf, sizeof(struct s_binary_output_buffer_sans_regs));
  
  
  
  return;
  
}	// displayStateBinary()

//! Function to calculate the number of instructions performed and the time taken
void 
Or1200MonitorSC::perfSummary()
{
  if (exit_perf_summary_enabled) 
    {
      double ts;
      ts = sc_time_stamp().to_seconds() * 1000000000.0;
      int cycles = ts / (BENCH_CLK_HALFPERIOD*2); // Number of clock cycles we had
      
      clock_t finish = clock();
      double elapsed_time = (double(finish)-double(start))/CLOCKS_PER_SEC;
      // It took elapsed_time seconds to do insn_count instructions. Divide insn_count by the time to get instructions/second.
      double ips = (insn_count/elapsed_time);
      double mips = (insn_count/elapsed_time)/1000000;
      int hertz = (int) ((cycles/elapsed_time)/1000);
      std::cout << "* Or1200Monitor: simulated " << sc_time_stamp() << ", time elapsed: " << elapsed_time << " seconds" << endl;
      std::cout << "* Or1200Monitor: simulated " << dec << cycles << " clock cycles, executed at approx " << hertz << "kHz" << endl;
      std::cout << "* Or1200Monitor: simulated " << insn_count << " instructions, insn/sec. = " << ips /*<< ", mips = " << mips*/ << endl;
    }
  return;
} 	// perfSummary


//! Dump contents of simulation's RAM to file
void 
Or1200MonitorSC::memdump()
{
  if (!do_memdump) return;
  uint32_t current_word;
  int size_words = (memdump_end_addr/4) - (memdump_start_addr/4);
  if (!(size_words > 0)) return;
  
  // First try opening the file
  memdumpFile.open(memdumpFileName.c_str(), ios::binary); // Open memorydump file
  if(memdumpFile.is_open())
    {
      // If we could open the file then turn on logging
      cout << "* Dumping system RAM from  0x" << hex << memdump_start_addr << "-0x" << hex << memdump_end_addr << " to file " << memdumpFileName << endl;
      
      // Convert memdump_start_addr to word address
      memdump_start_addr = memdump_start_addr / 4;
      while (size_words)
	{
	  // Read the data from the simulation memory
	  current_word = accessor->get_mem(memdump_start_addr);
	  //cout << hex << current_word << " ";
	  /*
	  cout << hex << ((current_word >> 24 ) & 0xff) << " ";
	  cout << hex << ((current_word >> 16) & 0xff) << " ";
	  cout << hex << ((current_word >> 8 ) & 0xff) << " " ; 
	  cout << hex << ((current_word >> 0 ) & 0xff) << " ";
	  */
	  // Change from whatever endian the host is (most
	  // cases little) to big endian
	  current_word = htonl(current_word);
	  memdumpFile.write((char*) &current_word, 4);
	  memdump_start_addr++; size_words--;
	}
      
      // Ideally we've now finished piping out the data
      // not 100% about the endianess of this.
    }
  memdumpFile.close();
  
}


void
Or1200MonitorSC::busMonitor()
{

  // This is for the wb_conmax module. Presumably other Wishbone bus arbiters 
  // will need this section of the code to be re-written appropriately, along 
  // with the relevent functions in the OrpsocAccess module.
  
  static busLogStates busLogState = BUS_LOG_IDLE;
  static int currentMaster = -1;
  static uint32_t currentAddr = 0, currentDataIn = 0;
  static uint32_t currentSel = 0, currentSlave = 0;
  static bool currentWe = false;
  static int cyclesWaited = 0;

  if (bus_trans_log_start_delay_enable)
    {      
      if (sc_time_stamp() >= bus_trans_log_start_delay)
	{
	  // No longer waiting
	  bus_trans_log_start_delay_enable = false;
	  cout << "* System log now enabled (time =  " << bus_trans_log_start_delay.to_string() << ")" << endl;	  
	}
      
      if (bus_trans_log_start_delay_enable)
	return;
    }
  
  switch ( busLogState )
    {
    case BUS_LOG_IDLE:
      {
	// Check the current granted master's cyc and stb inputs
	uint32_t gnt = accessor->getWbArbGrant();
	if (accessor->getWbArbMastCycI(gnt) && accessor->getWbArbMastStbI(gnt) && 
	    !accessor->getWbArbMastAckO(gnt))
	  {
	    currentAddr = accessor->getWbArbMastAdrI(gnt);	      
	    currentDataIn = accessor->getWbArbMastDatI(gnt);
	    currentSel = (uint32_t) accessor->getWbArbMastSelI(gnt);
	    currentSlave = (uint32_t)accessor->getWbArbMastSlaveSelDecoded(gnt)-1;
	    currentWe = accessor->getWbArbMastWeI(gnt);
	    currentMaster = gnt;
	    busLogState = BUS_LOG_WAIT_FOR_ACK;
	    cyclesWaited = 0;
	  }
      }
      
      break;
      
    case BUS_LOG_WAIT_FOR_ACK:
      
      cyclesWaited++;
      
      // Check for ACK
      if (accessor->getWbArbMastAckO(currentMaster))
	{
	  // Transaction completed
	  busTransLog << sc_time_stamp() << " M" << currentMaster << " ";
	  if (currentWe)
	    busTransLog << " W " << hex << currentSel << " " << hex << std::setfill('0') << std::setw(8) << currentAddr << " S" << dec <<  currentSlave << " " << hex << std::setw(8) << currentDataIn << " " << dec << cyclesWaited << endl;
	  else
	    busTransLog << " R " << hex << currentSel << " " << hex << std::setfill('0') << std::setw(8) << currentAddr << " S" << dec << currentSlave << " "  << hex << std::setw(8) << accessor->getWbArbMastDatO(currentMaster) << " " << dec << cyclesWaited << endl;
	  
	  busLogState = BUS_LOG_IDLE;
	}
      
      break;
      
    }

  return;
  
}	// busMonitor ()
