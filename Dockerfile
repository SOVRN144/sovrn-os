FROM debian:bookworm-slim

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      clang lld binutils nasm \
      mtools dosfstools xorriso \
      gnu-efi uuid-dev \
      ca-certificates make; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work
