# `unicode.segment`

Unicode 文本分段包（字素簇 / 词 / 句边界）。

## 能力边界

- 已提供：本包声明（`namespace! unicode.segment;`）与 UCD `16.0.0` 版本元数据。
- 未提供：任何分段公开入口，也不提供近似结果。
- `std` 不提供 `segment` 一类入口，需要分段能力的调用方应自行处理。

## 未覆盖的能力

- 字素簇边界（`Grapheme_Cluster_Break`、`Extended_Pictographic`、U+200D 规则）。
- 词边界（`Word_Break`，含 `Case_Ignorable` 交互）。
- 句边界（`Sentence_Break`）。
- 非 BMP 码点（`char` 为 u16，emoji 扩展等无法表达）。

## 版本

- 包版本：`0.1.0`（骨架版本）
- UCD 版本：`16.0.0`
- 依赖：`unicode.types`（属性数据底包）

## 边界

- 不做语言相关分词（泰语/日语词典分词不属于 UCD 范围）。
- 表由脚本生成（与 `unicode.types` 同一数据源），本包不手抄数据。
