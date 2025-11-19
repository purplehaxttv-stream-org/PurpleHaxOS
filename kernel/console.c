// kernel/console.c
// Simple kernel console for PurpleHaxOS (VGA text mode).

#include <stddef.h>
#include <stdint.h>

static volatile uint16_t* const VGA_BUFFER = (uint16_t*)0xB8000;
static const uint8_t VGA_DEFAULT_COLOR = 0x05; // purple on black

static size_t cursor_row = 0;
static size_t cursor_col = 0;

static inline uint16_t vga_entry(char c, uint8_t color) {
    return (uint16_t)c | ((uint16_t)color << 8);
}

static void console_put_at(char c, uint8_t color, size_t row, size_t col) {
    if (row >= 25 || col >= 80) return;
    VGA_BUFFER[row * 80 + col] = vga_entry(c, color);
}

void console_clear(void) {
    for (size_t i = 0; i < 80 * 25; i++) {
        VGA_BUFFER[i] = vga_entry(' ', VGA_DEFAULT_COLOR);
    }
    cursor_row = 0;
    cursor_col = 0;
}

static void console_newline_internal(void) {
    cursor_col = 0;
    cursor_row++;
    if (cursor_row >= 25) {
        // Scroll up one line
        for (size_t row = 1; row < 25; row++) {
            for (size_t col = 0; col < 80; col++) {
                VGA_BUFFER[(row - 1) * 80 + col] = VGA_BUFFER[row * 80 + col];
            }
        }
        // Clear last line
        for (size_t col = 0; col < 80; col++) {
            VGA_BUFFER[(25 - 1) * 80 + col] = vga_entry(' ', VGA_DEFAULT_COLOR);
        }
        cursor_row = 24;
    }
}

void console_putc(char c) {
    if (c == '\n') {
        console_newline_internal();
        return;
    }
    console_put_at(c, VGA_DEFAULT_COLOR, cursor_row, cursor_col);
    cursor_col++;
    if (cursor_col >= 80) {
        console_newline_internal();
    }
}

void console_write(const char* s) {
    while (*s) {
        console_putc(*s++);
    }
}

void console_write_line(const char* s) {
    console_write(s);
    console_putc('\n');
}

void console_write_hex64(uint64_t value) {
    static const char* HEX = "0123456789ABCDEF";
    char buf[18];
    buf[0] = '0';
    buf[1] = 'x';
    for (int i = 0; i < 16; i++) {
        int shift = (15 - i) * 4;
        uint8_t nibble = (value >> shift) & 0xF;
        buf[2 + i] = HEX[nibble];
    }
    buf[18 - 1] = 0;
    console_write(buf);
}

void console_write_dec(uint64_t value) {
    char buf[32];
    int i = 0;
    if (value == 0) {
        console_putc('0');
        return;
    }
    while (value > 0 && i < (int)(sizeof(buf) - 1)) {
        buf[i++] = '0' + (value % 10);
        value /= 10;
    }
    // reverse
    while (i--) {
        console_putc(buf[i]);
    }
}

