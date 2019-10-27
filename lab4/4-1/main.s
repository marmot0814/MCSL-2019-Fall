    .syntax unified
    .cpu cortex-m4
    .thumb
.text
.global main
.global Systick_Handler

.equ RCC_AHB2ENR,   0x4002104C
.equ GPIOB_MODER,   0x48000400
.equ GPIOB_OTYPER,  0x48000404
.equ GPIOB_OSPEEDR, 0x48000408
.equ GPIOB_PUPDR,   0x4800040C
.equ GPIOB_ODR,     0x48000414
.equ SYST_CSR,      0xE000E010
.equ SYST_RVR,      0xE000E014

.thumb_func
Systick_Handler:
    ldr     r0,     =i
    ldr     r1,     [r0]
    add     r1,     #0x01
    teq     r1,     #0x10
    it      eq
    moveq   r1,     #0x00
    str     r1,     [r0]
    bx      lr

.thumb_func
main:
    bl GPIO_init
    bl MAX7219_init
    bl Systick_init
loop:
    mov     r0,     0x01
    ldr     r1,     =arr
    ldr     r4,     =i
    ldr     r4,     [r4]
    add     r1,     r1,     r4
    ldrb    r1,     [r1]
    bl      send_packet
    b       loop

GPIO_init:
    // Enable AHB2 clock for GPIOB
    ldr     r0,     =RCC_AHB2ENR
    ldr     r1,     [r0]
    orr     r1,     r1,     0x02
    str     r1,     [r0]

    // Set GPIO PB3,4,5 as output
    ldr     r0,     =GPIOB_MODER
    ldr     r1,     [r0]
    and     r1,     r1,     0xFFFFF03F
    orr     r1,     r1,     0x540
    str     r1,     [r0]

    mov     r1,     #0xA800
    ldr     r0,     =GPIOB_OSPEEDR
    strh    r1,     [r0]
    bx lr

MAX7219_init:
    mov     r0,     #0x0C
    mov     r1,     #0x01
    push    {lr}
    bl      send_packet
    pop     {lr}
    bx lr

Systick_init:
    movs r0, #0x01
    lsl r0, #19
    ldr r1, =SYST_RVR
    str r0, [r1]

    movs r0, #0x03
    ldr r1, =SYST_CSR
    str r0, [r1]
    bx      lr

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
    .global arr
    arr:    .byte   0x7e, 0x30, 0x6d, 0x79, 0x33, 0x5b, 0x5f, 0x70, 0x7f, 0x7b, 0x77, 0x1f, 0x4e, 0x3d, 0x4f, 0x47
    i:      .word   0
