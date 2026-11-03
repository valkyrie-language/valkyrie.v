# Browser / portable JS glue：`js.random` capability（非 Node 专有 API）

[when(target.specification == "browser")]
namespace std.adaptor.wasm.random;

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random {
    return std.random.Random::with_seed(__random_js_entropy() as u64)
}

[js("random")]
private micro __random_js_entropy(): i32
