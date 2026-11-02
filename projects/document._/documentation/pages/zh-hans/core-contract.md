# `document.*` 核心合同（v0 设计）

状态：设计定稿，待编译器泛洪清零后实施。本文是核心模型、引用求解、布局/渲染边界与失败模型的唯一合同；
实现以本文为准逐块落地，落地后本文保持与代码同步。

## 1. 包划分与依赖方向

```text
document          文档树、元数据、引用、资源、校验、失败类型（无 IO、无渲染、无布局）
document.layout   页面/测量/断行断页            ──依赖──▶ document
document.render   渲染管线与输出目标            ──依赖──▶ document, document.layout
notedown / tex / …产品包                        ──依赖──▶ document（只产模型，不造树、不渲染）
```

- 核心三包不得依赖任何产品包；产品包只把解析产物映射进核心模型。
- 判定规则：**知道"页面"存在的归 layout；知道"标签/输出语法"存在的归 render；两者都不知道的归 document。**

## 2. 文档模型（document 包）

### 2.1 节点骨架

```v
structure DocumentAttribute { name: utf8, value: utf8 }

structure Block {
    id: u64
    classes: [utf8]
    attributes: [DocumentAttribute]
    kind: BlockKind
}

structure Inline {
    id: u64
    classes: [utf8]
    attributes: [DocumentAttribute]
    kind: InlineKind
}
```

- `id`：文档内唯一的节点身份，`u64`。构造侧保证唯一；`document_validate` 查重。`0` 不是保留值，仅是普通取值。
- `classes`/`attributes`：开放扩展面。核心不解释的扩展信息（如任务列表勾选态）一律进这里，不新增字段。
- `attributes` 内键可重复出现由构造侧负责去重；校验对重复键报 `document.error.duplicate_attribute`。

### 2.2 BlockKind

```v
unite BlockKind {
    [constructor] Heading { level: usize, content: [Inline] }
    [constructor] Paragraph { content: [Inline] }
    [constructor] ListBlock { ordered: bool, start: usize, items: [ListItem] }
    [constructor] Table { caption: Option<utf8>, header: [TableRow], rows: [TableRow] }
    [constructor] CodeBlock { language: Option<utf8>, text: utf8 }
    [constructor] QuoteBlock { content: [Block] }
    [constructor] ThematicBreak
    [constructor] ImageBlock { source: utf8, alt: [Inline], title: Option<utf8> }
}

structure ListItem { blocks: [Block] }
structure TableRow { cells: [TableCell], is_header: bool }
structure TableCell { content: [Block], colspan: usize, rowspan: usize }
```

不变量（违例 → `document_validate` 报错，渲染硬失败）：

| 编号 | 不变量 | 错误码 |
|---|---|---|
| B1 | `1 ≤ Heading.level ≤ 6` | `document.error.heading_level` |
| B2 | `ListBlock.ordered = true` 时 `start ≥ 1` | `document.error.list_start` |
| B3 | `TableCell.colspan ≥ 1`、`rowspan ≥ 1` | `document.error.cell_span` |
| B4 | 嵌套列表只经 `ListItem.blocks` 内的 `ListBlock` 表达 | （结构即真，无码） |
| B5 | `id` 文档内唯一（Block/Inline 同一命名空间） | `document.error.duplicate_id` |
| B6 | 同一节点 `attributes` 键不重复 | `document.error.duplicate_attribute` |

### 2.3 InlineKind

```v
unite InlineKind {
    [constructor] Text { text: utf8 }
    [constructor] Styled { style: InlineStyle, content: [Inline] }
    [constructor] Link { target: utf8, title: Option<utf8>, content: [Inline] }
    [constructor] InlineImage { source: utf8, alt: [Inline], title: Option<utf8> }
    [constructor] Break { hard: bool }
    [constructor] FootnoteRef { key: utf8 }
    [constructor] CitationRef { keys: [utf8] }
}

enums InlineStyle { Strong, Emphasis, Code, Strike }
```

不变量：

