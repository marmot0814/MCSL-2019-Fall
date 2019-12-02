#include "inc/stm32l476xx.h"

// use this pragma at handlers
//#pragma thumb


int resistor, vol;
extern void max7219_send(int, int);

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

#pragma thumb
void SysTick_UserConfig(int sec) {

	SysTick->CTRL |= 0x00000004;
	SysTick->LOAD = (uint32_t) (sec * 400000);
	SysTick->VAL = 0;
	SysTick->CTRL |= 0x00000003;
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
	ADC123_COMMON->CCR |= 1 << ADC_CCR_CKMODE_Pos;
	ADC123_COMMON->CCR &= ~ADC_CCR_PRESC; // prescaler: div 1
	ADC123_COMMON->CCR &= ~ADC_CCR_MDMA; // disable dma
	ADC123_COMMON->CCR &= ~ADC_CCR_DELAY; // delay: 5 adc clk cycle
	ADC123_COMMON->CCR |= 4 << ADC_CCR_DELAY_Pos;
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
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOCEN;

    GPIOA->MODER = (GPIOA->MODER & 0xFFFFF3FF) | 0x400;

    GPIOB->MODER = (GPIOB->MODER & ~(0x3 << (2 *  3))) | (0x1 << (2 *  3));   // PB 3 output mode
    GPIOB->MODER = (GPIOB->MODER & ~(0x3 << (2 *  4))) | (0x1 << (2 *  4));   // PB 4 output mode
    GPIOB->MODER = (GPIOB->MODER & ~(0x3 << (2 *  5))) | (0x1 << (2 *  5));   // PB 5 output mode

    GPIOC->MODER = (GPIOC->MODER & ~(0x3 << (2 * 13))) | (0x0 << (2 * 13));   // PC13 input mode
    GPIOC->PUPDR = 0xAA;


    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOCEN;
	GPIOA->MODER = (GPIOA->MODER & 0xFFC3FFFF) | 0x280000;
	GPIOA->AFR[1] = (GPIOA->AFR[1] & 0xFFFFF00F) | 0x770;

}

void max7219_init() {
	max7219_send(0x0C, 0x01);
	max7219_send(0x0B, 0x07);
	max7219_send(0x09, 0xFF);
	max7219_send(0x0A, 0x08);
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


int main() {
    GPIO_init();
    ADC1_init();
    max7219_init();
    ConfigUSART();
    SysTick_UserConfig(10);
    while (1) {
        if (poll_button()) {
            char buf[100]; buf[0] = '\0'; int ptr = 0;
            int tar = resistor;
            while (tar) {
                buf[ptr++] = (tar % 10) + '0';
                tar /= 10;
            }
            if (ptr == 0)
                buf[ptr++] = '0';
            buf[ptr] = '\0';

            int L = 0, R = ptr - 1;
            while (L < R) {
                char tmp = buf[L];
                buf[L] = buf[R];
                buf[R] = tmp;
                L++;
                R--;
            }
            buf[ptr++] = ' ';
            buf[ptr] = '\0';
            for (int i = 0 ; i < ptr ; i++) {
                while (!(USART1->ISR & USART_ISR_TXE));
                USART1->TDR = buf[i];
            }
        }
    }
	return 0;
}
