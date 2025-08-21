CROSS ?= x86_64-elf-
HAS_CROSS := $(shell command -v $(CROSS)gcc 2>/dev/null)

ifeq ($(HAS_CROSS),)
  CC := cc
  ENTRY := _main
  STATIC :=
else
  CC := $(CROSS)gcc
  ENTRY := main
  STATIC := -static
endif

CFLAGS  := -ffreestanding -Os -nostdlib -ffile-prefix-map=$(PWD)=. -Wall -Wextra
LDFLAGS := $(STATIC) -nostdlib -Wl,-e,$(ENTRY) -Wl,-no_pie

all: kernel.bin

kernel.o: kernel/stub.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel.bin: kernel.o
	$(CC) -o $@ $^ $(LDFLAGS)
	./scripts/size_gate.sh $@ 524288

clean:
	rm -f kernel.o kernel.bin
