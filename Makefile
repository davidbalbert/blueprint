RUST_SRC := /Users/david/Development/rust
RUSTC_TARGET := x86_64-unknown-linux-gnu

UNAME := $(shell uname)
ifeq ($(UNAME),Darwin)
	PLATFORM := darwin
endif
ifeq ($(UNAME),Linux)
	PLATFORM := linux
endif


ifeq ($(PLATFORM), darwin)
	CUSTOM_LD := tools/bin/x86_64-linux-gnu-ld
	LD := tools/bin/x86_64-linux-gnu-ld
endif
ifeq ($(PLATFORM), linux)
	CUSTOM_LD := ""
	LD := ld
endif

hd.img: boot1.bin kernel.bin
	cat boot1.bin kernel.bin > hd.img

boot1.bin: boot1.s
	nasm -f bin -o boot1.bin boot1.s

kernel.bin: boot2.o kernel.o linker.ld $(CUSTOM_LD)
	$(LD) -T linker.ld -o kernel.bin boot2.o kernel.o

boot2.o: boot2.s
	nasm -f elf64 boot2.s

kernel.o: kernel.rs libcore.rlib
	rustc kernel.rs -O --emit obj --extern core=./libcore.rlib --target=${RUSTC_TARGET}

libcore.rlib:
	rustc ${RUST_SRC}/src/libcore/lib.rs --target ${RUSTC_TARGET}

# Custom binutils for OS X
tools/bin/x86_64-linux-gnu-ld:
	sh scripts/fetch_binutils.sh

.PHONY: run
run: hd.img
	qemu-system-x86_64 -monitor stdio -cpu SandyBridge hd.img

.PHONY: clean

clean:
	rm -f *.o *.bin *.rlib hd.img
