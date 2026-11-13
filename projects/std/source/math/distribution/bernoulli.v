namespace std.math.distribution;

# 伯努利试验与按试验次数计数的分布。

# 伯努利试验：以概率 `p` 返回 `true`。
class Bernoulli {
    _p: f64
}

imply Bernoulli: Distribution {
    type Sample = bool;

    micro sample<G>(self, generator: G) -> bool
        where G: std::random::Generator
    {
        let mut rng: G = generator
        return std::random::next_f64(rng) < self._p
    }
}

imply Bernoulli {
    # `[0, 1]` 之外的概率是退化参数，结构化失败。
    micro new(p: f64) -> Self {
        if p < 0.0 {
            std::types::panic("std.math.distribution: Bernoulli probability below zero")
        }

        if p > 1.0 {
            std::types::panic("std.math.distribution: Bernoulli probability above one")
        }

        return Self { _p: p }
    }
}

# 二项分布：`trials` 次独立伯努利试验的成功次数。
class Binomial {
    _trials: i32
    _event: Bernoulli
}

imply Binomial: Distribution {
    type Sample = i32;

    micro sample<G>(self, generator: G) -> i32
        where G: std::random::Generator
    {
        let mut rng: G = generator
        let mut count: i32 = 0
        let mut i: i32 = 0
        while i < self._trials {
            if self._event.sample(rng) {
                count = count + 1
            }

            i = i + 1
        }

        return count
    }
}

imply Binomial {
    # 负试验次数是退化参数，结构化失败；零试验是合法边界，采样恒为 0。
    micro new(trials: i32, p: f64) -> Self {
        if trials < 0 {
            std::types::panic("std.math.distribution: Binomial requires non-negative trials")
        }

        return Self { _trials: trials, _event: Bernoulli::new(p) }
    }
}
