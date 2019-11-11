#include "inc/stm32l476xx.h"

extern void GPIO_init();
extern void max7219_send(int addr, int data);

int id[8] = {0, 6, 1, 6, 0, 6, 9};

#pragma thumb
int main() {
	GPIO_init();
	max7219_send(0x0C, 0x01);
	max7219_send(0x0B, 0x06);
	max7219_send(0x09, 0xFF);
	max7219_send(0x0A, 0x08);
	for(int i=6; i>=0; i--) {
		max7219_send(7-i, id[i]);
	}
	return 0;
}
