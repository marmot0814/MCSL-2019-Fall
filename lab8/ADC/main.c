#include "inc/stm32l476xx.h"

// use this pragma at handlers
//#pragma thumb
extern void max7219_send(int, int);

int voltage;

#pragma thumb
void SysTick_Handler() {
    ADC1->CR |= ADC_CR_ADSTART;                     // start adc conversion
}

#pragma thumb
void ADC1_2_IRQHandler() {
	while (!(ADC1->ISR & ADC_ISR_EOC));             // wait for conversion complete
	voltage = (int) ADC1->DR;
}

void GPIO_init() {
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN;
    GPIOA->MODER = (GPIOA->MODER & 0xFFC3FFFF) | 0x280000;
    GPIOA->AFR[1] = (GPIOA->AFR[1] & 0xFFFFF00F) | 0x770;

    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOCEN;
    GPIOC->MODER = (GPIOC->MODER & ~(0x3 << (2 * 13))) | (0x0 << (2 * 13));   // PC13 input mode
    GPIOC->MODER = (GPIOC->MODER & 0xFFFFFFFC) | 0x3;
    GPIOC->PUPDR = 0xAA;
    GPIOC->ASCR |= 1;
}

void ADC1_init() {
	RCC->AHB2ENR |= RCC_AHB2ENR_ADCEN;              // enable ADC
    ADC1->CFGR &= ~ADC_CFGR_RES;                    // resolution 12-bit
    ADC1->CFGR &= ~ADC_CFGR_CONT;                   // single conversion mode
    ADC1->CFGR &= ~ADC_CFGR_ALIGN;                  // right alignment

    ADC123_COMMON->CCR &= ~ADC_CCR_DUAL;            // independent mode
    ADC123_COMMON->CCR &= ~ADC_CCR_CKMODE;          // HCLK / 1
    ADC123_COMMON->CCR |= 1 << ADC_CCR_CKMODE_Pos;
    ADC123_COMMON->CCR &= ~ADC_CCR_PRESC;           // prescaler: div 1
    ADC123_COMMON->CCR &= ~ADC_CCR_MDMA;            // disable DMA
    ADC123_COMMON->CCR &= ~ADC_CCR_DELAY;
    ADC123_COMMON->CCR |= 4 << ADC_CCR_DELAY_Pos;

    ADC1->SQR1 &= ~(ADC_SQR1_SQ1);                  // channel: 1, rank: 1
    ADC1->SQR1 |= 1 << ADC_SQR1_SQ1_Pos;
    
    ADC1->SMPR1 &= ~ADC_SMPR1_SMP1;                 // ADC sample pre 6.5 clock cycle
    ADC1->SMPR1 |= 2 << ADC_SMPR1_SMP1_Pos;

    ADC1->CR &= ~ADC_CR_DEEPPWD;                    // disable deeppwd
    ADC1->CR |= ADC_CR_ADVREGEN;                    // enable ADC voltage regulator
    for (int i = 0 ; i < 1000 ; i++);               // wait for voltage regulator
    ADC1->IER |= ADC_IER_EOCIE;                     // enable end of conversion interrupt
    NVIC_EnableIRQ(ADC1_2_IRQn);                    
    ADC1->CR |= ADC_CR_ADEN;                        // enable ADC
    while (!(ADC1->ISR & ADC_ISR_ADRDY));           // wait for ADC startup
}

void USART_init() {
    RCC->APB2ENR |= RCC_APB2ENR_USART1EN;
    USART1->BRR = 0x1A0;
    USART1->CR1 |= USART_CR1_TE;
    USART1->CR1 |= USART_CR1_UE;
}

void SysTick_init() {
    SysTick->CTRL |= 0x00000004;
    SysTick->LOAD = 10 * 4000000;
    SysTick->VAL = 0;
    SysTick->CTRL |= 0x00000003;
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

void print(char *s) {
    for(int i=0; s[i]; i++) {
        while(!(USART1->ISR & USART_ISR_TXE));
        USART1->TDR = s[i];
    }
}

void printInt(int tar) {
    static char buf[100]; buf[0] = '\0'; int ptr = 0;
    while (tar)
        buf[ptr++] = (tar % 10) + '0', tar /= 10;
    if (ptr == 0)
        buf[ptr++] = '0';
    buf[ptr] = '\0';
    int L = 0, R = ptr - 1;
    while (L < R) {
        char tmp = buf[L]; buf[L] = buf[R]; buf[R] = tmp;
        L++; R--;
    }
    print(buf);
}

int main() {
    GPIO_init();
    ADC1_init();
    USART_init();
    SysTick_init();
    while (1) {
        if (poll_button())
            print("\r                    \rvoltage: "), printInt(voltage);
    }
}
