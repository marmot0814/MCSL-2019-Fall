    .syntax unified
    .cpu cortex-m4
    .thumb
.text
    m: .word 39
    n: .word 65
.global main

//  int gcd(int a, int b) {
//      if (b == 0) return a;
//      return gcd(b, a % b);
//  }

gcd:
    // R0: m
    // R1: n
    // R2: ret
    push {R0, R1, lr}
    cmp R7, sp                  // compare stack pointer
    blt skipUpdateSp
    mov R7, sp
skipUpdateSp:
    cmp R0, #0                  // if (r0 == 0)
    beq gcdR1Ret                // r2 *= r1
    cmp R1, #0                  // if (r1 == 0)
    beq gcdR0Ret                // r2 *= r0
    b cntn
gcdR1Ret:
    mul R2, R2, R1
    b gcdRet
gcdR0Ret:
    mul R2, R2, R0
    b gcdRet
gcdRet:
    pop  {R0, R1, pc}
cntn:
    and R3, R0, #1              // r3 = r0 & 1
    and R4, R1, #1              // r4 = r1 & 1
    orr R5, R3, R4              // r5 = r3 | r4
    cmp R5, #0                  // if (r5 == 0)
    bne else1                   //   
    lsr R0, R0, #1              // r0 /= 2
    lsr R1, R1, #1              // r1 /= 2
    lsl R2, R2, #1              // r2 *= 2
    b endif
else1:
    cmp R3, #0                  // if (r3 == 0)
    bne else2                   
    lsr R0, R0, #1              // r0 /= 2
    b endif
else2:
    cmp R4, #0                  // if (r4 == 0)
    bne else3
    lsr R1, R1, #1              // r1 /= 2
    b endif
else3:
    sub R3, R0, R1              // r3 = r0 - r1
    cmp R3, #0                  // if (r3 < 0)
    bgt skipAbs
    mov R4, #0                  // 
    sub R3, R4, R3              //   r3 = 0 - r3
skipAbs:
    mov R4, R1                  // r4 = r1
    cmp R0, R1                  // if (r0 < r1)
    bgt isR1
    mov R4, R0                  //   r4 = r0
isR1:
    mov R0, R3                  // r0 = r3
    mov R1, R4                  // r1 = r4
    b endif
endif:
    bl gcd
    pop  {R0, R1, pc}

main:
    ldr R0, =m
    ldr R0, [R0]
    ldr R1, =n
    ldr R1, [R1]
    mov R2, #1
    mov R6, sp                  // init stack pointer
    mov R7, sp                  // minimun stack pointer
    bl gcd
    ldr R3, =result
    str R2, [R3]
    ldr R3, =max_size
    sub R6, R6, R7
    str R6, [R3]
    b main

.bss
.data
    result: .word 0
    max_size:   .word 0
