# `unicode.width`

Unicode 显示宽度包（East Asian Width）。

## 状态：未实现，不要调用

本包只有一个 `namespace! unicode.width;` 声明，**不导出任何可用入口**。
`std` 也不提供 `width` 一类入口（`std` 不新增随 UCD 版本漂移的 API）。
终端排版、表格对齐等场合请继续自己处理，不要依赖本包。

## 版本

- 包版本：`0.1.0`（骨架版本）
- UCD 版本：`16.0.0`
- 依赖：`unicode.types`（属性数据底包）

## 缺口账本

| 缺口 | 依据 | 前置条件 |
|:-----|:-----|:---------|
| 宽度分类表 | UAX #11 `EastAsianWidth.txt`（`Na`/`N`/`A`/`W`/`F`/`H`） | `unicode.types` 增属性表 |
| 码点宽度查询（0/1/2） | 同上 | 同上 |
| `A`（Ambiguous）取舍 | 依 locale 变化，本包语义为 locale 无关 | 需要一次显式裁决，本轮不猜 |
| 组合标记宽度 0 | 依赖 `Grapheme_Extend` 类属性 | 与 `unicode.segment` 同源缺口 |
| 非 BMP 码点 | `char` 是 u16，宽度结论只能覆盖 BMP | 先扩展文本表示 |

上述条目全部**未落地**；本包不返回任何默认宽度，以免调用方误信。

## 边界

- 不做终端渲染、不做截断算法；只负责码点宽度数据与查询（本轮均未实现）。
- 表将由脚本生成（`EastAsianWidth.txt`），本包不手抄数据。
