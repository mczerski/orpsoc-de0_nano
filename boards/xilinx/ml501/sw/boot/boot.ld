
MEMORY
	{
	reset	: ORIGIN = 0x00000000, LENGTH = 0x00000108
        ram     : ORIGIN = 0x0000108, LENGTH = 4K
	}

SECTIONS
{
	.reset :
        {
        *(.reset)
        } > reset


/* 
	.vectors :
        {
        _vec_start = .;
        *(.vectors)
        _vec_end = .;
        } > vectors
*/
        .text :
        {
        *(.text)
        } > ram

      .rodata :
        {
        *(.rodata)
        *(.rodata.*)
        } > ram
 
     .icm :
        {
        _icm_start = .;
        *(.icm)
        _icm_end = .;
        } > ram

     .data :
        {
        _dst_beg = .;
        *(.data)
        _dst_end = .;
        } > ram
 
      .bss :
        {
        *(.bss)
        } > ram
 
      .stack (NOLOAD) :
        {
        *(.stack)
        _src_addr = .;
        } > ram

}
