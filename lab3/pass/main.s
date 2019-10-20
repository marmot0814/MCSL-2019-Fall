    .syntax unified
    .cpu cortex-m4
    .thumb
.data
    delay_counter:      .word   0
    status:             .word   0
    btn_prev:           .word   0
    btn_counter:        .word   0
    btn_chgOrNot:       .word   0
    btn_bounce_limit:   .word   1024
    password:           .byte   0b1101

.text
.global main

.equ RCC_AHB2ENR,       0x4002104C

.equ GPIOA_MODER,       0x48000000
.equ GPIOA_OTYPER,      0x48000004
.equ GPIOA_OSPEEDR,     0x48000008
.equ GPIOA_PUPDR,       0x4800000C
.equ GPIOA_ODR,         0x48000014

.equ GPIOB_MODER,       0x48000400
.equ GPIOB_OTYPER,      0x48000404
.equ GPIOB_OSPEEDR,     0x48000408
.equ GPIOB_PUPDR,       0x4800040C
.equ GPIOB_IDR,         0x48000410

.equ GPIOC_MODER,       0x48000800
.equ GPIOC_OTYPER,      0x48000804
.equ GPIOC_OSPEEDR,     0x48000808
.equ GPIOC_PUPDR,       0x4800080C
.equ GPIOC_IDR,         0x48000810

main:
    bl      Initial
Loop:
    bl      ReadBtn
    ldr     r0,     =status                             //  Load status address
    ldr     r1,     [r0]                                //  Load status value
    cmp     r1,     #0                                  //  Compare Status
    beq     Loop                                        //  If not pushed, goto Loop
    bl      CmpPwdAndDisplay                            //  Else, compare password and display
    b       Loop

Initial:
    push    {lr}
    bl      GPIO_init
    pop     {pc}

GPIO_init:
    push    {lr}
    bl      set_ACC_AHB2ENR
    bl      set_GPIO_MODER
    bl      set_GPIO_OSPEEDR
    pop     {pc}

set_ACC_AHB2ENR:
    mov     r1,     #0x7                                //  Set PA and PB on
    ldr     r0,     =RCC_AHB2ENR                        //  Load RCC address
    str     r1,     [r0]                                //  Store back to RCC address
    bx      lr

set_GPIO_MODER:
    ldr     r0,     =GPIOA_MODER                        //  Load MODER address
    ldr     r1,     [r0]                                //  Load MODER current value
    and     r1,     #0xFFFFF3FF                         //  Clear PA5
    orr     r1,     #0x00000400                         //  Set PA5 into 01
    ldr     r0,     =GPIOA_MODER                        //  Load MODER address
    str     r1,     [r0]                                //  Store back to MODER address
    ldr     r0,     =GPIOB_MODER                        //  Load MODER address
    ldr     r1,     [r0]                                //  Load MODER current value
    and     r1,     #0xFFFFC03F                         //  Clear PB3-PB6
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
    ldr     r0,     =GPIOA_OSPEEDR                      //  Load OSPEEDR address
    strh    r1,     [r0]                                //  Store back to OSPEEDR address
    mov     r1,     #0x800                              //  Set ouput speed
    ldr     r0,     =GPIOB_OSPEEDR                      //  Load OSPEEDR address
    strh    r1,     [r0]                                //  Store back to OSPEEDR address
    mov     r1,     #0x800                              //  Set ouput speed
    ldr     r0,     =GPIOB_OSPEEDR                      //  Load OSPEEDR address
    strh    r1,     [r0]                                //  Store back to OSPEEDR address
    bx      lr

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
    b       HandleOutputMask                            //  goto HandleOutputMask
ResetCounter:
    mov     r1,     #0                                  //  Set btn_counter into zero
    ldr     r0,     =btn_counter                        //  Load btn_counter address
    str     r1,     [r0]                                //  Store back to btn_counter address
    ldr     r0,     =btn_prev                           //  Load btn_prev address
    ldr     r1,     [r0]                                //  Load btn_prev value
    eor     r1,     #1                                  //  Reverse btn_prev value
    ldr     r0,     =btn_prev                           //  Load btn_prev address
    str     r1,     [r0]                                //  Store back to btn_prev address
    b       HandleOutputMask                            //  goto HandleOutputMask
HandleOutputMask:
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
ReadBtnEnd:
    bx      lr

CmpPwdAndDisplay:
    push    {lr}
    mov     r1,     #0                                  //  Set status into 0
    ldr     r0,     =status                             //  Load status address
    str     r1,     [r0]                                //  Store back to status address
    ldr     r0,     =GPIOB_IDR                          //  Load GPIOB_IDR address
    ldr     r1,     [r0]                                //  Load GPIOB_IDR value
    mov     r2,     #0xF                                //  Set 1111 mask
    lsl     r2,     r2,     #3                          //  Move to target position
    and     r1,     r2                                  //  Get PB3-PB6 value
    lsr     r1,     r1,     #3                          //  Get Input Password
    eor     r1,     #0xF                                //  Reverse Input Signal
    ldr     r0,     =password                           //  Load password address
    ldr     r2,     [r0]                                //  Load password value
    cmp     r1,     r2                                  //  Compare password
    beq     PwdMatch                                    //  Password Match
    bne     PwdWrong                                    //  Password Wrong
PwdMatch:
    mov     r2,     #3                                  //  Blink 3 times
PwdMatchLoop:
    cmp     r2,     #0                                  //  Compare counter
    beq     PwdMatchEnd                                 //  If finish, goto End
    bl      TurnOn                                      //  TurnOn
    bl      Delay                                       //  Delay
    bl      TurnOff                                     //  TurnOff
    bl      Delay                                       //  Delay
    sub     r2,     r2,     #1                          //  Substract r2 from 1
    b       PwdMatchLoop
PwdMatchEnd:
    pop     {pc}
PwdWrong:
    bl      TurnOn                                      //  TurnOn
    bl      Delay                                       //  Delay
    bl      TurnOff                                     //  TurnOff
    bl      Delay                                       //  Delay
    pop     {pc}

Delay:
    mov     r1,     #(1<<19)                            //  Delay counter
DelayLoop:
    sub     r1,     r1,     #1                          //  Substract r1 from 1
    cmp     r1,     #0                                  //  If r1 equal to zero
    beq     DelayEnd                                    //  Finish Delay
    b       DelayLoop
DelayEnd:
    bx      lr

TurnOn:
    mov     r1,     #(1 << 5)                           //  Turn on PA5
    ldr     r0,     =GPIOA_ODR                          //  Load GPIOA_ODR address
    strh    r1,     [r0]                                //  Store back to GPIOA_ODR
    bx      lr

TurnOff:
    mov     r1,     #0                                  //  Turn off PA5
    ldr     r0,     =GPIOA_ODR                          //  Load GPIOA_ODR address
    strh    r1,     [r0]                                //  Store back to GPIOA_ODR
    bx      lr

.bss
