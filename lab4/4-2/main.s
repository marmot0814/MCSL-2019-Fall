    .syntax unified
    .cpu cortex-m4
    .thumb
.text
.global main

.equ RCC_AHB2ENR,   0x4002104C
.equ GPIOB_MODER,   0x48000400
.equ GPIOB_OTYPER,  0x48000404
.equ GPIOB_OSPEEDR, 0x48000408
.equ GPIOB_PUPDR,   0x4800040C
.equ GPIOB_ODR,     0x48000414
.equ SYST_CSR,      0xE000E010
.equ SYST_RVR,      0xE000E014

.thumb_func
main:
    movs r0,#(AA&0xFF)
    orrs r0, r0,#(AA&0xFF00)
    movs r1,#20
    adds r2,r0,r1
    b main

.bss
.data
    .global A
    A: .word 0xAA
