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

.equ GPIOC_MODER,   0x48000800
.equ GPIOC_OTYPER,  0x48000804
.equ GPIOC_OSPEEDR, 0x48000808
.equ GPIOC_PUPDR,   0x4800080C
.equ GPIOC_ODR,     0x48000814

.equ SYST_CSR,      0xE000E010
.equ SYST_RVR,      0xE000E014

.thumb_func
main:
    bl GPIO_init
    bl MAX7219_init
    mov     r4,     #0x6
loop:
    mov     r0,     r4
    add     r0,     #0x01
    ldr     r1,     =student_id
    subs    r1,     r1,     r4
    adds    r1,     r1,     #0x06
    ldrb    r1,     [r1]
    push    {r4}
    bl      send_packet
    pop     {r4}
    subs    r4,     r4,     #0x1
    bge     loop

loop_end:
    b       loop_end

GPIO_init:
    // Enable AHB2 clock for GPIOB
    ldr     r0,     =RCC_AHB2ENR
    ldr     r1,     [r0]
    orr     r1,     r1,     #0x06
    str     r1,     [r0]

    // Set GPIO PB3,4,5 as output
    ldr     r0,     =GPIOB_MODER
    ldr     r1,     [r0]
    and     r1,     r1,     #0xFFFFF03F
    orr     r1,     r1,     #0x540
    str     r1,     [r0]

    // Set GPIO PC13 as input
    ldr     r0,     =GPIOC_MODER
    ldr     r1,     [r0]
    and     r1,     r1,     #0xFCFFFFFF
    orr     r1,     r1,     #0x00
    str     r1,     [r0]

    // Set pull up mode
    ldr     r0,     =GPIOC_PUPDR
    ldr     r1,     [r0]
    orr     r1,     r1,     #0x04000000
    str     r1,     [r0]
    bx lr

MAX7219_init:
    mov     r0,     #0x0C
    mov     r1,     #0x01
    push    {lr}
    bl      send_packet
    pop     {lr}
    // Scan all digits
    mov     r0,     #0x0B
    mov     r1,     #0x07
    push    {lr}
    bl      send_packet
    pop     {lr}
    // Decode mode
    mov     r0,     #0x09
    mov     r1,     #0xFF
    push    {lr}
    bl      send_packet
    pop     {lr}
    bx lr

send_packet:
    rbit    r0,     r0
    rbit    r1,     r1
    lsr     r0,     r0,     #0x18
    lsr     r1,     r1,     #0x10
    orr     r0,     r0,     r1
    movs    r4,     r0
    movs    r6,     #0x00
loop_send:
    teq     r6,     #0x10
    beq     loop_send_end
    mov     r5,     #0x00
    and     r7,     r4,     #0x01
    orr     r5,     r5,     r7
    lsl     r7,     r5,     #0x03

    ldr     r0,     =GPIOB_ODR
    str     r7,     [r0]

    eor     r5,     r5,     #0x04
    lsl     r7,     r5,     #0x03
    str     r7,     [r0]

    add     r6,     #0x01
    lsr     r4,     #0x01
    b loop_send
loop_send_end:
    ldr     r0,     =GPIOB_ODR
    mov     r5,     #0x10
    str     r5,     [r0]
    mov     r5,     #0x30
    str     r5,     [r0]
    bx      lr

.bss
.data
    student_id: .byte 0, 6, 1, 6, 0, 6, 9
