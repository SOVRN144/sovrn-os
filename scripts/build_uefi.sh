#!/bin/sh
set -eux
umask 022
mkdir -p out boot out/compat/Protocol

# Make an EDK2-style shim that includes the Debian/gnu-efi header
echo '#include <efi/protocol/serial-io.h>' > out/compat/Protocol/SerialIo.h

# Ensure build info header exists
[ -f out/buildinfo_autogen.h ] || scripts/buildinfo.sh

# --- Try direct PE/COFF with clang+lld --------------------------------------
if clang -target x86_64-pc-win32-coff -fuse-ld=lld \
  -ffreestanding -fshort-wchar -fno-stack-protector -fno-pic -mno-red-zone \
  -Iout -Iout/compat -Iboot \
  -Wl,/subsystem:efi_application -Wl,/entry:efi_main -nostdlib \
  boot/uefi_main.c -o boot/BOOTX64.EFI
then
  exit 0
fi

# --- Fallback: link via gnu-efi ---------------------------------------------
EFIINC=/usr/include/efi
EFIARCH=x86_64
EFIINCS="-Iout -Iout/compat -Iboot -I$EFIINC -I$EFIINC/$EFIARCH -I$EFIINC/protocol"

# Find ldscript/crt0 in common Debian paths if not discoverable
LDSCRIPT="$(ldconfig -p 2>/dev/null | grep -Eo '/.*/elf_x86_64_efi\.lds' | head -n1 || true)"
CRT0="$(ldconfig -p 2>/dev/null | grep -Eo '/.*/crt0-efi-x86_64\.o' | head -n1 || true)"
[ -z "$LDSCRIPT" ] && [ -f /usr/lib/x86_64-linux-gnu/gnu-efi/elf_x86_64_efi.lds ] && LDSCRIPT=/usr/lib/x86_64-linux-gnu/gnu-efi/elf_x86_64_efi.lds
[ -z "$CRT0" ] && [ -f /usr/lib/x86_64-linux-gnu/gnu-efi/crt0-efi-x86_64.o ] && CRT0=/usr/lib/x86_64-linux-gnu/gnu-efi/crt0-efi-x86_64.o

clang -MMD -MP -c -O2 \
  -ffreestanding -fshort-wchar -fno-stack-protector -fno-pic -mno-red-zone \
  $EFIINCS \
  boot/uefi_main.c -o out/uefi_main.o

ld -nostdlib -znocombreloc -shared -Bsymbolic \
  -T "$LDSCRIPT" "$CRT0" out/uefi_main.o -o out/uefi_main.so \
  -lefi -lgnuefi

objcopy \
  -j .text -j .sdata -j .data -j .dynamic -j .dynsym \
  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc \
  --target efi-app-x86_64 \
  out/uefi_main.so boot/BOOTX64.EFI
