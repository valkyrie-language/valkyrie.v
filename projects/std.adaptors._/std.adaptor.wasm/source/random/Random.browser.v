# Browser / portable JS glue：`js.random` capability（非 Node 专有 API）

[when(target.specification == "browser")]
namespace std.adaptor.wasm.random;

[host_provider(std::random::Random::new)]
[js("random")]
micro host_new() -> std.random.Random

[host_provider(std::random::Random::with_seed)]
[js("random")]
micro host_with_seed(seed: i32) -> std.random.Random

[host_provider(std::random::Random::next_i32)]
[js("random")]
micro host_next_i32(random: std.random.Random, max_exclusive: i32) -> i32

[host_provider(std::random::Random::next_f64)]
[js("random")]
micro host_next_f64(random: std.random.Random) -> f64
