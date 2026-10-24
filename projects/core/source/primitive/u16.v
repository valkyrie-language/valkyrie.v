namespace core::primitive;

⍝ 无符号 16 位整数。
⍝ 适合中小范围无符号计数与索引。
[primitive("core::primitive::u16")]
structure u16 { }

imply u16 {
    infix `+`(self, rhs: Self): Self {
        __u16_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __u16_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __u16_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __u16_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __u16_rem(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __u16_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __u16_lt(self, rhs)
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
        __u16_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __u16_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __u16_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __u16_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __u16_shr(self, rhs)
    }
}

# region u16 内部指令映射
[host_contract]
private micro __u16_add(lhs: u16, rhs: u16): u16

[host_contract]
private micro __u16_sub(lhs: u16, rhs: u16): u16

[host_contract]
private micro __u16_mul(lhs: u16, rhs: u16): u16

[host_contract]
private micro __u16_div(lhs: u16, rhs: u16): u16

[host_contract]
private micro __u16_rem(lhs: u16, rhs: u16): u16

[host_contract]
private micro __u16_eq(lhs: u16, rhs: u16): bool

[host_contract]
private micro __u16_lt(lhs: u16, rhs: u16): bool

[host_contract]
private micro __u16_and(lhs: u16, rhs: u16): u16

[host_contract]
private micro __u16_or(lhs: u16, rhs: u16): u16

[host_contract]
private micro __u16_xor(lhs: u16, rhs: u16): u16

[host_contract]
private micro __u16_shl(lhs: u16, rhs: u16): u16

[host_contract]
private micro __u16_shr(lhs: u16, rhs: u16): u16
# end region
