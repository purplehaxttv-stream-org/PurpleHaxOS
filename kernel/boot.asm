; kernel/boot.asm
; First contact with the CPU. GRUB loads this as a 32-bit Multiboot2 kernel.

BITS 32

%define MB2_MAGIC        0xE85250D6
%define MB2_ARCH_I386    0

; GDT selectors (offsets from GDT base, each descriptor = 8 bytes)
GDT64_NULL_SEL    equ 0x00
GDT64_CODE_SEL    equ 0x08    ; 32-bit kernel code
GDT64_DATA_SEL    equ 0x10    ; 32-bit kernel data
GDT64_CODE64_SEL  equ 0x18    ; 64-bit kernel code

; Paging flags (for page table entries)
PTE_PRESENT    equ 1 << 0      ; entry is valid
PTE_RW         equ 1 << 1      ; writable
PTE_PS         equ 1 << 7      ; large page (2 MiB)

; =============================================================================
; Multiboot2 header
; =============================================================================

SECTION .multiboot_header
align 8
multiboot_header_start:
    dd MB2_MAGIC                         ; magic
    dd MB2_ARCH_I386                     ; architecture
    dd multiboot_header_end - multiboot_header_start ; header length
    dd -(MB2_MAGIC + MB2_ARCH_I386 + (multiboot_header_end - multiboot_header_start)) ; checksum

    ; End tag (type = 0, size = 8)
    dw 0                                  ; type
    dw 0                                  ; reserved
    dd 8                                  ; size
multiboot_header_end:

; =============================================================================
; GDT (32-bit + 64-bit descriptors)
; =============================================================================

section .data
align 8

gdt64:
    dq 0                     ; NULL descriptor

gdt64_code:
    ; 32-bit kernel code descriptor
    ; base=0, limit=0xFFFFF, granularity=4K, D=1 (32-bit), L=0, type=0xA (execute/read)
    dq 0x00CF9A000000FFFF

gdt64_data:
    ; 32-bit kernel data descriptor (read/write)
    ; base=0, limit=0xFFFFF, granularity=4K, D=1 (32-bit), L=0, type=0x2 (read/write)
    dq 0x00CF92000000FFFF

gdt64_code64:
    ; 64-bit kernel code descriptor
    ; Long mode: L=1, D=0, code exec/read, base/limit ignored
    dq 0x00209A0000000000

gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64 - 1     ; size
    dd gdt64                     ; base (32-bit; fine in 32-bit mode)

; =============================================================================
; Paging structures + stack (.bss)
; =============================================================================

section .bss
align 4096

pml4:
    resq 512          ; PML4 = 512 entries (4 KiB)

pdpt:
    resq 512          ; PDPT = 512 entries

pd:
    resq 512          ; Page Directory = 512 entries (we'll use 2 MiB page)

align 16
stack_bottom:
    resb 4096 * 4     ; 16 KiB stack
stack_top:

; =============================================================================
; 32-bit code
; =============================================================================

section .text
global _start

; Load our GDT and reload segment registers
load_gdt:
    lgdt [gdt64_descriptor]

    mov ax, GDT64_DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    jmp GDT64_CODE_SEL:flush_cs   ; far jump to reload CS

flush_cs:
    ret

; Enable PAE (CR4.PAE = 1)
enable_pae:
    mov eax, cr4
    or  eax, 1 << 5
    mov cr4, eax
    ret

; Initialize paging structures for long mode:
; PML4[0] -> PDPT
; PDPT[0] -> PD
; PD[0]   -> 2 MiB identity-mapped page at 0x00000000
; Then load CR3 with &pml4.
init_paging:
    ; PML4[0] = address of PDPT | PRESENT | RW
    mov eax, pdpt
    or  eax, PTE_PRESENT | PTE_RW
    mov [pml4], eax
    mov dword [pml4 + 4], 0

    ; PDPT[0] = address of PD | PRESENT | RW
    mov eax, pd
    or  eax, PTE_PRESENT | PTE_RW
    mov [pdpt], eax
    mov dword [pdpt + 4], 0

    ; PD[0] = 2 MiB page at physical 0x00000000
    mov eax, PTE_PRESENT | PTE_RW | PTE_PS
    mov [pd], eax
    mov dword [pd + 4], 0

    ; Load CR3 with the address of PML4
    mov eax, pml4
    mov cr3, eax
    ret

; Enable long mode in EFER (set LME bit)
enable_long_mode:
    mov ecx, 0xC0000080        ; IA32_EFER
    rdmsr
    or  eax, 1 << 8            ; LME = 1
    wrmsr
    ret

; Enable paging (CR0.PG = 1)
enable_paging:
    mov eax, cr0
    or  eax, 1 << 31           ; PG = 1
    mov cr0, eax
    ret

; -----------------------------------------------------------------------------
; 32-bit entry point
; -----------------------------------------------------------------------------

_start:
    ; GRUB gave us:
    ;  - 32-bit protected mode
    ;  - A20 enabled
    ;  - paging disabled

    cli                         ; Disable interrupts
    call load_gdt               ; Install and use our GDT
    call enable_pae             ; Enable PAE in CR4
    call init_paging            ; Setup paging structures, load CR3
    call enable_long_mode       ; Set EFER.LME
    call enable_paging          ; Enable paging (CR0.PG = 1)

    ; Now jump into 64-bit long mode code segment
    jmp GDT64_CODE64_SEL:long_mode_entry

; =============================================================================
; 64-bit long mode code
; =============================================================================

section .text64
align 16
BITS 64
extern kernel_main
global long_mode_entry

long_mode_entry:
    ; Set up a 16-byte aligned stack for C (SysV ABI)
    mov     rsp, stack_top
    sub     rsp, 8              ; align so (RSP+8) % 16 == 0 before CALL

    ; Call the C kernel entry point
    call    kernel_main

.hang64:
    hlt
    jmp .hang64

