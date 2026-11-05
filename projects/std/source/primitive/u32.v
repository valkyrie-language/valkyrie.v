namespace std.primitive;

⍝ 无符号 32 位整数。
⍝ 适合通用无符号算术、长度与位模式表示。
[primitive("std::primitive::u32")]
structure u32 { }

imply u32 {
    infix `+`(self, rhs: Self): Self {
        __u32_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __u32_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __u32_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __u32_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __u32_rem(self, rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __u32_lt(self, rhs)
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
        __u32_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __u32_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __u32_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __u32_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __u32_shr(self, rhs)
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
        self.bit_xor(0xFFFFFFFF as u32)
    }

    # 位元查询：位宽由 `u32` 的 32 位定义，全 0 的前导/尾随零均为 32。
    # 只用 `&` / `-` / `<<` 与比较：`>>` 在 wasm 上仍被 lower 成左旋。
    micro count_ones(self): u32 {
        let mut value: u32 = self
        let mut total: u32 = 0
        while value != 0 as u32 {
            value = value & (value - (1 as u32))
            total = total + 1
        }
        return total
    }

    micro leading_zeros(self): u32 {
        if self == 0 as u32 {
            return 32
        }

        let mut value: u32 = self
        let mut count: u32 = 0
        while (value & (0x80000000 as u32)) == 0 as u32 {
            value = value << (1 as u32)
            count = count + 1
        }
        return count
    }

    micro trailing_zeros(self): u32 {
        if self == 0 as u32 {
            return 32
        }

        let mut mask: u32 = 1 as u32
        let mut count: u32 = 0
        while (self & mask) == 0 as u32 {
            mask = mask << (1 as u32)
            count = count + 1
        }
        return count
    }
}

[host_contract]
private micro __u32_add(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_sub(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_mul(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_div(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_rem(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_eq(lhs: u32, rhs: u32): bool

[host_contract]
private micro __u32_lt(lhs: u32, rhs: u32): bool

[host_contract]
private micro __u32_and(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_or(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_xor(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_shl(lhs: u32, rhs: u32): u32

[host_contract]
private micro __u32_shr(lhs: u32, rhs: u32): u32

imply u32: Equal {
    infix `==`(self, rhs: Self): bool {
        return __u32_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply u32: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `=!=`(self, rhs: Self): bool {
        return self != rhs
    }
}
