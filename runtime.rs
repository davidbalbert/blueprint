pub mod kinds {
    #[lang="sized"]
    pub trait Sized for Sized? {
    }

    #[lang="copy"]
    pub trait Copy for Sized? {
    }
}


pub mod option {
    pub enum Option<T> {
        Some(T),
        None,
    }
}

pub mod iter {
    use runtime::option::Option;
    use runtime::option::Option::{Some, None};

    #[lang="iterator"]
    pub trait Iterator<A> {
        fn next(&mut self) -> Option<A>;
    }

    struct IntRange {
        current: int,
        end: int,
        step: int
    }

    impl Iterator<int> for IntRange {
        fn next(&mut self) -> Option<int> {
            if self.current < self.end {
                let res = self.current;
                self.current += self.step;
                Some(res)
            } else {
                None
            }
        }
    }

    pub fn range(start: int, end: int) -> IntRange {
        IntRange { current: start, end: end, step: 1 }
    }

    pub fn range_step(start: int, end: int, step: int) -> IntRange {
        IntRange { current: start, end: end, step: step }
    }
}

pub mod ptr {
    extern "rust-intrinsic" {
        fn uninit<T>() -> T;
        fn copy_nonoverlapping_memory<T>(dst: *mut T, src: *const T, count: uint);
    }

    pub unsafe fn read<T>(src: *const T) -> T {
        let mut tmp: T = uninit();
        copy_nonoverlapping_memory(&mut tmp, src, 1);
        tmp
    }
}

pub mod mem {
    use runtime::ptr;

    extern "rust-intrinsic" {
        pub fn transmute<T, U>(e: T) -> U;
        pub fn size_of<T>() -> uint;
    }

    pub unsafe fn transmute_copy<T, U>(src: &T) -> U {
        ptr::read(src as *const T as *const U)
    }
}

pub mod raw {
    use runtime::kinds::{Sized, Copy};
    use runtime::mem;

    #[repr(C)]
    pub struct Slice<T> {
        pub data: *const T,
        pub len: uint,
    }

    impl<T> Copy for Slice<T> {}

    pub trait Repr<T> for Sized? {
        fn repr(&self) -> T { unsafe { mem::transmute_copy(&self) } }
    }

    impl Repr<Slice<u8>> for str {}
    impl<T> Repr<Slice<T>> for [T] {}
}

pub mod intrinsics {
    extern "rust-intrinsic" {
        pub fn offset<T>(dst: *const T, offset: int) -> *const T;
    }
}

pub mod ops {
    use runtime::mem;
    use runtime::intrinsics;
    use runtime::slice::SliceExt;
    use runtime::raw::Repr;
    use runtime::kinds::Sized;

    use util;

    #[lang="index"]
    pub trait Index<Sized? Index, Sized? Result> for Sized? {
        fn index<'a>(&'a self, index: &Index) -> &'a Result;
    }

    impl<T> Index<uint, T> for [T] {
        fn index(&self, &index: &uint) -> &T {
            if index >= self.len() {
                util::die("Index out of bounds!");
            }

            unsafe {
                mem::transmute(intrinsics::offset(self.repr().data, index as int))
            }
        }
    }

}

pub mod str {
    use runtime::kinds::Sized;
    use runtime::raw::Repr;
    use runtime::mem;

    pub trait StrExt for Sized? {
        fn len(&self) -> uint;
        fn as_bytes(&self) -> &[u8];
    }

    impl StrExt for str {
        fn len(&self) -> uint {
            self.repr().len
        }

        fn as_bytes(&self) -> &[u8] {
            unsafe { mem::transmute(self) }
        }
    }
}

pub mod slice {
    use runtime::iter;
    use runtime::raw;
    use runtime::intrinsics;
    use runtime::mem;
    use runtime::option::Option;
    use runtime::option::Option::{Some, None};
    use runtime::kinds::Sized;
    use runtime::raw::Repr;

    struct Iter<T> {
        ptr: *const T,
        end: *const T,
    }

    // Doesn't handle zero sized T.
    impl<T> iter::Iterator<T> for Iter<T> {
        fn next(&mut self) -> Option<T> {
            if self.ptr == self.end {
                None
            } else {
                unsafe {
                    let res = self.ptr;
                    self.ptr = intrinsics::offset(self.ptr, 1);
                    Some(*res)
                }
            }
        }
    }

    pub trait SliceExt<T> for Sized? {
        fn len(&self) -> uint;
        fn as_ptr(&self) -> *const T;
        fn iter(&self) -> Iter<T>;
    }

    impl<T> SliceExt<T> for [T] {
        fn len(&self) -> uint {
            self.repr().len
        }

        fn as_ptr(&self) -> *const T {
            self.repr().data
        }

        fn iter(&self) -> Iter<T> {
            unsafe {
                Iter { ptr: self.as_ptr(), end: intrinsics::offset(self.as_ptr(), self.len() as int) }
            }
        }
    }
}

pub mod prelude {
    pub use runtime::kinds::{Sized, Copy};
    pub use runtime::iter::range;
    pub use runtime::option::Option;
    pub use runtime::option::Option::{Some, None};
    pub use runtime::slice::SliceExt;
    pub use runtime::str::StrExt;
}


#[lang = "stack_exhausted"] extern fn stack_exhausted() {}
#[lang = "eh_personality"] extern fn eh_personality() {}
#[lang = "panic_fmt"] fn panic_fmt() -> ! { loop {} }
