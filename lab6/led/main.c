#include "inc/stm32l476xx.h"

// use this pragma at handlers
//#pragma thumb

extern void max7219_send(int addr, int data);

void GPIO_init() {
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOCEN;

	GPIOA->MODER = (GPIOA->MODER & 0xFFFFFFFC) | 0x02;
	GPIOA->AFR[0] = (GPIOA->AFR[0] & 0xFFFFFFF0) | 0x01;

	GPIOB->MODER = (GPIOB->MODER & 0xFFF0003F) | 0x540;
	GPIOB->OSPEEDR = 0xA80;
	GPIOB->PUPDR = 0xAA100;

	GPIOC->MODER = (GPIOC->MODER & 0xFFFC03FF) | 0x15400;
	GPIOC->OSPEEDR = 0x2A800;
}

void max7219_init() {
	max7219_send(0x0C, 0x01);
	max7219_send(0x0B, 0x07);
	max7219_send(0x09, 0xFF);
	max7219_send(0x0A, 0x08);
}

int pitch_arr[9] = {0, 15291, 13619, 12136, 11455, 10204, 9091, 8099, 7644};

void timer_init(TIM_TypeDef *timer) {
	RCC->APB1ENR1 |= 0x01;
	timer->PSC = 0;
	timer->CCMR1 = 0x00000060;
	timer->CCER |= 0x01;
}

void timer_start(TIM_TypeDef *timer) {
	timer->CR1 |= 0x01;
}

void timer_set_pitch(TIM_TypeDef *timer, int arr, int cycle) {
	static int current_arr = 0;
	if(arr == current_arr) {
		return ;
	}
	if(arr != -1) {
		current_arr = arr;
		timer->ARR = arr;
	}
	timer->CCR1 = current_arr*cycle/100;
	timer->EGR |= 0x01;
}

void display(int val) {
	max7219_send(0x01, val%10);
	val /= 10;
	max7219_send(0x02, val%10);
	val /= 10;
	max7219_send(0x03, 128 | val%10);
	val /= 10;
	for(int p=4; p<=8; p++) {
		if(val) {
			max7219_send(p, val%10);
		} else {
			max7219_send(p, 0x0F);
		}
		val/=10;
	}
}

int main() {
	GPIO_init();
	max7219_init();
	display(0);
	timer_init(TIM2);
	timer_start(TIM2);

	int pressed = 0;
	int cycle = 50;
	int hold[2] = {0, 0};
	while(1) {
		pressed = 0;
		for(int i=5; i<9; i++) {
			GPIOC->ODR = (1<<i);
			for(int j=0; j<4; j++) {
				if((GPIOB->IDR >> j) & 0x40) {
					int r = 9-i + 3*j;
					if(i == 5)r = 10 + j;
					if(j == 3)r = 8 + i;
					if(r == 15) r = 0;
					if(r == 16) r = 15;
					if(r <= 8)timer_set_pitch(TIM2, pitch_arr[r], cycle);
					else if(r == 10 && !hold[0]) {
						hold[0] = 1;
						cycle += 10;
						if(cycle > 90)cycle = 90;
						timer_set_pitch(TIM2, -1, cycle);
					} else if(r == 11 && !hold[1]) {
						hold[1] = 1;
						cycle -= 10;
						if(cycle < 10)cycle = 10;
						timer_set_pitch(TIM2, -1, cycle);
					}
					display(r);
					pressed = 1;
				}
			}
		}
		if(!pressed) {
			hold[0] = hold[1] = 0;
			timer_set_pitch(TIM2, 0, cycle);
			display(0);
		}
	}
	return 0;
}
