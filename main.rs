#![crate_type="lib"]
#![no_std]
#![feature(lang_items)]
#![feature(globs)]
#![feature(asm)]
#![feature(intrinsics)]

/* libcore is way too big for a bootloader. We'll have to write our own. */
mod runtime;

mod util;
mod io;
mod ata;
mod fat;
mod vga;

#[no_mangle]
pub fn stage2_main() {
    vga::clear_screen();
    vga::print("Hello, Blueprint!");

    ata::read(0, 2, 0x10000);

    //let size = fat::file_size("/hello.txt");
    fat::read_file("/hello.txt", 0x10000);

    //vga::print_memory(0x10000, size);

    util::halt();
}
