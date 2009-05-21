/* ADDED BY ME */
#define OR1K 1

/* Test l.mul, l.mac and l.macrc instructions */
#include "support.h"

#define T1 0xa6312f33
#define T2 0x0d4de375
#define T3 0x61ab48dc

#ifndef __or32__

#include <stdlib.h>
#define LONGEST long long


LONGEST acc = 0;
#define MAC(x,y) {\
  printf ("[%08x,%08x]\t", (unsigned long)(x), (unsigned long)(y));\
  acc += (LONGEST)(x) * (LONGEST)(y);\
  printf ("(%08x,%08x)\n", (unsigned long)(acc >> 32), (unsigned long)(acc & 0xffffffff));\
}
#define MACRC    (macrc())
static inline long macrc() {
  long result = acc >> 28;
  printf ("<%08x>\n", (unsigned long)result);
  acc = 0;
  return result;
}
#else /* OR1K */

#define MAC(x,y) asm volatile ("l.mac\t%0,%1" : : "r" (x), "r" (y))
#define MACRC macrc()
static inline long macrc() {
  long x;
  asm volatile ("l.macrc\t%0" : "=r" (x));
  return x;
}

#endif /* SIM */

// Define dummpy or32 trap vectors
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
void res1_except(){}
void trap_except(){}
void res2_except(){}


long test_mul (long a, long b) {
  long t;
  int i;
  for (i = 0; i < 100; i++) {
    t = a * b;
    t += 153;
    a = t - a * 17;
    b = t + b * 13333;    

    /*printf ("(%08x,%08x)", a, b);*/
  }
  return a;
}

long test_mac (long a, long b) {
  long t = 1234567;
  int i;
  for (i = 0; i < 100; i++) {
    MAC (a, b);
    if (i & 3) {
      a = t - a;
      b = t + a;
    } else {
      a = MACRC;
      report(a);
    }
    MAC (a, 3);
    MAC (a, 5);
    MAC (a, 7);
    //printf ("(%08x,%08x)", a, b);
  }
  return a;
}

long test_mul_mac (long a, long b) {
  long t = 1;
  int i;
  for (i = 0; i < 100; i++) {
    a = a * 119;
    MAC (a, b);
    MAC (b, 423490431);
    MAC (b, 113);
    MAC (a, 997);
    b = 87 * a * t;
    if (i & 3) {
      t = a * b;
      a = t - a;
      b = t + a;
    } else {
      a = MACRC;
    }
 //   printf ("(%08x,%08x)", a, b);
  }  
  return a;
}

int main () {
  unsigned t1;
  unsigned t2;
  unsigned t3;
/*
  report (MACRC);
  MAC ((unsigned long)888888887, (unsigned long)0x87654321);
  report (MACRC);
  MAC ((unsigned long)888888887, (unsigned long)0x87654321);
  MAC ((unsigned long)888888887, (unsigned long)0x87654321);
  report (MACRC);
  or32_exit(0);
*/
  printf ("%8x\n", MACRC);
  t1 = test_mul (888888887, 0x87654321);    
  //t2 = test_mac (888888887, 0x87654321);    
  //t3 = test_mul_mac (888888887, 0x87654321);
  printf ("%08x, expected %08x\n", t1, T1);
  //printf ("%08x, expected %08x\n", t2, T2);
  //printf ("%08x, expected %08x\n", t3, T3);
  report (t1 /*^ t2 ^ t3*/ ^ T1 /* ^ T2 ^ T3*/ ^ 0xdeaddead);
  if (t1 != T1 /* || t2 != T2 || t3 != T3*/) {
    printf ("Test failed!\n");
    if (t1 != T1) or32_exit (1);
    //if (t2 != T2) or32_exit (2);
    //if (t3 != T3) or32_exit (3);
  } else {
    printf ("Test succesful.\n");
    or32_exit (0);
  }
  or32_exit (0);
}
