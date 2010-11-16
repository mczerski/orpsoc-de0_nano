
# Expecting BOARD_SW_ROOT already set to indicate how far below directory we're
# in the board's software root path is.

# Root from the board's sw/ path
PROJ_ROOT=../../../..

# Figure out actual path the common software directory
SW_ROOT=$(BOARD_SW_ROOT)/$(PROJ_ROOT)/sw

# Set the BOARD_PATH to point to the root of this board build
BOARD_PATH=$(shell pwd)/$(BOARD_SW_ROOT)/..

# Set RTL_VERILOG_INCLUDE_DIR so software 
RTL_VERILOG_INCLUDE_DIR=$(BOARD_PATH)/rtl/verilog/include

# Set the processor capability flags
# This doesn't work! :-( Need to figure out way to set these and have them
# carry through to things like the liborpsoc driver modules etc.
#MARCH_FLAGS =-mhard-mul -mhard-div -msoft-float
MARCH_FLAGS =-mhard-mul -msoft-div -msoft-float
export MARCH_FLAGS

# Finally include the main software include file

include $(SW_ROOT)/Makefile.inc
