# `std.adaptor.wasm`

Valkyrie WebAssembly 宿主 SDK — 浏览器 / 微信两套 provider 位于同一 package、同一 namespace，由文件级 `[when(...)]` 条件在链接期分流；中性 wasm 不选任何宿主 provider。

## 📋 目标三元组

| 目标三元组                 | 含义                                   | 选中的 provider                     |
|:---------------------------|:---------------------------------------|:------------------------------------|
| `wasm32-unknown-unknown-wasm` | 中性 WASM，不声明任何宿主             | 无（仅 backend 能力空间）           |
| `wasm32-unknown-browser-wasm` | 浏览器宿主（DOM / Web API）           | `fetch.browser.v`、`Random.browser.v` |
| `wasm32-wechat-unknown-wasm`  | 微信宿主（小程序 / 小游戏，`vendor = wechat`） | `fetch.wechat.v`、`Random.wechat.v` |

> **条件语义**：browser 用 `[when(target.specification == "browser")]`，WeChat 用 `[when(target.vendor == "wechat")]`；两者互斥，`vendor = wechat` 不会匹配 `specification = browser`，反之亦然。

### 分流规则

| 条件                                   | 生效文件                                  | 说明                         |
|:---------------------------------------|:------------------------------------------|:-----------------------------|
| `target.specification == "browser"`    | `fetch.browser.v`、`Random.browser.v`     | `fetch` / `random` JS glue   |
| `target.vendor == "wechat"`            | `fetch.wechat.v`、`Random.wechat.v`       | `wx.request` / `random` glue |
| 中性 `wasm32-unknown-unknown-wasm`     | 仅无条件的公共绑定                        | 无宿主 provider              |

## 📦 包内容

```
std.adaptor.wasm/
├── legion.von          # 包清单（build: wasm / browser / wechat）
└── source/
    ├── console/_.v           # Console API（对齐 std.console）
    ├── crypto/hash.v         # Crypto API（对齐 std.crypto）
    ├── dom.v                 # DOM API（平台专有）
    ├── fetch.v               # fetch / Response / Headers 公共绑定
    ├── fetch.browser.v       # browser `std::net::get|post|put|delete`
    ├── fetch.wechat.v        # wechat `std::net::get`（`wx.request`）
    ├── json.v                # JSON API（平台专有）
    ├── math/basic.v          # Math API（对齐 std.math.basic）
    ├── math/random/Random.v          # 共享 namespace
    ├── math/random/Random.browser.v  # browser random provider
    ├── math/random/Random.wechat.v   # wechat random provider
    ├── io/{fs,print,time}.v  # IO provider（对齐 std.io）
    ├── text/Utf{8,16}Text.v  # 文本 provider（对齐 std.text）
    ├── performance.v         # Performance API（平台专有）
    ├── storage.v             # Storage API（平台专有）
    ├── timer.v               # Timer API（平台专有）
    └── url.v                 # URL API（平台专有）
```

## 🔧 绑定概览

| 文件                     | 绑定类型                                            | 副作用    | 覆盖 API                        |
|:-------------------------|:----------------------------------------------------|:----------|:--------------------------------|
| `console/_.v`            | `[js_builtin("console.*")]`                         | ✅ 有     | 日志、分组、计时                |
| `crypto/hash.v`          | `[js_builtin("crypto.*")]`                          | ✅ 有     | 随机值、UUID                    |
| `dom.v`                  | `[js_builtin("document.*"/"Element.*")]`            | ✅ 有     | 元素查询/创建/操作/样式/树/事件 |
| `fetch.v`                | `[js_builtin("fetch"/"Response.*")]`                | ✅ 有     | HTTP 请求/响应/Headers          |
| `fetch.wechat.v`         | `[js_builtin("wx.request")]`                         | ✅ 有     | 微信 `std::net::get`            |
| `json.v`                 | `[js_builtin("JSON.*"), pure]`                      | ❌ 纯函数 | 解析/序列化                     |
| `math/basic.v`           | `[js_builtin("Math.*"), pure]`                      | ❌ 纯函数 | 常量/取整/极值/幂根/对数/三角   |
| `performance.v`          | `[js_builtin("performance.*")]`                     | 混合      | 时间戳（纯）/ 标记（副作用）    |
| `storage.v`              | `[js_builtin("localStorage.*"/"sessionStorage.*")]` | ✅ 有     | 本地/会话存储 CRUD              |
| `timer.v`                | `[js_builtin("setTimeout"/"raf")]`                  | ✅ 有     | 定时器/动画帧/微任务            |
| `url.v`                  | `[js_builtin("URL*")]`                              | 混合      | URL 解析/URLSearchParams        |

### 绑定类型说明

- **`[js_builtin]`**：直接映射 JS 内置全局对象，按目标宿主生成 JS glue 调用
- **`[wasi]`**：绑定 WASI 系统调用，由 `std.adaptor.wasi` 承接

### 注解说明

本 SDK 使用以下注解（完整 FFI 注解体系参见 [attributes.md](../../documentation/language/attributes.md)）：

| 注解                   | 语义                                            |
|:-----------------------|:------------------------------------------------|
| `[js_builtin("path")]` | 直接映射 JS 内置全局对象，按目标宿主生成 JS glue |
| `[when(...)]`          | 文件级 target 条件，决定 provider 是否参与链接   |
| `[wasi]`               | 绑定 WASI 系统调用                              |

### 纯函数标注

标注 `pure` 的函数可被编译器优化（DCE、常量折叠、公共子表达式消除）。

## 🎯 使用场景

- 🎮 Web 游戏发布（`wasm32-unknown-browser-wasm`）
- 🌍 Web 应用开发（SPA、PWA）
- 💬 微信小程序 / 小游戏（`wasm32-wechat-unknown-wasm`）
- 🧩 中性 WASM 库（`wasm32-unknown-unknown-wasm`，无宿主 provider）

## ⚙️ 编译命令

```bash
# 编译为浏览器 WASM
vcc build --target browser

# 编译为微信宿主 WASM
vcc build --target wechat

# 编译为中性 WASM（不选宿主 provider）
vcc build --target wasm
```

## 📌 状态

✅ 浏览器 / 微信双宿主绑定已覆盖主要 Web API。 🚧 `WASI Component Model` 侧能力由 `std.adaptor.wasi` 独立承接。
