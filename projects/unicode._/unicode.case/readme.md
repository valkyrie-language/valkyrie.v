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
| 1→多映射（`ß→SS`、`İ→i̇`） | 未实现 | `SpecialCasing.txt` |
| Final_Sigma（词尾 `Σ→ς`） | 未实现 | `SpecialCasing.txt` 条件规则 |

## 边界

- `char` 是 u16：非 BMP 码点不能表达，直接不支持；文本级映射对 4 字节序列原样保留。
- 不做规范化（NFC/NFD）、不做语言敏感映射、不做 `to_titlecase`。
- 数据表由脚本生成，不手改；按 512 码点分块（每块一个函数），因为 OVM 单函数代码上限 64KiB，
  且整表一次性字面量会触发「trait 约束未解析：LiteralSequence」。
- 文本级映射用 `ArrayList<u8>` 逐码点编码追加，而非 `Utf8Builder.append`：
  后者在跨包调用时与 `std.collection.LiteralSequence.append` 重载冲突，编译失败。

## 再生成

```powershell
node scripts/gen-unicode-case.mjs
```

脚本默认从 `https://www.unicode.org/Public/16.0.0/ucd/UnicodeData.txt` 下载数据到
`.cache/unicode/16.0.0`（已存在则复用），并把输入 SHA-256 写入生成文件头。
