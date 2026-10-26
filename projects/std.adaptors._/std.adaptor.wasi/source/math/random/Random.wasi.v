# WASI Preview 2（`wasi` / wasip2 规格别名）

[when(target.specification == "wasi")]
namespace std.adaptor.wasi.math.random;

[host_provider(std::math::random::Random::new)]
micro host_new() -> std.math.random.Random

[host_provider(std::math::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.math.random.Random

[host_provider(std::math::random::Random::next_i32)]
micro host_next_i32(random: std.math.random.Random, max_exclusive: i32) -> i32

[host_provider(std::math::random::Random::next_f64)]
micro host_next_f64(random: std.math.random.Random) -> f64
