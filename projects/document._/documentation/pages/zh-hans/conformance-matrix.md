# `document.*` 核心 conformance 用例表

状态：设计定稿。全部用例以**内存构造文档树**驱动，不经过任何解析器。
编号规则：`M`=模型校验、`N`=编号/TOC、`H`=HTML、`T`=纯文本、`P`=断页、`A`=资源、`X`=可插拔/失败。
期望列只列断言要点，不写整串 golden。合同条目引用 [core-contract](./core-contract.md) 编号。

## M 模型校验（document_validate）

| # | 合同 | 输入树要点 | 期望 |
|---|---|---|---|
| M1 | B1 | `Heading.level = 0` | 报 `document.error.heading_level`，node_id 对 |
| M2 | B1 | `Heading.level = 7` | 同上 |
| M3 | B2 | `ListBlock{ordered: true, start: 0}` | 报 `document.error.list_start` |
| M4 | B3 | `TableCell{colspan: 0}` | 报 `document.error.cell_span` |
| M5 | B5 | 两个 Block 同 `id` | 报 `document.error.duplicate_id`（含两 id 之一） |
| M6 | B6 | 同节点 attributes 两同键 | 报 `document.error.duplicate_attribute` |
| M7 | §2.4 | footnotes 两同 key | 报 `document.error.duplicate_footnote_key` |
| M8 | §2.4 | bibliography 两同 key | 报 `document.error.duplicate_bib_key` |
| M9 | B4 | 三级嵌套列表（ListItem.blocks 内 ListBlock 套 ListBlock） | validate 通过 |
| M10 | §2.2 | QuoteBlock 内含 Paragraph+CodeBlock；TableCell 内含 ListBlock | validate 通过 |
| M11 | §6 | 一棵树同时含 M1+M3+M5 违例 | 三条全报，不首错返回 |

## N 编号 / 引用 / TOC（document_index / document_toc）

| # | 合同 | 输入树要点 | 期望 |
|---|---|---|---|
| N1 | R2 | `h1 h2 h3` 顺序三节 | `1` / `1.1` / `1.1.1` |
| N2 | R2 | `h1 h2 h2 h1` | `1` / `1.1` / `1.2` / `2`（上级递增清下级） |
| N3 | R3 | `h1` 后直接 `h3` | `1` 与 `1.0.1`（不补段） |
| N4 | R1 | QuoteBlock 内夹一个 h2 | 顶层 sections 不含它，TOC 无此项 |
| N5 | R4 | 全部 heading | anchor = 点分号且唯一 |
| N6 | R5 | footnotes 两定义 + 正文两处 FootnoteRef | 编号 1/2；渲染引用处显示对应号 |
| N7 | R6 | bibliography 两条 + CitationRef{keys:[k2,k1]} | 渲染 `[2,1]`（按引用键序，不重排） |
| N8 | I2 | FootnoteRef 指向未定义 key | render Fail `document.error.undefined_footnote` |
| N9 | I3 | CitationRef 含未定义 key | render Fail `document.error.undefined_citation` |
| N10 | R8 | 三节树 | `document_toc` 三项，level/number/title/anchor 与 sections 一致 |
| N11 | R7 | `Link{target:"#1.2"}` | HTML 原样 `href="#1.2"`，无校验失败 |

## H HTML 目标（HtmlRenderer）

| # | 合同 | 输入树要点 | 期望要点 |
|---|---|---|---|
| H1 | R20 | h1 标题含 Text | `<h1 id="1">` + 文本 |
| H2 | R20 | Paragraph 含 Strong/Emphasis/Code/Strike | `<strong><em><code><del>` 各就位 |
| H3 | I4 | Strong 套 Strong | 归一单层 `<strong>` |
| H4 | R20 | 无序列表两级嵌套 | 外层 `<ul>` 内 `li > ul` 结构 |
| H5 | R20 | `ListBlock{ordered, start: 3}` | `<ol start="3">` |
| H6 | R20 | 表格含 header 行 + colspan=2 | `thead/th`、`td colspan="2"` |
| H7 | R20 | `CodeBlock{language: Some("v")}` | `<pre><code class="language-v">` |
| H8 | R18 | Text 含 `& < > "` | 全部转义为实体 |
| H9 | §2.2 | ThematicBreak | `<hr>` |
| H10 | R20 | ImageBlock/InlineImage | `<img src alt>`，title 有则落位 |
| H11 | R19 | `Link{target:"a b.md"}` | `href` 原样含空格，不做编码 |
| H12 | §2.1 | 节点带 classes/attributes | `class` 合并落位，attributes 落同名属性 |
| H13 | R20 | 两脚注 + 引用点 | `<sup>` 链接 + `<section class="footnotes">` 有序项 |
| H14 | R20 | CitationRef 两键 | `[1,2]` 文本形 |
| H15 | R17 | 任意树 | HTML 产物无分页概念 |
| H16 | R18 | attributes 值含 `"` 与 `<` | 属性值内转义 |

