/*$$HEADER*/
/******************************************************************************/
/*                                                                            */
/*                    H E A D E R   I N F O R M A T I O N                     */
/*                                                                            */
/******************************************************************************/

// Project Name                   : ORPSoCv2
// File Name                      : gdb.c
// Prepared By                    : jb, rmd
// Project Start                  : 2008-10-01

/*$$COPYRIGHT NOTICE*/
/******************************************************************************/
/*                                                                            */
/*                      C O P Y R I G H T   N O T I C E                       */
/*                                                                            */
/******************************************************************************/
/*
  This library is free software; you can redistribute it and/or
  modify it under the terms of the GNU Lesser General Public
  License as published by the Free Software Foundation; 
  version 2.1 of the License, a copy of which is available from
  http://www.gnu.org/licenses/old-licenses/lgpl-2.1.txt.

  This library is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
  Lesser General Public License for more details.

  You should have received a copy of the GNU Lesser General Public
  License along with this library; if not, write to the Free Software
  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

/*$$DESCRIPTION*/
/******************************************************************************/
/*                                                                            */
/*                           D E S C R I P T I O N                            */
/*                                                                            */
/******************************************************************************/
//
// Implements RSP comatible GDB stub
//


/*$$CHANGE HISTORY*/
/******************************************************************************/
/*                                                                            */
/*                         C H A N G E  H I S T O R Y                         */
/*                                                                            */
/******************************************************************************/

// Date		Version	Description
//------------------------------------------------------------------------
// 081101		Imported code from "jp" project			jb
// 090219               Adapted code from Jeremy Bennett's RSP server
//                      for the or1ksim project.                       rmb
// 090304               Finished RSP server code import, added extra
//                      functions, adding stability when debugging on
//                      a remote target.                                jb
// 090608               A few hacks for VPI compatibilty added          jb

#ifdef CYGWIN_COMPILE

#else
// linux includes		   
#include <time.h>
#include <sched.h>
#endif

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <stdarg.h>

/* Libraries for JTAG proxy server.  */
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/ioctl.h>
#include <sys/select.h>
#include <sys/poll.h>
#include <fcntl.h>
#include <netdb.h>
#include <netinet/tcp.h>
#include <signal.h>
#include <inttypes.h>
#include <errno.h>
#include <arpa/inet.h>


#ifndef DEBUG_GDB
#define DEBUG_GDB 0
#endif

#ifndef DEBUG_GDB_DUMP_DATA
#define DEBUG_GDB_DUMP_DATA 0
#endif

#ifndef DEBUG_GDB_BLOCK_DATA
#define DEBUG_GDB_BLOCK_DATA 0
#endif

#ifndef DEBUG_CMDS
#define DEBUG_CMDS 0
#endif

/*! Name of the Or1ksim RSP service */
#define OR1KSIM_RSP_SERVICE  "or1ksim-rsp"

#include "gdb.h" /* partially copied from gdb/config/or1k */
#include "rsp-rtl_sim.h"

#define MAX_GPRS    (32)

/* Indices of GDB registers that are not GPRs. Must match GDB settings! */
#define PPC_REGNUM  (MAX_GPRS + 0)	/*!< Previous PC */
#define NPC_REGNUM  (MAX_GPRS + 1)	/*!< Next PC */
#define SR_REGNUM   (MAX_GPRS + 2)	/*!< Supervision Register */
#define NUM_REGS    (MAX_GPRS + 3)	/*!< Total GDB registers */

/* OR1k CPU registers address */
#define NPC_CPU_REG_ADD  	0x10							/* Next PC */
#define SR_CPU_REG_ADD   	0x11							/* Supervision Register */
#define PPC_CPU_REG_ADD  	0x12							/* Previous PC */
#define DMR1_CPU_REG_ADD	((6 << 11) + 16)	/* Debug Mode Register 1 (DMR1) 0x3010 */
#define DMR2_CPU_REG_ADD	((6 << 11) + 17)	/* Debug Mode Register 2 (DMR2) 0x3011 */
#define DSR_CPU_REG_ADD		((6 << 11) + 20)	/* Debug Stop Register (DSR) 0x3014 */
#define DRR_CPU_REG_ADD  	((6 << 11) + 21)	/* Debug Reason Register (DRR) 0x3015 */

/*! Trap instruction for OR32 */
#define OR1K_TRAP_INSTR  0x21000001

/*! The maximum number of characters in inbound/outbound buffers.  The largest
    packets are the 'G' packet, which must hold the 'G' and all the registers
    with two hex digits per byte and the 'g' reply, which must hold all the
    registers, and (in our implementation) an end-of-string (0)
    character. Adding the EOS allows us to print out the packet as a
    string. So at least NUMREGBYTES*2 + 1 (for the 'G' or the EOS) are needed
    for register packets */
#define GDB_BUF_MAX  ((NUM_REGS) * 8 + 1)

/*! Size of the matchpoint hash table. Largest prime < 2^10 */
#define MP_HASH_SIZE  1021

/* Definition of special-purpose registers (SPRs). */
#define MAX_SPRS (0x10000)

#define SPR_DMR1_ST	  		0x00400000  /* Single-step trace*/
#define SPR_DMR2_WGB	   	0x003ff000  /* Watchpoints generating breakpoint */
#define SPR_DSR_TE				0x00002000  /* Trap exception */

#define WORDSBIGENDIAN_N

/* Definition of OR1K exceptions */
#define EXCEPT_NONE     0x0000
#define EXCEPT_RESET	0x0100
#define EXCEPT_BUSERR	0x0200
#define EXCEPT_DPF	0x0300
#define EXCEPT_IPF	0x0400
#define EXCEPT_TICK	0x0500
#define EXCEPT_ALIGN	0x0600
#define EXCEPT_ILLEGAL	0x0700
#define EXCEPT_INT	0x0800
#define EXCEPT_DTLBMISS	0x0900
#define EXCEPT_ITLBMISS	0x0a00
#define EXCEPT_RANGE	0x0b00
#define EXCEPT_SYSCALL	0x0c00
#define EXCEPT_FPE	0x0d00
#define EXCEPT_TRAP	0x0e00

// Changed to #defines from static const int's due to compile error
// DRR (Debug Reason Register) Bits
#define SPR_DRR_RSTE  0x00000001  //!< Reset
#define SPR_DRR_BUSEE 0x00000002  //!< Bus error
#define SPR_DRR_DPFE  0x00000004  //!< Data page fault
#define SPR_DRR_IPFE  0x00000008  //!< Insn page fault
#define SPR_DRR_TTE   0x00000010  //!< Tick timer
#define SPR_DRR_AE    0x00000020  //!< Alignment
#define SPR_DRR_IIE   0x00000040  //!< Illegal instruction
#define SPR_DRR_IE    0x00000080  //!< Interrupt
#define SPR_DRR_DME   0x00000100  //!< DTLB miss
#define SPR_DRR_IME   0x00000200  //!< ITLB miss
#define SPR_DRR_RE    0x00000400  //!< Range fault
#define SPR_DRR_SCE   0x00000800  //!< System call
#define SPR_DRR_FPE   0x00001000  //!< Floating point
#define SPR_DRR_TE    0x00002000  //!< Trap


/*! Definition of GDB target signals. Data taken from the GDB 6.8
    source. Only those we use defined here. The exact meaning of 
    signal number is defined by the header `include/gdb/signals.h'
    in the GDB source code. For an explanation of what each signal
    means, see target_signal_to_string.*/
enum target_signal {
  TARGET_SIGNAL_NONE =  0,
  TARGET_SIGNAL_INT  =  2,
  TARGET_SIGNAL_ILL  =  4,
  TARGET_SIGNAL_TRAP =  5,
  TARGET_SIGNAL_FPE  =  8,
  TARGET_SIGNAL_BUS  = 10,
  TARGET_SIGNAL_SEGV = 11,
  TARGET_SIGNAL_ALRM = 14,
  TARGET_SIGNAL_USR2 = 31,
  TARGET_SIGNAL_PWR  = 32
};

/*! String to map hex digits to chars */
static const char hexchars[]="0123456789abcdef";


//! Is the NPC cached?

//! Setting the NPC flushes the pipeline, so subsequent reads will return
//! zero until the processor has refilled the pipeline. This will not be
//! happening if the processor is stalled (as it is when GDB had control),
//! so we must cache the NPC. As soon as the processor is unstalled, this
//! cached value becomes invalid. So we must track the stall state, and if
//! appropriate cache the NPC.
enum stallStates {
  STALLED,
  UNSTALLED,
  UNKNOWN
} stallState;

int      npcIsCached;		//!< Is the NPC cached - should be bool
uint32_t  npcCachedValue;		//!< Cached value of the NPC

static int err = 0;


/************************
   JTAG Server Routines
************************/
int serverIP = 0;
int serverPort = 0;
int server_fd = 0;
int gdb_fd = 0;

static int tcp_level = 0;

/* global to store what chain the debug unit is currently connected to 
(not the JTAG TAP, but the onchip debug module has selected) */
int gdb_chain = -1;

/*! Data structure for RSP buffers. Can't be null terminated, since it may
  include zero bytes */
struct rsp_buf
{
  char  data[GDB_BUF_MAX];
  int   len;
};

/*! Enumeration of different types of matchpoint. These have explicit values
    matching the second digit of 'z' and 'Z' packets. */
enum mp_type {
  BP_MEMORY   = 0,		// software-breakpoint Z0  break 
  BP_HARDWARE = 1,		// hardware-breakpoint Z1  hbreak 
  WP_WRITE    = 2,		// write-watchpoint    Z2  watch  
  WP_READ     = 3,		// read-watchpoint     Z3  rwatch  
  WP_ACCESS   = 4			// access-watchpoint   Z4  awatch
};										

/*! Data structure for a matchpoint hash table entry */
struct mp_entry
{
  enum mp_type       type;		/*!< Type of matchpoint */
  uint32_t  addr;		/*!< Address with the matchpoint */
  uint32_t  instr;		/*!< Substituted instruction */
  struct mp_entry   *next;		/*!< Next entry with this hash */
};

/*! Central data for the RSP connection */
static struct
{
  int            		client_waiting;	/*!< Is client waiting a response? */
// Not used  int                proto_num;		/*!< Number of the protocol used */
  int                client_fd;		/*!< FD for talking to GDB */
  int               sigval;			/*!< GDB signal for any exception */
  uint32_t start_addr;	/*!< Start of last run */
  struct mp_entry   *mp_hash[MP_HASH_SIZE];	/*!< Matchpoint hash table */
} rsp;

/* Forward declarations of static functions */
static char *printTime(void);
static int gdb_read(void*, int);
static int gdb_write(void*, int);
static void ProtocolClean(int, int32_t);
static void GDBRequest(void);
static void rsp_interrupt();
static char rsp_peek();
static struct rsp_buf *get_packet (void);
static void rsp_init (void);
static void set_npc (uint32_t  addr);
static uint32_t get_npc();
static void rsp_check_for_exception();
static int check_for_exception_vector(uint32_t ppc);
static void rsp_exception (uint32_t  except);
static int get_rsp_char (void);
static int hex (int  c);
static void rsp_get_client (void);
static void rsp_client_request (void);
static void rsp_client_close (void);
static void client_close (char err);
static void	put_str_packet (const char *str);
static void rsp_report_exception (void);
static void put_packet (struct rsp_buf *p_buf);
static void send_rsp_str (unsigned char *data, int len);
static void rsp_query (struct rsp_buf *p_buf);
static void rsp_vpkt (struct rsp_buf *p_buf);
static void	rsp_step (struct rsp_buf *p_buf);
static void	rsp_step_with_signal (struct rsp_buf *p_buf);
static void	rsp_step_generic (uint32_t  addr, uint32_t  except);
static void rsp_continue (struct rsp_buf *p_buf);
static void	rsp_continue_with_signal (struct rsp_buf *p_buf);
static void	rsp_continue_generic (uint32_t  addr, uint32_t  except);
static void rsp_read_all_regs (void);
static void rsp_write_all_regs (struct rsp_buf *p_buf);
static void rsp_read_mem (struct rsp_buf *p_buf);
static void rsp_write_mem (struct rsp_buf *p_buf);
static void rsp_write_mem_bin (struct rsp_buf *p_buf);
static int rsp_unescape (char *data, int len);
static void rsp_read_reg (struct rsp_buf *p_buf);
static void rsp_write_reg (struct rsp_buf *p_buf);
static void mp_hash_init (void);
static void	mp_hash_add (enum mp_type type, uint32_t  addr, uint32_t  instr);
static struct mp_entry * mp_hash_lookup (enum mp_type type, uint32_t  addr);
static struct mp_entry * mp_hash_delete (enum mp_type type,	uint32_t  addr);
static void rsp_remove_matchpoint (struct rsp_buf *p_buf);
static void rsp_insert_matchpoint (struct rsp_buf *p_buf);
static void rsp_command (struct rsp_buf *p_buf);
static void rsp_set (struct rsp_buf *p_buf);
static void rsp_restart (void);
static void  ascii2hex (char *dest,char *src);
static void  hex2ascii (char *dest,	char *src);
static uint32_t hex2reg (char *p_buf);
static void	reg2hex (uint32_t  val, char *p_buf);
static void swap_buf(char* p_buf, int len);
static void set_stall_state (int state);
static void reset_or1k (void);
static void gdb_ensure_or1k_stalled();
static int gdb_set_chain(int chain);
static int gdb_write_reg(uint32_t adr, uint32_t data);
static int gdb_read_reg(uint32_t adr, uint32_t *data);
static int gdb_write_block(uint32_t adr, uint32_t *data, int len);
static int gdb_read_block(uint32_t adr, uint32_t *data, int len);

char *printTime(void)
{
  time_t tid;
  struct tm *strtm; 
  static char timeBuf[20];
  
  time(&tid); 
  strtm = localtime(&tid);
  sprintf(timeBuf,"[%.02d:%.02d:%.02d] ",strtm->tm_hour,strtm->tm_min,strtm->tm_sec);
  return timeBuf;
}
/*---------------------------------------------------------------------------*/
/*!Set the serverPort variable
                                                                             */
/*---------------------------------------------------------------------------*/

void 
set_rsp_server_port(int portNum)
{
  serverPort = portNum;
}

/*---------------------------------------------------------------------------*/
/*!Initialize the Remote Serial Protocol connection

   Set up the central data structures.                                       */
/*---------------------------------------------------------------------------*/
void
rsp_init (void)
{
  /* Clear out the central data structure */
  rsp.client_waiting =  0;		/* GDB client is not waiting for us */
  rsp.client_fd      = -1;		/* i.e. invalid */
  rsp.sigval         = 0;		/* No exception */
  rsp.start_addr     = EXCEPT_RESET;	/* Default restart point */

  /* Set up the matchpoint hash table */
  mp_hash_init ();
  
  /* RSP always starts stalled as though we have just reset the processor. */
  rsp_exception (EXCEPT_TRAP);

  /* Setup the NPC caching variables */
  stallState = STALLED;
  // Force a caching of the NPC
  npcIsCached = 0;
  get_npc();
  
}	/* rsp_init () */

/*---------------------------------------------------------------------------*/
/*!Look for action on RSP

   This function is called when the processor has stalled, which, except for
   initialization, must be due to an interrupt.

   If we have no RSP client, we get one. We can make no progress until the
   client is available.

   Then if the cause is an exception following a step or continue command, and
   the exception not been notified to GDB, a packet reporting the cause of the
   exception is sent.

   The next client request is then processed.                                */
