// Program that will erase and program an SPI flash

#include "or32-utils.h"
#include "spr-defs.h"
#include "board.h"
#include "uart.h"
#include "simple-spi.h"
#include "printf.h"


unsigned long programming_file_start;
unsigned long programming_file_end;
unsigned long programming_file_length;
int spi_master;
char slave;



// Little program to dump the contents of the SPI flash memory it's connected 
// to on the board

void
spi_write_ignore_read(int core, char dat)
{
  spi_core_write_data(core,dat);
  while (!(spi_core_data_avail(core))); // Wait for the transaction (should 
                                        // generate a byte)
  spi_core_read_data(core);
}

char
spi_read_ignore_write(int core)
{
  spi_core_write_data(core, 0x00);
  while (!(spi_core_data_avail(core))); // Wait for the transaction (should 
                                        // generate a byte)
  return spi_core_read_data(core);
}


unsigned long
spi_read_id(int core, char slave_sel)
{
  unsigned long rdid;
  char* rdid_ptr = (char*) &rdid;
  int i;
  spi_core_slave_select(core, slave_sel); // Select slave
  rdid_ptr[3] = 0;
  // Send the RDID command
  spi_write_ignore_read(core,0x9f); // 0x9f is READ ID command
  // Now we read the next 3 bytes
  for(i=0;i<3;i++)
    {
      rdid_ptr[i] = spi_read_ignore_write(core);
    }
  spi_core_slave_select(core, 0); // Deselect slave
  return rdid;
}

// Read status regsiter
char
spi_read_sr(int core, char slave_sel)
{
  char rdsr;
  spi_core_slave_select(core, slave_sel); // Select slave
  // Send the RDSR command
  spi_write_ignore_read(core,0x05); // 0x05 is READ status register command
  rdsr = spi_read_ignore_write(core);
  spi_core_slave_select(core, 0); // Deselect slave  
  return rdsr;
}


void
spi_read_block(int core, char slave_sel, unsigned int addr, int num_bytes, 
	       char* buf)
{
  int i;
  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core, 0x3); // READ command
  spi_write_ignore_read(core,((addr >> 16) & 0xff)); // addres high byte
  spi_write_ignore_read(core,((addr >> 8) & 0xff)); // addres middle byte
  spi_write_ignore_read(core,((addr >> 0) & 0xff)); // addres low byte
  for(i=0;i<num_bytes;i++)
    buf[i] = spi_read_ignore_write(core);
  
  spi_core_slave_select(core, 0); // Deselect slave  
}


void
spi_set_write_enable(int core, char slave_sel)
{
  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core,0x06); // 0x06 is to set write enable
  spi_core_slave_select(core, 0); // Deselect slave  
}


// Write up to 256 bytes of data to a page, always from offset 0
void
spi_page_program(int core, char slave_sel, short page_num, int num_bytes, 
		 char* buf)
{
  
  // Set WE latch
  spi_set_write_enable(core, slave_sel);
  while(!(spi_read_sr(core, slave_sel) & 0x2)); // Check it's set

  int i;
  if (!(num_bytes > 0)) return;
  if (num_bytes > 256) return;
  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core, 0x2); // Page program command
  spi_write_ignore_read(core,((page_num >> 8) & 0xff)); // addres high byte
  spi_write_ignore_read(core,((page_num >> 0) & 0xff)); // addres middle byte
  spi_write_ignore_read(core,0); // addres low byte
  for(i=0;i<num_bytes;i++)
    spi_write_ignore_read(core, buf[i]);
  spi_core_slave_select(core, 0); // Deselect slave  

 // Now poll status reg for WIP bit
  while((spi_read_sr(core, slave_sel) & 0x1));
}


// Erase a sector - assumes 128KByte memory, so 4 sectors of 32KBytes each
void
spi_sector_erase(int core, char slave_sel, unsigned int sector)
{
  // Set WE latch
  spi_set_write_enable(core, slave_sel);
  while(!(spi_read_sr(core, slave_sel) & 0x2)); // Check it's set

  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core, 0xd8); // Sector erase command
  spi_write_ignore_read(core,(sector>>1)&0x1); // sector select high bit (bit 
                                               // 16 of addr)
  spi_write_ignore_read(core,(sector&0x1)<<7); // sector select low bit (bit 15
                                               // of addr)
  spi_write_ignore_read(core,0); // addres low byte  
  spi_core_slave_select(core, 0); // Deselect slave  

  // Now poll status reg for WIP bit
  while((spi_read_sr(core, slave_sel) & 0x1));

}

