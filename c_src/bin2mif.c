#include <stdio.h>

#define DEPTH 256
#define WIDTH 32

int main(int argc, char* argv[]){
	if(argc != 2){
		printf("need a bin file.\n");
		return 1;
	}
	FILE *bin,*mif;
	if((bin = fopen(argv[1],"rb")) < 0){
		printf("cannot open bin file.\n");
		return 1;
	}
	mif = fopen("rom.mif","w");
	fprintf(mif, "DEPTH = %d;\n",DEPTH);
	fprintf(mif, "WIDTH = %d;\n\n",WIDTH);
	fprintf(mif, "ADDRESS_RADIX = HEX;\n");
	fprintf(mif, "DATA_RADIX = HEX;\n\n");
	fprintf(mif, "CONTENT\n");
	fprintf(mif, "BEGIN\n\n");

	int bin32bit;
	for(int i = 0; i < DEPTH; i++){
		if(fread(&bin32bit, sizeof(int), 1, bin) == 0)
			bin32bit = 0;
		fprintf(mif, "%04x : %08x;\n",i,bin32bit);
	}
	fprintf(mif, "\nEND;");
	fclose(bin);
	fclose(mif);
	return 0;
}