/*---------------------------------------------------------------------------*/
void
handle_rsp (void)
{
  uint32_t		temp_uint32;

  rsp_init();
  
  while (1){
    /* If we have no RSP client, wait until we get one. */
    while (-1 == rsp.client_fd)
      {
	rsp_get_client ();
	rsp.client_waiting = 0;		/* No longer waiting */
      }
    
    /* If we have an unacknowledged exception tell the GDB client. If this
       exception was a trap due to a memory breakpoint, then adjust the NPC. */
    if (rsp.client_waiting)
      {
	
	// Check for exception
	rsp_check_for_exception();
	
	if(stallState == STALLED)
	  // Get the PPC if we're stalled
	  gdb_read_reg(PPC_CPU_REG_ADD, &temp_uint32);
	
	
	if ((TARGET_SIGNAL_TRAP == rsp.sigval) && (NULL != mp_hash_lookup (BP_MEMORY, temp_uint32)))
	  {
	  if (stallState != STALLED)
	    // This is a quick fix for a strange situation seen in some of the simulators where
	    // the sw bp would be detected, but the stalled state variable wasn't updated correctly
	    // indicating that last time it checked, it wasn't set but the processor has now hit the
	    // breakpoint. So run rsp_check_for_exception() to bring everything up to date.
	    rsp_check_for_exception();
	  
	  if(DEBUG_GDB) printf("Software breakpoint hit at 0x%08x. Rolling back NPC to this instruction\n", temp_uint32);
	  
	  set_npc (temp_uint32);
	  
	  rsp_report_exception();
	  rsp.client_waiting = 0;		/* No longer waiting */
	}
	else if(stallState == STALLED) {
	  // If we're here, the thing has stalled, but not because of a breakpoint we set
	  // report back the exception
	  
	  rsp_report_exception();
	  rsp.client_waiting = 0;		/* No longer waiting */
	  
	}	      
      }
    
    // See if there's any incoming data from the client by peeking at the socket
    if (rsp_peek() > 0)
      {
	if (rsp_peek() == 0x03 && (stallState != STALLED)) // ETX, end of text control char
	  {
	    // Got an interrupt command from GDB, this function should
	    // pull the packet off the socket and stall the processor.
	    // and then send a stop reply packet with signal TARGET_SIGNAL_NONE
	    rsp_interrupt();
	    rsp.client_waiting = 0;
	  }
	else if (rsp.client_waiting == 0)
	  {
	    // Default handling of data from the client:
	    /* Get a RSP client request */
	    rsp_client_request ();
	  }
      } /* end if (rsp_peek() > 0) */
    
  }

}   /* handle_rsp () */


/*
  Check if processor is stalled - if it is, read the DRR
  and return the target signal code
*/
static void rsp_check_for_exception()
{

  unsigned char stalled;
  uint32_t drr;
  err = dbg_cpu0_read_ctrl(0, &stalled);				 /* check if we're stalled */
  
  if (!(stalled & 0x01))
    {
      // Processor not stalled. Just return;
      return;
    }
  
  if (DEBUG_GDB) printf("rsp_check_for_exception() detected processor was stalled\nChecking DRR\n");
  
  // We're stalled
  stallState = STALLED;
  npcIsCached = 0;

  gdb_set_chain(SC_RISC_DEBUG);

  // Now read the DRR (Debug Reason Register)
  gdb_read_reg(DRR_CPU_REG_ADD, &drr);

  if (DEBUG_GDB) printf("DRR: 0x%08x\n", drr);
  
  switch ((int)(drr&0xffffffff))
    {
    case SPR_DRR_RSTE:  rsp.sigval = TARGET_SIGNAL_PWR;  break;
    case SPR_DRR_BUSEE: rsp.sigval = TARGET_SIGNAL_BUS;  break;
    case SPR_DRR_DPFE:  rsp.sigval = TARGET_SIGNAL_SEGV; break;
    case SPR_DRR_IPFE:  rsp.sigval = TARGET_SIGNAL_SEGV; break;
    case SPR_DRR_TTE:   rsp.sigval = TARGET_SIGNAL_ALRM; break;
    case SPR_DRR_AE:    rsp.sigval = TARGET_SIGNAL_BUS;  break;
    case SPR_DRR_IIE:   rsp.sigval = TARGET_SIGNAL_ILL;  break;
    case SPR_DRR_IE:    rsp.sigval = TARGET_SIGNAL_INT;  break;
    case SPR_DRR_DME:   rsp.sigval = TARGET_SIGNAL_SEGV; break;
    case SPR_DRR_IME:   rsp.sigval = TARGET_SIGNAL_SEGV; break;
    case SPR_DRR_RE:    rsp.sigval = TARGET_SIGNAL_FPE;  break;
    case SPR_DRR_SCE:   rsp.sigval = TARGET_SIGNAL_USR2; break;
    case SPR_DRR_FPE:   rsp.sigval = TARGET_SIGNAL_FPE;  break;
    case SPR_DRR_TE:    rsp.sigval = TARGET_SIGNAL_TRAP; break;
      
    default:
      // This must be the case of single step (which does not set DRR)
      rsp.sigval = TARGET_SIGNAL_TRAP; break;
    }

  if (DEBUG_GDB) printf("rsp.sigval: 0x%x\n", rsp.sigval);
  
  return;  
}

/*---------------------------------------------------------------------------*/
/*!Check if PPC is in an exception vector that halts program flow

Compare the provided PPC with known exception vectors that are fatal
to a program's execution. Call rsp_exception(ppc) to set the appropriate
sigval and return.

@param[in] ppc  Value of current PPC, as read from debug unit
@return: 1 if we set a sigval and should return control to GDB, else 0       */
/*---------------------------------------------------------------------------*/
static int 
check_for_exception_vector(uint32_t ppc)
{
  switch(ppc)
    {
      // The following should return sigvals to GDB for processing
    case EXCEPT_BUSERR:   
    case EXCEPT_ALIGN:    
    case EXCEPT_ILLEGAL:  
    case EXCEPT_TRAP:     if(DEBUG_GDB) 
	                    printf("PPC at exception address\n");
                          rsp_exception(ppc); 
			  return 1;
      
    default:
      return 0;
    }
  return 1; 
}

/*---------------------------------------------------------------------------*/
/*!Note an exception for future processing

   The simulator has encountered an exception. Record it here, so that a
   future call to handle_exception will report it back to the client. The
   signal is supplied in Or1ksim form and recorded in GDB form.

   We flag up a warning if an exception is already pending, and ignore the
   earlier exception.

   @param[in] except  The exception (Or1ksim form)                           */
/*---------------------------------------------------------------------------*/
void
rsp_exception (uint32_t  except)
{
  int  sigval;			/* GDB signal equivalent to exception */

  switch (except)
    {
    case EXCEPT_RESET:    sigval = TARGET_SIGNAL_PWR;  break;
    case EXCEPT_BUSERR:   sigval = TARGET_SIGNAL_BUS;  break;
    case EXCEPT_DPF:      sigval = TARGET_SIGNAL_SEGV; break;
    case EXCEPT_IPF:      sigval = TARGET_SIGNAL_SEGV; break;
    case EXCEPT_TICK:     sigval = TARGET_SIGNAL_ALRM; break;
    case EXCEPT_ALIGN:    sigval = TARGET_SIGNAL_BUS;  break;
    case EXCEPT_ILLEGAL:  sigval = TARGET_SIGNAL_ILL;  break;
    case EXCEPT_INT:      sigval = TARGET_SIGNAL_INT;  break;
    case EXCEPT_DTLBMISS: sigval = TARGET_SIGNAL_SEGV; break;
    case EXCEPT_ITLBMISS: sigval = TARGET_SIGNAL_SEGV; break;
    case EXCEPT_RANGE:    sigval = TARGET_SIGNAL_FPE;  break;
    case EXCEPT_SYSCALL:  sigval = TARGET_SIGNAL_USR2; break;
    case EXCEPT_FPE:      sigval = TARGET_SIGNAL_FPE;  break;
    case EXCEPT_TRAP:     sigval = TARGET_SIGNAL_TRAP; break;

    default:
      fprintf (stderr, "Warning: Unknown RSP exception %u: Ignored\n", except);
      return;
    }

  if ((0 != rsp.sigval) && (sigval != rsp.sigval))
    {
      fprintf (stderr, "Warning: RSP signal %d received while signal "
	       "%d pending: Pending exception replaced\n", sigval, rsp.sigval);
    }

  rsp.sigval         = sigval;		/* Save the signal value */

}	/* rsp_exception () */


/*---------------------------------------------------------------------------*/
/*!Get a new client connection.

   Blocks until the client connection is available.

   A lot of this code is copied from remote_open in gdbserver remote-utils.c.

   This involves setting up a socket to listen on a socket for attempted
   connections from a single GDB instance (we couldn't be talking to multiple
   GDBs at once!).

   The service is specified either as a port number in the Or1ksim configuration
   (parameter rsp_port in section debug, default 51000) or as a service name
   in the constant OR1KSIM_RSP_SERVICE.

   The protocol used for communication is specified in OR1KSIM_RSP_PROTOCOL. */
/*---------------------------------------------------------------------------*/
static void
rsp_get_client (void)
{
  int                 tmp_fd;		/* Temporary descriptor for socket */
  int                 optval;		/* Socket options */
  struct sockaddr_in  sock_addr;	/* Socket address */
  socklen_t           len;		/* Size of the socket address */

  /* 0 is used as the RSP port number to indicate that we should use the
     service name instead. */
  if (0 == serverPort)
  {
    struct servent *service = getservbyname (OR1KSIM_RSP_SERVICE, "tcp");
    if (NULL == service)
      {
	fprintf (stderr, "Warning: RSP unable to find service \"%s\": %s \n",
		 OR1KSIM_RSP_SERVICE, strerror (errno));
	return;
      }
    serverPort = ntohs (service->s_port);
  }

  /* Open a socket on which we'll listen for clients */
  tmp_fd = socket (PF_INET, SOCK_STREAM, IPPROTO_TCP);
  if (tmp_fd < 0)
    {
      fprintf (stderr, "ERROR: Cannot open RSP socket\n");
      exit (0);
    }

  /* Allow rapid reuse of the port on this socket */
  optval = 1;
  setsockopt (tmp_fd, SOL_SOCKET, SO_REUSEADDR, (char *)&optval,
	      sizeof (optval));

  /* Bind the port to the socket */
  sock_addr.sin_family      = PF_INET;
  sock_addr.sin_port        = htons (serverPort);
  sock_addr.sin_addr.s_addr = INADDR_ANY;
  if (bind (tmp_fd, (struct sockaddr *) &sock_addr, sizeof (sock_addr)))
    {
      fprintf (stderr, "ERROR: Cannot bind to RSP socket\n");
      exit (0);
    }
      
  /* Listen for (at most one) client */
  if (0 != listen (tmp_fd, 1))
    {
      fprintf (stderr, "ERROR: Cannot listen on RSP socket\n");
      exit (0);
    }

  printf("Waiting for gdb connection on localhost:%d\n", serverPort);
  fflush (stdout);

  printf("Press CTRL+c and type 'finish' to exit.\n");
  fflush (stdout);

  /* Accept a client which connects */
  len = sizeof (sock_addr);
  rsp.client_fd = accept (tmp_fd, (struct sockaddr *)&sock_addr, &len);

  if (-1 == rsp.client_fd)
  {
    fprintf (stderr, "Warning: Failed to accept RSP client\n");
    return;
  }

  /* Enable TCP keep alive process */
  optval = 1;
  setsockopt (rsp.client_fd, SOL_SOCKET, SO_KEEPALIVE, (char *)&optval,
	      sizeof (optval));

  int flags;
  
  /* If they have O_NONBLOCK, use the Posix way to do it */
  
#if defined(O_NONBLOCK)
  /* Fixme: O_NONBLOCK is defined but broken on SunOS 4.1.x and AIX 3.2.5. */
  if (-1 == (flags = fcntl(rsp.client_fd, F_GETFL, 0)))
    flags = 0;
  
  fcntl(rsp.client_fd, F_SETFL, flags | O_NONBLOCK);
#else
  /* Otherwise, use the old way of doing it */
  flags = 1;
  ioctl(fd, FIOBIO, &flags);
#endif



  /* Set socket to be non-blocking */

  /* We do this because when we're given a continue, or step
     instruction,command we set the processor stall off, then instnatly check
     if it's stopped. If it hasn't then we drop through and wait for input
     from GDB. Obviously this will cause problems when it will stop after we
     do the check. So now, rsp_peek() has been implemented to simply check if
     there's an incoming command from GDB (only interested in interrupt
     commands), otherwise it returns back to and poll the processor's PPC and
     stall bit. It can only do this if the socket is non-blocking.

     At first test, simply adding this line appeared to give no problems with
     the existing code. No "simulation" of blocking behaviour on the
     non-blocking socket was required (in the event that a read/write throws
     back a EWOULDBLOCK error, as was looked to be the case in the previous
     GDB handling code) -- Julius
  */
  if (ioctl(rsp.client_fd, FIONBIO, (char *)&optval) > 0 )
    {
      perror("ioctl() failed");
      close(rsp.client_fd);
      close(tmp_fd);
      exit(0);
    }

  
  /* Don't delay small packets, for better interactive response (disable
     Nagel's algorithm) */
  optval = 1;
  setsockopt (rsp.client_fd, IPPROTO_TCP, TCP_NODELAY, (char *)&optval,
	      sizeof (optval));

  /* Socket is no longer needed */
  close (tmp_fd);			/* No longer need this */
  signal (SIGPIPE, SIG_IGN);		/* So we don't exit if client dies */

  printf ("Remote debugging from host %s\n", inet_ntoa (sock_addr.sin_addr));
}	/* rsp_get_client () */


/*---------------------------------------------------------------------------*/
/*!Deal with a request from the GDB client session

   In general, apart from the simplest requests, this function replies on
   other functions to implement the functionality.                           */
/*---------------------------------------------------------------------------*/
static void rsp_client_request (void)
{
  struct rsp_buf *p_buf = get_packet ();	/* Message sent to us */

  // Null packet means we hit EOF or the link was closed for some other
  // reason. Close the client and return
  if (NULL == p_buf)
    {
      rsp_client_close ();
      return;
    }

  if (DEBUG_GDB){
    printf("%s-----------------------------------------------------\n", printTime());
    printf ("Packet received %s: %d chars\n", p_buf->data, p_buf->len );
    fflush (stdout);
  }

  switch (p_buf->data[0])
    {
    case '!':
      /* Request for extended remote mode */
      put_str_packet ("OK"); // OK = supports and has enabled extended mode.
      return;

    case '?':
      /* Return last signal ID */
      rsp_report_exception();
      return;

    case 'A':
      /* Initialization of argv not supported */
      fprintf (stderr, "Warning: RSP 'A' packet not supported: ignored\n");
      put_str_packet ("E01");
      return;

    case 'b':
      /* Setting baud rate is deprecated */
      fprintf (stderr, "Warning: RSP 'b' packet is deprecated and not "
	       "supported: ignored\n");
      return;

    case 'B':
      /* Breakpoints should be set using Z packets */
      fprintf (stderr, "Warning: RSP 'B' packet is deprecated (use 'Z'/'z' "
	       "packets instead): ignored\n");
      return;

    case 'c':
      /* Continue */
      rsp_continue (p_buf);
      return;

    case 'C':
      /* Continue with signal */
      rsp_continue_with_signal (p_buf);
      return;

    case 'd':
      /* Disable debug using a general query */
      fprintf (stderr, "Warning: RSP 'd' packet is deprecated (define a 'Q' "
	       "packet instead: ignored\n");
      return;

    case 'D':
      /* Detach GDB. Do this by closing the client. The rules say that
	 execution should continue. TODO. Is this really then intended
	 meaning? Or does it just mean that only vAttach will be recognized
	 after this? */
      put_str_packet ("OK");
      // In VPI disconnect everyone and exit
      rsp_client_close();
      client_close('0');
      dbg_client_detached();   // Send message to sim that the client detached
      exit(0);
      //reset_or1k ();
      //set_stall_state (0);
      return;

    case 'F':
      /* File I/O is not currently supported */
      fprintf (stderr, "Warning: RSP file I/O not currently supported: 'F' "
	       "packet ignored\n");
      return;

    case 'g':
      rsp_read_all_regs ();
      return;

    case 'G':
      rsp_write_all_regs (p_buf);
      return;
      
    case 'H':
      /* Set the thread number of subsequent operations. For now ignore
	    silently and just reply "OK" */
      put_str_packet ("OK");
      return;

    case 'i':
      /* Single instruction step */
      fprintf (stderr, "Warning: RSP cycle stepping not supported: target "
	       "stopped immediately\n");
      rsp.client_waiting = 1;			/* Stop reply will be sent */
      return;

    case 'I':
      /* Single instruction step with signal */
      fprintf (stderr, "Warning: RSP cycle stepping not supported: target "
	       "stopped immediately\n");
      rsp.client_waiting = 1;			/* Stop reply will be sent */
      return;

    case 'k':
      /* Kill request. Do nothing for now. */
      return;

    case 'm':
      /* Read memory (symbolic) */
      rsp_read_mem (p_buf);
      return;

    case 'M':
      /* Write memory (symbolic) */
      rsp_write_mem (p_buf);
      return;

    case 'p':
      /* Read a register */
      rsp_read_reg (p_buf);
      return;

    case 'P':
      /* Write a register */
      rsp_write_reg (p_buf);
      return;

    case 'q':
      /* Any one of a number of query packets */
      rsp_query (p_buf);
      return;

    case 'Q':
      /* Any one of a number of set packets */
      rsp_set (p_buf);
      return;

    case 'r':
      /* Reset the system. Deprecated (use 'R' instead) */
      fprintf (stderr, "Warning: RSP 'r' packet is deprecated (use 'R' "
	       "packet instead): ignored\n");
      return;

    case 'R':
      /* Restart the program being debugged. */
      rsp_restart ();
      return;

    case 's':
      /* Single step (one high level instruction). This could be hard without
			DWARF2 info */
      rsp_step (p_buf);
      return;

    case 'S':
      /* Single step (one high level instruction) with signal. This could be
			hard without DWARF2 info */
      rsp_step_with_signal (p_buf);
      return;

    case 't':
      /* Search. This is not well defined in the manual and for now we don't
	 		support it. No response is defined. */
      fprintf (stderr, "Warning: RSP 't' packet not supported: ignored\n");
      return;

    case 'T':
      /* Is the thread alive. We are bare metal, so don't have a thread
	 		context. The answer is always "OK". */
      put_str_packet ("OK");
      return;

    case 'v':
      /* Any one of a number of packets to control execution */
      rsp_vpkt (p_buf);
      return;

    case 'X':
      /* Write memory (binary) */
      rsp_write_mem_bin (p_buf);
      return;

    case 'z':
      /* Remove a breakpoint/watchpoint. */
      rsp_remove_matchpoint (p_buf);
      return;

    case 'Z':
      /* Insert a breakpoint/watchpoint. */
      rsp_insert_matchpoint (p_buf);
      return;

    default:
      /* Unknown commands are ignored */
      fprintf (stderr, "Warning: Unknown RSP request %s\n", p_buf->data);
      return;
    }
}	/* rsp_client_request () */


