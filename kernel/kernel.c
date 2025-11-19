// kernel/kernel.c
// PurpleHaxOS kernel C entrypoint with Multiboot2 memory parsing + IDT init.

#include <stddef.h>
#include <stdint.h>

#include "console.h"
#include "panic.h"
#include "idt.h"

// ---------------------------------------------------------------------------
// Multiboot2 structures
// ---------------------------------------------------------------------------

#define MULTIBOOT2_TAG_TYPE_END    0
#define MULTIBOOT2_TAG_TYPE_MMAP   6
#define MULTIBOOT2_MMAP_TYPE_AVAILABLE 1

struct multiboot_tag {
    uint32_t type;
    uint32_t size;
};

struct multiboot_mmap_entry {
    uint64_t addr;
    uint64_t len;
    uint32_t type;
    uint32_t reserved;
};

struct multiboot_tag_mmap {
    uint32_t type;
    uint32_t size;
    uint32_t entry_size;
    uint32_t entry_version;
    struct multiboot_mmap_entry entries[];
};

void kernel_main(uint64_t mb_info_addr) {
    console_clear();
    console_write_line("PurpleHaxOS kernel_main() in 64-bit C");
    console_write_line("Parsing Multiboot2 memory map...");

    if (mb_info_addr == 0) {
        panic("mb_info_addr == 0 (no Multiboot2 info)");
    }

    // Initialize IDT so CPU exceptions have somewhere to go
    idt_init();

    uint8_t* mb = (uint8_t*)(uintptr_t)mb_info_addr;
    uint32_t total_size = *(uint32_t*)mb;     // total size of multiboot info
    (void)total_size; // not used yet
    uint8_t* tag_ptr = mb + 8;               // skip total_size + reserved

    uint64_t total_usable_bytes = 0;
    uint32_t usable_regions = 0;

    while (1) {
        struct multiboot_tag* tag = (struct multiboot_tag*)tag_ptr;

        if (tag->type == MULTIBOOT2_TAG_TYPE_END && tag->size == 8) {
            break;
        }

        if (tag->type == MULTIBOOT2_TAG_TYPE_MMAP) {
            struct multiboot_tag_mmap* mmap_tag = (struct multiboot_tag_mmap*)tag;
            uint8_t* entry_ptr = (uint8_t*)mmap_tag->entries;

            while (entry_ptr < (uint8_t*)mmap_tag + mmap_tag->size) {
                struct multiboot_mmap_entry* entry =
                    (struct multiboot_mmap_entry*)entry_ptr;

                if (entry->type == MULTIBOOT2_MMAP_TYPE_AVAILABLE) {
                    total_usable_bytes += entry->len;
                    usable_regions++;
                }

                entry_ptr += mmap_tag->entry_size;
            }
        }

        // tags are 8-byte aligned
        tag_ptr += (tag->size + 7U) & ~7U;
    }

    uint64_t total_usable_mib = total_usable_bytes >> 20; // / (1024*1024)

    console_write("Usable regions: ");
    console_write_dec(usable_regions);
    console_putc('\n');

    console_write("Usable RAM (MiB): ");
    console_write_dec(total_usable_mib);
    console_putc('\n');

    console_write_line("");
    console_write_line("System idle. (hlt loop)");

    for (;;) {
        __asm__ __volatile__("hlt");
    }
}

