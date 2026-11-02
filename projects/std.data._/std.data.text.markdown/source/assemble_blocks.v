namespace std.data.text.markdown;

using std.data::{DataCstNode, data_cst_span};
using document::{Block, Inline, ListItem, TableCell, TableRow, block_code, block_list, block_paragraph, block_table, block_thematic_break, list_item, table_cell, table_row};

# fence / 表格 / 列表的装配。

micro markdown_build_fence(node: DataCstNode<MarkdownTokenKind>, state: MarkdownBuildState) -> MarkdownBlocks {
    match node {
        case Node(payload):
            let open_text: utf8 = markdown_line_text(payload.children⁅0⁆, state)
            let trimmed: utf8 = markdown_trim(open_text)
            let mut language: utf8 = ""
            if trimmed.length() > 3 {
                language = markdown_trim(trimmed.slice(3, trimmed.length() - 3))
            }
            let mut body: utf8 = ""
            let mut index: usize = 1
            let mut stop: usize = payload.children.length()
            if payload.children.length() >= 2 {
                let last: utf8 = markdown_trim(markdown_line_text(payload.children⁅payload.children.length() - 1⁆, state))
                if last.slice(0, 3).equals("```") {
                    stop = payload.children.length() - 1
                }
            }
            while index < stop {
                if body.length() > 0 {
                    body = body + "\n"
                }
                body = body + markdown_line_text(payload.children⁅index⁆, state)
                index = index + 1
            }
            let id: u64 = markdown_take_id(state)
            let out: MarkdownBlocks = MarkdownBlocks {
                state: markdown_bump(state),
                blocks: [],
                footnotes: []
            }
            if language.length() == 0 {
                return markdown_blocks_push(out, block_code(id, None, body))
            }
            return markdown_blocks_push(out, block_code(id, Some(language), body))
        else:
            return MarkdownBlocks {
                state: state,
                blocks: [],
                footnotes: []
            }
    }
}

# 表格行切分：相邻 `Pipe` token 之间的源文本为单元；末段（最后一个
# `Pipe` 之后）非空也计为一个单元；首 `Pipe` 之前的空白忽略。
micro markdown_table_row_cells(node: DataCstNode<MarkdownTokenKind>, state: MarkdownBuildState) -> [utf8] {
    match node {
        case Node(payload):
            let mut pipes: [usize] = []
            let mut pipe_stops: [usize] = []
            let mut index: usize = 0
            while index < payload.children.length() {
                match payload.children⁅index⁆ {
                    case Token(leaf):
                        match leaf.token.kind {
                            case Pipe:
                                pipes = push(pipes, leaf.token.span.start)
                                pipe_stops = push(pipe_stops, leaf.token.span.end)
                            else:
                                pipes = pipes
                        }
                    else:
                        pipes = pipes
                }
                index = index + 1
            }
            let mut cells: [utf8] = []
            let mut segment: usize = 0
            while segment + 1 < pipes.length() {
                let cell: utf8 = markdown_trim(state.text.slice(pipe_stops⁅segment⁆, pipes⁅segment + 1⁆ - pipe_stops⁅segment⁆))
                cells = push(cells, cell)
                segment = segment + 1
            }
            if pipes.length() > 0 {
                let tail_start: usize = pipe_stops⁅pipe_stops.length() - 1⁆
                let line_stop: usize = data_cst_span(node).end
                if line_stop > tail_start {
                    let tail: utf8 = markdown_trim(state.text.slice(tail_start, line_stop - tail_start))
                    if tail.length() > 0 {
                        cells = push(cells, tail)
                    }
                }
            }
            return cells
        else:
            return []
    }
}

micro markdown_is_separator_cells(cells: [utf8]) -> bool {
    if cells.length() == 0 {
        return false
    }
    let mut index: usize = 0
    while index < cells.length() {
        if !markdown_is_separator_cell(cells⁅index⁆) {
            return false
        }
        index = index + 1
    }
    return true
}

