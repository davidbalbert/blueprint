extern kernel_main

section .text
    ; Clear the screen
    call    kernel_main

    ; Just in case kernel_main returns
loop_forever:
    hlt
    jmp     loop_forever


; Rust wants __morestack. I don't really understand it.
global __morestack
__morestack:
    cli
    jmp     loop_forever
