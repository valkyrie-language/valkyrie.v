namespace core::primitive;

⍝ 无符号 8 位整数。
⍝ 适合原始字节和小范围无符号算术。
[primitive("core::primitive::u8")]
structure u8 { }

imply u8 {
    infix `+`(self, rhs: Self): Self {
        __u8_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __u8_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __u8_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __u8_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __u8_rem(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __u8_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __u8_lt(self, rhs)
    }

    infix `<=`(self, rhs: Self): bool {
        !(rhs < self)
    }

    infix `>`(self, rhs: Self): bool {
        rhs < self
    }

    infix `>=`(self, rhs: Self): bool {
        !(self < rhs)
    }

    bit_and(self, rhs: Self): Self {
        __u8_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __u8_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __u8_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __u8_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __u8_shr(self, rhs)
    }
}

# region u8 内部指令映射
[intrinsic("u8.add")]
private micro __u8_add(lhs: u8, rhs: u8): u8 { }

[intrinsic("u8.sub")]
private micro __u8_sub(lhs: u8, rhs: u8): u8 { }

[intrinsic("u8.mul")]
private micro __u8_mul(lhs: u8, rhs: u8): u8 { }

[intrinsic("u8.div")]
private micro __u8_div(lhs: u8, rhs: u8): u8 { }

[intrinsic("u8.rem")]
private micro __u8_rem(lhs: u8, rhs: u8): u8 { }

[intrinsic("u8.eq")]
private micro __u8_eq(lhs: u8, rhs: u8): bool { }

[intrinsic("u8.lt")]
private micro __u8_lt(lhs: u8, rhs: u8): bool { }

[intrinsic("u8.and")]
private micro __u8_and(lhs: u8, rhs: u8): u8 { }

[intrinsic("u8.or")]
private micro __u8_or(lhs: u8, rhs: u8): u8 { }

[intrinsic("u8.xor")]
private micro __u8_xor(lhs: u8, rhs: u8): u8 { }

[intrinsic("u8.shl")]
private micro __u8_shl(lhs: u8, rhs: u8): u8 { }

[intrinsic("u8.shr")]
private micro __u8_shr(lhs: u8, rhs: u8): u8 { }
# end region
