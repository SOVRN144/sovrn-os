FROM debian:bookworm-slim

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
      clang lld binutils nasm \
      mtools dosfstools xorriso \
      gnu-efi gnu-efi-dev uuid-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
