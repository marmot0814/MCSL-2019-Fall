    .syntax unified
    .cpu cortex-m4
    .thumb
.text
.global main
.equ AA, 0x55AA

main:
    movs r0,#(AA&0xFF)
    orrs r0, r0,#(AA&0xFF00)
    movs r1,#20
    adds r2,r0,r1
    b main
