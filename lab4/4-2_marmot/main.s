    .syntax unified
    .cpu cortex-m4
    .thumb
.data
        student_id:             .byte   0,  6,  1,  6,  0,  1,  4
.text
.global main

.equ    RCC_AHB2ENR,            0x4002104C

.equ    GPIOB_BASE,             0x48000400

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

.equ    DECODE_MODE,            0x09
.equ    INTENSITY,              0x0A
.equ    SCAN_LIMIT,             0x0B
.equ    SHUTDOWN,               0x0C
.equ    DISPLAY_TEST,           0x0F

.equ    CLOCK,                  0x08
.equ    DATA,                   0x10
.equ    LOAD,                   0x20

main:
    bl      Init
    bl      Display
Loop:
    b       Loop

Init:
    push    {lr}
    bl      GPIOInit
    bl      MAX7219Init
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
    and     r2,     #0xFFFFF03F
    orr     r2,     #0x00000540
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

MAX7219Init:
    push    {lr}
    bl      SetMAX7219_DECODE_MODE
    bl      SetMAX7219_DISPLAY_TEST
    bl      SetMAX7219_SCAN_LIMIT
    bl      SetMAX7219_INTENSITY
    bl      SetMAX7219_SHUTDOWN
    bl      ResetMAX7219Digit
    pop     {pc}

SetMAX7219_DECODE_MODE:
    push    {r0,    r1,     lr}
    ldr     r0,     =DECODE_MODE
    ldr     r1,     =#0xFF
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

SetMAX7219_DISPLAY_TEST:
    push    {r0,    r1,     lr}
    ldr     r0,     =DISPLAY_TEST
    ldr     r1,     =#0x00
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

SetMAX7219_SCAN_LIMIT:
    push    {r0,    r1,     lr}
    ldr     r0,     =SCAN_LIMIT
    ldr     r1,     =#0x06
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

SetMAX7219_INTENSITY:
    push    {r0,    r1,     lr}
    ldr     r0,     =INTENSITY
    ldr     r1,     =#0x0A
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

SetMAX7219_SHUTDOWN:
    push    {r0,    r1,     lr}
    ldr     r0,     =#SHUTDOWN
    ldr     r1,     =#0x01
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

ResetMAX7219Digit:
    push    {r0,    r1,     lr}
    mov     r0,     #8
    mov     r1,     #0
ResetMAX7219DigitLoop:
    bl      MAX7219Send
    subs    r0,     r0,     #1
    bne     ResetMAX7219DigitLoop
    pop     {r0,    r1,     pc}

MAX7219Send:
    push    {r0,    r1,     r2,     lr}
    lsl     r0,     r0,     #8
    orr     r0,     r0,     r1
    rbit    r0,     r0
    lsr     r0,     #16
    mov     r1,     #16
MAX7219SendLoop:
    ldr     r2,     =CLOCK
    bl      BitReset
    ldr     r2,     =DATA
    tst     r0,     #1
    it      ne
    blne    BitSet
    it      eq
    bleq    BitReset
    ldr     r2,     =CLOCK
    bl      BitSet
    lsr     r0,     r0,     #1
    subs    r1,     r1,     #1
    bne     MAX7219SendLoop
    ldr     r2,     =LOAD
    bl      BitSet
    bl      BitReset
    pop     {r0,    r1,     r2,     pc}

BitSet:
    push    {r0,    r1,     lr}
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_BSRR_OFFSET
    str     r2,     [r0,    r1]
    pop     {r0,    r1,     pc}

BitReset:
    push    {r0,    r1,     lr}
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_BRR_OFFSET
    str     r2,     [r0,    r1]
    pop     {r0,    r1,     pc}

Display:
    push    {r0,    r1,     r2,     lr}
    ldr     r2,     =student_id
    mov     r3,     #0
    mov     r0,     #7
DisplayLoop:
    ldrb    r1,     [r2,    r3]
    bl      MAX7219Send
    sub     r0,     r0,     #1
    add     r3,     r3,     #1
    cmp     r3,     #7
    bne     DisplayLoop
    pop     {r0,    r1,     r2,     pc}
