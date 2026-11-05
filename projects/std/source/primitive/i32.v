namespace std.primitive;

⍝ 有符号 32 位
⍝ 原始类型
[primitive("std::primitive::i32")]
structure i32 { }

imply i32 {
    infix `+`(self, rhs: Self): Self {
        __i32_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __i32_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __i32_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __i32_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __i32_rem(self, rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __i32_lt(self, rhs)
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

    # 半开区间 `[start, end)`；端点不假设顺序，`start > end` 得到零次迭代的空区间。
    infix `..`(self, rhs: Self): std::types::I32Range {
        return std::types::i32_range(self, rhs)
    }

    # 闭区间 `[start, end]`；声明侧就位，表达式形态待 `..=` token 落地。
    infix `..=`(self, rhs: Self): std::types::I32InclusiveRange {
        return std::types::i32_inclusive_range(self, rhs)
    }

    prefix `-`(self): Self {
        __i32_neg(self)
    }

    bit_and(self, rhs: Self): Self {
        __i32_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __i32_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __i32_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __i32_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __i32_shr(self, rhs)
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
        self.bit_xor(-1)
    }

    # 位元查询按位模式解释 `i32`：负数的最高位为 1，前导零为 0。
    # 只用 `&` / `-` / `<<` 与比较，不依赖右移。
    micro count_ones(self): u32 {
        let mut value: i32 = self
        let mut total: u32 = 0
        while value != 0 as i32 {
            value = value & (value - (1 as i32))
            total = total + 1
        }
        return total
    }

    micro leading_zeros(self): u32 {
        if self == 0 as i32 {
            return 32
        }

        let mut value: i32 = self
        let mut count: u32 = 0
        while (value & ((1 as i32) << (31 as i32))) == 0 as i32 {
            value = value << (1 as i32)
            count = count + 1
        }
        return count
    }

    micro trailing_zeros(self): u32 {
        if self == 0 as i32 {
            return 32
        }

        let mut mask: i32 = 1 as i32
        let mut count: u32 = 0
        while (self & mask) == 0 as i32 {
            mask = mask << (1 as i32)
            count = count + 1
        }
        return count
    }
}

# region i32 内部指令映射
[host_contract]
private micro __i32_add(lhs: i32, rhs: i32): i32

[host_contract]
private micro __i32_sub(lhs: i32, rhs: i32): i32

[host_contract]
private micro __i32_neg(self: i32): i32

[host_contract]
private micro __i32_mul(lhs: i32, rhs: i32): i32

[host_contract]
private micro __i32_div(lhs: i32, rhs: i32): i32

[host_contract]
private micro __i32_rem(lhs: i32, rhs: i32): i32

private micro __i32_pow(lhs: i32, rhs: i32): i32 {
    if rhs < 0 {
        return 0
    }

    let mut base: i32 = lhs
    let mut exp: i32 = rhs
    let mut acc: i32 = 1

    while exp > 0 {
        if exp % 2 == 1 {
            acc = acc * base
        }
        base = base * base
        exp = exp / 2
    }

    return acc
}

[host_contract]
private micro __i32_eq(lhs: i32, rhs: i32): bool

[host_contract]
private micro __i32_lt(lhs: i32, rhs: i32): bool

[host_contract]
private micro __i32_and(lhs: i32, rhs: i32): i32

[host_contract]
private micro __i32_or(lhs: i32, rhs: i32): i32

[host_contract]
private micro __i32_xor(lhs: i32, rhs: i32): i32

[host_contract]
private micro __i32_shl(lhs: i32, rhs: i32): i32

[host_contract]
private micro __i32_shr(lhs: i32, rhs: i32): i32
# end region

imply i32: Equal {
    infix `==`(self, rhs: Self): bool {
        return __i32_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply i32: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `=!=`(self, rhs: Self): bool {
        return self != rhs
    }
}

