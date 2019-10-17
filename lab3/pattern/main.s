    .syntax unified
    .cpu cortex-m4
    .thumb
.text
.global main
.equ RCC_AHB2ENR, 0x4002104C
.equ GPIOB_MODER, 0x48000400
.equ GPIOB_OTYPER, 0x48000404
.equ GPIOB_OSPEEDR, 0x48000408
.equ GPIOB_PUPDR, 0x4800040C
.equ GPIOB_ODR, 0x48000414

main:
    movs    r0, #0x2
    ldr     r1, =RCC_AHB2ENR
    str     r0, [r1]

    movs    r0, #0x55
    lsl     r0, r0, #6
    ldr     r1, =GPIOB_MODER
    ldr     r2, [r1]
    and     r2, #0xFFFFC03F
    orrs    r2, r2, r0
    str     r2, [r1]

    movs    r0, #0x800
    ldr     r1, =GPIOB_OSPEEDR
    strh    r0, [r1]

    ldr     r1, =GPIOB_ODR

L1:
    movs    r0, #1
    lsl     r0, r0, #3
    strh    r0, [r1]
    bl delay

    movs    r0, #3
    lsl     r0, r0, #3
    strh    r0, [r1]
    bl delay

    movs    r0, #3
    lsl     r0, r0, #4
    strh    r0, [r1]
    bl delay

    movs    r0, #3
    lsl     r0, r0, #5
    strh    r0, [r1]
    bl delay

    movs    r0, #1
    lsl     r0, r0, #6
    strh    r0, [r1]
    bl delay

    movs    r0, #3
    lsl     r0, r0, #5
    strh    r0, [r1]
    bl delay

    movs    r0, #3
    lsl     r0, r0, #4
    strh    r0, [r1]
    bl delay

    movs    r0, #3
    lsl     r0, r0, #3
    strh    r0, [r1]
    bl delay

    b L1

delay:
    movs    r0, #1
    lsl     r0, r0, #20
loop:
    cmp     r0, #0
    beq     end
    sub     r0, r0, #1
    b loop
end:
    bx lr

.bss
.data
