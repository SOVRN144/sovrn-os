CROSS ?= x86_64-elf-
HAS_CROSS := $(shell command -v $(CROSS)gcc 2>/dev/null)
OS := $(shell uname)
OUT := out

# Toolchain + link mode
ifeq ($(HAS_CROSS),)
  CC := cc
  STATIC :=
  # Host CC: platform-specific entry/flags
  ifeq ($(OS),Darwin)
    ENTRY := _main
    NO_PIE := -Wl,-no_pie
  else
    ENTRY := main
    NO_PIE :=
  endif
else
  CC := $(CROSS)gcc
  STATIC := -static
  ENTRY := main
  NO_PIE :=
endif

CFLAGS  := -ffreestanding -Os -nostdlib -ffile-prefix-map=$(PWD)=. -Wall -Wextra
LDFLAGS := $(STATIC) -nostdlib -Wl,-e,$(ENTRY) $(NO_PIE)

all: kernel.bin $(OUT)/BUILDINFO

$(OUT)/BUILDINFO: scripts/buildinfo.sh
	mkdir -p $(OUT)
	./scripts/buildinfo.sh > $(OUT)/BUILDINFO

kernel.o: kernel/stub.c
	$(CC) $(CFLAGS) -c $< -o $@

kernel.bin: kernel.o
	$(CC) -o $@ $^ $(LDFLAGS)
	./scripts/size_gate.sh $@ 524288

clean:
	rm -f kernel.o kernel.bin
	rm -rf $(OUT)
