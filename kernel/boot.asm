; kernel/boot.asm
; First contact with the CPU. GRUB loads this file into 32 bit protected mode

BITS 32

%define MB2_MAGIC 0xE85250D6
%define MB_2_ARCH_I386 0
; We'll compute header lentgh via labels below
; checksum  = (magic + arch + header_length)

; GDT selectors (offsets from GDT base, each descriptor = 8 bytes)

GDT64_NULL_SEL  equ 0x00
GDT64_CODE_SEL  equ 0x08
GDT64_DATA_SEL  equ 0x10

; Paging flags (for page table entries)
PTE_PRESENT    equ 1 << 0      ; entry is valid
PTE_RW         equ 1 << 1      ; writable
PTE_PS         equ 1 << 7      ; large page (2 MiB)


SECTION .multiboot_header
align 8 
multiboot_header_start:
    dd MB2_MAGIC                ; magic number
    dd MB_2_ARCH_I386          ; architecture
    dd multiboot_header_end - multiboot_header_start ; header length
    dd -(MB2_MAGIC + MB_2_ARCH_I386 + (multiboot_header_end - multiboot_header_start)) ; checksum
    
    ;=== End tag (type = 0, size = 8) ===
    dw 0                      ; type
    dw 0                      ; reserved
    dd 8                      ; size

multiboot_header_end:

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


gdt64_end:

gdt64_descriptor:
    dw gdt64_end - gdt64 - 1 ; size of GDT in bytes - 1
    dd gdt64                 ; base address (32-bit for now; we’re still in 32-bit)

section .bss
align 4096

pml4:
    resq 512          ; PML4 = 512 entries (4 KiB)

pdpt:
    resq 512          ; PDPT = 512 entries

pd:
    resq 512          ; Page Directory = 512 entries (will use 2 MiB page)


section .text
global _start

load_gdt:
    ; Load our 64-bit-capable GDT (still in 32-bit mode for now)
    lgdt [gdt64_descriptor]

    ; Reload data segment registers to use our GDT entries
    mov ax, GDT64_DATA_SEL
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    ; Far jump to reload CS with our code descriptor
    jmp GDT64_CODE_SEL:flush_cs

flush_cs:
    ret

; ====================================================================
; Enable PAE (Physical Address Extension)
; Required before entering long mode.
; This sets CR4.PAE = 1 (bit 5).
; ====================================================================

enable_pae:
    mov eax, cr4            ; read current CR4
    or  eax, 1 << 5         ; set bit 5 (PAE = 1)
    mov cr4, eax            ; write back to CR4
    ret

; ====================================================================
; Initialize paging structures for long mode
; Build a minimal 4-level hierarchy:
;   PML4[0] -> PDPT
;   PDPT[0] -> PD
;   PD[0]   -> 2 MiB identity-mapped page at 0x00000000
; Then load CR3 with &pml4.
; ====================================================================

init_paging:
    ; PML4[0] = address of PDPT | PRESENT | RW
    mov eax, pdpt
    or  eax, PTE_PRESENT | PTE_RW
    mov [pml4], eax           ; low 32 bits of entry
    mov dword [pml4 + 4], 0   ; high 32 bits = 0 (we're in low memory)

    ; PDPT[0] = address of PD | PRESENT | RW
    mov eax, pd
    or  eax, PTE_PRESENT | PTE_RW
    mov [pdpt], eax           ; low 32 bits
    mov dword [pdpt + 4], 0   ; high 32 bits

    ; PD[0] = 2 MiB page at physical 0x00000000
    ; For a 2 MiB page:
    ;   - bits 12..31 = base address >> 12
    ;   - bit 7 (PS)  = 1 -> large page
    ; We're mapping from 0, so base = 0.
    mov eax, PTE_PRESENT | PTE_RW | PTE_PS
    mov [pd], eax             ; low 32 bits: flags + base bits (0 here)
    mov dword [pd + 4], 0     ; high 32 bits

    ; Load CR3 with the address of PML4
    mov eax, pml4
    mov cr3, eax

    ret



; ====================================================================
; VGA TEXT MODE WRITER (simple ASM version)
; ====================================================================

vga_print: 
    pusha                   

    mov edi, 0xB8000   ; VGA text buffer
    mov esi, msg        ; message to print
    mov ah, 0x05        ; purple on black

.vga_loop: 
    lodsb              ; load byte from [esi] into al, increment esi
    cmp al, 0          ; check for null terminator
    je .done           ; if null, we're done
    stosw              ; store ax (character + attribute) into [edi], increment edi by 2
    jmp .vga_loop      ; repeat

.done:
    popa
    ret
msg: db "Welcome to PurpleHaxOS with PAE enabled!", 0
_start:
    ; GRUB gave us: 
    ;  - 32-bit protected mode
    ;  - A20 enabled
    ;  - paging disabled
    ;  - stack is not guaranteed, we will deal with that later

    cli                ; Disable interrupts
    call load_gdt      ; Install and use our GDT
    call enable_pae    ; Enable PAE in CR4
    call init_paging   ; Setup paging structures
    call vga_print     ; Print welcome message

.hang: 
    hlt                ; stop the cpu until next interrupt
    jmp .hang          ; infinite loop


