    .syntax unified
    .cpu cortex-m4
    .thumb
.data
        btn_counter:            .word   0
        btn_prev:               .word   0
        btn_bounce_limit:       .word   2048
        btn_reset_limit:        .word   65536
        btn_chg:                .word   0
        fib1:                   .word   1
        fib2:                   .word   0
        fib_chg:                .word   0
        fib_reset:              .word   0
        display_limit:          .word   100000000
.text
.global main

.equ    RCC_AHB2ENR,            0x4002104C

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

.equ    DECODE_MODE,            0x09
.equ    INTENSITY,              0x0A
.equ    SCAN_LIMIT,             0x0B
.equ    SHUTDOWN,               0x0C
.equ    DISPLAY_TEST,           0x0F

.equ    CLOCK,                  0x08
.equ    DATA,                   0x10
.equ    LOAD,                   0x20

main:
    bl      Init
Update:
    mov     r1,     #0
    str     r1,     [r0]
    bl      Display
Loop:
    bl      ReadBtn
    ldr     r0,     =fib_chg
    ldr     r1,     [r0]
    cmp     r1,     #0
    bne     Update
    b       Loop

Display:
    push    {r0,    r1,     r2,     r3,     lr}
    bl      ResetMAX7219Digit
    ldr     r0,     =fib2
    ldr     r1,     [r0]
    ldr     r0,     =display_limit
    ldr     r2,     [r0]
    cmp     r1,     r2
    bgt     DisplayError
    b       UpdateFib
DisplayError:
    mov     r0,     #0x01
    mov     r1,     #0x01
    bl      MAX7219Send
    mov     r0,     #0x02
    mov     r1,     #0x0A
    bl      MAX7219Send
    b       DisplayEnd
UpdateFib:
    ldr     r0,     =fib1
    ldr     r1,     [r0]
    ldr     r0,     =fib2
    ldr     r2,     [r0]
    add     r3,     r1,     r2
    ldr     r0,     =fib1
    str     r2,     [r0]
    ldr     r0,     =fib2
    str     r3,     [r0]
    b       DisplayFib1
DisplayFib1:
    ldr     r0,     =fib1
    ldr     r0,     [r0]
    cmp     r0,     #0
    beq     DisplayZero
    bne     DisplayNumber
DisplayZero:
    mov     r0,     #0x01
    mov     r1,     #0x00
    bl      MAX7219Send
    b       DisplayEnd
DisplayNumber:
    mov     r0,     #1
    mov     r2,     #10
    ldr     r3,     =fib1
    ldr     r3,     [r3]
DisplayNumberLoop:
    cmp     r3,     #0
    beq     DisplayEnd
    sdiv    r1,     r3,     r2
    mul     r1,     r1,     r2
    sub     r1,     r3,     r1
    sdiv    r3,     r3,     r2
    bl      MAX7219Send
    add     r0,     r0,     #1
    b       DisplayNumberLoop
    
DisplayEnd:
    pop     {r0,    r1,     r2,     r3,     pc}

Init:
    push    {lr}
    bl      GPIOInit
    bl      MAX7219Init
    pop     {pc}

GPIOInit:
    push    {lr}
    bl      SetRCC_AHB2ENR
    bl      SetGPIO_MODER
    bl      SetGPIO_OSPEEDR
    bl      SetGPIO_PUPDR
    pop     {pc}

SetRCC_AHB2ENR:
    push    {r0,    r1,     lr}
    ldr     r0,     =RCC_AHB2ENR
    mov     r1,     #0x6
    str     r1,     [r0]
    pop     {r0,    r1,     pc}

SetGPIO_MODER:
    push    {lr}
    bl      SetGPIOB_MODER
    bl      SetGPIOC_MODER
    pop     {pc}

SetGPIOB_MODER:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_MODER_OFFSET
    ldr     r2,     [r0,    r1]
    and     r2,     #0xFFFFF03F
    orr     r2,     #0x00000540
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
    bl      SetGPIOB_OSPEEDR
    bl      SetGPIOC_OSPEEDR
    pop     {pc}

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

