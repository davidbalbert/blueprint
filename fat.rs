// Functions for reading data off a FAT32 formatted active primary partition.

use core::prelude::*;

use util;
use ata;

#[repr(C, packed)]
struct BootRecord {
    bpb: BiosParameterBlock,
    ebr: ExtendedBootRecord,
}

#[repr(C, packed)]
struct BiosParameterBlock {
    jump: [u8, ..3],            // Machine code for jumping over the following data
    oem_id: [u8, ..8],
    bytes_per_sector: u16,
    sectors_per_cluster: u8,
    reserved_sectors: u16,
    fats: u8,
    dir_entries: u16,
    sectors: u16,
    media_descriptor_type: u8,
    fat16_sectors_per_fat: u16,
    sectors_per_track: u16,
    heads: u16,
    lba_start: u32,
    large_sectors: u32,
}

#[repr(C, packed)]
struct ExtendedBootRecord {
    sectors_per_fat: u32,
    flags: u16,
    version_major: u8,
    version_minor: u8,
    root_cluster: u32,
    fsinfo_sector: u16,
    backup_boot_sector: u16,
    reserved: [u8, ..12],
    drive_number: u8,
    winnt_flags: u8,
    signature: u8,
    serial_number: u32,
    label: [u8, ..11],
    system_id: [u8, ..8],
    boot_code: [u8, ..420],
    boot_signature: u16,
}

#[repr(C, packed)]
struct FileAllocationTable {
}

#[repr(C)]
struct Partition {
    active: u8,
    start_head: u8,
    start_sector_and_cylinder: u16,
    system_id: u8,
    end_head: u8,
    end_sector_and_cylinder: u16,
    lba_start: u32,
    lba_size: u32,
}

impl Partition {
    fn is_unused(&self) -> bool {
        self.system_id == 0
    }

    fn is_active(&self) -> bool {
        self.active == 0x80
    }

    fn read_file(&self, path: &str, destination: uint) {
        let mut fat = FileAllocationTable {};


    }
}

fn get_partition_table() -> &'static [Partition, ..4] {
    unsafe {
        &*((0x7c00i + 0x1be) as *const [Partition, ..4])
    }
}

fn active_partition(table: &[Partition, ..4]) -> &Partition {
    for p in table.iter() {
        if !p.is_unused() && p.is_active() {
            return p;
        }
    }

    util::die("No active partition");
}

pub fn file_size(path: &str) -> uint {
    0
}

pub fn read_file(path: &str, destination: uint) {
    let partition_table = get_partition_table();

    let active_partition = active_partition(partition_table);

    active_partition.read_file(path, destination);
}
