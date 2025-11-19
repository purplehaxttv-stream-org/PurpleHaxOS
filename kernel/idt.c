// kernel/idt.c
// Minimal 64-bit IDT setup for CPU exceptions.

#include <stdint.h>
#include <stddef.h>
#include "console.h"
#include "panic.h"
#include "idt.h"

struct idt_entry {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t  ist;
    uint8_t  type_attr;
    uint16_t offset_mid;
    uint32_t offset_high;
    uint32_t zero;
} __attribute__((packed));

struct idt_ptr {
    uint16_t limit;
    uint64_t base;
} __attribute__((packed));

#define IDT_MAX_ENTRIES    256
#define IDT_CODE_SELECTOR  0x18   // matches GDT64_CODE64_SEL in boot.asm

static struct idt_entry idt[IDT_MAX_ENTRIES];
static struct idt_ptr   idt_descriptor;

extern void isr0_stub(void); // defined in boot.asm (64-bit section)

static void idt_set_gate(int vec, uint64_t handler_addr) {
    struct idt_entry *e = &idt[vec];
    e->offset_low  = handler_addr & 0xFFFF;
    e->selector    = IDT_CODE_SELECTOR;
    e->ist         = 0;
    e->type_attr   = 0x8E; // present, DPL=0, interrupt gate
    e->offset_mid  = (handler_addr >> 16) & 0xFFFF;
    e->offset_high = (handler_addr >> 32) & 0xFFFFFFFF;
    e->zero        = 0;
}

void isr0_handler(void) {
    panic("Divide-by-zero exception");
}

void idt_init(void) {
    // Zero out IDT
    for (size_t i = 0; i < IDT_MAX_ENTRIES; i++) {
        idt[i].offset_low  = 0;
        idt[i].selector    = 0;
        idt[i].ist         = 0;
        idt[i].type_attr   = 0;
        idt[i].offset_mid  = 0;
        idt[i].offset_high = 0;
        idt[i].zero        = 0;
    }

    // Vector 0: divide-by-zero -> isr0_stub
    idt_set_gate(0, (uint64_t)&isr0_stub);

    idt_descriptor.limit = sizeof(idt) - 1;
    idt_descriptor.base  = (uint64_t)&idt[0];

    __asm__ __volatile__("lidt %0" : : "m"(idt_descriptor));

    console_write_line("IDT initialized (vector 0: divide-by-zero).");
}

