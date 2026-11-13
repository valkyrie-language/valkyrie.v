namespace std.math.distribution;

# 正态分布：Box-Muller 极坐标法。

# 均值 `mean`、标准差 `std_dev` 的正态分布：每次采样消费两个均匀样本，
# 返回极坐标变换的 `z0`；`sqrt` / `log` / `cos` 取自 `std.math` 宿主合同，
# 常量 `pi` 取自 `std.math` 常量面。
class Normal {
    _mean: f64
    _std_dev: f64
}

imply Normal: Distribution {
    type Sample = f64;

    micro sample<G>(self, generator: G) -> f64
        where G: std::random::Generator
    {
        let mut rng: G = generator
        let u1: f64 = std::random::next_f64(rng)
        let u2: f64 = std::random::next_f64(rng)
        let radius: f64 = std::math::sqrt(-2.0 * std::math::log(1.0 - u1))
        return self._mean + self._std_dev * radius * std::math::cos(2.0 * std::math::pi * u2)
    }
}

imply Normal {
    # 非正标准差是退化参数，结构化失败。
    micro new(mean: f64, std_dev: f64) -> Self {
        if std_dev <= 0.0 {
            std::types::panic("std.math.distribution: Normal requires positive std_dev")
        }

        return Self { _mean: mean, _std_dev: std_dev }
    }
}
