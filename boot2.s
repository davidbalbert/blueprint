bits    64
org     0x7E00

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
    db "Hello, Blueprint!", 0

times 512 - ($ - $$) db 0
