#!/usr/bin/env bash
set -euo pipefail
ISO=${1:-iso/sovrn_demo.iso}
CODE=OVMF_CODE_4M.fd
VARS=OVMF_VARS_SOVRN.fd
[[ -f "$VARS" ]] || cp OVMF_VARS_4M.fd "$VARS"

exec qemu-system-x86_64 \
  -machine q35,accel=tcg -m 256 -no-reboot -net none \
  -drive if=pflash,format=raw,readonly=on,file="$CODE" \
  -drive if=pflash,format=raw,file="$VARS" \
  -cdrom "$ISO" -boot order=d,menu=on \
  -display cocoa -serial stdio
