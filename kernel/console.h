// kernel/console.h

#pragma once
#include <stdint.h>

void console_clear(void);
void console_putc(char c);
void console_write(const char* s);
void console_write_line(const char* s);
void console_write_hex64(uint64_t value);
void console_write_dec(uint64_t value);

