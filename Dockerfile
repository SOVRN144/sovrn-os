FROM debian:stable-slim

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
      clang lld binutils mtools dosfstools gnu-efi nasm xorriso && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /work
ENTRYPOINT ["/bin/sh"]
