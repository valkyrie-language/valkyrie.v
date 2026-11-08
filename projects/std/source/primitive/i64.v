namespace std.primitive;

⍝ 有符号 64 位整数
⍝ 适合通用大范围整数运算
[primitive("std::primitive::i64")]
structure i64 { }

imply i64 {
    infix `+`(self, rhs: Self): Self {
        __i64_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __i64_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __i64_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __i64_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __i64_rem(self, rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __i64_lt(self, rhs)
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

    # 半开区间 `[start, end)`；64 位目标 `isize = i64`，本 impl 同时服务 `isize`。
    infix `..`(self, rhs: Self): std::types::I64Range {
        return std::types::i64_range(self, rhs)
    }

    # 闭区间 `[start, end]`；声明侧就位，表达式形态待 `..=` token 落地。
    infix `..=`(self, rhs: Self): std::types::I64InclusiveRange {
        return std::types::i64_inclusive_range(self, rhs)
    }

    prefix `-`(self): Self {
        __i64_neg(self)
    }

    bit_and(self, rhs: Self): Self {
        __i64_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __i64_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __i64_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __i64_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __i64_shr(self, rhs)
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

    # 位元查询按位模式解释 `i64`：负数的最高位为 1，前导零为 0。
    # 只用 `&` / `-` / `<<` 与比较，不依赖右移。
    micro count_ones(self): u32 {
        let mut value: i64 = self
        let mut total: u32 = 0
        while value != 0 as i64 {
            value = value & (value - (1 as i64))
            total = total + 1
        }
        return total
    }

    micro leading_zeros(self): u32 {
        if self == 0 as i64 {
            return 64
        }

        let mut value: i64 = self
        let mut count: u32 = 0
        while (value & ((1 as i64) << (63 as i64))) == 0 as i64 {
            value = value << (1 as i64)
            count = count + 1
        }
        return count
    }

    micro trailing_zeros(self): u32 {
        if self == 0 as i64 {
            return 64
        }

        let mut mask: i64 = 1 as i64
        let mut count: u32 = 0
        while (self & mask) == 0 as i64 {
            mask = mask << (1 as i64)
            count = count + 1
        }
        return count
    }

    # 位序反转：按 64 位位模式解释，最低位成为最高位。负数不做符号特判，
    # 只用 `&` / `<<` / `|` 逐位搬移，不依赖右移。
    micro reverse_bits(self): Self {
        let mut result: i64 = 0 as i64
        let mut source_mask: i64 = 1 as i64
        let mut index: u32 = 0
        while index < 64 {
            result = result << (1 as i64)
            if (self & source_mask) != 0 as i64 {
                result = result | (1 as i64)
            }
            source_mask = source_mask << (1 as i64)
            index = index + 1
        }
        return result
    }
}

imply i64: Equal {
    infix `==`(self, rhs: Self): bool {
        return __i64_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

[host_contract]
private micro __i64_add(lhs: i64, rhs: i64): i64

[host_contract]
private micro __i64_sub(lhs: i64, rhs: i64): i64

[host_contract]
private micro __i64_neg(self: i64): i64

[host_contract]
private micro __i64_mul(lhs: i64, rhs: i64): i64

[host_contract]
private micro __i64_div(lhs: i64, rhs: i64): i64

[host_contract]
private micro __i64_rem(lhs: i64, rhs: i64): i64

[host_contract]
private micro __i64_eq(lhs: i64, rhs: i64): bool

[host_contract]
private micro __i64_lt(lhs: i64, rhs: i64): bool

[host_contract]
private micro __i64_and(lhs: i64, rhs: i64): i64

[host_contract]
private micro __i64_or(lhs: i64, rhs: i64): i64

[host_contract]
private micro __i64_xor(lhs: i64, rhs: i64): i64

[host_contract]
private micro __i64_shl(lhs: i64, rhs: i64): i64

[host_contract]
private micro __i64_shr(lhs: i64, rhs: i64): i64


imply i64: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `=!=`(self, rhs: Self): bool {
        return self != rhs
    }
}
