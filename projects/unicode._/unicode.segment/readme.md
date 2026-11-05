# `unicode.segment`

Unicode 文本分段包（字素簇 / 词 / 句边界）。

## 状态：未实现，不要调用

本包只有一个 `namespace! unicode.segment;` 声明，**不导出任何可用入口**。
`std` 也不提供 `segment` 一类入口（`std` 不新增随 UCD 版本漂移的 API）。
需要分段能力的调用方请继续用自己的逻辑，不要依赖本包。

## 版本

- 包版本：`0.1.0`（骨架版本）
- UCD 版本：`16.0.0`
- 依赖：`unicode.types`（属性数据底包）

## 缺口账本

| 缺口 | 依据 | 前置条件 |
|:-----|:-----|:---------|
| 字素簇边界 | UAX #29 `Grapheme_Cluster_Break`、`Extended_Pictographic`、U+200D 规则 | `unicode.types` 增属性表 |
| 词边界 | UAX #29 `Word_Break`（WB3c/WB4/WB6/WB7 与 `Case_Ignorable` 交互） | 同上 |
| 句边界 | UAX #29 `Sentence_Break` | 同上 |
| 非 BMP 码点 | 本语言 `char` 是 u16，emoji 扩展等无法表达 | 先扩展文本表示 |

上述条目全部**未落地**；本包不提供任何近似结果，以免调用方误信。

## 边界

- 不做语言相关分词（泰语/日语词典分词不属于 UCD 范围）。
- 表将由脚本生成（与 `unicode.types` 同一数据源），本包不手抄数据。
