    .syntax unified
    .cpu cortex-m4
    .thumb
.data
        submit:                 .word   0
        btn_counter:            .word   0
        btn_prev:               .word   0
        btn_bounce_limit:       .word   1
        btn_chg:                .word   0
        delay_counter:          .word   1572864
        password:               .byte   0b1111

.text
.global main

.equ    RCC_AHB2ENR,            0x4002104C

.equ    GPIOA_BASE,             0x48000000
.equ    GPIOB_BASE,             0x48000400
.equ    GPIOC_BASE,             0x48000800

.equ    GPIO_MODER_OFFSET,      0x00
.equ    GPIO_OTYPER_OFFSET,     0x04
.equ    GPIO_OSPEEDR_OFFSET,    0x08
.equ    GPIO_PUPDR_OFFSET,      0x0C
.equ    GPIO_IDR_OFFSET,        0x10
.equ    GPIO_ODR_OFFSET,        0x14
.equ    GPIO_BSRR_OFFSET,       0x18
.equ    GPIO_LCKR_OFFSET,       0x1C
.equ    GPIO_AFRL_OFFSET,       0x20
.equ    GPIO_AFRH_OFFSET,       0x24
.equ    GPIO_BRR_OFFSET,        0x28
.equ    GPIO_ASCR_OFFSET,       0x2C

main:
    bl      Init
Loop:
    bl      ReadBtn
    ldr     r0,     =submit
    ldr     r1,     [r0]
    cmp     r1,     #0
    beq     Loop
    bl      SubmitPWD
    b       Loop


Init:    
    push    {lr}
    bl      SetRCC_AHB2ENR
    bl      SetGPIO_MODER
    bl      SetGPIO_OSPEEDR
    pop     {pc}

SetRCC_AHB2ENR:
    push    {r0,    r1,     lr}
    ldr     r0,     =RCC_AHB2ENR
    mov     r1,     #0x7
    str     r1,     [r0]
    pop     {r0,    r1,     pc}

SetGPIO_MODER:
    push    {lr}
    bl      SetGPIOA_MODER
    bl      SetGPIOB_MODER
    bl      SetGPIOC_MODER
    pop     {pc}

SetGPIOA_MODER:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOA_BASE
    ldr     r1,     =GPIO_MODER_OFFSET
    ldr     r2,     [r0,    r1]
    and     r2,     #0xFFFFF3FF
    orr     r2,     #0x00000400
    str     r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

SetGPIOB_MODER:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_MODER_OFFSET
    ldr     r2,     [r0,    r1]
    and     r2,     #0xFFFFC03F
    str     r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

SetGPIOC_MODER:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOC_BASE
    ldr     r1,     =GPIO_MODER_OFFSET
    ldr     r2,     [r0,    r1]
    and     r2,     #0xF3FFFFFF
    str     r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

SetGPIO_OSPEEDR:
    push    {lr}
    bl      SetGPIOA_OSPEEDR
    bl      SetGPIOB_OSPEEDR
    bl      SetGPIOC_OSPEEDR
    pop     {pc}

SetGPIOA_OSPEEDR:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOA_BASE
    ldr     r1,     =GPIO_OSPEEDR_OFFSET
    mov     r2,     #0x800
    strh    r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

SetGPIOB_OSPEEDR:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_OSPEEDR_OFFSET
    mov     r2,     #0x800
    strh    r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

SetGPIOC_OSPEEDR:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOC_BASE
    ldr     r1,     =GPIO_OSPEEDR_OFFSET
    mov     r2,     #0x800
    strh    r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

ReadBtn:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOC_BASE
    ldr     r1,     =GPIO_IDR_OFFSET
    ldr     r2,     [r0,    r1]
    ands    r2,     #(1 << 13)
    beq     BtnBePushed
    bne     BtnUnPushed
BtnBePushed:
    ldr     r0,     =btn_prev
    ldr     r1,     [r0]
    cmp     r1,     #0
    beq     AddCounter
    bne     ResetCounter
BtnUnPushed:
    ldr     r0,     =btn_prev
    ldr     r1,     [r0]
    cmp     r1,     #1
    beq     AddCounter
    bne     ResetCounter
AddCounter:
    ldr     r0,     =btn_counter
    ldr     r1,     [r0]
    add     r1,     r1,     #1
    str     r1,     [r0]
    b       HandleBtnSignal
ResetCounter:
    mov     r1,     #0
    ldr     r0,     =btn_counter
    str     r1,     [r0]
    ldr     r0,     =btn_prev
    ldr     r1,     [r0]
    eor     r1,     #1
    str     r1,     [r0]
    b       HandleBtnSignal
HandleBtnSignal:
    ldr     r0,     =btn_counter
    ldr     r1,     [r0]
    ldr     r0,     =btn_bounce_limit
    ldr     r2,     [r0]
    cmp     r1,     r2
    blt     ReadBtnEnd
    ldr     r0,     =btn_prev
    ldr     r1,     [r0]
    cmp     r1,     #0
    beq     BtnBePushedSignal
    bne     BtnUnPushedSignal
BtnBePushedSignal:
    ldr     r0,     =btn_chg
    ldr     r1,     [r0]
    cmp     r1,     #1
    beq     ReadBtnEnd
    mov     r1,     #1
    str     r1,     [r0]
    ldr     r0,     =submit
    mov     r1,     #1
    str     r1,     [r0]
    b       ReadBtnEnd
BtnUnPushedSignal:
    ldr     r0,     =btn_chg
    mov     r1,     #0
    str     r1,     [r0]
    b       ReadBtnEnd
ReadBtnEnd:
    pop     {r0,    r1,     r2,     pc}

SubmitPWD:
    push    {r0,    r1,     r2,     lr}
    bl      ResetSubmit
GetInputPassword:
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_IDR_OFFSET
    ldr     r2,     [r0,    r1]
    lsr     r2,     r2,     #3
    and     r2,     #0xF
    eor     r2,     #0xF
ComparePassword:
    ldr     r0,     =password
    ldr     r1,     [r0]
    cmp     r1,     r2
    beq     PasswordMatch
    bne     PasswordWrong
PasswordMatch:
    mov     r1,     #3
PasswordMatchLoop:
    bl      TurnOnLED
    bl      Delay
    bl      TurnOffLED
    bl      Delay
    subs    r1,     #1
    bne     PasswordMatchLoop
    b       SubmitPWDEnd
PasswordWrong:
    bl      TurnOnLED
    bl      Delay
    bl      TurnOffLED
    bl      Delay
    b       SubmitPWDEnd
SubmitPWDEnd:
    pop     {r0,    r1,     r2,     pc}

ResetSubmit:
    push    {r0,    r1,     lr}
    mov     r1,     #0
    ldr     r0,     =submit
    str     r1,     [r0]
    pop     {r0,    r1,     pc}

Delay:
    push    {r0,    lr}
    ldr     r0,     =delay_counter
    ldr     r0,     [r0]
DelayLoop:
    subs    r0,     #1
    bne     DelayLoop
    pop     {r0,    pc}

TurnOnLED:
    push    {r0,    r1,     r2,     lr}
    mov     r2,     #(1 << 5)
    ldr     r0,     =GPIOA_BASE
    ldr     r1,     =GPIO_ODR_OFFSET
    strh    r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

TurnOffLED:
    push    {r0,    r1,     r2,     lr}
    mov     r2,     #0
    ldr     r0,     =GPIOA_BASE
    ldr     r1,     =GPIO_ODR_OFFSET
    strh    r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}
