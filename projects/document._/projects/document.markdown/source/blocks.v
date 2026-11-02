namespace document.markdown;

using document::{Block, Document, FootnoteDefinition, Inline, ListItem, TableCell, TableRow, block_code, block_heading, block_list, block_paragraph, block_table, block_thematic_break, empty_document_metadata, footnote_definition, inline_break, list_item, new_document, table_cell, table_row};

# 块级装配：fenced 代码块、标题、`---`、`-` 列表、pipe 表格、脚注定义、段落。
# 未闭合 fence 收编到源末尾（错误容许）；表格缺分隔行时整段按段落处理。

structure MarkdownBlocks {
    gen: MarkdownIdGen
    blocks: [Block]
    footnotes: [FootnoteDefinition]
}

micro markdown_blocks_push(state: MarkdownBlocks, block: Block) -> MarkdownBlocks {
    return MarkdownBlocks {
        gen: state.gen,
        blocks: push(state.blocks, block),
        footnotes: state.footnotes
    }
}

# 行扫描成 inline 序列；多行段落行间插 soft `Break`。
micro markdown_scan_paragraph(lines: [utf8], start: usize, count: usize, gen: MarkdownIdGen) -> MarkdownScan {
    let mut state: MarkdownScan = MarkdownScan {
        gen: gen,
        items: []
    }
    let mut offset: usize = 0
    while offset < count {
        if offset > 0 {
            let break_id: u64 = state.gen.next
            state = MarkdownScan {
                gen: markdown_bump_id(state.gen),
                items: push(state.items, inline_break(break_id, false))
            }
        }
        state = markdown_scan_inlines(lines⁅start + offset⁆, state.gen)
        offset = offset + 1
    }
    return state
}

# 段落级 `$$...$$` 检测：拼接文本 trim 后两端恰为 `$$` 且内容非空。
micro markdown_display_math(joined: utf8) -> utf8 {
    let trimmed: utf8 = markdown_trim(joined)
    let length: usize = trimmed.length()
    if length < 5 {
        return ""
    }
    if !trimmed.slice(0, 2).equals("$$") {
        return ""
    }
    if !trimmed.slice(length - 2, 2).equals("$$") {
        return ""
    }
    return markdown_trim(trimmed.slice(2, length - 4))
}

