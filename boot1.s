    bits    16
    org     0x7C00

    jmp     0x0000:start

start:
    xor     ax, ax          ; Set the data segment to 0. We want all loads and
    mov     ds, ax          ; stores to be relative to 0x0 by default.

    mov     ax, 0xB800      ; video memory starts at 0xb8000. We'll set ES to
    mov     es, ax          ; point to the beginning of video memory. (Note that
                            ; the segment selector is 0xB800, not 0xB8000).

    xor     bx, bx          ; Start clearing the screen from [es:0]
clear_start:
    mov     BYTE [es:bx], ' '   ; write a space
    inc     bx
    mov     BYTE [es:bx], 0x1F  ; white on blue
    inc     bx

    cmp     bx, 4000        ; 80 columns * 25 rows * 2 bytes
    jne     clear_start


    mov     bx, 0           ; Reset our index into video memory
    mov     di, message     ; DI will be our index into our message
    xor     ax, ax          ; Clear AX
print_message:
    mov     al, [di]            ; Copy a character from the message into AL
    mov     BYTE [es:bx], al    ; and move it into video memory.
    add     bx, 2               ; Move forward 2 bytes in video memory (to skip the attribute byte)
    inc     di                  ; and move forward 1 byte in the message.

    cmp     BYTE [di], 0        ; See if we've reached the end of the message
    jne     print_message

loop_forever:
    hlt
    jmp     loop_forever

message:
    db "Hello, from Real Mode!", 0

times 512 - 2 - ($ - $$) db 0
db 0x55, 0xAA
