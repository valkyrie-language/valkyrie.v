# `unicode.normalization`

Unicode 归一化包（NFC / NFD / NFKC / NFKD）。

## 能力边界

- 已提供：本包声明（`namespace! unicode.normalization;`）与 UCD `16.0.0` 版本元数据。
- 未提供：任何归一化公开入口，也不提供部分实现或近似结果。
- `std` 同样不提供 `normalize` / `collate` 一类入口，需要字符串规范化或比较的调用方应自行处理。

归一化是字符身份层面的变换，半截实现会产出错误文本，因此本包只保留包结构，不导出可用入口。

## 未覆盖的能力

- 规范分解映射与兼容分解映射（`UnicodeData.txt` 字段 5）。
- 规范组合类排序（`Canonical_Combining_Class`）。
- 组合排除（`Composition_Exclusion.txt`、`DerivedNormalizationProps.txt`）。
- Hangul 算法分解与合成（U+AC00..U+D7A3）。
- 非 BMP 码点（`char` 为 u16，无法表达）。

## 版本

- 包版本：`0.1.0`（骨架版本）
- UCD 版本：`16.0.0`
- 依赖：`unicode.types`（属性数据底包）

## 边界

- 不做 `collate`（排序规则），不属于归一化。
- 不做大小写折叠（属于 `unicode.case`）。
