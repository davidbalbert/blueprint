#![crate_type="staticlib"]
#![no_std]
#![feature(lang_items)]
#![feature(globs)]
#![feature(asm)]
#![feature(intrinsics)]

extern crate core;

mod util;
mod io;
mod ata;
mod fat;
mod vga;

#[no_mangle]
pub fn stage2_main() {
    vga::clear_screen();
    vga::print("Hello, Blueprint!");

    let size = fat::file_size("/hello.txt");
    fat::read_file("/hello.txt", 0x10000);

    //vga::print_memory(0x10000, size);

    util::halt();
}

#[lang = "stack_exhausted"] extern fn stack_exhausted() {}
#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] fn panic_fmt() -> ! { loop {} }
