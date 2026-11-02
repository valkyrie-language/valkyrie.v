namespace document.markdown;

using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};
using document::{Block, Document, DocumentIndex, Inline, TableCell, TableRow, attribute_value};
using document.render::{html_emit_block, html_emit_inline, render_anchor_of, render_number};
using document.mermaid::{mermaid_render_svg};
using document.vector::{svg_escape_text};
using vutex::{math_default_font, math_render_svg};

# 编排发射：标准块/行内委托 `document.render` 的发射器，两个产品侧扩展点在此
# 拦截。诊断随返回值线程化（`WeaveOut`）：
# - `CodeBlock` `language = mermaid`：成功发 `<div class='mermaid'>SVG</div>`；失败
#   降级为普通代码块并记 `document.markdown.mermaid_unsupported`。
# - `classes` 含 `math` 的 `Styled`：`tex` 属性送 vutex；行内发 `<span class='math'>`，
#   `math-display` 发 `<div class='math'>`；失败按源文本 code 形态降级并记
#   `document.markdown.math_malformed`。
# 诊断位置：模型节点不带源位置，span 取零宽哨兵，上下文写入 message。

structure WeaveOut {
    text: utf8
    diagnostics: [Diagnostic]
}

micro weave_out(text: utf8, diagnostics: [Diagnostic]) -> WeaveOut {
    return WeaveOut {
        text: text,
        diagnostics: diagnostics
    }
}

micro weave_classes_have(item: Inline, name: utf8) -> bool {
    let mut index: usize = 0
    while index < item.classes.length() {
        if item.classes⁅index⁆.equals(name) {
            return true
        }
        index = index + 1
    }
    return false
}

micro weave_is_math(item: Inline) -> bool {
    match item.kind {
        case Styled(payload):
            return weave_classes_have(item, "math")
        else:
            return false
    }
}

micro weave_emit_inline(item: Inline, index: DocumentIndex, diagnostics: [Diagnostic]) -> WeaveOut {
    if !weave_is_math(item) {
        return weave_out(html_emit_inline(item, index), diagnostics)
    }
    let tex: Option<utf8> = attribute_value(item.attributes, "tex")
    if tex.is_none() {
        return weave_out(html_emit_inline(item, index), diagnostics)
    }
    let rendered: Option<utf8> = math_render_svg(tex.unwrap(), math_default_font())
    if rendered.is_some() {
        if weave_classes_have(item, "math-display") {
            return weave_out("<div class='math'>" + rendered.unwrap() + "</div>", diagnostics)
        }
        return weave_out("<span class='math'>" + rendered.unwrap() + "</span>", diagnostics)
    }
    return weave_out("<code>" + svg_escape_text(tex.unwrap()) + "</code>", push(diagnostics, new_diagnostic("document.markdown.math_malformed", Error, "math source failed to typeset", new_span(0, 0))))
}

micro weave_emit_inlines(items: [Inline], index: DocumentIndex, diagnostics: [Diagnostic]) -> WeaveOut {
    let mut out: utf8 = ""
    let mut collected: [Diagnostic] = diagnostics
    let mut position: usize = 0
    while position < items.length() {
        let step: WeaveOut = weave_emit_inline(items⁅position⁆, index, collected)
        out = out + step.text
        collected = step.diagnostics
        position = position + 1
    }
    return weave_out(out, collected)
}

micro weave_emit_blocks(blocks: [Block], index: DocumentIndex, diagnostics: [Diagnostic]) -> WeaveOut {
    let mut out: utf8 = ""
    let mut collected: [Diagnostic] = diagnostics
    let mut position: usize = 0
    while position < blocks.length() {
        let step: WeaveOut = weave_emit_block(blocks⁅position⁆, index, collected)
        out = out + step.text
        collected = step.diagnostics
        position = position + 1
    }
    return weave_out(out, collected)
}

