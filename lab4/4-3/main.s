    .syntax unified
    .cpu cortex-m4
    .thumb
.data
    delay_counter:      .word   0
    status:             .word   0
    btn_prev:           .word   0
    btn_counter:        .word   0
    btn_chgOrNot:       .word   0
    btn_bounce_limit:   .word   64
    btn_reset_limit:    .word   4096
    arr:   .byte    0x7e, 0x30, 0x6d, 0x79, 0x33, 0x5b, 0x5f, 0x70, 0x7f, 0x7b, 0x77, 0x1f, 0x4e, 0x3d, 0x4f, 0x47
    fib1:               .word   0
    fib2:               .word   1
    display_bound:      .word   100000000
.text
.global main

.equ RCC_AHB2ENR,       0x4002104C
.equ GPIOB_MODER,       0x48000400
.equ GPIOB_OTYPER,      0x48000404
.equ GPIOB_OSPEEDR,     0x48000408
.equ GPIOB_PUPDR,       0x4800040C
.equ GPIOB_ODR,         0x48000414
.equ GPIOB_BSRR,        0x48000418
.equ GPIOB_BRR,         0x48000428

.equ GPIOC_MODER,       0x48000800
.equ GPIOC_OSPEEDR,     0x48000808
.equ GPIOC_IDR,         0x48000810


.equ DECODE_MODE,       0x09
.equ INTENSITY,         0x0A
.equ SCAN_LIMIT,        0x0B
.equ SHUTDOWN,          0x0C
.equ DISPLAY_TEST,      0x0F

.equ CLOCK,             0x08
.equ DATA,              0x10
.equ LOAD,              0x20

main:
    bl      Initial
Loop:
    bl      ReadBtn
    ldr     r0,     =status
    ldr     r1,     [r0]
    cmp     r1,     #0
    beq     SkipUpdateFib
    bl      UpdateFib
SkipUpdateFib:
    mov     r1,     #0
    ldr     r0,     =status
    str     r1,     [r0]
    bl      Display
    b Loop

UpdateFib:
    ldr     r0,     =fib1
    ldr     r1,     [r0]
    ldr     r0,     =display_bound
    ldr     r2,     [r0]
    cmp     r1,     r2
    bgt     UpdateFibEnd
    ldr     r0,     =fib2
    ldr     r2,     [r0]
    add     r3,     r1,     r2
    ldr     r0,     =fib1
    str     r2,     [r0]
    ldr     r0,     =fib2
    str     r3,     [r0]
UpdateFibEnd:
    bx      lr

Display:
    push    {lr}
    ldr     r0,     =fib1
    ldr     r1,     [r0]
    ldr     r0,     =display_bound
    ldr     r2,     [r0]
    cmp     r1,     r2
    bgt     DisplayError
    ldr     r0,     =fib1
    ldr     r1,     [r0]
    cmp     r1,     #0
    beq     DisplayZero
    ldr     r0,     =fib1
    ldr     r5,     [r0]
    mov     r2,     #0
DisplayLoop:
    add     r2,     r2,     #1
    cmp     r5,     #0
    beq     DisplayEnd
    mov     r4,     #10
    udiv    r3,     r5,     r4
    mul     r3,     r3,     r4
    sub     r1,     r5,     r3
    ldr     r0,     =arr
    ldrb    r1,     [r0,    r1]
    mov     r0,     r2
    bl      MAX7219Send
    udiv    r5,     r5,     r4
    b       DisplayLoop
DisplayEnd:
    pop     {pc}
