#![crate_type="lib"]
#![no_std]
#![feature(lang_items)]
#![feature(globs)]
#![feature(asm)]

extern crate core;

use core::prelude::*;

mod util;
mod io;
mod ata;
mod fat;
mod vga;

const VIDEO_MEMORY: int = 0xB8000;

#[no_mangle]
pub fn stage2_main() {
    vga::clear_screen();
    vga::print("Hello, Blueprint!");

    ata::read(0, 2, 0x10000);

    let size = fat::file_size("/hello.txt");
    fat::read_file("/hello.txt", 0x10000);

    //vga::print_memory(0x10000, size);

    util::halt();
}

// These functions and traits are used by the compiler, but not
// for a bare-bones hello world. These are normally
// provided by libstd.
#[lang = "stack_exhausted"] extern fn stack_exhausted() {}
#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] fn panic_fmt() -> ! { loop {} }
