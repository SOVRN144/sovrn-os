#!/bin/sh
set -eu

umask 022
mkdir -p out

PRODUCT=${PRODUCT:-SOVRN}
VERSION=${VERSION:-v0.1.0-phase2}
COMMIT=${COMMIT:-$(git rev-parse --short=12 HEAD 2>/dev/null || echo UNKNOWN)}
BUILD_EPOCH=${BUILD_EPOCH:-$(date +%s)}
TRIPLE=${TRIPLE:-x86_64-pc-win32-coff}
TOOLCHAIN=${TOOLCHAIN:-$(clang --version 2>/dev/null | head -n1 || echo unknown)}

# NASM include for BIOS stage-2
cat > out/buildinfo.inc <<INC
%define BI_PRODUCT_STR "$PRODUCT"
%define BI_VERSION_STR "$VERSION"
%define BI_COMMIT_STR "$COMMIT"
%define BI_BUILD_EPOCH_STR "$BUILD_EPOCH"
%define BI_TRIPLE_STR "$TRIPLE"
%define BI_TOOLCHAIN_STR "$TOOLCHAIN"
INC

# C header for UEFI
cat > out/buildinfo_autogen.h <<H
#pragma once
#define BI_PRODUCT_STR "$PRODUCT"
#define BI_VERSION_STR "$VERSION"
#define BI_COMMIT_STR "$COMMIT"
#define BI_BUILD_EPOCH_STR "$BUILD_EPOCH"
#define BI_TRIPLE_STR "$TRIPLE"
#define BI_TOOLCHAIN_STR "$TOOLCHAIN"
H
