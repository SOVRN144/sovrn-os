#!/usr/bin/env bash
set -euo pipefail
./scripts/gen_banner_h.sh

OUTDIR="boot"
OBJDIR="out/efi"
SRC="boot/efi_main.c"
EFI="$OUTDIR/BOOTX64.EFI"
mkdir -p "$OUTDIR" "$OBJDIR"

have() { command -v "$1" >/dev/null 2>&1; }
pick_objcopy() {
  if have objcopy; then echo objcopy; elif have gobjcopy; then echo gobjcopy; else return 1; fi
}

if have gcc; then
  # Try to find gnu-efi bits on common distros
  LDS=$(find /usr/lib /usr/lib64 /usr/local/lib -name 'elf_x86_64_efi.lds' -print -quit 2>/dev/null || true)
  CRT=$(find /usr/lib /usr/lib64 /usr/local/lib -name 'crt0-efi-x86_64.o' -print -quit 2>/dev/null || true)
  if [ -d /usr/include/efi ] && [ -n "${LDS:-}" ] && [ -n "${CRT:-}" ]; then
    CFLAGS="-I/usr/include/efi -I/usr/include/efi/x86_64 -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -DEFI_FUNCTION_WRAPPER -Wall -Wextra -Os"
    LDFLAGS="-nostdlib -znocombreloc -T ${LDS} -shared -Bsymbolic"
    gcc $CFLAGS -c "$SRC" -o "$OBJDIR/efi_main.o"
    ld  $LDFLAGS "${CRT}" "$OBJDIR/efi_main.o" -o "$OBJDIR/efi_main.so" -L/usr/lib -lgnuefi -lefi

    # Make a proper PE/COFF EFI Application
    OBJCOPY=$(pick_objcopy) || {
      echo "objcopy/gobjcopy not found"; exit 1;
    }
    "$OBJCOPY" \
      -j .text -j .sdata -j .data -j .dynamic -j .rodata \
      -j .rel -j .rela -j .rel.* -j .rela.* -j .reloc \
      --subsystem=10 \
      --target=efi-app-x86_64 \
      "$OBJDIR/efi_main.so" "$EFI"

    echo "Built $EFI via gnu-efi with Subsystem=EFI application"
    exit 0
  fi
fi

# Fallback for dev on macOS: keep placeholder so ISO still builds
printf 'UEFI placeholder\n' > "$EFI"
echo "gnu-efi not found; wrote placeholder $EFI (CI will produce real EFI)."
