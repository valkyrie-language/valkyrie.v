# WASI Preview 3：无 [js] / [wasm]；正式 component binding 由 backend 消费（待实现）。

[when(target.specification == "wasip3")]
namespace std.adaptor.wasi.random;

[host_provider(std::random::Random::new)]
micro host_new() -> std.random.Random
