# 依赖规则

依赖边按事实所有者划分。当前源码位置、包名与长期职责分别判断，不用目录搬迁或改名掩盖重复事实源。

## 所有权方向

- Oak 负责 lexer/parser、CST/AST、恢复诊断及源码 formatter。
- Valkyrie frontend 负责规范语义、绑定、类型、实例/evidence 需求、HIR 和 Semantic MIR。
- Nyar 负责通用验证、优化、表示及 backend lowering framework。
- Acorn 负责外部二进制格式；nyar-bytecode 负责 Nyar 字节码。
- Legion 负责工程 graph、逐文件输入、Compiler 调用、cache 与 ArtifactStore。
- core/std 定义语言基础与库行为，adaptor 定义目标实现，由 linker 选择。

Frontend 可以依赖 Oak 与 Nyar；Nyar 可依赖 Acorn；通用框架不能反向依赖 Legion 或 Valkyrie 装配实现。VM 只消费产物，不依赖 AST 或语言 frontend。

## 编译与工具

外部只有 WorkspaceResolver、Compiler、ArtifactStore。Legion 不直接调用 frontend、语义闭包 planner 或 HIR/MIR，不注入语义选择结果。Compiler 不访问工程文件系统。

绑定、实例需求与 HIR 物化在 Compiler 内协作到固定点，共用 package visibility；不存在工具层先选语义闭包、Compiler 再建立另一套绑定的协议。

linker 绑定 adaptor/import；表示规划只选布局；backend 只编码已验证 BackendPrivatePlan。禁止用 carrier、名称或目标特判弥补语义缺口。

源码 formatter 只调用 Oak CST/token-gap；PP 是模型打印。Lint 消费恢复树或语义事实，不拥有第二套语言准入；工程 check/LSP 共享同一工程输入。

## 删除与验收

迁移消费者后删除依赖与实现，证明旧生产入口不可达，不保留兼容 wrapper。成对验证可达/不可达、可见/不可见、正确/错误 owner 及泛型实例；文本扫描只辅助，不替代合同和真实执行证据。

架构总览见 [architecture.md](architecture.md)，编译阶段见 [compilation.md](../maintainer/compilation.md)。