// Erase entire device
void
spi_bulk_erase(int core, char slave_sel)
{
 // Set WE latch
  spi_set_write_enable(core, slave_sel);
  while(!(spi_read_sr(core, slave_sel) & 0x2)); // Check it's set

  spi_core_slave_select(core, slave_sel); // Select slave
  spi_write_ignore_read(core, 0xc7); // Bulk erase
  spi_core_slave_select(core, 0); // Deselect slave  

 // Now poll status reg for WIP bit
  while((spi_read_sr(core, slave_sel) & 0x1));
}

extern unsigned long spiprogram_data, _spiprogram_data;
extern unsigned long end_spiprogram_data, _end_spiprogram_data;

#define printhelp() printf("\nUsage: \n\t[p]rogram\t\twrite program to flash\n\t[v]erify\t\tveryify written program\n\t[s]tatus\t\tprint status of SPI flash\n\n")

void 
print_spi_status(void)
{

  printf("SPI core: %d\n",spi_master);
  printf("SPI slave select: 0x%x\n",slave&0xff);

  printf("SPI slave info:\n");
  printf("\tID:\t%x\n", spi_read_id(spi_master, slave));
  printf("\tSR:\t%x\n", spi_read_sr(spi_master, slave));  
  printf("\n");
  printf("Programming file from 0x%x-0x%x, %d bytes\n",programming_file_start,
	 programming_file_end,
	 programming_file_length);
  printf("Embedded length: %d\n", (unsigned long) spiprogram_data);
}


// Verify contents of SPI flash
void
verify_spi(int core, char slave_sel, char * data, unsigned int length)
{
  unsigned int i;
  unsigned int page_num = 0;
  unsigned int bytes_this_page;
  char verify_buf[256];
  int verify_error = 0;
  printf("* Verifying contents of SPI flash.\n");
  while(length)
    {
      bytes_this_page = (length >= 256) ? 256 : length;
      spi_read_block(spi_master, slave, (page_num<<8), bytes_this_page, 
		     verify_buf);
      for(i=0;i<bytes_this_page;i++)
	{
	  if (verify_buf[i] != data[i])
	    {
	      printf("* Verify error! Byte %d of page %d - was 0x%x, expected 0x%x\n", i, page_num, verify_buf[i] & 0xff, data[i] & 0xff);
	      verify_error=1;
	    }
	}
      data +=256;
      length -= (length >= 256) ? 256 : length;
      page_num++;
    }
  if (verify_error)
    printf("* SPI flash verify NOT OK\n");
  else
    printf("* SPI flash verify OK\n");
  
}

// Function to fully erase and program SPI flash
void
program_spi(int core, char slave_sel, char * data, unsigned int length)
{
  char *program_data_ptr = data;
  unsigned int program_data_length = length;
  unsigned int i;
  unsigned int page_num = 0;
  unsigned int bytes_this_page;
  printf("* Erasing SPI flash\n");
  spi_bulk_erase(core,slave_sel);
  printf("* SPI flash erased\n");
  while(length)
    {
      bytes_this_page = (length >= 256) ? 256 : length;
      printf("* SPI page %d being programmed with %d bytes", page_num, bytes_this_page);
      spi_page_program(core, slave_sel, page_num, bytes_this_page, data);
      printf("\n");
      data +=256;
      length -= (length >= 256) ? 256 : length;
      page_num++;
    }
  printf("* SPI flash programmed\n");

  verify_spi(core,slave_sel,program_data_ptr,program_data_length);
  
}


int 
main()
{

  uart_init(0); // init the UART before we can printf
  
  volatile char c;
  int i,j;
  spi_master = 0;
  slave = 1;

  spi_core_slave_select(spi_master, 0); // Deselect slaves

  // Clear the read FIFO
  while (spi_core_data_avail(spi_master))
    c = spi_core_read_data(spi_master);
  
  programming_file_start = (unsigned long) &spiprogram_data;
  programming_file_end = (unsigned long) &end_spiprogram_data;
  programming_file_length = programming_file_end - programming_file_start;

  // SPI core 0, should already be configured to read out data
  // when we reset.

  printf("\n\n\tSPI flash programming app\n\n");

  while(1){
    printf("[p,v,s,h] > ");
    c = uart_getc(DEFAULT_UART);  
    printf("%c",c);
    printf("\n");
    
    if (c == 'h')
      printhelp();
    else if (c == 's')
      print_spi_status();
    else if (c == 'p')
      program_spi(spi_master, slave, (char *) &spiprogram_data, programming_file_length);
    else if (c == 'v')
      verify_spi(spi_master, slave, (char *) &spiprogram_data, programming_file_length);
    

  }
  
  return 0;

}
