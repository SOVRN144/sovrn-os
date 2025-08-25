#!/bin/sh
set -eux

# fresh 16 MiB ESP, format as FAT16 (works at this size)
rm -f esp.img
dd if=/dev/zero of=esp.img bs=1M count=16 status=none
mkfs.vfat -F 16 -n SOVRN esp.img >/dev/null

# populate ESP
mmd   -i esp.img ::/EFI ::/EFI/BOOT
mcopy -i esp.img boot/BOOTX64.EFI ::/EFI/BOOT/BOOTX64.EFI
mdir  -i esp.img ::/EFI/BOOT

# mirror the EFI tree into the ISO filesystem and carry the ESP along
mkdir -p isoroot
rm -rf isoroot/EFI
mcopy -s -i esp.img ::/EFI isoroot/
cp -f esp.img isoroot/efi.img
