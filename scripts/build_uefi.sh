#!/bin/sh
set -eux
umask 022

# directories for generated files
mkdir -p out boot out/compat/Protocol

# --- SerialIo shim: use the real gnu-efi header, or fail clearly -------------
cat > out/compat/Protocol/SerialIo.h <<'EOF'
#if defined(__has_include) && __has_include(<efi/protocol/serial-io.h>)
  #include <efi/protocol/serial-io.h>
#else
  #error "Missing UEFI headers: install gnu-efi-dev (provides <efi/protocol/serial-io.h>)"
#endif
EOF

# make sure build info exists
[ -f out/buildinfo_autogen.h ] || scripts/buildinfo.sh

# --- Build BOOTX64.EFI via gnu-efi ------------------------------------------
EFIINC=/usr/include/efi
EFIARCH=x86_64
EFIINCS="-Iout -Iboot -Iout/compat -I${EFIINC} -I${EFIINC}/${EFIARCH} -I${EFIINC}/protocol"

# discover linker script & crt0 (paths differ by distro)
LDSCRIPT="$(ldconfig -p 2>/dev/null | grep -Eo '/.*/elf_x86_64_efi\.lds' | head -n1 || true)"
CRT0="$(ldconfig -p 2>/dev/null | grep -Eo '/.*/crt0-efi-x86_64\.o' | head -n1 || true)"
[ -z "$LDSCRIPT" ] && [ -f /usr/lib/x86_64-linux-gnu/gnu-efi/elf_x86_64_efi.lds ] && LDSCRIPT=/usr/lib/x86_64-linux-gnu/gnu-efi/elf_x86_64_efi.lds
[ -z "$CRT0" ] && [ -f /usr/lib/x86_64-linux-gnu/gnu-efi/crt0-efi-x86_64.o ] && CRT0=/usr/lib/x86_64-linux-gnu/gnu-efi/crt0-efi-x86_64.o

# compile and link
clang -MMD -MP -O2 -ffreestanding -fshort-wchar -fno-stack-protector -fno-pic -mno-red-zone \
      ${EFIINCS} \
      -c boot/uefi_main.c -o out/uefi_main.o

ld -nostdlib -znocombreloc -shared -Bsymbolic \
   -T "$LDSCRIPT" "$CRT0" out/uefi_main.o -o out/uefi_main.so \
   -lefi -lgnuefi

objcopy \
  -j .text -j .sdata -j .data -j .dynamic -j .dynsym \
  -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc \
  --target efi-app-x86_64 \
  out/uefi_main.so boot/BOOTX64.EFI
