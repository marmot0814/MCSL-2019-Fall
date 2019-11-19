#include "inc/stm32l476xx.h"

extern void max7219_send(int addr, int data);

void GPIO_init() {
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOCEN;
	GPIOB->MODER = (GPIOB->MODER & 0xFFF0003F) | 0x540;
	GPIOB->OSPEEDR = 0xA80;
	GPIOB->PUPDR = 0xAA100;

	GPIOC->MODER = (GPIOC->MODER & 0xFFFC03FF) | 0x15400;
	GPIOC->OSPEEDR = 0x2A800;
}

void display(int r) {
	max7219_send(0x02, 0x0F);
	if(r < 10) {
		max7219_send(0x01, r);
	} else {
		max7219_send(0x02, 0x01);
		max7219_send(0x01, r-10);
	}
}

int main() {
	GPIO_init();
	max7219_send(0x0C, 0x01);
	max7219_send(0x0B, 0x01);
	max7219_send(0x09, 0xFF);
	max7219_send(0x0A, 0x08);
	int pressed = 0, sum = 0;
	while(1) {
		pressed = sum = 0;
		for(int i=5; i<9; i++) {
			GPIOC->ODR = (1<<i);
			for(int j=0; j<4; j++) {
				asm("nop");
				if((GPIOB->IDR >> j) & 0x40) {
					int r = 9-i + 3*j;
					if(i == 5)r = 10 + j;
					if(j == 3)r = 8 + i;
					if(r == 15) r = 0;
					if(r == 16) r = 15;
					sum += r;
					pressed = 1;
				}
			}
		}
		if(!pressed) {
			max7219_send(0x01, 0x0F);
			max7219_send(0x02, 0x0F);
		} else {
			display(sum);
		}
	}
	return 0;
}
