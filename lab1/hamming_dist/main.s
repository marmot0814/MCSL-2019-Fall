    .syntax unified
    .cpu cortex-m4
    .thumb
.text
.global main
.equ X, 0xBE83
.equ Y, 0x39AC

hamm:
    eor R3, R0, R1
    
    movs R4, R3         // x = (x & 0x5555) + ((x >> 1) & 0x5555);
    movs R5, R3
    lsrs R5, R5, #1
    movw R6, 0x5555
    and R4, R4, R6
    and R5, R5, R6
    add R3, R4, R5

    movs R4, R3         // x = (x & 0x3333) + ((x >> 2) & 0x3333);
    movs R5, R3
    lsrs R5, R5, #2
    movw R6, 0x3333
    and R4, R4, R6
    and R5, R5, R6
    add R3, R4, R5

    movs R4, R3         // x = (x & 0x0f0f) + ((x >> 4) & 0x0f0f);
    movs R5, R3
    lsrs R5, R5, #4
    movw R6, 0x0f0f
    and R4, R4, R6
    and R5, R5, R6
    add R3, R4, R5

    movs R4, R3         // x = (x & 0x00ff) + ((x >> 8) & 0x00ff);
    movs R5, R3
    lsrs R5, R5, #8
    movw R6, 0x00ff
    and R4, R4, R6
    and R5, R5, R6
    add R3, R4, R5

    strb R3, [R2]
    bx lr

main:
    movw R0, #X
    movw R1, #Y
    ldr R2, =result
    bl hamm
    b main

.bss
.data
    result: .byte 0
    .global A
    A: .word 0xAA
