ORPSoCv2 board builds

This directory contains scripts and support RTL for synthesizing ORPSoC to run on various vendors' FPGAs and boards.

The directory hierarchy should first be organised by target FPGA vendor, and then by board model. Various configurations for each board may exist, and it's up to the maintainer of the board support to decide how that is handled (either several different make targets, or user modifiable scripts/constraints.)

The boards/tools.inc file:

This file contains various paths to vendor-specific FPGA development tools. It can be included in any Makefile used to synthesize the design, and is designed to provide a single place where users can set their own paths to tools, rather than having several hard-set paths throughout the scripts.

Add path variables to this file if it's likely a user will need to supply their own due to differing installation locations of tools.

Board build documentation

Please include a readme in each board's path, containing a rundown on the different configurations possible and the commands necessary to start synthesis. 
