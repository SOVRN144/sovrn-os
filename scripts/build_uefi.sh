#!/bin/sh
set -eux
umask 022

# workspace
mkdir -p out boot out/compat/Protocol

# ---- SerialIo header shim (avoid recursion with include_next) --------------
cat > out/compat/Protocol/SerialIo.h <<'EOF'
#ifndef SOVRN_SERIALIO_SHIM_GUARD
#define SOVRN_SERIALIO_SHIM_GUARD 1

#if defined(__has_include)
/* Debian/Ubuntu gnu-efi headers live here */
# if __has_include(<efi/protocol/serial-io.h>)
#  include <efi/protocol/serial-io.h>
/* EDK2 style path: skip this shim dir and include the next match */
# elif __has_include(<Protocol/SerialIo.h>)
#  if defined(__clang__) || defined(__GNUC__)
#   include_next <Protocol/SerialIo.h>
#  else
#   include <Protocol/SerialIo.h>
#  endif
# else
#  error "UEFI SerialIo header not found on this runner"
# endif
#else
/* No __has_include: try to skip this directory anyway */
# if defined(__clang__) || defined(__GNUC__)
#  include_next <Protocol/SerialIo.h>
# else
#  include <Protocol/SerialIo.h>
# endif
#endif

#endif /* SOVRN_SERIALIO_SHIM_GUARD */
EOF

# Ensure buildinfo header exists
[ -f out/buildinfo_autogen.h ] || scripts/buildinfo.sh

# ---- Try direct PE/COFF with clang+lld ------------------------------------
# Make system EFI headers visible and also our 'out/compat'
if clang -target x86_64-pc-win32-coff -fuse-ld=lld \
  -ffreestanding -fshort-wchar -fno-stack-protector -fno-pic -mno-red-zone \
  -Iout -Iboot -Iout/compat \
  -I/usr/include/efi -I/usr/include/efi/x86_64 -I/usr/include/efi/protocol \
  -Wl,/subsystem:efi_application -Wl,/entry:efi_main -nostdlib \
  boot/uefi_main.c -o boot/BOOTX64.EFI
then
  exit 0
fi

# ---- Fallback: link via gnu-efi -------------------------------------------
EFIINC=/usr/include/efi
EFIARCH=x86_64
EFIINCS="-Iout -Iboot -Iout/compat -I$EFIINC -I$EFIINC/$EFIARCH -I$EFIINC/protocol"

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
