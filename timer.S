/*
 * ----------------------------------------------------------------------------
 * "THE BEER-WARE LICENSE" (Revision 42):
 * <j@meshut.ch> wrote this file. As long as you retain this notice you
 * can do whatever you want with this stuff. If we meet some day, and you think
 * this stuff is worth it, you can buy me a beer in return - James Hutchinson
 * ----------------------------------------------------------------------------
 */

.include "macros.inc"

/* 32 bits of a 1MHz timer */
TIMER_CLO = 0x20003004

FUNC wait_usecs
  ldr r3, =TIMER_CLO
  ldr r1, [r3]
timer_wait:
    ldr r2, [r3]
    sub r2, r2, r1
    cmp r2, r0
    blt timer_wait
  bx lr
