CC=arm-none-eabi-gcc
CC_FLAGS=-O0 -c -g -mcpu=cortex-m4 -mthumb -mfloat-abi=hard
LD=arm-none-eabi-ld
LD_FLAGS_F4=-nostartfiles -TLinkerScriptF4.ld
LD_FLAGS_L4=-nostartfiles -TLinkerScriptL4.ld
OBJ_COPY=arm-none-eabi-objcopy

main.bin: main.elf
	$(OBJ_COPY) -O binary main.elf main.bin

main.elf: start.o io.o main.o
	$(LD) $(LD_FLAGS_L4) -o main.elf main.o io.o start.o

start.o: start.s
	$(CC) $(CC_FLAGS) -o start.o start.s

io.o: io.s
	$(CC) $(CC_FLAGS) -o io.o io.s
main.o: main.c
	$(CC) $(CC_FLAGS) -o main.o main.c


clean:
	rm -f main.elf
	rm -f main.o
	rm -f start.o
	rm -f main.bin
	rm -f io.o
