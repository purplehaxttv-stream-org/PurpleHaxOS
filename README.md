# PurpleHaxOS

PurpleHaxOS is a small, educational 64-bit operating system built from scratch.
It begins in 32-bit protected mode (via Multiboot2), switches into 64-bit long
mode, and hands control to a fully freestanding C kernel.

This project is designed to be simple, transparent, and fun — a place to learn
low-level OS concepts without unnecessary abstraction.

---

## 🚀 Current Status (v0.3.0-dev)

PurpleHaxOS now fully boots into **64-bit long mode** and executes a C kernel.

### Implemented Features

### **Boot / CPU Initialization**
- Multiboot2-compliant bootloader setup
- 32-bit → 64-bit transition (PAE, paging, EFER.LME, CR0.PG)
- Custom GDT with 64-bit code segment
- Identity-mapped page tables for early long mode

### **Kernel (C) Framework**
- Working `kernel_main()` (C entrypoint)
- VGA text console  
  - clear screen  
  - print text  
  - scrolling  
  - hex output  
  - colored output  
- `panic()` system with CPU halt + diagnostic display

### **Interrupts / Exceptions**
- Full 64-bit IDT
- Assembly ISR stubs
- C-based exception handlers
- Divide-by-zero exception demo & testing

### **Multiboot2 Integration**
- Multiboot2 memory map parser  
- Displays usable RAM regions during boot  
- Solid foundation for future physical/virtual memory managers

---

## 📦 Build Instructions

Prerequisites (Debian/Kali/Ubuntu):

```
sudo apt install build-essential nasm xorriso grub-pc-bin
```

Build everything:

```
./build.sh
```

Produced outputs:
- `kernel/kernel.elf` — the 64-bit kernel
- `purple-os.iso` — bootable ISO for VirtualBox/QEMU/VMware

---

## 🧪 Running the OS

### QEMU (recommended for debugging)

```
qemu-system-x86_64 -cdrom purple-os.iso
```

### VirtualBox
- Create a new VM  
- Type: **Other > Other/Unknown (64-bit)**
- Attach `purple-os.iso`  
- Enable:
  - PAE/NX
  - I/O APIC
  - Hardware virtualization

---

## 🛣️ Roadmap

### **v0.3.x — Long Mode Foundations**
- [x] 64-bit C kernel
- [x] IDT + exceptions
- [ ] IRQ remapping
- [ ] Keyboard interrupt driver
- [ ] Basic command prompt

### **v0.4.x — Memory Management**
- [ ] Physical memory manager (bitmap)
- [ ] Page-frame allocator
- [ ] Higher-half kernel mapping
- [ ] Kernel heap allocator

### **v0.5.x — Drivers + Device Abstraction**
- [ ] Keyboard input (full)
- [ ] PIT timer driver
- [ ] ACPI parsing
- [ ] APIC enablement

### **v0.6.x — User Experience**
- [ ] Real command shell
- [ ] Kernel modules
- [ ] Improved console
- [ ] Panic screen UI

---

## 🧙 Philosophy

PurpleHaxOS is built with three guiding principles:

1. **Clarity over cleverness** — readable assembly, simple C  
2. **Full transparency** — no opaque magic, every part explained  
3. **Progressive expansion** — each version builds on the last  

---

## 📄 License

MIT License.