SetGPIO_PUPDR:
    push    {lr}
    bl      SetGPIOC_PUPDR
    pop     {pc}

SetGPIOC_PUPDR:
    push    {r0,    r1,     r2,     lr}
    ldr     r0,     =GPIOC_BASE
    ldr     r1,     =GPIO_PUPDR_OFFSET
    mov     r2,     #1
    lsl     r2,     r2,     #26
    str     r2,     [r0,    r1]
    pop     {r0,    r1,     r2,     pc}

MAX7219Init:
    push    {lr}
    bl      SetMAX7219_DECODE_MODE
    bl      SetMAX7219_DISPLAY_TEST
    bl      SetMAX7219_SCAN_LIMIT
    bl      SetMAX7219_INTENSITY
    bl      SetMAX7219_SHUTDOWN
    bl      ResetMAX7219Digit
    pop     {pc}

SetMAX7219_DECODE_MODE:
    push    {r0,    r1,     lr}
    ldr     r0,     =DECODE_MODE
    ldr     r1,     =#0xFF
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

SetMAX7219_DISPLAY_TEST:
    push    {r0,    r1,     lr}
    ldr     r0,     =DISPLAY_TEST
    ldr     r1,     =#0x00
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

SetMAX7219_SCAN_LIMIT:
    push    {r0,    r1,     lr}
    ldr     r0,     =SCAN_LIMIT
    ldr     r1,     =#0x07
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

SetMAX7219_INTENSITY:
    push    {r0,    r1,     lr}
    ldr     r0,     =INTENSITY
    ldr     r1,     =#0x0A
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

SetMAX7219_SHUTDOWN:
    push    {r0,    r1,     lr}
    ldr     r0,     =#SHUTDOWN
    ldr     r1,     =#0x1
    bl      MAX7219Send
    pop     {r0,    r1,     pc}

ResetMAX7219Digit:
    push    {r0,    r1,     lr}
    mov     r0,     #8
    mov     r1,     #0xF
ResetMAX7219DigitLoop:
    bl      MAX7219Send
    subs    r0,     r0,     #1
    bne     ResetMAX7219DigitLoop
    pop     {r0,    r1,     pc}

MAX7219Send:
    push    {r0,    r1,     r2,     lr}
    lsl     r0,     r0,     #8
    orr     r0,     r0,     r1
    rbit    r0,     r0
    lsr     r0,     #16
    mov     r1,     #16
MAX7219SendLoop:
    ldr     r2,     =CLOCK
    bl      BitReset
    ldr     r2,     =DATA
    tst     r0,     #1
    it      ne
    blne    BitSet
    it      eq
    bleq    BitReset
    ldr     r2,     =CLOCK
    bl      BitSet
    lsr     r0,     r0,     #1
    subs    r1,     r1,     #1
    bne     MAX7219SendLoop
    ldr     r2,     =LOAD
    bl      BitSet
    bl      BitReset
    pop     {r0,    r1,     r2,     pc}

BitSet:
    push    {r0,    r1,     lr}
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_BSRR_OFFSET
    str     r2,     [r0,    r1]
    pop     {r0,    r1,     pc}

BitReset:
    push    {r0,    r1,     lr}
    ldr     r0,     =GPIOB_BASE
    ldr     r1,     =GPIO_BRR_OFFSET
    str     r2,     [r0,    r1]
    pop     {r0,    r1,     pc}

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
    ldr     r0,     =btn_counter
    ldr     r1,     [r0]
    ldr     r0,     =btn_reset_limit
    ldr     r2,     [r0]
    cmp     r1,     r2
    bgt     FibReset
    ldr     r0,     =btn_chg
    ldr     r1,     [r0]
    cmp     r1,     #1
    beq     ReadBtnEnd
    mov     r1,     #1
    str     r1,     [r0]
    ldr     r0,     =fib_chg
    mov     r1,     #1
    str     r1,     [r0]
    b       ReadBtnEnd
FibReset:
    ldr     r0,     =fib1
    mov     r1,     #1
    str     r1,     [r0]
    ldr     r0,     =fib2
    mov     r1,     #0
    str     r1,     [r0]
    ldr     r0,     =fib_chg
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
