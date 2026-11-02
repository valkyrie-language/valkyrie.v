namespace std.data.text.markdown;

using std.data::{DataCstNode, DataOutcome, DataSettings, DataSource, data_cst_span, data_outcome_partial};
using std.diagnostic::{Span};
using document::{Block, Document, FootnoteDefinition, Inline, ListItem, TableCell, TableRow, block_code, block_heading, block_list, block_paragraph, block_table, block_thematic_break, empty_document_metadata, footnote_definition, inline_break, list_item, new_document, table_cell, table_row};

# 模型装配：`NodeDocument` 子节点 -> 块序列与脚注表。
# 段落级 `$$...$$` 检测：拼接文本 trim 后两端恰为 `$$` 且内容非空。

structure MarkdownBlocks {
    state: MarkdownBuildState
    blocks: [Block]
    footnotes: [FootnoteDefinition]
}

micro markdown_blocks_push(out: MarkdownBlocks, block: Block) -> MarkdownBlocks {
    return MarkdownBlocks {
        state: out.state,
        blocks: push(out.blocks, block),
        footnotes: out.footnotes
    }
}

# 行 token 的可见文本（span 切片；首尾空白在建模处 trim）。
micro markdown_line_text(node: DataCstNode<MarkdownTokenKind>, state: MarkdownBuildState) -> utf8 {
    let span: Span = data_cst_span(node)
    return state.text.slice(span.start, span.end - span.start)
}

micro markdown_heading_level_of(node: DataCstNode<MarkdownTokenKind>) -> usize {
    match node {
        case Node(payload):
            if payload.children.length() == 0 {
                return 1
            }
            match payload.children⁅0⁆ {
                case Token(leaf):
                    return leaf.token.span.end - leaf.token.span.start
                else:
                    return 1
            }
        else:
            return 1
    }
}

micro markdown_build_heading(node: DataCstNode<MarkdownTokenKind>, state: MarkdownBuildState) -> MarkdownBlocks {
    let level: usize = markdown_heading_level_of(node)
    let raw: utf8 = markdown_line_text(node, state)
    let title: utf8 = markdown_trim(raw.slice(level + 1, raw.length() - level - 1))
    let scan: MarkdownScan = markdown_scan_inlines(title, state)
    let id: u64 = markdown_take_id(scan.state)
    let out: MarkdownBlocks = MarkdownBlocks {
        state: markdown_bump(scan.state),
        blocks: [],
        footnotes: []
    }
    return markdown_blocks_push(out, block_heading(id, level, scan.items))
}

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

# 段落内容：`children` 为行级 Text token；行间插 soft `Break`。
micro markdown_scan_paragraph_lines(children: [DataCstNode<MarkdownTokenKind>], state: MarkdownBuildState) -> MarkdownScan {
    let mut scan: MarkdownScan = MarkdownScan {
        state: state,
        items: []
    }
    let mut index: usize = 0
    while index < children.length() {
        if index > 0 {
            let break_id: u64 = markdown_take_id(scan.state)
            scan = MarkdownScan {
                state: markdown_bump(scan.state),
                items: push(scan.items, inline_break(break_id, false))
            }
        }
        let line: utf8 = markdown_line_text(children⁅index⁆, scan.state)
        scan = markdown_scan_inlines(line, scan.state)
        index = index + 1
    }
    return scan
}

micro markdown_joined_lines(children: [DataCstNode<MarkdownTokenKind>], state: MarkdownBuildState) -> utf8 {
    let mut out: utf8 = ""
    let mut index: usize = 0
    while index < children.length() {
        if index > 0 {
            out = out + "\n"
        }
        out = out + markdown_line_text(children⁅index⁆, state)
        index = index + 1
    }
    return out
}

micro markdown_try_footnote_def(text: utf8) -> Option<utf8> {
    if !text.slice(0, 2).equals("[^") {
        return None
    }
    let close: Option<usize> = markdown_find(text, "]", 3)
    if close.is_none() {
        return None
    }
    if close.unwrap() + 1 > text.length() || text[close.unwrap() + 1] != ':' {
        return None
    }
    let key: utf8 = text.slice(2, close.unwrap() - 3)
    if key.length() == 0 {
        return None
    }
    return Some(key)
}

micro markdown_build_paragraph(node: DataCstNode<MarkdownTokenKind>, state: MarkdownBuildState) -> MarkdownBlocks {
    match node {
        case Node(payload):
            let joined: utf8 = markdown_joined_lines(payload.children, state)
            if payload.children.length() == 1 {
                let key: Option<utf8> = markdown_try_footnote_def(markdown_trim(joined))
                if key.is_some() {
                    let trimmed: utf8 = markdown_trim(joined)
                    let close: usize = markdown_find(trimmed, "]", 3).unwrap()
                    let content: utf8 = markdown_trim(trimmed.slice(close + 1, trimmed.length() - close - 1))
                    let scan: MarkdownScan = markdown_scan_inlines(content, state)
                    let paragraph_id: u64 = markdown_take_id(scan.state)
                    return MarkdownBlocks {
                        state: markdown_bump(scan.state),
                        blocks: [],
                        footnotes: [footnote_definition(key.unwrap(), [block_paragraph(paragraph_id, scan.items)])]
                    }
                }
            }
            let display_tex: utf8 = markdown_display_math(joined)
            if display_tex.length() > 0 {
                let empty_scan: MarkdownScan = MarkdownScan {
                    state: state,
                    items: []
                }
                let math_scan: MarkdownScan = markdown_math_node(empty_scan, display_tex, true)
                let block_id: u64 = markdown_take_id(math_scan.state)
                let out: MarkdownBlocks = MarkdownBlocks {
                    state: markdown_bump(math_scan.state),
                    blocks: [],
                    footnotes: []
                }
                return markdown_blocks_push(out, block_paragraph(block_id, math_scan.items))
            }
            let scan: MarkdownScan = markdown_scan_paragraph_lines(payload.children, state)
            let block_id: u64 = markdown_take_id(scan.state)
            let out: MarkdownBlocks = MarkdownBlocks {
                state: markdown_bump(scan.state),
                blocks: [],
                footnotes: []
            }
            return markdown_blocks_push(out, block_paragraph(block_id, scan.items))
        else:
            return MarkdownBlocks {
                state: state,
                blocks: [],
                footnotes: []
            }
    }
}
