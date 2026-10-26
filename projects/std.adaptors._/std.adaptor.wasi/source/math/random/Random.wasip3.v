# WASI Preview 3：无 [js] / [wasm]；正式 component binding 由 backend 消费（待实现）。

[when(target.specification == "wasip3")]
namespace std.adaptor.wasi.math.random;

[host_provider(std::math::random::Random::new)]
micro host_new() -> std.math.random.Random

[host_provider(std::math::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.math.random.Random

[host_provider(std::math::random::Random::next_i32)]
micro host_next_i32(random: std.math.random.Random, max_exclusive: i32) -> i32

[host_provider(std::math::random::Random::next_f64)]
micro host_next_f64(random: std.math.random.Random) -> f64
