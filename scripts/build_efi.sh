#!/usr/bin/env bash
set -euo pipefail
./scripts/gen_banner_h.sh

OUTDIR="boot"
OBJDIR="out/efi"
SRC="boot/efi_main.c"
EFI="$OUTDIR/BOOTX64.EFI"
mkdir -p "$OUTDIR" "$OBJDIR"

have() { command -v "$1" >/dev/null 2>&1; }

if have gcc; then
  LDS=$(find /usr/lib -name elf_x86_64_efi.lds -print -quit 2>/dev/null || true)
  CRT=$(find /usr/lib -name crt0-efi-x86_64.o -print -quit 2>/dev/null || true)
  if [ -d /usr/include/efi ] && [ -n "${LDS:-}" ] && [ -n "${CRT:-}" ]; then
    CFLAGS="-I/usr/include/efi -I/usr/include/efi/x86_64 -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -DEFI_FUNCTION_WRAPPER -Wall -Wextra -Os"
    LDFLAGS="-nostdlib -znocombreloc -T ${LDS}"
    gcc $CFLAGS -c "$SRC" -o "$OBJDIR/efi_main.o"
    ld $LDFLAGS "${CRT}" "$OBJDIR/efi_main.o" -o "$OBJDIR/efi_main.so" -lgnuefi -lefi
    objcopy --target=efi-app-x86_64 "$OBJDIR/efi_main.so" "$EFI"
    echo "Built $EFI via gnu-efi"
    exit 0
  fi
fi

# Fallback for dev on macOS: keep placeholder so ISO still builds
printf 'UEFI placeholder\n' > "$EFI"
echo "gnu-efi not found; wrote placeholder $EFI (CI will produce real EFI)."
