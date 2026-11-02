namespace vutex;

using document.vector::{svg_document, svg_rect, svg_text};

[test]
micro parse_accepts_supported_subset() -> unit {
    if math_parse("x^{2}").is_none() {
        panic("script parses")
    }
    if math_parse("\\frac{1}{x}").is_none() {
        panic("frac parses")
    }
    if math_parse("\\sqrt{a}").is_none() {
        panic("sqrt parses")
    }
    if math_parse("\\alpha+\\beta").is_none() {
        panic("greek and operator parse")
    }
    if math_parse("x_i^{2}").is_none() {
        panic("combined scripts parse")
    }
    if math_parse("(a+b) = {c-d}").is_none() {
        panic("row with braces parses")
    }
}

[test]
micro parse_rejects_malformed_sources() -> unit {
    if math_parse("\\frac{1").is_some() {
        panic("unclosed frac group rejected")
    }
    if math_parse("x^").is_some() {
        panic("dangling script rejected")
    }
    if math_parse("}").is_some() {
        panic("stray close brace rejected")
    }
    if math_parse("{x").is_some() {
        panic("unclosed group rejected")
    }
    if math_parse("\\unknown{x}").is_some() {
        panic("unsupported command rejected")
    }
    if math_parse("x^1^2").is_some() {
        panic("duplicate script slot rejected")
    }
}

[test]
micro svg_snapshot_script() -> unit {
    let rendered: Option<utf8> = math_render_svg("x^{2}", math_default_font())
    if rendered.is_none() {
        panic("script renders")
    }
    let expected: utf8 = svg_document(25.5, 21.0,
        svg_text(4.0, 15.0, "x", "#000000", 10.0)
        + svg_text(14.0, 10.0, "2", "#000000", 7.5))
    if !rendered.unwrap().equals(expected) {
        panic("script svg snapshot matches")
    }
}

[test]
micro svg_snapshot_frac() -> unit {
    let rendered: Option<utf8> = math_render_svg("\\frac{1}{x}", math_default_font())
    if rendered.is_none() {
        panic("frac renders")
    }
    let expected: utf8 = svg_document(18.0, 30.5,
        svg_text(4.0, 12.0, "1", "#000000", 10.0)
        + svg_rect(4.0, 14.0, 10.0, 0.5, "#000000")
        + svg_text(4.0, 22.5, "x", "#000000", 10.0))
    if !rendered.unwrap().equals(expected) {
        panic("frac svg snapshot matches")
    }
}

[test]
micro svg_snapshot_sqrt() -> unit {
    let rendered: Option<utf8> = math_render_svg("\\sqrt{a}", math_default_font())
    if rendered.is_none() {
        panic("sqrt renders")
    }
    let expected: utf8 = svg_document(29.0, 18.5,
        svg_text(4.0, 12.5, "√", "#000000", 10.0)
        + svg_rect(15.0, 4.0, 10.0, 0.5, "#000000")
        + svg_text(15.0, 12.5, "a", "#000000", 10.0))
    if !rendered.unwrap().equals(expected) {
        panic("sqrt svg snapshot matches")
    }
}

[test]
micro svg_snapshot_greek_row() -> unit {
    let rendered: Option<utf8> = math_render_svg("\\alpha+\\beta", math_default_font())
    if rendered.is_none() {
        panic("greek row renders")
    }
    let expected: utf8 = svg_document(43.0, 18.0,
        svg_text(4.0, 12.0, "α", "#000000", 10.0)
        + svg_text(16.5, 12.0, "+", "#000000", 10.0)
        + svg_text(29.0, 12.0, "β", "#000000", 10.0))
    if !rendered.unwrap().equals(expected) {
        panic("greek row svg snapshot matches")
    }
}

[test]
micro render_is_deterministic() -> unit {
    let first: Option<utf8> = math_render_svg("\\frac{a_{1}}{\\sqrt{b}}+c^{2}", math_default_font())
    let second: Option<utf8> = math_render_svg("\\frac{a_{1}}{\\sqrt{b}}+c^{2}", math_default_font())
    if first.is_none() || second.is_none() {
        panic("nested source renders")
    }
    if !first.unwrap().equals(second.unwrap()) {
        panic("same input renders the same bytes")
    }
}
