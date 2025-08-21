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
  # Find headers, linker script, crt, and libs across common Ubuntu layouts
  INC_BASE="/usr/include/efi"
  INC_X64="$INC_BASE/x86_64"
  LDS=$(find /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu /usr/lib/gnu-efi -name elf_x86_64_efi.lds -print -quit 2>/dev/null || true)
  CRT=$(find /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu /usr/lib/gnu-efi -name crt0-efi-x86_64.o -print -quit 2>/dev/null || true)
  LIBDIR=$(dirname "$(find /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu /usr/lib/gnu-efi -name libgnuefi.a -print -quit 2>/dev/null || echo /nonexistent)") || true

  if [ -d "$INC_BASE" ] && [ -d "$INC_X64" ] && [ -n "${LDS:-}" ] && [ -n "${CRT:-}" ] && [ -d "${LIBDIR:-}" ]; then
    CFLAGS="-I$INC_BASE -I$INC_X64 -fno-stack-protector -fpic -fshort-wchar -mno-red-zone -DEFI_FUNCTION_WRAPPER -Wall -Wextra -Os"
    LDFLAGS="-nostdlib -shared -Bsymbolic -znocombreloc -T $LDS -L$LIBDIR"
    gcc $CFLAGS -c "$SRC" -o "$OBJDIR/efi_main.o"
    ld  $LDFLAGS "$CRT" "$OBJDIR/efi_main.o" -lgnuefi -lefi -o "$OBJDIR/efi_main.so"
    objcopy --target=efi-app-x86_64 "$OBJDIR/efi_main.so" "$EFI"
    echo "Built $EFI via gnu-efi"
    exit 0
  else
    echo "diag: INC_BASE=$INC_BASE  INC_X64=$INC_X64"
    echo "diag: LDS=$LDS"
    echo "diag: CRT=$CRT"
    echo "diag: LIBDIR=$LIBDIR"
  fi
fi

# Fallback for dev on macOS: keep placeholder so ISO still builds
printf 'UEFI placeholder\n' > "$EFI"
echo "gnu-efi not found; wrote placeholder $EFI (CI will produce real EFI)."
