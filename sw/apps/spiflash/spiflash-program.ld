/*STARTUP(../support/crt0.o)*/
/*ENTRY()*/
OUTPUT_ARCH(or32)
/*GROUP()*/
SEARCH_DIR(.)
__DYNAMIC  =  0;

MEMORY
{
	vectors : ORIGIN = 0, LENGTH = 0x1000
	ram     : ORIGIN = 0x1000, LENGTH = (8M - 0x1000)
}


/*
 * Allocate the stack to be at the top of memory, since the stack
 * grows down.
 */
PROVIDE (_stack = 64K - 4);
PROVIDE (__stack = 64K - 4);

SECTIONS
{	
	.vectors :
	{
		*(.vectors)
	} > vectors
                              
	.text : {
		stext = .;
		_stext = .;
		*(.text)
		_etext  =  .;
		__CTOR_LIST__ = .;
		LONG((__CTOR_END__ - __CTOR_LIST__) / 4 - 2)
		*(.ctors)
		LONG(0)
		__CTOR_END__ = .;
		__DTOR_LIST__ = .;
		LONG((__DTOR_END__ - __DTOR_LIST__) / 4 - 2)
		*(.dtors)
		LONG(0)
		__DTOR_END__ = .;
		*(.lit)
		*(.shdata)
		_endtext = .;
	}  > ram

	.rodata : {
		*(.rodata);
		*(.rodata.*)
	} > ram

	/* Section we'll use for storing the program to load into the SPI flash */
	.spiprogram : {
		    spiprogram_data = .;
		    _spiprogram_data = .;
		    *(.spiprogram)
		    end_spiprogram_data = .;
		    _end_spiprogram_data = .;

	} > ram
	
	.shbss :
	{
		*(.shbss)
	} > ram
	
	.talias :
	{ 
	}  > ram
	
	.data : {
		sdata  =  .;
		_sdata  =  .;
		*(.data)
		edata  =  .;
		_edata  =  .;
	} > ram
	
	.bss SIZEOF(.data) + ADDR(.data) :
	{
		_bss_start = ALIGN(0x8);
		*(.bss)
		*(COMMON)
		_bss_end = .;
	}
	
	.stab  0 (NOLOAD) : 
	{
		[ .stab ]
	}
	
	.stabstr  0 (NOLOAD) :
	{
		[ .stabstr ]
	}
}
