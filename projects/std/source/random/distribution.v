namespace std.random.distribution;

# std.random.distribution — 分布在 `std.random.Random` 之上的采样。
#
# 语义不变量：
# - 全部分布只消费 `Random` 的确定性流；同种子同样本，与平台无关。
# - 连续分布的超越函数（`sqrt`/`log`/`cos`）取自 `std.math` 的纯函数合同；
#   浮点超越函数允许平台间最后进制位差异，区间断言按此留量。
# - 退化参数一律结构化失败（`std::types::panic`），不返回默认值：
#   空/反向区间、越界概率、非正速率、零或负标准差。

# `[min, max_exclusive)` 整数均匀分布。
micro uniform_i32(mut random: std.random.Random, min: i32, max_exclusive: i32) -> i32 {
    if max_exclusive <= min {
        std::types::panic("std.random.distribution: uniform_i32 requires min < max_exclusive")
    }

    return min + random.next_i32(max_exclusive - min)
}

# `[min, max)` 实数均匀分布。
micro uniform_f64(mut random: std.random.Random, min: f64, max: f64) -> f64 {
    if max <= min {
        std::types::panic("std.random.distribution: uniform_f64 requires min < max")
    }

    return min + (max - min) * random.next_f64()
}

# 伯努利试验：以概率 `p` 返回 `true`。
micro bernoulli(mut random: std.random.Random, p: f64) -> bool {
    if p < 0.0 {
        std::types::panic("std.random.distribution: bernoulli probability below zero")
    }

    if p > 1.0 {
        std::types::panic("std.random.distribution: bernoulli probability above one")
    }

    return random.next_f64() < p
}

# 二项分布：`trials` 次独立伯努利试验的成功次数。
micro binomial(mut random: std.random.Random, trials: i32, p: f64) -> i32 {
    if trials < 0 {
        std::types::panic("std.random.distribution: binomial requires non-negative trials")
    }

    let mut count: i32 = 0
    let mut i: i32 = 0
    while i < trials {
        if bernoulli(random, p) {
            count = count + 1
        }

        i = i + 1
    }

    return count
}

# 指数分布（速率 `rate`）：逆变换采样，`-log(1 - u) / rate`。
micro exponential(mut random: std.random.Random, rate: f64) -> f64 {
    if rate <= 0.0 {
        std::types::panic("std.random.distribution: exponential requires positive rate")
    }

    return (0.0 - std::math::log(1.0 - random.next_f64())) / rate
}

# 正态分布：Box-Muller 极坐标法，每次调用取一对均匀样本、返回 `z0`。
micro normal(mut random: std.random.Random, mean: f64, std_dev: f64) -> f64 {
    if std_dev <= 0.0 {
        std::types::panic("std.random.distribution: normal requires positive std_dev")
    }

    let u1: f64 = random.next_f64()
    let u2: f64 = random.next_f64()
    let radius: f64 = std::math::sqrt(-2.0 * std::math::log(1.0 - u1))
    return mean + std_dev * radius * std::math::cos(2.0 * __distribution_pi() * u2)
}

# 泊松分布（速率 `rate`，单位区间事件数）：指数分布间隔到达计数，只用 `log`。
micro poisson(mut random: std.random.Random, rate: f64) -> i32 {
    if rate <= 0.0 {
        std::types::panic("std.random.distribution: poisson requires positive rate")
    }

    let mut count: i32 = 0
    let mut elapsed: f64 = exponential(random, rate)
    while elapsed <= 1.0 {
        count = count + 1
        elapsed = elapsed + exponential(random, rate)
    }

    return count
}

private micro __distribution_pi() -> f64 {
    return 3.141592653589793
}
