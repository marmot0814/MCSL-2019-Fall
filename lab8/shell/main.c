#include "inc/stm32l476xx.h"

int resistor, vol;
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

#pragma thumb
void SysTick_UserConfig(int sw) {
	if(sw) {
		SysTick->CTRL |= 0x00000004;
		SysTick->LOAD = 5 * 400000;
		SysTick->VAL = 0;
		SysTick->CTRL |= 0x00000003;
	} else {
		SysTick->CTRL &= (0xFFFFFFFE);
	}
}

#pragma thumb
void SysTick_Handler() {
//    	GPIOA->ODR = GPIOA->ODR ^ (1<<5);

	ADC1->CR |= ADC_CR_ADSTART; // start adc conversion
}

#pragma thumb
void ADC1_2_IRQHandler() {
	while (!(ADC1->ISR & ADC_ISR_EOC)); // wait for conversion complete
	vol = (int) ADC1->DR;
    resistor = (5000 - vol) * 220 / vol;
}

void ADC1_init() {
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOCEN;
	RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;
	GPIOC->MODER |= 0b11; // analog mode
	GPIOC->ASCR |= 1; // connect analog switch to ADC input
	ADC1->CFGR &= ~ADC_CFGR_RES; // 12-bit resolution
	ADC1->CFGR &= ~ADC_CFGR_CONT; // disable continuous conversion
	ADC1->CFGR &= ~ADC_CFGR_ALIGN; // right align
	ADC123_COMMON->CCR &= ~ADC_CCR_DUAL; // independent mode
	ADC123_COMMON->CCR &= ~ADC_CCR_CKMODE; // clock mode: hclk / 1
	ADC123_COMMON->CCR |= 1 << 16;
	ADC123_COMMON->CCR &= ~ADC_CCR_PRESC; // prescaler: div 1
	ADC123_COMMON->CCR &= ~ADC_CCR_MDMA; // disable dma
	ADC123_COMMON->CCR &= ~ADC_CCR_DELAY; // delay: 5 adc clk cycle
	ADC123_COMMON->CCR |= 4 << 8;
	ADC1->SQR1 &= ~(ADC_SQR1_SQ1 << 6); // channel: 1, rank: 1
	ADC1->SQR1 |= (1 << 6);
	ADC1->SMPR1 &= ~(ADC_SMPR1_SMP0 << 3); // adc clock cycle: 12.5
	ADC1->SMPR1 |= (2 << 3);
	ADC1->CR &= ~ADC_CR_DEEPPWD; // turn off power
	ADC1->CR |= ADC_CR_ADVREGEN; // enable adc voltage regulator
	for (int i = 0; i <= 1000; ++i); // wait for regulator start up
	ADC1->IER |= ADC_IER_EOCIE; // enable end of conversion interrupt
	NVIC_EnableIRQ(ADC1_2_IRQn);
	ADC1->CR |= ADC_CR_ADEN; // enable adc
	while (!(ADC1->ISR & ADC_ISR_ADRDY)); // wait for adc start up
}

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
			SysTick_UserConfig(1);
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
	ADC1_init();
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
					SysTick_UserConfig(0);
					shell_state = 0;
				}
			}
		}
	}
	return 0;
}
