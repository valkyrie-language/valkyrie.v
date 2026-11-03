namespace document.render;

using document::{Block, Document, DocumentAttribute, DocumentIndex, Inline, TableCell, TableRow, document_index_citation_number, document_index_footnote_number};

# 纯文本目标（R21）：列表标记 `-` / `N.`、缩进 2 空格/级；表格为 `|` 分隔的
# 字符网格（列宽取内容最大码点数）；代码块原样 fenced；hard break 换行、
# soft break 空格；脚注与参考文献各自成区，编号与正文引用一致。
# 行内图片 v0 形态 `[image: alt]`；表格不渲染表头分隔行。

micro render_text(document: Document) -> RenderResult<utf8> {
    match render_prepare(document) {
        case Fine(payload):
            return render_fine(text_emit_document(document, payload.value))
        case Fail(payload):
            return render_fail(payload.error)
    }
}

micro text_emit_document(document: Document, index: DocumentIndex) -> utf8 {
    let mut out: utf8 = text_emit_blocks(document.blocks, index)
    if document.footnotes.length() > 0 {
        let mut position: usize = 0
        while position < document.footnotes.length() {
            out = out + "\n\n[" + render_number(position + 1) + "] " + text_plain_blocks(document.footnotes⁅position⁆.content, index)
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

micro text_emit_fields(fields: [DocumentAttribute]) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < fields.length() {
        if position > 0 {
            out = out + "; "
        }
        out = out + fields⁅position⁆.name + ": " + fields⁅position⁆.value
        position = position + 1
    }
    return out
}

micro text_emit_blocks(blocks: [Block], index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < blocks.length() {
        if position > 0 {
            out = out + "\n\n"
        }
        out = out + text_emit_block(blocks⁅position⁆, index)
        position = position + 1
    }
    return out
}

# 列表项内容按紧凑形态连接：项内块间不插空行，嵌套列表直接挂在上一块之下
# （与 HTML `<li>` 内顺序块的语义等价；项内多个段落本模型不区分松/紧）。
micro text_emit_blocks_tight(blocks: [Block], index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < blocks.length() {
        if position > 0 {
            out = out + "\n"
        }
        out = out + text_emit_block(blocks⁅position⁆, index)
        position = position + 1
    }
    return out
}

# 块文本的单行投影（表格单元、脚注行等单行场景）。
micro text_plain_blocks(blocks: [Block], index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < blocks.length() {
        if position > 0 {
            out = out + " "
        }
        out = out + text_emit_block(blocks⁅position⁆, index)
        position = position + 1
    }
    return out
}

micro text_split_lines(text: utf8) -> [utf8] {
    let mut out: [utf8] = []
    let mut current: utf8 = ""
    let mut position: usize = 1
    let length: usize = text.length()
    while position <= length {
        let c: char = text[position]
        if c == '\n' {
            out = push(out, current)
            current = ""
        } else {
            current = current + std::text::encode_char_as_utf8(c)
        }
        position = position + 1
    }
    out = push(out, current)
    return out
}

# 逐行加前缀：首行 `first`，其余行 `rest`。
micro text_prefix_lines(text: utf8, first: utf8, rest: utf8) -> utf8 {
    let lines: [utf8] = text_split_lines(text)
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < lines.length() {
        if position > 0 {
            out = out + "\n" + rest
        } else {
            out = first
        }
        out = out + lines⁅position⁆
        position = position + 1
    }
    return out
}

micro text_spaces(count: usize) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < count {
        out = out + " "
        position = position + 1
    }
    return out
}

micro text_pad_right(text: utf8, width: usize) -> utf8 {
    let length: usize = text.length()
    if length >= width {
        return text
    }
    return text + text_spaces(width - length)
}

micro text_emit_block(block: Block, index: DocumentIndex) -> utf8 {
    match block.kind {
        case Heading(payload):
            return text_emit_inlines(payload.content, index)
        case Paragraph(payload):
            return text_emit_inlines(payload.content, index)
        case ListBlock(payload):
            let mut out: utf8 = ""
            let mut position: usize = 0
            while position < payload.items.length() {
                let mut marker: utf8 = "- "
                if payload.ordered {
                    marker = render_number(payload.start + position) + ". "
                }
                let content: utf8 = text_emit_blocks_tight(payload.items⁅position⁆.blocks, index)
                if position > 0 {
                    out = out + "\n"
                }
                out = out + text_prefix_lines(content, marker, text_spaces(marker.length()))
                position = position + 1
            }
            return out
        case Table(payload):
            return text_emit_table(payload.header, payload.rows, index)
        case CodeBlock(payload):
            let mut fence: utf8 = "```"
            if payload.language.is_some() {
                fence = fence + payload.language.unwrap()
            }
            return fence + "\n" + payload.text + "\n```"
        case QuoteBlock(payload):
            return text_prefix_lines(text_emit_blocks(payload.content, index), "> ", "> ")
        case ThematicBreak:
            return "---"
        case ImageBlock(payload):
            return "[image: " + text_emit_inlines(payload.alt, index) + "]"
    }
}

micro text_emit_table(header: [TableRow], rows: [TableRow], index: DocumentIndex) -> utf8 {
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

    let mut column_count: usize = 0
    position = 0
    while position < all_rows.length() {
        if all_rows⁅position⁆.cells.length() > column_count {
            column_count = all_rows⁅position⁆.cells.length()
        }
        position = position + 1
    }

    let mut widths: [usize] = []
    let mut column: usize = 0
    while column < column_count {
        widths = push(widths, 0)
        column = column + 1
    }
    position = 0
    while position < all_rows.length() {
        let cells: [TableCell] = all_rows⁅position⁆.cells
        let mut cell_index: usize = 0
        while cell_index < cells.length() {
            let width: usize = text_plain_blocks(cells⁅cell_index⁆.content, index).length()
            if width > widths⁅cell_index⁆ {
                widths⁅cell_index⁆ = width
            }
            cell_index = cell_index + 1
        }
        position = position + 1
    }

    let mut out: utf8 = ""
    position = 0
    while position < all_rows.length() {
        if position > 0 {
            out = out + "\n"
        }
        let cells: [TableCell] = all_rows⁅position⁆.cells
        let mut cell_index: usize = 0
        let mut line: utf8 = ""
        while cell_index < column_count {
            if cell_index > 0 {
                line = line + " | "
            }
            if cell_index < cells.length() {
                line = line + text_pad_right(text_plain_blocks(cells⁅cell_index⁆.content, index), widths⁅cell_index⁆)
            } else {
                line = line + text_spaces(widths⁅cell_index⁆)
            }
            cell_index = cell_index + 1
        }
        out = out + "| " + line + " |"
        position = position + 1
    }
    return out
}

micro text_emit_inlines(items: [Inline], index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < items.length() {
        out = out + text_emit_inline(items⁅position⁆, index)
        position = position + 1
    }
    return out
}

micro text_emit_inline(item: Inline, index: DocumentIndex) -> utf8 {
    match item.kind {
        case Text(payload):
            return payload.text
        case Styled(payload):
            return text_emit_inlines(payload.content, index)
        case Link(payload):
            return text_emit_inlines(payload.content, index)
        case InlineImage(payload):
            return "[image: " + text_emit_inlines(payload.alt, index) + "]"
        case Break(payload):
            if payload.hard {
                return "\n"
            }
            return " "
        case FootnoteRef(payload):
            let number: Option<usize> = document_index_footnote_number(index, payload.key)
            if number.is_none() {
                return ""
            }
            return "[" + render_number(number.unwrap()) + "]"
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
