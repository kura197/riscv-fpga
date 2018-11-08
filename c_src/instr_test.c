
#define RISCV

#ifndef RISCV
#include <stdio.h>
#endif

int main(void)
{
	int a[23];
	int x=0x80001111;
	int y=0b00001100;
	a[0] = x + 0b00001100;
	a[1] = x ^ 0b00001100;
	a[2] = x & 0b00001100;
	a[3] = x | 0b00001100;
	a[4] = x << 2;
	a[5] = x >> 2;
	a[6] = (unsigned int)x >> 2;
	a[7] = x + y;
	a[8] = x - y;
	a[9] = x ^ y;
	a[10] = x & y;
	a[11] = x | y;
	a[12] = x << y;
	a[13] = x >> y;
	a[14] = (unsigned int)y >> 2;
	a[15] = x > y;
	a[16] = (unsigned int)x > (unsigned int)y;
	int z = 0x00000001;
	int w = 0x80000002;
	if(z == w)	a[17] = 1;
	else		a[17] = 0;
	if(z != w)	a[18] = 1;
	else		a[18] = 0;
	if(z < w)	a[19] = 1;
	else		a[19] = 0;
	if(z >= w)	a[20] = 1;
	else		a[20] = 0;
	if((unsigned int)z > (unsigned int)w)	a[21] = 1;
	else		a[21] = 0;
	if((unsigned int)z > (unsigned int)w)	a[22] = 1;
	else		a[22] = 0;
#ifdef RISCV
	int* addr = (int*)0xf00;
	for(int i = 0; i < 23; i++){
		*addr = a[i];
		addr++;
	}
#else
	for(int i = 0; i < 23; i++){
		printf("a[%d] = %08x\n",i,a[i]);
	}
#endif
	
	return 0;
}



