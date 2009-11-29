
#include "unistd.h"
#include "uart.h"

#define __ALIGN      .align 0
#define __ALIGN_STR ".align 0"

#ifdef __cplusplus
#define CPP_ASMLINKAGE extern "C"
#else
#define CPP_ASMLINKAGE
#endif

#ifndef asmlinkage
#define asmlinkage CPP_ASMLINKAGE
#endif

#ifndef asmregparm
# define asmregparm
#endif

static int uart_init_done = 0;

asmlinkage ssize_t sys_write(unsigned int fd, const char __user * buf, size_t count)
{
  //ssize_t ret = -EBADF;

  // init uart if not done already
  if (!uart_init_done)
    {
      uart_init();
      uart_init_done = 1;
    }
  
  int c=0;
  // Simply send each char to the UART
  while (c < count)
    uart_putc(buf[c++]);
  
  /*
        struct file *file;
        
        int fput_needed;

        file = fget_light(fd, &fput_needed);
        if (file) {
                loff_t pos = file_pos_read(file);
                ret = vfs_write(file, buf, count, &pos);
                file_pos_write(file, pos);
                fput_light(file, fput_needed);
        }
  */
  return c;
}
