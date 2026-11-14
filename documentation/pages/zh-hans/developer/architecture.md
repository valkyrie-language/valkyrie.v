# 编译与运行架构

Valkyrie、TypeScript、Python、Lua 各自拥有语言语义、诊断和 IR。Valkyrie 的复杂控制流 MIR 属于 Valkyrie；它不是其他语言接入 Nyar 的前提。历史名称 `Canonical MIR` 及其程序、操作和语义验证模型应归还 Valkyrie，不能作为 Nyar 的公共语言模型。

## 语言与共享工具

静态路线由语言前端完成绑定、类型、控制流及效果建模，产出本语言已验证的 IR，再由语言与目标之间的适配器降低到目标私有计划和 LIR。

Nyar 提供可复用的变换、分析、优化、部分求值和残余化工具。共享遍历协议、图算法和优化机制不要求共享语言操作枚举。语言定义优化合法性及可观察行为，目标定义物理表示和指令合法性。OA、EGraph 和 PE 可以组合使用，不能分别取代语言 IR、全部阶段或目标 lowering。

## 动态语言与 LegendVM

Python、Lua 和动态 TypeScript 由语言包拥有解释器 `I_L`，程序为 `P`。Futamura 第一投影为 `S(I_L, P) = R_L,P`：专门化器固定程序，生成仍接收未知运行输入的残余程序。LegendVM 提供 guest 解释、专门化和运行支撑，不集中实现各语言的 AST tree walk。

动态对象、查找、异常、反射和运行输入等未能证明静态化的语义必须留在 residual 或对应语言 runtime。guard、失效及回退必须有语言语义依据，不能吞掉动态行为。编译期执行不得替代 I/O、时间或其他可观察效果。此合同不代表这些语言或 Futamura 第二、第三投影已经实现。

## 五类目标与 OdinVM

Wasm、CLR、JVM、OVM、native 各自拥有目标计划、包装和 LIR。普通函数、合成包装、闭包桥与 runtime helper 经同一目标 LIR 验证和编码，不允许直接拼字节的旁路。Acorn 承担适用的外部二进制格式能力，不负责语言语义。

OVM 产出 `.odin`。OdinVM 拥有模块加载、验证、执行帧、VM 对象、GC 和可选 JIT。其他目标直接进入自己的产物链，不经 `.odin`。LegendVM 与 OdinVM 的职责不同，不能合并成一个万能执行器。

native 先确定 ISA、ABI、目标文件与链接合同。`.node` 是 Node-API bridge 与 native 链接产物；`.pyd` 或扩展 `.so` 是 CPython bridge 与 native 链接产物。两者分别定义注册、值转换、异常、资源所有权和线程规则，不能只替换动态库后缀。

## 工程与支持证据

Oak 拥有语法处理；Valkyrie 编译器拥有语言事实；Legion 拥有工程输入、缓存和产物装配。Compiler 不由后端或 runtime 回调以补事实。标准库表达语言通用能力，产品概念留在产品包。

架构合同与当前实现分别判断。源码目录、计划对象或局部 smoke 均不能证明某个语言与目标组合可用；必须核验对应提交的真实编译、产物验证、加载和调用。

Valkyrie 阶段约束见 [编译流程](../maintainer/compilation.md)，目标边界见 [目标家族契约](../maintainer/target-family-contract.md)。
