# Valkyrie 编译流程

本文只定义 Valkyrie 语言的阶段职责。多语言及两类 VM 的总体关系见 [编译与运行架构](../developer/architecture.md)。

Legion 将已解析的工程、依赖和逐文件输入交给 Compiler。Valkyrie 前端完成名称绑定、类型、place、泛型实例、trait evidence 和 effect/handler 语义，生成 Valkyrie HIR/MIR。跨包链接确定声明身份、adaptor 和 import signature，语言验证器检查字段与变体 owner、调用、完整实例和控制流事实。

Valkyrie MIR 可以保留本语言所需的复杂控制流；历史 `Canonical MIR` 不代表 Nyar 公共 IR。共享 Nyar 工具通过协议操作语言拥有的模型，语言负责优化合法性。

语言与目标适配器消费已验证的语言事实或 residual，选择目标表示、运行时合同和包装，产出该目标私有计划及 LIR。表示侧表不复制语言 CFG，不重做绑定。目标验证后，普通及合成函数经同一 LIR 编码器进入产物。

Wasm、CLR、JVM、native 直接生成各自目标产物；OVM 生成 `.odin` 交由 OdinVM。Acorn 负责适用的外部格式。ArtifactStore 原子提交完整产物及证据。

缺少类型、调用、布局、导入或 runtime 能力时，由事实所属阶段明确拒绝。语言允许的动态行为可以通过经过声明和验证的 residual/runtime 承载，不得靠默认值、名称猜测或直接发射修补缺口。Valkyrie 编译环境不接受顶级可变变量；REPL 的时序环境与单例生命周期不构成全局可变初始化机制。