micro markdown_parse_document(source: utf8) -> Document {
    let lines: [utf8] = markdown_split_lines(source)
    let mut state: MarkdownBlocks = MarkdownBlocks {
        gen: markdown_id_gen(),
        blocks: [],
        footnotes: []
    }
    let mut cursor: usize = 0
    while cursor < lines.length() {
        let line: utf8 = lines⁅cursor⁆
        let trimmed: utf8 = markdown_trim(line)
        if trimmed.length() == 0 {
            cursor = cursor + 1
        } else if trimmed.slice(0, 3).equals("```") && trimmed.length() >= 3 {
            let language: utf8 = markdown_trim(trimmed.slice(3, trimmed.length() - 3))
            let mut body: utf8 = ""
            let mut closed: bool = false
            cursor = cursor + 1
            while cursor < lines.length() && !closed {
                if markdown_trim(lines⁅cursor⁆).equals("```") {
                    closed = true
                } else {
                    if body.length() > 0 {
                        body = body + "\n"
                    }
                    body = body + lines⁅cursor⁆
                }
                cursor = cursor + 1
            }
            let block_id: u64 = state.gen.next
            state = MarkdownBlocks {
                gen: markdown_bump_id(state.gen),
                blocks: push(state.blocks, block_code(block_id, Some(language), body)),
                footnotes: state.footnotes
            }
        } else if markdown_heading_level(line) > 0 {
            let level: usize = markdown_heading_level(line)
            let text: utf8 = markdown_trim(line.slice(level + 1, line.length() - level - 1))
            let scan: MarkdownScan = markdown_scan_inlines(text, state.gen)
            let block_id: u64 = scan.gen.next
            state = MarkdownBlocks {
                gen: markdown_bump_id(scan.gen),
                blocks: push(state.blocks, block_heading(block_id, level, scan.items)),
                footnotes: state.footnotes
            }
            cursor = cursor + 1
        } else if trimmed.equals("---") {
            let block_id: u64 = state.gen.next
            state = MarkdownBlocks {
                gen: markdown_bump_id(state.gen),
                blocks: push(state.blocks, block_thematic_break(block_id)),
                footnotes: state.footnotes
            }
            cursor = cursor + 1
        } else if trimmed.slice(0, 2).equals("- ") {
            let mut items: [ListItem] = []
            while cursor < lines.length() && markdown_trim(lines⁅cursor⁆).slice(0, 2).equals("- ") {
                let item_text: utf8 = markdown_trim(lines⁅cursor⁆.slice(2, lines⁅cursor⁆.length() - 2))
                let scan: MarkdownScan = markdown_scan_inlines(item_text, state.gen)
                let paragraph_id: u64 = scan.gen.next
                let gen1: MarkdownIdGen = markdown_bump_id(scan.gen)
                items = push(items, list_item([block_paragraph(paragraph_id, scan.items)]))
                state = MarkdownBlocks {
                    gen: gen1,
                    blocks: state.blocks,
                    footnotes: state.footnotes
                }
                cursor = cursor + 1
            }
            let block_id: u64 = state.gen.next
            state = MarkdownBlocks {
                gen: markdown_bump_id(state.gen),
                blocks: push(state.blocks, block_list(block_id, false, 1, items)),
                footnotes: state.footnotes
            }
        } else if trimmed.slice(0, 1).equals("|") {
            let mut rows: [utf8] = []
            while cursor < lines.length() && markdown_trim(lines⁅cursor⁆).slice(0, 1).equals("|") {
                rows = push(rows, lines⁅cursor⁆)
                cursor = cursor + 1
            }
            if rows.length() >= 2 && markdown_is_table_separator(markdown_split_table_row(rows⁅1⁆)) {
                let header_cells: [utf8] = markdown_split_table_row(rows⁅0⁆)
                let mut header_row_cells: [TableCell] = []
                let mut cell_index: usize = 0
                while cell_index < header_cells.length() {
                    let scan: MarkdownScan = markdown_scan_inlines(header_cells⁅cell_index⁆, state.gen)
                    let paragraph_id: u64 = scan.gen.next
                    let gen1: MarkdownIdGen = markdown_bump_id(scan.gen)
                    header_row_cells = push(header_row_cells, table_cell([block_paragraph(paragraph_id, scan.items)], 1, 1))
                    state = MarkdownBlocks {
                        gen: gen1,
                        blocks: state.blocks,
                        footnotes: state.footnotes
                    }
                    cell_index = cell_index + 1
                }
                let mut body_rows: [TableRow] = []
                let mut row_index: usize = 2
                while row_index < rows.length() {
                    let cells: [utf8] = markdown_split_table_row(rows⁅row_index⁆)
                    let mut row_cells: [TableCell] = []
                    cell_index = 0
                    while cell_index < cells.length() {
                        let scan: MarkdownScan = markdown_scan_inlines(cells⁅cell_index⁆, state.gen)
                        let paragraph_id: u64 = scan.gen.next
                        let gen1: MarkdownIdGen = markdown_bump_id(scan.gen)
                        row_cells = push(row_cells, table_cell([block_paragraph(paragraph_id, scan.items)], 1, 1))
                        state = MarkdownBlocks {
                            gen: gen1,
                            blocks: state.blocks,
                            footnotes: state.footnotes
                        }
                        cell_index = cell_index + 1
                    }
                    body_rows = push(body_rows, table_row(row_cells, false))
                    row_index = row_index + 1
                }
                let block_id: u64 = state.gen.next
                state = MarkdownBlocks {
                    gen: markdown_bump_id(state.gen),
                    blocks: push(state.blocks, block_table(block_id, None, [table_row(header_row_cells, true)], body_rows)),
                    footnotes: state.footnotes
                }
            } else {
                let scan: MarkdownScan = markdown_scan_paragraph(rows, 0, rows.length(), state.gen)
                let block_id: u64 = scan.gen.next
                state = MarkdownBlocks {
                    gen: markdown_bump_id(scan.gen),
                    blocks: push(state.blocks, block_paragraph(block_id, scan.items)),
                    footnotes: state.footnotes
                }
            }
        } else if trimmed.slice(0, 2).equals("[^") {
            let close: Option<usize> = markdown_find(trimmed, "]", 3)
            let mut parsed: bool = false
            if close.is_some() && close.unwrap() + 1 <= trimmed.length() && trimmed[close.unwrap() + 1] == ':' {
                let key: utf8 = trimmed.slice(2, close.unwrap() - 3)
                let text: utf8 = markdown_trim(trimmed.slice(close.unwrap() + 1, trimmed.length() - close.unwrap() - 1))
                if key.length() > 0 {
                    let scan: MarkdownScan = markdown_scan_inlines(text, state.gen)
                    let paragraph_id: u64 = scan.gen.next
                    state = MarkdownBlocks {
                        gen: markdown_bump_id(scan.gen),
                        blocks: state.blocks,
                        footnotes: push(state.footnotes, footnote_definition(key, [block_paragraph(paragraph_id, scan.items)]))
                    }
                    parsed = true
                }
            }
            if !parsed {
                let scan: MarkdownScan = markdown_scan_inlines(trimmed, state.gen)
                let block_id: u64 = scan.gen.next
                state = MarkdownBlocks {
                    gen: markdown_bump_id(scan.gen),
                    blocks: push(state.blocks, block_paragraph(block_id, scan.items)),
                    footnotes: state.footnotes
                }
            }
            cursor = cursor + 1
        } else {
            let start: usize = cursor
            while cursor < lines.length() && !markdown_is_block_starter(lines⁅cursor⁆) {
                cursor = cursor + 1
            }
            let count: usize = cursor - start
            let mut joined: utf8 = ""
            let mut offset: usize = 0
            while offset < count {
                if offset > 0 {
                    joined = joined + "\n"
                }
                joined = joined + lines⁅start + offset⁆
                offset = offset + 1
            }
            let display_tex: utf8 = markdown_display_math(joined)
            if display_tex.length() > 0 {
                let mut math_state: MarkdownScan = MarkdownScan {
                    gen: state.gen,
                    items: []
                }
                math_state = markdown_math_node(math_state, display_tex, true)
                let block_id: u64 = math_state.gen.next
                state = MarkdownBlocks {
                    gen: markdown_bump_id(math_state.gen),
                    blocks: push(state.blocks, block_paragraph(block_id, math_state.items)),
                    footnotes: state.footnotes
                }
            } else {
                let scan: MarkdownScan = markdown_scan_paragraph(lines, start, count, state.gen)
                let block_id: u64 = scan.gen.next
                state = MarkdownBlocks {
                    gen: markdown_bump_id(scan.gen),
                    blocks: push(state.blocks, block_paragraph(block_id, scan.items)),
                    footnotes: state.footnotes
                }
            }
        }
    }
    return new_document(empty_document_metadata(), state.blocks, state.footnotes, [])
}
