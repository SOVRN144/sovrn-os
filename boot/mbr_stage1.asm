[org 0x7C00]
[bits 16]

jmp short start
nop

; print AL via BIOS teletype
putc:
    mov ah, 0x0E
    int 0x10
    ret

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00
    sti

    ; S1 (stage-1)
    mov al, 'S'   ; S
    call putc
    mov al, '1'
    call putc
    mov al, ' '
    call putc

    ; reset floppy (DL=0)
    mov dl, 0x00
    xor ah, ah
    int 0x13

    ; R1: read 17 sectors: C=0 H=0 S=2..18 -> 0000:7E00
    mov bx, 0x7E00
    mov ah, 0x02
    mov al, 17
    mov ch, 0
    mov cl, 2
    mov dh, 0
    mov dl, 0
    int 0x13
    jc  .fail
    mov al, 'R'   ; R1
    call putc
    mov al, '1'
    call putc
    mov al, ' '
    call putc

    ; R2: read 15 sectors: C=0 H=1 S=1..15 -> 0000:A000
    mov bx, 0xA000
    mov ah, 0x02
    mov al, 15
    mov ch, 0
    mov cl, 1
    mov dh, 1
    mov dl, 0
    int 0x13
    jc  .fail
    mov al, 'R'   ; R2
    call putc
    mov al, '2'
    call putc
    mov al, ' '
    call putc

    ; J: far-jump to 0000:7E00 (stage-2 entry)
    mov al, 'J'
    call putc
    mov al, ' '
    call putc

    jmp 0x0000:0x7E00

.fail:
    mov si, failmsg
.print:
    lodsb
    test al, al
    jz  .hang
    call putc
    jmp .print

.hang:
    hlt
    jmp .hang

failmsg: db " STAGE1 READ FAIL",0

times 510-($-$$) db 0
dw 0xAA55
