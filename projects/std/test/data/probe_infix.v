namespace std.data;

# 双变量运算形态的解析测试：每个测试覆盖一种运算。

[test]
micro test_probe_mul_two_variables() -> unit {
    # 双变量乘法。
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
