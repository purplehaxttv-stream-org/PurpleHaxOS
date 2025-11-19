; kernel/boot.asm
; Bootloader stage: GRUB loads us in 32-bit protected mode.
; This file sets up:
;  - GDT
;  - PAE paging
;  - Long Mode transition
;  - Calls kernel_main() in 64-bit C
;  - Provides an ISR0 stub for the IDT

BITS 32

%define MB2_MAGIC       0xE85250D6
%define MB2_ARCH_I386   0

GDT_NULL        equ 0x00
GDT_CODE32      equ 0x08
GDT_DATA32      equ 0x10
GDT_CODE64      equ 0x18

PTE_PRESENT     equ 1 << 0
PTE_RW          equ 1 << 1
PTE_PS          equ 1 << 7


; ============================================================
; Multiboot2 Header
; ============================================================

SECTION .multiboot_header
align 8

multiboot_header_start:
    dd MB2_MAGIC
    dd MB2_ARCH_I386
    dd multiboot_header_end - multiboot_header_start
    dd -(MB2_MAGIC + MB2_ARCH_I386 + (multiboot_header_end - multiboot_header_start))

    ; End tag
    dw 0
    dw 0
    dd 8

multiboot_header_end:


; ============================================================
; GDT (32-bit + 64-bit code)
; ============================================================

SECTION .data
align 8

gdt64:
    dq 0                        ; Null descriptor

    dq 0x00CF9A000000FFFF       ; 32-bit code segment
    dq 0x00CF92000000FFFF       ; 32-bit data segment
    dq 0x00209A0000000000       ; 64-bit code segment

gdt64_end:

gdt_descriptor:
    dw gdt64_end - gdt64 - 1
    dd gdt64


; Stored Multiboot2 pointer (GRUB gives to us in EBX)
global mb_info_ptr
mb_info_ptr:
    dd 0


; ============================================================
; Paging Structures (4-level, minimal)
; ============================================================

SECTION .bss
align 4096

pml4: resq 512
pdpt: resq 512
pd:   resq 512


; ============================================================
; Code Section (32-bit)
; ============================================================

SECTION .text
global _start

_start:
    ; Save Multiboot2 pointer (EBX)
    mov [mb_info_ptr], ebx

    cli
    call load_gdt
    call enable_pae
    call init_paging
    call enable_long_mode
    call enable_paging

    ; Far jump into 64-bit code segment
    jmp GDT_CODE64:long_mode_entry


; ============================================================
; STAGE 1 FUNCTIONS (32-bit)
; ============================================================

load_gdt:
    lgdt [gdt_descriptor]

    mov ax, GDT_DATA32
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp GDT_CODE32:flush32

flush32:
    ret


enable_pae:
    mov eax, cr4
    or  eax, 1 << 5      ; PAE
    mov cr4, eax
    ret


init_paging:
    ; PML4 -> PDPT
    mov eax, pdpt
    or  eax, PTE_PRESENT | PTE_RW
    mov [pml4], eax
    mov dword [pml4+4], 0

    ; PDPT -> PD
    mov eax, pd
    or  eax, PTE_PRESENT | PTE_RW
    mov [pdpt], eax
    mov dword [pdpt+4], 0

    ; PD[0] -> 2MiB page at 0x00000000
    mov eax, PTE_PRESENT | PTE_RW | PTE_PS
    mov [pd], eax
    mov dword [pd+4], 0

    ; Load CR3
    mov eax, pml4
    mov cr3, eax
    ret


enable_long_mode:
    mov ecx, 0xC0000080      ; IA32_EFER
    rdmsr
    or eax, 1 << 8           ; LME
    wrmsr
    ret


enable_paging:
    mov eax, cr0
    or  eax, 1 << 31         ; PG bit
    mov cr0, eax
    ret



; ============================================================
; 64-BIT SECTION
; ============================================================

SECTION .text64
BITS 64
align 16

extern kernel_main
extern isr0_handler
global long_mode_entry
global isr0_stub

long_mode_entry:
    ; Setup stack
    mov     rsp, stack_top
    sub     rsp, 8               ; Correct alignment

    ; Zero-extend mb_info_ptr (32-bit) → RDI
    mov     eax, [mb_info_ptr]
    mov     rdi, rax

    call    kernel_main

.hang:
    hlt
    jmp .hang


; ============================================================
; ISR0 (Divide-by-zero) stub
; ============================================================

isr0_stub:
    push rbp
    mov rbp, rsp
    call isr0_handler

.isr_hang:
    hlt
    jmp .isr_hang



; ============================================================
; 64-bit STACK
; ============================================================

SECTION .bss
align 16
stack_bottom:
    resb 4096
stack_top:

