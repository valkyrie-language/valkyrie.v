namespace std.math;

# 数论公共面：`gcd` / `lcm` 的正例、零值与负数口径。
# 溢出路径走 `std::types::panic`，测试框架不捕获 `raise`，故只覆盖可表示边界。

[test]
micro `test gcd zero and sign normalization`() {
    if gcd(0, 0) != 0 {
        std::types::panic("gcd(0, 0) must be 0")
    }

    if gcd(0, 5) != 5 {
        std::types::panic("gcd(0, 5) must be 5")
    }

    if gcd(5, 0) != 5 {
        std::types::panic("gcd(5, 0) must be 5")
    }

    if gcd(12, 18) != 6 {
        std::types::panic("gcd(12, 18) must be 6")
    }

    if gcd(-12, 18) != 6 {
        std::types::panic("gcd(-12, 18) must be 6")
    }

    if gcd(12, -18) != 6 {
        std::types::panic("gcd(12, -18) must be 6")
    }

    if gcd(-12, -18) != 6 {
        std::types::panic("gcd(-12, -18) must be 6")
    }
}

[test]
micro `test lcm zero and sign normalization`() {
    if lcm(0, 0) != 0 {
        std::types::panic("lcm(0, 0) must be 0")
    }

    if lcm(0, 7) != 0 {
        std::types::panic("lcm(0, 7) must be 0")
    }

    if lcm(7, 0) != 0 {
        std::types::panic("lcm(7, 0) must be 0")
    }

    if lcm(4, 6) != 12 {
        std::types::panic("lcm(4, 6) must be 12")
    }

    if lcm(-4, 6) != 12 {
        std::types::panic("lcm(-4, 6) must be 12")
    }

    if lcm(4, -6) != 12 {
        std::types::panic("lcm(4, -6) must be 12")
    }

    if lcm(-4, -6) != 12 {
        std::types::panic("lcm(-4, -6) must be 12")
    }
}

[test]
micro `test lcm reduces by gcd before multiply`() {
    # 2^40 与 3 互素：结果 3 * 2^40 = 3298534883328，完整落在 i64 正域。
    let power: i64 = (1 as i64) << (40 as i64)
    if gcd(power, 3) != 1 {
        std::types::panic("gcd(2^40, 3) must be 1")
    }

    if lcm(power, 3) != 3298534883328 {
        std::types::panic("lcm(2^40, 3) must be 3298534883328")
    }

    # 有公因子时先归约：lcm(2^40 * 3, 2^40) 等于 2^40 * 3。
    let with_factor: i64 = power * 3
    if lcm(with_factor, power) != 3298534883328 {
        std::types::panic("lcm(3 * 2^40, 2^40) must be 3298534883328")
    }
}
