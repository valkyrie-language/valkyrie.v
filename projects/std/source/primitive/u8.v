namespace std.primitive;

⍝ 无符号 8 位整数。
⍝ 适合原始字节和小范围无符号算术。
[primitive("std::primitive::u8")]
structure u8 { }

imply u8 {
    # `u8` 在 lane 侧的物理载体是 i32：后端只承认 Integer32/Integer64/Character，
    # 不提供 Integer8。加宽到 u32 再窄化回 u8；窄化按位截断（实测
    # `256 as u8 == 0`、`65535 as u8 == 255`），等价于模 256 的环加，语义精确。
    infix `+`(self, rhs: Self): Self {
        return ((self as u32) + (rhs as u32)) as u8
    }

    infix `-`(self, rhs: Self): Self {
        return ((self as u32) - (rhs as u32)) as u8
    }

    infix `*`(self, rhs: Self): Self {
        return ((self as u32) * (rhs as u32)) as u8
    }

    infix `/`(self, rhs: Self): Self {
        return ((self as u32) / (rhs as u32)) as u8
    }

    infix `%`(self, rhs: Self): Self {
        return ((self as u32) % (rhs as u32)) as u8
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
        return ((self as u32) & (rhs as u32)) as u8
    }

    bit_or(self, rhs: Self): Self {
        return ((self as u32) | (rhs as u32)) as u8
    }

    bit_xor(self, rhs: Self): Self {
        return ((self as u32) ^ (rhs as u32)) as u8
    }

    bit_shift_left(self, rhs: Self): Self {
        # 窄语义：移位量达到位宽（8）后全部位已移出，结果为 0。
        # 直接拓宽成 u32 再移会保留高位（`0xFF << 8` 在 u32 上是 `0xFF00`），
        # 因此必须显式守卫，不能只靠截断。
        if rhs >= 8 as u8 {
            return 0 as u8
        }
        return ((self as u32) << (rhs as u32)) as u8
    }

    bit_shift_right(self, rhs: Self): Self {
        if rhs >= 8 as u8 {
            return 0 as u8
        }
        # u32 载体的 `>>` 在 wasm 上仍被 lower 成左旋（见 06 卡点），
        # 因此逻辑右移改写成除以 2^n；在 u32 上与逻辑右移等价，两个 lane 都精确。
        return ((self as u32) / ((1 as u32) << (rhs as u32))) as u8
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

    # 位元查询：位宽由 `u8` 的 8 位定义，全 0 的前导/尾随零均为 8。
    # 只用 `&` / `-` / `<<` 与比较：`>>` 在 wasm 上仍被 lower 成左旋，
    # 因此计位与扫描都写成不依赖右移的形式。
    micro count_ones(self): u32 {
        let mut value: u8 = self
        let mut total: u32 = 0
        while value != 0 as u8 {
            value = value & (value - (1 as u8))
            total = total + 1
        }
        return total
    }

    micro leading_zeros(self): u32 {
        if self == 0 as u8 {
            return 8
        }

        let mut value: u8 = self
        let mut count: u32 = 0
        while (value & (0x80 as u8)) == 0 as u8 {
            value = value << (1 as u8)
            count = count + 1
        }
        return count
    }

    micro trailing_zeros(self): u32 {
        if self == 0 as u8 {
            return 8
        }

        let mut mask: u8 = 1 as u8
        let mut count: u32 = 0
        while (self & mask) == 0 as u8 {
            mask = mask << (1 as u8)
            count = count + 1
        }
        return count
    }

    # 位序反转：8 位宽内最低位成为最高位。只用 `&` / `<<` / `|` 逐位搬移，
    # 不依赖右移（wasm 上 `>>` 仍被 lower 成左旋）。
    micro reverse_bits(self): Self {
        let mut result: u8 = 0 as u8
        let mut source_mask: u8 = 1 as u8
        let mut index: u32 = 0
        while index < 8 {
            result = result << (1 as u8)
            if (self & source_mask) != 0 as u8 {
                result = result | (1 as u8)
            }
            source_mask = source_mask << (1 as u8)
            index = index + 1
        }
        return result
    }
}

# 移位守卫与其余算术均在 std 层合成，本文件已无宿主合同。
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

