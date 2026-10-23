namespace core::primitive;

⍝ 64 位浮点数
⍝ 适合通用科学计算与高精度近似数值运算
[primitive("core::primitive::f64")]
structure f64 { }

imply f64 {
    infix `+`(self, rhs: Self): Self {
        __f64_add(self, rhs)
    }

    infix `-`(self, rhs: Self): Self {
        __f64_sub(self, rhs)
    }

    infix `*`(self, rhs: Self): Self {
        __f64_mul(self, rhs)
    }

    infix `/`(self, rhs: Self): Self {
        __f64_div(self, rhs)
    }

    infix `==`(self, rhs: Self): bool {
        __f64_eq(self, rhs)
    }

    infix `!=`(self, rhs: Self): bool {
        !(self == rhs)
    }

    infix `<`(self, rhs: Self): bool {
        __f64_lt(self, rhs)
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
        __f64_neg(self)
    }
}

[host_contract]
private micro __f64_add(lhs: f64, rhs: f64): f64

[host_contract]
private micro __f64_sub(lhs: f64, rhs: f64): f64

[host_contract]
private micro __f64_neg(self: f64): f64

[host_contract]
private micro __f64_mul(lhs: f64, rhs: f64): f64

[host_contract]
private micro __f64_div(lhs: f64, rhs: f64): f64

[host_contract]
private micro __f64_eq(lhs: f64, rhs: f64): bool

[host_contract]
private micro __f64_lt(lhs: f64, rhs: f64): bool

