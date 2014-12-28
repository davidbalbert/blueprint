extern stage2_main

section .text
    ; Clear the screen
    call    stage2_main

    ; Just in case kernel_main returns
loop_forever:
    hlt
    jmp     loop_forever

; From https://github.com/thepowersgang/rust_os/blob/957ece57bfdae826075755c9f9491a271b19e724/Kernel/arch/amd64/start.asm

;; RDI = Address
;; RSI = Value
;; RDX = Count
global memset
memset:
  mov rax, rsi
  mov rcx, rdx
  rep stosb
  ret
;; RDI = Destination
;; RSI = Source
;; RDX = Count
global memcpy
memcpy:
  mov rcx, rdx
  rep movsb
  ret
;; RDI = Destination
;; RSI = Source
;; RDX = Count
global memmove
memmove:
  cmp rdi, rsi
  jz .ret   ; if RDI == RSI, do nothinbg
  jb memcpy ; if RDI < RSI, it's safe to do a memcpy
  add rsi, rdx  ; RDI > RSI
  cmp rdi, rsi
  jae memcpy  ; if RDI >= RSI + RDX, then the two regions don't overlap, and memcpy is safe
  ; Reverse copy (add count to both addresses, and set DF)
  add rdi, rdx
  dec rdi
  dec rsi
  std
  mov rcx, rdx
  rep movsb
  cld
.ret:
  ret