/*---------------------------------------------------------------------------*/
/*!Close the connection to the client if it is open                          */
/*---------------------------------------------------------------------------*/
static void
rsp_client_close (void)
{
  if (-1 != rsp.client_fd)
    {
      close (rsp.client_fd);
      rsp.client_fd = -1;
    }
}	/* rsp_client_close () */


/*---------------------------------------------------------------------------*/
/*!Send a packet to the GDB client

   Modeled on the stub version supplied with GDB. Put out the data preceded by
   a '$', followed by a '#' and a one byte checksum. '$', '#', '*' and '}' are
   escaped by preceding them with '}' and then XORing the character with
   0x20.

   @param[in] p_buf  The data to send                                          */
/*---------------------------------------------------------------------------*/
static void
put_packet (struct rsp_buf *p_buf)
{
  unsigned char  data[GDB_BUF_MAX * 2];
  int   len;
  int   ch;				/* Ack char */

  /* Construct $<packet info>#<checksum>. Repeat until the GDB client
     acknowledges satisfactory receipt. */
  do
  {
    unsigned char checksum = 0;	/* Computed checksum */
    int           count    = 0;	/* Index into the buffer */

    if (DEBUG_GDB_DUMP_DATA){
      printf ("Putting %s\n\n", p_buf->data);
      fflush (stdout);
    }

    len = 0;
    data[len++] =  '$';			/* Start char */

    /* Body of the packet */
    for (count = 0; count < p_buf->len; count++)
		{
		  unsigned char  ch = p_buf->data[count];

		  /* Check for escaped chars */
		  if (('$' == ch) || ('#' == ch) || ('*' == ch) || ('}' == ch))
		    {
		      ch       ^= 0x20;
		      checksum += (unsigned char)'}';
					data[len++] =  '}';
		    }

		  checksum += ch;
			data[len++] =  ch;
		}

		data[len++] =  '#';			/* End char */

    /* Computed checksum */
    data[len++] =	(hexchars[checksum >> 4]);
		data[len++] =	(hexchars[checksum % 16]);

		send_rsp_str ((unsigned char *) &data, len);

    /* Check for ack of connection failure */
    ch = get_rsp_char ();
    if (0 > ch)
		{
		  return;			/* Fail the put silently. */
		}
  }
  while ('+' != ch);
  
}	/* put_packet () */


/*---------------------------------------------------------------------------*/
/*!Convenience to put a constant string packet

   param[in] str  The text of the packet                                     */
/*---------------------------------------------------------------------------*/
static void
put_str_packet (const char *str)
{
  struct rsp_buf  buffer;
  int    len = strlen (str);

  /* Construct the packet to send, so long as string is not too big,
     otherwise truncate. Add EOS at the end for convenient debug printout */

  if (len >= GDB_BUF_MAX)
    {
      fprintf (stderr, "Warning: String %s too large for RSP packet: "
	       "truncated\n", str);
      len = GDB_BUF_MAX - 1;
    }

  strncpy (buffer.data, str, len);
  buffer.data[len] = 0;
  buffer.len       = len;

  put_packet (&buffer);

}	/* put_str_packet () */


/*---------------------------------------------------------------------------*/
/*!Get a packet from the GDB client
  
   Modeled on the stub version supplied with GDB. The data is in a static
   buffer. The data should be copied elsewhere if it is to be preserved across
   a subsequent call to get_packet().

   Unlike the reference implementation, we don't deal with sequence
   numbers. GDB has never used them, and this implementation is only intended
   for use with GDB 6.8 or later. Sequence numbers were removed from the RSP
   standard at GDB 5.0.

   @return  A pointer to the static buffer containing the data                */
/*---------------------------------------------------------------------------*/
static struct rsp_buf *
get_packet (void)
{
  static struct rsp_buf  buf;		/* Survives the return */

  /* Keep getting packets, until one is found with a valid checksum */
  while (1)
	{
		unsigned char checksum;		/* The checksum we have computed */
		int           count;			/* Index into the buffer */
		int 	     		ch;					/* Current character */

    /* Wait around for the start character ('$'). Ignore all other
	  characters */
    ch = get_rsp_char ();

    while (ch != '$')
		{
		  if (-1 == ch)
		    {
		      return  NULL;		/* Connection failed */
		    }

		  ch = get_rsp_char ();

		  // Potentially handle an interrupt character (0x03) here		  
		}

    /* Read until a '#' or end of buffer is found */
    checksum =  0;
    count    =  0;
    while (count < GDB_BUF_MAX - 1)
		{
		  ch = get_rsp_char ();
		  
		  if(rsp.client_waiting && DEBUG_GDB)
		    {
		      printf("%x\n",ch);
		    }


		  /* Check for connection failure */
		  if (0 > ch)
		    {
		      return  NULL;
		    }

		  /* If we hit a start of line char begin all over again */
		  if ('$' == ch)
		    {
		      checksum =  0;
		      count    =  0;

		      continue;
		    }

		  /* Break out if we get the end of line char */
		  if ('#' == ch)
		    {
		      break;
		    }

		  /* Update the checksum and add the char to the buffer */

		  checksum        = checksum + (unsigned char)ch;
		  buf.data[count] = (char)ch;
		  count           = count + 1;
		}

    /* Mark the end of the buffer with EOS - it's convenient for non-binary
	  data to be valid strings. */
    buf.data[count] = 0;
    buf.len         = count;

    /* If we have a valid end of packet char, validate the checksum */
    if ('#' == ch)
		{
		  unsigned char  xmitcsum;	/* The checksum in the packet */

		  ch = get_rsp_char ();
		  if (0 > ch)
		    {
		      return  NULL;		/* Connection failed */
		    }
		  xmitcsum = hex (ch) << 4;

		  ch = get_rsp_char ();
		  if (0 > ch)
		    {
		      return  NULL;		/* Connection failed */
		    }

		  xmitcsum += hex (ch);

		  /* If the checksums don't match print a warning, and put the
		     negative ack back to the client. Otherwise put a positive ack. */
		  if (checksum != xmitcsum)
		    {
		      fprintf (stderr, "Warning: Bad RSP checksum: Computed "
			       "0x%02x, received 0x%02x\n", checksum, xmitcsum);

					ch = '-';
		      send_rsp_str ((unsigned char *) &ch, 1);	/* Failed checksum */
		    }
		  else
		    {
					ch = '+';
		      send_rsp_str ((unsigned char *) &ch, 1);	/* successful transfer */
		      break;
		    }
		}
    else
		{
		  fprintf (stderr, "Warning: RSP packet overran buffer\n");
		}
  }
  return &buf;				/* Success */
}	/* get_packet () */


/*---------------------------------------------------------------------------*/
/*!Put a single character out onto the client socket

   This should only be called if the client is open, but we check for safety.

   @param[in] c  The character to put out                                    */
/*---------------------------------------------------------------------------*/
static void
send_rsp_str (unsigned char *data, int len)
{
  if (-1 == rsp.client_fd)
    {
      fprintf (stderr, "Warning: Attempt to write '%s' to unopened RSP "
	       "client: Ignored\n", data);
      return;
    }

  /* Write until successful (we retry after interrupts) or catastrophic
     failure. */
  while (1)
    {
      switch (write (rsp.client_fd, data, len))
			{
			case -1:
			  /* Error: only allow interrupts or would block */
			  if ((EAGAIN != errno) && (EINTR != errno))
			    {
			      fprintf (stderr, "Warning: Failed to write to RSP client: "
				       "Closing client connection: %s\n",
				       strerror (errno));
			      rsp_client_close ();
			      return;
			    }
		      
			  break;

			case 0:
			  break;		/* Nothing written! Try again */

			default:
			  return;		/* Success, we can return */
			}
    }
}	/* send_rsp_str () */


/*---------------------------------------------------------------------------*/
/*!Get a single character from the client socket

   This should only be called if the client is open, but we check for safety.

   @return  The character read, or -1 on failure                             */
/*---------------------------------------------------------------------------*/
static int
get_rsp_char ()
{
  if (-1 == rsp.client_fd)
    {
      fprintf (stderr, "Warning: Attempt to read from unopened RSP "
	       "client: Ignored\n");
      return  -1;
    }

  /* Non-blocking read until successful (we retry after interrupts) or
     catastrophic failure. */
  while (1)
    {
      unsigned char  c;

      switch (read (rsp.client_fd, &c, sizeof (c)))
	{
	case -1:
	  /* Error: only allow interrupts */
	  if ((EAGAIN != errno) && (EINTR != errno))
	    {
	      fprintf (stderr, "Warning: Failed to read from RSP client: "
		       "Closing client connection: %s\n",
		       strerror (errno));
	      rsp_client_close ();
	      return  -1;
	    }

	  break;

	case 0:
	  // EOF
	  rsp_client_close ();
	  return  -1;

	default:
	  return  c & 0xff; /* Success, we can return (no sign extend!) */
	}
    }
}	/* get_rsp_char () */

/*---------------------------------------------------------------------------*/
/* !Peek at data coming into server from GDB
   
   Useful for polling for ETX (0x3) chars being sent when GDB wants to
   interrupt
 
   @return the char we peeked, 0 otherwise                                   */
/*---------------------------------------------------------------------------*/
static char 
rsp_peek()
{
  /*
  if (-1 == rsp.client_fd)
    {
      fprintf (stderr, "Warning: Attempt to read from unopened RSP "
	       "client: Ignored\n");
      return  -1;
    }
  */
  char  c;
  int n;
  // Using recv here instead of read becuase we can pass the MSG_PEEK
  // flag, which lets us look at what's on the socket, without actually
  // taking it off

  //if (DEBUG_GDB) 
  //  printf("peeking at GDB socket...\n");
  
  n = recv (rsp.client_fd, &c, sizeof (c), MSG_PEEK);
  
  //if (DEBUG_GDB) 
  //  printf("peeked, got n=%d, c=0x%x\n",n, c);
  
  if (n > 0)
    return c;
  else
    return '\0';

}

/*---------------------------------------------------------------------------*/
/*!Handle an interrupt from GDB

 Detect an interrupt from GDB and stall the processor                        */
/*---------------------------------------------------------------------------*/
static void 
rsp_interrupt()
{
  unsigned char  c;

  if (read (rsp.client_fd, &c, sizeof (c)) <= 0)
    {
      // Had issues, just return
      return;
    }
  
  // Ensure this is a ETX control char (0x3), currently, we only call this
  // function when we've peeked and seen it, otherwise, ignore, return and pray
  // things go back to normal...
  if (c != 0x03)
    {
      printf("Warning: Interrupt character expected but not found on socket.\n");
      return;
    }
  
  // Otherwise, it's an interrupt packet, stall the processor, and upon return
  // to the main handle_rsp() loop, it will inform GDB.

  if (DEBUG_GDB) printf("Interrupt received from GDB. Stalling processor.\n");

  set_stall_state (1);

  // Send a stop reply response, manually set rsp.sigval to TARGET_SIGNAL_NONE
  rsp.sigval = TARGET_SIGNAL_NONE;
  rsp_report_exception();
  rsp.client_waiting = 0;		/* No longer waiting */  

  return;
  
}


/*---------------------------------------------------------------------------*/
/*!"Unescape" RSP binary data

   '#', '$' and '}' are escaped by preceding them by '}' and oring with 0x20.

   This function reverses that, modifying the data in place.

   @param[in] data  The array of bytes to convert
   @para[in]  len   The number of bytes to be converted

   @return  The number of bytes AFTER conversion                             */
/*---------------------------------------------------------------------------*/
static int
rsp_unescape (char *data,
	      int   len)
{
  int  from_off = 0;		/* Offset to source char */
  int  to_off   = 0;		/* Offset to dest char */

  while (from_off < len)
    {
      /* Is it escaped */
      if ( '}' == data[from_off])
			{
			  from_off++;
			  data[to_off] = data[from_off] ^ 0x20;
			}
		  else
			{
			  data[to_off] = data[from_off];
			}

      from_off++;
      to_off++;
    }

  return  to_off;

}	/* rsp_unescape () */


/*---------------------------------------------------------------------------*/
/*!Initialize the matchpoint hash table

   This is an open hash table, so this function clears all the links to
   NULL.                                                                     */
/*---------------------------------------------------------------------------*/
static void
mp_hash_init (void)
{
  int  i;

  for (i = 0; i < MP_HASH_SIZE; i++)
    {
      rsp.mp_hash[i] = NULL;
    }
}	/* mp_hash_init () */


/*---------------------------------------------------------------------------*/
/*!Add an entry to the matchpoint hash table

   Add the entry if it wasn't already there. If it was there do nothing. The
   match just be on type and addr. The instr need not match, since if this is
   a duplicate insertion (perhaps due to a lost packet) they will be
   different.

   @param[in] type   The type of matchpoint
   @param[in] addr   The address of the matchpoint
   @para[in]  instr  The instruction to associate with the address           */
/*---------------------------------------------------------------------------*/
static void
mp_hash_add (enum mp_type type,
	     uint32_t  addr,
	     uint32_t  instr)
{
  int              hv    = addr % MP_HASH_SIZE;
  struct mp_entry *curr;

  /* See if we already have the entry */
  for(curr = rsp.mp_hash[hv]; NULL != curr; curr = curr->next)
  {
    if ((type == curr->type) && (addr == curr->addr))
		{
		  return;		/* We already have the entry */
		}
  }

  /* Insert the new entry at the head of the chain */
  curr = (struct mp_entry*) malloc (sizeof (*curr));

  curr->type  = type;
  curr->addr  = addr;
  curr->instr = instr;
  curr->next  = rsp.mp_hash[hv];

  rsp.mp_hash[hv] = curr;

}	/* mp_hash_add () */


/*---------------------------------------------------------------------------*/
/*!Look up an entry in the matchpoint hash table

   The match must be on type AND addr.

   @param[in] type   The type of matchpoint
   @param[in] addr   The address of the matchpoint

   @return  The entry deleted, or NULL if the entry was not found            */
/*---------------------------------------------------------------------------*/
static struct mp_entry * mp_hash_lookup (enum mp_type type,	uint32_t addr)
{
  int    hv = addr % MP_HASH_SIZE;
  struct mp_entry *curr;

  /* Search */
  for (curr = rsp.mp_hash[hv]; NULL != curr; curr = curr->next)
  {
    if ((type == curr->type) && (addr == curr->addr))
		{
		  return  curr;		/* The entry found */
		}
  }

  /* Not found */
  return  NULL;
      
}	/* mp_hash_lookup () */


/*---------------------------------------------------------------------------*/
/*!Delete an entry from the matchpoint hash table

   If it is there the entry is deleted from the hash table. If it is not
   there, no action is taken. The match must be on type AND addr.

   The usual fun and games tracking the previous entry, so we can delete
   things.

   @note  The deletion DOES NOT free the memory associated with the entry,
          since that is returned. The caller should free the memory when they
          have used the information.

   @param[in] type   The type of matchpoint
   @param[in] addr   The address of the matchpoint

   @return  The entry deleted, or NULL if the entry was not found            */
