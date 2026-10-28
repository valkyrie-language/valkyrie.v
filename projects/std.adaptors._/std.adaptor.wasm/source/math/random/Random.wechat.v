# 微信小程序 wasm：`js.random`（与 browser 同 glue 名，经 capability 与 `when` 分流）

[when(target.vendor == "wechat")]
namespace std.adaptor.wasm.math.random;

[host_provider(std::math::random::Random::new)]
[js("random")]
micro host_new() -> std.math.random.Random

[host_provider(std::math::random::Random::with_seed)]
[js("random")]
micro host_with_seed(seed: i32) -> std.math.random.Random

[host_provider(std::math::random::Random::next_i32)]
[js("random")]
micro host_next_i32(random: std.math.random.Random, max_exclusive: i32) -> i32

[host_provider(std::math::random::Random::next_f64)]
[js("random")]
micro host_next_f64(random: std.math.random.Random) -> f64
