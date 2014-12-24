bits    16
org     0x7C00

    jmp     0x0000:start    ; Get CS in a known state (0x0000).

start:
    xor     ax, ax          ; Make sure the data segment and stack segment are at 0.
    mov     ds, ax
    mov     ss, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax
    cld

    mov     sp, 0x7BFE      ; Set up the stack directly below the bootloader in
    mov     bp, sp          ; memory. We can't set it to 0x7BFF, because the stack
                            ; has to be 16-bit (2 byte) alligned. We're storing our
                            ; paging structures at 0x1000, 0x2000, 0x3000, and 0x4000,
                            ; so the stack can grow from 0x7BFE to 0x5000 without
                            ; overwriting anything important (see
                            ; http://wiki.osdev.org/Memory_Map_(x86)). That's more than
                            ; 11 KiB of usable space, which should be plenty.


    call    is_a20_enabled
    cmp     ax, 1
    je      finish_a20_check

    push    a20_error_message
    jmp     panic

finish_a20_check:

    ; Load stage 2 from disk. Look for "dap:" to see the parameters.
    ; See: http://wiki.osdev.org/ATA_in_x86_RealMode_%28BIOS%29#LBA_in_Extended_Mode
    xor     ax, ax
    mov     ah, 0x42                    ; Some sort of subroutine identifier for disk reads, maybe?
    mov     dl, 0x80                    ; "C" drive
    mov     si, dap                     ; Save the address of the DAP

    int     0x13                        ; Call the BIOS

    ; Enabeling Long Mode

    call    disable_interrupts

    ; Set up long mode page tables. We're going to identity map the first two
    ; megabytes of memory.

    mov     edi, 0x1000
    mov     cr3, edi        ; Store the address of the PML4T in CR3.

    ; Clear 0x1000 - 0x4FFF
    xor     eax, eax
    mov     ecx, 4096
    rep stosd               ; Writes 4096 (ECX) 32-bit length 0's (EAX) starting at 0x1000 (edi)

    ; Map the page tables
    mov     edi, cr3
    mov     DWORD [edi], 0x2003 ; Point PML4T[0] to a PDPT at 0x2000, marked as read/write and present(bit 2, and 1).
    add     edi, 0x1000
    mov     DWORD [edi], 0x3003 ; Point PDPT[0] to a PDT at 0x3000, marked as read/write and present
    add     edi, 0x1000
    mov     DWORD [edi], 0x4003 ; Point PDT[0] to a PT at 0x4000, marked as read/write and present
    add     edi, 0x1000

    ; Identity map all 512 entries in PML4T[0]->PDPT[0]->PDT[0]->PT. This is 2 MiB.
    mov     ebx, 0x3        ; r/w and present
    mov     ecx, 512

map_entry:
    mov     DWORD [edi], ebx    ; Map in the address of the current page (with r/w and present)
    add     ebx, 0x1000         ; Calculate the address of the next page
    add     edi, 8              ; Move to the next Page Table Entry in memory
    loop    map_entry           ; Jumps to map_entry and decrements ECX unless ECX == 1

    ; Enable PAE
    mov     eax, cr4
    or      eax, 1 << 5
    mov     cr4, eax

    ; Enable Long Mode in the EFER Machine Specific Register
    mov     ecx, 0xC0000080     ; The address of the EFER MSR
    rdmsr                       ; Stores the 64-bit value of EFER into EDX:EAX
    or      eax, 1 << 8         ; Set the LM bit
    wrmsr

    ; Enable paging (31) and protected mode (0)
    mov     eax, cr0
    or      eax, 1 << 31 | 1 << 0
    mov     cr0, eax


    lgdt    [gdt_header]    ; Load the GDT

    jmp     0x8:start64     ; Far jump into long mode! 0x8 is the selector of the
                            ; code segment descriptor. This sets CS.

bits 64
start64:
    mov     ax, 0x10        ; 0x10 is the selector of the data segment descriptor.
    mov     ds, ax
    mov     ss, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    jmp     0x7E00


; Real mode helper functions

bits 16

; Prints the null terminated string pointed to on the top of the stack and
; halts.
panic:
    ; Clear the screen
    mov     ax, 0xB800      ; Video memory 0xB800:0000.
    mov     es, ax          ; ES:DI is used by STOSW.

    mov     di, 0
    mov     ax, 0x0720      ; A white on blue (1F) space (20)
    mov     cx, 80 * 25     ; Set count to be number of characters on the screen

    rep stosw               ; Copies ax to *di, ecx times.

    ; Print the message
    mov     ax, 0           ; The segment of the error message
    mov     es, ax

    pop     si              ; Address of the error message

    mov     ax, 0xB800      ; video segment
    mov     fs, ax

    mov     di, 0           ; video index

error_loop:
    mov     al, [es:si]         ; Load the next byte of the string
    cmp     al, 0               ; If it's 0, break out of the loop
    je      error_halt

    mov     [fs:di], al
    inc     si
    add     di, 2               ; Move to the next byte in video memory (skipping the attribute byte)
    jmp     error_loop

error_halt:
    hlt
    jmp     error_halt

; Disables all interrupts (including NMIs).
;
; Takes no parameters

disable_interrupts:
    cli                     ; Disable interrupts

                            ; Disable Non-Maskable Interrupts by:
    in      al, 0x70        ; 1. Reading the currently CMOS address
    or      al, 0x80        ; 2. Setting the NMI disable bit (bit 7), to 1.
    out     0x70, al        ; 3. Writing this value back to the CMOS address port.
    ret

; Stores 1 in ax if the A20 gate is enabled. Stores 0 otherwise.
; See http://wiki.osdev.org/A20_Line.
;
; Takes no parameters.
;
; Write different values to memory location 0x0000:0x0500 (1,280) and
; 0xFFFF:0x0510 (1,049,856). 1,049,856 % 2^20 is 1,280, so if we read
; 0x0000:0x0500 and get what we wrote to 0xFFFF:0x0510, then we know the A20
; Gate is disabeled.
;
; This function assumes nothing important is stored at either of these memory
; locations.

is_a20_enabled:
    pushf
    push es
    push si
    push fs
    push di
    push bx

    xor ax, ax         ; ax = 0
    mov es, ax
    mov si, 0x0500

    not ax             ; ax = 0xFFFF
    mov fs, ax
    mov di, 0x0510

    mov byte [es:si], 0xAB
    mov byte [fs:di], 0xCD

    xor ax, ax                  ; ax = 0

    cmp BYTE [es:si], 0xCD      ; If 0x0000:0x0500 is equal to what we just wrote, to
    je is_a20_enabled_cleanup   ; the higher address, the second write wrapped around
                                ; and A20 is disabeled (return 0).

    mov al, 1                   ; Otherwise, it's enabled.

is_a20_enabled_cleanup:
    pop bx
    pop di
    pop fs
    pop si
    pop es
    popf

    ret

; Disk address packet
align 2
dap:
    db  16              ; Packet size
    db  0               ; Always zero
.sector_count:
    dw  1               ; Number of sectors
.offset:
    dw  0x7E00          ; Destination offset
.segment:
    dw  0               ; Destination segment
.lba:
    dd  1               ; Starting LBA
    dd  0               ; Upper 16 bits of 48-bit LBA

; Expands to an entry for the gdt table.
; See: http://wiki.osdev.org/GDT
;
; Arguments:
; %1 - Base, 32 bits
; %2 - Limit, 20 bits
; %3 - Access byte, 8 bits
; %4 - Flags, 4 bits
%macro gdt_entry 4
    dw %2 & 0xFFFF                              ; First 2 bytes of limit
    dw %1 & 0xFFFF                              ; First 2 bytes of base
    db %1 >> 16 & 0xFF                          ; Third byte of base
    db %3                                       ; Access byte
    db (%4 << 4 & 0xF0) | %2 >> 16 & 0x0F       ; 4 bits of flags, last 4 bits of limit
    db %1 >> 24 & 0xFF                          ; Fourth byte of base
%endmacro

gdt_header:
    dw gdt_end - gdt - 1
    dd gdt

; The GDT should be alligned on an 8-byte boundary. See section 3.5.1, of
; volume 3A of the Intel 64 and IA-32 Architectures Software Developer's
; Manual.
align 8
gdt:
    gdt_entry 0, 0, 0, 0                        ; Null descriptor
    gdt_entry 0, 0, 10011010b, 1010b            ; Code segment
    gdt_entry 0, 0, 10010010b, 0                ; Data segment
    ; We need a TSS segment here, but I don't know what that is yet.
gdt_end:

a20_error_message:
    db "Error: A20 Gate disabled. We don't support enabling it yet.", 0

times 512 - 76 - ($ - $$) db 0      ; Pad the rest of the sector (512 bytes) with zeros.
                                    ; 76 is the size of the partition table, and the magic
                                    ; boot numbers.

%macro empty_partition_table_entry 0
    times 16 db 0
%endmacro

; Partition Table

times 10 db 0                       ; Optional "unique" disk ID
empty_partition_table_entry         ; The Partition Table always has 4 entries
empty_partition_table_entry
empty_partition_table_entry
empty_partition_table_entry

db 0x55, 0xAA                       ; magic boot numbers
