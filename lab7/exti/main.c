#include "inc/stm32l476xx.h"

// use this pragma at handlers
#pragma thumb
void EXTI0_Handler() {
	GPIOA->ODR = GPIOA->ODR ^ (1<<5);
}

void NVIC_config() {
	NVIC->ISER[0] = (0x0F << 6);
}

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

int col = 0;

int main() {
	GPIO_init();
	while(1) {
		for(int i=5; i<9; i++) {
			// mask EXTI on line 9-6
			// locked
			col = i;
			GPIOC->ODR = (1<<i);
			// unmask EXTI again
		}
	}
	return 0;
}
