namespace std.math.distribution;

# 均匀分布：区间上的等概率采样。

# 整数均匀分布 `[min, max_exclusive)`。
class UniformI32 {
    _min: i32
    _span: i32
}

imply UniformI32: Distribution {
    type Sample = i32;

    micro sample<G>(self, generator: G) -> i32
        where G: std::random::Generator
    {
        let mut rng: G = generator
        return self._min + std::random::next_i32(rng, self._span)
    }
}

imply UniformI32 {
    # 空区间与反向区间是退化参数，结构化失败。
    micro new(min: i32, max_exclusive: i32) -> Self {
        if max_exclusive <= min {
            std::types::panic("std.math.distribution: UniformI32 requires min < max_exclusive")
        }

        return Self { _min: min, _span: max_exclusive - min }
    }
}

# 实数均匀分布 `[min, max)`。
class UniformF64 {
    _min: f64
    _span: f64
}

imply UniformF64: Distribution {
    type Sample = f64;

    micro sample<G>(self, generator: G) -> f64
        where G: std::random::Generator
    {
        let mut rng: G = generator
        return self._min + self._span * std::random::next_f64(rng)
    }
}

imply UniformF64 {
    # 空区间与反向区间是退化参数，结构化失败。
    micro new(min: f64, max: f64) -> Self {
        if max <= min {
            std::types::panic("std.math.distribution: UniformF64 requires min < max")
        }

        return Self { _min: min, _span: max - min }
    }
}
