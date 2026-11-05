namespace std.math;

# std.math 数论：整数最大公约数与最小公倍数。
#
# 口径：
# - 结果恒为非负；负数按绝对值参与计算。
# - `gcd(0, 0) == 0`：Euclid 终止时 `x` 即 0，与常见库一致。
# - `lcm(0, n) == lcm(n, 0) == 0`。
# - `i64` 最小值的绝对值超出 `i64` 正域，属不可表示输入；
#   先于取反判定并 `panic`，不依赖回绕后的负值继续计算。
# - `lcm` 先以 `|a| / gcd` 归约，再判定归约商与另一因子的乘积上限；
#   溢出按 std 既有域检查约定 `panic` 结构化失败，不做静默回绕。

# `i64` 最小值的位模式：`1 << 63` 在 64 位补码里只有符号位。
private micro i64_minimum() -> i64 {
    return (1 as i64) << (63 as i64)
}

# `i64` 最大值的位模式：高 31 位与低 32 位拼接，避免超长十进制字面量。
private micro i64_maximum() -> i64 {
    return ((0x7FFFFFFF as i64) << 32) | (0xFFFFFFFF as i64)
}

# 取绝对值；不可表示的最小值在此结构化失败，不进入后续算术。
private micro magnitude(value: i64) -> i64 {
    if value == i64_minimum() {
        std::types::panic("std.math: integer magnitude exceeds i64 range")
    }

    if value < 0 {
        return -value
    }

    return value
}

micro gcd(a: i64, b: i64) -> i64 {
    let mut x: i64 = magnitude(a)
    let mut y: i64 = magnitude(b)

    while y != 0 {
        let remainder: i64 = x % y
        x = y
        y = remainder
    }

    return x
}

micro lcm(a: i64, b: i64) -> i64 {
    let x: i64 = magnitude(a)
    let y: i64 = magnitude(b)

    if x == 0 || y == 0 {
        return 0
    }

    let divisor: i64 = gcd(x, y)
    let reduced: i64 = x / divisor
    let limit: i64 = i64_maximum() / y
    if reduced > limit {
        std::types::panic("std.math: lcm exceeds i64 range")
    }

    return reduced * y
}
