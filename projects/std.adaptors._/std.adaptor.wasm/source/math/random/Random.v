# std.adaptor.wasm: Random host_provider
# adaptor 在 std 之前编译，不得 brace-construct / 字段访问 std.math.random.Random，
# 也不得调用 std 包内 fallback；布局与随机源由 wasm env host 承担。

namespace std.adaptor.wasm.math.random;

[host_provider(std::math::random::Random::new)]
micro host_new() -> std.math.random.Random {
    return __host_random_new()
}

[host_provider(std::math::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.math.random.Random {
    return __host_random_with_seed(seed)
}

[host_provider(std::math::random::Random::next_i32)]
micro host_next_i32(random: std.math.random.Random, max_exclusive: i32) -> i32 {
    return __host_random_next_i32(random, max_exclusive)
}

[host_provider(std::math::random::Random::next_f64)]
micro host_next_f64(random: std.math.random.Random) -> f64 {
    return __host_random_next_f64(random)
}

[wasm("env", "random_new")]
private micro __host_random_new(): std.math.random.Random

[wasm("env", "random_with_seed")]
private micro __host_random_with_seed(seed: i32): std.math.random.Random

[wasm("env", "random_next_i32")]
private micro __host_random_next_i32(random: std.math.random.Random, max_exclusive: i32): i32

[wasm("env", "random_next_f64")]
private micro __host_random_next_f64(random: std.math.random.Random): f64
