#!/bin/sh
set -eux
nasm -f bin boot/mbr_stage2.asm -Iout/ -o out/stage2.bin
nasm -f bin boot/mbr_stage1.asm -o out/stage1.bin
dd if=/dev/zero of=boot.img bs=1024 count=1440 status=none
dd if=out/stage1.bin of=boot.img conv=notrunc status=none
dd if=out/stage2.bin of=boot.img bs=512 seek=1 conv=notrunc status=none
