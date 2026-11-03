namespace std.random.distribution;

# KAT 口径：无超越函数的分布（uniform/bernoulli/binomial）做定种子精确断言；
# 含 `log`/`cos`/`sqrt` 的分布（exponential/normal/poisson）允许平台间最后进制位
# 差异，只做定种子区间断言（均值/方差/取值域），不做逐值等值。

[test]
micro `test distribution uniform_i32 known answers`() {
    let mut generator: std.random.Random = std.random.Random::with_seed(0 as u64)
    let mut expected: ArrayList<i32> = ArrayList::new(5)
    expected.push(4)
    expected.push(3)
    expected.push(4)
    expected.push(7)
    expected.push(4)

    let mut i: usize = 0
    while i < expected.length() {
        if uniform_i32(generator, 3, 9) != expected⁅i⁆ {
            panic("distribution uniform_i32 known answer mismatch")
        }

        i = i + 1
    }
}

[test]
micro `test distribution uniform_i32 stays in bounds`() {
    let mut generator: std.random.Random = std.random.Random::new()
    let mut i: i32 = 0
    while i < 64 {
        let value: i32 = uniform_i32(generator, 3, 9)
        if value < 3 || value >= 9 {
            panic("distribution uniform_i32 bound test failed")
        }

        i = i + 1
    }
}

[test]
micro `test distribution uniform_f64 known answer and bounds`() {
    let mut generator: std.random.Random = std.random.Random::with_seed(0 as u64)
    if uniform_f64(generator, 10.0, 20.0) != 18.833108082136427 {
        panic("distribution uniform_f64 known answer mismatch")
    }

    let mut i: i32 = 0
    while i < 64 {
        let value: f64 = uniform_f64(generator, 10.0, 20.0)
        if value < 10.0 || value >= 20.0 {
            panic("distribution uniform_f64 bound test failed")
        }

        i = i + 1
    }
}

[test]
micro `test distribution bernoulli known answers`() {
    let mut generator: std.random.Random = std.random.Random::with_seed(0 as u64)
    let mut expected: ArrayList<bool> = ArrayList::new(10)
    expected.push(false)
    expected.push(false)
    expected.push(true)
    expected.push(false)
    expected.push(true)
    expected.push(false)
    expected.push(true)
    expected.push(false)
    expected.push(true)
    expected.push(false)

    let mut i: usize = 0
    while i < expected.length() {
        if bernoulli(generator, 0.3) != expected⁅i⁆ {
            panic("distribution bernoulli known answer mismatch")
        }

        i = i + 1
    }
}

[test]
micro `test distribution bernoulli boundary probabilities`() {
    let mut generator: std.random.Random = std.random.Random::new()
    let mut i: i32 = 0
    while i < 8 {
        if !bernoulli(generator, 1.0) {
            panic("distribution bernoulli p=1 must always be true")
        }

        if bernoulli(generator, 0.0) {
            panic("distribution bernoulli p=0 must always be false")
        }

        i = i + 1
    }
}

[test]
micro `test distribution binomial known answers`() {
    let mut generator: std.random.Random = std.random.Random::with_seed(0 as u64)
    if binomial(generator, 20, 0.3) != 5 {
        panic("distribution binomial seed 0 known answer mismatch")
    }

    let mut other: std.random.Random = std.random.Random::with_seed(7 as u64)
    if binomial(other, 20, 0.3) != 4 {
        panic("distribution binomial seed 7 known answer mismatch")
    }
}

[test]
micro `test distribution binomial zero trials`() {
    let mut generator: std.random.Random = std.random.Random::new()
    if binomial(generator, 0, 0.5) != 0 {
        panic("distribution binomial zero trials must be zero")
    }
}

[test]
micro `test distribution exponential is non-negative`() {
    let mut generator: std.random.Random = std.random.Random::new()
    let mut i: i32 = 0
    while i < 64 {
        if exponential(generator, 2.0) < 0.0 {
            panic("distribution exponential must be non-negative")
        }

        i = i + 1
    }
}

[test]
micro `test distribution exponential mean interval`() {
    let mut generator: std.random.Random = std.random.Random::with_seed(42 as u64)
    let mut sum: f64 = 0.0
    let mut i: i32 = 0
    while i < 512 {
        sum = sum + exponential(generator, 2.0)
        i = i + 1
    }

    let mean: f64 = sum / 512.0
    if mean < 0.4 || mean > 0.6 {
        panic("distribution exponential mean interval test failed")
    }
}

[test]
micro `test distribution normal mean and variance intervals`() {
    let mut generator: std.random.Random = std.random.Random::with_seed(42 as u64)
    let mut sum: f64 = 0.0
    let mut sumsq: f64 = 0.0
    let mut i: i32 = 0
    while i < 512 {
        let value: f64 = normal(generator, 5.0, 2.0)
        sum = sum + value
        sumsq = sumsq + value * value
        i = i + 1
    }

    let mean: f64 = sum / 512.0
    let variance: f64 = sumsq / 512.0 - mean * mean
    if mean < 4.5 || mean > 5.5 {
        panic("distribution normal mean interval test failed")
    }

    if variance < 2.5 || variance > 5.5 {
        panic("distribution normal variance interval test failed")
    }
}

[test]
micro `test distribution poisson stays in range`() {
    let mut generator: std.random.Random = std.random.Random::with_seed(0 as u64)
    let mut i: i32 = 0
    while i < 16 {
        let value: i32 = poisson(generator, 3.0)
        if value < 0 || value >= 12 {
            panic("distribution poisson range test failed")
        }

        i = i + 1
    }
}

[test]
micro `test distribution poisson mean interval`() {
    let mut generator: std.random.Random = std.random.Random::with_seed(42 as u64)
    let mut sum: i32 = 0
    let mut i: i32 = 0
    while i < 512 {
        sum = sum + poisson(generator, 3.0)
        i = i + 1
    }

    let mean: f64 = (sum as f64) / 512.0
    if mean < 2.5 || mean > 3.5 {
        panic("distribution poisson mean interval test failed")
    }
}
