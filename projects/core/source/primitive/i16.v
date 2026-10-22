namespace core::primitive;

⍝ 有符号 16 位整数。
⍝ 适合中小范围的整数运算。
[primitive("core::primitive::i16")]
structure i16 { }

imply i16 {
    infix `+`(self, rhs: Self): Self {
        __i16_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __i16_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __i16_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __i16_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __i16_rem(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __i16_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __i16_lt(self, rhs)
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

    prefix `-`(self): Self {
        __i16_neg(self)
    }

    bit_and(self, rhs: Self): Self {
        __i16_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __i16_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __i16_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __i16_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __i16_shr(self, rhs)
    }
}

# region i16 内部指令映射
[intrinsic("i16.add")]
private micro __i16_add(lhs: i16, rhs: i16): i16 { }

[intrinsic("i16.sub")]
private micro __i16_sub(lhs: i16, rhs: i16): i16 { }

[intrinsic("i16.neg")]
private micro __i16_neg(self: i16): i16 { }

[intrinsic("i16.mul")]
private micro __i16_mul(lhs: i16, rhs: i16): i16 { }

[intrinsic("i16.div")]
private micro __i16_div(lhs: i16, rhs: i16): i16 { }

[intrinsic("i16.rem")]
private micro __i16_rem(lhs: i16, rhs: i16): i16 { }

[intrinsic("i16.eq")]
private micro __i16_eq(lhs: i16, rhs: i16): bool { }

[intrinsic("i16.lt")]
private micro __i16_lt(lhs: i16, rhs: i16): bool { }

[intrinsic("i16.and")]
private micro __i16_and(lhs: i16, rhs: i16): i16 { }

[intrinsic("i16.or")]
private micro __i16_or(lhs: i16, rhs: i16): i16 { }

[intrinsic("i16.xor")]
private micro __i16_xor(lhs: i16, rhs: i16): i16 { }

[intrinsic("i16.shl")]
private micro __i16_shl(lhs: i16, rhs: i16): i16 { }

[intrinsic("i16.shr")]
private micro __i16_shr(lhs: i16, rhs: i16): i16 { }
# end region
