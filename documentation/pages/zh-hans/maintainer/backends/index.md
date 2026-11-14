# 后端边界

五个目标家族为 Wasm、CLR、JVM、OVM 和 native。WASI 是 Wasm 的宿主环境，Node-API 与 CPython 扩展是 native 的宿主桥，不另造公共语言 IR。

每个语言拥有自己的语义 IR。语言与目标适配器降低已验证的语言 IR 或 residual 到目标私有计划及 LIR；Nyar 提供可复用变换、分析、优化和专门化工具，不提供强制的统一语言操作集。

目标包装负责承载语言所需运行时机制，并与普通函数走同一 LIR 验证和编码。未静态化的动态语义必须由显式 runtime 合同承载；缺少承载能力时明确拒绝，不猜测语义或产出空实现。

- [Wasm](wasm.md)
- [CLR](clr.md)
- [JVM](jvm.md)
- [OVM / OdinVM](ovm.md)
- [native 与宿主扩展](native.md)

总体架构见 [编译与运行架构](../../developer/architecture.md)。这些页面定义职责，不宣称所有语言与目标组合已经实现。
