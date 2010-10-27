/*************************************************************
 * I2C functions for Herveille i2c master_slave core         *
 *                                                           *
 * Provides functions to read from and write to the I2C bus. *
 * Master and slave mode are both supported                  *
 *                                                           *
 *                                                           *
 ************************************************************/

#ifndef _I2C_MASTER_SLAVE_H_
#define _I2C_MASTER_SLAVE_H_

extern const int i2c_base_adr[4];
//Memory mapping adresses

#define PRERlo 0x0  // Clock prescaler register 
#define PRERhi 0x1  // Clock prescaler register 
#define CTR    0x2     // Control register
#define TXR    0x3     // Transmit register
#define RXR    0x3     // Recive register
#define CR     0x4      // Controll register
#define SR     0x4      // Status register
#define SLADR  0x7      // Slave address register


#define CTR_CORE_ENABLE 0x80
#define CTR_INTR_ENABLE 0x40
#define CTR_SLAVE_ENABLE 0x20

#define CR_START        0x80
#define CR_STOP         0x40
#define CR_READ         0x20
#define CR_WRITE        0x10
#define CR_ACK          0x08
#define CR_SL_CONT      0x02
#define CR_IACK         0x01

#define SR_RXACK            0x80
#define SR_BUSY             0x40
#define SR_ARB_LOST         0x20
#define SR_SLAVE_MODE       0x10
#define SR_SLAVE_DATA_AVAIL 0x08
#define SR_SLAVE_DATA_REQ   0x04
#define SR_TRANSFER_IN_PRG  0x02
#define SR_IRQ_FLAG         0x01


int i2c_master_slave_initI2C(int core, unsigned short prescaler, 
			     int interrupt_enable);

int i2c_master_slave_initI2CSlave (int core, char addr);
int i2c_master_slave_deactI2CSlave (int core);
int i2c_master_slave_masterStart(int core, unsigned char addr, int read);
int i2c_master_slave_masterWrite(int core, unsigned char data, 
				 int check_prev_ack, int stop);
int i2c_master_slave_masterStop(int core);
int i2c_master_slave_masterRead(int core, int check_prev_ack, int stop, 
				char* data);
int i2c_master_slave_ackInterrupt(int core);
#endif
