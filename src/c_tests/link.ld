MEMORY
{
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 512   /* 128 words */
}

SECTIONS
{
  .text : {
    *(.text.init)
    *(.text*)
    *(.rodata*)
  } > RAM

  .data : {
    *(.data*)
    *(.sdata*)
  } > RAM

  .bss : {
    *(.bss*)
  } > RAM
}