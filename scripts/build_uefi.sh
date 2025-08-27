#!/bin/sh
set -eux

umask 022
mkdir -p out boot

# Include dirs for gnu-efi headers
EFINC=/usr/include/efi
EFIARCH=x86_64
EFINCS="-Iout -I$EFINC -I$EFINC/$EFIARCH -I$EFINC/protocol"

# Find gnu-efi linker script & crt0
ldconfig -p || true
LDSCRIPT=$(ldconfig -p | grep -Eo '/.*/elf_x86_64_efi\.lds' | head -n1)
CRT0=$(ldconfig -p | grep -Eo '/.*/crt0-efi-x86_64\.o' | head -n1)
[ -f "$LDSCRIPT" ] || LDSCRIPT=/usr/lib/x86_64-linux-gnu/gnu-efi/elf_x86_64_efi.lds
[ -f "$CRT0" ]     || CRT0=/usr/lib/x86_64-linux-gnu/gnu-efi/crt0-efi-x86_64.o

# Compile
clang -MMD -MP -c -O2 -ffreestanding -fshort-wchar -fno-stack-protector -fno-pic -mno-red-zone \
  -Iout $EFINCS boot/uefi_main.c -o out/uefi_main.o

# Link with gnu-efi
ld -nostdlib -znocombreloc -shared -Bsymbolic \
   -T "$LDSCRIPT" "$CRT0" out/uefi_main.o -o out/uefi_main.so \
   -lefi -lgnuefi

# Convert to PE/COFF
objcopy \
  -j .text -j .sdata -j .data -j .dynamic -j .dynsym \
  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc \
  --target efi-app-x86_64 \
  out/uefi_main.so boot/BOOTX64.EFI
