spram:
	vppp --simple eth_spram_256x32.v > spram_256x32.v

fifo:
	vppp --simple eth_fifo.v > fifo.v

eth:
	cat eth_clockgen.v eth_crc.v eth_fifo.v eth_maccontrol.v eth_macstatus.v eth_miim.v eth_outputcontrol.v eth_random.v eth_receivecontrol.v eth_register.v eth_registers.v eth_rxaddrcheck.v eth_rxcounters.v eth_rxethmac.v eth_rxstatem.v eth_shiftreg.v eth_spram_256x32.v eth_transmitcontrol.v eth_txcounters.v eth_txethmac.v eth_txstatem.v eth_wishbone.v eth_top.v > eth_top_ip.v

all: eth
