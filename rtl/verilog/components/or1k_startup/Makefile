spi:
	vppp --simple spi_clgen.v spi_shift.v spi_top.v | cat copyright_spi.v - > spi_flash.v

OR1K_startup:
	vppp --simple +define+SPI_BASE_MSB+B000 OR1K_startup_generic.v | cat copyright_OR1K_startup.v - > OR1K_startup.v

OR1K_startup_ACTEL:
	vppp --simple OR1K_startup_ACTEL.v | cat copyright_OR1K_startup.v - > OR1K_startup_ACTEL_IP.v

all: spi OR1K_startup OR1K_startup_ACTEL
	
