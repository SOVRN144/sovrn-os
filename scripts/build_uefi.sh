#!/bin/sh
set -eux
inc=/usr/include/efi
inc64=/usr/include/efi/x86_64
mkdir -p boot out
clang -target x86_64-pc-win32-coff -ffreestanding -fshort-wchar -mno-red-zone \
      -fno-stack-protector -fno-asynchronous-unwind-tables -fno-unwind-tables \
      -I"$inc" -I"$inc64" -Iout -c boot/efi_main.c -o out/efi_main.obj
lld-link /subsystem:efi_application /entry:efi_main /machine:x64 \
         /out:boot/BOOTX64.EFI out/efi_main.obj
dd if=/dev/zero of=esp.img bs=1M count=32 status=none
mkfs.vfat -F 32 -n SOVRN esp.img >/dev/null
mmd   -i esp.img ::/EFI ::/EFI/BOOT
mcopy -i esp.img -v boot/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI
