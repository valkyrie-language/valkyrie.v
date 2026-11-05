# `unicode.normalization`

Unicode 归一化包（NFC / NFD / NFKC / NFKD）。

## 状态：未实现，不要调用

本包只有一个 `namespace! unicode.normalization;` 声明，**不导出任何可用入口**。
`std` 也不提供 `normalize`/`collate` 一类入口（`std` 不新增随 UCD 版本漂移的 API）。
需要字符串比较或规范化的调用方请继续用自己的逻辑，不要依赖本包。

## 版本

- 包版本：`0.1.0`（骨架版本）
- UCD 版本：`16.0.0`
- 依赖：`unicode.types`（属性数据底包）

## 缺口账本

| 缺口 | 依据 | 前置条件 |
|:-----|:-----|:---------|
| 规范分解映射 | `UnicodeData.txt` 字段 5 | `unicode.types` 增数据表 |
| 兼容分解映射 | 同上（`<compat>` 标记） | 同上 |
| 组合类排序 | `UnicodeData.txt` 字段 3（`Canonical_Combining_Class`）+ 稳定排序 | 同上 |
| 组合排除 | `Composition_Exclusion.txt`、`DerivedNormalizationProps.txt` | 同上 |
| Hangul 算法分解/合成 | U+AC00..U+D7A3 算术规则 | 无需数据表，但需实现 |
| 非 BMP 码点 | 分解结果可能超出 u16 `char` | 先扩展文本表示 |

上述条目全部**未落地**。归一化是字符身份层面的变换，半截实现会静默产出错误文本，
因此本包**不提供部分实现**，也不提供「尽力而为」的近似入口。

## 边界

- 不做 `collate`（排序规则），不属于归一化。
- 不做大小写折叠（属于 `unicode.case`）。
