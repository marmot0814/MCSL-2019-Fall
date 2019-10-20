    .syntax unified
    .cpu cortex-m4
    .thumb
.data
    leds:               .word   0
    mvr:                .word   1
    delay_counter:      .word   0
    output_mask:        .word   0
    btn_prev:           .word   0
    btn_counter:        .word   0
    btn_chgOrNot:       .word   0
    btn_bounce_limit:   .word   1024
.text
.global main

.equ RCC_AHB2ENR,       0x4002104C
.equ GPIOB_MODER,       0x48000400
.equ GPIOB_OTYPER,      0x48000404
.equ GPIOB_OSPEEDR,     0x48000408
.equ GPIOB_PUPDR,       0x4800040C
.equ GPIOB_ODR,         0x48000414

.equ GPIOC_MODER,       0x48000800
.equ GPIOC_OSPEEDR,     0x48000808
.equ GPIOC_IDR,         0x48000810

main:
    bl      Initial
Loop:
    bl      DisplayLED
    bl      Delay
    b Loop

Initial:
    push    {lr}
    bl      GPIO_init
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
    
DisplayLED:
    ldr     r0,     =leds                               //  Load leds offset address
    ldr     r1,     [r0]                                //  Load leds offset value
    mov     r2,     #0xC                                //  Initial LED mask into 1100
    lsl     r2,     r2,     r1                          //  Shift mask left #offset
#   disable version begin
#   ldr     r0,     =output_mask                        //  Load output_mask address
#   ldr     r1,     [r0]                                //  Load output_mask value
#   and     r2,     r1                                  //  and with output_mask
#   disable version  end
    mvn     r2,     r2                                  //  Trans into Active Low
    ldr     r0,     =GPIOB_ODR                          //  Load ODR address
    strh    r2,     [r0]                                //  Store back to ODR address

#   running version begin
    ldr     r0,     =output_mask                        //  Load output_mask address
    ldr     r1,     [r0]                                //  Load output_mask value
    cmp     r1,     #0                                  //  Compare output_mask
    bne     Running                                     //  If not zero, running
    bx      lr                                          //  Else, return
Running:
#   running version  end

    ldr     r0,     =mvr                                //  Load mover address
    ldr     r2,     [r0]                                //  Load mover value
    ldr     r0,     =leds                               //  Load leds offset address
    ldr     r1,     [r0]                                //  Load leds offset value
    add     r1,     r1,     r2                          //  Update offset value
    ldr     r0,     =leds                               //  Load leds offset address
    str     r1,     [r0]                                //  Store back to leds offset address
                                                        //  Update move value
    cmp     r1,     #0                                  //  If leds offset value equal to 0
    beq     ReverseMVR                                  //      Reverse mover
    cmp     r1,     #4                                  //  If leds offset value equal to 4
    beq     ReverseMVR                                  //      Reverse mover
    bx      lr
ReverseMVR:
    ldr     r0,     =mvr                                //  Load mover address
    ldr     r1,     [r0]                                //  Load mover value
    mvn     r1,     r1                                  //  Two's complement
    add     r1,     r1,     #1                          //  Two's complement
    ldr     r0,     =mvr                                //  Load mover address
    str     r1,     [r0]                                //  Store back to mover address
    bx      lr
    
Delay:
    push    {lr}
    ldr     r0,     =delay_counter                      //  Load delay_counter address
    mov     r1,     #(1 << 13)                          //  Set delay counter into 1 << 16
    str     r1,     [r0]                                //  Store back to delay_counter address
DelayLoop:
    ldr     r0,     =delay_counter                      //  Load delay_counter addesss
    ldr     r1,     [r0]                                //  Load delay_counter value
    cmp     r1,     #0                                  //  If counter equal to 0
    beq     DelayEnd                                    //      goto DelayEnd
    sub     r1,     r1,     #1                          //  Substract counter to 1
    ldr     r0,     =delay_counter                      //  Load delay_counter address
    str     r1,     [r0]                                //  Store back to delay_counter address
    bl      ReadBtn
    b       DelayLoop
DelayEnd:
    pop     {pc}

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
    ldr     r0,     =output_mask                        //  Load output_mask address
    ldr     r1,     [r0]                                //  Load output_mask address
    mvn     r1,     r1                                  //  Reverse output mask
    ldr     r0,     =output_mask                        //  Load output_mask address
    str     r1,     [r0]                                //  Store back to output_mask address
    b       ReadBtnEnd

UnPushedSignal:
    mov     r1,     #0                                  //  Set btn_chgOrNot into zero
    ldr     r0,     =btn_chgOrNot                       //  Load btn_chgOrNot address
    str     r1,     [r0]                                //  Store back to btn_chgOrNot address
    b ReadBtnEnd

ReadBtnEnd:
    bx      lr
