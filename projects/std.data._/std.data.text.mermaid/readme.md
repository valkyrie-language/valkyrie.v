# std.data.text.mermaid

mermaid 子集解析库（Valkyrie 实现）：三段式 `mermaid_lex` → `mermaid_parse` → `mermaid_build`。

## 定位

- flowchart 子集：`graph TD/TB` / `flowchart TD/TB` 头；`A[Label] --> B[Label]`、
  `A -->|label| B`、裸节点语句、`%%` 注释；节点 v0 仅矩形（`[...]`）
- sequence 子集：`sequenceDiagram` 头；`A->>B: message`、自消息、`participant X as Label`
- 产物：`MermaidDiagram`（节点/边材料，类型归本包，元素用 `document.plot` 的
  `PlotDecl`/`PlotEdge`）；布局与 SVG 发射归 `document.plot`
- 渲染便捷口：`mermaid_render_svg`（解析 → 布局 → SVG 全链，`DataOutcome` 三态）

## 失败模型

- 非法字符/孤立箭头：`Illegal` token + `mermaid.lex.*`，继续扫描
- 无法归类的语句：`Poison` 挂起 + `mermaid.parse.unexpected_statement`，跳过继续
- 标签未闭合：`Missing` 占位 + `mermaid.parse.unclosed_label`
- 二进制源：`mermaid.lex.binary_source`（Error）+ 空流

## 边界

- 不支持的形态（其余箭头/节点形状、子图、note/alt/loop 等）按未支持处理，不猜测
- 布局归 `document.plot`；本包只做语法映射与便捷编排
