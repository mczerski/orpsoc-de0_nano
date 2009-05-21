// ----------------------------------------------------------------------------

// Access functions for the ORPSoC Verilator model: implementation

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

// $Id: OrpsocAccess.cpp 303 2009-02-16 11:20:17Z jeremy $

#include "OrpsocAccess.h"

#include "Vorpsoc_top.h"
#include "Vorpsoc_top_orpsoc_top.h"
#include "Vorpsoc_top_or1k_top.h"
#include "Vorpsoc_top_or1200_top.h"
#include "Vorpsoc_top_or1200_cpu.h"
#include "Vorpsoc_top_or1200_ctrl.h"
#include "Vorpsoc_top_or1200_rf.h"
#include "Vorpsoc_top_or1200_dpram.h"

//! Constructor for the ORPSoC access class

//! Initializes the pointers to the various module instances of interest
//! within the Verilator model.

//! @param[in] orpsoc  The SystemC Verilated ORPSoC instance

OrpsocAccess::OrpsocAccess (Vorpsoc_top *orpsoc_top)
{
  or1200_ctrl = orpsoc_top->v->i_or1k->i_or1200_top->or1200_cpu->or1200_ctrl;
  rf_a        = orpsoc_top->v->i_or1k->i_or1200_top->or1200_cpu->or1200_rf->rf_a;

}	// OrpsocAccess ()


//! Access for the wb_freeze signal

//! @return  The value of the or1200_ctrl.wb_freeze signal

bool
OrpsocAccess::getWbFreeze ()
{
  return  or1200_ctrl->wb_freeze;

}	// getWbFreeze ()


//! Access for the wb_insn register

//! @return  The value of the or1200_ctrl.wb_insn register

uint32_t
OrpsocAccess::getWbInsn ()
{
  return  (or1200_ctrl->get_wb_insn) ();

}	// getWbInsn ()


//! Access for the OR1200 GPRs

//! These are extracted from memory using the Verilog function

//! @param[in] regNum  The GPR whose value is wanted

//! @return            The value of the GPR

uint32_t
OrpsocAccess::getGpr (uint32_t  regNum)
{
  return  (rf_a->get_gpr) (regNum);

}	// getGpr ()
