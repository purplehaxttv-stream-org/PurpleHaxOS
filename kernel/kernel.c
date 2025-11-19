// kernel/kernel.c
// First C entry point for PurpleHaxOS in 64-bit long mode.

#include <stddef.h>
#include <stdint.h>

static volatile uint16_t* const VGA_BUFFER = (uint16_t*)0xB8000;
static const uint8_t VGA_COLOR = 0x05; // purple on black

static void vga_clear(void) {
    for (size_t i = 0; i < 80 * 25; i++) {
        VGA_BUFFER[i] = (uint16_t)' ' | ((uint16_t)VGA_COLOR << 8);
    }
}

static void vga_write_string(const char* s, size_t row, size_t col) {
    size_t index = row * 80 + col;
    for (size_t i = 0; s[i] != 0; i++) {
        VGA_BUFFER[index + i] = (uint16_t)s[i] | ((uint16_t)VGA_COLOR << 8);
    }
}

void kernel_main(void) {
    vga_clear();
    vga_write_string("PurpleHaxOS kernel_main() in 64-bit C", 0, 0);
    vga_write_string("Long mode online. Time to build an OS.", 1, 0);

    // Halt forever for now
    for (;;) {
        __asm__ __volatile__("hlt");
    }
}

