# Browser / portable JS glue：`js.random` capability（非 Node 专有 API）
# 文件级 `when`（Oak 暂用键值实参；`target.specification == "…"` 待前端 attribute 解析 `==` 后切换）

[when(target.vendor == "browser")]
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
