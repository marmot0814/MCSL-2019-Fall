#include "inc/stm32l476xx.h"
#include <string.h>

// use this pragma at handlers
//#pragma thumb

char str[] = "Hello, World!";

void GPIO_init() {
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOCEN;
	GPIOA->MODER = (GPIOA->MODER & 0xFFC3FFFF) | 0x280000;
	GPIOA->AFR[1] = (GPIOA->AFR[1] & 0xFFFFF00F) | 0x770;

	GPIOC->MODER = (GPIOC->MODER & 0xF3FFFFFF);
	GPIOC->OSPEEDR = 0x800;
	GPIOC->PUPDR = 0xAA;
}

void ConfigUSART() {
	RCC->APB2ENR |= RCC_APB2ENR_USART1EN;
	USART1->BRR = 0x1A0;
	USART1->CR1 |= USART_CR1_TE;
	USART1->CR1 |= USART_CR1_UE;
}

int poll_button() {
	static int cnt = 0;
	static int prev = 0;
	int status = GPIOC->IDR & (0x01 << 13);
	if(!status) {
		if(cnt > 2048) {
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

void delay() {
    int cnt = 400000;
    while (cnt--);
}

int main() {
	GPIO_init();
	ConfigUSART();
	int l = strlen(str);
	while(1) {
		if(poll_button()) {
			for(int i=0; str[i]; i++) {
				while(!(USART1->ISR & USART_ISR_TXE));
				USART1->TDR = str[i];
			}
		}
	}
	return 0;
}
