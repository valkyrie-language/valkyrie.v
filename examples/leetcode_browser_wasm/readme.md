# leetcode_browser_wasm

Browser Wasm 题解样板：`legion build` 目标为 `wasm32-unknown-browser-wasm`，publish `web-app`。

- 源码只引用 `std` 契约（如 `std.math.random.Random`）。
- Legion 按 target 选择 `std.adaptor.wasm`（browser JS glue）；`Random.browser.v` 经文件级 `when` 提供 `js.random`。WASI 使用独立包 `std.adaptor.wasi`，不进入本示例。
- 构建后查看 `compile-evidence.txt` / API `host_required_capabilities` 核对物化能力集。

**rusty-valkyrie 门禁**（无需全量 `legion build` 语料树）：在 `victory 胜利女神` 仓库根目录执行：

```bash
node scripts/valkyrie/host-capability-smoke.mjs
```

`valkyrie.v` 自带 CI 的 `legion` 来自 NyarVM.cs，能力模型合入后需升级 CLI 再在此处加 `legion build examples/leetcode_browser_wasm` 硬门禁。
