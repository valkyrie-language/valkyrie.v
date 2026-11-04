namespace std.primitive;

⍝ 无符号 8 位整数。
⍝ 适合原始字节和小范围无符号算术。
[primitive("std::primitive::u8")]
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
        self.bit_xor(0xFF as u8)
    }
}

# region u8 内部指令映射
[host_contract]
private micro __u8_add(lhs: u8, rhs: u8): u8

[host_contract]
private micro __u8_sub(lhs: u8, rhs: u8): u8

[host_contract]
private micro __u8_mul(lhs: u8, rhs: u8): u8

[host_contract]
private micro __u8_div(lhs: u8, rhs: u8): u8

[host_contract]
private micro __u8_rem(lhs: u8, rhs: u8): u8

[host_contract]
private micro __u8_lt(lhs: u8, rhs: u8): bool

[host_contract]
private micro __u8_and(lhs: u8, rhs: u8): u8

[host_contract]
private micro __u8_or(lhs: u8, rhs: u8): u8

[host_contract]
private micro __u8_xor(lhs: u8, rhs: u8): u8

[host_contract]
private micro __u8_shl(lhs: u8, rhs: u8): u8

[host_contract]
private micro __u8_shr(lhs: u8, rhs: u8): u8
# end region
imply u8: Equal {
    # u8 在各 lane 的物理载体是 i32（`[primitive]` 声明只冻结 u8 身份，
    # 后端不为其单独提供 Integer8 载体）。等值比较拓宽到 u32 后按位判定：
    # u8 值域 0..=255 落在 i32 低位，拓宽不改变任何位的取值，语义精确。
    infix `==`(self, rhs: Self): bool {
        return (self as u32) == (rhs as u32)
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply u8: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `=!=`(self, rhs: Self): bool {
        return self != rhs
    }
}

