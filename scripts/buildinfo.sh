#!/bin/sh
set -eu
PRODUCT="${PRODUCT:-SOVRN}"
VERSION="${VERSION:-v0.1.0-phase2}"
COMMIT="${COMMIT:-$(git rev-parse --short HEAD 2>/dev/null || echo UNKNOWN)}"
BUILD_EPOCH="${BUILD_EPOCH:-$(date -u +%s)}"
TRIPLE="x86_64-pc-win32-coff"
TOOLCHAIN="$(clang --version 2>/dev/null | head -1 || echo clang)"

cat > out/buildinfo_autogen.h <<EOF
#define BI_PRODUCT      "${PRODUCT}"
#define BI_VERSION      "${VERSION}"
#define BI_COMMIT       "${COMMIT}"
#define BI_BUILD_EPOCH  "${BUILD_EPOCH}"
#define BI_TRIPLE       "${TRIPLE}"
#define BI_TOOLCHAIN    "${TOOLCHAIN}"
EOF

cat > out/buildinfo.inc <<EOF
%define BI_PRODUCT_STR     "${PRODUCT}"
%define BI_VERSION_STR     "${VERSION}"
%define BI_COMMIT_STR      "${COMMIT}"
%define BI_BUILD_EPOCH_STR "${BUILD_EPOCH}"
%define BI_TRIPLE_STR      "${TRIPLE}"
%define BI_TOOLCHAIN_STR   "${TOOLCHAIN}"
EOF
