# Valkyrie frontend 工作流

本文只描述 Valkyrie frontend 与 Nyar 框架之间的责任边界。工程装配由 Legion 负责，源码 parser 和 formatter 由 Oak 负责。

## 正式编译流

```text
WorkspaceResolver
    → immutable source inventory + package graph
    → Valkyrie Compiler
        → Oak recovery/diagnostics
        → declaration binding + instance/evidence demand fixed point
        → demanded HIR bodies
        → package Semantic MIR
        → linker / Canonical validation
        → RepresentationPlan
        → BackendPrivatePlan
    → artifact / execution evidence
```

Compiler 是唯一语义入口。它不接受工具层注入的 AST、HIR、MIR、选择结果或 `body_source` 重解析，不在缺事实时按名称、默认值或目标补语义。

## 各层职责

Oak 负责 lexer、parser、CST/AST、语法恢复和 syntax diagnostics。源码 formatter 使用 lossless CST、token/trivia 和 gap 约束生成 edits。Oak 不负责名称、类型、调用、可写性或编译准入。

Valkyrie frontend 负责可见声明绑定、类型、泛型替换、trait/imply evidence、调用、语义需求固定点、HIR 和 package Semantic MIR。AST 的 unary/binary 语法在 HIR 展开为普通 callable，后续调用统一为 `Invoke`。

Nyar 负责通用 IR、验证、优化、表示规划和 backend lowering framework。linker 选择 target-conditioned adaptor/import，Representation Planner 选择稳定 ID keyed 的表示，backend 只编码 `BackendPrivatePlan`。

Legion 负责 manifests、package graph、缓存、ArtifactStore 和执行编排。它不能重新实现 parser、resolver、HIR/MIR 或 semantic closure。

## 诊断与准入

Frontend 必须同时传递可用树、recovery/missing/error 状态和 diagnostics。不可达坏 body 可以保留在 inventory/index 中，但不得进入成功 Semantic MIR。可达错误必须在所属语义阶段结构化失败。各阶段保留自己的 code、owner、source/span，不能统一包装成 parser error。

PP document 是 AST/IR/值模型的文本打印，不是源码 formatter。Nyar 或工具层可以调用 Oak formatter，但不能用 PP 输出覆盖源码。

## 验收

验收同时覆盖可达与不可达坏 body、同名不同 owner/namespace、未声明依赖、跨包成员、泛型实例和 evidence。局部测试或单个报错消失不代表 Compiler contract 或 LeetCode 双 target 交付完成。
