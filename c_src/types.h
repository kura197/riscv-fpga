typedef unsigned int   uint;
typedef unsigned short ushort;
typedef unsigned char  uchar;
typedef uint pde_t;

__attribute__((__aligned__(PGSIZE)))
pde_t entrypgdir[NPDENTRIES] = {
  // Map VA's [0, 4MB) to PA's [0, 4MB)
  //[0] = (0) | PTE_V | PTE_R | PTE_X | PTE_W,
  [0] = (0) | 0xf,
  // Map VA's [KERNBASE, KERNBASE+4MB) to PA's [0, 4MB)
  //[KERNBASE>>PDXSHIFT] = (0) | PTE_V | PTE_W | PTE_PS,
 // [KERNBASE>>PDXSHIFT] = (0) | PTE_V | PTE_R | PTE_X | PTE_W,
};
