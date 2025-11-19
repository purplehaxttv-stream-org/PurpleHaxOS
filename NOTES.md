# PurpleHaxOS v0.2.0 — Long Mode Online (Pre-release)

This release marks a major architectural milestone: PurpleHaxOS now boots
fully into 64-bit long mode using a fully custom-written boot pipeline.

---

## 🚀 New In This Release

### ✔️ Stable 32-bit Boot Pipeline
- Multiboot2-compliant kernel image
- 32-bit GRUB boot path verified and reliable
- GDT with 32-bit code/data segments

### ✔️ CPU Mode Switching Completed
- PAE enabled (CR4.PAE = 1)
- Paging structures (PML4 → PDPT → PD) built manually
- 2MiB large page identity map for early boot
- CR3 loaded with PML4
- Long mode enabled via EFER.LME
- Paging enabled (CR0.PG = 1)
- Successful far jump into 64-bit kernel code segment

### ✔️ Verified 64-bit Execution
- 64-bit `.text64` section mapped and executed
- Confirmed running in long mode using 64-bit register operations
- Simple VGA write from 64-bit mode

---

## 🧱 What This Unlocks
With long mode operational, the OS can now expand into:

- A 64-bit C/C++ kernel
- Memory map parsing
- Physical & virtual memory managers
- Fully functional IDT + interrupts
- Timer & keyboard drivers
- Framebuffer graphics console
- Syscall layer
- Multi-tasking (future)

This is the foundation of a modern x86_64 operating system.

---

## ⚠️ Current Limitations
This is a **pre-release**.  
It is not intended to be a usable OS yet.

- No interrupt handling
- No memory allocator
- No C environment
- No drivers
- No filesystem
- No userspace

---

## 🧪 Status
Long mode bring-up has been tested in VirtualBox and confirmed stable.
Next milestone: **v0.3.0 — 64-bit C kernel entry + basic memory map structures**

---


