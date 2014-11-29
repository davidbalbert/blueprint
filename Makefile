hd.img: boot1.bin boot2.bin
	cat boot1.bin boot2.bin > hd.img

boot1.bin: boot1.s
	nasm -f bin -o boot1.bin boot1.s

boot2.bin: boot2.s
	nasm -f bin -o boot2.bin boot2.s

.PHONY: run
run: hd.img
	qemu-system-x86_64 -monitor stdio -cpu SandyBridge hd.img

.PHONY: clean

clean:
	rm -f *.bin hd.img
