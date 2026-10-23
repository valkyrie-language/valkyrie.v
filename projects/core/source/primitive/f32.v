namespace core::primitive;

⍝ 32 位浮点数。
⍝ 适合图形、信号与对空间占用敏感的近似数值计算。
[primitive("core::primitive::f32")]
structure f32 { }

imply f32 {
    infix `+`(self, rhs: Self): Self {
        __f32_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __f32_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __f32_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __f32_div(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __f32_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __f32_lt(self, rhs)
    }

    infix `<=`(self, rhs: Self): bool {
        if self < rhs {
            return true
        }

        return self == rhs
    }

    infix `>`(self, rhs: Self): bool {
        rhs < self
    }

    infix `>=`(self, rhs: Self): bool {
        if rhs < self {
            return true
        }

        return self == rhs
    }

    prefix `-`(self): Self {
        __f32_neg(self)
    }
}

# region f32 内部指令映射
[host_contract]
private micro __f32_add(lhs: f32, rhs: f32): f32

[host_contract]
private micro __f32_sub(lhs: f32, rhs: f32): f32

[host_contract]
private micro __f32_neg(self: f32): f32

[host_contract]
private micro __f32_mul(lhs: f32, rhs: f32): f32

[host_contract]
private micro __f32_div(lhs: f32, rhs: f32): f32

[host_contract]
private micro __f32_eq(lhs: f32, rhs: f32): bool

[host_contract]
private micro __f32_lt(lhs: f32, rhs: f32): bool
# end region
