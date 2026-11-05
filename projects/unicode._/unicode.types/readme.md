# `unicode.types`

Unicode 码点属性**数据**底包（纯数据，无宿主绑定，locale 无关）。

## 版本

- 包版本：`0.1.0`
- UCD 版本：`16.0.0`
- std 依赖固定版本的 `unicode.types`；升级 Unicode 即升本包版本，std 语义不随之漂移。

## 当前能力

| 属性             | UCD 来源                 | 数据 |
|:-----------------|:-------------------------|:-----|
| `White_Space`    | `PropList.txt`           | `unicode_white_space_ranges()`：10 段 / 25 个码点 |
| `Cased`          | `DerivedCoreProperties.txt` | `unicode_cased_ranges()`：117 段 |
| `Case_Ignorable` | `DerivedCoreProperties.txt` | `unicode_case_ignorable_ranges()`：335 段 |

后两项供 `unicode.case` 的 Final_Sigma 上下文判定使用；本包只提供数据，不做判定。

## 为什么这里只有数据

包依赖方向是 `std → unicode.*`（`std` 依赖本包，本包不依赖 `std`）。
本语言的操作符、数组方法都在 `std` 内，底包不能使用它们，因此这里只提供
码点属性**数据**；查表算法留在调用方（`std::text::Utf8Text::is_whitespace_code_point`）。
这也正是底包的意义：数据随 UCD 升版，算法与公开 API 留在 `std` 保持稳定。

## 边界

- 只覆盖 BMP。本语言 `char` 是 u16，非 BMP 码点无法用 `char` 表示；
  `White_Space` 全部位于 BMP，因此本属性无截断缺口。
- 不做语言/区域相关判定，只做 UCD 属性数据。
- 表由脚本生成，不手改。

## 再生成

```powershell
node scripts/gen-unicode-types.mjs    # White_Space
node scripts/gen-unicode-case.mjs     # Cased / Case_Ignorable（与 unicode.case 同一次生成）
```

脚本默认从 `https://www.unicode.org/Public/16.0.0/ucd/` 下载数据到
`.cache/unicode/16.0.0`（已存在则复用），并把输入 SHA-256 写入生成文件头。
