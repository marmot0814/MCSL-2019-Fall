#include "inc/stm32l476xx.h"

// use this pragma at handlers

int col = 0;
int freeze = 0, freeze_col;
extern void max7219_send(int, int);

int value[] = {
    1,  2,  3, 10,
    4,  5,  6, 11,
    7,  8,  9, 12,
   15,  0, 14, 13
};

int cnt;
int is_counting = 0;

void delay() {
    int cnt = 400000;
    while (cnt--);
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

void timer_set_pitch(TIM_TypeDef *timer, int arr) {
    static int current_arr = 0;
    if(arr == current_arr) {
        return ;
    }
    current_arr = arr;
    timer->ARR = arr;
    timer->CCR1 = arr/2;
    timer->EGR |= 0x01;
}
int cnt_exti = 0;
void handler_keypad(int val) {
    cnt_exti++;
    SysTick->CTRL |= 1;
    SysTick->VAL = 500000;
    if (!is_counting) {
        is_counting = 1;
        cnt = value[val * 4 + col];
    } else {
        cnt -= value[val * 4 + col];
        if (cnt <= 0)
            timer_set_pitch(TIM2, 15291), is_counting = 0;

    }
    EXTI->PR1 |= 0x0F;
    EXTI->IMR1 = (EXTI->IMR1 & 0xFFFFFFF0);
}

#pragma thumb
void EXTI0_Handler() {
    handler_keypad(0);
    NVIC_ClearPendingIRQ(EXTI0_IRQn);
}

#pragma thumb
void EXTI1_Handler() {
    handler_keypad(1);
    NVIC_ClearPendingIRQ(EXTI1_IRQn);
}

#pragma thumb
void EXTI2_Handler() {
    handler_keypad(2);
    NVIC_ClearPendingIRQ(EXTI2_IRQn);
}

#pragma thumb
void EXTI3_Handler() {
    handler_keypad(3);
    NVIC_ClearPendingIRQ(EXTI3_IRQn);
}

#pragma thumb
void SysTick_Handler() {
    if (is_counting)
        cnt--;
    if (is_counting && cnt <= 0)
        timer_set_pitch(TIM2, 15291), is_counting = 0;
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

void timer_init(TIM_TypeDef *timer) {
    RCC->APB1ENR1 |= 0x01;
    timer->PSC = 0;
    timer->CCMR1 = 0x00000060;
    timer->CCER |= 0x01;
}

void timer_start(TIM_TypeDef *timer) {
    timer->CR1 |= 0x01;
}


int poll_button() {
	static int cnt = 0;
	static int prev = 0;
	int status = GPIOC->IDR & (0x01 << 13);
	if(!status) {
		if(cnt > 1024) {
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


void max7219_init() {
	max7219_send(0x0C, 0x01);
	max7219_send(0x0B, 0x07);
	max7219_send(0x09, 0xFF);
	max7219_send(0x0A, 0x08);
}

void GPIO_init() {
    RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOCEN;

	GPIOB->MODER = (GPIOB->MODER & 0xFFF0003F) | 0x540;
	GPIOB->OSPEEDR = 0xA80;
	GPIOB->PUPDR = 0xAA100;

    GPIOA->MODER = (GPIOA->MODER & 0xFFFFFFFC) | 0x02;
    GPIOA->AFR[0] = (GPIOA->AFR[0] & 0xFFFFFFF0) | 0x01;

    GPIOC->MODER = (GPIOC->MODER & 0xFFFC0300) | 0x15400;
    GPIOC->MODER = (GPIOC->MODER & 0xF3FFFFFF);
    GPIOC->OSPEEDR = 0x800;
    GPIOC->PUPDR = 0xAA;
}


int main() {
    GPIO_init();
    NVIC_config();
    EXTI_config();
    timer_init(TIM2);
    max7219_init();
    timer_start(TIM2);
    SysTick->LOAD = 500000;
	SysTick->CTRL = 2;
    int pressed = 0;
    while(1) {
        for (int i = 0 ; i < 4 ; i++) {
            col = i;
            GPIOC->ODR = (1 << (i + 5));
            if (GPIOC->IDR & 0xF)
                pressed = 1;
            if (!is_counting && poll_button()) {
                timer_set_pitch(TIM2, 0);
            }
        }
        display(cnt_exti);
        if (!pressed)
            EXTI_config();
        pressed = 0;
    }
    return 0;
}
