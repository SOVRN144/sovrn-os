FROM ubuntu:24.04

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
      clang lld binutils nasm \
      mtools dosfstools xorriso \
      gnu-efi gnu-efi-dev uuid-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
