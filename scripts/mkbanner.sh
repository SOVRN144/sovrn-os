#!/usr/bin/env bash
set -euo pipefail
SRC="out/BUILDINFO"
OUTF="out/BANNER.txt"
PRODUCT="SOVRN OS"

# Read fields (fallbacks are safe)
get(){ grep "^$1=" "$SRC" | cut -d= -f2- || true; }
VERSION="$(get GIT_DESCRIBE)"; [ -n "$VERSION" ] || VERSION="v0.0.0-forge"
COMMIT="$(get GIT_COMMIT | cut -c1-12)"
EPOCH="$(get BUILD_EPOCH)"; [ -n "$EPOCH" ] || EPOCH="$(date -u +%s)"
TRIPLE="$(get CROSS_TRIPLE)"
CCLINE="$(get TOOLCHAIN_CC)"

mkdir -p out
{
  printf "PRODUCT=%s\n"    "$PRODUCT"
  printf "VERSION=%s\n"    "$VERSION"
  printf "COMMIT=%s\n"     "$COMMIT"
  printf "BUILD_EPOCH=%s\n" "$EPOCH"
  printf "TRIPLE=%s\n"     "$TRIPLE"
  printf "TOOLCHAIN=%s\n"  "$CCLINE"
} > "$OUTF"
echo "Banner → $OUTF"
