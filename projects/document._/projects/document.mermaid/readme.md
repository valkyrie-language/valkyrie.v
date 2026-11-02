# document.mermaid

`document.*` mermaid 子集解析：mermaid 源文本 → `document.plot` 图场景 → SVG 矢量文本。

## 定位

- flowchart 子集：`graph TD/TB` / `flowchart TD/TB` 头；`A[Label] --> B[Label]`、
  `A -->|label| B`、裸节点语句、`%%` 注释；节点 v0 仅矩形（`[...]`）
- sequence 子集：`sequenceDiagram` 头；`A->>B: message`、自消息、`participant X as Label`
- 管线：解析 → `document.plot` 布局 → SVG；畸形或不支持的语法返回 `None`，不产占位树

## 边界

- 不支持的形态（其余箭头/节点形状、子图、note/alt/loop 等）按未支持处理，不猜测
- 布局与发射归 `document.plot`；本包只做语法映射

## 当前状态

两类子集解析与渲染管线已落地；正反测试齐备。
