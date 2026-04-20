.section .text.init
.global _start
_start:
    li sp, 4096      /* 1024 words * 4 bytes/word = 4096 (Top of DMEM) */
    call main

inf_loop:
    j inf_loop
