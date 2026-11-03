namespace std.math;

# std.math.SplitMix64 — 确定性伪随机序列算法：纯函数、可复现、
# 不依赖宿主能力、不引入 provider。实现 `std.random.Generator` 合同；
# 同种子同序列，跨 lane 一致。
#
# 语义不变量：
# - 单个 `u64` 状态、可序列化：`snapshot()` 返回当前状态；
#   `with_seed(快照)` 从断点复现续流。
# - 步进：状态先加黄金比例增量，再经两轮 xor-移位-乘混合。
# - ≥2^63 的 u64 常量按高低 32 位拼写（无大十六进制字面量语法）。

class SplitMix64 {
    _state: u64
}

imply SplitMix64: std::random::Generator {
    # 种子即完整初始状态：同种子同序列；`with_seed(snapshot())` 即断点复现。
    micro reseed(mut self, seed: u64): unit {
        self._state = seed
    }

    micro next_u64(mut self) -> u64 {
        self._state = self._state + splitmix64_gamma()
        let mut z: u64 = self._state
        z = (z ^ (z >> 30)) * splitmix64_multiplier_a()
        z = (z ^ (z >> 27)) * splitmix64_multiplier_b()
        return z ^ (z >> 31)
    }
}

imply SplitMix64 {
    micro with_seed(seed: u64) -> Self {
        return Self { _state: seed }
    }

    # 快照：返回当前状态，交给 `with_seed` 可从断点重放后续序列。
    micro snapshot(self) -> u64 {
        return self._state
    }
}

# 黄金比例增量 0x9E3779B97F4A7C15。
private micro splitmix64_gamma() -> u64 {
    return ((0x9E3779B9 as u64) << 32) | (0x7F4A7C15 as u64)
}

# 混合乘子 0xBF58476D1CE4E5B9。
private micro splitmix64_multiplier_a() -> u64 {
    return ((0xBF58476D as u64) << 32) | (0x1CE4E5B9 as u64)
}

# 混合乘子 0x94D049BB133111EB。
private micro splitmix64_multiplier_b() -> u64 {
    return ((0x94D049BB as u64) << 32) | (0x133111EB as u64)
}
