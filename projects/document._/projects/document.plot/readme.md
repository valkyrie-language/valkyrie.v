# document.plot

`document.*` 图场景：节点-边布局 → 矢量文本（SVG）。

## 定位

- 场景模型：节点（身份、标签、几何）与有向边（标签可选）
- flowchart 布局：最长路分层（TB 方向），层内按输入序横排，直边 + 箭头
- sequence 布局：参与者按出现序横排，生命线 + 消息箭头自上而下
- 输出经 `document.vector`：确定性 SVG 文本，同输入同字节

## 边界

- 文本度量是字符单元（`document.layout` 盒模型字体），真实字体度量后接
- flowchart v0：直边、无折线；节点统一矩形；循环图按输入序兜底分层
- sequence v0：普通消息与自消息；不做激活条、不做 note/alt/loop 块
- 不解析任何图方言：解析归 `document.mermaid` 等格式包

## 当前状态

场景模型、两类布局与 SVG 发射已落地；正反测试齐备。
