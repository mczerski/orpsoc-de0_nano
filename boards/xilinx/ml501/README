Xilinx ML501 board build

This board contains a Xilinx Virtex5 LX50 part. The key supported features in board build are the DDR2 SODIMM, the ZBT SRAM and the Ethernet MAC (only 10/100, no Gigabit support). Additionally configured features of the ML501 include the GPIO and UART.

For more information on the ML501, see Xilinx's page: http://www.xilinx.com/products/devkits/HW-V5-ML501-UNI-G.htm

Configuring the build:

The Verilog include file rtl/ml501_defines.v contains the defines which control how the RTL is configured. This is where the desired memory controller, and internal blockRAM memory configuration is set, as well as which peripherals to include. See that file for further details.

There are seperate defines files for each of the componenets in ORPSoC also included in the board's RTL directory, allowing an individual configuration of the OR1200, ethernet and Wishbone arbiter for this board.

How to simulate:

Ensure the Xilinx tools are installed on your system and their path is configured in the board/tools.inc file.

Mentor Graphics' Modelsim is required to perform the simulations (Icarus Verilog cannot compile the Xilinx libraries).

Go into boards/xilinx/ml501/sim/run and do a "make rtl-board-tests". This will start a loop which will run 3 tests, a boot test (UART printout, simulation may take several minutes to complete), a memory test, testing the selected memory controller, and a GPIO test. To see VCD dumps of these tests, also set "VCD=1" when running the tests. If any changes were made to the RTL configuration, it's recommended a clean is run before re-running the simulations.

How to synthesize:

It is possible to run a single make command to run the flow from RTL synthesis through to programming file generation. To do this, go to the par/ directory and run "make ml501.bit".

The design is configured with the DDR2 SDRAM controller, ethernet MAC, and GPIO enabled by default. If any of these are disabled, or say the ZBT SRAM controller is used instead of the DDR2, the Xilinx mapper will fail when attemping to assign pins to nonexistant ports on the design. The UCF will need to be changed to fix this, so edit the par/ml501_xst.ucf UCF file, commenting or uncommenting, as necessary, the required clearly-marked sections.

The resulting FPGA .bit file can be downloaded and is configured to run the sw/boot program on reset (as long as that section of the memory has not been written over.)

Debugging on the board:

The standard OpenRISC debug interface, controlled via the JTAG bus, is included in this design. A seperate JTAG TAP is included with ORPSoC and is used in this build, its pins connected to the expansion header, J4 (the middle column), in the following order:
Pin 2: UART Rx
Pin 4: UART Tx
Pin 6: JTAG Tdo
Pin 8: JTAG Tdi
Pin 10: JTAG Tms
Pin 12: JTAG Tck

This debugging interface has been tested with the ORSoC debug cable and seen to work. These UART pins go to the same UART as the 9-pin DSUB connector, either one can be used for the UART interface.

To do:

Notes:

* The design currently runs the Wishbone bus and processor at 50MHz, the ZBT SRAM at 200MHz, the DDR2 SDRAM at 266 MHz. There are a few multi-cycle paths in the design for these memory controllers and these are defined in the UCF.

* The DDR2 SDRAM controller was generated using the Xilinx Memory Interface Generator (MIG) tool and has been modified slightly. The small cache RAM that sits between the DDR2 MIG controller and Wishbone interface must convert from 128-bit wide 266MHz domain generated memory signals to the 32-bit wide Wishbone domain words, and to do this another Xilinx Coregen blockRAM setup has been used. The RTL instantiating it is in the rtl/ path and the NGC is included in the syn/ path.

* The mapper complains that the debug interface's JTAG tck signal isn't going on on an optimal pin, but we override that. So far it has not been seen to exhibit any problematic effects.

* There are several errors reported in the timing report, after place and route, related to some clock domain crossover signals in the ethernet MAC core. Despite timing ignore (TIG) markings in the UCF these remain. Please contact the maintainer if this looks like it really is an issue, or can be solved somehow.

* As the Ethernet MAC core is only 10/100, it cannot handle gigabit mode. There is software included which resets the Marvell ethernet PHY and disables advertisement of gigabit capability.

* There is a user-driven reset feature, meaning the user is able to reset the system by accessing any address starting at 0xe0000000. For this to be enabled, however, the pins 62 and 64 on expansion header J4 (bottom two pins on same column as JTAG debug pins) must be connected. This is useful for debugging the system and not requiring that the reset button be pushed to restart it.

* A post-synthesis netlist can be made by going so syn/ and running "make ml501.v", and a post-PAR netlist can be made by going to par/ and running "make ml501.netlist". It is possible to run the post-synthesis simulation in sim/run/ running "make syn-board-test", however no target for post-PAR netlist simulation exists yet, although it shouldn't be too hard to configure.

Maintained by Julius Baxter, julius.baxter@orsoc.se
