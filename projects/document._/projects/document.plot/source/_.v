namespace document.plot;

# document.plot — 图场景：节点-边布局 → 矢量文本。
#
# 本包不知道任何图方言（解析归 `document.mermaid` 等），只消费
# 节点/边声明，产出确定性 SVG 文本。文本度量走 `document.layout`
# 盒模型字体（字符单元，等宽假设）。
