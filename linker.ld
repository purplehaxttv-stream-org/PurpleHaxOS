/* linker.ld  - Linker script for Multiboot , loaded at 1 MiB */

ENTRY(_start)

SECTIONS
{
    /*GRUB will load us around here */
    . = 1M;

    .text ALIGN(4K) : 
    {
        /* Multiboot2 header must be early in the binary */
        *(.multiboot_header)
        *(.text*)
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

