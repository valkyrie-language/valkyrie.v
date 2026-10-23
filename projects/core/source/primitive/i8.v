namespace core::primitive;

⍝ 有符号 8 位整数。
⍝ 适合紧凑存储和字节级算术。
[primitive("core::primitive::i8")]
structure i8 { }

imply i8 {
    infix `+`(self, rhs: Self): Self {
        __i8_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __i8_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __i8_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __i8_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __i8_rem(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __i8_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __i8_lt(self, rhs)
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
        __i8_neg(self)
    }

    bit_and(self, rhs: Self): Self {
        __i8_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __i8_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __i8_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __i8_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __i8_shr(self, rhs)
    }
}

# region i8 内部指令映射
[host_contract]
private micro __i8_add(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_sub(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_neg(self: i8): i8

[host_contract]
private micro __i8_mul(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_div(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_rem(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_eq(lhs: i8, rhs: i8): bool

[host_contract]
private micro __i8_lt(lhs: i8, rhs: i8): bool

[host_contract]
private micro __i8_and(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_or(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_xor(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_shl(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_shr(lhs: i8, rhs: i8): i8
# end region