DisplayZero:
    mov     r6,     #1
    bl      ClearBoard
    ldr     r0,     =arr
    ldrb    r1,     [r0,    #0]
    mov     r0,     #0x01
    bl      MAX7219Send
    pop     {pc}
DisplayError:
    mov     r6,     #2
    bl      ClearBoard
    ldr     r0,     =arr
    ldrb    r1,     [r0,   #1]
    mov     r0,     #0x01
    bl      MAX7219Send
    mov     r0,     #0x02
    mov     r1,     #0x01
    bl      MAX7219Send
    pop     {pc}

ClearBoard:
    push    {r0, r1, r4, lr}
    mov     r4,     r6
ClearBoardLoop:
    add     r4,     r4,     #1
    mov     r0,     r4
    mov     r1,     #0
    bl      MAX7219Send
    cmp     r4,     #8
    bne     ClearBoardLoop
    pop     {r0, r1, r4, pc}

Initial:
    push    {lr}
    bl      GPIO_init
    bl      max7219_init
    pop     {pc}

GPIO_init:
    push    {lr}
    bl      set_RCC_AHB2ENR
    bl      set_GPIO_MODER
    bl      set_GPIO_OSPEEDR
    pop     {pc}

set_RCC_AHB2ENR:
    mov     r1,     #0x6                                //  Set PB and PC on
    ldr     r0,     =RCC_AHB2ENR                        //  Load RCC address
    str     r1,     [r0]                                //  Store back to RCC address
    bx      lr

set_GPIO_MODER:
    ldr     r0,     =GPIOB_MODER                        //  Load MODER address
    ldr     r1,     [r0]                                //  Load MODER current value
    and     r1,     #0xFFFFC03F                         //  Clear target address
    orr     r1,     #0x00001540                         //  Write into target address
    ldr     r0,     =GPIOB_MODER                        //  Load MODER address
    str     r1,     [r0]                                //  Store back to MODER address
    ldr     r0,     =GPIOC_MODER                        //  Load MODER address
    ldr     r1,     [r0]                                //  Load MODER current value
    and     r1,     #0xF3FFFFFF                         //  Set P13 into input mode
    ldr     r0,     =GPIOC_MODER                        //  Load MODER address
    str     r1,     [r0]                                //  Store back to MODER address
    bx      lr

set_GPIO_OSPEEDR:
    mov     r1,     #0x800                              //  Set ouput speed
    ldr     r0,     =GPIOB_OSPEEDR                      //  Load OSPEEDR address
    strh    r1,     [r0]                                //  Store back to OSPEEDR address
    mov     r1,     #0x800                              //  Set ouput speed
    ldr     r0,     =GPIOC_OSPEEDR                      //  Load OSPEEDR address
    strh    r1,     [r0]                                //  Store back to OSPEEDR address
    bx      lr

max7219_init:
    push    {lr}
    ldr     r0,     =#DECODE_MODE
    ldr     r1,     =#0x00
    bl      MAX7219Send
    ldr     r0,     =#DISPLAY_TEST
    ldr     r1,     =#0x0
    bl      MAX7219Send
    ldr     r0,     =#SCAN_LIMIT
    ldr     r1,     =#0x7
    bl      MAX7219Send
    ldr     r0,     =#INTENSITY
    ldr     r1,     =#0xA
    bl      MAX7219Send
    ldr     r0,     =#SHUTDOWN
    ldr     r1,     =#0x1
    bl      MAX7219Send
    mov     r4,     #0
max7219_initLoop:
    add     r4,     r4,     #1
    mov     r0,     r4
    mov     r1,     #0
    bl      MAX7219Send
    cmp     r4,     #8
    bne     max7219_initLoop
    pop     {pc}

MAX7219Send:
    push    {r0, r1, r2, r3, lr}
    lsl     r0,     r0,     #8
    add     r1,     r0,     r1
    mov     r2,     #16
MAX7219SendLoop:
    ldr     r3,     =#CLOCK
    ldr     r0,     =GPIOB_BRR
    str     r3,     [r0]
    sub     r2,     r2,     #1
    mov     r3,     #1
    lsl     r3,     r3,     r2
    tst     r1,     r3
    beq     bit_not_set
    ldr     r3,     =#DATA
    ldr     r0,     =GPIOB_BSRR
    str     r3,     [r0]
    b       done
bit_not_set:
    ldr     r3,     =#DATA
    ldr     r0,     =GPIOB_BRR
    str     r3,     [r0]
done:
    ldr     r3,     =#CLOCK
    ldr     r0,     =GPIOB_BSRR
    str     r3,     [r0]
    cmp     r2,     #0
    bne     MAX7219SendLoop
    ldr     r3,     =#LOAD
    ldr     r0,     =GPIOB_BRR
    str     r3,     [r0]
    ldr     r3,     =#LOAD
    ldr     r0,     =GPIOB_BSRR
    str     r3,     [r0]
    pop     {r0, r1, r2, r3, pc}

ReadBtn:
    ldr     r0,     =GPIOC_IDR                          //  Load IDR address
    ldr     r1,     [r0]                                //  Load IDR value
    ands    r1,     #(1<<13)                            //  Get 13rd bit
    beq     BtnPushed                                   //  If 13rd bit is zero, btn be pushed
    ldr     r0,     =btn_prev                           //  Load btn_prev address
    ldr     r1,     [r0]                                //  Load btn_prev value
    cmp     r1,     #1                                  //  If btn_prev is one
    beq     AddCounter                                  //  Add counter
    bne     ResetCounter                                //  Otherwise, Reset counter
BtnPushed:
    ldr     r0,     =btn_prev                           //  Load btn_prev address
    ldr     r1,     [r0]                                //  Load btn_prev value
    cmp     r1,     #0                                  //  If btn_prev is zero
    beq     AddCounter                                  //  Add counter
    bne     ResetCounter                                //  Otherwuse, Reset counter
AddCounter:
    ldr     r0,     =btn_counter                        //  Load btn_counter address
    ldr     r1,     [r0]                                //  Load btn_counter value
    add     r1,     r1,     #1                          //  add counter
    ldr     r0,     =btn_counter                        //  Load btn_counter address
    str     r1,     [r0]                                //  Store back to btn_counter address
    b       HandleStatus                                //  goto HandleOutputMask
ResetCounter:
    mov     r1,     #0                                  //  Set btn_counter into zero
    ldr     r0,     =btn_counter                        //  Load btn_counter address
    str     r1,     [r0]                                //  Store back to btn_counter address
    ldr     r0,     =btn_prev                           //  Load btn_prev address
    ldr     r1,     [r0]                                //  Load btn_prev value
    eor     r1,     #1                                  //  Reverse btn_prev value
    ldr     r0,     =btn_prev                           //  Load btn_prev address
    str     r1,     [r0]                                //  Store back to btn_prev address
    b       HandleStatus                                //  goto HandleOutputMask
HandleStatus:
    ldr     r0,     =btn_counter                        //  Load btn_counter address
    ldr     r1,     [r0]                                //  Load btn_counter value
    ldr     r0,     =btn_bounce_limit                   //  Load btn_bounce_limit address
    ldr     r2,     [r0]                                //  Load btn_bounce_limit value
    cmp     r1,     r2                                  //  compare counter and bounce_limit
    blt     ReadBtnEnd                                  //  If less than, ignore signal
    ldr     r0,     =btn_prev                           //  Load btn_prev address
    ldr     r1,     [r0]                                //  Load btn_prev value
    cmp     r1,     #0                                  //  compare btn_prev value
    beq     PushedSignal
    bne     UnPushedSignal
PushedSignal:
    ldr     r0,     =btn_counter                        //  Load btn_counter address
    ldr     r1,     [r0]                                //  Load btn_counter value
    ldr     r0,     =btn_reset_limit                    //  Load btn_reset_limit address
    ldr     r2,     [r0]                                //  Load btn_reset_limit value
    cmp     r1,     r2
    bgt     ResetFib
    ldr     r0,     =btn_chgOrNot                       //  Load btn_chgOrNot address
    ldr     r1,     [r0]                                //  Load btn_chgOrNot value
    cmp     r1,     #0                                  //  compare chgOrNot value
    bne     ReadBtnEnd                                  //  If changed, goto ReadBtnEnd
    mov     r1,     #1                                  //  Set btn_chgOrNot into 1
    ldr     r0,     =btn_chgOrNot                       //  Load btn_chgOrNot address
    str     r1,     [r0]                                //  Store back to btn_chgOrNot address
    ldr     r0,     =status                             //  Load output_mask address
    ldr     r1,     [r0]                                //  Load output_mask address
    mov     r1,     #1                                  //  Set Status into 1
    ldr     r0,     =status                             //  Load output_mask address
    str     r1,     [r0]                                //  Store back to output_mask address
    b       ReadBtnEnd
UnPushedSignal:
    mov     r1,     #0                                  //  Set btn_chgOrNot into zero
    ldr     r0,     =btn_chgOrNot                       //  Load btn_chgOrNot address
    str     r1,     [r0]                                //  Store back to btn_chgOrNot address
    b ReadBtnEnd
ResetFib:
    mov     r1,     #0
    ldr     r0,     =fib1
    str     r1,     [r0]
    mov     r1,     #1
    ldr     r0,     =fib2
    str     r1,     [r0]
ReadBtnEnd:
    bx      lr

.bss
