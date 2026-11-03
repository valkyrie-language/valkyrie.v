namespace std.random;

# KAT 常量由 SplitMix64 参考实现交叉计算；≥2^63 的 u64 常量按高低 32 位拼写。

[test]
micro `test random splitmix64 known answers`() {
    let mut generator: Random = Random::with_seed(0 as u64)

    let first: u64 = generator.next_u64()
    if first != (((0xE220A839 as u64) << 32) | (0x7B1DCDAF as u64)) {
        panic("random splitmix64 first draw mismatch")
    }

    let second: u64 = generator.next_u64()
    if second != (((0x6E789E6A as u64) << 32) | (0xA1B965F4 as u64)) {
        panic("random splitmix64 second draw mismatch")
    }

    let third: u64 = generator.next_u64()
    if third != (0x06C45D188009454F as u64) {
        panic("random splitmix64 third draw mismatch")
    }
}

[test]
micro `test random same seed same sequence`() {
    let mut a: Random = Random::with_seed(42 as u64)
    let mut b: Random = Random::with_seed(42 as u64)

    if a.next_u64() != (((0xBDD73226 as u64) << 32) | (0x2FEB6E95 as u64)) {
        panic("random seed 42 known answer mismatch")
    }

    let mut i: i32 = 0
    while i < 8 {
        if a.next_u64() != b.next_u64() {
            panic("random same seed diverged")
        }

        i = i + 1
    }
}

[test]
micro `test random snapshot replays sequence`() {
    let mut generator: Random = Random::with_seed(7 as u64)
    generator.next_u64()
    generator.next_u64()

    let mark: u64 = generator.snapshot()
    let expected: u64 = generator.next_u64()
    if expected != (((0xE6984080 as u64) << 32) | (0xBAB12A02 as u64)) {
        panic("random snapshot known answer mismatch")
    }

    let mut replay: Random = Random::with_seed(mark)
    if replay.next_u64() != expected {
        panic("random snapshot replay mismatch")
    }
}

[test]
micro `test random next_u32 takes high half`() {
    let mut generator: Random = Random::with_seed(0 as u64)
    if generator.next_u32() != (0xE220A839 as u32) {
        panic("random next_u32 known answer mismatch")
    }
}

[test]
micro `test random below known answers`() {
    let mut generator: Random = Random::with_seed(0 as u64)
    if generator.next_u64_below(10 as u64) != (5 as u64) {
        panic("random below 10 known answer mismatch")
    }

    let mut seeded: Random = Random::with_seed(99 as u64)
    if seeded.next_u64_below(4 as u64) != (3 as u64) {
        panic("random below 4 known answer mismatch")
    }
}

[test]
micro `test random next_i32 stays in bounds`() {
    let mut generator: Random = Random::new()
    let mut i: i32 = 0

    while i < 64 {
        let value: i32 = generator.next_i32(10)
        if value < 0 {
            panic("random next_i32 lower bound test failed")
        }

        if value >= 10 {
            panic("random next_i32 bound test failed")
        }

        i = i + 1
    }
}

[test]
micro `test random range stays in bounds`() {
    let mut generator: Random = Random::new()
    let mut i: i32 = 0

    while i < 64 {
        let value: i32 = generator.next_range(3, 9)
        if value < 3 {
            panic("random range lower bound test failed")
        }

        if value >= 9 {
            panic("random range upper bound test failed")
        }

        i = i + 1
    }
}

[test]
micro `test random range handles empty span`() {
    let mut generator: Random = Random::new()

    if generator.next_range(5, 5) != 5 {
        panic("random empty span test failed")
    }

    if generator.next_range(8, 2) != 8 {
        panic("random reversed span test failed")
    }
}

[test]
micro `test random next f64 stays normalized`() {
    let mut generator: Random = Random::new()
    let value: f64 = generator.next_f64()

    if value < 0.0 {
        panic("random f64 lower bound test failed")
    }

    if value >= 1.0 {
        panic("random f64 upper bound test failed")
    }
}

[test]
micro `test random next f64 known answer`() {
    let mut generator: Random = Random::with_seed(0 as u64)
    if generator.next_f64() != 0.8833108082136426 {
        panic("random f64 known answer mismatch")
    }
}

[test]
micro `test random seeded bounds stay valid`() {
    let mut generator: Random = Random::with_seed(99 as u64)
    let value: i32 = generator.next_i32(4)

    if value < 0 {
        panic("random seeded lower bound test failed")
    }

    if value >= 4 {
        panic("random seeded upper bound test failed")
    }
}