/*---------------------------------------------------------------------------*/
static struct mp_entry *
mp_hash_delete (enum mp_type       type,
		uint32_t  addr)
{
  int              hv   = addr % MP_HASH_SIZE;
  struct mp_entry *prev = NULL;
  struct mp_entry *curr;

  /* Search */
  for (curr  = rsp.mp_hash[hv]; NULL != curr; curr = curr->next)
    {
      if ((type == curr->type) && (addr == curr->addr))
	{
	  /* Found - delete. Method depends on whether we are the head of
	     chain. */
	  if (NULL == prev)
	    {
	      rsp.mp_hash[hv] = curr->next;
	    }
	  else
	    {
	      prev->next = curr->next;
	    }

	  return  curr;		/* The entry deleted */
	}

      prev = curr;
    }

  /* Not found */
  return  NULL;
      
}	/* mp_hash_delete () */


/*---------------------------------------------------------------------------*/
/*!Utility to give the value of a hex char

   @param[in] ch  A character representing a hexadecimal digit. Done as -1,
                  for consistency with other character routines, which can use
                  -1 as EOF.

   @return  The value of the hex character, or -1 if the character is
            invalid.                                                         */
/*---------------------------------------------------------------------------*/
static int hex (int  c)
{
  return  ((c >= 'a') && (c <= 'f')) ? c - 'a' + 10 :
          ((c >= '0') && (c <= '9')) ? c - '0' :
          ((c >= 'A') && (c <= 'F')) ? c - 'A' + 10 : -1;

}	/* hex () */


/*---------------------------------------------------------------------------*/
/*!Convert a register to a hex digit string

   The supplied 32-bit value is converted to an 8 digit hex string according
   the target endianism. It is null terminated for convenient printing.

   @param[in]  val  The value to convert
   @param[out] p_buf  The buffer for the text string                           */
/*---------------------------------------------------------------------------*/
static void
reg2hex (uint32_t  val, char *p_buf)
{
  int  n;			/* Counter for digits */
	int  nyb_shift;

  for (n = 0; n < 8; n++)
    {
#ifdef WORDSBIGENDIAN
      if(n%2==0){
      	nyb_shift = n * 4 + 4;
			}
			else{
				nyb_shift = n * 4 - 4;
			}
#else
      nyb_shift = 28 - (n * 4);
#endif
      p_buf[n] = hexchars[(val >> nyb_shift) & 0xf];
    }

  p_buf[8] = 0;			/* Useful to terminate as string */

}	/* reg2hex () */


/*---------------------------------------------------------------------------*/
/*!Convert a hex digit string to a register value

   The supplied 8 digit hex string is converted to a 32-bit value according
   the target endianism

   @param[in] p_buf  The buffer with the hex string

   @return  The value to convert                                             */
/*---------------------------------------------------------------------------*/
static uint32_t
hex2reg (char *p_buf)
{
  int                n;		/* Counter for digits */
  uint32_t  val = 0;	/* The result */

  for (n = 0; n < 8; n++)
    {
#ifdef WORDSBIGENDIAN
      int  nyb_shift = n * 4;
#else
      int  nyb_shift = 28 - (n * 4);
#endif
      val |= hex (p_buf[n]) << nyb_shift;
    }

  return val;

}	/* hex2reg () */


/*---------------------------------------------------------------------------*/
/*!Convert an ASCII character string to pairs of hex digits

   Both source and destination are null terminated.

   @param[out] dest  Buffer to store the hex digit pairs (null terminated)
   @param[in]  src   The ASCII string (null terminated)                      */
/*---------------------------------------------------------------------------*/
static void  ascii2hex (char *dest,
			char *src)
{
  int  i;

  /* Step through converting the source string */
  for (i = 0; src[i] != '\0'; i++)
    {
      char  ch = src[i];

      dest[i * 2]     = hexchars[ch >> 4 & 0xf];
      dest[i * 2 + 1] = hexchars[ch      & 0xf];
    }

  dest[i * 2] = '\0';
	
}	/* ascii2hex () */


/*---------------------------------------------------------------------------*/
/*!Convert pairs of hex digits to an ASCII character string

   Both source and destination are null terminated.

   @param[out] dest  The ASCII string (null terminated)
   @param[in]  src   Buffer holding the hex digit pairs (null terminated)    */
/*---------------------------------------------------------------------------*/
static void  hex2ascii (char *dest,
			char *src)
{
  int  i;

  /* Step through convering the source hex digit pairs */
  for (i = 0; src[i * 2] != '\0' && src[i * 2 + 1] != '\0'; i++)
    {
      dest[i] = ((hex (src[i * 2]) & 0xf) << 4) | (hex (src[i * 2 + 1]) & 0xf);
    }

  dest[i] = '\0';

}	/* hex2ascii () */


/*---------------------------------------------------------------------------*/
/*!Set the program counter

   This sets the value in the NPC SPR. Not completely trivial, since this is
   actually cached in cpu_state.pc. Any reset of the NPC also involves
   clearing the delay state and setting the pcnext global.

   Only actually do this if the requested address is different to the current
   NPC (avoids clearing the delay pipe).

   @param[in] addr  The address to use                                       */
/*---------------------------------------------------------------------------*/
static void
set_npc (uint32_t  addr)
{
  
  // First set the chain 
  gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */


  if (addr != get_npc())
  {

    gdb_write_reg(NPC_CPU_REG_ADD, addr);
    
    if (STALLED == stallState)
      {
	if (DEBUG_GDB) printf("set_npc(): New NPC value (0x%08x) written and locally cached \n", addr);
	npcCachedValue = addr;
	npcIsCached = 1;
      }
    else
      {
	if (DEBUG_GDB) printf("set_npc(): New NPC value (0x%08x) written \n", addr);
	npcIsCached = 0;
      }
    

  }
  else
    return;

      
}	/* set_npc () */


//! Read the value of the Next Program Counter (a SPR)

//! Setting the NPC flushes the pipeline, so subsequent reads will return
//! zero until the processor has refilled the pipeline. This will not be
//! happening if the processor is stalled (as it is when GDB had control),
//! so we must cache the NPC. As soon as the processor is unstalled, this
//! cached value becomes invalid.

//! If we are stalled and the value has been cached, use it. If we are stalled
//! and the value has not been cached, cache it (for efficiency) and use
//! it. Otherwise read the corresponding SPR.

//! @return  The value of the NPC
static uint32_t get_npc ()
{
  uint32_t current_npc;

  if (STALLED == stallState)
    {
      if (npcIsCached == 0)
	{
	  err = gdb_set_chain(SC_RISC_DEBUG);
	  err = gdb_read_reg(NPC_CPU_REG_ADD, &npcCachedValue);
	  if(err > 0){
	    printf("Error %d reading NPC\n", err);
	    rsp_client_close ();
	    return 0;
	  }
	  if (DEBUG_GDB) printf("get_npc(): caching newly read NPC value (0x%08x)\n",npcCachedValue);


	  npcIsCached    = 1;
	}
      else
	if (DEBUG_GDB) printf("get_npc(): reading cached NPC value (0x%08x)\n",npcCachedValue);

      return  npcCachedValue;
    }
  else
    {
      err = gdb_read_reg(NPC_CPU_REG_ADD, &current_npc);
      if(err > 0){
	printf("Error %d reading NPC\n", err);
	rsp_client_close ();
	return 0;
      }
      return current_npc;

    }
}	// get_npc ()



/*---------------------------------------------------------------------------*/
/*!Send a packet acknowledging an exception has occurred

   This is only called if there is a client FD to talk to                    */
/*---------------------------------------------------------------------------*/
static void
rsp_report_exception (void)
{
  struct rsp_buf  buffer;

  /* Construct a signal received packet */
  buffer.data[0] = 'S';
  buffer.data[1] = hexchars[rsp.sigval >> 4];
  buffer.data[2] = hexchars[rsp.sigval % 16];
  buffer.data[3] = 0;
  buffer.len     = strlen (buffer.data);

  put_packet (&buffer);

}	/* rsp_report_exception () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP continue request

   Parse the command to see if there is an address. Uses the underlying
   generic continue function, with EXCEPT_NONE.

   @param[in] p_buf  The full continue packet                                  */
/*---------------------------------------------------------------------------*/
static void
rsp_continue (struct rsp_buf *p_buf)
{
  uint32_t  addr;		/* Address to continue from, if any */

  // First set the chain 
  err = gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */
  
  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();

  if(err > 0){
    printf("Error %d to set RISC Debug Interface chain in the CONTINUE command 'c'\n", err);
    rsp_client_close ();
    return;
  }

  if (0 == strcmp ("c", p_buf->data))
  {
    // Arc Sim Code -->   addr = cpu_state.pc;	/* Default uses current NPC */
    /* ---------- NPC ---------- */
    addr = get_npc();
  }
  else if (1 != sscanf (p_buf->data, "c%x", &addr))
  {
    fprintf (stderr,
       "Warning: RSP continue address %s not recognized: ignored\n",
       p_buf->data);

    // Arc Sim Code -->   addr = cpu_state.pc;	/* Default uses current NPC */
    /* ---------- NPC ---------- */
    addr = get_npc();
  }

  if (DEBUG_GDB) printf("rsp_continue() --> Read NPC = 0x%08x\n", addr);

  rsp_continue_generic (addr, EXCEPT_NONE);

}	/* rsp_continue () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP continue with signal request

   Currently null. Will use the underlying generic continue function.

   @param[in] p_buf  The full continue with signal packet                      */
/*---------------------------------------------------------------------------*/
static void
rsp_continue_with_signal (struct rsp_buf *p_buf)
{
  printf ("RSP continue with signal '%s' received\n", p_buf->data);

}	/* rsp_continue_with_signal () */


/*---------------------------------------------------------------------------*/
/*!Generic processing of a continue request

   The signal may be EXCEPT_NONE if there is no exception to be
   handled. Currently the exception is ignored.

   The single step flag is cleared in the debug registers and then the
   processor is unstalled.

   @param[in] addr    Address from which to step
   @param[in] except  The exception to use (if any)                          */
/*---------------------------------------------------------------------------*/
static void
rsp_continue_generic (uint32_t  addr,
		      uint32_t  except)
{
  uint32_t		temp_uint32;
  
  /* Set the address as the value of the next program counter */
  set_npc (addr);
  
  /* Clear Debug Reason Register (DRR) 0x3015 */
  // Arc sim --> cpu_state.sprs[SPR_DRR]   = 0;
  if(gdb_write_reg(DRR_CPU_REG_ADD, 0)) printf("Error write to DRR register\n");  
  
  /* Clear watchpoint break generation in Debug Mode Register 2	(DMR2) 0x3011 */
  // Arc sim --> cpu_state.sprs[SPR_DMR2] &= ~SPR_DMR2_WGB;
  if(gdb_read_reg(DMR2_CPU_REG_ADD, &temp_uint32)) printf("Error read from DMR2 register\n");
  temp_uint32 &= ~SPR_DMR2_WGB;
  if(gdb_write_reg(DMR2_CPU_REG_ADD, temp_uint32)) printf("Error write to DMR2 register\n");  
  
  /* Clear the single step trigger in Debug Mode Register 1 (DMR1) Register 0x3010 */
  // Arc sim --> cpu_state.sprs[SPR_DMR1] &= ~SPR_DMR1_ST;
  if(gdb_read_reg(DMR1_CPU_REG_ADD, &temp_uint32)) printf("Error read from DMR1 register\n");
  temp_uint32 &= ~SPR_DMR1_ST;
  if(gdb_write_reg(DMR1_CPU_REG_ADD, temp_uint32)) printf("Error write to DMR1 register\n");  
  
  /* Set traps to be handled by the debug unit in the Debug Stop Register (DSR) Register 0x3014 */
  // Arc sim --> cpu_state.sprs[SPR_DSR]  |= SPR_DSR_TE;
  if(gdb_read_reg(DSR_CPU_REG_ADD, &temp_uint32)) printf("Error read from DSR register\n");
  temp_uint32 |= SPR_DSR_TE;
  if(gdb_write_reg(DSR_CPU_REG_ADD, temp_uint32)) printf("Error write to DSR register\n");  

  /* Unstall the processor */
  set_stall_state (0);

  /* Note the GDB client is now waiting for a reply. */
  rsp.client_waiting = 1;

}	/* rsp_continue_generic () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP read all registers request

   The registers follow the GDB sequence for OR1K: GPR0 through GPR31, PPC
   (i.e. SPR PPC), NPC (i.e. SPR NPC) and SR (i.e. SPR SR). Each register is
   returned as a sequence of bytes in target endian order.

   Each byte is packed as a pair of hex digits.                              */
/*---------------------------------------------------------------------------*/
static void
rsp_read_all_regs (void)
{
  struct rsp_buf  buffer;			/* Buffer for the reply */
  int             r;			  	/* Register index */
  uint32_t   temp_uint32;
  
  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();
  
  // First set the chain 
  gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */
  
  
  // Read all GPRs
  for (r = 0; r < MAX_GPRS; r++){
    
    err = gdb_read_reg(0x400 + r, &temp_uint32);
    if(err > 0){
      if (DEBUG_GDB) printf("Error %d in gdb_read_reg at reg. %d\n", err, r);
      put_str_packet ("E01");
      return;
    }
    reg2hex (temp_uint32, &(buffer.data[r * 8]));
    
    if (DEBUG_GDB_DUMP_DATA){
      switch(r % 4)
	{
	case 0:	 
	  printf("gpr%02d   0x%08x  ", r, temp_uint32);
	  break;
	case 1:	 
	case 2:
	  printf("0x%08x  ", temp_uint32);	 
	  break;
	case 3:	 
	  printf("0x%08x\n", temp_uint32);
	  break;
	default:
	  break;
	}
    }
    
  }
  /* ---------- PPC ---------- */
  err = gdb_read_reg(PPC_CPU_REG_ADD, &temp_uint32);
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in gdb_read_reg read --> PPC\n", err);
  	put_str_packet ("E01");
  	return;
  }
  reg2hex (temp_uint32, &(buffer.data[PPC_REGNUM * 8]));
  if (DEBUG_GDB_DUMP_DATA)	printf("PPC     0x%08x\n", temp_uint32);
  /* ---------- NPC ---------- */
  temp_uint32 = get_npc();
  /*
  err = gdb_read_reg(NPC_CPU_REG_ADD, &temp_uint32);
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in gdb_read_reg read --> NPC\n", err);
  	put_str_packet ("E01");
  	return;
  }
  */
  reg2hex (temp_uint32, &(buffer.data[NPC_REGNUM * 8]));
  if (DEBUG_GDB_DUMP_DATA)	printf("NPC     0x%08x\n", temp_uint32);
  /* ---------- SR ---------- */
  err = gdb_read_reg(SR_CPU_REG_ADD, &temp_uint32);
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in gdb_read_reg read --> SP\n", err);
  	put_str_packet ("E01");
  	return;
  }
  reg2hex (temp_uint32, &(buffer.data[SR_REGNUM * 8]));
	if (DEBUG_GDB_DUMP_DATA)	printf("SR      0x%08x\n", temp_uint32);

  /* Finalize the packet and send it */
  buffer.data[NUM_REGS * 8] = 0;
  buffer.len                = NUM_REGS * 8;

  put_packet (&buffer);
	return;
}	/* rsp_read_all_regs () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP write all registers request

   The registers follow the GDB sequence for OR1K: GPR0 through GPR31, PPC
   (i.e. SPR PPC), NPC (i.e. SPR NPC) and SR (i.e. SPR SR). Each register is
   supplied as a sequence of bytes in target endian order.

   Each byte is packed as a pair of hex digits.

   @todo There is no error checking at present. Non-hex chars will generate a
         warning message, but there is no other check that the right amount
         of data is present. The result is always "OK".

   @param[in] p_buf  The original packet request.                              */
/*---------------------------------------------------------------------------*/
static void
rsp_write_all_regs (struct rsp_buf *p_buf)
{
  uint32_t  regnum;				/* Register index */
  // char          valstr[9];		/* Allow for EOS on the string */

  // /* Check for valid data */
  // if (0 != (strcmp ("G", p_buf->data)) && (GDB_BUF_MAX != strlen(p_buf->data)))
  // {
  //   fprintf (stderr, "Warning: Failed to recognize RSP write register "
  //      "command: %s\n", p_buf->data);
  //   // put_str_packet ("E01");
  //   return;
  // }
  
  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();

  // First set the chain 
  err = gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in gdb_set_chain\n", err);
    put_str_packet ("E01");
  	return;
	}

  /* ---------- GPRS ---------- */
  for (regnum = 0; regnum < MAX_GPRS; regnum++)
  {
    err = gdb_write_reg(0x400 + regnum, hex2reg (&p_buf->data[regnum * 8 + 1]));
	  if(err > 0){
	  	if (DEBUG_GDB) printf("Error %d in rsp_write_reg write --> GPRS\n", err);
	    put_str_packet ("E01");
	  	return;
	  }
  }																	 
  
  /* ---------- PPC ---------- */
  err = gdb_write_reg(PPC_CPU_REG_ADD, hex2reg (&p_buf->data[PPC_REGNUM * 8 + 1]));
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in rsp_write_reg write --> PPC\n", err);
    put_str_packet ("E01");
  	return;
  }
  /* ---------- SR ---------- */
  err = gdb_write_reg(SR_CPU_REG_ADD, hex2reg (&p_buf->data[SR_REGNUM * 8 + 1]));
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in rsp_write_reg write --> SR\n", err);
    put_str_packet ("E01");
  	return;
  }
  /* ---------- NPC ---------- */
  set_npc(hex2reg (&p_buf->data[NPC_REGNUM * 8 + 1]));
  /*
  err = gdb_write_reg(NPC_CPU_REG_ADD, hex2reg (&p_buf->data[NPC_REGNUM * 8 + 1]));
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in rsp_write_reg write --> NPC\n", err);
    put_str_packet ("E01");
  	return;
  }
  */
  /* Acknowledge. TODO: We always succeed at present, even if the data was
     defective. */
  put_str_packet ("OK");
}	/* rsp_write_all_regs () */


