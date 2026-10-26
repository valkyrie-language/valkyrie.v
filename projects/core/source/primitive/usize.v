namespace core::primitive;

⍝ 无符号指针宽度整数。
⍝ 适合索引、长度与平台相关无符号计数。
[primitive("core::primitive::usize")]
structure usize { }

imply usize {
    infix `+`(self, rhs: Self): Self {
        __usize_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __usize_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __usize_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __usize_div(self, rhs)
    }

    infix `%`(self, rhs: Self): Self {
        __usize_rem(self, rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __usize_lt(self, rhs)
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
        __usize_and(self, rhs)
    }

    bit_or(self, rhs: Self): Self {
        __usize_or(self, rhs)
    }

    bit_xor(self, rhs: Self): Self {
        __usize_xor(self, rhs)
    }

    bit_shift_left(self, rhs: Self): Self {
        __usize_shl(self, rhs)
    }

    bit_shift_right(self, rhs: Self): Self {
        __usize_shr(self, rhs)
    }
}

[host_contract]
private micro __usize_add(lhs: usize, rhs: usize): usize

[host_contract]
private micro __usize_sub(lhs: usize, rhs: usize): usize

[host_contract]
private micro __usize_mul(lhs: usize, rhs: usize): usize

[host_contract]
private micro __usize_div(lhs: usize, rhs: usize): usize

[host_contract]
private micro __usize_rem(lhs: usize, rhs: usize): usize

[host_contract]
private micro __usize_eq(lhs: usize, rhs: usize): bool

[host_contract]
private micro __usize_lt(lhs: usize, rhs: usize): bool

[host_contract]
private micro __usize_and(lhs: usize, rhs: usize): usize

[host_contract]
private micro __usize_or(lhs: usize, rhs: usize): usize

[host_contract]
private micro __usize_xor(lhs: usize, rhs: usize): usize

[host_contract]
private micro __usize_shl(lhs: usize, rhs: usize): usize

[host_contract]
private micro __usize_shr(lhs: usize, rhs: usize): usize

imply usize: Eq {
    infix `==`(self, rhs: Self): bool {
        return __usize_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        return !(self == rhs)
    }
}

imply usize: Identical {
    infix `===`(self, rhs: Self): bool {
        return self == rhs
    }

    infix `!==`(self, rhs: Self): bool {
        return self != rhs
    }
}
