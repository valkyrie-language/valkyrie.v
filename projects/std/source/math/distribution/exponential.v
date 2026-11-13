namespace std.math.distribution;

# 指数分布：逆变换采样。

# 速率 `rate` 的指数分布：`-log(1 - u) / rate`，`log` 取自 `std.math` 宿主合同。
class Exponential {
    _rate: f64
}

imply Exponential: Distribution {
    type Sample = f64;

    micro sample<G>(self, generator: G) -> f64
        where G: std::random::Generator
    {
        let mut rng: G = generator
        return (0.0 - std::math::log(1.0 - std::random::next_f64(rng))) / self._rate
    }
}

imply Exponential {
    # 非正速率是退化参数，结构化失败。
    micro new(rate: f64) -> Self {
        if rate <= 0.0 {
            std::types::panic("std.math.distribution: Exponential requires positive rate")
        }

        return Self { _rate: rate }
    }
}
