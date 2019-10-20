    .syntax unified
    .cpu cortex-m4
    .thumb
.data
    leds:   .word 0
    mvr:    .word 1
.text
.global main

.equ RCC_AHB2ENR, 0x4002104C
.equ GPIOB_MODER, 0x48000400
.equ GPIOB_OTYPER, 0x48000404
.equ GPIOB_OSPEEDR, 0x48000408
.equ GPIOB_PUPDR, 0x4800040C
.equ GPIOB_ODR, 0x48000414

main:
    bl      Initial
Loop:
    bl      DisplayLED
    bl      Delay
    b Loop

Initial:
    push    {lr}
    bl      GPIO_init
    bl      GlobalVar_init
    pop     {pc}

GPIO_init:
    push    {lr}
    bl      set_RCC_AHB2ENR
    bl      set_GPIO_MODER
    bl      set_GPIO_OSPEEDR
    pop     {pc}

set_RCC_AHB2ENR:
    ldr     r0,     =RCC_AHB2ENR                        //  Load RCC address
    mov     r1,     #0x2                                //  Turn on PB output
    str     r1,     [r0]                                //  Store 0x2 into RCC
    bx      lr

set_GPIO_MODER:
    ldr     r0,     =GPIOB_MODER                        //  Load MODER address
    ldr     r1,     [r0]                                //  Load MODER current value
    and     r1,     #0xFFFFC03F                         //  Clear target address
    orr     r1,     #0x00001540                         //  Write into target address
    ldr     r0,     =GPIOB_MODER                        //  Load MODER address
    str     r1,     [r0]                                //  Store back to MODER address
    bx      lr

set_GPIO_OSPEEDR:
    ldr     r0,     =GPIOB_OSPEEDR                      //  Load OSPEEDR address
    mov     r1,     #0x800                              //  Set ouput speed
    strh    r1,     [r0]                                //  Store back to OSPEEDR address
    bx      lr
    
GlobalVar_init:
    bx      lr

DisplayLED:
    ldr     r0,     =leds                               //  Load leds offset address
    ldr     r1,     [r0]                                //  Load leds offset value
    mov     r2,     #0xC                                //  Initial LED mask into 1100
    lsl     r2,     r2,     r1                          //  Shift mask left #offset
    mvn     r2,     r2                                  //  Trans into Active Low
    ldr     r0,     =GPIOB_ODR                          //  Load ODR address
    strh    r2,     [r0]                                //  Store back to ODR address
    ldr     r0,     =mvr                                //  Load mover address
    ldr     r2,     [r0]                                //  Load mover value
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
    mov     r1,     #1                                  //  Delay counter
    lsl     r1,     r1,     #16                         //  Delay counter
DelayLoop:
    cmp     r1,     #0                                  //  If counter equal to 0
    beq     end                                         //      goto end
    sub     r1,     r1,     #1                          //  Substract counter to 1
    b       DelayLoop
end:
    bx      lr
