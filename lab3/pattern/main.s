    .syntax unified
    .cpu cortex-m4
    .thumb
.data
        leds:                   .word   0
        mover:                  .word   1
        delay_counter:          .word   1572864
.text
.global main

.equ    RCC_AHB2ENR,            0x4002104C

.equ    GPIOA_BASE,             0x48000000
.equ    GPIOB_BASE,             0x48000400
.equ    GPIOC_BASE,             0x48000800

.equ    GPIO_MODER_OFFSET,      0x00
.equ    GPIO_OTYPER_OFFSET,     0x04
.equ    GPIO_OSPEEDR_OFFSET,    0x08
.equ    GPIO_PUPDR_OFFSET,      0x0C
.equ    GPIO_IDR_OFFSET,        0x10
.equ    GPIO_ODR_OFFSET,        0x14
.equ    GPIO_BSRR_OFFSET,       0x18
.equ    GPIO_LCKR_OFFSET,       0x1C
.equ    GPIO_AFRL_OFFSET,       0x20
.equ    GPIO_AFRH_OFFSET,       0x24
.equ    GPIO_BRR_OFFSET,        0x28
.equ    GPIO_ASCR_OFFSET,       0x2C

main:
    bl      Init
Loop:
    bl      DisplayLED
    bl      UpdateLEDPosition
    bl      UpdateMover
    bl      Delay
    b       Loop

Init:
    push    {lr}
    bl      GPIOInit
    pop     {pc}

GPIOInit:
    push    {lr}
    bl      SetRCC_AHB2ENR
    bl      SetGPIO_MODER
    bl      SetGPIO_OSPEEDR
    pop     {pc}

SetRCC_AHB2ENR:
    push    {r0,    r1,     lr}
    ldr     r0,     =RCC_AHB2ENR
    mov     r1,     #0x2
    str     r1,     [r0]
    pop     {r0,    r1,     pc}

SetGPIO_MODER:
    push    {lr}
    bl      SetGPIOB_MODER
    pop     {pc}

SetGPIOB_MODER:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_MODER_OFFSET
    ldr     r2,     [r0,    r1]
    and     r2,     #0xFFFFC03F
    orr     r2,     #0x00001540
    str     r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

SetGPIO_OSPEEDR:
    push    {lr}
    bl      SetGPIOB_OSPEEDR
    pop     {pc}

SetGPIOB_OSPEEDR:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_OSPEEDR_OFFSET
    mov     r2,     #0x800
    strh    r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

DisplayLED:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =leds
    ldr     r1,     [r0]
    mov     r2,     #0xC
    lsl     r2,     r2,     r1
    mvn     r2,     r2
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_ODR_OFFSET
    strh    r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

UpdateLEDPosition:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =mover
    ldr     r2,     [r0]
    ldr     r0,     =leds
    ldr     r1,     [r0]
    add     r1,     r1,     r2
    str     r1,     [r0]
    pop     {r0,    r1,     r2,     pc}

UpdateMover:
    push    {r0,    r1,     lr}
    ldr     r0,     =leds
    ldr     r1,     [r0]
    cmp     r1,     #0
    beq     MoverTurnAround
    cmp     r1,     #4
    beq     MoverTurnAround
    pop     {r0,    r1,     pc}
MoverTurnAround:
    ldr     r0,     =mover
    ldr     r1,     [r0]
    mvn     r1,     r1
    add     r1,     r1,     #1
    str     r1,     [r0]
    pop     {r0,    r1,     pc}

Delay:
    push    {r0,    lr}
    ldr     r0,     =delay_counter
    ldr     r0,     [r0]
DelayLoop:
    subs    r0,     #1
    bne     DelayLoop
    pop     {r0,    pc}
