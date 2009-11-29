/* Test three custom instructions.  */

#include "../support/support.h"

void buserr_except(){}
void dpf_except(){}
void ipf_except(){}
void lpint_except(){}
void align_except(){}
void illegal_except(){}
void hpint_except(){}
void dtlbmiss_except(){}
void itlbmiss_except(){}
void range_except(){}
void syscall_except(){}
void fpu_except(){}
void trap_except(){}
void res2_except(){}

/* Custom instruction l.cust5: move byte
   
   Move byte custom instruction moves a least significant byte from source register rB and
   combines it with other bytes from source register rA and places combined result into rD. Location
   of the placed byte in rD depends on the immediate.
*/
#define MOVBYTE(dr,sr,sb,i) asm volatile ("l.cust5\t%0,%1,%2,%3,1" : "=r" (dr) : "r" (sr), "r" (sb), "i" (i)); report(dr)

/* Custom instruction l.cust5: set bit
   
   Take source register rA, set a specified bit to 1 and place result to destination register rD.
   Bit to be set is specified with an immediate.
*/
#define SETBIT(dr,sr,i) asm volatile ("l.cust5\t%0,%1,r0,%2,2" : "=r" (dr) : "r" (sr), "i" (i)); report(dr)

/* Custom instruction l.cust5: clear bit
   
   Take source register rA, clear a specified bit to 0 and place result to destination register rD.
   Bit to be cleared is specified with an immediate.
*/
#define CLRBIT(dr,sr,i) asm volatile ("l.cust5\t%0,%1,r0,%2,3" : "=r" (dr) : "r" (sr), "i" (i)); report(dr)

/* Test case for "move byte" custom instruction
   
   Move least significant byte from variable s into different byte positions of variable d.
   Every time a byte move is done compute checksum of variable d. Final checksum is used to verify
   correct operation.

*/
unsigned long test_movbyte()
{
	unsigned long s, d, r;
	
	s = 0x12345678;
	r = d = 0xaabbccdd;

	MOVBYTE	(d, d, s, 0);
	r += d;
	MOVBYTE	(d, d, s, 1);
	r += d;
	MOVBYTE	(d, d, s, 2);
	r += d;
	MOVBYTE	(d, d, s, 3);
	r += d;

	return (r);
}

/* Test case for "set bit" custom instruction
   
   Set a couple of bits of variable d to 1.
   Every time a bit is set compute checksum of variable d. Final checksum is used to verify
   correct operation.

*/
unsigned long test_setbit()
{
	unsigned long d, r;
	
	r = d = 0x00000000;

	SETBIT	(d, d, 10);
	r += d;
	SETBIT	(d, d, 15);
	r += d;
	SETBIT	(d, d, 19);
	r += d;
	SETBIT	(d, d, 25);
	r += d;

	return (r);
}

/* Test case for "clear bit" custom instruction
   
   Clear a couple of bits of variable d to 0.
   Every time a bit is cleared compute checksum of variable d. Final checksum is used to verify
   correct operation.

*/
unsigned long test_clrbit()
{
	unsigned long d, r;
	
	r = d = 0xffffffff;

	CLRBIT	(d, d, 10);
	r += d;
	CLRBIT	(d, d, 15);
	r += d;
	CLRBIT	(d, d, 19);
	r += d;
	CLRBIT	(d, d, 25);
	r += d;

	return (r);
}

int main()
{	
	unsigned long result = 0;
	
	result += test_movbyte();
	result += test_setbit();
	result += test_clrbit();
	
	printf("RESULT: %.8lx\n", result);
	report(result);
	or32_exit(result);
}
