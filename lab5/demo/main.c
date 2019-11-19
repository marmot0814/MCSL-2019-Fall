#include "inc/stm32l476xx.h"
#define max(a, b) (a < b ? b : a)
extern void max7219_send(int addr, int data);

void GPIO_init(int idx) {
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOCEN;
	GPIOB->MODER = (GPIOB->MODER & 0xFFF0003F) | 0x540;
    if (idx == 1)
	    GPIOB->MODER |= 0x55000;
	GPIOB->OSPEEDR = 0xA80;
    if (idx == 0)
    	GPIOB->PUPDR = 0xAA100;
    else
        GPIOB->PUPDR = 0x100;

	GPIOC->MODER = (GPIOC->MODER & 0xFFFC03FF);
    if (idx == 0)
        GPIOC->MODER |= 0x15400;
	GPIOC->OSPEEDR = 0x2A800;
    if (idx == 1)
        GPIOC->PUPDR = 0x2A800;
}

int arr[2][16] = {
   {1,  2,  3, 10,
    4,  5,  6, 11,
    7,  8,  9, 12,
   15,  0, 14, 13},
  {13, 12, 11, 10,
   14,  9,  6,  3,
    0,  8,  5,  2,
   15,  7,  4,  1}
};

void display(int *x, int x_num) {
    if (x_num == -1) {
        for (int i = 1 ; i <= 8 ; i++)
            max7219_send(i, 0x0F);
        return ;
    }
    int pos = 1;
    for (int i = 0 ; i < x_num ; i++) {
        if (x[i] == 0) {
            max7219_send(pos, 0x00);
            pos++;
        } else {
            while (x[i]) {
                max7219_send(pos, x[i] % 10);
                x[i] /= 10;
                pos++;
            }
        }
    }
    for (; pos <= 8 ; pos++)
        max7219_send(pos, 0x0F);
}
void max7219_init() {
	max7219_send(0x0C, 0x01);
	max7219_send(0x0B, 0x07);
	max7219_send(0x09, 0xFF);
	max7219_send(0x0A, 0x08);
}
int main() {
	GPIO_init(0);
    max7219_init();
    while (1) {
        int press = 0;
        int res[10], res_num = 0;
        for (int t = 0 ; t < 2 ; t++) {
            GPIO_init(t); int sum = 0;
            int num = 0, data[10];
            for (int i = 5 ; i < 9 ; i++) {
                (t == 0 ? GPIOC : GPIOB)->ODR = (1 << (i + t));
                for (int j = 0 ; j < 4 ; j++) {
                    int r = 8 - i + 4 * j;
                    if (((t == 0 ? GPIOB : GPIOC)->IDR >> (j + (1 - t))) & 0x20) {
                        press = 1;
                        data[num++] = arr[t][r];
                    }
                }
            }
            if (res_num < num) {
                res_num = num;
                for (int i = 0 ; i < res_num ; i++)
                    res[i] = data[i];
            }
        }
        if (press)
            display(res, res_num);
        else
            display(res, -1);
    }
	return 0;
}
