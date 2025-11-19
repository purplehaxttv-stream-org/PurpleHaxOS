/* linker.ld  - Linker script for 64-bit kernel, loaded at 1 MiB */

ENTRY(_start)

SECTIONS
{
    /* GRUB will load us around here */
    . = 1M;

    .text ALIGN(4K) :
    {
        /* Multiboot2 header must be early in the binary */
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

