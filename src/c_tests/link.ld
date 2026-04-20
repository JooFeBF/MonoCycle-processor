MEMORY
{
  IMEM (rx) : ORIGIN = 0x00000000, LENGTH = 4K   /* 1024 words */
  DMEM (rw) : ORIGIN = 0x00000000, LENGTH = 4K   /* 1024 words */
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text*)
    *(.rodata*)
  } > IMEM

  .data : {
    *(.data*)
    *(.sdata*)
    *(.bss*)
  } > DMEM
}
