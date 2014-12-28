use vga;

pub fn halt() -> ! {
    loop {
        unsafe {
            asm!("hlt");
        }
    }
}

pub fn die(msg: &str) -> ! {
    vga::clear_screen();
    vga::print(msg);

    halt();
}
