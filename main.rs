#![crate_type="lib"]
#![no_std]
#![feature(lang_items)]
#![feature(globs)]

extern crate core;

use core::prelude::*;

const VIDEO_MEMORY: int = 0xB8000;

fn clear_screen() {
    for x in range(0i, 80 * 25) {
        unsafe {
            *((VIDEO_MEMORY + x * 2) as *mut u16) = 0x1F20;
        }
    }
}

fn print(message: &str) {
    let mut i = 0i;

    for x in message.chars() {
        unsafe {
            *((VIDEO_MEMORY + i) as *mut u8) = x as u8;
        }
        i += 2;
    }
}

#[no_mangle]
pub fn kernel_main() {
    clear_screen();
    print("Hello, Blueprint!");

    loop {}
}


// These functions and traits are used by the compiler, but not
// for a bare-bones hello world. These are normally
// provided by libstd.
#[lang = "stack_exhausted"] extern fn stack_exhausted() {}
#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] fn panic_fmt() -> ! { loop {} }
