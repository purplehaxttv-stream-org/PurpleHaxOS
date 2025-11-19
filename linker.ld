/* linker.ld  - Linker script for Multiboot , loaded at 1 MiB */

ENTRY(_start)

SECTIONS
{
    . = 1M;

    .text ALIGN(4K) :
    {
        *(.multiboot_header)
        *(.text)
    }

    .text64 ALIGN(4K) :
    {
        *(.text64)
    }

    .rodata ALIGN(4K) :
    {
        *(.rodata*)
    }

    .data ALIGN(4K) :
    {
        *(.data*)
    }

    .bss ALIGN(4K) :
    {
        *(COMMON)
        *(.bss*)
    }
}

