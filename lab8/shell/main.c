#include "inc/stm32l476xx.h"

char* prev;
char* strtok(char *str) {
    if (str)
        prev = str;
    else
        str = prev;
    if (*str == '\0')
        return 0;
    while (*prev != '\0' && *prev != ' ')
        prev++;
    while (*prev == ' ')
        *prev = '\0', prev++;
    return str;
}

int strlen(char *s) {
    int ret = 0;
    while (*s != '\0')
        s++, ret++;
    return ret;
}

int strcmp(char *a, char *b) {
    int lenA = strlen(a);
    int lenB = strlen(b);
    if (lenA != lenB)
        return 0;
    for (int i = 0 ; i < lenA ; i++)
        if (a[i] != b[i])
            return 0;
    return 1;
}

// use this pragma at handlers
//#pragma thumb

#define MAX_BUFFER_SIZE 64

char str[] = "Hello, World!";

void GPIO_init() {
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOCEN;
	GPIOA->MODER = (GPIOA->MODER & 0xFFC3FFFF) | 0x280000;
	GPIOA->AFR[1] = (GPIOA->AFR[1] & 0xFFFFF00F) | 0x770;
	GPIOA->MODER = (GPIOA->MODER & 0xFFFFF3FF) | 0x400;

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
		} else if(strcmp(s, "light")) {
			shell_state = 1;
			return ;
		} else if(strcmp(s, "led")) {
			s = strtok(0);
			if(strcmp(s, "on")) {
				GPIOA->ODR |= (1<<5);
			} else if(strcmp(s, "off")) {
				GPIOA->ODR &= ~(1<<5);
			}
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
			if(shell_state == 0) {
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
			} else {
				if(c == 'q') {
					shell_state = 0;
				}
			}
		}
	}
	return 0;
}
