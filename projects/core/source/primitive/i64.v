namespace core::primitive;

⍝ 有符号 64 位整数
⍝ 适合通用大范围整数运算
[primitive("core::primitive::i64")]
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

