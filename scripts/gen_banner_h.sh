#!/usr/bin/env bash
set -euo pipefail
SRC="out/BANNER.txt"
DST="boot/banner.h"
[ -f "$SRC" ] || { echo "Missing $SRC; run: ./scripts/set_env.sh && make"; exit 1; }

kv(){ grep "^$1=" "$SRC" | sed 's/^[^=]*=//' || true; }
PRODUCT=$(kv PRODUCT)
VERSION=$(kv VERSION)
COMMIT=$(kv COMMIT)
EPOCH=$(kv BUILD_EPOCH)
TRIPLE=$(kv TRIPLE)
TOOLCHAIN=$(kv TOOLCHAIN)

LINE="SOVRN ENGINE ONLINE | VERSION=$VERSION | COMMIT=$COMMIT | EPOCH=$EPOCH | TRIPLE=$TRIPLE | TOOLCHAIN=$TOOLCHAIN"

# Escape backslashes and quotes for safe C string literals
ESC=$(printf '%s' "$LINE" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
PROD_ESC=$(printf '%s' "$PRODUCT"   | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
VER_ESC=$(printf  '%s' "$VERSION"   | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
COM_ESC=$(printf  '%s' "$COMMIT"    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
EPO_ESC=$(printf  '%s' "$EPOCH"     | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
TRI_ESC=$(printf  '%s' "$TRIPLE"    | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
TOOL_ESC=$(printf '%s' "$TOOLCHAIN" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')

mkdir -p "$(dirname "$DST")"
cat > "$DST" <<HDR
#pragma once
#define BANNER_ASCII "$ESC"
#define BANNER_WIDE  L"$ESC"
#define BANNER_PRODUCT   L"$PROD_ESC"
#define BANNER_VERSION   L"$VER_ESC"
#define BANNER_COMMIT    L"$COM_ESC"
#define BANNER_EPOCH     L"$EPO_ESC"
#define BANNER_TRIPLE    L"$TRI_ESC"
#define BANNER_TOOLCHAIN L"$TOOL_ESC"
HDR
echo "Wrote $DST"
