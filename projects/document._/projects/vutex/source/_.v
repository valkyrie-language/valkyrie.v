namespace vutex;

# vutex — 文档排版与数学排版内核（Valkyrie 实现）。
#
# 职责：数学 AST（`MathNode`）→ `document.layout` 盒树 → `document.vector`
# SVG 矢量文本。TeX 源文本解析归 `std.data.text.tex`，本包不含解析器。
#
# v0 边界（如实记录）：
# - 度量是字符单元（等宽假设），真实字体度量经 provider 接入后替换。
# - 联合上下标（同基点 `^{}_{}`/`_{}^{}`）的列基线取下标行，上标随列上移，
#   与全功能排版的精对位有偏差；单独上标/下标是精确的。
# - 分式分子分母在分式宽内居中（glue 填充），根号是 `√` 加顶线的近似形态。
