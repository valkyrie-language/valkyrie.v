namespace document;

# 模型预检 `document_validate`：聚合全部违例，不首错返回。
#
# 覆盖的不变量与错误码（文档级违例 `node_id` 取 0）：
# - B1 `1 ≤ Heading.level ≤ 6` → `document.error.heading_level`
# - B2 有序列表 `start ≥ 1` → `document.error.list_start`
# - B3 `colspan/rowspan ≥ 1` → `document.error.cell_span`（挂在所属 Table 块 id 上）
# - B5 节点 id 文档内唯一（Block/Inline 同一命名空间，含脚注定义内容）→ `document.error.duplicate_id`
# - B6 同一节点 `attributes` 键不重复 → `document.error.duplicate_attribute`
# - I2 `FootnoteRef.key` 必须有定义 → `document.error.undefined_footnote`
# - I3 `CitationRef.keys` 非空且每键有定义 → `document.error.undefined_citation`
# - 元数据：脚注键唯一 → `document.error.duplicate_footnote_key`；参考文献键唯一 → `document.error.duplicate_bib_key`
#
# B4（嵌套列表只经 `ListItem.blocks` 表达）与 I1（空串 `Text` 合法）是结构即真，无检查。

# 遍历状态：已聚合错误与已见节点 id。不可变线程式传递，不就地改写。
structure ValidateState {
    errors: [DocumentError]
    seen_ids: [u64]
}

micro validate_state_with_error(state: ValidateState, error: DocumentError) -> ValidateState {
    return ValidateState {
        errors: push(state.errors, error),
        seen_ids: state.seen_ids
    }
}

micro validate_state_has_id(state: ValidateState, id: u64) -> bool {
    let mut index: usize = 0
    while index < state.seen_ids.length() {
        if state.seen_ids⁅index⁆ == id {
            return true
        }
        index = index + 1
    }
    return false
}

# 登记节点 id：重复即聚合 `document.error.duplicate_id`（报在后出现的节点上）。
micro validate_state_register_id(state: ValidateState, id: u64) -> ValidateState {
    if validate_state_has_id(state, id) {
        return validate_state_with_error(state, document_error("document.error.duplicate_id", "node id must be unique within the document", id))
    }
    return ValidateState {
        errors: state.errors,
        seen_ids: push(state.seen_ids, id)
    }
}

micro validate_attributes_of(node_id: u64, attributes: [DocumentAttribute], state: ValidateState) -> ValidateState {
    let mut result: ValidateState = state
    let mut outer: usize = 0
    while outer < attributes.length() {
        let mut inner: usize = outer + 1
        while inner < attributes.length() {
            if attributes⁅outer⁆.name.equals(attributes⁅inner⁆.name) {
                result = validate_state_with_error(result, document_error("document.error.duplicate_attribute", "attribute names must not repeat on one node", node_id))
            }
            inner = inner + 1
        }
        outer = outer + 1
    }
    return result
}

micro validate_inline_tree(item: Inline, document: Document, state: ValidateState) -> ValidateState {
    let mut result: ValidateState = validate_state_register_id(state, item.id)
    result = validate_attributes_of(item.id, item.attributes, result)
    match item.kind {
        case Text(payload):
            return result
        case Styled(payload):
            return validate_inline_list(payload.content, document, result)
        case Link(payload):
            return validate_inline_list(payload.content, document, result)
        case InlineImage(payload):
            return validate_inline_list(payload.alt, document, result)
        case Break(payload):
            return result
        case FootnoteRef(payload):
            if !document_has_footnote(document, payload.key) {
                return validate_state_with_error(result, document_error("document.error.undefined_footnote", "footnote reference must resolve to a definition", item.id))
            }
            return result
        case CitationRef(payload):
            if payload.keys.length() == 0 {
                result = validate_state_with_error(result, document_error("document.error.undefined_citation", "citation reference must name at least one key", item.id))
                return result
            }
            let mut index: usize = 0
            while index < payload.keys.length() {
                if !document_has_bibliography(document, payload.keys⁅index⁆) {
                    result = validate_state_with_error(result, document_error("document.error.undefined_citation", "citation key must resolve to a bibliography entry", item.id))
                }
                index = index + 1
            }
            return result
    }
}

