#!/usr/bin/env bash
set -euo pipefail
# Ensure banner header exists
./scripts/gen_banner_h.sh

OUTDIR="boot"
OBJDIR="out/efi"
SRC="boot/efi_main.c"
EFI="$OUTDIR/BOOTX64.EFI"
mkdir -p "$OUTDIR" "$OBJDIR"

have() { command -v "$1" >/dev/null 2>&1; }

if have gcc && [ -d /usr/include/efi ] && [ -f /usr/lib/elf_x86_64_efi.lds ]; then
  # gnu-efi toolchain path (Ubuntu CI)
  CFLAGS="-I/usr/include/efi -I/usr/include/efi/x86_64 -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -DEFI_FUNCTION_WRAPPER -Wall -Wextra -Os"
  LDFLAGS="-nostdlib -znocombreloc -T /usr/lib/elf_x86_64_efi.lds"
  gcc $CFLAGS -c "$SRC" -o "$OBJDIR/efi_main.o"
  ld $LDFLAGS /usr/lib/crt0-efi-x86_64.o "$OBJDIR/efi_main.o" -o "$OBJDIR/efi_main.so" -lgnuefi -lefi
  objcopy --target=efi-app-x86_64 "$OBJDIR/efi_main.so" "$EFI"
  echo "Built $EFI via gnu-efi"
else
  # Fallback (dev on mac): keep placeholder so ISO still builds
  printf 'UEFI placeholder\n' > "$EFI"
  echo "gnu-efi not found; wrote placeholder $EFI (CI will produce real EFI)."
fi
