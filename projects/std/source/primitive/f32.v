namespace std.primitive;

⍝ 32 位浮点数。
⍝ 适合图形、信号与对空间占用敏感的近似数值计算。
[primitive("std::primitive::f32")]
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

    ⍝ 返回 IEEE-754 原始位模式，不做数值转换。
    micro to_bits(self): u32 {
        __f32_to_bits(self)
    }

    ⍝ 从 IEEE-754 原始位模式重建，保留 -0.0、次正规数与 NaN payload。
    micro from_bits(bits: u32): Self {
        __f32_from_bits(bits)
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

# region f32 位模式重解释
⍝ 只搬位、不做数值转换：`to_bits` 必须得到 32 位位模式，`from_bits` 往返后位模式恒等。
[host_contract]
private micro __f32_to_bits(self: f32): u32

[host_contract]
private micro __f32_from_bits(bits: u32): f32
# end region
# end region
