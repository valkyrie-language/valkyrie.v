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
        # 窄语义：移位量达到位宽（16）后全部位已移出，结果为 0。
        # 拓宽到 u32 再移会保留高位，因此必须显式守卫。
        if rhs >= 16 as u16 {
            return 0 as u16
        }
        return ((self as u32) << (rhs as u32)) as u16
    }

    bit_shift_right(self, rhs: Self): Self {
        if rhs >= 16 as u16 {
            return 0 as u16
        }
        # u32 载体的 `>>` 在 wasm 上仍被 lower 成左旋（见 06 卡点），
        # 逻辑右移改写成除以 2^n，两个 lane 都精确。
        return ((self as u32) / ((1 as u32) << (rhs as u32))) as u16
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

# 移位守卫与其余算术均在 std 层合成，本文件已无宿主合同。
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

