namespace std.primitive;

⍝ 无符号 64 位整数。
⍝ 适合大范围无符号计数与位级数据表示。
[primitive("std::primitive::u64")]
structure u64 { }

imply u64 {
    infix `+`(self, rhs: Self): Self {
        __u64_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __u64_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __u64_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __u64_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __u64_rem(self, rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __u64_lt(self, rhs)
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
        __u64_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __u64_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __u64_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __u64_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __u64_shr(self, rhs)
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

    # 全 1 掩码以 hi/lo 组合表达：编译器对超 i64 上限的 64 位十六进制字面量溢栈。
    bit_not(self): Self {
        self.bit_xor(((0xFFFFFFFF as u64) << 32) | (0xFFFFFFFF as u64))
    }

    # 位元查询：位宽由 `u64` 的 64 位定义，全 0 的前导/尾随零均为 64。
    # 最高位掩码同样以 hi/lo 组合表达，不写超 i64 上限的字面量。
    micro count_ones(self): u32 {
        let mut value: u64 = self
        let mut total: u32 = 0
        while value != 0 as u64 {
            value = value & (value - (1 as u64))
            total = total + 1
        }
        return total
    }

    micro leading_zeros(self): u32 {
        if self == 0 as u64 {
            return 64
        }

        let mut value: u64 = self
        let mut count: u32 = 0
        let top: u64 = (0x80000000 as u64) << 32
        while (value & top) == 0 as u64 {
            value = value << (1 as u64)
            count = count + 1
        }
        return count
    }

    micro trailing_zeros(self): u32 {
        if self == 0 as u64 {
            return 64
        }

        let mut mask: u64 = 1 as u64
        let mut count: u32 = 0
        while (self & mask) == 0 as u64 {
            mask = mask << (1 as u64)
            count = count + 1
        }
        return count
    }
}

[host_contract]
private micro __u64_add(lhs: u64, rhs: u64): u64

[host_contract]
private micro __u64_sub(lhs: u64, rhs: u64): u64

[host_contract]
private micro __u64_mul(lhs: u64, rhs: u64): u64

[host_contract]
private micro __u64_div(lhs: u64, rhs: u64): u64

[host_contract]
private micro __u64_rem(lhs: u64, rhs: u64): u64

[host_contract]
private micro __u64_eq(lhs: u64, rhs: u64): bool

[host_contract]
private micro __u64_lt(lhs: u64, rhs: u64): bool

[host_contract]
private micro __u64_and(lhs: u64, rhs: u64): u64

[host_contract]
private micro __u64_or(lhs: u64, rhs: u64): u64

[host_contract]
private micro __u64_xor(lhs: u64, rhs: u64): u64

[host_contract]
private micro __u64_shl(lhs: u64, rhs: u64): u64

[host_contract]
private micro __u64_shr(lhs: u64, rhs: u64): u64

imply u64: Equal {
    infix `==`(self, rhs: Self): bool {
        return __u64_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply u64: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `=!=`(self, rhs: Self): bool {
        return self != rhs
    }
}