/*---------------------------------------------------------------------------*/
/* Handle a RSP read memory (symbolic) request

   Syntax is:

     m<addr>,<length>:

   The response is the bytes, lowest address first, encoded as pairs of hex
   digits.

   The length given is the number of bytes to be read.

   @note This function reuses p_buf, so trashes the original command.

   @param[in] p_buf  The command received                                      */
/*---------------------------------------------------------------------------*/
static void rsp_read_mem (struct rsp_buf *p_buf)
{
  unsigned int    addr;			/* Where to read the memory */
  int             len;			/* Number of bytes to read */
  int             off;			/* Offset into the memory */
	uint32_t		temp_uint32 = 0;
  char 						*rec_buf;


  if (2 != sscanf (p_buf->data, "m%x,%x:", &addr, &len))
  {
    fprintf (stderr, "Warning: Failed to recognize RSP read memory "
       "command: %s\n", p_buf->data);
    put_str_packet ("E01");
    return;
  }

  /* Make sure we won't overflow the buffer (2 chars per byte) */
  if ((len * 2) >= GDB_BUF_MAX)
  {
    fprintf (stderr, "Warning: Memory read %s too large for RSP packet: "
       "truncated\n", p_buf->data);
    len = (GDB_BUF_MAX - 1) / 2;
	}

  if(!(rec_buf = (char*)malloc(len))) {
    put_str_packet ("E01");
    ProtocolClean(0, JTAG_PROXY_OUT_OF_MEMORY);
    return;
  }

  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();

  // Set chain 5 --> Wishbone Memory chain
  err = gdb_set_chain(SC_WISHBONE);
  if(err){
  	if (DEBUG_GDB) printf("Error %d in gdb_set_chain\n", err);
  	put_str_packet ("E01");
    return;
	}

  // Read the data from Wishbone Memory chain
  err = gdb_read_block(addr, (uint32_t*)rec_buf, len); 
  if(err){
  	put_str_packet ("E01");
		return;
	}

  /* Refill the buffer with the reply */
  for( off = 0 ; off < len ; off ++ ) {
		;
		temp_uint32 = (temp_uint32 << 8) | (0x000000ff & *(rec_buf + off));
		
		if((off %4 ) == 3){
			temp_uint32 = htonl(temp_uint32);
			reg2hex (temp_uint32, &(p_buf->data[off * 2 - 6]));
		}
		if (DEBUG_GDB_BLOCK_DATA){
		  switch(off % 16)
			{
				case 3:	 
					printf("Add 0x%08x   Data 0x%08x  ", addr + off - 3, temp_uint32);
					break;
				case 7:	 
				case 11:
					printf("0x%08x  ", temp_uint32);	 
					break;
				case 15:	 
					printf("0x%08x\n", temp_uint32);
					break;
				default:
					break;
			}
			if ((len - off == 1) && (off % 16) < 15) printf("\n");
		}
  }
  
  if (DEBUG_GDB && (err > 0)) printf("\nError %x\n", err);fflush (stdout);
	free(rec_buf);
  p_buf->data[off * 2] = 0;			/* End of string */
  p_buf->len           = strlen (p_buf->data);
  put_packet (p_buf);
}	/* rsp_read_mem () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP write memory (symbolic) request	 ("M")

   Syntax is:

     M<addr>,<length>:<data>

  	Example: M4015cc,2:c320# 
	  (Write the value 0xc320 to address 0x4015cc.) 

		An example target response: 
		+ $OK# 

   The data is the bytes, lowest address first, encoded as pairs of hex
   digits.

   The length given is the number of bytes to be written.

   @note This function reuses p_buf, so trashes the original command.

   @param[in] p_buf  The command received                                      */
/*---------------------------------------------------------------------------*/
static void
rsp_write_mem (struct rsp_buf *p_buf)
{
  unsigned int    addr;			/* Where to write the memory */
  int             len;			/* Number of bytes to write */
  char           *symdat;		/* Pointer to the symboli data */
  int             datlen;		/* Number of digits in symbolic data */
  int             off;			/* Offset into the memory */
  int             nibc;			/* Nibbel counter */
	uint32_t   val;
  
  if (2 != sscanf (p_buf->data, "M%x,%x:", &addr, &len))
  {
    fprintf (stderr, "Warning: Failed to recognize RSP write memory "
       "command: %s\n", p_buf->data);
    put_str_packet ("E01");
    return;
  }

  /* Find the start of the data and check there is the amount we expect. */
  symdat = (char*) memchr ((const void *)p_buf->data, ':', GDB_BUF_MAX) + 1;
  datlen = p_buf->len - (symdat - p_buf->data);

  /* Sanity check */
  if (len * 2 != datlen)
  {
    fprintf (stderr, "Warning: Write of %d digits requested, but %d digits "
       "supplied: packet ignored\n", len * 2, datlen );
    put_str_packet ("E01");
    return;
  }

  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();


  // Set chain 5 --> Wishbone Memory chain
  err = gdb_set_chain(SC_WISHBONE);
	if(err){
    put_str_packet ("E01");
    return;
	}
		
	val = 0;
	off = 0;
  /* Write the bytes to memory */
  for (nibc = 0; nibc < datlen; nibc++)
  {
		val |= 0x0000000f & hex (symdat[nibc]);
		if(nibc % 8 == 7){
			err = gdb_write_block(addr + off, &val, 4);
			if (DEBUG_GDB) printf("Error %x\n", err);fflush (stdout);
			if(err){
				put_str_packet ("E01");
				return;
			}
		  val = 0;
			off += 4;
		}	  
	  val <<= 4;
  }
  put_str_packet ("OK");
}	/* rsp_write_mem () */


/*---------------------------------------------------------------------------*/
/*!Read a single register

   The registers follow the GDB sequence for OR1K: GPR0 through GPR31, PC
   (i.e. SPR NPC) and SR (i.e. SPR SR). The register is returned as a
   sequence of bytes in target endian order.

   Each byte is packed as a pair of hex digits.

   @param[in] p_buf  The original packet request. Reused for the reply.        */
/*---------------------------------------------------------------------------*/
static void
rsp_read_reg (struct rsp_buf *p_buf)
{
  unsigned int  	regnum;
	uint32_t 	temp_uint32;

  /* Break out the fields from the data */
  if (1 != sscanf (p_buf->data, "p%x", &regnum))
    {
      fprintf (stderr, "Warning: Failed to recognize RSP read register "
	       "command: %s\n", p_buf->data);
      put_str_packet ("E01");
      return;
    }

  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();

  // First set the chain 
  err = gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in gdb_set_chain\n", err);
    put_str_packet ("E01");
  	return;
	}

  /* Get the relevant register */
  if (regnum < MAX_GPRS)
    {
		  err = gdb_read_reg(0x400 + regnum, &temp_uint32);
		  if(err > 0){
		  	if (DEBUG_GDB) printf("Error %d in rsp_read_reg at reg. %d \n", err, regnum);
		    put_str_packet ("E01");
		  	return;
		  }
		  reg2hex (temp_uint32, p_buf->data);
    }
  else if (PPC_REGNUM == regnum)	/* ---------- PPC ---------- */
    {
		  err = gdb_read_reg(PPC_CPU_REG_ADD, &temp_uint32);
		  if(err > 0){
		  	if (DEBUG_GDB) printf("Error %d in rsp_read_reg read --> PPC\n", err);
		    put_str_packet ("E01");
		  	return;
		  }
		  reg2hex (temp_uint32, p_buf->data);
    }
  else if (NPC_REGNUM == regnum)	/* ---------- NPC ---------- */
    {
      temp_uint32 = get_npc();
      /*
      err = gdb_read_reg(NPC_CPU_REG_ADD, &temp_uint32);
      if(err > 0){
	if (DEBUG_GDB) printf("Error %d in rsp_read_reg read --> PPC\n", err);
	put_str_packet ("E01");
	return;
      }
      */
      reg2hex (temp_uint32, p_buf->data);
    }
  else if (SR_REGNUM == regnum)		/* ---------- SR ---------- */
    {
      err = gdb_read_reg(SR_CPU_REG_ADD, &temp_uint32);
      if(err > 0){
	if (DEBUG_GDB) printf("Error %d in rsp_read_reg read --> PPC\n", err);
	put_str_packet ("E01");
	return;
      }
      reg2hex (temp_uint32, p_buf->data);
    }
  else
    {
      /* Error response if we don't know the register */
      fprintf (stderr, "Warning: Attempt to read unknown register 0x%x: "
	       "ignored\n", regnum);
      put_str_packet ("E01");
      return;
    }

  p_buf->len = strlen (p_buf->data);
  put_packet (p_buf);

}	/* rsp_read_reg () */

    
/*---------------------------------------------------------------------------*/
/*!Write a single register

   The registers follow the GDB sequence for OR1K: GPR0 through GPR31, PC
   (i.e. SPR NPC) and SR (i.e. SPR SR). The register is specified as a
   sequence of bytes in target endian order.

   Each byte is packed as a pair of hex digits.

   @param[in] p_buf  The original packet request.                              */
/*---------------------------------------------------------------------------*/
static void
rsp_write_reg (struct rsp_buf *p_buf)
{
  unsigned int  regnum;
  char          valstr[9];		/* Allow for EOS on the string */
	// int           err = 0;

  /* Break out the fields from the data */
  if (2 != sscanf (p_buf->data, "P%x=%8s", &regnum, valstr))
    {
      fprintf (stderr, "Warning: Failed to recognize RSP write register "
	       "command: %s\n", p_buf->data);
      put_str_packet ("E01");
      return;
    }

  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();
  
  // First set the chain 
  err = gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in gdb_set_chain\n", err);
    put_str_packet ("E01");
  	return;
	}

  /* Set the relevant register */
  if (regnum < MAX_GPRS)				 /* ---------- GPRS ---------- */
		{
      err = gdb_write_reg(0x400 + regnum, hex2reg (valstr));
		  if(err > 0){
		  	if (DEBUG_GDB) printf("Error %d in rsp_write_reg write --> GPRS\n", err);
		    put_str_packet ("E01");
		  	return;
		  }
    }
  else if (PPC_REGNUM == regnum) /* ---------- PPC ---------- */
    {
      err = gdb_write_reg(PPC_CPU_REG_ADD, hex2reg (valstr));
		  if(err > 0){
		  	if (DEBUG_GDB) printf("Error %d in rsp_write_reg write --> PPC\n", err);
		    put_str_packet ("E01");
		  	return;
		  }
    }
  else if (NPC_REGNUM == regnum) /* ---------- NPC ---------- */
    {
      set_npc(hex2reg (valstr));
      /*
      err = gdb_write_reg(NPC_CPU_REG_ADD, hex2reg (valstr));
      if(err > 0){
	if (DEBUG_GDB) printf("Error %d in rsp_write_reg write --> NPC\n", err);
	put_str_packet ("E01");
	return;
      }
      */
    }
  else if (SR_REGNUM == regnum)	 /* ---------- SR ---------- */
    {
      err = gdb_write_reg(SR_CPU_REG_ADD, hex2reg (valstr));
		  if(err > 0){
		  	if (DEBUG_GDB) printf("Error %d in rsp_write_reg write --> SR\n", err);
		    put_str_packet ("E01");
		  	return;
		  }
    }
  else
    {
      /* Error response if we don't know the register */
      fprintf (stderr, "Warning: Attempt to write unknown register 0x%x: "
	       "ignored\n", regnum);
      put_str_packet ("E01");
      return;
    }

  put_str_packet ("OK");

}	/* rsp_write_reg () */

    
/*---------------------------------------------------------------------------*/
/*!Handle a RSP query request

   @param[in] p_buf  The request                                               */
/*---------------------------------------------------------------------------*/
static void
rsp_query (struct rsp_buf *p_buf)
{
  if (0 == strcmp ("qC", p_buf->data))
    {
      /* Return the current thread ID (unsigned hex). A null response
	 indicates to use the previously selected thread. Since we do not
	 support a thread concept, this is the appropriate response. */
      put_str_packet ("");
    }
  else if (0 == strncmp ("qCRC", p_buf->data, strlen ("qCRC")))
    {
      /* Return CRC of memory area */
      fprintf (stderr, "Warning: RSP CRC query not supported\n");
      put_str_packet ("E01");
    }
  else if (0 == strcmp ("qfThreadInfo", p_buf->data))
    {
      /* Return info about active threads. We return just '-1' */
      put_str_packet ("m-1");
    }
  else if (0 == strcmp ("qsThreadInfo", p_buf->data))
    {
      /* Return info about more active threads. We have no more, so return the
	 end of list marker, 'l' */
      put_str_packet ("l");
    }
  else if (0 == strncmp ("qGetTLSAddr:", p_buf->data, strlen ("qGetTLSAddr:")))
    {
      /* We don't support this feature */
      put_str_packet ("");
    }
  else if (0 == strncmp ("qL", p_buf->data, strlen ("qL")))
    {
      /* Deprecated and replaced by 'qfThreadInfo' */
      fprintf (stderr, "Warning: RSP qL deprecated: no info returned\n");
      put_str_packet ("qM001");
    }
  else if (0 == strcmp ("qOffsets", p_buf->data))
    {
      /* Report any relocation */
      put_str_packet ("Text=0;Data=0;Bss=0");
    }
  else if (0 == strncmp ("qP", p_buf->data, strlen ("qP")))
    {
      /* Deprecated and replaced by 'qThreadExtraInfo' */
      fprintf (stderr, "Warning: RSP qP deprecated: no info returned\n");
      put_str_packet ("");
    }
  else if (0 == strncmp ("qRcmd,", p_buf->data, strlen ("qRcmd,")))
    {
      /* This is used to interface to commands to do "stuff" */
      rsp_command (p_buf);
    }
  else if (0 == strncmp ("qSupported", p_buf->data, strlen ("qSupported")))
    {
      /* Report a list of the features we support. For now we just ignore any
				 supplied specific feature queries, but in the future these may be
				 supported as well. Note that the packet size allows for 'G' + all the
				 registers sent to us, or a reply to 'g' with all the registers and an
				 EOS so the buffer is a well formed string. */
      setup_or32();	// setup cpu
      char  reply[GDB_BUF_MAX];
      sprintf (reply, "PacketSize=%x", GDB_BUF_MAX);
      put_str_packet (reply);
    }
  else if (0 == strncmp ("qSymbol:", p_buf->data, strlen ("qSymbol:")))
    {
      /* Offer to look up symbols. Nothing we want (for now). TODO. This just
	 ignores any replies to symbols we looked up, but we didn't want to
	 do that anyway! */
      put_str_packet ("OK");
    }
  else if (0 == strncmp ("qThreadExtraInfo,", p_buf->data,
			 strlen ("qThreadExtraInfo,")))
    {
      /* Report that we are runnable, but the text must be hex ASCI
	 digits. For now do this by steam, reusing the original packet */
      sprintf (p_buf->data, "%02x%02x%02x%02x%02x%02x%02x%02x%02x",
	       'R', 'u', 'n', 'n', 'a', 'b', 'l', 'e', 0);
      p_buf->len = strlen (p_buf->data);
      put_packet (p_buf);
    }
  else if (0 == strncmp ("qXfer:", p_buf->data, strlen ("qXfer:")))
    {
      /* For now we support no 'qXfer' requests, but these should not be
	 expected, since they were not reported by 'qSupported' */
      fprintf (stderr, "Warning: RSP 'qXfer' not supported: ignored\n");
      put_str_packet ("");
    }
  else
    {
      fprintf (stderr, "Unrecognized RSP query: ignored\n");
    }
}	/* rsp_query () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP qRcmd request

  The actual command follows the "qRcmd," in ASCII encoded to hex

   @param[in] p_buf  The request in full                                       */
