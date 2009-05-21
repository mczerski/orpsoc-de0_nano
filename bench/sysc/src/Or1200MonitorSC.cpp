// ----------------------------------------------------------------------------

// SystemC OpenRISC 1200 Monitor: implementation

// Copyright (C) 2008  Embecosm Limited <info@embecosm.com>

// Contributor Jeremy Bennett <jeremy.bennett@embecosm.com>

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

// $Id: Or1200MonitorSC.cpp 303 2009-02-16 11:20:17Z jeremy $

#include <iostream>
#include <iomanip>

#include "Or1200MonitorSC.h"


SC_HAS_PROCESS( Or1200MonitorSC );

//! Constructor for the OpenRISC 1200 monitor

//! @param[in] name  Name of this module, passed to the parent constructor.
//! @param[in] accessor  Accessor class for this Verilated ORPSoC model

Or1200MonitorSC::Or1200MonitorSC (sc_core::sc_module_name   name,
				  OrpsocAccess             *_accessor) :
  sc_module (name),
  accessor (_accessor)
{
  SC_METHOD (checkInstruction);
  sensitive << clk.pos();
  dont_initialize();
    
}	// Or1200MonitorSC ()


//! Method to handle special instrutions

//! These are l.nop instructions with constant values. At present the
//! following are implemented:

//! - l.nop 1  Terminate the program
//! - l.nop 2  Report the value in R3
//! - l.nop 3  Printf the string with the arguments in R3, etc
//! - l.nop 4  Print a character

void
Or1200MonitorSC::checkInstruction()
{
  uint32_t  r3;
  double    ts;

  // Check the instruction when the freeze signal is low.
  if (!accessor->getWbFreeze())
    {
      // Do something if we have l.nop
      switch (accessor->getWbInsn())
	{
	case NOP_EXIT:
	  r3 = accessor->getGpr (3);
	  ts = sc_time_stamp().to_seconds() * 1000000000.0;
	  std::cout << std::fixed << std::setprecision (2) << ts;
	  std::cout << " ns: Exiting (" << r3 << ")" << std::endl;
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

	default:
	  break;
	}
    }

}	// checkInstruction()

