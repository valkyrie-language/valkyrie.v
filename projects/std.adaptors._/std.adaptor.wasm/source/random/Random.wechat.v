# 微信小程序 wasm：`js.random`（与 browser 同 glue 名，经 capability 与 `when` 分流）

[when(target.vendor == "wechat")]
namespace std.adaptor.wasm.random;

[host_provider(std::random::entropy)]
micro host_entropy() -> u64 {
    return __random_js_entropy() as u64
}

[js("random")]
private micro __random_js_entropy(): i32
