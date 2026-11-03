namespace std.random;

# Generator 合同与派生流操作的 KAT：实现类型取 `std.math.SplitMix64`，
# 期望值与纯算法面一致。熵源端到端用例依赖目标 adaptor 的
# `[host_provider(std::random::entropy)]`。

[test]
micro `test generator next_u32 takes high half`() {
    let mut generator: std.math.SplitMix64 = std::math::SplitMix64::with_seed(0 as u64)
    if next_u32(generator) != (0xE220A839 as u32) {
        std::types::panic("generator next_u32 known answer mismatch")
    }
}

[test]
micro `test generator below known answers`() {
    let mut generator: std.math.SplitMix64 = std::math::SplitMix64::with_seed(0 as u64)
    if next_u64_below(generator, 10 as u64) != (5 as u64) {
        std::types::panic("generator below 10 known answer mismatch")
    }

    let mut seeded: std.math.SplitMix64 = std::math::SplitMix64::with_seed(99 as u64)
    if next_u64_below(seeded, 4 as u64) != (3 as u64) {
        std::types::panic("generator below 4 known answer mismatch")
    }
}

[test]
micro `test generator next_i32 stays in bounds`() {
    let mut generator: std.math.SplitMix64 = std::math::SplitMix64::with_seed(0 as u64)
    let mut i: i32 = 0

    while i < 64 {
        let value: i32 = next_i32(generator, 10)
        if value < 0 {
            std::types::panic("generator next_i32 lower bound test failed")
        }

        if value >= 10 {
            std::types::panic("generator next_i32 bound test failed")
        }

        i = i + 1
    }
}

[test]
micro `test generator range stays in bounds`() {
    let mut generator: std.math.SplitMix64 = std::math::SplitMix64::with_seed(0 as u64)
    let mut i: i32 = 0

    while i < 64 {
        let value: i32 = next_range(generator, 3, 9)
        if value < 3 {
            std::types::panic("generator range lower bound test failed")
        }

        if value >= 9 {
            std::types::panic("generator range upper bound test failed")
        }

        i = i + 1
    }
}

[test]
micro `test generator range handles empty span`() {
    let mut generator: std.math.SplitMix64 = std::math::SplitMix64::with_seed(0 as u64)

    if next_range(generator, 5, 5) != 5 {
        std::types::panic("generator empty span test failed")
    }

    if next_range(generator, 8, 2) != 8 {
        std::types::panic("generator reversed span test failed")
    }
}

[test]
micro `test generator next f64 known answer`() {
    let mut generator: std.math.SplitMix64 = std::math::SplitMix64::with_seed(0 as u64)
    let value: f64 = next_f64(generator)
    if value != 0.8833108082136426 {
        std::types::panic("generator f64 known answer mismatch")
    }
}

[test]
micro `test generator next f64 stays normalized`() {
    let mut generator: std.math.SplitMix64 = std::math::SplitMix64::with_seed(0 as u64)
    let mut i: i32 = 0

    while i < 64 {
        let value: f64 = next_f64(generator)
        if value < 0.0 {
            std::types::panic("generator f64 lower bound test failed")
        }

        if value >= 1.0 {
            std::types::panic("generator f64 upper bound test failed")
        }

        i = i + 1
    }
}

[test]
micro `test generator bool reproducible`() {
    let mut a: std.math.SplitMix64 = std::math::SplitMix64::with_seed(5 as u64)
    let mut b: std.math.SplitMix64 = std::math::SplitMix64::with_seed(5 as u64)
    let mut i: i32 = 0

    while i < 16 {
        if next_bool(a) != next_bool(b) {
            std::types::panic("generator bool same seed diverged")
        }

        i = i + 1
    }
}

[test]
micro `test generator seeded stream replays known answers`() {
    let mut generator: std.math.SplitMix64 = seeded_stream(0 as u64)
    if generator.next_u64() != (((0xE220A839 as u64) << 32) | (0x7B1DCDAF as u64)) {
        std::types::panic("generator seeded_stream known answer mismatch")
    }
}

[test]
micro `test generator entropy stream usable`() {
    let mut generator: std.math.SplitMix64 = random_stream()
    let mut i: i32 = 0

    while i < 16 {
        let value: i32 = next_i32(generator, 100)
        if value < 0 {
            std::types::panic("generator entropy stream lower bound test failed")
        }

        if value >= 100 {
            std::types::panic("generator entropy stream upper bound test failed")
        }

        i = i + 1
    }
}
