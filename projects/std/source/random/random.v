namespace std.random;

# std.random — 确定性伪随机源。
#
# 合同与默认实现同体：种子、序列算法、范围取样与快照/复现语义在此固定，
# 全部平台共享同一份纯 V 实现。唯一的宿主能力是 `new()` 的无种子熵源，
# 由各目标 adaptor 以 `[host_provider]` 注入；未绑定的目标回落到默认体的
# 固定种子，得到全平台一致的可复现序列。
#
# 语义不变量：
# - 算法为 SplitMix64：单个 `u64` 状态、可序列化；同种子同序列，与平台无关。
# - 快照即状态：`snapshot()` 返回当前状态；`with_seed(快照)` 从断点复现续流。
# - 范围取样无偏：`next_u64_below` 以拒绝采样消除模偏，不直接裸取 `%`。
# - ≥2^63 的 u64 常量按高低 32 位拼写（编译器大十六进制字面量缺陷未修）。

class Random {
    _state: u64
}

imply Random {
    # 无种子构造：熵源归宿主 provider；默认体为固定种子，全平台可复现。
    [host_contract]
    micro new() -> Self {
        return Self { _state: __random_default_seed() }
    }

    # 种子即完整初始状态：同种子同序列；`with_seed(snapshot())` 即断点复现。
    micro with_seed(seed: u64) -> Self {
        return Self { _state: seed }
    }

    # 快照：返回当前状态，交给 `with_seed` 可从断点重放后续序列。
    micro snapshot(self) -> u64 {
        return self._state
    }

    # SplitMix64 步进：状态先加黄金比例增量，再经两轮 xor-移位-乘混合。
    micro next_u64(mut self) -> u64 {
        self._state = self._state + __random_gamma()
        let mut z: u64 = self._state
        z = (z ^ (z >> 30)) * __random_multiplier_a()
        z = (z ^ (z >> 27)) * __random_multiplier_b()
        return z ^ (z >> 31)
    }

    micro next_u32(mut self) -> u32 {
        return (self.next_u64() >> 32) as u32
    }

    # `[0, bound)` 无偏取样；`bound` 为 0 是退化参数，结构化失败。
    micro next_u64_below(mut self, bound: u64) -> u64 {
        if bound == (0 as u64) {
            std::types::panic("std.random: next_u64_below bound must be non-zero")
        }

        let threshold: u64 = ((0 as u64) - bound) % bound
        let mut x: u64 = self.next_u64()
        while x < threshold {
            x = self.next_u64()
        }

        return x % bound
    }

    # `[0, max_exclusive)`；非正上界是退化参数，结构化失败。
    micro next_i32(mut self, max_exclusive: i32) -> i32 {
        if max_exclusive <= 0 {
            std::types::panic("std.random: next_i32 bound must be positive")
        }

        return self.next_u64_below(max_exclusive as u64) as i32
    }

    # `[min, max)`；退化区间（`max <= min`）恒返回 `min`。
    micro next_range(mut self, min: i32, max: i32) -> i32 {
        if max <= min {
            return min
        }

        return min + self.next_i32(max - min)
    }

    micro next_bool(mut self) -> bool {
        return self.next_u64_below(2 as u64) == (1 as u64)
    }

    # `[0, 1)` 均匀实数：取高 53 位乘以 2^-53。
    micro next_f64(mut self) -> f64 {
        return ((self.next_u64() >> 11) as f64) * (1.0 / 9007199254740992.0)
    }
}

# SplitMix64 黄金比例增量 0x9E3779B97F4A7C15。
private micro __random_gamma() -> u64 {
    return ((0x9E3779B9 as u64) << 32) | (0x7F4A7C15 as u64)
}

# SplitMix64 混合乘子 0xBF58476D1CE4E5B9。
private micro __random_multiplier_a() -> u64 {
    return ((0xBF58476D as u64) << 32) | (0x1CE4E5B9 as u64)
}

# SplitMix64 混合乘子 0x94D049BB133111EB。
private micro __random_multiplier_b() -> u64 {
    return ((0x94D049BB as u64) << 32) | (0x133111EB as u64)
}

# `new()` 默认体的固定种子（SplitMix64 参考实现默认 0x853C49E6748FEA9B）。
private micro __random_default_seed() -> u64 {
    return ((0x853C49E6 as u64) << 32) | (0x748FEA9B as u64)
}
