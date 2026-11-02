namespace document.render;

using document::{Block, BibliographyEntry, Document, DocumentAttribute, DocumentIndex, FootnoteDefinition, Inline, InlineStyle, ListItem, TableCell, TableRow, document_index_citation_number, document_index_footnote_number, inline_plain_all};
using document.vector::{svg_escape_attribute, svg_escape_text};

# HTML 目标：连续流不分页（R17）。标签映射按 R20；转义按 R18（`&` `<` `>` 与
# 属性值内的 `'`）；URI 属性原样引用（R19）；`#` 开头 anchor 原样输出（R7）。
# 输出形态：body 片段（不含 `<html>`/`<head>` 包装），元素间无多余空白。

micro render_html(document: Document) -> RenderResult<utf8> {
    match render_prepare(document) {
        case Fine(payload):
            return render_fine(html_emit_document(document, payload.value))
        case Fail(payload):
            return render_fail(payload.error)
    }
}

micro html_emit_document(document: Document, index: DocumentIndex) -> utf8 {
    let mut out: utf8 = html_emit_blocks(document.blocks, index)
    if document.footnotes.length() > 0 {
        out = out + "<section class='footnotes'><ol>"
        let mut position: usize = 0
        while position < document.footnotes.length() {
            let definition: FootnoteDefinition = document.footnotes⁅position⁆
            let number: utf8 = render_number(position + 1)
            out = out + "<li id='fn-" + number + "'>" + html_emit_blocks(definition.content, index) + "</li>"
            position = position + 1
        }
        out = out + "</ol></section>"
    }
    if document.bibliography.length() > 0 {
        out = out + "<section class='bibliography'><ol>"
        let mut position: usize = 0
        while position < document.bibliography.length() {
            let entry: BibliographyEntry = document.bibliography⁅position⁆
            out = out + "<li id='bib-" + render_number(position + 1) + "'>" + html_emit_fields(entry.fields) + "</li>"
            position = position + 1
        }
        out = out + "</ol></section>"
    }
    return out
}

# 参考文献字段 v0 形态：`name: value` 对按 `; ` 连接，内容转义。
micro html_emit_fields(fields: [DocumentAttribute]) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < fields.length() {
        if position > 0 {
            out = out + "; "
        }
        out = out + svg_escape_text(fields⁅position⁆.name) + ": " + svg_escape_text(fields⁅position⁆.value)
        position = position + 1
    }
    return out
}

micro html_emit_blocks(blocks: [Block], index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < blocks.length() {
        out = out + html_emit_block(blocks⁅position⁆, index)
        position = position + 1
    }
    return out
}

micro html_emit_block(block: Block, index: DocumentIndex) -> utf8 {
    match block.kind {
        case Heading(payload):
            let level: utf8 = render_number(payload.level)
            let anchor: utf8 = render_anchor_of(index, block.id)
            let mut open: utf8 = "<h" + level
            if !anchor.equals("") {
                open = open + " id='" + anchor + "'"
            }
            return open + ">" + html_emit_inlines(payload.content, index) + "</h" + level + ">"
        case Paragraph(payload):
            return "<p>" + html_emit_inlines(payload.content, index) + "</p>"
        case ListBlock(payload):
            let mut tag: utf8 = "ul"
            let mut open: utf8 = "<ul"
            if payload.ordered {
                tag = "ol"
                open = "<ol"
            }
            if payload.ordered && payload.start != 1 {
                open = open + " start='" + render_number(payload.start) + "'"
            }
            let mut out: utf8 = open + ">"
            let mut position: usize = 0
            while position < payload.items.length() {
                out = out + "<li>" + html_emit_blocks(payload.items⁅position⁆.blocks, index) + "</li>"
                position = position + 1
            }
            return out + "</" + tag + ">"
        case Table(payload):
            let mut out: utf8 = "<table>"
            if payload.caption.is_some() {
                out = out + "<caption>" + svg_escape_text(payload.caption.unwrap()) + "</caption>"
            }
            if payload.header.length() > 0 {
                out = out + "<thead>" + html_emit_table_rows(payload.header, true, index) + "</thead>"
            }
            out = out + "<tbody>" + html_emit_table_rows(payload.rows, false, index) + "</tbody></table>"
            return out
        case CodeBlock(payload):
            let mut open: utf8 = "<pre><code"
            if payload.language.is_some() {
                open = open + " class='language-" + svg_escape_attribute(payload.language.unwrap()) + "'"
            }
            return open + ">" + svg_escape_text(payload.text) + "</code></pre>"
        case QuoteBlock(payload):
            return "<blockquote>" + html_emit_blocks(payload.content, index) + "</blockquote>"
        case ThematicBreak:
            return "<hr/>"
        case ImageBlock(payload):
            return html_emit_image(payload.source, payload.alt, payload.title)
    }
}

