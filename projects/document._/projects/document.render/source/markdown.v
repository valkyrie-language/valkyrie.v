namespace document.render;

using document::{Block, Document, DocumentIndex, Inline, TableRow, document_index_citation_number};

# Markdown 目标。约定（v0）：
# - 标题 `#`×level；样式 `**`/`*`/\`/`~~`；链接 `[c](target)`，标题属性
#   用单引号形态 `[c](target 'title')`。
# - 表格为 pipe 形态，表头后补 `---` 分隔行；单元不做宽度对齐（紧凑形态）。
# - 脚注用 `[^key]` 定义与引用（键原样）；参考文献按 `[N]` 编号成区。
# - hard break 为行尾两空格 + 换行；soft break 为空格。
# - `Text` 原样输出，Markdown 特殊字符的转义是后续能力（如实记录）。

micro render_markdown(document: Document) -> RenderResult<utf8> {
    match render_prepare(document) {
        case Fine(payload):
            return render_fine(markdown_emit_document(document, payload.value))
        case Fail(payload):
            return render_fail(payload.error)
    }
}

micro markdown_emit_document(document: Document, index: DocumentIndex) -> utf8 {
    let mut out: utf8 = text_emit_blocks_markdown(document.blocks, index)
    if document.footnotes.length() > 0 {
        let mut position: usize = 0
        while position < document.footnotes.length() {
            out = out + "\n\n[^" + document.footnotes⁅position⁆.key + "]: " + markdown_plain_blocks(document.footnotes⁅position⁆.content, index)
            position = position + 1
        }
    }
    if document.bibliography.length() > 0 {
        let mut position: usize = 0
        while position < document.bibliography.length() {
            out = out + "\n\n[" + render_number(position + 1) + "] " + text_emit_fields(document.bibliography⁅position⁆.fields)
            position = position + 1
        }
    }
    return out
}

micro markdown_repeat(text: utf8, count: usize) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < count {
        out = out + text
        position = position + 1
    }
    return out
}

micro text_emit_blocks_markdown(blocks: [Block], index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < blocks.length() {
        if position > 0 {
            out = out + "\n\n"
        }
        out = out + markdown_emit_block(blocks⁅position⁆, index)
        position = position + 1
    }
    return out
}

micro markdown_plain_blocks(blocks: [Block], index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < blocks.length() {
        if position > 0 {
            out = out + " "
        }
        out = out + markdown_emit_block(blocks⁅position⁆, index)
        position = position + 1
    }
    return out
}

micro markdown_emit_block(block: Block, index: DocumentIndex) -> utf8 {
    match block.kind {
        case Heading(payload):
            return markdown_repeat("#", payload.level) + " " + markdown_emit_inlines(payload.content, index)
        case Paragraph(payload):
            return markdown_emit_inlines(payload.content, index)
        case ListBlock(payload):
            let mut out: utf8 = ""
            let mut position: usize = 0
            while position < payload.items.length() {
                let mut marker: utf8 = "- "
                if payload.ordered {
                    marker = render_number(payload.start + position) + ". "
                }
                let content: utf8 = text_emit_blocks_markdown(payload.items⁅position⁆.blocks, index)
                if position > 0 {
                    out = out + "\n"
                }
                out = out + text_prefix_lines(content, marker, text_spaces(marker.length()))
                position = position + 1
            }
            return out
        case Table(payload):
            return markdown_emit_table(payload.header, payload.rows, index)
        case CodeBlock(payload):
            let mut fence: utf8 = "```"
            if payload.language.is_some() {
                fence = fence + payload.language.unwrap()
            }
            return fence + "\n" + payload.text + "\n```"
        case QuoteBlock(payload):
            return text_prefix_lines(text_emit_blocks_markdown(payload.content, index), "> ", "> ")
        case ThematicBreak:
            return "---"
        case ImageBlock(payload):
            return markdown_emit_image(payload.source, markdown_emit_inlines(payload.alt, index), payload.title)
    }
}

micro markdown_emit_image(source: utf8, alt: utf8, title: Option<utf8>) -> utf8 {
    let mut out: utf8 = "![" + alt + "](" + source
    if title.is_some() {
        out = out + " '" + title.unwrap() + "'"
    }
    return out + ")"
}

