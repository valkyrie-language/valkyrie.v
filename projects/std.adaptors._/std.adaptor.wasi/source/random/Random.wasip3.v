# WASI Preview 3：无 [js] / [wasm]；正式 component binding 由 backend 消费（待实现）。

[when(target.specification == "wasip3")]
namespace std.adaptor.wasi.random;

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random

[host_provider(std::random::Random::with_seed)]
micro host_with_seed(seed: i32) -> std.random.Random

[host_provider(std::random::Random::next_i32)]
micro host_next_i32(random: std.random.Random, max_exclusive: i32) -> i32

[host_provider(std::random::Random::next_f64)]
micro host_next_f64(random: std.random.Random) -> f64
