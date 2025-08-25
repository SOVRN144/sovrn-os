[org 0x7E00]
[bits 16]
%include "out/buildinfo.inc"

COM1 equ 0x3F8

; Always enter here even if functions appear above
jmp start
nop

; ----- serial -----
serial_init:
    mov dx, COM1+1    ; disable IRQs
    xor al, al
    out dx, al
    mov dx, COM1+3    ; DLAB=1
    mov al, 0x80
    out dx, al
    mov dx, COM1+0    ; 115200 baud (divisor 1)
    mov al, 0x01
    out dx, al
    mov dx, COM1+1
    xor al, al
    out dx, al
    mov dx, COM1+3    ; 8N1, DLAB=0
    mov al, 0x03
    out dx, al
    mov dx, COM1+2    ; FIFO on
    mov al, 0xC7
    out dx, al
    mov dx, COM1+4    ; DTR|RTS|OUT2
    mov al, 0x0B
    out dx, al
    ret

serial_putc:          ; AL = char
    mov  bl, al
.wait:
    mov  dx, COM1+5
    in   al, dx
    test al, 0x20
    jz   .wait
    mov  dx, COM1
    mov  al, bl
    out  dx, al
    ret

serial_puts:          ; DS:SI -> asciz
.next:
    lodsb
    test al, al
    jz   .done
    call serial_putc
    jmp  .next
.done:
    ret

; ----- VGA (top-left, white on black) -----
vga_puts:             ; DS:SI -> asciz
    push ax
    push bx
    push cx
    push di
    push es
    mov  ax, 0xB800
    mov  es, ax
    xor  di, di
    mov  ah, 0x0F
.vloop:
    lodsb
    test al, al
    jz   .vok
    cmp  al, 10
    jne  .vwrite
    mov  bx, di
    mov  cx, 160
    xor  dx, dx
    mov  ax, bx
    div  cx
    inc  ax
    mul  cx
    mov  di, ax
    jmp  .vloop
.vwrite:
    stosw
    jmp  .vloop
.vok:
    pop  es
    pop  di
    pop  cx
    pop  bx
    pop  ax
    ret

; ----- banner -----
banner:
    db "SOVRN ENGINE ONLINE "
    db "PRODUCT=",     BI_PRODUCT_STR,     " "
    db "VERSION=",     BI_VERSION_STR,     " "
    db "COMMIT=",      BI_COMMIT_STR,      " "
    db "BUILD_EPOCH=", BI_BUILD_EPOCH_STR, " "
    db "TRIPLE=",      BI_TRIPLE_STR,      " "
    db "TOOLCHAIN=",   BI_TOOLCHAIN_STR,   13,10,0

; ----- entry -----
start:
    ; arrived via far jump to 0000:7E00
    xor ax, ax
    mov ds, ax
    mov ss, ax
    mov sp, 0x7C00

    ; breadcrumb '2' so we know stage-2 actually ran
    mov ah, 0x0E
    mov al, '2'
    int 0x10

    call serial_init
    mov  si, banner
    call vga_puts
    mov  si, banner
    call serial_puts

.hang:
    hlt
    jmp .hang