micro html_emit_table_rows(rows: [TableRow], head: bool, index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < rows.length() {
        out = out + "<tr>"
        let row: TableRow = rows⁅position⁆
        let mut cell_index: usize = 0
        while cell_index < row.cells.length() {
            let cell: TableCell = row.cells⁅cell_index⁆
            let mut tag: utf8 = "td"
            if head || row.is_header {
                tag = "th"
            }
            let mut open: utf8 = "<" + tag
            if cell.colspan > 1 {
                open = open + " colspan='" + render_number(cell.colspan) + "'"
            }
            if cell.rowspan > 1 {
                open = open + " rowspan='" + render_number(cell.rowspan) + "'"
            }
            out = out + open + ">" + html_emit_blocks(cell.content, index) + "</" + tag + ">"
            cell_index = cell_index + 1
        }
        out = out + "</tr>"
        position = position + 1
    }
    return out
}

micro html_emit_image(source: utf8, alt: [Inline], title: Option<utf8>) -> utf8 {
    let mut out: utf8 = "<img src='" + svg_escape_attribute(source)
        + "' alt='" + svg_escape_attribute(inline_plain_all(alt)) + "'"
    if title.is_some() {
        out = out + " title='" + svg_escape_attribute(title.unwrap()) + "'"
    }
    return out + "/>"
}

micro html_emit_inlines(items: [Inline], index: DocumentIndex) -> utf8 {
    let mut out: utf8 = ""
    let mut position: usize = 0
    while position < items.length() {
        out = out + html_emit_inline(items⁅position⁆, index)
        position = position + 1
    }
    return out
}

micro html_emit_inline(item: Inline, index: DocumentIndex) -> utf8 {
    match item.kind {
        case Text(payload):
            return svg_escape_text(payload.text)
        case Styled(payload):
            let content: utf8 = html_emit_inlines(payload.content, index)
            match payload.style {
                case Strong:
                    return "<strong>" + content + "</strong>"
                case Emphasis:
                    return "<em>" + content + "</em>"
                case Code:
                    return "<code>" + content + "</code>"
                case Strike:
                    return "<s>" + content + "</s>"
            }
        case Link(payload):
            let mut open: utf8 = "<a href='" + svg_escape_attribute(payload.target) + "'"
            if payload.title.is_some() {
                open = open + " title='" + svg_escape_attribute(payload.title.unwrap()) + "'"
            }
            return open + ">" + html_emit_inlines(payload.content, index) + "</a>"
        case InlineImage(payload):
            return html_emit_image(payload.source, payload.alt, payload.title)
        case Break(payload):
            if payload.hard {
                return "<br/>"
            }
            return " "
        case FootnoteRef(payload):
            let number: Option<usize> = document_index_footnote_number(index, payload.key)
            if number.is_none() {
                return ""
            }
            let label: utf8 = render_number(number.unwrap())
            return "<sup><a href='#fn-" + label + "' id='fnref-" + label + "'>" + label + "</a></sup>"
        case CitationRef(payload):
            let mut out: utf8 = "<sup>["
            let mut position: usize = 0
            while position < payload.keys.length() {
                if position > 0 {
                    out = out + ","
                }
                let number: Option<usize> = document_index_citation_number(index, payload.keys⁅position⁆)
                if number.is_some() {
                    let label: utf8 = render_number(number.unwrap())
                    out = out + "<a href='#bib-" + label + "'>" + label + "</a>"
                }
                position = position + 1
            }
            return out + "]</sup>"
    }
}