## T 纯文本目标（TextRenderer）

| # | 合同 | 输入树要点 | 期望要点 |
|---|---|---|---|
| T1 | R21 | h1/h2 | 标题行 + 点分编号前缀 |
| T2 | R21 | 无序两级嵌套列表 | `-` 标记，内层缩进 2 空格 |
| T3 | R21 | 有序列表 start=3 | `3.` `4.` 连续编号 |
| T4 | R21 | 表格（含 header） | `\|` 分隔字符网格，header 分隔线 |
| T5 | R21 | CodeBlock | fenced 原样，语言标记保留 |
| T6 | R21 | QuoteBlock | `> ` 前缀逐行 |
| T7 | R21 | Break hard/soft | 硬 = 换行，软 = 空格 |
| T8 | R21 | 两脚注 | 正文 `[1]` 上标位 + 文末 `Footnotes` 区对应编号 |
| T9 | R21 | bibliography 两条 | 文末区 `[1]`/`[2]` 条目 |
| T10 | R21 | TOC 输出（文档含三节） | 文首/独立区三项，缩进按 level |

## P 断页（document.layout.paginate）

| # | 合同 | 输入要点 | 期望 |
|---|---|---|---|
| P1 | §5.1 | 20 行文本，`PageSpec.height=10`（边距 0） | 2 页，各 10 行 |
| P2 | §5.1 | height=10 + 上下边距各 2 | 每页正文 ≤6 行，页数相应 |
| P3 | R13 | 页尾仅剩 1 行且为 heading 行 | heading 行整体移入下页 |
| P4 | R14 | 表格跨页 | 不拆单行；行整体落到下页 |
| P5 | §5.1 | header/footer 配置 | 每页首行/末行为页眉页脚文本 |
| P6 | §5.1 | 行宽超可用宽 | 按可用宽折叠（断行点断言） |

## A 资源（asset_register）

| # | 合同 | 输入 | 期望 |
|---|---|---|---|
| A1 | R12 | 同 kind 同 source 注册两次 | entries 长度 1 |
| A2 | R12 | 同 source 不同 kind | 两条（kind 参与身份） |
| A3 | R10 | base `docs` + `a.png` | resolved `docs/a.png` |
| A4 | R10 | base `docs/` + `a.png` | resolved `docs/a.png`（无重复分隔） |
| A5 | R9 | source `/abs/x.png` + base `docs` | resolved `/abs/x.png` 不变 |
| A6 | R11 | source `../x.png` | 原样拼接，不做 `..` 解析 |

## X 可插拔与失败通道

| # | 合同 | 输入 | 期望 |
|---|---|---|---|
| X1 | §5.2 | 同一棵树过 HTML 与 Text 两目标 | 块级内容项计数一致（同树同源） |
| X2 | R16 | 含 M1 违例的树直接 render | `Fail`，code 稳定，无产物、无 panic |
| X3 | R16 | 含 N8 未定义脚注的树 render | `Fail document.error.undefined_footnote` |
| X4 | §5.2 | 第三目标 stub（测试内自定义 Renderer） | 与内置两目标同管线可达（trait 可插拔证明） |

## 通过口径

- 全部用例结构断言（节点存在性、属性值、计数、编号、错误码），不做整串 golden 比对。
- 每区正例反例成对；失败用例必须断言 `Fail` 且 code 精确，禁止 panic 通过。
