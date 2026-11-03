namespace std.random;

# std.random — 宿主能力边界：熵源与生成器合同。
#
# 本包只定义能力与合同，不定义算法：
# - 熵源 `entropy()`：无种子，只从宿主取熵，不产生序列。各目标 adaptor 以
#   `[host_provider(std::random::entropy)]` 提供；缺 provider 时计划阶段结构化失败，
#   无内建表、无名字特判、无默认返回值兜底。
# - 生成器合同 `Generator`：种子状态与状态推进语义在合同上（同种子 + 同算法 → 同序列）；
#   具体算法不进合同本体，也不作为合同默认方法焊死。具体算法是实现该 trait 的类型
#   （如 `std.math.SplitMix64`），合同不反向依赖任何实现。
# - 派生流操作（范围取样、实数化等）是约束 `Generator` 的泛型函数，不是合同默认方法。
# - 默认流是策略层：`seeded_stream` / `random_stream` 给出可替换的默认实现与构造入口；
#   更换算法只改策略层返回的实现类型，不改合同、不改消费者。
# - 宿主自带序列（`java.util.Random` / `System.Random` 等）不绑定：其序列不满足
#   同种子同序列合同。

# 生成器能力合同。
#
# 合同语义：
# - 种子是完整初始状态：`reseed(seed)` 之后，后续 `next_u64` 序列唯一确定。
# - 同种子 + 同一实现算法 → 同一序列；跨 lane 一致性由本合同表达，
#   不靠单一实现独占保证。
# - 合同不规定混合算法与状态表示；序列产生能力由实现类型提供。
trait Generator {
    micro reseed(mut self, seed: u64): unit
    micro next_u64(mut self) -> u64
}

# 宿主熵源：无种子，只取熵，不产生序列。
# 目标缺少 `[host_provider(std::random::entropy)]` 时计划阶段结构化失败。
[host_contract]
micro entropy() -> u64

# 默认流策略层：种子构造入口。默认实现为 `std.math.SplitMix64`；
# 更换算法只替换此处返回的实现类型，合同与消费者不变。
micro seeded_stream(seed: u64) -> std.math.SplitMix64 {
    return std::math::SplitMix64::with_seed(seed)
}

# 默认流策略层：熵构造入口。每次调用以宿主熵源播种一条新流。
micro random_stream() -> std.math.SplitMix64 {
    return seeded_stream(entropy())
}

# 取高 32 位。
micro next_u32<G>(mut generator: G) -> u32
    where G: Generator
{
    return (generator.next_u64() >> 32) as u32
}

# `[0, bound)` 无偏取样：拒绝采样消除模偏，不直接裸取 `%`。
# `bound` 为 0 是退化参数，结构化失败。
micro next_u64_below<G>(mut generator: G, bound: u64) -> u64
    where G: Generator
{
    if bound == (0 as u64) {
        std::types::panic("std.random: next_u64_below bound must be non-zero")
    }

    let threshold: u64 = ((0 as u64) - bound) % bound
    let mut x: u64 = generator.next_u64()
    while x < threshold {
        x = generator.next_u64()
    }

    return x % bound
}

# `[0, max_exclusive)`；非正上界是退化参数，结构化失败。
micro next_i32<G>(mut generator: G, max_exclusive: i32) -> i32
    where G: Generator
{
    if max_exclusive <= 0 {
        std::types::panic("std.random: next_i32 bound must be positive")
    }

    return next_u64_below(generator, max_exclusive as u64) as i32
}

# `[min, max)`；退化区间（`max <= min`）恒返回 `min`。
micro next_range<G>(mut generator: G, min: i32, max: i32) -> i32
    where G: Generator
{
    if max <= min {
        return min
    }

    return min + next_i32(generator, max - min)
}

micro next_bool<G>(mut generator: G) -> bool
    where G: Generator
{
    return next_u64_below(generator, 2 as u64) == (1 as u64)
}

# `[0, 1)` 均匀实数：取高 53 位乘以 2^-53。
micro next_f64<G>(mut generator: G) -> f64
    where G: Generator
{
    return ((generator.next_u64() >> 11) as f64) * (1.0 / 9007199254740992.0)
}
