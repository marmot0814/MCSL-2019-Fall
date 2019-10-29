    .syntax unified
    .cpu cortex-m4
    .thumb
.text
.global main
.global Systick_Handler
.global UsageFault_Handler
.equ RCC_AHB2ENR, 0x4002104C
.equ GPIOB_MODER, 0x48000000
.equ GPIOB_OTYPER, 0x48000004
.equ GPIOB_OSPEEDR, 0x48000008
.equ GPIOB_PUPDR, 0x4800000C
.equ GPIOB_ODR, 0x48000014
.equ SYST_CSR, 0xE000E010
.equ SYST_RVR, 0xE000E014

.thumb_func
.align 4
Systick_Handler:
    ldr r3, =leds
    ldrb r0, [r3]
    ldr r1, =GPIOB_ODR
    teq r0, #0x0
    beq turnon
    movs r2, #0x0
    str r2, [r1]
    strb r2, [r3]
    bx lr
turnon:
    movs r2, #(1<<5)
    str r2, [r1]
    movs r2, #0x1
    strb r2, [r3]
    bx lr
    
.thumb_func
main:
.align 4
    movs r0, #0x1
    ldr r1, =RCC_AHB2ENR
    str r0, [r1]

    // movs r0, #0x1540
    movs r0, #0x400
    ldr r1, =GPIOB_MODER
    ldr r2, [r1]
    // and r2, #0xFFFFC03F
    and r2, #0xFFFFF3FF
    orrs r2, r2, r0
    str r2, [r1]

    movs r0, #0x800
    ldr r1, =GPIOB_OSPEEDR
    strh r0, [r1]

    movs r0, #0x01
    lsl r0, #19
    ldr r1, =SYST_RVR
    str r0, [r1]

    movs r0, #0x03
    ldr r1, =SYST_CSR
    str r0, [r1]
program_end:
    nop
    b program_end

.bss
.data
    .global leds
    leds: .byte 0x0
