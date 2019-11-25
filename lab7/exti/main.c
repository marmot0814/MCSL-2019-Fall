#include "inc/stm32l476xx.h"

// use this pragma at handlers
#pragma thumb

int col = 0;

int value[] = {
    1,  2,  3, 10,
    4,  5,  6, 11,
    7,  8,  9, 12,
   15,  0, 14, 13
};

void delay() {
    int cnt = 400000;
    while (cnt--);
}

void EXTI0_Handler() {
    int cnt = value[0 * 4 + col];
    while (cnt--) {
	    GPIOA->ODR = GPIOA->ODR ^ (1<<5);
        delay();
	    GPIOA->ODR = GPIOA->ODR ^ (1<<5);
        delay();
    }
    EXTI->PR1 |= 0x0F;
    NVIC_ClearPendingIRQ(EXTI0_IRQn);
}

#pragma thumb
void EXTI1_Handler() {
    int cnt = value[1 * 4 + col];
    while (cnt--) {
	    GPIOA->ODR = GPIOA->ODR ^ (1<<5);
        delay();
	    GPIOA->ODR = GPIOA->ODR ^ (1<<5);
        delay();
    }
    EXTI->PR1 |= 0x0F;
    NVIC_ClearPendingIRQ(EXTI1_IRQn);
}

#pragma thumb
void EXTI2_Handler() {
    int cnt = value[2 * 4 + col];
    while (cnt--) {
	    GPIOA->ODR = GPIOA->ODR ^ (1<<5);
        delay();
	    GPIOA->ODR = GPIOA->ODR ^ (1<<5);
        delay();
    }
    EXTI->PR1 |= 0x0F;
    NVIC_ClearPendingIRQ(EXTI2_IRQn);
}

#pragma thumb
void EXTI3_Handler() {
    int cnt = value[3 * 4 + col];
    while (cnt--) {
	    GPIOA->ODR = GPIOA->ODR ^ (1<<5);
        delay();
	    GPIOA->ODR = GPIOA->ODR ^ (1<<5);
        delay();
    }
    EXTI->PR1 |= 0x0F;
    NVIC_ClearPendingIRQ(EXTI3_IRQn);
}

void NVIC_config() {
	NVIC->ISER[0] = (0x0F << 6);
}

void EXTI_config() {
    RCC->APB2ENR |= RCC_APB2ENR_SYSCFGEN;
    SYSCFG->EXTICR[0] = 0x2222;
    EXTI->IMR1 = (EXTI->IMR1 & 0xFFFFFFF0) | 0xF;
    EXTI->RTSR1 = (EXTI->RTSR1 & 0xFFFFFFF0) | 0xF;
    EXTI->PR1 = (EXTI->PR1 & 0xFFFFFFF0) | 0xF;
}

void GPIO_init() {
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOCEN;
	GPIOA->MODER = (GPIOA->MODER & 0xFFFFF3FF) | 0x400;
	GPIOA->OSPEEDR = 0x800;
	GPIOA->ODR = GPIOA->ODR ^ (1<<5);

	GPIOC->MODER = (GPIOC->MODER & 0xFFFC0300) | 0x15400;
	GPIOC->OSPEEDR = 0x800;
    GPIOC->PUPDR = 0xAA;
}


int main() {
	GPIO_init();
    NVIC_config();
    EXTI_config();
	while(1) {
		for (int i = 0 ; i < 4 ; i++) {
			col = i;
			GPIOC->ODR = (1 << (i + 5));
		}
	}
	return 0;
}
