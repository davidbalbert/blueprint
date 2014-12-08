# Blueprint

A bootloader. Maybe an OS one day. We'll see.

## Requirements

- make
- nasm
- qemu
- ld that understands elf64-x86-64. If you're on OS X, `make` will download and build this in the ./tools directory.
- Rust nightly
- The Rust source (for libcore)

## Running it

First, edit the Makefile to point `RUST_SRC` at your local copy of the rust source. Ideally, you should check out the same commit as the one that your rust compiler was built from.

```
$ make run
```

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0-standalone.html) or later.
