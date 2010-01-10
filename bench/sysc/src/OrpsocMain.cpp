/////////////////////////////////////////////////////////////////////
////                                                              ////
////  ORPSoC SystemC Testbench                                    ////
////                                                              ////
////  Description                                                 ////
////  ORPSoC Testbench file                                       ////
////                                                              ////
////  To Do:                                                      ////
////                                                              ////
////                                                              ////
////  Author(s):                                                  ////
////      - Jeremy Bennett jeremy.bennett@embecosm.com            ////
////      - Julius Baxter jb@orsoc.se                             ////
////                                                              ////
////                                                              ////
//////////////////////////////////////////////////////////////////////
////                                                              ////
//// Copyright (C) 2009 Authors and OPENCORES.ORG                 ////
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

#include "OrpsocMain.h"

#include "jtagsc.h"

#include "Vorpsoc_top.h"
#include "OrpsocAccess.h"
#include "MemoryLoad.h"

#include <SpTraceVcdC.h>

#include "ResetSC.h"
#include "Or1200MonitorSC.h"
#include "GdbServerSC.h"
#include "UartSC.h"

int SIM_RUNNING;
int sc_main (int   argc,
	     char *argv[] )
{
  sc_set_time_resolution( 1, TIMESCALE_UNIT);
  // CPU clock (also used as JTAG TCK) and reset (both active high and low)
  sc_time  clkPeriod (BENCH_CLK_HALFPERIOD * 2.0, TIMESCALE_UNIT);
  sc_time   jtagPeriod (JTAG_CLK_HALFPERIOD * 2.0, TIMESCALE_UNIT);

  sc_clock             clk ("clk", clkPeriod);
  sc_clock  jtag_tck ("jtag-clk", jtagPeriod, 0.5, SC_ZERO_TIME, false);
  
  sc_signal<bool>      rst;
  sc_signal<bool>      rstn;
  sc_signal<bool>      rst_o;

  sc_signal<bool>      jtag_tdi;		// JTAG interface
  sc_signal<bool>      jtag_tdo;
  sc_signal<bool>      jtag_tms;
  sc_signal<bool>      jtag_trst;

  sc_signal<bool>      uart_rx;		// External UART
  sc_signal<bool>      uart_tx;

  sc_signal<bool> spi_sd_sclk; // SD Card Memory SPI
  sc_signal<bool> spi_sd_ss;
  sc_signal<bool> spi_sd_miso;
  sc_signal<bool> spi_sd_mosi;
  
  sc_signal<uint32_t> gpio_a; // GPIO bus - output only in verilator sims

  sc_signal<bool> spi1_mosi;
  sc_signal<bool> spi1_miso;
  sc_signal<bool> spi1_ss;
  sc_signal<bool> spi1_sclk;

  SIM_RUNNING = 0;

  // Setup the name of the VCD dump file
  bool VCD_enabled = false;
  string dumpNameDefault("vlt-dump.vcd");
  string testNameString;
  string vcdDumpFile;
  // VCD dump controling vars
  bool dump_start_delay_set = false, dump_stop_set = false;
  bool dumping_now = false;
  int dump_depth = 99; // Default dump depth
  sc_time dump_start,dump_stop, finish_time;
  bool finish_time_set = false; // By default we will let the simulation finish naturally
  SpTraceVcdCFile *spTraceFile;
  
  /*int*/double time_val;
  bool vcd_file_name_given = false;

  bool rsp_server_enabled = false;
  int rsp_server_port = DEFAULT_RSP_PORT;

  // Executable app load variables
  int do_program_file_load = 0; // Default: we don't require a file, we use the VMEM
  char* program_file; // Old char* style for program name

  // Verilator accessor
  OrpsocAccess    *accessor;

  // Modules
  Vorpsoc_top *orpsoc;		// Verilated ORPSoC
  
  MemoryLoad *memoryload;       // Memory loader
  
  ResetSC          *reset;		// Generate a RESET signal
  Or1200MonitorSC  *monitor;		// Handle l.nop x instructions
  JtagSC           *jtag;		// Generate JTAG signals
  GdbServerSC      *gdbServer;		// Map RSP requests to debug unit
  UartSC          *uart;		// Handle UART signals

  // Instantiate the Verilator model, VCD trace handler and accessor
  orpsoc     = new Vorpsoc_top ("orpsoc");
  
  accessor   = new OrpsocAccess (orpsoc);
  
  memoryload = new MemoryLoad (accessor);
  
  monitor    = new Or1200MonitorSC ("monitor", accessor, memoryload, 
				    argc, argv);
  
  // Instantiate the SystemC modules
  reset         = new ResetSC ("reset", BENCH_RESET_TIME);
  
  jtag          = new JtagSC ("jtag");

  uart          = new UartSC("uart"); // TODO: Probalby some sort of param

  // Parse command line options
  // Default is for VCD generation OFF, only turned on if specified on command line
  
  // Search through the command line parameters for options  
  if (argc > 1)
    {
      for(int i=1; i<argc; i++)
	{
	  if ( (strcmp(argv[i], "-e")==0) ||
	       (strcmp(argv[i], "--endtime")==0) )
	    {
	      time_val = strtod(argv[i+1], NULL);	  
	      sc_time opt_end_time(time_val,TIMESCALE_UNIT);
	      finish_time = opt_end_time;
	      finish_time_set = true;
	    }
	  else if ( (strcmp(argv[i], "-f")==0) ||
		    (strcmp(argv[i], "--program")==0) )
	    {
	      do_program_file_load = 1; // Enable program loading - will be done after sim init
	      program_file = argv[i+1]; // Old char* style for program name
	    }
	  else if ((strcmp(argv[i], "-d")==0) ||
		   (strcmp(argv[i], "--vcdfile")==0) ||
		   (strcmp(argv[i], "-v")==0) ||
		   (strcmp(argv[i], "--vcdon")==0)
		   )
	    {
	      VCD_enabled = true;
	      dumping_now = true;
	      vcdDumpFile = dumpNameDefault;
	      if (i+1 < argc)
		if(argv[i+1][0] != '-')
		  {
		    testNameString = argv[i+1];
		    vcdDumpFile = testNameString;
		    i++;
		  }
	    }
	  else if ( (strcmp(argv[i], "-s")==0) ||
		    (strcmp(argv[i], "--vcdstart")==0) )
	    {
	      VCD_enabled = true;
	      time_val = strtod(argv[i+1], NULL);	  
	      sc_time dump_start_time(time_val,TIMESCALE_UNIT);
	      dump_start = dump_start_time;
	      dump_start_delay_set = true;
	      dumping_now = false;
	    }
	  else if ( (strcmp(argv[i], "-t")==0) ||
		    (strcmp(argv[i], "--vcdstop")==0) )
	    {
	      VCD_enabled = true;
	      time_val = strtod(argv[i+1],NULL);	  
	      sc_time dump_stop_time(time_val,TIMESCALE_UNIT);
	      dump_stop = dump_stop_time;
	      dump_stop_set = true;
	    }
	  else if ( (strcmp(argv[i], "-r")==0) ||
		    (strcmp(argv[i], "--rsp")==0) )
	    {
	      rsp_server_enabled = true;
	      if (i+1 < argc) if(argv[i+1][0] != '-')
				{
				  rsp_server_port = atoi(argv[i+1]);
				  i++;
				}
	    }
	  /* 
	     Depth setting of VCD doesn't appear to work, I think it's only
	     configurable during at compile time .
	  */
	  /*	  else if ( (strcmp(argv[i], "-p")==0) ||
		  (strcmp(argv[i], "--vcddepth")==0) )
		  {
		  dump_depth = atoi(argv[i+1]);	  
		  }*/
	  else if ( (strcmp(argv[i], "-h")==0) ||
		    (strcmp(argv[i], "--help")==0) )
	    {
	      printf("Usage: %s [options]\n",argv[0]);
	      printf("\n  ORPSoCv2 cycle accurate model\n");
	      printf("  For details visit http://opencores.org/openrisc,orpsocv2\n");
	      printf("\n");
	      printf("Options:\n");
	      printf("  -h, --help\t\tPrint this help message\n");
	      printf("\nSimulation control:\n");
      	      printf("  -f, --program <file> \tLoad program from OR32 ELF <file>\n");
	      printf("  -e, --endtime <val> \tStop the sim at <val> ns\n");
	      printf("\nVCD generation:\n");
	      printf("  -v, --vcdon\t\tEnable VCD generation\n");
	      printf("  -d, --vcdfile <file>\tEnable and save VCD to <file>\n");

	      printf("  -s, --vcdstart <val>\tEnable and delay VCD generation until <val> ns\n");
	      printf("  -t, --vcdstop <val> \tEnable and terminate VCD generation at <val> ns\n");
	      printf("\nRemote debugging:\n");
	      printf("  -r, --rsp [<port>]\tEnable RSP debugging server, opt. specify <port>\n");	     
	      monitor->printUsage();
	      printf("\n");
	      return 0;
	    }
	  
	}
    }
  
  // Determine if we're going to setup a VCD dump:
  // Pretty much setting any related option will enable VCD dumping.
  if (VCD_enabled)
    {
      
      cout << "* Enabling VCD trace";
  
      if (dump_start_delay_set)
	cout << ", on at time " << dump_start.to_string();
      if (dump_stop_set)
	cout << ", off at time " << dump_stop.to_string();
      cout << endl;
    }
  
  if (rsp_server_enabled)
    gdbServer     = new GdbServerSC ("gdb-server", FLASH_START, FLASH_END,
				       rsp_server_port, jtag->tapActionQueue);
  else
      gdbServer = NULL;
    
  // Connect up ORPSoC
  orpsoc->clk_pad_i (clk);
  orpsoc->rst_pad_i (rstn);
  orpsoc->rst_pad_o (rst_o);

  orpsoc->dbg_tck_pad_i  (jtag_tck);		// JTAG interface
  orpsoc->dbg_tdi_pad_i  (jtag_tdi);
  orpsoc->dbg_tms_pad_i  (jtag_tms);
  orpsoc->dbg_tdo_pad_o  (jtag_tdo);

  orpsoc->uart0_srx_pad_i (uart_rx);		// External UART
  orpsoc->uart0_stx_pad_o (uart_tx);

  orpsoc->spi_sd_sclk_pad_o (spi_sd_sclk); // SD Card Memory SPI
  orpsoc->spi_sd_ss_pad_o (spi_sd_ss);
  orpsoc->spi_sd_miso_pad_i (spi_sd_miso);
  orpsoc->spi_sd_mosi_pad_o (spi_sd_mosi);

  orpsoc->spi1_mosi_pad_o (spi1_mosi);
  orpsoc->spi1_miso_pad_i (spi1_miso);
  orpsoc->spi1_ss_pad_o  (spi1_ss);
  orpsoc->spi1_sclk_pad_o (spi1_sclk);


  orpsoc->gpio_a_pad_io (gpio_a); // GPIO bus - output only in 
                                  // verilator sims

  // Connect up the SystemC  modules
  reset->clk (clk);			// Reset
  reset->rst (rst);
  reset->rstn (rstn);

  monitor->clk (clk);			// Monitor

  jtag->sysReset (rst);			// JTAG
  jtag->tck (jtag_tck);
  jtag->tdi (jtag_tdi);
  jtag->tdo (jtag_tdo);
  jtag->tms (jtag_tms);
  jtag->trst (jtag_trst);

  uart->clk (clk); // Uart
  uart->uartrx (uart_rx); // orpsoc's receive line
  uart->uarttx (uart_tx); // orpsoc's transmit line

  // Tie off signals
  jtag_tdi      = 1;			// Tie off the JTAG inputs
  jtag_tms      = 1;
  
  spi_sd_miso = 0; // Tie off master-in/slave-out of SD SPI bus

  spi1_miso = 0;


  if (VCD_enabled)
    {
      Verilated::traceEverOn (true);
      
      printf("* VCD dumpfile: %s\n", vcdDumpFile.c_str());
      
      // Establish a new trace with its correct time resolution, and trace to
      // great depth.
      spTraceFile = new SpTraceVcdCFile ();
      //spTraceFile->spTrace()->set_time_resolution (sc_get_time_resolution());
      //setSpTimeResolution (sc_get_time_resolution ());
      //traceTarget->trace (spTraceFile, 99);
      orpsoc->trace (spTraceFile, dump_depth);
      
      if (dumping_now)    
	{
	  spTraceFile->open (vcdDumpFile.c_str());
	}
    }
  
  //printf("* Beginning test\n");

  // Init the UART function
  uart->initUart(25000000, 115200);

  if (do_program_file_load) // Did the user specify a file to load?
    {            
      cout << "* Loading program from " << program_file << endl;
      if (memoryload->loadcode(program_file,0,0) < 0)
	{
	  cout << "* Error: executable file " << program_file << " not loaded" << endl;
	}
    }
  else // Load SRAM from VMEM file
    {
      accessor->do_ram_readmemh();
    }

  SIM_RUNNING = 1;	        
  
  // First check how we should run the sim.
  if (VCD_enabled || finish_time_set)
    { // We'll run sim with step
      
      if (!VCD_enabled && finish_time_set)
	{
	  // We just run the sim until the set finish time
	  sc_start((double)(finish_time.to_double()), TIMESCALE_UNIT);
	  SIM_RUNNING=0;
	  sc_stop();
	  // Print performance summary
	  monitor->perfSummary();
	  // Do memdump if enabled
	  monitor->memdump();
	}
      else
	{
	  if (dump_start_delay_set)
	    {
	      // Run the sim until we want to dump
	      sc_start((double)(dump_start.to_double()),TIMESCALE_UNIT);
	      // Open the trace file
	      spTraceFile->open (vcdDumpFile.c_str());
	      dumping_now = 1;
	    }

	  if (dumping_now)
	    {
	      // Step the sim and generate the trace
	          // Execute until we stop
	      while(!Verilated::gotFinish())
		{
		  if (SIM_RUNNING) // Changed by Or1200MonitorSC when finish NOP
		    sc_start (1,TIMESCALE_UNIT); // Step the sim
		  else
		    {
		      spTraceFile->close();
		      break;
		    }
		  
		  spTraceFile->dump (sc_time_stamp().to_double());
		  
		  if (dump_stop_set)
		    {
		      if (sc_time_stamp() >=  dump_stop)
			{
			  // Close dump file
			  spTraceFile->close();
			  // Now continue on again until the end
			  if (!finish_time_set)
			    sc_start();
			  else
			    {
			      // Determine how long we should run for
			      sc_time sim_time_remaining = 
				finish_time - sc_time_stamp();
			      sc_start((double)(sim_time_remaining.to_double()),
				       TIMESCALE_UNIT);
			      // Officially stop the sim
			      sc_stop();
			      // Print performance summary
			      monitor->perfSummary();
			      // Do memdump if enabled
			      monitor->memdump();
			    }
			  break;
			}
		    }
		  if (finish_time_set)
		    {
		      if (sc_time_stamp() >=  finish_time)
			{
			  // Officially stop the sim
			  sc_stop();
			  // Close dump file
			  spTraceFile->close();
			  // Do memdump if enabled
			  monitor->memdump();
			  // Print performance summary
			  monitor->perfSummary();
			  break;
			}
		    }
		}
	    }
	}
    }
  else
    {
      // Simple run case
      // Ideally a "l.nop 1" will terminate the simulation gracefully
      sc_start();
    }
  
  
  // Free memory
  if (rsp_server_enabled)
    delete gdbServer;
  delete jtag;
  delete monitor;
  delete reset;

  delete accessor;

  //delete trace;
  delete orpsoc;

  return 0;

}	/* sc_main() */
