FROM ubuntu:24.04

RUN set -eux; \
    apt-get update -qq; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
      software-properties-common ca-certificates; \
    add-apt-repository -y universe; \
    apt-get update -qq; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
      clang lld binutils nasm \
      mtools dosfstools xorriso \
      gnu-efi gnu-efi-dev uuid-dev; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work
