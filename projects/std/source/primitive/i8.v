namespace std.primitive;

⍝ 有符号 8 位整数。
⍝ 适合紧凑存储和字节级算术。
[primitive("std::primitive::i8")]
structure i8 { }

imply i8 {
    # `i8` 与无符号窄整数同族：后端只承认 Integer32/Integer64/Character 载体，
    # 不提供 Integer8。算术与比较一律在 i32 载体上计算，结果窄化回 i8；
    # `as i32` 是符号扩展，`as i8` 是按位截断，两者合起来即模 256 的环运算，
    # 有符号比较因符号扩展而精确。
    infix `+`(self, rhs: Self): Self {
        return ((self as i32) + (rhs as i32)) as i8
    }

    infix `-`(self, rhs: Self): Self {
        return ((self as i32) - (rhs as i32)) as i8
    }

    infix `*`(self, rhs: Self): Self {
        return ((self as i32) * (rhs as i32)) as i8
    }

    infix `/`(self, rhs: Self): Self {
        return ((self as i32) / (rhs as i32)) as i8
    }

    infix `%`(self, rhs: Self): Self {
        return ((self as i32) % (rhs as i32)) as i8
    }

    infix `<`(self, rhs: Self): bool {
        return (self as i32) < (rhs as i32)
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
        return ((0 as i32) - (self as i32)) as i8
    }

    bit_and(self, rhs: Self): Self {
        return ((self as i32) & (rhs as i32)) as i8
    }

    bit_or(self, rhs: Self): Self {
        return ((self as i32) | (rhs as i32)) as i8
    }

    bit_xor(self, rhs: Self): Self {
        return ((self as i32) ^ (rhs as i32)) as i8
    }

    bit_shift_left(self, rhs: Self): Self {
        # 窄语义：移位量达到位宽（8）后全部位已移出，结果为 0。
        if rhs >= 8 as i8 {
            return 0 as i8
        }
        return ((self as i32) << (rhs as i32)) as i8
    }

    bit_shift_right(self, rhs: Self): Self {
        # 算术右移：达到位宽后由符号位填满（非负为 0，负数为 -1）。
        if rhs >= 8 as i8 {
            return ((self as i32) >> 31) as i8
        }
        return ((self as i32) >> (rhs as i32)) as i8
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
        self.bit_xor(-1 as i8)
    }

    # 位元查询按位模式解释 `i8`：负数的高位为 1，结果与无符号同宽位模式一致。
    # 只用 `&` / `-` / `<<` 与比较，不依赖右移，也不做符号特判。
    micro count_ones(self): u32 {
        let mut value: i8 = self
        let mut total: u32 = 0
        while value != 0 as i8 {
            value = value & (value - (1 as i8))
            total = total + 1
        }
        return total
    }

    micro leading_zeros(self): u32 {
        if self == 0 as i8 {
            return 8
        }

        let mut value: i8 = self
        let mut count: u32 = 0
        while (value & ((1 as i8) << (7 as i8))) == 0 as i8 {
            value = value << (1 as i8)
            count = count + 1
        }
        return count
    }

    micro trailing_zeros(self): u32 {
        if self == 0 as i8 {
            return 8
        }

        let mut mask: i8 = 1 as i8
        let mut count: u32 = 0
        while (self & mask) == 0 as i8 {
            mask = mask << (1 as i8)
            count = count + 1
        }
        return count
    }
}

# 移位守卫与其余算术均在 std 层合成，本文件已无宿主合同。

imply i8: Equal {
    # i8 经 `as i32` 符号扩展后比较，值域完整落在 i32 内，语义精确。
    infix `==`(self, rhs: Self): bool {
        return (self as i32) == (rhs as i32)
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply i8: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `=!=`(self, rhs: Self): bool {
        return self != rhs
    }
}
