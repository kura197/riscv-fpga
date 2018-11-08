#include <stdio.h>

int main(int argc, char* argv[]){
	FILE *rfp, *wfp;
	if(argc != 2){
		printf("need a binary file\n");
		return 1;
	}
	rfp = fopen(argv[1], "rb");
	wfp = fopen("test.hex", "w");
	char bin[4];
	while(fread(bin,sizeof(char),4,rfp) > 0){
		fprintf(wfp,"%02x%02x%02x%02x\n",bin[3]&0xFF,bin[2]&0xFF,bin[1]&0xFF,bin[0]&0xFF);
	}
	fclose(rfp);
	fclose(wfp);
}
