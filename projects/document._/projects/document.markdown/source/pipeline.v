namespace document.markdown;

using std.data::{DataOutcome, data_outcome_failed, data_outcome_partial};
using std.diagnostic::{Diagnostic, Error, new_diagnostic, new_span};
using document::{Document, DocumentError, DocumentIndex};
using document.render::{RenderResult, html_emit_fields, render_number, render_prepare};

# 管线入口与三态收口：
# - `markdown_render_html`：解析（错误容许）→ `document` 模型 → `weave_render_html`。
# - `weave_render_html`：预检/编号（`document.render` 管线）；预检硬失败 → `Failed`
#   （`DocumentError` 原码转为 `Diagnostic`）；发射期诊断非空 → `Partial`，否则 `Fine`。

micro weave_error_to_diagnostic(error: DocumentError) -> Diagnostic {
    return new_diagnostic(error.code, Error, error.message + " (node " + format("{}", error.node_id) + ")", new_span(0, 0))
}

micro weave_emit_document(document: Document, index: DocumentIndex) -> WeaveOut {
    let body: WeaveOut = weave_emit_blocks(document.blocks, index, [])
    let mut out: utf8 = body.text
    let mut collected: [Diagnostic] = body.diagnostics
    if document.footnotes.length() > 0 {
        out = out + "<section class='footnotes'><ol>"
        let mut position: usize = 0
        while position < document.footnotes.length() {
            let step: WeaveOut = weave_emit_blocks(document.footnotes⁅position⁆.content, index, collected)
            collected = step.diagnostics
            out = out + "<li id='fn-" + render_number(position + 1) + "'>" + step.text + "</li>"
            position = position + 1
        }
        out = out + "</ol></section>"
    }
    if document.bibliography.length() > 0 {
        out = out + "<section class='bibliography'><ol>"
        let mut position: usize = 0
        while position < document.bibliography.length() {
            out = out + "<li id='bib-" + render_number(position + 1) + "'>" + html_emit_fields(document.bibliography⁅position⁆.fields) + "</li>"
            position = position + 1
        }
        out = out + "</ol></section>"
    }
    return weave_out(out, collected)
}

micro weave_render_html(document: Document) -> DataOutcome<utf8> {
    match render_prepare(document) {
        case Fine(payload):
            let out: WeaveOut = weave_emit_document(document, payload.value)
            return data_outcome_partial(out.text, out.diagnostics)
        case Fail(payload):
            return data_outcome_failed([weave_error_to_diagnostic(payload.error)])
    }
}

micro markdown_render_html(source: utf8) -> DataOutcome<utf8> {
    return weave_render_html(markdown_parse_document(source))
}
