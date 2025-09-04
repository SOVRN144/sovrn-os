#!/bin/sh
set -eux

umask 022
mkdir -p out boot

EFINC=/usr/include/efi
EFIARCH=x86_64
EFINCS="-Iout -I${EFINC} -I${EFINC}/${EFIARCH} -I${EFINC}/protocol -include boot/bi_compat.h"

find_first() {
  for p in "$@"; do [ -f "$p" ] && { echo "$p"; return 0; }; done
  name="$(basename "$1")"
  find /usr -type f -name "$name" 2>/dev/null | head -n1
}

LDSCRIPT="$(find_first \
  /usr/lib/x86_64-linux-gnu/gnu-efi/elf_x86_64_efi.lds \
  /usr/lib/gnuefi/elf_x86_64_efi.lds \
  /usr/lib64/gnuefi/elf_x86_64_efi.lds \
  /usr/lib/elf_x86_64_efi.lds \
)"
[ -n "$LDSCRIPT" ] && [ -f "$LDSCRIPT" ] || { echo "Missing elf_x86_64_efi.lds"; exit 1; }

CRT0="$(find_first \
  /usr/lib/x86_64-linux-gnu/gnu-efi/crt0-efi-x86_64.o \
  /usr/lib/gnuefi/crt0-efi-x86_64.o \
  /usr/lib64/gnuefi/crt0-efi-x86_64.o \
  /usr/lib/crt0-efi-x86_64.o \
)"
[ -n "$CRT0" ] && [ -f "$CRT0" ] || { echo "Missing crt0-efi-x86_64.o"; exit 1; }

LIBEFI="$(find_first \
  /usr/lib/x86_64-linux-gnu/gnu-efi/libefi.a \
  /usr/lib/gnuefi/libefi.a \
  /usr/lib64/gnuefi/libefi.a \
  /usr/lib/libefi.a \
)"
LIBGNU="$(find_first \
  /usr/lib/x86_64-linux-gnu/gnu-efi/libgnuefi.a \
  /usr/lib/gnuefi/libgnuefi.a \
  /usr/lib64/gnuefi/libgnuefi.a \
  /usr/lib/libgnuefi.a \
)"
[ -f "$LIBEFI" ] || { echo "Missing libefi.a"; exit 1; }
[ -f "$LIBGNU" ] || { echo "Missing libgnuefi.a"; exit 1; }

# Compile with -fPIC (key change)
clang -MMD -MP -c -O2 -ffreestanding -fshort-wchar -fno-stack-protector -fPIC -mno-red-zone \
      $EFINCS boot/uefi_main.c -o out/uefi_main.o

# Link using the found script, CRT0, and static archives
ld -nostdlib -znocombreloc -T "$LDSCRIPT" -shared -Bsymbolic \
   -o out/uefi_main.so "$CRT0" out/uefi_main.o "$LIBEFI" "$LIBGNU"

# Convert ELF -> PE/COFF .EFI
objcopy -j .text -j .sdata -j .data -j .dynamic -j .dynsym \
        -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc \
        --target=efi-app-x86_64 out/uefi_main.so boot/BOOTX64.EFI
