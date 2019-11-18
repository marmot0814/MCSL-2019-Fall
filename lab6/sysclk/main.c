#include "inc/stm32l476xx.h"

// use this pragma at handlers

int clk_state = 0;
int debounce[5] = {512, 3072, 5120, 8192, 20480};
//int clk[5] = {2, 2, 2, 2, 2};

#pragma thumb
void SysTick_Handler() {
	GPIOA->ODR = GPIOA->ODR ^ (1<<5);
}

void GPIO_init() {
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOCEN;

	GPIOA->MODER = (GPIOA->MODER & 0xFFFFF3FF) | 0x400;
	GPIOA->OSPEEDR = 0x800;

	GPIOB->MODER = (GPIOB->MODER & 0xFFFFF03F) | 0x540;
	GPIOB->OSPEEDR = 0xA80;

	GPIOC->MODER = (GPIOC->MODER & 0xF3FFFFFF);
	GPIOB->PUPDR = 0x04000000;
}

int poll_button() {
	static int cnt = 0;
	static int prev = 0;
	int status = GPIOC->IDR & (0x01 << 13);
	if(!status) {
		if(cnt > debounce[clk_state]) {
			if(prev == 0) {
				prev = 1;
				cnt = 0;
				return 1;
			}
			cnt = 0;
		}
		cnt++;
	} else {
		prev = 0;
		cnt = 0;
	}
	return 0;
}

void switch_clk(int n, int m, int r) {
	// switch to MSI clock first
	while(!(RCC->CR & RCC_CR_MSIRDY));
	RCC->CFGR = (RCC->CFGR & 0xFFFFFFFC) | 0x00;
	
	RCC->CR &= (0xFEFFFFFF);
	while(RCC->CR & RCC_CR_PLLRDY);
	RCC->PLLCFGR = (RCC->PLLCFGR & 0xF8FF808C) | (r << 25) | (n << 8) | (m << 4) | 0x01;
	RCC->CR |= 0x01000000;
	RCC->PLLCFGR |= 0x01000000;

	// switch to PLL clock
	while(!(RCC->CR & RCC_CR_PLLRDY));
	RCC->CFGR = (RCC->CFGR & 0xFFFFFFFC) | 0x03;
}

extern void max7219_send(int addr, int data);

int main() {
	static int PLLN[5] = {8, 24, 40, 64, 40};
	static int PLLM[5] = {3, 3, 3, 3, 0};
	static int PLLR[5] = {3, 1, 1, 1, 1};
	GPIO_init();
	max7219_send(0x0C, 0x01);
	max7219_send(0x0B, 0x00);
	max7219_send(0x09, 0xFF);
	max7219_send(0x0A, 0x08);
	SysTick->LOAD = 1000000;
	SysTick->CTRL = 3;
	switch_clk(PLLN[clk_state], PLLM[clk_state], PLLR[clk_state]);
	max7219_send(0x01, clk_state);
	while(1) {
		if(poll_button()) {
			clk_state++;
			if(clk_state == 5) clk_state = 0;
			// switching to clock faster than 10MHz may make max7219 fail
			max7219_send(0x01, clk_state);
			switch_clk(PLLN[clk_state], PLLM[clk_state], PLLR[clk_state]);
		}
	}
	return 0;
}
