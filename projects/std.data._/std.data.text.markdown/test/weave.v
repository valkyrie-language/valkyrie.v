namespace std.data.text.markdown;

using std.data::{DataOutcome, data_outcome_value_or};
using std.diagnostic::{Diagnostic};
using document::{Document};
using std.data.text.mermaid::{mermaid_render_svg};
using std.data.text.tex::{tex_parse_text};
using document.vector::{svg_document, svg_rect, svg_text};
using vutex::{MathNode, math_default_font, math_emit_svg, math_row, math_typeset};

# 端到端 fixture：标题/表格/脚注/flowchart/分式的完整 HTML 产物断言。

micro markdown_fixture_source() -> utf8 {
    return "# Guide\n\nIntro **bold** $x^{2}$ end.\n\n| Name | Value |\n| --- | --- |\n| a | 1 |\n\nNote ref[^n1].\n\n[^n1]: note text\n\n```mermaid\ngraph TD\nA[Start] --> B[End]\n```\n\n$$\n\\frac{1}{x}\n$$\n"
}

micro markdown_fixture_expected() -> utf8 {
    let math_svg: utf8 = math_emit_svg(math_typeset(data_outcome_value_or(tex_parse_text("x^{2}"), math_row([])), math_default_font()), math_default_font())
    let mermaid_svg: utf8 = data_outcome_value_or(mermaid_render_svg("graph TD\nA[Start] --> B[End]"), "")
    let display_svg: utf8 = math_emit_svg(math_typeset(data_outcome_value_or(tex_parse_text("\\frac{1}{x}"), math_row([])), math_default_font()), math_default_font())
    return "<h1 id='1'>Guide</h1>"
        + "<p>Intro <strong>bold</strong> <span class='math'>" + math_svg + "</span> end.</p>"
        + "<table><thead><tr><th><p>Name</p></th><th><p>Value</p></th></tr></thead><tbody><tr><td><p>a</p></td><td><p>1</p></td></tr></tbody></table>"
        + "<p>Note ref<sup><a href='#fn-1' id='fnref-1'>1</a></sup>.</p>"
        + "<div class='mermaid'>" + mermaid_svg + "</div>"
        + "<div class='math'>" + display_svg + "</div>"
        + "<section class='footnotes'><ol><li id='fn-1'><p>note text</p></li></ol></section>"
}

[test]
micro fixture_full_document_matches_byte_for_byte() -> unit {
    let outcome: DataOutcome<utf8> = markdown_render_html(markdown_fixture_source())
    match outcome {
        case Fine(payload):
            if !payload.value.equals(markdown_fixture_expected()) {
                panic("fixture html matches the expected bytes")
            }
        case Partial(payload):
            panic("clean fixture must render without diagnostics")
        case Failed(payload):
            panic("clean fixture must render")
    }
}

[test]
micro fixture_is_deterministic() -> unit {
    let first: DataOutcome<utf8> = markdown_render_html(markdown_fixture_source())
    let second: DataOutcome<utf8> = markdown_render_html(markdown_fixture_source())
    match first {
        case Fine(payload):
            match second {
                case Fine(again):
                    if !payload.value.equals(again.value) {
                        panic("same input renders the same bytes")
                    }
                case Partial(again):
                    panic("second render must stay fine")
                case Failed(again):
                    panic("second render must stay fine")
            }
        case Partial(payload):
            panic("fixture must render fine")
        case Failed(payload):
            panic("fixture must render fine")
    }
}

[test]
micro mermaid_outside_subset_degrades_with_diagnostic() -> unit {
    let outcome: DataOutcome<utf8> = markdown_render_html("```mermaid\ngraph LR\nA --> B\n```\n")
    match outcome {
        case Partial(payload):
            if payload.diagnostics.length() == 0 {
                panic("unsupported mermaid reports diagnostics")
            }
            let last: Diagnostic = payload.diagnostics⁅payload.diagnostics.length() - 1⁆
            if !last.code.equals("markdown.weave.mermaid_unsupported") {
                panic("diagnostic carries the mermaid code")
            }
            if !payload.value.equals("<pre><code class='language-mermaid'>graph LR\nA --&gt; B</code></pre>") {
                panic("unsupported mermaid degrades to a code block")
            }
        case Fine(payload):
            panic("unsupported mermaid must produce a diagnostic")
        case Failed(payload):
            panic("degraded mermaid must still render")
    }
}

[test]
micro malformed_math_renders_partial_with_diagnostic() -> unit {
    let outcome: DataOutcome<utf8> = markdown_render_html("a $x^$ b\n")
    match outcome {
        case Partial(payload):
            if payload.diagnostics.length() == 0 {
                panic("malformed math reports diagnostics")
            }
            let mut found: bool = false
            let mut index: usize = 0
            while index < payload.diagnostics.length() {
                if payload.diagnostics⁅index⁆.code.equals("tex.parse.missing_atom") {
                    found = true
                }
                index = index + 1
            }
            if !found {
                panic("diagnostic carries the tex parse code")
            }
            if !payload.value.slice(0, 22).equals("<p>a <span class='mat") {
                panic("partial math still renders in place")
            }
        case Fine(payload):
            panic("malformed math must produce a diagnostic")
        case Failed(payload):
            panic("partial math must still render")
    }
}

[test]
micro undefined_footnote_fails_structured() -> unit {
    let outcome: DataOutcome<utf8> = markdown_render_html("ref[^nope]\n")
    match outcome {
        case Failed(payload):
            if payload.diagnostics.length() != 1 {
                panic("one diagnostic for the undefined footnote")
            }
            if !payload.diagnostics⁅0⁆.code.equals("document.error.undefined_footnote") {
                panic("diagnostic keeps the model error code")
            }
        case Fine(payload):
            panic("undefined footnote must fail")
        case Partial(payload):
            panic("undefined footnote must fail")
    }
}
