
//#include "types.h"
//#include "elf.h"
//#include "riscv.h"
//#include "memlayout.h"
typedef unsigned int   uint;
typedef unsigned short ushort;
typedef unsigned char  uchar;
#define RISCV_IO_BASE 0xFFFFF000

#define SECTSIZE  512

void readseg(uchar*, uint, uint);

void main(void)
{
  readseg((uchar*)0x7c00, SECTSIZE, 0);
  void (*entry)(void);
  entry = (void(*)(void))(0x7c00);
  entry();
}

static inline uchar
inb(ushort port)
{
  uchar data;

  data = (*(volatile uchar *)(RISCV_IO_BASE + port));
  return data;
}

static inline void
insl(int port, void *addr, int cnt)
{
  uchar *addr_sl = (uchar *)addr;
  while ((cnt--) > 0) {
    *addr_sl = (*(volatile uchar *)(RISCV_IO_BASE + port));
    addr_sl++;
  }
}

static inline void
outb(ushort port, uchar data)
{
  (*(volatile uchar *)(RISCV_IO_BASE + port)) = data;
}

void
waitdisk(void)
{
  // Wait for disk ready.
  while((inb(0x1F7) & 0xC0) != 0x40)
    ;
}

// Read a single sector at offset into dst.
void
readsect(void *dst, uint offset)
{
  // Issue command.
  //waitdisk();
  outb(0x1F2, 1);   // count = 1
  
  outb(0x1F3, offset);
  outb(0x1F4, offset >> 8);
  outb(0x1F5, offset >> 16);
  //outb(0x1F6, (offset >> 24) | 0xE0);
  outb(0x1F6, (offset >> 24));
  
  //*(int*)(RISCV_IO_BASE + 0x1F3) = offset;
  outb(0x1F7, 0x20);  // cmd 0x20 - read sectors

  // Read data.
  waitdisk();
  //insl(0x1F0, dst, SECTSIZE/4);
  insl(0x1F0, dst, SECTSIZE);
}

// Read 'count' bytes at 'offset' from kernel into physical address 'pa'.
// Might copy more than asked.
void
readseg(uchar* pa, uint count, uint offset)
{
//0x1E3:	read op
//0x1E4 - 0x1E7:	phisical address
//0x1E8 - 0x1EB:	read address(offset)
//0x1EC - 0x1EF:	read size(count)
  uchar* epa;

  epa = pa + count;

  // Round down to sector boundary.
  pa -= offset % SECTSIZE;

  // Translate from bytes to sectors; kernel starts at sector 1.
  offset = (offset / SECTSIZE);// + 1;
  // If this is too slow, we could read lots of sectors at a time.
  // We'd write more to memory than asked, but it doesn't matter --
  // we load in increasing order.
  for(; pa < epa; pa += SECTSIZE, offset++)
    readsect(pa, offset);
}


