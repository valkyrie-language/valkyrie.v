# `unicode.width`

Unicode 显示宽度包（East Asian Width）。

## 能力边界

- 已提供：本包声明（`namespace! unicode.width;`）与 UCD `16.0.0` 版本元数据。
- 未提供：任何宽度查询公开入口，也不返回默认宽度。
- `std` 不提供 `width` 一类入口，终端排版、表格对齐等场合应自行处理。

## 未覆盖的能力

- 宽度分类表（`EastAsianWidth.txt` 的 `Na`/`N`/`A`/`W`/`F`/`H`）。
- 码点宽度（0/1/2）查询。
- `A`（Ambiguous）分类：语义依赖 locale，本包若提供会固定为 locale 无关口径。
- 组合标记宽度 0（依赖 `Grapheme_Extend` 类属性）。
- 非 BMP 码点（`char` 为 u16，宽度结论只能覆盖 BMP）。

## 版本

- 包版本：`0.1.0`（骨架版本）
- UCD 版本：`16.0.0`
- 依赖：`unicode.types`（属性数据底包）

## 边界

- 不做终端渲染、不做截断算法；只负责码点宽度数据与查询。
- 表由脚本生成（`EastAsianWidth.txt`），本包不手抄数据。
