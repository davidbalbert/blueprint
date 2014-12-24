# Blueprint

A bootloader. Maybe an OS one day. We'll see.

## Requirements

- make
- nasm
- qemu
- mtools
- ld that understands elf64-x86-64. If you're on OS X, `make` will download and build this in the ./tools directory. If you're on Linux, we assume your system ld supports elf64-x86-64.
- Rust nightly
- The Rust source (for libcore)

### OS X

First, install [Homebrew](http://brew.sh). This will automatically install the OS X Command Line Tools which includes Make.

Follow the [installiation instructions](http://doc.rust-lang.org/guide.html#installing-rust) in the Rust guide.

Clone the Rust source and check out the same revision as your nightly build. You can find the commit your Rust compiler was built from by running `rustc --version`.

```
$ git clone https://github.com/rust-lang/rust.git
$ cd rust
$ rustc --version
rustc 0.13.0-nightly (62fb41c32 2014-12-23 02:41:48 +0000)
$ git checkout 62fb41c32 
```

Then install the rest of the dependencies with Homebrew.

```
$ brew install nasm qemu mtools
```

## Running it

First, edit the Makefile to point `RUST_SRC` at your local copy of the Rust source.

```
$ make run
```

## License

[GPLv3](https://www.gnu.org/licenses/gpl-3.0-standalone.html) or later.
