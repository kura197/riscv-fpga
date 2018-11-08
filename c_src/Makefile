CC = riscv32-unknown-linux-gnu-gcc -O2
AS = riscv32-unknown-linux-gnu-as
LD = riscv32-unknown-linux-gnu-ld
OBJCOPY = riscv32-unknown-linux-gnu-objcopy
OBJDUMP = riscv32-unknown-linux-gnu-objdump
CCFLAGS = -nostdlib -nostartfiles -Ttest.ls 

test.hex:test.s bin2mif bin2hex
	$(CC) $(CCFLAGS) test.s -o test.o
	$(LD) test.o -o test.bin -e main -Ttext 0 --oformat binary
	./bin2hex test.bin
	./bin2mif test.bin

test.s:test.c
	$(CC) -O0 test.c -S -o test.s

dump:test.o
	$(OBJDUMP) test.o -S

bin2hex:bin2hex.c
	g++ -o $@ $^

bin2mif:bin2mif.c
	g++ -o $@ $^

clean:
	rm test.o test.bin test.hex bin2mif bin2hex