micro markdown_is_separator_cell(text: utf8) -> bool {
    if text.length() == 0 {
        return false
    }
    let mut has_dash: bool = false
    let mut position: usize = 1
    while position <= text.length() {
        let c: char = text[position]
        if c == '-' {
            has_dash = true
        } else if c != ':' {
            return false
        }
        position = position + 1
    }
    return has_dash
}

micro markdown_build_table(node: DataCstNode<MarkdownTokenKind>, state: MarkdownBuildState) -> MarkdownBlocks {
    match node {
        case Node(payload):
            if payload.children.length() < 2 {
                return markdown_build_paragraph(node, state)
            }
            let header_cells: [utf8] = markdown_table_row_cells(payload.children⁅0⁆, state)
            let separator_cells: [utf8] = markdown_table_row_cells(payload.children⁅1⁆, state)
            if !markdown_is_separator_cells(separator_cells) {
                return markdown_build_paragraph(node, state)
            }
            let mut current: MarkdownBuildState = state
            let mut header_row_cells: [TableCell] = []
            let mut cell_index: usize = 0
            while cell_index < header_cells.length() {
                let scan: MarkdownScan = markdown_scan_inlines(header_cells⁅cell_index⁆, current)
                current = scan.state
                let paragraph_id: u64 = markdown_take_id(current)
                current = markdown_bump(current)
                header_row_cells = push(header_row_cells, table_cell([block_paragraph(paragraph_id, scan.items)], 1, 1))
                cell_index = cell_index + 1
            }
            let mut body_rows: [TableRow] = []
            let mut row_index: usize = 2
            while row_index < payload.children.length() {
                let cells: [utf8] = markdown_table_row_cells(payload.children⁅row_index⁆, current)
                let mut row_cells: [TableCell] = []
                cell_index = 0
                while cell_index < cells.length() {
                    let scan: MarkdownScan = markdown_scan_inlines(cells⁅cell_index⁆, current)
                    current = scan.state
                    let paragraph_id: u64 = markdown_take_id(current)
                    current = markdown_bump(current)
                    row_cells = push(row_cells, table_cell([block_paragraph(paragraph_id, scan.items)], 1, 1))
                    cell_index = cell_index + 1
                }
                body_rows = push(body_rows, table_row(row_cells, false))
                row_index = row_index + 1
            }
            let id: u64 = markdown_take_id(current)
            let out: MarkdownBlocks = MarkdownBlocks {
                state: markdown_bump(current),
                blocks: [],
                footnotes: []
            }
            return markdown_blocks_push(out, block_table(id, None, [table_row(header_row_cells, true)], body_rows))
        else:
            return MarkdownBlocks {
                state: state,
                blocks: [],
                footnotes: []
            }
    }
}

micro markdown_build_list(node: DataCstNode<MarkdownTokenKind>, state: MarkdownBuildState) -> MarkdownBlocks {
    match node {
        case Node(payload):
            let mut current: MarkdownBuildState = state
            let mut items: [ListItem] = []
            let mut index: usize = 0
            while index < payload.children.length() {
                let raw: utf8 = markdown_line_text(payload.children⁅index⁆, current)
                let trimmed: utf8 = markdown_trim(raw)
                let content: utf8 = markdown_trim(trimmed.slice(1, trimmed.length() - 1))
                let scan: MarkdownScan = markdown_scan_inlines(content, current)
                current = scan.state
                let paragraph_id: u64 = markdown_take_id(current)
                current = markdown_bump(current)
                items = push(items, list_item([block_paragraph(paragraph_id, scan.items)]))
                index = index + 1
            }
            let id: u64 = markdown_take_id(current)
            let out: MarkdownBlocks = MarkdownBlocks {
                state: markdown_bump(current),
                blocks: [],
                footnotes: []
            }
            return markdown_blocks_push(out, block_list(id, false, 1, items))
        else:
            return MarkdownBlocks {
                state: state,
                blocks: [],
                footnotes: []
            }
    }
}
