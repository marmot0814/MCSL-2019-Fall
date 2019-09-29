    .syntax unified
    .cpu cortex-m4
    .thumb
.data
    arr1: .byte 0x19, 0x34, 0x14, 0x32, 0x52, 0x23, 0x61, 0x29
.text
.global main
.equ N, 8

//  for (int i = 0 ; i < n ; i++)
//      for (int j = 1 ; j < n ; j++)
//          if (data[j - 1] < data[j])
//              swap(data[j - 1], data[j])

do_sort:
    //  R0: array address
    //  R1: i
    //  R2: j
    //  R3: ptr
    movs R1, #0                 //  i = 0
loopi:
    cmp R1, #N                  //  if i >= n
    bge end                     //  to end
    add R1, R1, #1              //  i++

    movs R2, #1                 //  j = 1
    movs R3, R0                 //  ptr = arr
loopj:
    cmp R2, #N                  //  if j >= n
    bge loopi                   //  to loopi
    // load data to r4, r5
    ldrb R4, [R3]               //  r4 = arr[j - 1]
    ldrb R5, [R3, #1]           //  r5 = arr[j    ]
    cmp R4, R5                  //  if (r4 < r5)
    blt skip                    //  skip swap
    strb R5, [R3]               //  store r5 to arr[j    ]
    strb R4, [R3, #1]           //  store r4 to arr[j - 1]
skip:
    add R2, R2, #1              //  j++
    add R3, R3, #1              //  ptr++
    b loopj                 
end:
    bx lr

main:
    ldr R0, =arr1
    bl do_sort
