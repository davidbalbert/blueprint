bits    16
org     0x7C00

    jmp     0x0000:start    ; Get CS in a known state (0x0000).

start:
    xor     ax, ax          ; Make sure the data segment and stack segment are at 0.
    mov     ds, ax
    mov     ss, ax

    mov     sp, 0x7BFE      ; Set up the stack directly below the bootloader in
    mov     bp, sp          ; memory. We can't set it to 0x7BFF, because the stack
                            ; has to be 16-bit (2 byte) alligned. The stack can grow
                            ; from 0x7BFE to 0x500 without overwriting anything
                            ; important (see http://wiki.osdev.org/Memory_Map_(x86)).
                            ; That's almost 30 KiB of usable space. Way more than enough.


    call    is_a20_enabled
    cmp     ax, 1
    je      finish_a20_check

    call    clear_screen16

    push    a20_error_message
    call    print16
    sub     sp, 2

    jmp     error

finish_a20_check:

    ; Load the next sector from disk
    push    0x7E00             ; Destination offset
    push    0x0000             ; Destination segment
    push    1                  ; Number of sectors
    push    1                  ; LBA

    call    load_from_disk

    sub sp, 8

    ; Enabeling Protected Mode

    call    disable_interrupts

    lgdt    [gdt_header]    ; Load the GDT

    mov     eax, cr0        ; Set the Protected Mode Enable (PE) bit in CR0
    or      al, 1
    mov     cr0, eax

    jmp     0x8:start32     ; Far jump into Protected Mode! 0x8 is the selector of the
                            ; code segment descriptor. This sets CS.

bits 32
start32:
    mov     ax, 0x10        ; 0x10 is the selector of the data segment descriptor.
    mov     ds, ax
    mov     ss, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    jmp     0x8:0x7E00


; Real mode helper functions

bits 16

; A place to go if we have an error
error:
    hlt
    jmp error


; Clears the screen. Takes no arguments
clear_screen16:
    push    es
    push    di

    mov     ax, 0xB800      ; Video memory 0xB800:0000.
    mov     es, ax          ; ES:DI is used by STOSW.

    mov     di, 0
    mov     ax, 0x0720      ; A white on blue (1F) space (20)
    mov     cx, 80 * 25     ; Set count to be number of characters on the screen

    cld                     ; Direction flag = 0 (increase edi each repatition)

    rep stosw               ; Copies ax to *di, ecx times.

    pop     di
    pop     es
    ret

; Prints its argument to the screen
;
; void print16(const char *s);
;
; s must be null terminated.
print16:
    push    bp
    mov     bp, sp

    push    si
    push    di
    push    es          ; segment for the string
    push    fs          ; segment for video memory

    ; TODO: We shouldn't be storing the string address in ES. ES should be
    ; 0x0000 and SI should contain the offset address of the string. For simplicity, the video memory

    mov     ax, 0               ; set up string segment
    mov     es, ax

    mov     si, [bp + 4]        ; set up string address

    mov     ax, 0xB800          ; video segment
    mov     fs, ax

    mov     di, 0               ; video index

print16_loop:
    mov     al, [es:si]         ; Load the next byte of the string
    cmp     al, 0               ; If it's 0, break out of the loop
    je      print16_loop_end

    mov     [fs:di], al
    inc     si
    add     di, 2               ; Move to the next byte in video memory (skipping the attribute byte)
    jmp     print16_loop

print16_loop_end:
    pop     fs
    pop     es
    pop     di
    pop     si

    pop     bp
    ret

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


; Loads blocks from the primary disk into memory.
; See: http://wiki.osdev.org/ATA_in_x86_RealMode_%28BIOS%29#LBA_in_Extended_Mode
;
; void load_from_disk(short starting_lba,
;                     short sector_count,
;                     short destination_segment,
;                     short destination_offset)
;
;

load_from_disk:
    push    bp
    mov     bp, sp

    push    bx

    ; Clear out LBA field
    mov     DWORD [dap.lba], 0
    mov     DWORD [dap.lba + 4], 0

    mov     ax, [bp + 4]
    mov     [dap.lba], ax

    mov     ax, [bp + 6]
    mov     [dap.sector_count], ax

    mov     ax, [bp + 8]
    mov     [dap.segment], ax

    mov     ax, [bp + 10]
    mov     [dap.offset], ax

    push    si

    xor     ax, ax
    mov     ah, 0x42                    ; Some sort of subroutine identifier for disk reads, maybe?
    mov     dl, 0x80                    ; "C" drive
    mov     si, dap                     ; Save the address of the DAP

    int     0x13                        ; Call the BIOS

    pop si
    pop bx

    mov sp, bp
    pop bp
    ret

; Disk address packet
align 2
dap:
    db  16              ; Packet size
    db  0               ; Always zero
.sector_count:
    dw  0               ; Number of sectors
.offset:
    dw  0               ; Destination offset
.segment:
    dw  0               ; Destination segment
.lba:
    dd  0               ; Starting LBA
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

gdt:
    gdt_entry 0, 0, 0, 0                        ; Null descriptor
    gdt_entry 0, 0xFFFFFFFF, 10011010b, 1100b   ; Code segment
    gdt_entry 0, 0xFFFFFFFF, 10010010b, 1100b   ; Data segment
    ; We need a TSS segment here, but I don't know what that is yet.
gdt_end:

a20_error_message:
    db "Error: A20 Gate disabled. We don't support enabling it yet.", 0

times 512 - 2 - ($ - $$) db 0       ; Pad the rest of the sector (512 bytes) with zeros.
db 0x55, 0xAA                       ; magic boot numbers
