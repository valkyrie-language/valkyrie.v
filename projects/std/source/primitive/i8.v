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
        __i8_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __i8_shr(self, rhs)
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
}

# region i8 内部指令映射
# 除移位守卫外，i8 的算术、比较与位运算全部在 i32 载体上计算后按位截断，
# 不经宿主合同；`as i32` 符号扩展、`as i8` 按位截断，语义精确。
[host_contract]
private micro __i8_shl(lhs: i8, rhs: i8): i8

[host_contract]
private micro __i8_shr(lhs: i8, rhs: i8): i8
# end region

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
