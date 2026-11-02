namespace std.data.text.tex;

using std.data::{DataOutcome, data_outcome_diagnostics, data_outcome_value_or};
using std.diagnostic::{Diagnostic};
using vutex::{MathNode, math_default_font, math_emit_svg, math_row, math_typeset};
using document.vector::{svg_document, svg_rect, svg_text};

micro tex_svg_of(source: utf8) -> utf8 {
    let outcome: DataOutcome<MathNode> = tex_parse_text(source)
    let node: MathNode = data_outcome_value_or(outcome, math_row([]))
    return math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
}

[test]
micro snapshot_script() -> unit {
    let expected: utf8 = svg_document(25.5, 21.0,
        svg_text(4.0, 15.0, "x", "#000000", 10.0)
        + svg_text(14.0, 10.0, "2", "#000000", 7.5))
    if !tex_svg_of("x^{2}").equals(expected) {
        panic("script svg snapshot matches")
    }
}

[test]
micro snapshot_frac() -> unit {
    let expected: utf8 = svg_document(18.0, 30.5,
        svg_text(4.0, 12.0, "1", "#000000", 10.0)
        + svg_rect(4.0, 14.0, 10.0, 0.5, "#000000")
        + svg_text(4.0, 22.5, "x", "#000000", 10.0))
    if !tex_svg_of("\\frac{1}{x}").equals(expected) {
        panic("frac svg snapshot matches")
    }
}

[test]
micro snapshot_sqrt() -> unit {
    let expected: utf8 = svg_document(29.0, 18.5,
        svg_text(4.0, 12.5, "√", "#000000", 10.0)
        + svg_rect(15.0, 4.0, 10.0, 0.5, "#000000")
        + svg_text(15.0, 12.5, "a", "#000000", 10.0))
    if !tex_svg_of("\\sqrt{a}").equals(expected) {
        panic("sqrt svg snapshot matches")
    }
}

[test]
micro snapshot_greek_row() -> unit {
    let expected: utf8 = svg_document(43.0, 18.0,
        svg_text(4.0, 12.0, "α", "#000000", 10.0)
        + svg_text(16.5, 12.0, "+", "#000000", 10.0)
        + svg_text(29.0, 12.0, "β", "#000000", 10.0))
    if !tex_svg_of("\\alpha+\\beta").equals(expected) {
        panic("greek row svg snapshot matches")
    }
}

[test]
micro unclosed_group_keeps_value_with_diagnostic() -> unit {
    let outcome: DataOutcome<MathNode> = tex_parse_text("\\frac{1")
    let diagnostics: [Diagnostic] = data_outcome_diagnostics(outcome)
    if diagnostics.length() == 0 {
        panic("unclosed group reports a diagnostic")
    }
    if !diagnostics⁅0⁆.code.equals("tex.parse.unclosed_group") {
        panic("diagnostic carries the unclosed group code")
    }
}

[test]
micro unknown_command_degrades_visibly() -> unit {
    let outcome: DataOutcome<MathNode> = tex_parse_text("\\unknown{x}")
    let diagnostics: [Diagnostic] = data_outcome_diagnostics(outcome)
    let mut found: bool = false
    let mut index: usize = 0
    while index < diagnostics.length() {
        if diagnostics⁅index⁆.code.equals("tex.build.unknown_command") {
            found = true
        }
        index = index + 1
    }
    if !found {
        panic("unknown command reports a build diagnostic")
    }
    let svg: utf8 = tex_svg_of("\\unknown{x}")
    if !svg.equals(tex_svg_of("unknown{x}")) {
        panic("unknown command degrades to its name as visible symbols")
    }
}

[test]
micro duplicate_script_slot_reports() -> unit {
    let outcome: DataOutcome<MathNode> = tex_parse_text("x^1^2")
    let diagnostics: [Diagnostic] = data_outcome_diagnostics(outcome)
    let mut found: bool = false
    let mut index: usize = 0
    while index < diagnostics.length() {
        if diagnostics⁅index⁆.code.equals("tex.parse.duplicate_script") {
            found = true
        }
        index = index + 1
    }
    if !found {
        panic("duplicate script slot reports a parse diagnostic")
    }
}

[test]
micro render_is_deterministic() -> unit {
    if !tex_svg_of("\\frac{a_{1}}{\\sqrt{b}}+c^{2}").equals(tex_svg_of("\\frac{a_{1}}{\\sqrt{b}}+c^{2}")) {
        panic("same source renders the same bytes")
    }
}
