    .syntax unified
    .cpu cortex-m4
    .thumb
.data
    user_stack: .zero 128
    expr_result: .word 0
.text
.global main
postfix_expr: .asciz "70   1 + 2 -"
.word 0

.align 4
load_nxt:
    ldrb r2, [r0], #0x01
    ldrb r3, [r0], #0x01
    b loop_1
main:
    ldr r0, =(user_stack+128)
    msr PSP, r0
    mrs r0, CONTROL
    orr r0, r0, 0x02
    msr CONTROL, r0
    ldr r0, =postfix_expr
    ldrb r2, [r0], #0x01
    ldrb r3, [r0], #0x01
loop_1:
    teq r2, #0x00
    beq loop_1_end
    teq r2, #' '
    beq load_nxt
    teq r3, #' '
    bne reg_num
    cmp r2, #0x30
    blt op_start
reg_num:
    teq r3, #0x00
    bne read_number
op_start:
    teq r2, #'+'
    beq op_add
    teq r2, #'-'
    beq op_sub

op_add:
    pop {r4, r5}
    adds r4, r4, r5
    push {r4}
    b op_end
op_sub:
    pop {r4, r5}
    subs r4, r5, r4
    push {r4}
    b op_end
op_end:
    ldrb r2, [r0], #1
    ldrb r3, [r0], #1
    b loop_1

read_number:
    bl atoi
    push {r1}
    b loop_1
loop_1_end:
    pop {r0}
    ldr r1, =expr_result
    str r0, [r1]
    b program_end

program_end:
    nop
    b program_end

atoi:
    mov r1, #0x00 // result
    mov r3, #0x30 // '0'
    mov r4, #0x01 // one
    mov r5, #0x0A
    ldrb r2, [r0, #-2]
    adds r0, #0x01
loop_2:
    teq r2, #' '
    beq loop_2_end
    teq r2, #0x00
    beq loop_2_end
    teq r2, #'-'
    bne append_digit
    ldrb r2, [r0, #-2]
    adds r0, #0x01
    mov r4, #-1
append_digit:
    muls r1, r1, r5
    subs r2, r2, r3
    adds r1, r1, r2
    ldrb r2, [r0, #-2]
    adds r0, #0x01
    b loop_2
loop_2_end:
    muls r1, r1, r4
    subs r0, #2
    ldrb r2, [r0], #1
    ldrb r3, [r0], #1
    bx lr
