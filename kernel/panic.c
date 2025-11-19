// kernel/panic.c
// Simple kernel panic function.

#include <stdint.h>
#include "console.h"

__attribute__((noreturn))
void panic(const char* msg) {
    console_write_line("");
    console_write_line("=== KERNEL PANIC ===");
    console_write_line(msg);
    console_write_line("System halted.");

    for (;;) {
        __asm__ __volatile__("hlt");
    }
}

