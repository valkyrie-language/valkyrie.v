# 语言接入合同

Valkyrie、TypeScript、Python、Lua 各自拥有语义、IR、解释器和诊断。Valkyrie MIR 及其复杂控制流验证属于 Valkyrie，不要求其他语言生成它。历史 `Canonical MIR` 不是 Nyar 公共语义；`SharedSemanticSubset(CompiledProgram)` 也不能充当唯一公共入口。

Nyar 提供变换、分析、优化、部分求值和残余化工具。语言按需要实现遍历、图、代数或专门化协议，自己确定操作含义和优化合法性。OA 不替代 IR，EGraph 不取消阶段验证，PE 不取消目标 lowering。

静态编译路线由语言前端生成已验证的本语言 IR，经语言与目标适配器进入目标私有计划及 LIR。每个适配器拥有语言语义到目标包装及 runtime 的映射；目标编码器不反向识别语言 AST。

动态路线由语言包实现解释器 `I_L`。第一投影 `S(I_L, P) = R_L,P` 固定程序而保留未知运行输入。LegendVM 提供解释与专门化支撑；语言包负责 Python、Lua 等动态语义，不把各语言 tree walk 集中到 LegendVM。无法静态化的行为保留在 residual/runtime，编译期不得执行并删除可观察效果。

Wasm、CLR、JVM、OVM、native 各自拥有私有计划、LIR 和包装。OVM 产出 `.odin` 由 OdinVM 执行；其他目标不绕行 `.odin`。普通函数与合成函数共用目标 LIR 编码路径。native 的 Node-API 和 CPython 桥分别定义注册、值、错误、资源及线程合同。

上述为接入合同，不代表所有语言、目标或 Futamura 第二、第三投影已经交付。每个语言包必须单独说明真实实现范围和缺失能力。
