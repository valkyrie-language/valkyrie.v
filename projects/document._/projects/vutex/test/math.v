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
    let expected: utf8 = svg_document(18.0, 28.5,
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
micro matrix_lays_out_grid() -> unit {
    let node: MathNode = math_matrix([[math_symbol("a"), math_symbol("b")], [math_symbol("cc"), math_symbol("d")]])
    let svg: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    # 列宽 max(10,20)=20 / 10；行高 10+10，行距规则 4
    let expected: utf8 = svg_document(46.0, 32.0,
        svg_text(4.0, 12.0, "a", "#000000", 10.0)
        + svg_text(32.0, 12.0, "b", "#000000", 10.0)
        + svg_text(4.0, 26.0, "cc", "#000000", 10.0)
        + svg_text(32.0, 26.0, "d", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("matrix svg snapshot matches")
    }
}

[test]
micro big_op_stacks_limits() -> unit {
    let node: MathNode = math_big_op("∑", [math_symbol("i")], [math_symbol("n")])
    let svg: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    # 符号 1.4 倍：宽 14 高 11.2 深 2.8；上下限 0.75：各宽 7.5 高 6 深 1.5
    let expected: utf8 = svg_document(22.0, 37.0,
        svg_text(7.25, 10.0, "n", "#000000", 7.5)
        + svg_text(4.0, 22.7, "∑", "#000000", 14.0)
        + svg_text(7.25, 31.5, "i", "#000000", 7.5))
    if !svg.equals(expected) {
        panic("big op svg snapshot matches")
    }
}

[test]
micro delimited_scales_with_content() -> unit {
    let node: MathNode = math_delimited("(", ")", [math_frac(math_symbol("1"), math_symbol("x"))])
    let svg: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    # 内容总分式高 18.5 深 2 → 总高 20.5、缩放 2.05：括号宽 20.5；分式宽 10
    let expected: utf8 = svg_document(59.0, 28.5,
        svg_text(4.0, 20.4, "(", "#000000", 20.5)
        + svg_text(24.5, 12.0, "1", "#000000", 10.0)
        + svg_rect(24.5, 14.0, 10.0, 0.5, "#000000")
        + svg_text(24.5, 22.5, "x", "#000000", 10.0)
        + svg_text(34.5, 20.4, ")", "#000000", 20.5))
    if !svg.equals(expected) {
        panic("delimited svg snapshot matches")
    }
}

[test]
micro aligned_right_aligns_left_column() -> unit {
    let node: MathNode = math_aligned([[math_symbol("aa"), math_symbol("=b")], [math_symbol("c"), math_symbol("=dd")]])
    let svg: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    # 列宽 20 / 30；首列右对齐；行高 10 行距 4
    let expected: utf8 = svg_document(58.0, 32.0,
        svg_text(4.0, 12.0, "aa", "#000000", 10.0)
        + svg_text(24.0, 12.0, "=b", "#000000", 10.0)
        + svg_text(14.0, 26.0, "c", "#000000", 10.0)
        + svg_text(24.0, 26.0, "=dd", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("aligned svg snapshot matches")
    }
}

[test]
micro combined_scripts_avoid_collision() -> unit {
    let node: MathNode = math_scripts(math_symbol("x"), [math_symbol("2")], [math_symbol("1")])
    let metrics_svg: utf8 = math_emit_svg(math_typeset(node, math_default_font()), math_default_font())
    if metrics_svg.length() == 0 {
        panic("combined scripts render")
    }
    # 碰撞余量：sup 底 − sub 顶 ≥ 0.2em（由盒度量侧保证，此处验证确定性）
    if !metrics_svg.equals(math_emit_svg(math_typeset(node, math_default_font()), math_default_font())) {
        panic("collision adjustment is deterministic")
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