/*---------------------------------------------------------------------------*/
static void
rsp_command (struct rsp_buf *p_buf)
{
  char  cmd[GDB_BUF_MAX];
  unsigned int      regno;
  uint32_t 		temp_uint32;

  hex2ascii (cmd, &(p_buf->data[strlen ("qRcmd,")]));

  /* Work out which command it is */
  if (0 == strncmp ("readspr ", cmd, strlen ("readspr")))
  {
    /* Parse and return error if we fail */
    if( 1 != sscanf (cmd, "readspr %4x", &regno))
      {
	fprintf (stderr, "Warning: qRcmd %s not recognized: ignored\n", cmd);
	put_str_packet ("E01");
	return;
      }
    
    /* SPR out of range */
    if (regno > MAX_SPRS)
      {
	fprintf (stderr, "Warning: qRcmd readspr %x too large: ignored\n",
		 regno);
	put_str_packet ("E01");
	return;
      }
    
    /* Construct the reply */										
    
    // Make sure the processor is stalled
    gdb_ensure_or1k_stalled();

    // First set the chain 
    gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */
    
    // special case for NPC
    if(regno == NPC_CPU_REG_ADD)
      temp_uint32 = get_npc();
    else
      {
	err = gdb_read_reg(regno, &temp_uint32);
	if(err > 0){
	  if (DEBUG_GDB) printf("Error %d in rsp_command at reg. %x \n", err, regno);
	}										
	else{
	  reg2hex (temp_uint32, cmd);
	  if (DEBUG_GDB) printf("Error %d Command readspr Read reg. %x = 0x%08x\n", err, regno, temp_uint32);
	}
      }
    
    // pack the result into the buffer to send back
    sprintf (cmd, "%8x", (unsigned int)temp_uint32);
    ascii2hex (p_buf->data, cmd);
    p_buf->len = strlen (p_buf->data);
    put_packet (p_buf);
  }
  else if (0 == strncmp ("writespr ", cmd, strlen ("writespr")))
    {
      unsigned int       regno;
      uint32_t  val;
      
      /* Parse and return error if we fail */
      if( 2 != sscanf (cmd, "writespr %4x %8x", &regno, &val))
	{
	  fprintf (stderr, "Warning: qRcmd %s not recognized: ignored\n",
		   cmd);
	  put_str_packet ("E01");
	  return;
	}
      
      /* SPR out of range */
      if (regno > MAX_SPRS)
	{
	  fprintf (stderr, "Warning: qRcmd writespr %x too large: ignored\n",
		   regno);
	  put_str_packet ("E01");
	  return;
	}

      // Make sure the processor is stalled
      gdb_ensure_or1k_stalled();

      // First set the chain 
      gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */
      
      /* set the relevant register */
      // special case for NPC
      if(regno == NPC_CPU_REG_ADD)
	set_npc(val);
      else
	{
	  
	  err = gdb_write_reg(regno, val);
	  if(err > 0){
	    if (DEBUG_GDB) printf("Error %d in rsp_command write Reg. %x = 0x%08x\n", err, regno, val);
	    put_str_packet ("E01");
	    return;
	  }
	  else{
	    if (DEBUG_GDB) printf("Error %d Command writespr Write reg. %x = 0x%08x\n", err, regno, val);
	  }
	}
      put_str_packet ("OK");
    }
}	/* rsp_command () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP set request

   @param[in] p_buf  The request                                               */
/*---------------------------------------------------------------------------*/
static void
rsp_set (struct rsp_buf *p_buf)
{
  if (0 == strncmp ("QPassSignals:", p_buf->data, strlen ("QPassSignals:")))
    {
      /* Passing signals not supported */
      put_str_packet ("");
    }
  else if ((0 == strncmp ("QTDP",    p_buf->data, strlen ("QTDP")))   ||
	   (0 == strncmp ("QFrame",  p_buf->data, strlen ("QFrame"))) ||
	   (0 == strcmp  ("QTStart", p_buf->data))                    ||
	   (0 == strcmp  ("QTStop",  p_buf->data))                    ||
	   (0 == strcmp  ("QTinit",  p_buf->data))                    ||
	   (0 == strncmp ("QTro",    p_buf->data, strlen ("QTro"))))
    {
      /* All tracepoint features are not supported. This reply is really only
	 needed to 'QTDP', since with that the others should not be
	 generated. */
      put_str_packet ("");
    }
  else
    {
      fprintf (stderr, "Unrecognized RSP set request: ignored\n");
    }
}	/* rsp_set () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP restart request

   For now we just put the program counter back to the one used with the last
   vRun request. There is no point in unstalling the processor, since we'll
   never get control back.                                                   */
/*---------------------------------------------------------------------------*/
static void
rsp_restart (void)
{
  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();

  // First set the chain 
  err = gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in gdb_set_chain\n", err);
    put_str_packet ("E01");
  	return;
	}
	// OR32 Arc sim equivalent --> set_npc (rsp.start_addr);
  /* Set NPC to reset vector 0x100 */
  set_npc(rsp.start_addr);
  /*
  err = gdb_write_reg(NPC_CPU_REG_ADD, rsp.start_addr);
  if(err > 0){
  	if (DEBUG_GDB) printf("Error %d in rsp_restart write Reg. %x = 0x%08x\n", err, NPC_CPU_REG_ADD, rsp.start_addr);
    put_str_packet ("E01");
  	return;
  }
  
  else{
  if (DEBUG_GDB) printf("Error %d Command Reset. Set NPC to Start vector %x = 0x%08x\n", err, NPC_CPU_REG_ADD, rsp.start_addr);
  }
  */
}	/* rsp_restart () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP step request

   Parse the command to see if there is an address. Uses the underlying
   generic step function, with EXCEPT_NONE.

   @param[in] p_buf  The full step packet                          */
/*---------------------------------------------------------------------------*/
static void
rsp_step (struct rsp_buf *p_buf)
{
  uint32_t  addr;		/* The address to step from, if any */

  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();

  // First set the chain 
  err = gdb_set_chain(SC_RISC_DEBUG);	/* 1 RISC Debug Interface chain */
  if(err > 0){
  	printf("Error %d to set RISC Debug Interface chain in the STEP command 's'\n", err);
    rsp_client_close ();
    return;
	}

  if (0 == strcmp ("s", p_buf->data))
  {
    // Arc Sim Code -->   addr = cpu_state.pc;	/* Default uses current NPC */
    /* ---------- Npc ---------- */
    addr = get_npc();
    /*
    err = gdb_read_reg(NPC_CPU_REG_ADD, &addr);
    if(err > 0){
      printf("Error %d to read NPC in the STEP command 's'\n", err);
      rsp_client_close ();
      return;
    }
    */
  }
  else if (1 != sscanf (p_buf->data, "s%x", &addr))
  {
    fprintf (stderr,
	     "Warning: RSP step address %s not recognized: ignored\n",
	     p_buf->data);

    // Arc Sim Code -->   addr = cpu_state.pc;	/* Default uses current NPC */
    /* ---------- NPC ---------- */
    addr = get_npc();
    /*
    err = gdb_read_reg(NPC_CPU_REG_ADD, &addr);
    if(err > 0){
      printf("Error %d to read NPC in the STEP command 's'\n", err);
      rsp_client_close ();
      return;
    }
    */
  }

  //if (DEBUG_GDB) printf("rsp_step() --> Read NPC = 0x%08x\n", addr);
  rsp_step_generic (addr, EXCEPT_NONE);

}	/* rsp_step () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP step with signal request

   Currently null. Will use the underlying generic step function.

   @param[in] p_buf  The full step with signal packet              */
/*---------------------------------------------------------------------------*/
static void
rsp_step_with_signal (struct rsp_buf *p_buf)
{
  printf ("RSP step with signal '%s' received\n", p_buf->data);

}	/* rsp_step_with_signal () */


/*---------------------------------------------------------------------------*/
/*!Generic processing of a step request

   The signal may be EXCEPT_NONE if there is no exception to be
   handled. Currently the exception is ignored.

   The single step flag is set in the debug registers and then the processor
   is unstalled.

   @param[in] addr    Address from which to step
   @param[in] except  The exception to use (if any)                          */
/*---------------------------------------------------------------------------*/
static void
rsp_step_generic (uint32_t  addr,
		  uint32_t  except)
{
  uint32_t		temp_uint32;
  
  /* Set the address as the value of the next program counter */
  
  set_npc (addr);
  
  /* Clear Debug Reason Register (DRR) 0x3015 */
  // Arc sim --> cpu_state.sprs[SPR_DRR]   = 0;
  if(gdb_write_reg(DRR_CPU_REG_ADD, 0)) printf("Error write to DRR register\n");  
  
  /* Clear watchpoint break generation in Debug Mode Register 2	(DMR2) 0x3011 */
  // Arc sim --> cpu_state.sprs[SPR_DMR2] &= ~SPR_DMR2_WGB;
  if(gdb_read_reg(DMR2_CPU_REG_ADD, &temp_uint32)) printf("Error read from DMR2 register\n");
  temp_uint32 &= ~SPR_DMR2_WGB;
  if(gdb_write_reg(DMR2_CPU_REG_ADD, temp_uint32)) printf("Error write to DMR2 register\n");  
  
  /* Set the single step trigger in Debug Mode Register 1 (DMR1) Register 0x3010 */
  // Arc sim --> cpu_state.sprs[SPR_DMR1] |= SPR_DMR1_ST;
  if(gdb_read_reg(DMR1_CPU_REG_ADD, &temp_uint32)) printf("Error read from DMR1 register\n");
  temp_uint32 |= SPR_DMR1_ST;
  if(gdb_write_reg(DMR1_CPU_REG_ADD, temp_uint32)) printf("Error write to DMR1 register\n");  
  
  /* Set traps to be handled by the debug unit in the Debug Stop Register (DSR) Register 0x3014 */
  // Arc sim --> cpu_state.sprs[SPR_DSR]  |= SPR_DSR_TE;
  if(gdb_read_reg(DSR_CPU_REG_ADD, &temp_uint32)) printf("Error read from DSR register\n");
  temp_uint32 |= SPR_DSR_TE;
  if(gdb_write_reg(DSR_CPU_REG_ADD, temp_uint32)) printf("Error write to DSR register\n");  

  /* Unstall the processor */
  set_stall_state (0);

  /* Note the GDB client is now waiting for a reply. */
  rsp.client_waiting = 1;

}	/* rsp_step_generic () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP 'v' packet

   These are commands associated with executing the code on the target

   @param[in] p_buf  The request                                               */
/*---------------------------------------------------------------------------*/
static void
rsp_vpkt (struct rsp_buf *p_buf)
{
  if (0 == strncmp ("vAttach;", p_buf->data, strlen ("vAttach;")))
    {
      /* Attaching is a null action, since we have no other process. We just
	 return a stop packet (using TRAP) to indicate we are stopped. */
      put_str_packet ("S05");
      return;
    }
  else if (0 == strcmp ("vCont?", p_buf->data))
    {
      /* For now we don't support this. */
      put_str_packet ("");
      return;
    }
  else if (0 == strncmp ("vCont", p_buf->data, strlen ("vCont")))
    {
      /* This shouldn't happen, because we've reported non-support via vCont?
	 above */
      fprintf (stderr, "Warning: RSP vCont not supported: ignored\n" );
      return;
    }
  else if (0 == strncmp ("vFile:", p_buf->data, strlen ("vFile:")))
    {
      /* For now we don't support this. */
      fprintf (stderr, "Warning: RSP vFile not supported: ignored\n" );
      put_str_packet ("");
      return;
    }
  else if (0 == strncmp ("vFlashErase:", p_buf->data, strlen ("vFlashErase:")))
    {
      /* For now we don't support this. */
      fprintf (stderr, "Warning: RSP vFlashErase not supported: ignored\n" );
      put_str_packet ("E01");
      return;
    }
  else if (0 == strncmp ("vFlashWrite:", p_buf->data, strlen ("vFlashWrite:")))
    {
      /* For now we don't support this. */
      fprintf (stderr, "Warning: RSP vFlashWrite not supported: ignored\n" );
      put_str_packet ("E01");
      return;
    }
  else if (0 == strcmp ("vFlashDone", p_buf->data))
    {
      /* For now we don't support this. */
      fprintf (stderr, "Warning: RSP vFlashDone not supported: ignored\n" );
      put_str_packet ("E01");
      return;
    }
  else if (0 == strncmp ("vRun;", p_buf->data, strlen ("vRun;")))
    {
      /* We shouldn't be given any args, but check for this */
      if (p_buf->len > (int) strlen ("vRun;"))
	{
	  fprintf (stderr, "Warning: Unexpected arguments to RSP vRun "
		   "command: ignored\n");
	}

      /* Restart the current program. However unlike a "R" packet, "vRun"
	 should behave as though it has just stopped. We use signal
	 5 (TRAP). */
      rsp_restart ();
      put_str_packet ("S05");
    }
  else
    {
      fprintf (stderr, "Warning: Unknown RSP 'v' packet type %s: ignored\n",
	       p_buf->data);
      put_str_packet ("E01");
      return;
    }
}	/* rsp_vpkt () */


/*---------------------------------------------------------------------------*/
/*!Handle a RSP write memory (binary) request

   Syntax is:

     X<addr>,<length>:

   Followed by the specified number of bytes as raw binary. Response should be
   "OK" if all copied OK, E<nn> if error <nn> has occurred.

   The length given is the number of bytes to be written. However the number
   of data bytes may be greater, since '#', '$' and '}' are escaped by
   preceding them by '}' and oring with 0x20.

   @param[in] p_buf  The command received                                      */
/*---------------------------------------------------------------------------*/
static void
rsp_write_mem_bin (struct rsp_buf *p_buf)
{
  unsigned int  addr;			/* Where to write the memory */
  int           len;			/* Number of bytes to write */
  char         	*bindat;	/* Pointer to the binary data */
  int           off = 0;	/* Offset to start of binary data */
  int           newlen;		/* Number of bytes in bin data */

  if (2 != sscanf (p_buf->data, "X%x,%x:", &addr, &len))
    {
      fprintf (stderr, "Warning: Failed to recognize RSP write memory "
	       "command: %s\n", p_buf->data);
      put_str_packet ("E01");
      return;
    }

  /* Find the start of the data and "unescape" it */
  bindat = p_buf->data;
  while(off < GDB_BUF_MAX){
  	if(bindat[off] == ':'){
			bindat = bindat + off + 1;
			off++;
			break;
		}
		off++;
  }
	if(off >= GDB_BUF_MAX){
	  put_str_packet ("E01");
		return;
	}
  
  newlen = rsp_unescape (bindat, p_buf->len - off);

  /* Sanity check */
  if (newlen != len)
  {
    int  minlen = len < newlen ? len : newlen;

    fprintf (stderr, "Warning: Write of %d bytes requested, but %d bytes "
       "supplied. %d will be written\n", len, newlen, minlen);
    len = minlen;
  }

  // Make sure the processor is stalled
  gdb_ensure_or1k_stalled();

  // Set chain 5 --> Wishbone Memory chain
  err = gdb_set_chain(SC_WISHBONE);
  if(err){
    put_str_packet ("E01");
    return;
  }
  
  /* Write the bytes to memory */
  if (len)
    {
      swap_buf(bindat, len);
      
      if (DEBUG_GDB_BLOCK_DATA){
	uint32_t  temp_uint32;
	for (off = 0; off < len; off++){
	  temp_uint32 = (temp_uint32 << 8) | (0x000000ff & bindat[off]);
	  if((off %4 ) == 3){
	    temp_uint32 = htonl(temp_uint32);
	  }
	  switch(off % 16)
	    {
	    case 3:	 
	      printf("Add 0x%08x   Data 0x%08x  ", addr + off - 3, temp_uint32);
	      break;
	    case 7:	 
	    case 11:
	      printf("0x%08x  ", temp_uint32);	 
	      break;
	    case 15:	 
	      printf("0x%08x\n", temp_uint32);
	      break;
	    default:
	      break;
	    }
	  if ((len - off == 1) && (off % 16) < 15) printf("\n");
	}
      }
      
      err = gdb_write_block(addr, (uint32_t*)bindat, len);
      if(err){
	put_str_packet ("E01");
	return;
      }
      if (DEBUG_GDB) printf("Error %x\n", err);fflush (stdout);
    }
  put_str_packet ("OK");
  
}	/* rsp_write_mem_bin () */

      
/*---------------------------------------------------------------------------*/
/*!Handle a RSP remove breakpoint or matchpoint request

   For now only memory breakpoints are implemented, which are implemented by
   substituting a breakpoint at the specified address. The implementation must
   cope with the possibility of duplicate packets.

   @todo This doesn't work with icache/immu yet

   @param[in] p_buf  The command received                                      */