| 编号 | 不变量 | 错误码 |
|---|---|---|
| I1 | `Text.text` 可为空串（合法，渲染为空） | （无） |
| I2 | `FootnoteRef.key` 必须在 `Document.footnotes` 有定义 | `document.error.undefined_footnote` |
| I3 | `CitationRef.keys` 非空，且每键在 `Document.bibliography` 有定义 | `document.error.undefined_citation` |
| I4 | `Styled` 允许嵌套；同 style 直接嵌套在渲染时归一为单层 | （渲染归一，非错误） |

### 2.4 文档本体与元数据

```v
structure DocumentMetadata {
    title: Option<utf8>
    authors: [utf8]
    date: Option<utf8>
    labels: [utf8]
    front_matter: [DocumentAttribute]
}

structure FootnoteDefinition { key: utf8, content: [Block] }
structure BibliographyEntry { key: utf8, fields: [DocumentAttribute] }

structure Document {
    metadata: DocumentMetadata
    blocks: [Block]
    footnotes: [FootnoteDefinition]
    bibliography: [BibliographyEntry]
}
```

- 元数据与正文严格分离；`front_matter` 原样保留，核心不解释任何键名。
- 不变量：`footnotes` 键唯一（`document.error.duplicate_footnote_key`）；`bibliography` 键唯一（`document.error.duplicate_bib_key`）。
- 文档是**扁平块序列**：章节不由嵌套结构表达，由 Heading 层级 + 编号 pass 派生（见 §3）。

## 3. 引用系统求解规则

### 3.1 编号 pass 产物

```v
structure SectionNumber { parts: [usize] }
structure SectionRef { node_id: u64, number: SectionNumber, anchor: utf8, title: [Inline] }
structure FootnoteNumber { key: utf8, number: usize }
structure CitationNumber { key: utf8, number: usize }

structure DocumentIndex {
    sections: [SectionRef]
    footnotes: [FootnoteNumber]
    citations: [CitationNumber]
}

structure TocEntry { level: usize, number: SectionNumber, title: [Inline], anchor: utf8 }

micro document_index(document: Document) -> DocumentIndex
micro document_toc(index: DocumentIndex) -> [TocEntry]
```

### 3.2 章节编号规则

- 只对**顶层** `blocks` 的 `Heading` 编号；`QuoteBlock`/`TableCell`/`ListItem` 内部的 heading 不编号、不进 TOC（规则 R1）。
- 维护计数器 `counter[1..=6]`。遇到 `level = L` 的 heading：`counter[L] += 1`，并把 `counter[L+1..=6]` 清零（R2）。
- `SectionNumber.parts = counter[1..=L]`（定长 L 段）。跳级不补段：`h1` 后接 `h3` 得 `1.0.1`（R3，如实记录，校验侧可出提示但不判错）。
- `anchor`：点分编号字符串（如 `"1.2.3"`）。全文档唯一（编号唯一 ⇒ anchor 唯一，R4）。

### 3.3 脚注与引用键

- 脚注按 `Document.footnotes` **声明序**编号 1..n（R5）；`FootnoteRef.key` 经查表替换为编号；未定义 → 渲染硬失败。
- 参考文献按 `Document.bibliography` **声明序**编号 1..n（R6）；`CitationRef.keys` 逐键查表，渲染为 `[1]`、`[1,2]` 形态；未定义 → 渲染硬失败。
- 交叉引用 v0 范围：TOC、脚注、引用键、heading anchor。`Link.target` 以 `#` 开头者按 anchor 原样输出，核心不做存在性校验（R7，目标中立）。

### 3.4 TOC

- `document_toc` 只消费 `DocumentIndex.sections`，不重扫树（R8）。
- TOC 层级 = heading level；条目顺序 = 文档序。

## 4. 资源（document 包）

```v
enums AssetKind { Image, Font, Attachment }

structure AssetEntry { kind: AssetKind, source: utf8, resolved: utf8 }
structure AssetTable { entries: [AssetEntry] }

micro asset_register(table: AssetTable, kind: AssetKind, source: utf8, base: utf8) -> AssetTable
```

- `resolved` = base 解析后的资源身份。规则：**绝对路径原样**（以 `/` 或盘符开头，R9）；相对路径 = `base` + `/` + `source` 的字符串拼接，随后做 `/` 重复折叠与末尾 `/` 去除（R10）。v0 **不解析 `.`/`..`**（R11，记录为边界，不做字符串魔法）。
- 去重：`resolved` 相同且 `kind` 相同 ⇒ 已存在则原样返回（R12）。
- 核心不做 IO：读文件、取网络、探测 MIME 全是 host capability，归消费侧。