# 表格列宽：表头与表体所有单元的最大码点数（与文本目标同语义的对齐）。
micro markdown_table_widths(header: [TableRow], rows: [TableRow], column_count: usize, index: DocumentIndex) -> [usize] {
    let mut widths: [usize] = []
    let mut column: usize = 0
    while column < column_count {
        widths = push(widths, 0)
        column = column + 1
    }
    let mut all_rows: [TableRow] = []
    let mut position: usize = 0
    while position < header.length() {
        all_rows = push(all_rows, header⁅position⁆)
        position = position + 1
    }
    position = 0
    while position < rows.length() {
        all_rows = push(all_rows, rows⁅position⁆)
        position = position + 1
    }
    position = 0
    while position < all_rows.length() {
        let cells: [utf8] = markdown_table_cells(all_rows⁅position⁆, index)
        let mut cell_index: usize = 0
        while cell_index < cells.length() {
            if cells⁅cell_index⁆.length() > widths⁅cell_index⁆ {
                widths⁅cell_index⁆ = cells⁅cell_index⁆.length()
            }
            cell_index = cell_index + 1
        }
        position = position + 1
    }
    return widths
}

micro markdown_table_row(cells: [utf8], column_count: usize, widths: [usize]) -> utf8 {
    let mut out: utf8 = "|"
    let mut position: usize = 0
    while position < column_count {
        if position < cells.length() {
            out = out + " " + text_pad_right(cells⁅position⁆, widths⁅position⁆) + " |"
        } else {
            out = out + " " + text_pad_right("", widths⁅position⁆) + " |"
        }
        position = position + 1
    }
    return out
}

micro markdown_emit_table(header: [TableRow], rows: [TableRow], index: DocumentIndex) -> utf8 {
    let mut column_count: usize = 0
    let mut position: usize = 0
    while position < header.length() {
        if header⁅position⁆.cells.length() > column_count {
            column_count = header⁅position⁆.cells.length()
        }
        position = position + 1
    }
    position = 0
    while position < rows.length() {
        if rows⁅position⁆.cells.length() > column_count {
            column_count = rows⁅position⁆.cells.length()
        }
        position = position + 1
    }

    let widths: [usize] = markdown_table_widths(header, rows, column_count, index)

    let mut out: utf8 = ""
    let mut head_position: usize = 0
    while head_position < header.length() {
        if head_position > 0 {
            out = out + "\n"
        }
        let cells: [utf8] = markdown_table_cells(header⁅head_position⁆, index)
        out = out + markdown_table_row(cells, column_count, widths)
        head_position = head_position + 1
    }
    if header.length() > 0 {
        let mut separator: utf8 = "|"
        let mut column: usize = 0
        while column < column_count {
            separator = separator + " " + markdown_repeat("-", if widths⁅column⁆ > 3 { widths⁅column⁆ } else { 3 }) + " |"
            column = column + 1
        }
        out = out + "\n" + separator
    }
    let mut row_position: usize = 0
    while row_position < rows.length() {
        let cells: [utf8] = markdown_table_cells(rows⁅row_position⁆, index)
        out = out + "\n" + markdown_table_row(cells, column_count, widths)
        row_position = row_position + 1
    }
    return out
}

micro markdown_table_cells(row: TableRow, index: DocumentIndex) -> [utf8] {
    let mut out: [utf8] = []
    let mut position: usize = 0
    while position < row.cells.length() {
        out = push(out, markdown_plain_blocks(row.cells⁅position⁆.content, index))
        position = position + 1
    }
    return out
}

micro markdown_emit_inlines(items: [Inline], index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < items.length() {
        out = out + markdown_emit_inline(items⁅position⁆, index)
        position = position + 1
    }
    return out
}

micro markdown_emit_inline(item: Inline, index: DocumentIndex) -> utf8 {
    match item.kind {
        case Text(payload):
            return payload.text
        case Styled(payload):
            let content: utf8 = markdown_emit_inlines(payload.content, index)
            match payload.style {
                case Strong:
                    return "**" + content + "**"
                case Emphasis:
                    return "*" + content + "*"
                case Code:
                    return "`" + content + "`"
                case Strike:
                    return "~~" + content + "~~"
            }
        case Link(payload):
            let mut out: utf8 = "[" + markdown_emit_inlines(payload.content, index) + "](" + payload.target
            if payload.title.is_some() {
                out = out + " '" + payload.title.unwrap() + "'"
            }
            return out + ")"
        case InlineImage(payload):
            return markdown_emit_image(payload.source, markdown_emit_inlines(payload.alt, index), payload.title)
        case Break(payload):
            if payload.hard {
                return "  \n"
            }
            return " "
        case FootnoteRef(payload):
            return "[^" + payload.key + "]"
        case CitationRef(payload):
            let mut out: utf8 = "["
            let mut position: usize = 0
            while position < payload.keys.length() {
                if position > 0 {
                    out = out + ","
                }
                let number: Option<usize> = document_index_citation_number(index, payload.keys⁅position⁆)
                if number.is_some() {
                    out = out + render_number(number.unwrap())
                }
                position = position + 1
            }
            return out + "]"
    }
}
