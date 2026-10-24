namespace core::primitive;

⍝ 无符号 32 位整数。
⍝ 适合通用无符号算术、长度与位模式表示。
[primitive("core::primitive::u32")]
structure u32 { }

imply u32 {
    infix `+`(self, rhs: Self): Self {
        __u32_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __u32_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __u32_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __u32_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __u32_rem(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __u32_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __u32_lt(self, rhs)
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
        __u32_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __u32_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __u32_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __u32_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __u32_shr(self, rhs)
    }
}

[host_contract]
private micro __u32_add(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_sub(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_mul(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_div(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_rem(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_eq(lhs: u32, rhs: u32): bool

[host_contract]
private micro __u32_lt(lhs: u32, rhs: u32): bool

[host_contract]
private micro __u32_and(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_or(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_xor(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_shl(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_shr(lhs: u32, rhs: u32): u32
