#include "inc/stm32l476xx.h"

// use this pragma at handlers
//#pragma thumb

#define FUNC_ADDR ((uint32_t *)0x08080000U)
#define FUNC_ADDR_THUMB ((uint32_t *)0x08080001U)

char code[] = { 0x80, 0xb4, 0x00, 0xaf, 0x4f, 0xf0, 0x90, 0x43, 0x5b, 0x69, 0x4f, 0xf0, 0x90, 0x42, 0x83, 0xf0,
		0x20, 0x03, 0x53, 0x61, 0x00, 0xbf, 0xbd, 0x46, 0x5d, 0xf8, 0x04, 0x7b, 0x70, 0x47 };

void GPIO_init() {
	RCC->AHB2ENR |= RCC_AHB2ENR_GPIOAEN | RCC_AHB2ENR_GPIOBEN | RCC_AHB2ENR_GPIOCEN;

	GPIOA->MODER = (GPIOA->MODER & 0xFFFFF3FF) | 0x400;
	GPIOA->OSPEEDR = 0x800;

	GPIOC->MODER = (GPIOC->MODER & 0xF3FFFFFF);
	GPIOB->PUPDR = 0x04000000;
}

void flash_init() {
	FLASH->KEYR = 0x45670123;
	FLASH->KEYR = 0xCDEF89AB;
}

void flash_write(uint32_t *data, uint32_t n) {
	while(FLASH->SR & FLASH_SR_BSY);
	FLASH->SR |= FLASH_SR_FASTERR | FLASH_SR_MISERR | FLASH_SR_PGSERR | FLASH_SR_SIZERR |
		FLASH_SR_PGAERR | FLASH_SR_WRPERR | FLASH_SR_PROGERR;
	FLASH->CR &= (~FLASH_CR_PER) & (~FLASH_CR_MER1) & (~FLASH_CR_MER2);
	// Erase the desired region
	uint32_t page = 256, n0 = n;
	FLASH->CR |= FLASH_CR_PER;
	do {
		FLASH->CR = (FLASH->CR & 0xFFFFF807) | (page << 3);
		FLASH->CR |= FLASH_CR_STRT;
		while(FLASH->SR & FLASH_SR_BSY);
	} while(n0 >>= 12);
	FLASH->SR |= FLASH_SR_FASTERR | FLASH_SR_MISERR | FLASH_SR_PGSERR | FLASH_SR_SIZERR |
		FLASH_SR_PGAERR | FLASH_SR_WRPERR | FLASH_SR_PROGERR;
	FLASH->CR &= (~FLASH_CR_PER) & (~FLASH_CR_MER1) & (~FLASH_CR_MER2);

	// Program sequence
	uint32_t *dst_addr = FUNC_ADDR;
	FLASH->CR |= FLASH_CR_PG;
	for(int i=0; i<n; i-=-2) {
		dst_addr[i] = data[i];
		dst_addr[i+1] = data[i+1];
		while(FLASH->SR & FLASH_SR_BSY);
		FLASH->SR |= FLASH_SR_EOP;
	}
	FLASH->CR &= (~FLASH_CR_PG);
}

int main() {
	GPIO_init();
	flash_init();
	flash_write((uint32_t *)code, sizeof(code)/4 + 1);
	void (*fn)() = (void (*)())(FUNC_ADDR_THUMB);
	fn();
	while(1);
	return 0;
}
