# `unicode.case`

Unicode 大小写映射包，依赖 `std`（文本类型与构造器）与 `unicode.types`。

## 版本

- 包版本：`0.1.0`
- UCD 版本：`16.0.0`
- 语义：Unicode **默认全映射**、**locale 无关**（不做土耳其语 `I→ı`）。
- 升级 Unicode 即升本包版本；`std` 只保留 `Utf8Text::to_lower` / `to_upper` 签名，
  实现固定在某个 `unicode.case` 版本，std 语义不随之漂移。

## 当前能力

| 能力 | 状态 | 数据来源 |
|:-----|:-----|:---------|
| simple 大小写映射（BMP 全量） | 已实现 | `UnicodeData.txt` 字段 12/13 |
| 1→多映射（`ß→SS`、`İ→i̇`、`ŉ→ʼN`、`ǰ→J̌`） | 已实现 | `SpecialCasing.txt` 无条件项 |
| Final_Sigma（词尾 `Σ→ς`） | 已实现 | `SpecialCasing.txt` 条件规则 + `Cased` / `Case_Ignorable` |

## Final_Sigma 判定

按 Unicode 3.13（Itanium 词边界）：`Σ` 变 `ς` 当且仅当**前面有 `Cased`**（可跳过若干
`Case_Ignorable`）且**后面不是**（`Case_Ignorable*` 后接 `Cased`）。实现逐码点向前/向后跳过
`Case_Ignorable` 判定，边界即串首/串尾。写成中文即「前有字母、后无字母」。

## 边界

- `char` 是 u16：非 BMP 码点不能表达，直接不支持；文本级映射对 4 字节序列原样保留，
  也**不参与** Final_Sigma 的上下文判定（记为缺口）。
- 不做规范化（NFC/NFD）、不做 `to_titlecase`。
- 条件项里的**语言相关**规则（土耳其语/阿塞拜疆语 `I→ı`、立陶宛语）故意不实现：
  本包语义是 locale 无关。
- 数据表由脚本生成，不手改；按 512 码点分块（每块一个函数），因为 OVM 单函数代码上限 64KiB。
- 文本级映射用 `ArrayList<u8>` 逐码点编码追加，输出为变长字节序列。
- 跨包数组元素统一用 `char`（内建类型），调用方按需 `as u32` 读取。

## 再生成

```powershell
node scripts/gen-unicode-case.mjs
```

脚本默认从 `https://www.unicode.org/Public/16.0.0/ucd/` 下载 `UnicodeData.txt`、
`SpecialCasing.txt`、`DerivedCoreProperties.txt` 到 `.cache/unicode/16.0.0`（已存在则复用），
并把每个输入的 SHA-256 写入对应生成文件头。同一份数据重跑得到逐字节相同的 V 文件。
