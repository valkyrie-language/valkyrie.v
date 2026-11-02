namespace vutex;

using document.vector::{svg_document, svg_rect, svg_text};

# 盒构造与发射的测试：AST 由构造器直建（解析归 `std.data.text.tex`）。

[test]
micro snapshot_script() -> unit {
    let node: MathNode = math_scripts(math_symbol("x"), [math_symbol("2")], [])
    let svg: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    let expected: utf8 = svg_document(25.5, 21.0,
        svg_text(4.0, 15.0, "x", "#000000", 10.0)
        + svg_text(14.0, 10.0, "2", "#000000", 7.5))
    if !svg.equals(expected) {
        panic("script svg snapshot matches")
    }
}

[test]
micro snapshot_frac() -> unit {
    let node: MathNode = math_frac(math_symbol("1"), math_symbol("x"))
    let svg: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    let expected: utf8 = svg_document(18.0, 30.5,
        svg_text(4.0, 12.0, "1", "#000000", 10.0)
        + svg_rect(4.0, 14.0, 10.0, 0.5, "#000000")
        + svg_text(4.0, 22.5, "x", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("frac svg snapshot matches")
    }
}

[test]
micro snapshot_sqrt() -> unit {
    let node: MathNode = math_sqrt(math_symbol("a"))
    let svg: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    let expected: utf8 = svg_document(29.0, 18.5,
        svg_text(4.0, 12.5, "√", "#000000", 10.0)
        + svg_rect(15.0, 4.0, 10.0, 0.5, "#000000")
        + svg_text(15.0, 12.5, "a", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("sqrt svg snapshot matches")
    }
}

[test]
micro snapshot_row_with_thin_glue() -> unit {
    let node: MathNode = math_row([math_symbol("α"), math_symbol("+"), math_symbol("β")])
    let svg: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    let expected: utf8 = svg_document(43.0, 18.0,
        svg_text(4.0, 12.0, "α", "#000000", 10.0)
        + svg_text(16.5, 12.0, "+", "#000000", 10.0)
        + svg_text(29.0, 12.0, "β", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("row svg snapshot matches")
    }
}

[test]
micro emit_is_deterministic() -> unit {
    let node: MathNode = math_frac(math_scripts(math_symbol("a"), [], [math_symbol("1")]), math_sqrt(math_symbol("b")))
    let first: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    let second: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    if !first.equals(second) {
        panic("same tree emits the same bytes")
    }
}
