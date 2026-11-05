namespace std.primitive;

⍝ 有符号 16 位整数。
⍝ 适合中小范围的整数运算。
[primitive("std::primitive::i16")]
structure i16 { }

imply i16 {
    # `i16` 与无符号窄整数同族：后端只承认 Integer32/Integer64/Character 载体，
    # 不提供 Integer16。算术与比较一律在 i32 载体上计算，结果窄化回 i16；
    # `as i32` 是符号扩展，`as i16` 是按位截断，两者合起来即模 65536 的环运算。
    infix `+`(self, rhs: Self): Self {
        return ((self as i32) + (rhs as i32)) as i16
    }

    infix `-`(self, rhs: Self): Self {
        return ((self as i32) - (rhs as i32)) as i16
    }

    infix `*`(self, rhs: Self): Self {
        return ((self as i32) * (rhs as i32)) as i16
    }

    infix `/`(self, rhs: Self): Self {
        return ((self as i32) / (rhs as i32)) as i16
    }

    infix `%`(self, rhs: Self): Self {
        return ((self as i32) % (rhs as i32)) as i16
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
        return ((0 as i32) - (self as i32)) as i16
    }

    bit_and(self, rhs: Self): Self {
        return ((self as i32) & (rhs as i32)) as i16
    }

    bit_or(self, rhs: Self): Self {
        return ((self as i32) | (rhs as i32)) as i16
    }

    bit_xor(self, rhs: Self): Self {
        return ((self as i32) ^ (rhs as i32)) as i16
    }

    bit_shift_left(self, rhs: Self): Self {
        # 窄语义：移位量达到位宽（16）后全部位已移出，结果为 0。
        if rhs >= 16 as i16 {
            return 0 as i16
        }
        return ((self as i32) << (rhs as i32)) as i16
    }

    bit_shift_right(self, rhs: Self): Self {
        # 算术右移：达到位宽后由符号位填满（非负为 0，负数为 -1）。
        if rhs >= 16 as i16 {
            return ((self as i32) >> 31) as i16
        }
        return ((self as i32) >> (rhs as i32)) as i16
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
        self.bit_xor(-1 as i16)
    }
}

# 移位守卫与其余算术均在 std 层合成，本文件已无宿主合同。
imply i16: Equal {
    # i16 经 `as i32` 符号扩展后比较，值域完整落在 i32 内，语义精确。
    infix `==`(self, rhs: Self): bool {
        return (self as i32) == (rhs as i32)
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply i16: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `=!=`(self, rhs: Self): bool {
        return self != rhs
    }
}

