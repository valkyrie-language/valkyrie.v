namespace std.math.distribution;

# 泊松分布：指数间隔到达计数。

# 速率 `rate`（单位区间事件数）的泊松分布：以指数分布间隔累加到达时间，
# 统计单位区间内的事件数；只消费 `Exponential` 与生成器流。
class Poisson {
    _gap: Exponential
}

imply Poisson: Distribution {
    type Sample = i32;

    micro sample<G>(self, generator: G) -> i32
        where G: std::random::Generator
    {
        let mut rng: G = generator
        let mut count: i32 = 0
        let mut elapsed: f64 = self._gap.sample(rng)
        while elapsed <= 1.0 {
            count = count + 1
            elapsed = elapsed + self._gap.sample(rng)
        }

        return count
    }
}

imply Poisson {
    # 非正速率是退化参数，结构化失败。
    micro new(rate: f64) -> Self {
        if rate <= 0.0 {
            std::types::panic("std.math.distribution: Poisson requires positive rate")
        }

        return Self { _gap: Exponential::new(rate) }
    }
}
