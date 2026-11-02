namespace document.vector;

[test]
micro escape_text_covers_markup_signs() -> unit {
    if !svg_escape_text("a&b<c>d").equals("a&amp;b&lt;c&gt;d") {
        panic("text escape covers ampersand and angle brackets")
    }
    if !svg_escape_text("it's").equals("it's") {
        panic("apostrophe stays literal in text content")
    }
}

[test]
micro escape_attribute_covers_apostrophe() -> unit {
    if !svg_escape_attribute("it's").equals("it&apos;s") {
        panic("attribute escape covers apostrophe")
    }
}

[test]
micro text_element_has_fixed_attribute_order() -> unit {
    let expected: utf8 = "<text x='" + format("{}", 10.0)
        + "' y='" + format("{}", 20.0)
        + "' fill='#000000' font-size='" + format("{}", 12.0)
        + "' font-family='monospace'>a&lt;b</text>"
    if !svg_text(10.0, 20.0, "a<b", "#000000", 12.0).equals(expected) {
        panic("text element emits fixed attribute order with escaped content")
    }
}

[test]
micro rect_line_circle_and_path_emit() -> unit {
    let rect: utf8 = svg_rect(1.0, 2.0, 30.0, 40.0, "#ff0000")
    if !rect.equals("<rect x='" + format("{}", 1.0) + "' y='" + format("{}", 2.0)
        + "' width='" + format("{}", 30.0) + "' height='" + format("{}", 40.0)
        + "' fill='#ff0000'/>") {
        panic("rect element emits")
    }

    let line: utf8 = svg_line(0.0, 1.0, 2.0, 3.0, "#00ff00", 2.0)
    if !line.equals("<line x1='" + format("{}", 0.0) + "' y1='" + format("{}", 1.0)
        + "' x2='" + format("{}", 2.0) + "' y2='" + format("{}", 3.0)
        + "' stroke='#00ff00' stroke-width='" + format("{}", 2.0) + "'/>") {
        panic("line element emits")
    }

    let circle: utf8 = svg_circle(5.0, 6.0, 7.0, "#0000ff")
    if !circle.equals("<circle cx='" + format("{}", 5.0) + "' cy='" + format("{}", 6.0)
        + "' r='" + format("{}", 7.0) + "' fill='#0000ff'/>") {
        panic("circle element emits")
    }

    let path: utf8 = svg_path(svg_path_line_to(svg_path_move_to(0.0, 0.0), 10.0, 10.0), "#000000", 1.0, "none")
    if !path.equals("<path d='M " + format("{}", 0.0) + " " + format("{}", 0.0)
        + " L " + format("{}", 10.0) + " " + format("{}", 10.0)
        + "' stroke='#000000' stroke-width='" + format("{}", 1.0) + "' fill='none'/>") {
        panic("path element emits built path data")
    }
}

[test]
micro document_wraps_with_viewbox() -> unit {
    let document: utf8 = svg_document(100.0, 50.0, svg_group("<g/>"))
    let expected: utf8 = "<svg xmlns='http://www.w3.org/2000/svg' width='" + format("{}", 100.0)
        + "' height='" + format("{}", 50.0)
        + "' viewBox='0 0 " + format("{}", 100.0) + " " + format("{}", 50.0)
        + "'><g><g/></g></svg>"
    if !document.equals(expected) {
        panic("document emits namespace, size and viewBox")
    }
}

[test]
micro output_is_deterministic() -> unit {
    let first: utf8 = svg_document(10.0, 10.0, svg_text(1.0, 2.0, "x", "#000000", 12.0))
    let second: utf8 = svg_document(10.0, 10.0, svg_text(1.0, 2.0, "x", "#000000", 12.0))
    if !first.equals(second) {
        panic("same input emits the same bytes")
    }
}
