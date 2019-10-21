    .syntax unified
    .cpu cortex-m4
    .thumb
.data
    student_id:     .byte   0, 6, 1, 6, 0, 1, 4
.text
.global main

.equ RCC_AHB2ENR,       0x4002104C
.equ GPIOB_MODER,       0x48000400
.equ GPIOB_OTYPER,      0x48000404
.equ GPIOB_OSPEEDR,     0x48000408
.equ GPIOB_PUPDR,       0x4800040C
.equ GPIOB_ODR,         0x48000414
.equ GPIOB_BSRR,        0x48000418
.equ GPIOB_BRR,         0x48000428

.equ DECODE_MODE,       0x09
.equ INTENSITY,         0x0A
.equ SCAN_LIMIT,        0x0B
.equ SHUTDOWN,          0x0C
.equ DISPLAY_TEST,      0x0F

.equ CLOCK,             0x08
.equ DATA,              0x10
.equ LOAD,              0x20

main:
    bl      Initial
Loop:
    bl      Display
    b Loop

Display:
    mov     r4,     #0
DisplayLoop:
    ldr     r2,     =student_id
    mov     r5,     #7
    sub     r3,     r5,     r4
    ldrb    r1,     [r2,    r4]
    add     r4,     r4,     #1
    mov     r0,     r3
    bl      MAX7219Send
    cmp     r4,     #7
    bne     DisplayLoop
    bx      lr

Initial:
    push    {lr}
    bl      GPIO_init
    bl      max7219_init
    pop     {pc}

GPIO_init:
    push    {lr}
    bl      set_RCC_AHB2ENR
    bl      set_GPIO_MODER
    bl      set_GPIO_OSPEEDR
    pop     {pc}

set_RCC_AHB2ENR:
    mov     r1,     #0x2                                //  Set PB on
    ldr     r0,     =RCC_AHB2ENR                        //  Load RCC address
    str     r1,     [r0]                                //  Store back to RCC address
    bx      lr

set_GPIO_MODER:
    ldr     r0,     =GPIOB_MODER                        //  Load MODER address
    ldr     r1,     [r0]                                //  Load MODER current value
    and     r1,     #0xFFFFF03F                         //  Clear target address
    orr     r1,     #0x00000540                         //  Write into target address
    ldr     r0,     =GPIOB_MODER                        //  Load MODER address
    str     r1,     [r0]                                //  Store back to MODER address
    bx      lr

set_GPIO_OSPEEDR:
    mov     r1,     #0x800                              //  Set ouput speed
    ldr     r0,     =GPIOB_OSPEEDR                      //  Load OSPEEDR address
    strh    r1,     [r0]                                //  Store back to OSPEEDR address
    bx      lr

max7219_init:
    push    {lr}
    ldr     r0,     =#DECODE_MODE
    ldr     r1,     =#0xFF
    bl      MAX7219Send
    ldr     r0,     =#DISPLAY_TEST
    ldr     r1,     =#0x0
    bl      MAX7219Send
    ldr     r0,     =#SCAN_LIMIT
    ldr     r1,     =#0x6
    bl      MAX7219Send
    ldr     r0,     =#INTENSITY
    ldr     r1,     =#0xA
    bl      MAX7219Send
    ldr     r0,     =#SHUTDOWN
    ldr     r1,     =#0x1
    bl      MAX7219Send
    mov     r4,     #0
max7219_initLoop:
    add     r4,     r4,     #1
    mov     r0,     r4
    mov     r1,     #0
    bl      MAX7219Send
    cmp     r4,     #8
    bne     max7219_initLoop
    pop     {pc}

MAX7219Send:
    lsl     r0,     r0,     #8
    add     r1,     r0,     r1
    mov     r2,     #16
MAX7219SendLoop:
    ldr     r3,     =#CLOCK
    ldr     r0,     =GPIOB_BRR
    str     r3,     [r0]
    sub     r2,     r2,     #1
    mov     r3,     #1
    lsl     r3,     r3,     r2
    tst     r1,     r3
    beq     bit_not_set
    ldr     r3,     =#DATA
    ldr     r0,     =GPIOB_BSRR
    str     r3,     [r0]
    b       done
bit_not_set:
    ldr     r3,     =#DATA
    ldr     r0,     =GPIOB_BRR
    str     r3,     [r0]
done:
    ldr     r3,     =#CLOCK
    ldr     r0,     =GPIOB_BSRR
    str     r3,     [r0]
    cmp     r2,     #0
    bne     MAX7219SendLoop
    ldr     r3,     =#LOAD
    ldr     r0,     =GPIOB_BRR
    str     r3,     [r0]
    ldr     r3,     =#LOAD
    ldr     r0,     =GPIOB_BSRR
    str     r3,     [r0]
    bx      lr
    



.bss