micro weave_emit_table_rows(rows: [TableRow], head: bool, index: DocumentIndex, diagnostics: [Diagnostic]) -> WeaveOut {
    let mut out: utf8 = ""
    let mut collected: [Diagnostic] = diagnostics
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
            let step: WeaveOut = weave_emit_blocks(cell.content, index, collected)
            collected = step.diagnostics
            out = out + open + ">" + step.text + "</" + tag + ">"
            cell_index = cell_index + 1
        }
        out = out + "</tr>"
        position = position + 1
    }
    return weave_out(out, collected)
}

micro weave_emit_block(block: Block, index: DocumentIndex, diagnostics: [Diagnostic]) -> WeaveOut {
    match block.kind {
        case Heading(payload):
            let level: utf8 = render_number(payload.level)
            let anchor: utf8 = render_anchor_of(index, block.id)
            let mut open: utf8 = "<h" + level
            if !anchor.equals("") {
                open = open + " id='" + anchor + "'"
            }
            let step: WeaveOut = weave_emit_inlines(payload.content, index, diagnostics)
            return weave_out(open + ">" + step.text + "</h" + level + ">", step.diagnostics)
        case Paragraph(payload):
            if payload.content.length() == 1 && weave_is_math(payload.content⁅0⁆) && weave_classes_have(payload.content⁅0⁆, "math-display") {
                # 展示级数学独占段落：直发 `<div class='math'>`，不套 `<p>`。
                return weave_emit_inline(payload.content⁅0⁆, index, diagnostics)
            }
            let step: WeaveOut = weave_emit_inlines(payload.content, index, diagnostics)
            return weave_out("<p>" + step.text + "</p>", step.diagnostics)
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
            let mut collected: [Diagnostic] = diagnostics
            let mut position: usize = 0
            while position < payload.items.length() {
                let step: WeaveOut = weave_emit_blocks(payload.items⁅position⁆.blocks, index, collected)
                collected = step.diagnostics
                out = out + "<li>" + step.text + "</li>"
                position = position + 1
            }
            return weave_out(out + "</" + tag + ">", collected)
        case Table(payload):
            let mut out: utf8 = "<table>"
            if payload.caption.is_some() {
                out = out + "<caption>" + svg_escape_text(payload.caption.unwrap()) + "</caption>"
            }
            let mut collected: [Diagnostic] = diagnostics
            if payload.header.length() > 0 {
                let head_step: WeaveOut = weave_emit_table_rows(payload.header, true, index, collected)
                collected = head_step.diagnostics
                out = out + "<thead>" + head_step.text + "</thead>"
            }
            let body_step: WeaveOut = weave_emit_table_rows(payload.rows, false, index, collected)
            collected = body_step.diagnostics
            out = out + "<tbody>" + body_step.text + "</tbody></table>"
            return weave_out(out, collected)
        case CodeBlock(payload):
            let mut is_mermaid: bool = false
            if payload.language.is_some() && payload.language.unwrap().equals("mermaid") {
                is_mermaid = true
            }
            if !is_mermaid {
                return weave_out(html_emit_block(block, index), diagnostics)
            }
            let rendered: Option<utf8> = mermaid_render_svg(payload.text)
            if rendered.is_some() {
                return weave_out("<div class='mermaid'>" + rendered.unwrap() + "</div>", diagnostics)
            }
            return weave_out(html_emit_block(block, index), push(diagnostics, new_diagnostic("document.markdown.mermaid_unsupported", Error, "mermaid source is outside the supported subset", new_span(0, 0))))
        case QuoteBlock(payload):
            let step: WeaveOut = weave_emit_blocks(payload.content, index, diagnostics)
            return weave_out("<blockquote>" + step.text + "</blockquote>", step.diagnostics)
        case ThematicBreak:
            return weave_out(html_emit_block(block, index), diagnostics)
        case ImageBlock(payload):
            return weave_out(html_emit_block(block, index), diagnostics)
    }
}
