    .syntax unified
    .cpu cortex-m4
    .thumb
.text
    m: .word 918
    n: .word 1323
.global main

//  int gcd(int a, int b) {
//      if (b == 0) return a;
//      return gcd(b, a % b);
//  }

gcd:
    push {r0, r1, lr}
    cmp r1, #0
    bne cntn
    ldr r1, =result
    str r0, [r1]
    pop  {r0, r1, pc}
cntn:
    sdiv r2, r0, r1
    mul r2, r2, r1
    sub r2, r0, r2
    mov r0, r1
    mov r1, r2
    bl gcd
    pop  {r0, r1, pc}

main:
    ldr R0, =m
    ldr R0, [R0]
    ldr R1, =n
    ldr R1, [R1]
    bl gcd
    b main

.bss
.data
    result: .word 0
    max_size:   .word 0
