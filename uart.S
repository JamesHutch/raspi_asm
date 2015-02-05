/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <j@meshut.ch> wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return - James Hutchinson
 * ----------------------------------------------------------------------------
 */

.include "macros.inc"

/* Register locations */

AUX_ENABLES = 0x20215004
AUX_MU_BAUD_REG = 0x20215068
AUX_MU_IO_REG = 0x20215040
AUX_MU_LCR_REG = 0x2021504C
AUX_MU_LSR_REG = 0x20215054
AUX_MU_CNTL_REG = 0x20215060

GPFSEL1 = 0x20200004
GPPUD = 0x20200094
GPPUDCLK0 = 0x20200098

IRQ_DISABLE1 = 0x2000B21C
/* Aiming for 115200 baud */
BAUD = 270

FUNC uart_init
  /* Disable the AUX interrupt */
  ldr r1, =IRQ_DISABLE1
  ldr r0, =(1 << 29)
  str r0, [r1]
  /* Set the GPIO function of pin 14,15 to alt 5 */
  ldr r1, =GPFSEL1
  ldr r0, [r1]
  bic r0, #((7 << 12) | (7 << 15))
  orr r0, #((2 << 12) | (2 << 15)) /* Alt 5 */
  str r0, [r1]
  /* Remove any pull up/down from GPIO14 */
  ldr r1, =GPPUD
  mov r0, #0
  str r0, [r1]
  ldr r3, =2000
  wait_1:
    subs r3, #1
    bne wait_1
  ldr r1, =GPPUDCLK0
  ldr r0, =((1 << 14) | (1 << 15))
  str r0, [r1]
  ldr r3, =2000
  wait_2:
    subs r3, #1
    bne wait_2
  mov r0, #0
  str r0, [r1]
  /* Enable the Auxiliaries, bottom bit of the register is the uart */
  ldr r1, =AUX_ENABLES
  ldr r0, [r1]
  orr r0, r0, #1
  str r0, [r1]
  /* Turn off the uart */
  ldr r1, =AUX_MU_CNTL_REG
  ldr r0, =0
  str r0, [r1]
  /* Set 8bit mode */
  ldr r1, =AUX_MU_LCR_REG
  ldr r0, =3 /* Datasheet is *WRONG* about this value */
  str r0, [r1]
  /* Set the baud rate */
  ldr r1, =AUX_MU_BAUD_REG
  ldr r0, =BAUD
  str r0, [r1]
  /* Turn on the uart */
  ldr r1, =AUX_MU_CNTL_REG
  ldr r0, =3
  str r0, [r1]
  bx lr

FUNC uart_putc
  /* First check the transmit FIFO has space */
  ldr r1, =AUX_MU_LSR_REG
  not_ready:
    ldr r2, [r1]
    ands r2, #0b100000
    beq not_ready
  ldr r1, =AUX_MU_IO_REG
  str r0, [r1]
  bx lr

FUNC uart_hexchar
  push {lr}
  add r0, r0, #0x30
  cmp r0, #0x39
  addgt r0, r0, #0x7
  bl uart_putc
  pop {lr}
  bx lr

FUNC uart_hexstring
  push {r4-r5, lr}
  mov r4, r0 
  ldr r0, ='0
  bl uart_putc
  ldr r0, ='x
  bl uart_putc
  ldr r5, =0xF
  and r0, r5, r4, LSR #28
  bl uart_hexchar
  and r0, r5, r4, LSR #24
  bl uart_hexchar
  and r0, r5, r4, LSR #20
  bl uart_hexchar
  and r0, r5, r4, LSR #16
  bl uart_hexchar
  and r0, r5, r4, LSR #12
  bl uart_hexchar
  and r0, r5, r4, LSR #8
  bl uart_hexchar
  and r0, r5, r4, LSR #4
  bl uart_hexchar
  and r0, r5, r4
  bl uart_hexchar
  pop {r4-r5, lr}
  bx lr

FUNC uart_printstr
  push {r4, lr}
  mov r4, r0
  char_loop:
    ldrb r0, [r4], #1
    cmp r0, #0
    beq done
    bl uart_putc
    b char_loop
  done:
  pop {r4, lr}
  bx lr
  