/*---------------------------------------------------------------------------*/
static void
rsp_remove_matchpoint (struct rsp_buf *p_buf)
{
  enum mp_type       type;		/* What sort of matchpoint */
  uint32_t  addr;		/* Address specified */
  int                len;			/* Matchpoint length (not used) */
  struct mp_entry   *mpe;			/* Info about the replaced instr */

  /* Break out the instruction */
  if (3 != sscanf (p_buf->data, "z%1d,%x,%1d", (int *)&type, &addr, &len))
    {
      fprintf (stderr, "Warning: RSP matchpoint deletion request not "
	       "recognized: ignored\n");
      put_str_packet ("E01");
      return;
    }

  /* Sanity check that the length is 4 */
  if (4 != len)
    {
      fprintf (stderr, "Warning: RSP matchpoint deletion length %d not "
	       "valid: 4 assumed\n", len);
      len = 4;
    }

  /* Sort out the type of matchpoint */
  switch (type)
    {
    case BP_MEMORY:
      /* Memory breakpoint - replace the original instruction. */
      mpe = mp_hash_delete (type, addr);

      /* If the BP hasn't yet been deleted, put the original instruction
			 back. Don't forget to free the hash table entry afterwards. */
			if (NULL != mpe)
			{
			  // Arc Sim Code -->   set_program32 (addr, mpe->instr);
			  // Make sure the processor is stalled
			  gdb_ensure_or1k_stalled();

			  // Set chain 5 --> Wishbone Memory chain
			  err = gdb_set_chain(SC_WISHBONE);
				if(err){
					put_str_packet ("E01");
				  return;
				}
				err = gdb_write_block(addr, &mpe->instr, 4);
				if(err){
					put_str_packet ("E01");
				  return;
				}
			  free (mpe);
			}

      put_str_packet ("OK");
      return;
     
    case BP_HARDWARE:
      put_str_packet ("");		/* Not supported */
      return;

    case WP_WRITE:
      put_str_packet ("");		/* Not supported */
      return;

    case WP_READ:
      put_str_packet ("");		/* Not supported */
      return;

    case WP_ACCESS:
      put_str_packet ("");		/* Not supported */
      return;

    default:
      fprintf (stderr, "Warning: RSP matchpoint type %d not "
	       "recognized: ignored\n", type);
      put_str_packet ("E01");
      return;

    }
}	/* rsp_remove_matchpoint () */

      
/*---------------------------------------------------------------------------*/
/*!Handle a RSP insert breakpoint or matchpoint request

   For now only memory breakpoints are implemented, which are implemented by
   substituting a breakpoint at the specified address. The implementation must
   cope with the possibility of duplicate packets.

   @todo This doesn't work with icache/immu yet

   @param[in] p_buf  The command received                                      */
/*---------------------------------------------------------------------------*/
static void
rsp_insert_matchpoint (struct rsp_buf *p_buf)
{
  enum mp_type       type;		/* What sort of matchpoint */
  uint32_t  addr;		/* Address specified */
  int                len;		/* Matchpoint length (not used) */
	uint32_t      instr;

  /* Break out the instruction */
  if (3 != sscanf (p_buf->data, "Z%1d,%x,%1d", (int *)&type, &addr, &len))
    {
      fprintf (stderr, "Warning: RSP matchpoint insertion request not "
	       "recognized: ignored\n");
      put_str_packet ("E01");
      return;
    }

  /* Sanity check that the length is 4 */
  if (4 != len)
    {
      fprintf (stderr, "Warning: RSP matchpoint insertion length %d not "
	       "valid: 4 assumed\n", len);
      len = 4;
    }

  /* Sort out the type of matchpoint */
  switch (type)
    {
    case BP_MEMORY:		// software-breakpoint Z0  break
      /* Memory breakpoint - substitute a TRAP instruction */
      // Make sure the processor is stalled
      gdb_ensure_or1k_stalled();
      
      // Set chain 5 --> Wishbone Memory chain
      gdb_set_chain(SC_WISHBONE);
      
      // Read the data from Wishbone Memory chain
      // Arc Sim Code -->   mp_hash_add (type, addr, eval_direct32 (addr, 0, 0));
      gdb_read_block(addr, &instr, 4); 

      mp_hash_add (type, addr, instr);
      
      // Arc Sim Code -->   set_program32 (addr, OR1K_TRAP_INSTR);
      instr = OR1K_TRAP_INSTR;
      err = gdb_write_block(addr, &instr, 4);
      if(err){
	put_str_packet ("E01");
	return;
      }
      put_str_packet ("OK");
      return;
     
    case BP_HARDWARE:	// hardware-breakpoint Z1  hbreak
      put_str_packet ("");		/* Not supported */
      return;
																														 
    case WP_WRITE:		// write-watchpoint    Z2  watch																			
      put_str_packet ("");		/* Not supported */						 
      return;																								
																														
    case WP_READ:			// read-watchpoint     Z3  rwatch
      put_str_packet ("");		/* Not supported */
      return;

    case WP_ACCESS:		// access-watchpoint   Z4  awatch
      put_str_packet ("");		/* Not supported */
      return;

    default:
      fprintf (stderr, "Warning: RSP matchpoint type %d not "
	       "recognized: ignored\n", type);
      put_str_packet ("E01");
      return;
    }
}	/* rsp_insert_matchpoint () */


/*---------------------------------------------------------------------------
Setup the or32 to init state

---------------------------------------------------------------------------*/
void setup_or32(void)
{
  uint32_t		temp_uint32;
  // First set the chain 
  err = gdb_set_chain(SC_REGISTER);	/* 4 Register Chain */
  if(err > 0){
    if (DEBUG_GDB) printf("Error %d in gdb_set_chain\n", err);
  }
  if(gdb_read_reg(0x04, &temp_uint32)) printf("Error read from register\n");
  if (DEBUG_GDB) printf("Read from chain 4 SC_REGISTER at add 0x00000004 = 0x%08x\n", temp_uint32 );			
  
  if(gdb_write_reg(0x04, 0x00000001)) printf("Error write to register\n");  
  if (DEBUG_GDB) printf("Write to chain 4 SC_REGISTER at add 0x00000004 = 0x00000001\n");			
  
  //	if(gdb_read_reg(0x04, &temp_uint32)) printf("Error read from register\n");
  //	if (DEBUG_GDB) printf("Read from chain 4 SC_REGISTER at add 0x00000004 = 0x%08x\n", temp_uint32 );			
  
  //	if(gdb_read_reg(0x04, &temp_uint32)) printf("Error read from register\n");
  //	if (DEBUG_GDB) printf("Read from chain 4 SC_REGISTER at add 0x00000004 = 0x%08x\n", temp_uint32 );			
  
  if(gdb_write_reg(0x00, 0x01000001)) printf("Error write to register\n");  
  if (DEBUG_GDB) printf("Write to chain 4 SC_REGISTER at add 0x00000000 = 0x01000001\n");			
}

// Function to check if the processor is stalled - if not then stall it.
// this is useful in the event that GDB thinks the processor is stalled, but has, in fact
// been hard reset on the board and is running.
static void gdb_ensure_or1k_stalled()
{
  // Disable continual checking that the or1k is stalled
#ifdef ENABLE_OR1K_STALL_CHECK
  unsigned char stalled;
  dbg_cpu0_read_ctrl(0, &stalled);
  if ((stalled & 0x1) != 0x1)
    {
      if (DEBUG_GDB)
	printf("Processor not stalled, like we thought\n");
      
      // Set the TAP controller to its OR1k chain
      dbg_set_tap_ir(JI_DEBUG);
      gdb_chain = -1;

      // Processor isn't stalled, contrary to what we though, so stall it
      printf("Stalling or1k\n");
      dbg_cpu0_write_ctrl(0, 0x01);      // stall or1k
    }  
#endif
  return;
}


int gdb_read_reg(uint32_t adr, uint32_t *data) {
  switch (gdb_chain) {
  case SC_RISC_DEBUG: return dbg_cpu0_read(adr, data) ? ERR_CRC : ERR_NONE;
  case SC_REGISTER:   return dbg_cpu0_read_ctrl(adr, (unsigned char*)data) ? 
      ERR_CRC : ERR_NONE;
  case SC_WISHBONE:   return dbg_wb_read32(adr, data) ? ERR_CRC : ERR_NONE;
  case SC_TRACE:      *data = 0; return 0;
  default:            return JTAG_PROXY_INVALID_CHAIN;
  }
}

int gdb_write_reg(uint32_t adr, uint32_t data) {
  switch (gdb_chain) { /* remap registers, to be compatible with jp1 */
  case SC_RISC_DEBUG: if (adr == JTAG_RISCOP) adr = 0x00;
    return dbg_cpu0_write(adr, data) ? ERR_CRC : ERR_NONE;
  case SC_REGISTER:   return dbg_cpu0_write_ctrl(adr, data) ? ERR_CRC : ERR_NONE;
  case SC_WISHBONE:   return dbg_wb_write32(adr, data) ? ERR_CRC : ERR_NONE;
  case SC_TRACE:      return 0;
  default:            return JTAG_PROXY_INVALID_CHAIN;
  }
}

int gdb_read_block(uint32_t adr, uint32_t *data, int len) {
  if (DEBUG_CMDS) printf("rb %d\n", gdb_chain);
  switch (gdb_chain) {
  case SC_WISHBONE:   return dbg_wb_read_block32(adr, data, len) ? 
      ERR_CRC : ERR_NONE;
  default:            return JTAG_PROXY_INVALID_CHAIN;
  }
}

int gdb_write_block(uint32_t adr, uint32_t *data, int len) {
  if (DEBUG_CMDS) printf("wb %d\n", gdb_chain);
  switch (gdb_chain) {
  case SC_WISHBONE:   return dbg_wb_write_block32(adr, data, len) ? 
      ERR_CRC : ERR_NONE;
  default:            return JTAG_PROXY_INVALID_CHAIN;
  }
}

int gdb_set_chain(int chain) {
  int rv;
  switch (chain) {
  case SC_RISC_DEBUG:
  case SC_REGISTER:
  case SC_TRACE:      
  case SC_WISHBONE:   gdb_chain = chain;
    rv = ERR_NONE;
    break;
  default:            rv = JTAG_PROXY_INVALID_CHAIN;
    break;
  }
  return rv;
}

/* Added by CZ 24/05/01 */
int GetServerSocket(const char* name, const char* proto, int port) {
  struct servent *service;
  struct protoent *protocol;
  struct sockaddr_in sa;
  struct hostent *hp;  
  int sockfd;
  char myname[256];
  //int flags; --changed to socklen_t for c++?! -- Julius
  socklen_t flags;
  char sTemp[256];

  /* First, get the protocol number of TCP */
  if (!(protocol = getprotobyname(proto))) {
    sprintf(sTemp, "Unable to load protocol \"%s\"", proto);
    perror(sTemp);
    return 0;
  }
  tcp_level = protocol->p_proto; /* Save for later */

  /* If we weren't passed a non standard port, get the port
     from the services directory. */
  if (!port && (service = getservbyname(name, protocol->p_name)))
    port = ntohs(service->s_port);
 
  /* Create the socket using the TCP protocol */
  if ((sockfd = socket(PF_INET, SOCK_STREAM, protocol->p_proto)) < 0) {
    perror("Unable to create socket");
    return 0;
  }
 
  flags = 1;
  if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, 
		 (const char*)&flags, sizeof(int)) < 0) {
    sprintf(sTemp, "Can not set SO_REUSEADDR option on socket %d", sockfd);
    perror(sTemp);
    close(sockfd);
    return 0;
  }

  /* The server should also be non blocking. Get the current flags. */
  if(fcntl(sockfd, F_GETFL, &flags) < 0) {
    sprintf(sTemp, "Unable to get flags for socket %d", sockfd);
    perror(sTemp);
    close(sockfd);
    return 0;
  }

  /* Set the nonblocking flag */
  if(fcntl(sockfd, F_SETFL, flags | O_NONBLOCK) < 0) {
    sprintf(sTemp, "Unable to set flags for socket %d to value 0x%08x", 
                    sockfd, flags | O_NONBLOCK);
    perror(sTemp);
    close(sockfd);
    return 0;
  }

  /* Find out what our address is */
  memset(&sa, 0, sizeof(struct sockaddr_in));
  gethostname(myname, sizeof(myname));
  if(!(hp = gethostbyname(myname))) {
    perror("Unable to read hostname");
    close(sockfd);
    return 0;
  }
 
  /* Bind our socket to the appropriate address */
  sa.sin_family = hp->h_addrtype;
  sa.sin_port = htons(port);
  if(bind(sockfd, (struct sockaddr*)&sa, sizeof(struct sockaddr_in)) < 0) {
    sprintf(sTemp, "Unable to bind socket %d to port %d", sockfd, port);
    perror(sTemp);
    close(sockfd);
    return 0;
  }
  serverIP = sa.sin_addr.s_addr;
  flags = sizeof(struct sockaddr_in);
  if(getsockname(sockfd, (struct sockaddr*)&sa, &flags) < 0) {
    sprintf(sTemp, "Unable to get socket information for socket %d", sockfd);
    perror(sTemp);
    close(sockfd);
    return 0;
  }
  serverPort = ntohs(sa.sin_port);

  /* Set the backlog to 1 connections */
  if(listen(sockfd, 1) < 0) {
    sprintf(sTemp, "Unable to set backlog on socket %d to %d", sockfd, 1);
    perror(sTemp);
    close(sockfd);
    return 0;
  }

  return sockfd;
}

//void HandleServerSocket(Boolean block) {
void HandleServerSocket(void) {
  struct pollfd fds[2];
  int n;
  uint32_t		temp_uint32;

 rebuild:
  n = 0;
  if(!server_fd && !gdb_fd) return;
  
  if(server_fd) {
    fds[n].fd = server_fd;
    fds[n].events = POLLIN;
    fds[n++].revents = 0;
  }
  if(gdb_fd) {
    fds[n].fd = gdb_fd;
    fds[n].events = POLLIN;
    fds[n++].revents = 0;
  }
  
  while(1) {
    switch(poll(fds, n, -1)) {
    case 0:
    case -1:
      if(errno == EINTR) continue;
      perror("poll");
      server_fd = 0;
      return;
    default:
      /* Make sure to handle the gdb port first! */
      if (gdb_fd && ((fds[0].revents && !server_fd) || (fds[1].revents && server_fd)))
	{
	  int revents = server_fd ? fds[1].revents : fds[0].revents;
	  if (revents & POLLIN){
	    /* If we have an unacknowledged exception tell the GDB client. If this
	       exception was a trap due to a memory breakpoint, then adjust the NPC. */
	    if (rsp.client_waiting)
	      {
		err = gdb_read_reg(PPC_CPU_REG_ADD, &temp_uint32);
		if(err) printf("Error read from PPC register\n");
		if ((TARGET_SIGNAL_TRAP == rsp.sigval) &&
		    (NULL != mp_hash_lookup (BP_MEMORY, temp_uint32)))
		  {
		    set_npc (temp_uint32);
		  }
		
		rsp_report_exception();
		rsp.client_waiting = 0;		/* No longer waiting */
	      }
	    GDBRequest();
	  }
	  else {/* Error Occurred */
	    printf("\n%sSocket closed.\n",printTime());
	    //fprintf(stderr, 
	    //"Received flags 0x%08x on gdb socket. Shutting down.\n", revents);
	    close(gdb_fd);
	    gdb_fd = 0;
	  }
	}
      
      // Go to blocking accept() instead of looping around through poll(), 
      // takes a loot of CPU resources and it doesn't work when 
      // reconnecting... Jonas Rosén
      if(!gdb_fd)
      {
			  JTAGRequest();
			  rsp.client_waiting = 0;		/* No longer waiting */
			  goto rebuild;
      }
      
      if(fds[0].revents && server_fd) {
        if(fds[0].revents & POLLIN) {
          JTAGRequest();
          rsp.client_waiting = 0;		/* No longer waiting */
          goto rebuild;
        } else { /* Error Occurred */
			  fprintf(stderr, 
				  "Received flags 0x%08x on server. Shutting down.\n", 
				  fds[0].revents);
			  close(server_fd);
			  server_fd = 0;
			  serverPort = 0;
			  serverIP = 0;
			  return;
				}
  		}
      break;
    } /* End of switch statement */
  } /* End of while statement */
}

