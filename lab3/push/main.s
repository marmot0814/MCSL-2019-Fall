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

.equ GPIOC_MODER, 0x48000800
.equ GPIOC_IDR, 0x48000810


main:
    bl      GPIO_init
    movs    r6,     #0          // prev
    movs    r7,     #0          // output mask
    movs    r8,     #0          // counter
    movs    r9,     #0          // Change Or Not
    movs    r1,     #0
    ldr     r0,     =leds
    strb    r1,     [r0]
    movs    r4,     #1

Loop:
    bl      DisplayLED
    bl      Delay
    b       Loop

GPIO_init:
    movs    r0,     #0x6
    ldr     r1,     =RCC_AHB2ENR
    str     r0,     [r1]

    movs    r0,     #0x55
    lsl     r0,     r0,     #6
    ldr     r1,     =GPIOB_MODER
    ldr     r2,     [r1]
    and     r2,     #0xFFFFC03F
    orrs    r2,     r2,     r0
    str     r2,     [r1]

    ldr     r1,     =GPIOC_MODER
    ldr     r0,     [r1]
    ldr     r2,     =#0xF3FFFFFF
    and     r0,     r2
    str     r0,     [r1]

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
    and     r0,     r7
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

    ldr     r2,     =GPIOC_IDR
    ldr     r3,     [r2]
    mov     r5,     #1
    lsl     r5,     #13
    ands    r3,     r5
    beq     do_pushed
    cmp     r6,     #1
    beq     add_counter
    mov     r8,     #0
    mov     r6,     #1
    b       DelayLoop
do_pushed:
    cmp     r6,     #0
    beq     add_counter
    mov     r8,     #0
    mov     r6,     #0
    b       DelayLoop
add_counter:
    add     r8,     r8,     #1
    cmp     r8,     #(1<<13)
    blt     DelayLoop
    cmp     r6,     #0              // if not pushed
    bne     resetR9                 //   return
    cmp     r9,     #0              // if have changed
    bne     DelayLoop               //   return 
    mov     r9,     #1
    mvn     r7,     r7
    b       DelayLoop
resetR9:
    mov     r9,     #0
    b       DelayLoop

end:
    bx      lr