micro validate_inline_list(items: [Inline], document: Document, state: ValidateState) -> ValidateState {
    let mut result: ValidateState = state
    let mut index: usize = 0
    while index < items.length() {
        result = validate_inline_tree(items⁅index⁆, document, result)
        index = index + 1
    }
    return result
}

micro validate_block_list(blocks: [Block], document: Document, state: ValidateState) -> ValidateState {
    let mut result: ValidateState = state
    let mut index: usize = 0
    while index < blocks.length() {
        result = validate_block_tree(blocks⁅index⁆, document, result)
        index = index + 1
    }
    return result
}

micro validate_table_rows(owner_id: u64, rows: [TableRow], document: Document, state: ValidateState) -> ValidateState {
    let mut result: ValidateState = state
    let mut row_index: usize = 0
    while row_index < rows.length() {
        let row: TableRow = rows⁅row_index⁆
        let mut cell_index: usize = 0
        while cell_index < row.cells.length() {
            let cell: TableCell = row.cells⁅cell_index⁆
            if cell.colspan < 1 || cell.rowspan < 1 {
                result = validate_state_with_error(result, document_error("document.error.cell_span", "table cell span must be at least one", owner_id))
            }
            result = validate_block_list(cell.content, document, result)
            cell_index = cell_index + 1
        }
        row_index = row_index + 1
    }
    return result
}

micro validate_block_tree(block: Block, document: Document, state: ValidateState) -> ValidateState {
    let mut result: ValidateState = validate_state_register_id(state, block.id)
    result = validate_attributes_of(block.id, block.attributes, result)
    match block.kind {
        case Heading(payload):
            if payload.level < 1 || payload.level > 6 {
                result = validate_state_with_error(result, document_error("document.error.heading_level", "heading level must stay within one to six", block.id))
            }
            return validate_inline_list(payload.content, document, result)
        case Paragraph(payload):
            return validate_inline_list(payload.content, document, result)
        case ListBlock(payload):
            if payload.ordered && payload.start < 1 {
                result = validate_state_with_error(result, document_error("document.error.list_start", "ordered list start must be at least one", block.id))
            }
            let mut index: usize = 0
            while index < payload.items.length() {
                result = validate_block_list(payload.items⁅index⁆.blocks, document, result)
                index = index + 1
            }
            return result
        case Table(payload):
            result = validate_table_rows(block.id, payload.header, document, result)
            return validate_table_rows(block.id, payload.rows, document, result)
        case CodeBlock(payload):
            return result
        case QuoteBlock(payload):
            return validate_block_list(payload.content, document, result)
        case ThematicBreak:
            return result
        case ImageBlock(payload):
            return validate_inline_list(payload.alt, document, result)
    }
}

# 模型预检入口：聚合并返回全部违例；空列表即模型合法。
micro document_validate(document: Document) -> [DocumentError] {
    let mut state: ValidateState = ValidateState {
        errors: [],
        seen_ids: []
    }

    let mut footnote_outer: usize = 0
    while footnote_outer < document.footnotes.length() {
        let mut footnote_inner: usize = footnote_outer + 1
        while footnote_inner < document.footnotes.length() {
            if document.footnotes⁅footnote_outer⁆.key.equals(document.footnotes⁅footnote_inner⁆.key) {
                state = validate_state_with_error(state, document_error("document.error.duplicate_footnote_key", "footnote keys must be unique", 0))
            }
            footnote_inner = footnote_inner + 1
        }
        footnote_outer = footnote_outer + 1
    }

    let mut bib_outer: usize = 0
    while bib_outer < document.bibliography.length() {
        let mut bib_inner: usize = bib_outer + 1
        while bib_inner < document.bibliography.length() {
            if document.bibliography⁅bib_outer⁆.key.equals(document.bibliography⁅bib_inner⁆.key) {
                state = validate_state_with_error(state, document_error("document.error.duplicate_bib_key", "bibliography keys must be unique", 0))
            }
            bib_inner = bib_inner + 1
        }
        bib_outer = bib_outer + 1
    }

    state = validate_block_list(document.blocks, document, state)

    let mut footnote_index: usize = 0
    while footnote_index < document.footnotes.length() {
        state = validate_block_list(document.footnotes⁅footnote_index⁆.content, document, state)
        footnote_index = footnote_index + 1
    }

    return state.errors
}
