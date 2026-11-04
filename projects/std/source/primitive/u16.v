namespace std.primitive;

⍝ 无符号 16 位整数。
⍝ 适合中小范围无符号计数与索引。
[primitive("std::primitive::u16")]
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

    infix `&`(self, rhs: Self): Self {
        self.bit_and(rhs)
    }

    infix `|`(self, rhs: Self): Self {
        self.bit_or(rhs)
    }

    infix `^`(self, rhs: Self): Self {
        self.bit_xor(rhs)
    }

    infix `<<`(self, rhs: Self): Self {
        self.bit_shift_left(rhs)
    }

    infix `>>`(self, rhs: Self): Self {
        self.bit_shift_right(rhs)
    }

    bit_not(self): Self {
        self.bit_xor(0xFFFF as u16)
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
imply u16: Equal {
    # u16 值域 0..=65535 完整落在 u32 位宽内，拓宽后按位判定即精确等值。
    infix `==`(self, rhs: Self): bool {
        return (self as u32) == (rhs as u32)
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply u16: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `=!=`(self, rhs: Self): bool {
        return self != rhs
    }
}

