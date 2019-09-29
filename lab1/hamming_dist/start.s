    .syntax unified
    .cpu cortex-m4
    .thumb

.section .isr_vector, "x"
    .global Reset_Handler

    .macro IRQ handler
    .word \handler
    .weak \handler
    .set \handler, Default_Handler
    .endm

_vectors:
    .word _estack
    .word Reset_Handler
    IRQ NMI_Handler
    IRQ HardFault_Handler
    IRQ MemManageFault_Handler
    IRQ BusFault_Handler
    IRQ UsageFault_Handler
    //1C to 28 are reserved
    .word 0
    .word 0
    .word 0
    .word 0
    IRQ SVCall_Handler
    .word 0
    .word 0
    IRQ PendSV_Handler
    IRQ Systick_Handler

.org 0x00000188
    .thumb_func
Default_Handler: bx lr
    .thumb_func
Reset_Handler:
    bl main
