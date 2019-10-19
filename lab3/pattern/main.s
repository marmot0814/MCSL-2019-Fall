    .syntax unified
    .cpu cortex-m4
    .thumb
.data
    leds: .byte 0
.text
.global main

.equ RCC_AHB2ENR, 0x4002104C
.equ GPIOB_MODER, 0x48000400
.equ GPIOB_OTYPER, 0x48000404
.equ GPIOB_OSPEEDR, 0x48000408
.equ GPIOB_PUPDR, 0x4800040C
.equ GPIOB_ODR, 0x48000414


main:
    bl      GPIO_init
    movs    r1,     #0
    ldr     r0,     =leds
    strb    r1,     [r0]
    movs    r4,     #1

Loop:
    bl      DisplayLED
    bl      Delay
    b       Loop

GPIO_init:
    movs    r0,     #0x2
    ldr     r1,     =RCC_AHB2ENR
    str     r0,     [r1]

    movs    r0,     #0x55
    lsl     r0,     r0,     #6
    ldr     r1,     =GPIOB_MODER
    ldr     r2,     [r1]
    and     r2,     #0xFFFFC03F
    orrs    r2,     r2,     r0
    str     r2,     [r1]

    movs    r0,     #0x800
    ldr     r1,     =GPIOB_OSPEEDR
    strh    r0,     [r1]

    bx      lr

DisplayLED:
    ldr     r1,     =GPIOB_ODR
    movs    r0,     #0xC
    ldr     r2,     =leds
    ldr     r3,     [r2]
    lsl     r0,     r0,     r3
    mvn     r0,     r0
    strh    r0,     [r1]
    add     r3,     r3,     r4
    str     r3,     [r2]
    cmp     r3,     #0
    beq     ReverseDiff
    cmp     r3,     #4
    beq     ReverseDiff
    bx      lr
ReverseDiff:
    mvn     r4,     r4
    add     r4,     r4,     #1
    bx      lr

Delay:
    movs    r0,     #1
    lsl     r0,     r0,     #16
DelayLoop:
    cmp     r0,     #0
    beq     end
    sub     r0,     r0,     #1
    b       DelayLoop
end:
    bx      lr
