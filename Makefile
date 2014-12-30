RUST_SRC := /Users/david/Development/rust
RUSTC_TARGET := x86_64-unknown-blueprint.json

LD := tools/bin/x86_64-linux-gnu-ld

# This creates, partitions and formats a 50 MB hard drive with one FAT32
# partition. I arrived at the arguments to the second call to mpartition by
# some amount of black magic: I want to fill the entire HD with one partition.
# Mpartition complains if you don't have your partition aligned correctly, but
# doesn't tell you what "alligned correctly" means. I came up with this number
# by using fdisk to create a partition, and then using mpartition -p to get the
# proper flags to create the partition. This yielded a partition of a different
# size than what fdisk created, but it's close enough and mpartition doesn't
# error out when using these flags.
#
# In mformat, I have to specify a cluster size of 1 sector or it will complain
# that there aren't enough clusters for FAT32.
hd.img: boot1.bin stage2.bin mtoolsrc hello.txt
	dd bs=512 count=102400 if=/dev/zero of=hd.img
	MTOOLSRC=./mtoolsrc mpartition -I -B boot1.bin c:
	MTOOLSRC=./mtoolsrc mpartition -c -t 6 -h 255 -s 63 -b 63 c:
	MTOOLSRC=./mtoolsrc mformat -F -c 1 c:
	dd bs=512 seek=1 if=stage2.bin of=hd.img conv=notrunc
	MTOOLSRC=./mtoolsrc mcopy hello.txt c:/hello.txt

mtoolsrc:
	echo 'drive c: file="./hd.img" partition=1' > mtoolsrc

hello.txt:
	echo 'Hello, world!' > hello.txt

boot1.bin: boot1.s stage2size.inc
	nasm -f bin -o boot1.bin boot1.s

stage2size.inc: stage2.bin
	echo "%define stage2size $(shell echo $(shell wc -c stage2.bin | sed 's/^ *//' | cut -f 1 -d ' ') / 512 | bc)" > stage2size.inc

stage2.bin: boot2.o main.o linker.ld $(LD)
	$(LD) -T linker.ld -o stage2.bin boot2.o main.o
	@echo
	@echo "STAGE2 Size: " `stat -f%z stage2.bin`
	@echo

boot2.o: boot2.s
	nasm -f elf64 boot2.s

main.o: main.rs util.rs vga.rs fat.rs ata.rs io.rs libcore.rlib
	rustc main.rs --emit obj -O --extern core=libcore.rlib --target=${RUSTC_TARGET} -C lto

libcore.rlib:
	rustc ${RUST_SRC}/src/libcore/lib.rs --target=${RUSTC_TARGET}

# Custom binutils
tools/bin/x86_64-linux-gnu-ld:
	sh scripts/fetch_binutils.sh

.PHONY: run
run: hd.img
	qemu-system-x86_64 -monitor stdio -cpu SandyBridge hd.img

.PHONY: clean

clean:
	rm -f *.o *.bin *.rlib mtoolsrc hd.img hello.txt
