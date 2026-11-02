# document.vector

`document.*` 矢量文本发射：确定性 SVG 原语（纯函数，无 DOM、无 IO）。

## 定位

- 消费方：`vutex` 数学排版、`document.plot` 图布局，以及任何需要矢量文本输出的层
- 输出合同：同输入同字节；属性顺序固定（几何在前、样式随后）；元素内不写多余空白
- 属性拼写一律单引号：SVG/XML 双引号与单引号等价，单引号让源文件不含转义引号

## 边界

- 不拥有布局与度量：归 `document.layout` 盒模型 / 消费方
- 不拥有文档树语义：归 `document`
- 不做浏览器/DOM 集成：输出是纯文本，注入归下游

## 当前状态

SVG 原语（text/rect/line/path/circle/group/document）与文本、属性转义已落地。
