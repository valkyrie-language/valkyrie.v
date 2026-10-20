# Wasm 后端

Wasm 编码与 Node、浏览器、WASI 宿主能力分开。具体 target/profile 的支持以实际构建和调用证据为准。

## 输入合同

```text
Canonical + RepresentationPlan → Wasm BackendPrivatePlan
  → pre-encode validation → format encoding
  → Wasm artifact + signature-driven glue
```

linker 绑定 adaptor/import signature；表示规划绑定 GC/FFI carrier 与 layout。backend 只编码私有计划，不按 host field 名猜 ABI、按 callee 尾名决定行为或默认补宿主导入。

Wasm typeidx、local、table 和 rec-group 属于 backend。语言类型、完整实例、text 语义、字段与变体身份不能从这些编号或物理表示反推。JS UTF-16 存储不能替代语言文本索引合同；null 载荷不自动变为整数零。

## 验收

所有编码入口统一验证 callable、签名、carrier、layout 与 payload，缺事实结构化失败。有效 Wasm 还须验证本次 artifact digest、非空 export、真实 invoke、签名驱动参数/返回值及全部题意用例。wrapper 启动或单个 smoke 不证明交付。
