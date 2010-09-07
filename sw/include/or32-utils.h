#ifndef _OR32_UTILS_H_
#define _OR32_UTILS_H_


// null from stddef.h
#define NULL ((void *)0)
// valist stuff from stddef.h
typedef __builtin_va_list __gnuc_va_list;
typedef __gnuc_va_list va_list;
#define va_start(v,l)   __builtin_va_start(v,l)
#define va_end(v)       __builtin_va_end(v)
#define va_arg(v,l)     __builtin_va_arg(v,l)
#define va_copy(d,s)    __builtin_va_copy(d,s)

// size_t and wchar definitions
typedef unsigned int size_t;
// wchar def
#ifndef __WCHAR_TYPE__
#define __WCHAR_TYPE__ int
#endif
#ifndef __cplusplus
typedef __WCHAR_TYPE__ wchar_t;
#endif


/* Register access macros */
#define REG8(add) *((volatile unsigned char *)(add))
#define REG16(add) *((volatile unsigned short *)(add))
#define REG32(add) *((volatile unsigned long *)(add))


/*
 * l.nop constants
 *
 */
#define NOP_NOP         0x0000      /* Normal nop instruction */
#define NOP_EXIT        0x0001      /* End of simulation */
#define NOP_REPORT      0x0002      /* Simple report */
#define NOP_PRINTF      0x0003      /* Simprintf instruction */
#define NOP_PUTC        0x0004      /* Simulation putc instruction */
#define NOP_REPORT_FIRST 0x0400     /* Report with number */
#define NOP_REPORT_LAST  0x03ff      /* Report with number */

/* For writing into SPR. */
void mtspr(unsigned long spr, unsigned long value);

/* For reading SPR. */
unsigned long mfspr(unsigned long spr);

/* Print out a character via simulator */
void sim_putc(unsigned char c);

/* Prints out a value */
void report(unsigned long value);

/* Loops/exits simulation */
void exit(int i);

/* memcpy */
void* memcpy( void* s1, void* s2, size_t n);

/* strlen */
size_t strlen(const char*s);  

/* memchr */
void *memchr(const void *s, int c, size_t n);

/* Variable keeping track of timer ticks */
extern unsigned long timer_ticks;
/* Enable tick timer and interrupt generation */
void enable_timer(void);
/* Disable tick timer and interrupt generation */
void disable_timer(void);
/* Timer increment - called by interrupt routine */
void timer_tick(void);
/* Reset tick counter */
void clear_timer_ticks(void);
/* Get tick counter */
unsigned long get_timer_ticks(void);
/* Wait for 10ms */
void wait_10ms(void);

/* Seed for LFSR function used in rand() */
/* This seed was derived from running the LFSR with a seed of 1 - helps skip the
   first iterations which outputs the value shifting through. */
#define RAND_LFSR_SEED 0x14b6bc3c
/* Pseudo-random number generation */
unsigned long int rand ();

#endif