void JTAGRequest(void) {
  struct sockaddr_in sa;
  struct sockaddr* addr = (struct sockaddr*)&sa;
  //int n = sizeof(struct sockaddr_in); --changed to socklen_t from int type
  socklen_t n = sizeof(struct sockaddr_in);
  int fd = accept(server_fd, addr, &n);
  int on_off = 0; /* Turn off Nagel's algorithm on the socket */
  int flags;
  char sTemp[256];
  if (DEBUG_GDB) printf("JTAGRequest\n");

  if(fd < 0) {
    /* This is valid, because a connection could have started, 
       and then terminated due to a protocol error or user
       initiation before the accept could take place. */
    if(errno != EWOULDBLOCK && errno != EAGAIN) {
      perror("accept");
      close(server_fd);
      server_fd = 0;
      serverPort = 0;
      serverIP = 0;
    }
    return;
  }

  if(gdb_fd) {
    close(fd);
    return;
  }

  if(fcntl(fd, F_GETFL, &flags) < 0) {
    sprintf(sTemp, "Unable to get flags for gdb socket %d", fd);
    perror(sTemp);
    close(fd);
    return;
  }
  
  /* Rene
  if(fcntl(fd, F_SETFL, flags | O_NONBLOCK) < 0) {
    sprintf(sTemp, "Unable to set flags for gdb socket %d to value 0x%08x", 
      fd, flags | O_NONBLOCK);
    perror(sTemp);
    close(fd);
    return;
  }	Rene */

  if(setsockopt(fd, tcp_level, TCP_NODELAY, &on_off, sizeof(int)) < 0) {
    sprintf(sTemp, "Unable to disable Nagel's algorithm for socket %d.\nsetsockopt", fd);
    perror(sTemp);
    close(fd);
    return;
  }

  printf("\n%sConnection established from %s on port %d\n", printTime(),inet_ntoa(sa.sin_addr),ntohs(sa.sin_port));
  gdb_fd = fd;
}


/*---------------------------------------------------------------------------
* Decode the GDB command.
*
*---------------------------------------------------------------------------*/
static void GDBRequest(void) {
  JTAGProxyWriteMessage msg_write;
  JTAGProxyReadMessage msg_read;
  JTAGProxyChainMessage msg_chain;
  JTAGProxyWriteResponse resp_write;
  JTAGProxyReadResponse resp_read;
  JTAGProxyChainResponse resp_chain;
  JTAGProxyBlockWriteMessage *msg_bwrite;
  JTAGProxyBlockReadMessage msg_bread;
  JTAGProxyBlockWriteResponse resp_bwrite;
  JTAGProxyBlockReadResponse *resp_bread;
  char *p_buf;
  uint32_t command;
  uint32_t length;
  int len, i;

  /* First, we must read the incomming command */
  if(gdb_read(&command, sizeof(uint32_t)) < 0) {
    client_close ('1');
    return;
  }
  command = ntohl(command);

  if(gdb_read(&length, sizeof(uint32_t)) < 0) {
    client_close ('2');
    return;
  }
  length = ntohl(length);
  if (DEBUG_GDB) printf("\n%s-----------------------------------------------------\nCommand %d Length %d ", printTime(), command, length);

  if (DEBUG_GDB){
  switch(command){
    case JTAG_COMMAND_READ:
            printf("JTAG_COMMAND_READ       \n");
            break;
    case JTAG_COMMAND_WRITE:
            printf("JTAG_COMMAND_WRITE      \n");
            break;
    case JTAG_COMMAND_BLOCK_READ:
            printf("JTAG_COMMAND_BLOCK_READ \n");
            break;
    case JTAG_COMMAND_BLOCK_WRITE:
            printf("JTAG_COMMAND_BLOCK_WRITE\n");
            break;
    case JTAG_COMMAND_CHAIN:
            printf("JTAG_COMMAND_CHAIN      \n");
            break;
		}
	}
	
  /* Now, verify the protocol and implement the command */
  switch(command) {
    case JTAG_COMMAND_WRITE:
      if(length != sizeof(msg_write) - 8) {
        ProtocolClean(length, JTAG_PROXY_PROTOCOL_ERROR);
        return;
      }
      p_buf = (char*)&msg_write;
      if(gdb_read(&p_buf[8], length) < 0) {
        client_close ('3');
        return;
      }
      msg_write.address = ntohl(msg_write.address);
      msg_write.data_H = ntohl(msg_write.data_H);
      msg_write.data_L = ntohl(msg_write.data_L);
      err = gdb_write_reg(msg_write.address, msg_write.data_L);      
      resp_write.status = htonl(err);      
      if (DEBUG_GDB) printf("Write Reg to Chain %d at add 0x%08x -> H-Data 0x%08x L-Data 0x%08x Error %d", 
        gdb_chain, msg_write.address, msg_write.data_H, msg_write.data_L, err);fflush (stdout);
      if(gdb_write(&resp_write, sizeof(resp_write)) < 0) {
        client_close ('4');
        return;
      }
      break;
    case JTAG_COMMAND_READ:
      if(length != sizeof(msg_read) - 8) {
        ProtocolClean(length, JTAG_PROXY_PROTOCOL_ERROR);
        return;
      }
      p_buf = (char*)&msg_read;
      if(gdb_read(&p_buf[8], length) < 0) {
        client_close ('5');
        return;
      }
      msg_read.address = ntohl(msg_read.address);
      err = gdb_read_reg(msg_read.address, (uint32_t *)&resp_read.data_L);
      if (DEBUG_GDB) printf("Read Reg from Chain %d at add 0x%08x", gdb_chain, msg_read.address);
      resp_read.status = htonl(err);
      resp_read.data_H = 0;
      resp_read.data_L = htonl(resp_read.data_L);
      if(gdb_write(&resp_read, sizeof(resp_read)) < 0) {
        client_close ('6');
        return;
        }
      if (DEBUG_GDB) printf(" --> Data 0x%08x Error %d\n", htonl(resp_read.data_L), err);fflush (stdout);
      break;
    case JTAG_COMMAND_BLOCK_WRITE:
      if(length < sizeof(JTAGProxyBlockWriteMessage)-8) {
        ProtocolClean(length, JTAG_PROXY_PROTOCOL_ERROR);
        return;
      }
      if(!(p_buf = (char*)malloc(8+length))) {
        ProtocolClean(length, JTAG_PROXY_OUT_OF_MEMORY);
        return;
      }
      msg_bwrite = (JTAGProxyBlockWriteMessage*)p_buf;
      if(gdb_read(&p_buf[8], length) < 0) {
        client_close ('5');
        free(p_buf);
        return;
      }
      msg_bwrite->address = ntohl(msg_bwrite->address);
      msg_bwrite->nRegisters = ntohl(msg_bwrite->nRegisters);
      if (DEBUG_GDB) printf("Block Write to Chain %d start add 0x%08x Write %d (32 bit words):\n\n", gdb_chain, msg_bwrite->address, msg_bwrite->nRegisters);
      for(i=0;i<msg_bwrite->nRegisters;i++) {
        msg_bwrite->data[i] = ntohl(msg_bwrite->data[i]);
				if (DEBUG_GDB_BLOCK_DATA){
				  if ((i % 4) == 0)      printf("Add 0x%08x   Data 0x%08x  ", msg_bwrite->address + (i * 4), msg_bwrite->data[i]);
		          else if ((i % 4) == 3) printf("0x%08x\n", msg_bwrite->data[i]);
				  else                   printf("0x%08x  ", msg_bwrite->data[i]);

					// add a new line on the last data, but not if it is the last one in the colum 
					if ((msg_bwrite->nRegisters - i == 1) && (i % 4) < 3) printf("\n");
				}
      }
      err = gdb_write_block(msg_bwrite->address, (uint32_t*)msg_bwrite->data, msg_bwrite->nRegisters * 4);
      if (DEBUG_GDB) printf("Error %x\n", err);fflush (stdout);
      resp_bwrite.status = htonl(err);
      free(p_buf);
      msg_bwrite = (JTAGProxyBlockWriteMessage *)NULL;
      p_buf = (char *)msg_bwrite;
      if(gdb_write(&resp_bwrite, sizeof(resp_bwrite)) < 0) {
        client_close ('4');
        return;
      }
      break;
    case JTAG_COMMAND_BLOCK_READ:
      if(length != sizeof(msg_bread) - 8) {
        ProtocolClean(length, JTAG_PROXY_PROTOCOL_ERROR);
        return;
      }
      p_buf = (char*)&msg_bread;
      if(gdb_read(&p_buf[8], length) < 0) {
        client_close ('5');
        return;
      }
      msg_bread.address = ntohl(msg_bread.address);
      msg_bread.nRegisters = ntohl(msg_bread.nRegisters);
      if (DEBUG_GDB) printf("Block Read from Chain %d start add 0x%08x Read %d (32 bit words):\n\n", gdb_chain, msg_bread.address, msg_bread.nRegisters);
      len = sizeof(JTAGProxyBlockReadResponse) + 4*(msg_bread.nRegisters-1);
      if(!(p_buf = (char*)malloc(len))) {
        ProtocolClean(0, JTAG_PROXY_OUT_OF_MEMORY);
        return;
      }
      resp_bread = (JTAGProxyBlockReadResponse*)p_buf;
      err = gdb_read_block(msg_bread.address, (uint32_t*)resp_bread->data, msg_bread.nRegisters * 4);
      for(i=0;i<msg_bread.nRegisters;i++) {
        /* Read previous, address next one. */
        resp_bread->data[i] = htonl(resp_bread->data[i]);
		if (DEBUG_GDB_BLOCK_DATA){
		  if ((i % 4) == 0)      printf("Add 0x%08x   Data 0x%08x  ", msg_bread.address + (i * 4), htonl(resp_bread->data[i]));
          else if ((i % 4) == 3) printf("0x%08x\n", htonl(resp_bread->data[i]));
		  else                   printf("0x%08x  ", htonl(resp_bread->data[i]));
		}
		// add a new line on the last data, but not if it is the last one in the colum 
		if ((msg_bread.nRegisters - i == 1) && (i % 4) < 3) printf("\n");
      }
      resp_bread->status = htonl(err);
      resp_bread->nRegisters = htonl(msg_bread.nRegisters);
      if (DEBUG_GDB) printf("\nError %x\n", err);fflush (stdout);
      if(gdb_write(resp_bread, len) < 0) {
        client_close ('6');
        free(p_buf);
        return;
      }
      free(p_buf);
      resp_bread = (JTAGProxyBlockReadResponse *)NULL;
      p_buf = (char *)resp_bread;
      break;
    case JTAG_COMMAND_CHAIN:
      if(length != sizeof(msg_chain) - 8) {
        ProtocolClean(length, JTAG_PROXY_PROTOCOL_ERROR);
        return;
      }
      p_buf = (char*)&msg_chain;
      if(gdb_read(&p_buf[8], sizeof(msg_chain)-8) < 0) {
        client_close ('7');
        return;
      }
      msg_chain.chain = htonl(msg_chain.chain);
      err = gdb_set_chain(msg_chain.chain);
      resp_chain.status = htonl(err);
      if (DEBUG_GDB){
	      switch(msg_chain.chain){
					case SC_GLOBAL:      /* 0 Global BS Chain */
						printf("Set Chain %d Global BS Chain  Error %x\n", msg_chain.chain, err);
						break;
					case SC_RISC_DEBUG:  /* 1 RISC Debug Interface chain */
						printf("Set Chain %d RISC Debug Interface chain  Error %x\n", msg_chain.chain, err);
						break;
					case SC_RISC_TEST:   /* 2 RISC Test Chain */
						printf("Set Chain %d RISC Test Chain  Error %x\n", msg_chain.chain, err);
						break;
					case SC_TRACE:       /* 3 Trace Chain */
						printf("Set Chain %d Trace Chain  Error %x\n", msg_chain.chain, err);
						break;
					case SC_REGISTER:    /* 4 Register Chain */
						printf("Set Chain %d Register Chain  Error %x\n", msg_chain.chain, err);
						break;
					case SC_WISHBONE:    /* 5 Memory chain */
						printf("Set Chain %d Wishbone Memory chain  Error %x\n", msg_chain.chain, err);
						break;
					case SC_BLOCK:       /* 6 Block Chains */
						printf("Set Chain %d Block Chains  Error %x\n", msg_chain.chain, err);
						break;
					default:						 /* Invalid chain */
						printf("Set Chain %d Invalid chain  Error %x\n", msg_chain.chain, err);
						break;
	      }
      	fflush (stdout);
      }
      if(gdb_write(&resp_chain, sizeof(resp_chain)) < 0) {
        client_close ('8');
        return;
      }
      break;
    default:
      perror("Unknown JTAG command.");fflush (stdout);
      ProtocolClean(length, JTAG_PROXY_COMMAND_NOT_IMPLEMENTED);
      break;
  }
}

static void ProtocolClean(int length, int32_t err) {
  char buffer[4096];

  err = htonl(err);
  if(((gdb_read(buffer, length) < 0) || (gdb_write(&err, sizeof(err)) < 0)) && gdb_fd) {
    perror("gdb socket - 9");
    close(gdb_fd);
    gdb_fd = 0;
  }
}

static int gdb_write(void* p_buf, int len) {
  int n;
  char* w_buf = (char*)p_buf;
  struct pollfd block;

  while(len) {
    if((n = write(gdb_fd, w_buf, len)) < 0) {
      switch(errno) {
        case EWOULDBLOCK: /* or EAGAIN */
          /* We've been called on a descriptor marked
             for nonblocking I/O. We better simulate
             blocking behavior. */
          block.fd = gdb_fd;
          block.events = POLLOUT;
          block.revents = 0;
          poll(&block, 1, -1);
          continue;
        case EINTR:
          continue;
        case EPIPE:
          close(gdb_fd);
          gdb_fd = 0;
          return -1;
        default:
          return -1;
        }
      } else {
        len -= n;
        w_buf += n;
      }
  }
  return 0;
}

static int gdb_read(void* p_buf, int len) {
  int n;
  char* r_buf = (char*)p_buf;
  struct pollfd block;

  while(len) {
    if((n = read(gdb_fd, r_buf, len)) < 0) {
      switch(errno) {
        case EWOULDBLOCK: /* or EAGAIN */
          /* We've been called on a descriptor marked
       for nonblocking I/O. We better simulate
       blocking behavior. */
          block.fd = gdb_fd;
          block.events = POLLIN;
          block.revents = 0;
          poll(&block, 1, -1);
          continue;
        case EINTR:
          continue;
        default:
          return -1;
        }
    } else if(n == 0) {
      close(gdb_fd);
      gdb_fd = 0;
      return -1;
    } else {
      len -= n;
      r_buf += n;
    }
  }
  return 0;
}


/*****************************************************************************
* Close the connection to the client if it is open
******************************************************************************/
static void client_close (char err)
{
  if(gdb_fd) {
    perror("gdb socket - " + err);
    close(gdb_fd);
    gdb_fd = 0;
  }
}	/* client_close () */


/*---------------------------------------------------------------------------*/
/* Swap a buffer of 4-byte from 1234 to 4321

   parameter[in]  p_buf and len
   parameter[out] none																											 */
/*---------------------------------------------------------------------------*/
static void swap_buf(char* p_buf, int len) 
{
	int temp;
	int n = 0;

  if (len > 2)
  {
    while(n < len){
    	// swap 0 and 3
    	temp = p_buf[n];
			p_buf[n] = p_buf[n + 3];
			p_buf[n + 3] = temp;
    	// swap 1 and 2
    	temp = p_buf[n + 1];
			p_buf[n + 1] = p_buf[n + 2];
			p_buf[n + 2] = temp;
			
			n += 4;
    }
	}
}


/*---------------------------------------------------------------------------*/
/*!Set the stall state of the processor

   @param[in] state  If non-zero stall the processor.                        */
/*---------------------------------------------------------------------------*/
static void
set_stall_state (int state)
{
  
  if(state == 0)
    {
      err = dbg_cpu0_write_ctrl(0, 0);	 /* unstall or1k */
      stallState = UNSTALLED;
      npcIsCached = 0;
      rsp.sigval = TARGET_SIGNAL_NONE;
    }
  else 
    {
      err = dbg_cpu0_write_ctrl(0, 0x01);				 /* stall or1k */
      stallState = STALLED;
    }  

  if(err > 0 && DEBUG_GDB)printf("Error %d in set_stall_state Stall state = %d\n", err, state);

}	/* set_stall_state () */


/*---------------------------------------------------------------------------*/
/*!Set the reset bit of the processor's control reg in debug interface
 */
/*---------------------------------------------------------------------------*/
static void
reset_or1k (void)
{
  
  err = dbg_cpu0_write_ctrl(0, 0x02);  /* reset or1k */
  
  if(err > 0 && DEBUG_GDB)printf("Error %d in reset_or1k()\n", err);

}	/* reset_or1k () */

/*---------------------------------------------------------------------------*/
/*!Close down the connection with GDB in the event of a kill signal

 */
/*---------------------------------------------------------------------------*/
void gdb_close()
{
  rsp_client_close();
  client_close('0');
  // Maybe do other things here!
}
