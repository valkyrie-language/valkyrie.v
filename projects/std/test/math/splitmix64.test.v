namespace std.math;

# SplitMix64 确定性 KAT：期望值由参考实现交叉计算。
# ≥2^63 的 u64 常量按高低 32 位拼写。本文件只消费纯算法面，
# 不触碰熵源与任何宿主合同。

[test]
micro `test splitmix64 known answers`() {
    let mut generator: SplitMix64 = SplitMix64::with_seed(0 as u64)

    let first: u64 = generator.next_u64()
    if first != (((0xE220A839 as u64) << 32) | (0x7B1DCDAF as u64)) {
        std::types::panic("splitmix64 first draw mismatch")
    }

    let second: u64 = generator.next_u64()
    if second != (((0x6E789E6A as u64) << 32) | (0xA1B965F4 as u64)) {
        std::types::panic("splitmix64 second draw mismatch")
    }

    let third: u64 = generator.next_u64()
    if third != (0x06C45D188009454F as u64) {
        std::types::panic("splitmix64 third draw mismatch")
    }
}

[test]
micro `test splitmix64 same seed same sequence`() {
    let mut a: SplitMix64 = SplitMix64::with_seed(42 as u64)
    let mut b: SplitMix64 = SplitMix64::with_seed(42 as u64)

    if a.next_u64() != (((0xBDD73226 as u64) << 32) | (0x2FEB6E95 as u64)) {
        std::types::panic("splitmix64 seed 42 known answer mismatch")
    }

    let mut i: i32 = 0
    while i < 8 {
        if a.next_u64() != b.next_u64() {
            std::types::panic("splitmix64 same seed diverged")
        }

        i = i + 1
    }
}

[test]
micro `test splitmix64 reseed replays sequence`() {
    let mut generator: SplitMix64 = SplitMix64::with_seed(0 as u64)
    let first: u64 = generator.next_u64()
    generator.next_u64()
    generator.next_u64()

    generator.reseed(0 as u64)
    if generator.next_u64() != first {
        std::types::panic("splitmix64 reseed replay mismatch")
    }
}

[test]
micro `test splitmix64 snapshot replays sequence`() {
    let mut generator: SplitMix64 = SplitMix64::with_seed(7 as u64)
    generator.next_u64()
    generator.next_u64()

    let mark: u64 = generator.snapshot()
    let expected: u64 = generator.next_u64()
    if expected != (((0xE6984080 as u64) << 32) | (0xBAB12A02 as u64)) {
        std::types::panic("splitmix64 snapshot known answer mismatch")
    }

    let mut replay: SplitMix64 = SplitMix64::with_seed(mark)
    if replay.next_u64() != expected {
        std::types::panic("splitmix64 snapshot replay mismatch")
    }
}
