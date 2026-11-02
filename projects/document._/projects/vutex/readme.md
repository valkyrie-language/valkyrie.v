# vutex

文档排版与数学排版内核（Valkyrie 实现）。

## 定位

- 数学 AST（`MathNode`）与盒排版：分式、根式、上下标、希腊字母、运算符
- 链路：数学 AST → `document.layout` 盒树 → `document.vector` SVG 矢量文本
- 输出确定：同输入同字节
- TeX 源文本解析归 `std.data.text.tex`（本包不含解析器）

## 边界

- 度量是字符单元（等宽假设），真实字体度量经 provider 接入后替换
- 联合上下标的列基线取下标行（v0 近似）；单独上标/下标精确
- HTML 渲染走 asgard/ssg 路径，不在本包自造 HTML 渲染器

## 当前状态

盒排版与 SVG 发射已落地；构造器直驱的快照测试齐备。
