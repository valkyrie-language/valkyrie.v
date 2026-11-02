namespace std.data.text.mermaid;

using std.data::{DataOutcome, data_outcome_diagnostics, data_outcome_value_or};
using std.diagnostic::{Diagnostic};
using document.plot::{PlotScene, plot_arrow_head, plot_decl, plot_edge, plot_flowchart, plot_rect_outline, plot_sequence};
using document.vector::{svg_document, svg_line, svg_path, svg_path_line_to, svg_path_move_to, svg_rect, svg_text};

[test]
micro flowchart_svg_snapshot() -> unit {
    let outcome: DataOutcome<utf8> = mermaid_render_svg("graph TD\nA[Start] --> B[End]\n")
    let svg: utf8 = data_outcome_value_or(outcome, "")
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
    if !svg.equals(expected) {
        panic("flowchart svg snapshot matches")
    }
}

[test]
micro flowchart_edge_label_snapshot() -> unit {
    let outcome: DataOutcome<utf8> = mermaid_render_svg("graph TD\nA -->|go| B\n")
    let svg: utf8 = data_outcome_value_or(outcome, "")
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
    if !svg.equals(expected) {
        panic("edge label svg snapshot matches")
    }
}

[test]
micro sequence_svg_snapshot() -> unit {
    let outcome: DataOutcome<utf8> = mermaid_render_svg("sequenceDiagram\nparticipant A as Alice\nA->>B: hi\n")
    let svg: utf8 = data_outcome_value_or(outcome, "")
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
    if !svg.equals(expected) {
        panic("sequence svg snapshot matches")
    }
}

[test]
micro unsupported_header_fails_structured() -> unit {
    let outcome: DataOutcome<utf8> = mermaid_render_svg("graph LR\nA --> B\n")
    match outcome {
        case Failed(payload):
            if payload.diagnostics.length() == 0 {
                panic("unsupported header reports a diagnostic")
            }
            if !payload.diagnostics⁅payload.diagnostics.length() - 1⁆.code.equals("mermaid.build.unsupported_header") {
                panic("diagnostic carries the unsupported header code")
            }
        case Fine(payload):
            panic("left right direction is out of the subset")
        case Partial(payload):
            panic("left right direction must fail, not degrade")
    }
}

[test]
micro malformed_statement_reports_and_keeps_going() -> unit {
    let outcome: DataOutcome<utf8> = mermaid_render_svg("graph TD\nA ==\nB --> C\n")
    let diagnostics: [Diagnostic] = data_outcome_diagnostics(outcome)
    let mut found: bool = false
    let mut index: usize = 0
    while index < diagnostics.length() {
        if diagnostics⁅index⁆.code.equals("mermaid.parse.unexpected_statement") || diagnostics⁅index⁆.code.equals("mermaid.lex.malformed_arrow") || diagnostics⁅index⁆.code.equals("mermaid.build.malformed_statement") {
            found = true
        }
        index = index + 1
    }
    if !found {
        panic("malformed statement reports a diagnostic")
    }
    match outcome {
        case Failed(payload):
            panic("one bad statement must not fail the diagram")
        else:
            found = found
    }
}

[test]
micro render_is_deterministic() -> unit {
    let first: utf8 = data_outcome_value_or(mermaid_render_svg("graph TD\nA[Start] --> B[Mid]\nB --> C[End]\nA --> C\n"), "")
    let second: utf8 = data_outcome_value_or(mermaid_render_svg("graph TD\nA[Start] --> B[Mid]\nB --> C[End]\nA --> C\n"), "")
    if !first.equals(second) {
        panic("same source renders the same bytes")
    }
}
