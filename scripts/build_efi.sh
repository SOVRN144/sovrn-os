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
  # Try to locate gnu-efi bits on Debian/Ubuntu
  LDS=$(find /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu -name elf_x86_64_efi.lds -print -quit 2>/dev/null || true)
  CRT=$(find /usr/lib /usr/lib64 /usr/lib/x86_64-linux-gnu -name crt0-efi-x86_64.o -print -quit 2>/dev/null || true)

  LIBDIR=""
  if command -v dpkg >/dev/null 2>&1; then
    LIBDIR=$(dpkg -L gnu-efi 2>/dev/null | grep -E '/lib.*/libgnuefi\.a$' | xargs -r dirname | head -1 || true)
  fi
  [ -z "${LIBDIR:-}" ] && for d in /usr/lib/x86_64-linux-gnu /usr/lib64 /usr/lib; do
    [ -f "$d/libgnuefi.a" ] && { LIBDIR="$d"; break; }
  done

  if [ -d /usr/include/efi ] && [ -n "${LDS:-}" ] && [ -n "${CRT:-}" ] && [ -n "${LIBDIR:-}" ]; then
    CFLAGS="-I/usr/include/efi -I/usr/include/efi/x86_64 -fno-stack-protector -fshort-wchar -fpic -fshort-wchar -fno-asynchronous-unwind-tables -fno-unwind-tables -fno-pie -fpic -fshort-wchar -mno-red-zone  -Wall -Wextra -Os"
    # allow CI to inject e.g. -DSOVRN_EXIT_AFTER_BANNER
    CFLAGS="${CFLAGS} ${EFI_DEFINES:-}"

    gcc $CFLAGS -c "$SRC" -o "$OBJDIR/efi_main.o"

    # Link via GCC so multi-arch lib paths are honored, and add proper flags
    gcc -nostdlib -Wl,-shared -Wl,-Bsymbolic -Wl,-T,"$LDS" -L"$LIBDIR" \
        "$CRT" "$OBJDIR/efi_main.o" -o "$OBJDIR/efi_main.so" -lgnuefi -lefi -no-pie -Wl,--no-eh-frame-hdr

    # Produce a PE/COFF EFI application and stamp the subsystem
    objcopy --target=efi-app-x86_64 --subsystem=10 "$OBJDIR/efi_main.so" "$EFI"

    echo "Built $EFI (lds=$(basename "$LDS"), crt=$(basename "$CRT"), libdir=$LIBDIR)"
    exit 0
  else
    echo "Missing pieces for gnu-efi build: LDS='$LDS' CRT='$CRT' LIBDIR='$LIBDIR' inc=/usr/include/efi" >&2
  fi
fi

# Fallback for macOS devs so ISO still builds locally
printf 'UEFI placeholder\n' > "$EFI"
echo "gnu-efi not found; wrote placeholder $EFI (CI will produce real EFI)."
