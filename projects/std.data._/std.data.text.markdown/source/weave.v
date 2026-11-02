namespace std.data.text.markdown;

using std.data::{DataOutcome, data_outcome_diagnostics, data_outcome_value_or};
using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};
using document::{Block, DocumentIndex, Inline, TableCell, TableRow, attribute_value};
using document.render::{html_emit_block, html_emit_inline, render_anchor_of, render_number};
using std.data.text.mermaid::{mermaid_render_svg};
using std.data.text.tex::{tex_parse_text};
using document.vector::{svg_escape_text};
using vutex::{MathNode, math_default_font, math_emit_svg, math_typeset};

# 编排发射：标准块/行内委托 `document.render` 的发射器，两个扩展点在此拦截。
# 诊断随返回值线程化（`WeaveOut`）：
# - `CodeBlock` `language = mermaid`：经 `std.data.text.mermaid` 渲染 SVG；
#   失败降级为普通代码块并记 `markdown.weave.mermaid_unsupported`（透传子诊断）。
# - `classes` 含 `math` 的 `Styled`：`tex` 属性经 `std.data.text.tex` 解析、
#   `vutex` 排版发射；行内 `<span class='math'>`，`math-display` 独占段落发
#   `<div class='math'>`；失败按源文本 code 形态降级并记 `markdown.weave.math_malformed`。
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

micro weave_concat(first: [Diagnostic], second: [Diagnostic]) -> [Diagnostic] {
    let mut out: [Diagnostic] = first
    let mut index: usize = 0
    while index < second.length() {
        out = push(out, second⁅index⁆)
        index = index + 1
    }
    return out
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

micro weave_render_math(tex: utf8, display: bool, diagnostics: [Diagnostic]) -> WeaveOut {
    let parsed: DataOutcome<MathNode> = tex_parse_text(tex)
    match parsed {
        case Fine(payload):
            let svg: utf8 = math_emit_svg(math_typeset(payload.value, math_default_font()), math_default_font())
            if display {
                return weave_out("<div class='math'>" + svg + "</div>", diagnostics)
            }
            return weave_out("<span class='math'>" + svg + "</span>", diagnostics)
        case Partial(payload):
            let svg: utf8 = math_emit_svg(math_typeset(payload.value, math_default_font()), math_default_font())
            if display {
                return weave_out("<div class='math'>" + svg + "</div>", weave_concat(diagnostics, payload.diagnostics))
            }
            return weave_out("<span class='math'>" + svg + "</span>", weave_concat(diagnostics, payload.diagnostics))
        case Failed(payload):
            let collected: [Diagnostic] = push(weave_concat(diagnostics, payload.diagnostics), new_diagnostic("markdown.weave.math_malformed", Error, "math source failed to typeset", new_span(0, 0)))
            return weave_out("<code>" + svg_escape_text(tex) + "</code>", collected)
    }
}

micro weave_render_mermaid(source: utf8, fallback: Block, index: DocumentIndex, diagnostics: [Diagnostic]) -> WeaveOut {
    let outcome: DataOutcome<utf8> = mermaid_render_svg(source)
    match outcome {
        case Fine(payload):
            return weave_out("<div class='mermaid'>" + payload.value + "</div>", diagnostics)
        case Partial(payload):
            return weave_out("<div class='mermaid'>" + payload.value + "</div>", weave_concat(diagnostics, payload.diagnostics))
        case Failed(payload):
            let collected: [Diagnostic] = push(weave_concat(diagnostics, payload.diagnostics), new_diagnostic("markdown.weave.mermaid_unsupported", Error, "mermaid source is outside the supported subset", new_span(0, 0)))
            return weave_out(html_emit_block(fallback, index), collected)
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
    return weave_render_math(tex.unwrap(), weave_classes_have(item, "math-display"), diagnostics)
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
        case CodeBlock(payload):
            let mut is_mermaid: bool = false
            if payload.language.is_some() && payload.language.unwrap().equals("mermaid") {
                is_mermaid = true
            }
            if !is_mermaid {
                return weave_out(html_emit_block(block, index), diagnostics)
            }
            return weave_render_mermaid(payload.text, block, index, diagnostics)
        case ListBlock(payload):
            return weave_emit_list_block(block, payload.ordered, payload.start, payload.items, index, diagnostics)
        case Table(payload):
            return weave_emit_table(block, payload.caption, payload.header, payload.rows, index, diagnostics)
        case QuoteBlock(payload):
            let step: WeaveOut = weave_emit_blocks(payload.content, index, diagnostics)
            return weave_out("<blockquote>" + step.text + "</blockquote>", step.diagnostics)
        case ThematicBreak:
            return weave_out(html_emit_block(block, index), diagnostics)
        case ImageBlock(payload):
            return weave_out(html_emit_block(block, index), diagnostics)
    }
}
