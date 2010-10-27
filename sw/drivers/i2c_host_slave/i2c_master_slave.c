/*************************************************************
* I2C functions for the Herveille i2c controller            *
*                                                           *
* Provides functions to read from and write to the I2C bus. *
* Master and slave mode are both supported                  *
*                                                           *
* Julius Baxter, julius.baxter@orsoc.se                     *
*                                                           *
************************************************************/

#include "board.h"
#include "cpu-utils.h"
#include "i2c_master_slave.h"


inline unsigned char i2c_master_slave_read_i2c_reg(int core, unsigned char addr)
{
  return REG8((i2c_base_adr[core] + addr));
}
inline void i2c_master_slave_write_i2c_reg(int core, unsigned char addr, unsigned char data)
{
  REG8((i2c_base_adr[core] + addr)) = data;
}

int i2c_master_slave_wait_for_busy(int core)
{
  while(1) {
    // Check for busy flag in i2c status reg
    if(!(i2c_master_slave_read_i2c_reg(core, SR) & SR_BUSY))
      return 0;
  }
}


int i2c_master_slave_wait_for_transfer(int core)
{
  volatile unsigned char status;
  // Wait for ongoing transmission to finish
  while(1) {
    status = i2c_master_slave_read_i2c_reg(core, SR);		
    // If arbitration lost
    if( (status & SR_ARB_LOST) == SR_ARB_LOST)
      return 2;
    // If TIP bit = o , stop waiting
    else if(!(status & SR_TRANSFER_IN_PRG))
      return 0;
  }
}

/***********************************************************
* initI2C                                                  *
*                                                          *
* Setup i2c core:                                          *
* Write prescaler register with parmeter passed, enable    *
* core in control register, optionally enable interrupts   *
************************************************************/
int i2c_master_slave_initI2C (int core, unsigned short prescaler, int interrupt_enable) 
{

  // Setup I2C prescaler,
  i2c_master_slave_write_i2c_reg(core, PRERlo, prescaler&0xff);     
  i2c_master_slave_write_i2c_reg(core, PRERhi, (prescaler>>8)&0xff);

  // Enable I2C controller and optionally interrupts
  if (interrupt_enable)
    i2c_master_slave_write_i2c_reg(core, CTR, CTR_CORE_ENABLE | CTR_INTR_ENABLE );
  else
    i2c_master_slave_write_i2c_reg(core, CTR, CTR_CORE_ENABLE );

  return 0;

}

/***********************************************************
* initI2CSlave                                             *
*                                                          *
* Setup i2c core to allow slave accesses:                  *
* OR in slave enable bit to control register               *
* Set slave address                                        *
************************************************************/
int i2c_master_slave_initI2CSlave (int core, char addr)
{
  
  // Set slave enable bit
  i2c_master_slave_write_i2c_reg(core, CTR, i2c_master_slave_read_i2c_reg(core, CTR) | CTR_SLAVE_ENABLE);
  // Set slave address
  i2c_master_slave_write_i2c_reg(core, SLADR, addr );
  
  return 0;

}

/***********************************************************
* deactI2CSlave                                             *
*                                                          *
* Disable slave mode for this I2C core                     *
* Deassert slave eanble bit in control register            *
************************************************************/
int i2c_master_slave_deactI2CSlave (int core)
{
  // Slave slave enable bit
  i2c_master_slave_write_i2c_reg(core, CTR, i2c_master_slave_read_i2c_reg(core, CTR) & ~CTR_SLAVE_ENABLE);
  
  return 0;
}


/***********************************************************
* masterStart				                   *
*                                                          *
* Get the i2c bus.                                         *
************************************************************/
int i2c_master_slave_masterStart(int core, unsigned char addr, int read) {

  
  i2c_master_slave_wait_for_busy(core);
    
  // Set address in transfer register
  i2c_master_slave_write_i2c_reg(core, TXR, (addr<<1)|read);

  // Start and write the address
  i2c_master_slave_write_i2c_reg(core, CR, CR_START | CR_WRITE);
  
  i2c_master_slave_wait_for_transfer(core);
    
  return 0;
}

/***********************************************************
* masterWrite						   *
*                                                          *
* Send 1 byte of data					   *
************************************************************/
int i2c_master_slave_masterWrite(int core, unsigned char data, 
		       int check_prev_ack, int stop) 
{
  if (i2c_master_slave_wait_for_transfer(core))
    return 1;
  
  i2c_master_slave_write_i2c_reg(core, TXR, data); // present data

  if (!stop)
    i2c_master_slave_write_i2c_reg(core, CR, CR_WRITE); // set command (write)
  else
    i2c_master_slave_write_i2c_reg(core, CR, CR_WRITE | CR_STOP); // set command (write)
  
  return 0;
}

/***********************************************************
* masterStop						   *
*                                                          *
* Send stop condition					   *
************************************************************/
int i2c_master_slave_masterStop(int core) {
  unsigned char status;
  unsigned char ready=0;

  // Make I2C controller wait at end of finished byte
  if (i2c_master_slave_wait_for_transfer(core))
    return 1;
  
  // Send stop condition
  i2c_master_slave_write_i2c_reg(core, CR, CR_STOP);

  return 0;
}

/***********************************************************
* masterRead                                               *
*                                                          *
* Read 1 byte of data    				   *
************************************************************/
int i2c_master_slave_masterRead(int core, int check_prev_ack, 
		      int stop, char* data) {
 
  // Make I2C controller wait at end of finished byte
  if (i2c_master_slave_wait_for_transfer(core))
    return 1;
  
  if (stop)
    i2c_master_slave_write_i2c_reg(core, CR, CR_READ | CR_STOP);
  else
    i2c_master_slave_write_i2c_reg(core, CR, CR_READ);

  if (i2c_master_slave_wait_for_transfer(core))
    return 1;

  *data = i2c_master_slave_read_i2c_reg(core, RXR);

  return 0;
}


/***********************************************************
* ackInterrupt                                             *
*                                                          *
* Acknowledge interrupt has been serviced		   *
************************************************************/
int i2c_master_slave_ackInterrupt(int core)
{
 
  i2c_master_slave_write_i2c_reg(core, CR, CR_IACK);
 
  return 0;
}
