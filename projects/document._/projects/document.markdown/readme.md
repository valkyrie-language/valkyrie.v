# document.markdown

`document.*` markdown 子集：markdown 源文本 → `document` 模型 → HTML（内嵌 mermaid 图与 TeX 公式）。

## 定位

- markdown 子集解析：`#` 标题、段落、`**`/`*`/`` ` `` 样式、`[text](target)` 链接、
  `[^key]` 脚注引用与定义、`-` 列表、pipe 表格、fenced 代码块、`---` 分隔线
- 扩展面（走模型的开放扩展位，不改核心合同）：
  - ` ```mermaid ` 代码块 → `document.mermaid` 解析 → `document.plot` 布局 → SVG 内联
  - 行内 `$...$` / 块级 `$$...$$` → `vutex` → SVG 内联（`<span class='math'>` / `<div class='math'>`）
- 失败模型：`std.data` `DataOutcome<utf8>` 三态——渲染硬失败为 `Failed`；
  mermaid/公式解析失败降级为源码展示并记 `Diagnostic`（`Partial`），不 panic

## 边界

- 标准块/行内的 HTML 发射委托 `document.render`；本包只做子集解析与两处产品侧扩展点
- 未闭合的行内标记按字面量文本处理（markdown 语义），不记诊断
- 嵌套样式内的数学片段不拦截（v0）

## 当前状态

子集解析、编排发射与失败降级已落地；端到端 fixture 正反测试齐备。
