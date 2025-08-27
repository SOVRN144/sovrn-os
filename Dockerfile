FROM debian:stable-slim

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
      clang lld binutils nasm \
      mtools dosfstools xorriso \
      gnu-efi \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
