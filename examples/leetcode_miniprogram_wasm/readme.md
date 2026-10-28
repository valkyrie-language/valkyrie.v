# leetcode_miniprogram_wasm

微信小程序 Wasm 题解样板：`wasm32-unknown-miniprogram-wasm`，publish `mini-program`。

与 `leetcode_browser_wasm` 相同，只依赖 `std` 契约；Legion 注入 `std.adaptor.wasm`，由 `when(target.vendor == "wechat")` 激活 `Random.wechat.v`、`fetch.wechat.v` 等变体文件。
