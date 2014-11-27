    bits    16
    org     0x7C00

    jmp     0x0000:start

start:
    ; Enabeling Protected Mode

    cli                     ; Disable interrupts

                            ; Disable Non-Maskable Interrupts by:
    in      al, 0x70        ; 1. Reading the currently CMOS address
    or      al, 0x80        ; 2. Setting the NMI disable bit (bit 7), to 1.
    out     0x70, al        ; 3. Writing this value back to the CMOS address port.

    lgdt    [gdt_header]    ; Load the GDT

    mov     eax, cr0        ; Set the Protected Mode Enable (PE) bit in CR0
    or      al, 1
    mov     cr0, eax

    jmp     0x8:start32     ; Jump into Protected Mode! 0x8 is the selector of the code segment descriptor.


bits 32
start32:
    mov     ax, 0x10        ; 0x10 is the selector of the data segment descriptor.
    mov     ds, ax
    mov     ss, ax
    mov     es, ax
    mov     fs, ax
    mov     gs, ax

    ; Clear the screen

    mov     edi, 0xB8000    ; Video memory address
    mov     ax, 0x1F20      ; A white on blue (1F) space (20)
    mov     ecx, 80 * 25    ; Set count to be number of characters on the screen

    cld                     ; Direction flag = 0 (increase edi each repatition)

    rep stosw               ; Copies ax to *edi, ecx times.

    mov     edi, 0xB8000
    mov     edx, message
print_message:
    mov     al, [edx]            ; Copy a character from the message into AL
    mov     BYTE [edi], al       ; and move it into video memory.
    add     edi, 2               ; Move forward 2 bytes in video memory (to skip the attribute byte)
    inc     edx                  ; and move forward 1 byte in the message.

    cmp     BYTE [edx], 0        ; See if we've reached the end of the message
    jne     print_message

loop_forever:
    hlt
    jmp     loop_forever

message:
    db "Hello, from Protected Mode!", 0

; Creates a entry for the gdt table.
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

times 512 - 2 - ($ - $$) db 0       ; Pad the rest of the sector (512 bytes) with zeros.
db 0x55, 0xAA                       ; magic boot numbers
