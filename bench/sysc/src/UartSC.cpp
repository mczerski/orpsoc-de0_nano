// ----------------------------------------------------------------------------

// SystemC Uart: implementation

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

// $Id: $

#include <iostream>
#include <iomanip>
#include <cmath>

#include "UartSC.h"

//#define UART_SC_DEBUG


SC_HAS_PROCESS( UartSC );

//! Constructor for the Uart system C model

//! @param[in] name  Name of this module, passed to the parent constructor.
// Todo: Probably some sort of scaler parameter

UartSC::UartSC (sc_core::sc_module_name   name):
  sc_module (name)
{

  SC_METHOD (checkTx);
  dont_initialize();
  sensitive << clk.pos();
  //sensitive << uarttx;
  
}	// UartSC ()

void 
UartSC::initUart (int clk_freq_hz, // Presume in NS
		  int uart_baud
		  ) 
{
  // Calculate number of clocks per UART bit
  clocks_per_bit = (int)(clk_freq_hz/uart_baud);
  bits_received=0;
#ifdef UART_SC_DEBUG
  printf("UartSC Initialised: Sys. clk. freq.: %d Hz, Baud: %d, cpb: %d\n", clk_freq_hz, uart_baud, clocks_per_bit);
#endif
}  


// Maybe do this with threads instead?!
void 
UartSC::checkTx () {

#ifdef UART_SC_DEBUG
  //printf("Uart TX activity: level is : 0x%x\n", uarttx.read()&1);
#endif
  
  // Check the number of bits received
  if (bits_received==0)
    {
      // Check if tx is low
      if ((uarttx.read()&1) == 0)
	{ 
	  // Line pulled low, begin receive of new char
	  current_char = 0;
	  // Start 
	  counter = 1;
	  bits_received++; // We got the start bit
#ifdef UART_SC_DEBUG
	  cout << "UartSC checkTx: got start bit at time " << sc_time_stamp() << endl;
#endif
	}
    }
  else if (bits_received > 0 && bits_received < 9)
    {
      // Check the counter - see if it's time to sample the line
      // We do an extra half-bit delay on first bit read
      if ( ((bits_received==1) && 
	    (counter == (clocks_per_bit + (clocks_per_bit/2)))) || 
	   ((bits_received > 1) && (counter == clocks_per_bit)) )
	{
	  //printf("UartSC checkTx: read bit %d as 0x%x at time", bits_received, uarttx.read()&1);
	  //cout << sc_time_stamp() << endl;

	  // Shift in the current value of the tx into our char
	  current_char |= ((uarttx.read() & 1) << (bits_received-1));
	  // Reset the counter
	  counter = 1;
	  // Increment bit number
	  bits_received++;
	}
      else
	counter++;
    }
  else if (bits_received == 9)
    { 
      // Now check for stop bit 1
      if (counter == clocks_per_bit)
	{
	  // Check that the value is 1 - this should be the stop bit
	  if ((uarttx.read() & 1) != 1)
	    {
	      printf("UART TX framing error at time\n");
	      cout << sc_time_stamp() << endl;

	      // Perhaps do something else here to deal with this
	      bits_received = 0;
	      counter = 0;
	    }
	  else
	    {
	      // Print the char
#ifdef UART_SC_DEBUG
	      printf("Char received: 0x%2x time: ", current_char);
	      cout << sc_time_stamp() << endl;
#endif
	      // cout'ing the char didn't work for some systems - jb 090613ol
	      //cout << current_char;
	      printf("%c",current_char);

	      bits_received = 0;
	      counter = 0;
	    }
	}
      else
	counter++;
    }
}
  


