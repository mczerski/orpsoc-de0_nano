orpsoc-de0_nano
===============

ORPSoC fork (from git://openrisc.net/stefan/orpsoc) for de0_nano board (Altera Cyclone IV FPGA) 
with custom made expansion board.

Expansion board contains following features:
- etherned phy and RJ45 socket
- VGA output based on resistor ladder (4-bits per color)
- usb 1.1 phy and usb socket
- RS-232
- 2xPS2
- SD/MMC socket
- additional sdram chip

Usage
=====

Board specific files are located in boards/altera/de0_nano directory. To synthesise the design just go
to the root directory of the project and then:

    cd boards/altera/de0_nano/syn/quartus/run
    make all

If synthesis ends without errors, orpsoc.sof file will be generated in the same directory.