## 5. 布局与渲染边界

### 5.1 归 `document.layout`

```v
structure PageSpec {
    width: usize
    height: usize
    margin_top: usize
    margin_right: usize
    margin_bottom: usize
    margin_left: usize
    header: Option<[Inline]>
    footer: Option<[Inline]>
}

structure PageBox { index: usize, lines: [utf8] }

micro paginate(lines: [utf8], spec: PageSpec) -> [PageBox]
```

- 测量 v0：字符单元（1 码点 = 1 宽，等宽假设）。真实字体测量是经 provider 接入的后续能力，本包不硬编码字体知识。
- 断行：按可用宽度（`width − margin_left − margin_right`）折叠；v0 只对**已发射的文本行**分页，不理解块语义。
- 断页规则：keep-with-next（页尾孤 heading 行推入下页，R13）；表格行不拆（表格字符网格按整行单位，R14）；孤行/寡行规则 v0 不实现（R15，记录边界）。
- 列表/表格测量：列表缩进宽度、表格列宽分配（按内容最大宽，封顶可用宽度）——属 layout，文本渲染器消费。

### 5.2 归 `document.render`

```v
unite RenderResult<T> {
    [constructor] Fine { value: T }
    [constructor] Fail { error: DocumentError }
}

structure DocumentError { code: utf8, message: utf8, node_id: u64 }

trait DocumentRenderer {
    type Output;
    micro render(self, document: Document, index: DocumentIndex) -> RenderResult<Output>
}

structure HtmlRenderer {}
structure TextRenderer {}
```

- 管线：`document_validate` 预检 → `document_index` 编号 → 目标发射。任一硬失败即 `Fail`，不产半成品（R16）。
- HTML 目标：连续流，不分页（页面概念不进 HTML，R17）；文本目标：可选消费 `paginate` 产分页文本。
- HTML 转义：`Text`、属性值中的 `&` `<` `>` `"` 必转义（R18）；URI 属性原样引用（v0 不做 URL 编码魔法，R19）。
- 标签映射：`Heading→h1..h6`、`Paragraph→p`、`ListBlock→ol/ul+li`、`Table→table/thead/tbody/tr/th/td`、`CodeBlock→pre>code`（language 落 `class="language-x"`）、`QuoteBlock→blockquote`、`ThematicBreak→hr`、`ImageBlock→img`、脚注区段 = `<section class="footnotes">` + 有序列表，引用处上标链（R20）。
- 纯文本约定：列表标记 `-` / `1.`、缩进 2 空格/级；表格为字符网格（`|` 分隔）；代码块原样 fenced；hard break = 换行，soft break = 空格；脚注/参考文献各自成区，编号与正文引用一致（R21）。

## 6. 失败模型

| 侧 | 合同 |
|---|---|
| 解析侧（产品包） | `std.data` `DataOutcome` 三态：生产值 + 诊断累积，错误容许；核心不重复此机制 |
| 布局/渲染侧 | `RenderResult.Fail` 硬失败：结构化 `DocumentError`（稳定 code + `node_id`，文档级取 0）；不 panic、不产半成品 |
| 模型预检 | `document_validate(document) -> [DocumentError]`：聚合全部违例，不首错返回 |

错误码一览：`document.error.heading_level`、`document.error.list_start`、`document.error.cell_span`、`document.error.duplicate_id`、`document.error.duplicate_attribute`、`document.error.duplicate_footnote_key`、`document.error.duplicate_bib_key`、`document.error.undefined_footnote`、`document.error.undefined_citation`。

## 7. 明确不做（v0 边界）

- 无 RawBlock/RawHtml：原始格式片段不可目标中立表达，归产品方言包处理，不进核心。
- 无编辑图（NodeId/revision/增删改）：编辑器关注点，不是文档模型；如有需要在 `document.edit` 另立。
- 无 IO：文件/网络/字体文件读取全在消费侧。
- 无 `.`/`..` 路径解析、无 URL 编码、无 MIME 探测。
- 无 Setext 标题、无 `1.` 有序列表语法归一——这些是格式方言，归 `std.data.text.*`。
