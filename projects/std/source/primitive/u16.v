namespace std.primitive;

⍝ 无符号 16 位整数。
⍝ 适合中小范围无符号计数与索引。
[primitive("std::primitive::u16")]
structure u16 { }

imply u16 {
    # `u16` 与 `u8` 同族：后端只承认 Integer32/Integer64/Character 载体，
    # 不提供 Integer16。算术与比较一律在 u32 载体上计算，结果窄化回 u16；
    # 窄化按位截断（实测 `65536 as u16 == 0`），等价于模 65536 的环运算，
    # 语义由「值域完整落在 u32 低 16 位」保证。
    infix `+`(self, rhs: Self): Self {
        return ((self as u32) + (rhs as u32)) as u16
    }

    infix `-`(self, rhs: Self): Self {
        return ((self as u32) - (rhs as u32)) as u16
    }

    infix `*`(self, rhs: Self): Self {
        return ((self as u32) * (rhs as u32)) as u16
    }

    infix `/`(self, rhs: Self): Self {
        return ((self as u32) / (rhs as u32)) as u16
    }

    infix `%`(self, rhs: Self): Self {
        return ((self as u32) % (rhs as u32)) as u16
    }

    infix `<`(self, rhs: Self): bool {
        return (self as u32) < (rhs as u32)
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
        return ((self as u32) & (rhs as u32)) as u16
    }

    bit_or(self, rhs: Self): Self {
        return ((self as u32) | (rhs as u32)) as u16
    }

    bit_xor(self, rhs: Self): Self {
        return ((self as u32) ^ (rhs as u32)) as u16
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
# 除移位守卫外，u16 的算术、比较与位运算全部在 u32 载体上计算后按位截断，
# 不经宿主合同；语义由「值域完整落在 u32 低 16 位」保证。
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

