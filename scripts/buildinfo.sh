#!/usr/bin/env bash
set -euo pipefail
echo "BUILD_EPOCH=$(date -u +%s)"
echo "GIT_COMMIT=$(git rev-parse HEAD)"
echo "GIT_DESCRIBE=$(git describe --tags --always --dirty || true)"
echo "BUILD_ID=$(uname -s)-$(uname -m)"
if command -v x86_64-elf-gcc >/dev/null 2>&1; then
  echo "TOOLCHAIN_CC=$(x86_64-elf-gcc --version | head -1)"
  echo "TOOLCHAIN_LD=$(x86_64-elf-ld --version | head -1)"
  echo "CROSS_TRIPLE=x86_64-elf"
else
  echo "TOOLCHAIN_CC=$(cc --version | head -1)"
  echo "TOOLCHAIN_LD=$(ld -v 2>/dev/null || echo ld)"
  echo "CROSS_TRIPLE="
fi
echo "SOURCE_DATE_EPOCH=${SOURCE_DATE_EPOCH:-}"
