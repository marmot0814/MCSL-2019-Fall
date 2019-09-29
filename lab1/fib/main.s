    .syntax unified
    .cpu cortex-m4
    .thumb
.text
.global main
.equ N, 10

fib:
    // check if 1 > N || 100 < N
    movs R4, -1
    movs R1, 1
    cmp R1, R0
    bgt end
    movs R1, 100
    cmp R1, R1
    blt end
    // start fib
    movs R1, 1  // i
    movs R2, 1  // b
    movs R4, 1  // a
loop:
    cmp R1, R0
    bge end
    movs R3, R2
    add R2, R2, R4
    movs R4, R3
    // overflow
    cmp R4, 0
    blt overflow
    add R1, R1, 1
    b loop
overflow:
    movs R4, -2
    b end
end:
    bx lr

main:
    movs R0, #N
    bl fib
