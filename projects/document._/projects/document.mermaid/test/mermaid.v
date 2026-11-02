namespace document.mermaid;

using document.plot::{PlotScene, plot_arrow_head, plot_decl, plot_edge, plot_emit_self_edge, plot_font, plot_rect_outline, plot_flowchart, plot_sequence};
using document.vector::{svg_document, svg_line, svg_path, svg_path_line_to, svg_path_move_to, svg_rect, svg_text};

[test]
micro flowchart_parses_and_renders() -> unit {
    let rendered: Option<utf8> = mermaid_render_svg("graph TD\nA[Start] --> B[End]\n")
    if rendered.is_none() {
        panic("flowchart subset renders")
    }
    let scene: PlotScene = plot_flowchart([plot_decl("A", "Start"), plot_decl("B", "End")], [plot_edge("A", "B", "")])
    let expected: utf8 = svg_document(106.0, 116.0,
        svg_line(53.0, 38.0, 53.0, 78.0, "#000000", 1.0)
        + plot_arrow_head(53.0, 38.0, 53.0, 78.0, 6.0)
        + svg_rect(20.0, 20.0, 66.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅0⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 32.0, "Start", "#000000", 10.0)
        + svg_rect(30.0, 78.0, 46.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅1⁆), "#000000", 1.0, "none")
        + svg_text(38.0, 90.0, "End", "#000000", 10.0))
    if !rendered.unwrap().equals(expected) {
        panic("flowchart svg snapshot matches")
    }
}

[test]
micro flowchart_edge_labels_render() -> unit {
    let rendered: Option<utf8> = mermaid_render_svg("graph TD\nA -->|go| B\n")
    if rendered.is_none() {
        panic("edge label renders")
    }
    let scene: PlotScene = plot_flowchart([plot_decl("A", "A"), plot_decl("B", "B")], [plot_edge("A", "B", "go")])
    let expected: utf8 = svg_document(66.0, 116.0,
        svg_line(33.0, 38.0, 33.0, 78.0, "#000000", 1.0)
        + plot_arrow_head(33.0, 38.0, 33.0, 78.0, 6.0)
        + svg_text(33.0, 56.0, "go", "#000000", 10.0)
        + svg_rect(20.0, 20.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅0⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 32.0, "A", "#000000", 10.0)
        + svg_rect(20.0, 78.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅1⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 90.0, "B", "#000000", 10.0))
    if !rendered.unwrap().equals(expected) {
        panic("edge label svg snapshot matches")
    }
}

[test]
micro sequence_parses_participants_and_messages() -> unit {
    let rendered: Option<utf8> = mermaid_render_svg("sequenceDiagram\nparticipant A as Alice\nA->>B: hi\n")
    if rendered.is_none() {
        panic("sequence subset renders")
    }
    let scene: PlotScene = plot_sequence([plot_decl("A", "Alice"), plot_decl("B", "B")], [plot_edge("A", "B", "hi")])
    let expected: utf8 = svg_document(244.0, 138.0,
        svg_path(svg_path_line_to(svg_path_move_to(53.0, 38.0), 53.0, 138.0), "#666666", 1.0, "none")
        + svg_path(svg_path_line_to(svg_path_move_to(159.0, 38.0), 159.0, 138.0), "#666666", 1.0, "none")
        + svg_line(53.0, 78.0, 159.0, 78.0, "#000000", 1.0)
        + plot_arrow_head(53.0, 78.0, 159.0, 78.0, 6.0)
        + svg_text(106.0, 74.0, "hi", "#000000", 10.0)
        + svg_rect(20.0, 20.0, 66.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅0⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 32.0, "Alice", "#000000", 10.0)
        + svg_rect(146.0, 20.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅1⁆), "#000000", 1.0, "none")
        + svg_text(154.0, 32.0, "B", "#000000", 10.0))
    if !rendered.unwrap().equals(expected) {
        panic("sequence svg snapshot matches")
    }
}

[test]
micro parse_rejects_unsupported_or_malformed() -> unit {
    if mermaid_render_svg("graph LR\nA --> B\n").is_some() {
        panic("left right direction is out of the subset")
    }
    if mermaid_render_svg("graph TD\nA --> \n").is_some() {
        panic("missing edge target rejected")
    }
    if mermaid_render_svg("graph TD\nA(x) --> B\n").is_some() {
        panic("round node shape is out of the subset")
    }
    if mermaid_render_svg("sequenceDiagram\nA-->B: hi\n").is_some() {
        panic("unsupported arrow form rejected")
    }
    if mermaid_render_svg("not a diagram").is_some() {
        panic("unknown header rejected")
    }
}

[test]
micro render_is_deterministic() -> unit {
    let source: utf8 = "graph TD\nA[Start] --> B[Mid]\nB --> C[End]\nA --> C\n"
    let first: Option<utf8> = mermaid_render_svg(source)
    let second: Option<utf8> = mermaid_render_svg(source)
    if first.is_none() || second.is_none() {
        panic("chain flowchart renders")
    }
    if !first.unwrap().equals(second.unwrap()) {
        panic("same source renders the same bytes")
    }
}
