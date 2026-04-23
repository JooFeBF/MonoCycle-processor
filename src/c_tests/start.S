
.section .text.init
.global _start
_start:
    li sp, 512      /* 128 words * 4 bytes/word = 512 (Top of DMEM) */
    call main

inf_loop:
    beq a0, a0, inf_loop
