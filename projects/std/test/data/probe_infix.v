namespace std.data;

# infix 候选解析的最小复现集：每个测试一种双变量运算形态。
# 覆盖编译器已知的候选解析边界，修复前保持红色，不许用等价算术绕开。

[test]
micro test_probe_mul_two_variables() -> unit {
    # `a * b` 最小复现：`unresolved call \`infix *\``。
    let left: usize = 40
    let right: usize = 2
    let product: usize = left * right
    if product != 80 {
        panic("mul two variables mismatch")
    }
}

[test]
micro test_probe_add_two_variables() -> unit {
    let left: usize = 40
    let right: usize = 2
    let sum: usize = left + right
    if sum != 42 {
        panic("add two variables mismatch")
    }
}

[test]
micro test_probe_sub_two_variables() -> unit {
    let left: usize = 40
    let right: usize = 2
    let difference: usize = left - right
    if difference != 38 {
        panic("sub two variables mismatch")
    }
}

[test]
micro test_probe_lt_two_variables() -> unit {
    let left: usize = 40
    let right: usize = 2
    if left < right {
        panic("lt two variables mismatch")
    }
    if right < left {
    }
    else {
        panic("lt two variables mismatch")
    }
}

[test]
micro test_probe_add_variable_and_literal() -> unit {
    let left: usize = 40
    let sum: usize = left + 2
    if sum != 42 {
        panic("add variable and literal mismatch")
    }
}
