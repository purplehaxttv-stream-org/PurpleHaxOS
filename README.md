# PurpleHaxOS

PurpleHaxOS is a teaching operating system built from scratch using **pure Assembly + C**, targeting **x86_64**, booting via **BIOS + Multiboot2**, and designed to run on **VirtualBox & QEMU**.

It exists for one purpose:

> **To teach students how a real operating system boots, switches CPU modes, manages hardware, and grows into a full kernel — step by step, byte by byte.**

This project follows a strict philosophy:

* **Document early, document often.**
* **Never skip fundamentals.**
* **Build everything yourself until you understand it.**
* **Small commits, small steps, no leaps in logic.**

This README serves as both the official project description and the long‑term roadmap.

---

# 📟 Project Goals

PurpleHaxOS aims to become a fully functioning teaching kernel, demonstrating:

* Booting from Multiboot2
* Entering 32-bit protected mode
* Setting up a custom GDT
* Enabling PAE
* Building 64-bit page tables
* Entering long mode (x86_64)
* VGA text output
* Interrupts (IDT, PIC remap, keyboard driver)
* Memory management (physical allocator, paging, kernel heap)
* Task switching
* Basic filesystem
* Userland + shell

Every phase is implemented with extremely clear, minimal, self-contained code so that students can understand **why** each instruction exists.

---

# 🚀 Current Status — v0.1

The OS now:

* Boots with Multiboot2
* Runs in 32-bit protected mode
* Uses a custom kernel-defined GDT
* Enables PAE (required for long mode)
* Prints text in VGA mode

This marks the end of **Phase 4.0**.

---

# 📚 Roadmap / TODO

This list will update frequently. Each item corresponds to a GitHub milestone.

## ✅ Completed

* [x] Project skeleton
* [x] Multiboot2 header
* [x] 32-bit ASM kernel entry
* [x] VGA text mode writer
* [x] GDT (32-bit, kernel-only)
* [x] PAE enabled
* [x] Release v0.1

## 🔜 In Progress

* [ ] Add paging structures to `.bss`
* [ ] Initialize PML4 → PDPT → PD hierarchy
* [ ] Identity map the first 2 MiB
* [ ] Load CR3 with PML4 address

## ⏩ Next Major Milestones

### Phase 5 — Long Mode Entry

* [ ] Set EFER.LME via WRMSR
* [ ] Set CR0.PG
* [ ] Far jump into 64-bit mode
* [ ] First `BITS 64` code
* [ ] 64-bit VGA printf

### Phase 6 — GDT/IDT Finishing

* [ ] 64-bit GDT descriptors
* [ ] 64-bit IDT
* [ ] Exception handlers
* [ ] IRQ remapping
* [ ] Keyboard interrupts

### Phase 7 — Memory Management

* [ ] Physical page frame allocator
* [ ] Higher-half kernel mapping
* [ ] Virtual memory manager
* [ ] Simple kernel heap allocator

### Phase 8 — Tasking

* [ ] Stack switching
* [ ] TSS setup
* [ ] Cooperative multitasking
* [ ] Preemptive multitasking with PIT timer

### Phase 9 — Drivers & System Calls

* [ ] Basic keyboard driver (scancode set 1)
* [ ] System call ABI
* [ ] User-mode transition

### Phase 10 — Userland

* [ ] Simple init process
* [ ] Tiny shell
* [ ] Basic ELF loader

---

# 🧪 Build Instructions

You need:

* NASM
* ld (binutils)
* grub-mkrescue
* xorriso
* VirtualBox or QEMU

To build:

```bash
nasm -f elf32 kernel/boot.asm -o kernel/boot.o
ld -m elf_i386 -T linker.ld -o kernel/kernel.elf kernel/boot.o
cp kernel/kernel.elf iso/boot/kernel.elf
grub-mkrescue -o purple-os.iso iso
```

To run in VirtualBox or QEMU:

```bash
qemu-system-x86_64 -cdrom purple-os.iso
```

---

# 🧑‍🏫 Educational Philosophy

PurpleHaxOS is built to be:

* **Readable** — simple code, consistent formatting.
* **Explainable** — every file exists for a reason.
* **Teachable** — perfect for OS fundamentals or systems programming classes.
* **Hackable** — students can mod it, break it, fix it, extend it.

Every stage is designed to be shown live in a classroom.

---

# 🟣 Project Vibe

PurpleHaxOS is meant to feel like:

* a late-night hacking session,
* a retro demoscene project,
* and a modern kernel engineering playground.

Expect jokes, gremlin energy, and assembly code that bullies the CPU.

---

# 🤝 Contributing

Contributions are welcome — this is a teaching OS.

Pull requests should:

* Be small
* Be well-documented
* Add clear, readable code
* Include comments explaining architectural decisions

---

# 🧵 License

This project will ultimately adopt a permissive license (MIT/BSD).

For v0.1, code is provided without warranty.

