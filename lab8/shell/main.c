#include "inc/stm32l476xx.h"

// use this pragma at handlers
//#pragma thumb

#define MAX_BUFFER_SIZE 64

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
	USART1->CR1 |= USART_CR1_RE;
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

char com[MAX_BUFFER_SIZE];
char res[MAX_BUFFER_SIZE];
int ptr;
int shell_state = 0;

void print(char *s) {
	for(int i=0; s[i]; i++) {
		while(!(USART1->ISR & USART_ISR_TXE));
		USART1->TDR = s[i];
	}
}

void run_command() {
	for(char *s = strtok(com); s; s = strtok(0)) {
		if(strcmp(s, "showid")) {
			print("0616069");
		}
	}
}

int main() {
	GPIO_init();
	ConfigUSART();
	ptr = 0;
	while(1) {
		if(USART1->ISR & USART_ISR_RXNE) {
			char c = USART1->RDR;
			while(!(USART1->ISR & USART_ISR_TXE));
			USART1->TDR = c;
			if(c == '\n' || c == '\r') {
				USART1->TDR = '\n';
				com[ptr] = '\0';
				run_command();
				ptr = 0;
				continue;
			}
			com[ptr++] = c;
		}
	}
	return 0;
}
