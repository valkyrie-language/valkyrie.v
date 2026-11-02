# notedown 迁移映射（`source/ir/` → `document` 核心）

原则：notedown 只做"解析进模型"一端——`std.data.text.dejavu` 产出 notedown 方言的
lexer/parser 产物，notedown 把 AST 映射为 `document` 树；不造树、不渲染。

## 1. Block 映射（`ir/block.v`，kind 魔法数 0–6）

| notedown 现状 | `document` 目标 | 说明 |
|---|---|---|
| `0=Section{level, title, children}` | `Heading{level, content}` | 核心文档是扁平序列，章节嵌套由 Heading 层级 + 编号 pass 派生；`children`（图引用）不再存在，内容按文档序平铺 |
| `1=Paragraph{content}` | `Paragraph{content}` | 直迁 |
| `2=List{ordered, items}` | `ListBlock{ordered, start, items}` | `start` 取首项序号或 1；见 §3 方言项 |
| `3=Quote{content:[Inline]}` | `QuoteBlock{content:[Block]}` | 核心引用块内容升格为块序列（核心更强，迁移时把 inline 包一层 Paragraph） |
| `4=Code{language, text}` | `CodeBlock{language, text}` | 直迁 |
| `5=Table{caption, rows}` | `Table{caption, header, rows}` | `TableRow.is_header` 拆出 header 区：头部连续 `is_header` 行进 `header`，其余进 `rows`；`TableCell` 字段同构直迁 |
| `6=RawHtml{html}` | **核心缺失，不迁** | 核心 v0 明确无 RawBlock（core-contract §7）；raw HTML 是方言产物，见 §3 |

## 2. Inline 映射（`ir/inline.v`，kind 魔法数 0–6）

| notedown 现状 | `document` 目标 | 说明 |
|---|---|---|
| `0=Text{text}` | `Text{text}` | 直迁 |
| `1=Styled{style: utf8, children}` | `Styled{style: InlineStyle, content}` | 自由字符串 style → 枚举；无法归入 Strong/Emphasis/Code/Strike 的字符串是方言（§3） |
| `2=InlineCode{text}` | `Styled{style: Code, content:[Text{text}]}` | 归一入样式枚举 |
| `3=Link{target, title, children}` | `Link{target, title, content}` | 直迁 |
| `4=Image{source, alt, title}` | `InlineImage{source, alt, title}` | 直迁 |
| `5=Break{hard}` | `Break{hard}` | 直迁 |
| `6=RawHtml{html}` | **核心缺失，不迁** | 同 §1 |

## 3. 方言项（归 `std.data.text.dejavu`，不进核心）

| 项 | 来源 | 处置 |
|---|---|---|
| 任务列表（`ListItem.is_task` / `is_checked`） | `ir/block.v` | 方言扩展；如需跨核心携带，进 `attributes`（如 `data-task`/`data-checked`），核心不建专用字段 |
| `ListItem.number`（逐项序号） | `ir/block.v` | 核心只有块级 `start`；逐项自定义序号是方言，进 `attributes` |
| RawHtml（块/inline 两处） | `ir/block.v` `ir/inline.v` | 方言片段，核心不表达；dejavu 解析侧保留 token/CST，映射时按格式策略降级或诊断 |
| 自由字符串 style | `ir/inline.v` | 非四枚举的 style 字符串留 dejavu；映射时无法归一者进 `classes` 并记诊断 |
| notedown 文本语法本体 | — | `std.data.text.dejavu`：按 std.data 三段 trait 产 token/CST/AST，与 markdown 包同合同 |

## 4. 编辑图（`ir/graph.v` + `ir/validate.v`）

| 项 | 判定 |
|---|---|
| `DocumentGraph{id, revision, blocks, next_node}` + 增删改查 | **核心缺失，不迁**。编辑图（稳定 NodeId、revision、悬挂引用清理）是编辑器关注点，不是文档模型；需要时另立 `document.edit`，不塞进 `document` |
| `graph_validate` 的 level 范围检查 | 由核心 `document_validate` 的 B1（heading_level）覆盖 |
| `graph_validate` 的悬挂子引用检查 | 核心树无引用边（扁平 + 编号派生），该问题类在核心不存在；`document_validate` 覆盖 id 唯一与引用完整（footnote/citation key） |

## 5. 核心新增（notedown 侧原本没有）

元数据与 front matter（`DocumentMetadata`）、脚注定义与引用（`FootnoteDefinition`/`FootnoteRef`）、
参考文献（`BibliographyEntry`/`CitationRef`）、节点 id/classes/attributes 开放扩展面、
资源表（`AssetTable`）、编号/TOC pass（`document_index`/`document_toc`）。

## 6. 迁移动作序列（实施时按此拆块）

1. 第一步：notedown 新增映射层 `map/`（dejavu AST → `document` 树），依赖边加 `document`。
2. 第二步：notedown 测试改断言核心模型（沿用 conformance 思路，结构断言）。
3. 第三步：`source/ir/` 整体退役删除（含 `ir_graph.v` 旧测试）；`_.v` 更新定位描述。
4. 第四步：图编辑能力如仍有消费方，先登记 `document.edit` 需求坐标，不在本序列内实现。
