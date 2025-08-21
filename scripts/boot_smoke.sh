#!/usr/bin/env bash
set -euo pipefail

ISO="${1:-iso/sovrn.iso}"
[ -f "$ISO" ] || { echo "ISO not found: $ISO" >&2; exit 2; }

# timeout (Linux) or gtimeout (macOS: brew install coreutils)
if command -v timeout >/dev/null 2>&1; then TIMEOUT=timeout
elif command -v gtimeout >/dev/null 2>&1; then TIMEOUT=gtimeout
else echo "Install GNU coreutils for 'gtimeout' (macOS) or use 'timeout' (Linux)." >&2; exit 2
fi

# OVMF CODE firmware
if [[ "$(uname -s)" == "Darwin" ]]; then
  CODE="$(brew --prefix)/share/qemu/edk2-x86_64-code.fd"
else
  CODE="/usr/share/OVMF/OVMF_CODE.fd"
  [[ -f "$CODE" ]] || CODE="$(ls /usr/share/OVMF/OVMF_CODE*.fd 2>/dev/null | head -1)"
fi
[ -f "$CODE" ] || { echo "OVMF CODE firmware not found"; exit 2; }

# fresh pflash vars (macOS-friendly mktemp)
VARS="$(mktemp -t ovmf_vars).fd"
qemu-img create -f raw "$VARS" 4M >/dev/null

mkdir -p out
SERLOG="out/qemu-uefi-serial.log"
: > "$SERLOG"

# log serial straight to a file; avoid piping through tee
set +e
$TIMEOUT 60s qemu-system-x86_64 \
  -machine q35 -m 256 -no-reboot -display none \
  -chardev file,id=char0,path="$SERLOG",append=off \
  -serial chardev:char0 \
  -drive if=pflash,format=raw,readonly=on,file="$CODE" \
  -drive if=pflash,format=raw,file="$VARS" \
  -boot order=d,menu=off \
  -cdrom "$ISO"
rc=$?
set -e

if grep -q "SOVRN ENGINE ONLINE" "$SERLOG"; then
  echo "Smoke OK: banner observed on serial."
  exit 0
fi

echo "Smoke FAILED (rc=$rc). Last 60 lines:"
tail -n 60 "$SERLOG"
exit 1
