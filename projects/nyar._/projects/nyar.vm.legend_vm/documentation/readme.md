# LegendVM

LegendVM 提供 guest 解释、部分求值和专门化支撑。Python、Lua、TypeScript、Valkyrie 等语言包各自拥有解释器及语义，LegendVM 不集中实现各语言 AST tree walk。

Futamura 第一投影为 `S(I_L, P) = R_L,P`：固定语言解释器和程序，生成仍接收未知运行输入的 residual。动态对象、查找、反射、异常和宿主效果依照语言合同留在 residual/runtime。专门化必须保持可观察行为，guard、失效与回退不得隐式改变语义。

残余程序通过语言与目标适配器进入 Wasm、CLR、JVM、OVM 或 native 的私有计划和 LIR。只有 OVM 产物是 `.odin` 并进入 OdinVM。LegendVM 不取代目标后端、对象文件链接或 OdinVM 的加载执行职责。

本文规定职责，不宣称全部语言、目标或 Futamura 第二、第三投影已实现。
