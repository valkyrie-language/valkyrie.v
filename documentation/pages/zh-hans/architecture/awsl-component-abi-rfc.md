# AWSL 組件 ABI 與響應式語義最小擴展

本文说明组件 ABI 语法与接口分工；具体支持能力须由对应修订的组件编译和跨文件校验验证。

## 核心語法

| 用途 | 語法 |
|:---|:---|
| 組件輸入 | `[property] let name;` / `[property] let name = default;` |
| 內部狀態 | `let mut name = expr;` |
| 派生值 | `let name = expr;`（自動重算） |
| 快取派生 | `[memoize] let name = expr;` |
| 輸出事件 | `[event] micro event_name(args...) { }`（必須空 body） |
| 觸發事件 | `emit(event_name, args...)` |
| 副作用 | `effect(deps) { ... }` |
| 模板綁定 | `:snake_case` / `@snake_case` |

## 實作位置

- **语法与组件 ABI 提取**：Oak 对应语言接口；Asgard 消费 `oak_awsl::extract_component_abi_from_script` 与 `ComponentAbiIndex`。
- **组件编译与跨文件校验**：`valkyrie.rs` 的 `projects/compilers/asgard/src/awsl/abi_index.rs`。
- **UI wire 编码接线**：`valkyrie.rs` 的 `projects/compilers/asgard/src/codegen/mobile_ui_binary.rs`。UI wire 产物不证明 Valkyrie 程序语义或通用 backend 合同成立。
- **LSP 诊断适配**：`nyar-vm.rs` 的 `projects/compilers/nyar-language/src/valkyrie/lsp/handlers/awsl/diagnostics.rs`。编辑器适配不另建语义事实源。

## 範例

見 [`Switch.awsl`](../../../../projects/asgard._/projects/asgard.ui.core/source/components/Switch.awsl)。

## 遷移

- `emit("name", payload)` → 宣告 `[event] micro name(...) { }` + `emit(name, ...)`
- 隱式 prop `let x = default` → `[property] let x = default`
- camelCase → snake_case
