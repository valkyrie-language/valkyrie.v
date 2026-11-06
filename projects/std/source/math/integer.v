namespace std.math;

# 整数域归约：与 `f64` 重载同名同语义，按参数类型分流。
# 与浮点归约分文件维护，两套数值域各自独立演进。
# `i64` 最小值的绝对值超出正域，按结构化失败处理，不做静默回绕。

micro abs(value: i64): i64 {
    let minimum: i64 = (1 as i64) << (63 as i64)
    if value == minimum {
        std::types::panic("std.math: integer magnitude exceeds i64 range")
    }

    if value < 0 {
        return -value
    }

    return value
}

micro max(a: i64, b: i64): i64 {
    if a < b {
        return b
    }

    return a
}

micro min(a: i64, b: i64): i64 {
    if a < b {
        return a
    }

    return b
}

micro clamp(value: i64, lo: i64, hi: i64): i64 {
    if value < lo {
        return lo
    }

    if value > hi {
        return hi
    }

    return value
}
