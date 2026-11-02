# document._ 文档处理与渲染框架 workspace

`document._` 以 `document.*` 核心为唯一事实底座：文档树、元数据、引用系统、资源、布局与渲染管线。
产品级（notedown / panduck / pandark / vutex）只做"解析进模型"一端，不各自造树、不各自渲染。

## 设计文档

- [`document.*` 核心合同](./core-contract.md)：核心模型类型与不变量、引用求解规则、布局/渲染边界、失败模型
- [conformance 用例表](./conformance-matrix.md)：内存构造树 → HTML/纯文本的结构断言矩阵
- [notedown 迁移映射](./notedown-migration.md)：`source/ir/` → 核心模型的逐项映射与方言归属

## 分层

- **核心**：`document`（模型/引用/资源/失败类型）、`document.layout`（页面/测量/断页）、`document.render`（管线/HTML/纯文本）
- **格式**：`std.data.text.*`（含 `std.data.text.dejavu` 的 notedown 方言）按三段 trait 产 token/CST/AST
- **产品**：notedown（markdown/notedown 方言 → 模型）、panduck（转换编排）、pandark/vutex（消费侧）

## 边界约束

- 核心三包不依赖任何产品包；产品包只把解析产物映射进核心模型
- 核心不做 IO（文件/网络/字体读取归消费侧 host capability）
- 解析侧失败走 `std.data` 错误容许三态；布局/渲染侧硬失败走结构化错误通道
