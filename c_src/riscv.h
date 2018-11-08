// Routines to let C code use special x86 instructions.
//////////////////
//memory mapping//
//////////////////

/*  READ DISK DATA  */
//0x1E3:	read op
//0x1E4 - 0x1E7:	phisical address
//0x1E8 - 0x1EB:	read address(offset)
//0x1EC - 0x1EF:	read size

//MHz ???
#define CLK 500
//ms
#define FREQ_H(x) (x * CLK * 1000)
#define FREQ_L(x) (x * CLK * 1000)
#define TIMECMP_L 0x508
#define TIMECMP_H 0x50C


#define RISCV_IO_BASE 0xFFFFF000
//#define RISCV_IO_BASE 0xFE000000

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

static inline void
outw(ushort port, ushort data)
{
  (*(volatile ushort *)(RISCV_IO_BASE + port)) = data;
  //asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
  //asm volatile("cld; rep outsl" :
  //             "=S" (addr), "=c" (cnt) :
  //             "d" (port), "0" (addr), "1" (cnt) :
  //             "cc");
  //????
  int *port_sl = (int *)port;
  while ((cnt--) > 0) {
    (*(volatile int *)(RISCV_IO_BASE + port_sl)) = *((int*)addr);
    port_sl++;
  }
}

static inline void
stosb(void *addr, int data, int cnt)
{
  //asm volatile("cld; rep stosb" :
  //             "=D" (addr), "=c" (cnt) :
  //             "0" (addr), "1" (cnt), "a" (data) :
  //             "memory", "cc");
	int i;
	  for (i = 0; i < cnt; i++) {
		*(((char *) addr) + i) = (char) data;
	}
}

static inline void
stosl(void *addr, int data, int cnt)
{
  //asm volatile("cld; rep stosl" :
  //             "=D" (addr), "=c" (cnt) :
  //             "0" (addr), "1" (cnt), "a" (data) :
  //             "memory", "cc");
	int i;
	for (i = 0; i < cnt; i++) {
		*(((int *) addr) + i) = data;
	}
}

//struct segdesc;
//
//static inline void
//lgdt(struct segdesc *p, int size)
//{
//  volatile ushort pd[3];
//
//  pd[0] = size-1;
//  pd[1] = (uint)p;
//  pd[2] = (uint)p >> 16;
//
//  asm volatile("lgdt (%0)" : : "r" (pd));
//}
//
//struct gatedesc;
//
/*
static inline void
lidt(struct gatedesc *p, int size)
{
  volatile ushort pd[3];

  pd[0] = size-1;
  pd[1] = (uint)p;
  pd[2] = (uint)p >> 16;

  asm volatile("lidt (%0)" : : "r" (pd));
}
*/
static inline void
ltvec(int *p)
{
  asm volatile("csrw mtvec,%0" : : "r" (p));
}

static inline void
write_scratch(int val)
{
  asm volatile("csrw mscratch,%0" : : "r" (val));
}

static inline uint
read_cause()
{
  uint cause;
  asm volatile("csrr %0,mcause" : "=r" (cause));
  return cause;
}
//
//static inline void
//ltr(ushort sel)
//{
//  asm volatile("ltr %0" : : "r" (sel));
//}
//
static inline uint
read_status(void)
{
  uint status;
  //asm volatile("pushfl; popl %0" : "=r" (eflags));
  asm volatile("csrr %0, mstatus" : "=r" (status));
  return status;
}

static inline void
set_timecmp(uint val, uint num)
{ 
  uint port = (num == 0) ? TIMECMP_L : TIMECMP_H;
  int* addr = (int*)(port + RISCV_IO_BASE);
  *addr = val;
}
//
//static inline void
//loadgs(ushort v)
//{
//  asm volatile("movw %0, %%gs" : : "r" (v));
//}

static inline void
cli(void)
{
  asm volatile("li t6,0x00000008 ; csrc mstatus, t6");
}

static inline void
sti(void)
{
  asm volatile("li t6,0x00000008 ; csrs mstatus, t6");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
  uint result;
  asm volatile ("amoswap.w %0, %2, (%1)":
                "=r" (result), "+r" (addr):
                "r" (newval));
  return result;
}

//static inline uint
//rcr2(void)
//{
//  uint val;
//  asm volatile("movl %%cr2,%0" : "=r" (val));
//  return val;
//}
//
static inline void
lcr3(uint val)
{
	uint ppn = val >> 12;
	//asm volatile("movl %0,%%cr3" : : "r" (val));
	asm volatile("li t6, 0x80000000; or t6,t6,%0; csrw satp, t6" : : "r" (ppn));
}

#define SOFT 0
#define TIMER 1 
#define EXTERNAL 2 

static inline void
en_intr(int num)
{
	switch(num){
		case SOFT:
			asm volatile("li t6,0x8; csrs mie,t6");
			break;
		case TIMER:
			asm volatile("li t6,0x80; csrs mie,t6");
			break;
		case EXTERNAL:
			asm volatile("li t6,0x800; csrs mie,t6");
			break;
	}
}

static inline void
disen_intr(int num)
{
	switch(num){
		case SOFT:
			asm volatile("li t6,0x8; csrc mie,t6");
			break;
		case TIMER:
			asm volatile("li t6,0x80; csrc mie,t6");
			break;
		case EXTERNAL:
			asm volatile("li t6,0x800; csrc mie,t6");
			break;
	}
}

static inline void
eoi(int num)
{
	switch(num){
		case SOFT:
			asm volatile("li t6,0x8; csrc mip,t6");
			break;
		case TIMER:
			asm volatile("li t6,0x80; csrc mip,t6");
			break;
		case EXTERNAL:
			asm volatile("li t6,0x800; csrc mip,t6");
			break;
	}
}

//PAGEBREAK: 36
// Layout of the trap frame built on the stack by the
// hardware and by trapasm.S, and passed to trap().
struct trapframe {
  // registers as pushed by pusha
  uint ra;
  uint gp;
  uint tp;
  uint t0;
  uint t1;
  uint t2;
  uint s0;
  uint s1;
  uint a0;
  uint a1;
  uint a2;
  uint a3;
  uint a4;
  uint a5;
  uint a6;
  uint a7;
  uint s2;
  uint s3;
  uint s4;
  uint s5;
  uint s6;
  uint s7;
  uint s8;
  uint s9;
  uint s10;
  uint s11;
  uint t3;
  uint t4;
  uint t5;
  uint t6;

  uint mepc;
  uint mcause;
  uint mstatus;

  //uint trapno;
  //uint err;
  uint sp;

};

/*
struct trapframe {
  // registers as pushed by pusha
  uint edi;
  uint esi;
  uint ebp;
  uint oesp;      // useless & ignored
  uint ebx;
  uint edx;
  uint ecx;
  uint eax;

  // rest of trap frame
  ushort gs;
  ushort padding1;
  ushort fs;
  ushort padding2;
  ushort es;
  ushort padding3;
  ushort ds;
  ushort padding4;
  uint trapno;

  // below here defined by x86 hardware
  uint err;
  uint eip;
  ushort cs;
  ushort padding5;
  uint eflags;

  // below here only when crossing rings, such as from user to kernel
  uint esp;
  ushort ss;
  ushort padding6;
};
*/
