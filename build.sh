#!/bin/bash
set -e

if [ "$1" == "clean" ]; then
    echo "==> Cleaning build artifacts..."
    rm -f kernel/*.o kernel/kernel.elf purple-os.iso
    exit 0
fi

echo "==> Assembling boot.asm..."
nasm -f elf64 kernel/boot.asm -o kernel/boot.o

echo "==> Compiling C sources..."
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/kernel.c -o kernel/kernel.o
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/console.c -o kernel/console.o
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/panic.c -o kernel/panic.o
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/idt.c -o kernel/idt.o

echo "==> Linking kernel..."
ld -m elf_x86_64 -T linker.ld -o kernel/kernel.elf \
    kernel/boot.o \
    kernel/kernel.o \
    kernel/console.o \
    kernel/panic.o \
    kernel/idt.o

echo "==> Copying kernel into ISO directory..."
cp kernel/kernel.elf iso/boot/kernel.elf

echo "==> Building ISO..."
grub-mkrescue -o purple-os.iso iso

echo "==> Build complete. ISO: purple-os.iso"

