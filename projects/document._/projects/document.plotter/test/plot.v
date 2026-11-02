namespace document.plot;

using document.vector::{svg_document, svg_line, svg_path, svg_path_dashed, svg_path_line_to, svg_path_move_to, svg_rect, svg_rect_round, svg_text};

[test]
micro diamond_and_rounded_shapes_emit() -> unit {
    let scene: PlotScene = plot_flowchart([plot_decl_shaped("a", "A", 1), plot_decl_shaped("b", "B", 2)], [])
    let svg: utf8 = plot_emit_svg(scene)
    let diamond: utf8 = svg_path(plot_diamond_outline(scene.nodes⁅0⁆), "#000000", 1.0, "#ffffff")
    let rounded: utf8 = svg_rect_round(scene.nodes⁅1⁆.x, scene.nodes⁅1⁆.y, scene.nodes⁅1⁆.width, scene.nodes⁅1⁆.height, "#ffffff", "#000000", 6.0)
    let expected: utf8 = svg_document(scene.width, scene.height,
        diamond + svg_text(37.0, 37.0, "A", "#000000", 10.0)
        + rounded + svg_text(121.0, 32.0, "B", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("diamond and rounded shapes emit")
    }
}

[test]
micro bidirectional_edge_draws_two_heads() -> unit {
    let scene: PlotScene = plot_flowchart([plot_decl("a", "A"), plot_decl("b", "B")], [plot_edge_full("a", "b", "", true)])
    let svg: utf8 = plot_emit_svg(scene)
    let expected: utf8 = svg_document(66.0, 116.0,
        svg_line(33.0, 38.0, 33.0, 78.0, "#000000", 1.0)
        + plot_arrow_head(33.0, 38.0, 33.0, 78.0, 6.0)
        + plot_arrow_head(33.0, 78.0, 33.0, 38.0, 6.0)
        + svg_rect(20.0, 20.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅0⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 32.0, "A", "#000000", 10.0)
        + svg_rect(20.0, 78.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅1⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 90.0, "B", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("bidirectional edge draws arrow heads at both ends")
    }
}

[test]
micro cluster_draws_bounding_box() -> unit {
    let scene: PlotScene = plot_flowchart([plot_decl_clustered("a", "A", 0, "grp"), plot_decl_clustered("b", "B", 0, "grp")], [plot_edge("a", "b", "")])
    let svg: utf8 = plot_emit_svg(scene)
    if scene.clusters.length() != 1 {
        panic("one shared cluster for the group")
    }
    let cluster: PlotCluster = scene.clusters⁅0⁆
    if cluster.x != 8.0 || cluster.width != 50.0 || cluster.height != 100.0 {
        panic("cluster wraps members with padding")
    }
    let expected: utf8 = svg_document(66.0, 116.0,
        svg_rect_round(8.0, 8.0, 50.0, 100.0, "#f6f6f6", "#999999", 4.0)
        + svg_text(33.0 - 15.0, 20.0, "grp", "#666666", 10.0)
        + svg_line(33.0, 38.0, 33.0, 78.0, "#000000", 1.0)
        + plot_arrow_head(33.0, 38.0, 33.0, 78.0, 6.0)
        + svg_rect(20.0, 20.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅0⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 32.0, "A", "#000000", 10.0)
        + svg_rect(20.0, 78.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅1⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 90.0, "B", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("cluster svg snapshot matches")
    }
}

[test]
micro sequence_activation_note_frame_emit() -> unit {
    let spec: PlotSequenceSpec = plot_sequence_spec([plot_decl("a", "A"), plot_decl("b", "B")], [
        SeqMessage { source: "a", target: "b", label: "hi" },
        SeqActivate { target: "b" },
        SeqMessage { source: "b", target: "a", label: "ack" },
        SeqDeactivate { target: "b" },
        SeqNote { target: "a", side: 1, text: "ok" },
        SeqFrameBegin { label: "alt" },
        SeqMessage { source: "a", target: "b", label: "again" },
        SeqFrameElse { label: "else" },
        SeqMessage { source: "b", target: "a", label: "never" },
        SeqFrameEnd
    ])
    let scene: PlotScene = plot_sequence_full(spec)
    if scene.activations.length() != 1 {
        panic("activation bar pairs activate and deactivate")
    }
    if scene.notes.length() != 1 {
        panic("note placed")
    }
    if scene.frames.length() != 1 || scene.frames⁅0⁆.dividers.length() != 1 {
        panic("frame with one else divider")
    }
    let activation: PlotActivation = scene.activations⁅0⁆
    if activation.y2 <= activation.y1 {
        panic("activation spans downward")
    }
    let svg: utf8 = plot_emit_svg(scene)
    if svg.length() == 0 {
        panic("scene emits")
    }
}

[test]
micro self_message_draws_curve() -> unit {
    let scene: PlotScene = plot_sequence([plot_decl("a", "A")], [plot_edge("a", "a", "loop")])
    let svg: utf8 = plot_emit_svg(scene)
    let expected: utf8 = svg_document(66.0, 98.0,
        svg_path_dashed(svg_path_line_to(svg_path_move_to(33.0, 38.0), 33.0, 98.0), "#999999", 1.0, "none", "4 3")
        + plot_emit_self_edge(33.0, 78.0, "loop", plot_font())
        + svg_rect(20.0, 20.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅0⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 32.0, "A", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("self message draws a curved arrow")
    }
}


[test]
micro flowchart_layers_follow_longest_path() -> unit {
    let decls: [PlotDecl] = [plot_decl("a", "A"), plot_decl("b", "B"), plot_decl("c", "C"), plot_decl("d", "D")]
    let edges: [PlotEdge] = [plot_edge("a", "b", ""), plot_edge("b", "c", ""), plot_edge("a", "c", "")]
    let layers: [usize] = plot_flowchart_layers(decls, edges)
    if layers⁅0⁆ != 0 || layers⁅1⁆ != 1 || layers⁅2⁆ != 2 {
        panic("longest path layering wins over direct edge")
    }
    if layers⁅3⁆ != 0 {
        panic("isolated node stays at layer zero")
    }
}

[test]
micro flowchart_layout_positions_nodes_in_grid() -> unit {
    let scene: PlotScene = plot_flowchart([plot_decl("a", "A"), plot_decl("b", "B")], [plot_edge("a", "b", "")])
    if scene.nodes.length() != 2 {
        panic("both nodes placed")
    }
    if scene.nodes⁅0⁆.y != 20.0 || scene.nodes⁅1⁆.y != 78.0 {
        panic("layers stack vertically")
    }
    if scene.nodes⁅0⁆.x != 20.0 || scene.nodes⁅1⁆.x != 20.0 {
        panic("single node layers align on the grid")
    }
    if scene.nodes⁅0⁆.width != 26.0 || scene.nodes⁅0⁆.height != 18.0 {
        panic("node geometry follows label measure")
    }
    if scene.width != 66.0 || scene.height != 116.0 {
        panic("canvas covers the grid")
    }
}

[test]
micro flowchart_svg_snapshot() -> unit {
    let scene: PlotScene = plot_flowchart([plot_decl("a", "A"), plot_decl("b", "B")], [plot_edge("a", "b", "")])
    let svg: utf8 = plot_emit_svg(scene)
    let expected: utf8 = svg_document(66.0, 116.0,
        svg_line(33.0, 38.0, 33.0, 78.0, "#000000", 1.0)
        + plot_arrow_head(33.0, 38.0, 33.0, 78.0, 6.0)
        + svg_rect(20.0, 20.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅0⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 32.0, "A", "#000000", 10.0)
        + svg_rect(20.0, 78.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅1⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 90.0, "B", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("flowchart svg snapshot matches")
    }
}

[test]
micro sequence_layout_spaces_messages() -> unit {
    let scene: PlotScene = plot_sequence([plot_decl("a", "A"), plot_decl("b", "B")], [
        plot_edge("a", "b", "hello"),
        plot_edge("b", "a", "ack")
    ])
    if scene.nodes.length() != 2 || scene.edges.length() != 2 {
        panic("participants and messages placed")
    }
    if scene.edges⁅0⁆.y1 != 78.0 || scene.edges⁅1⁆.y1 != 118.0 {
        panic("messages stack by declaration order")
    }
    if scene.edges⁅0⁆.x1 != 33.0 || scene.edges⁅0⁆.x2 != 119.0 {
        panic("messages span lifeline centers")
    }
    if scene.lifelines.length() != 2 {
        panic("lifelines follow participants")
    }
}

[test]
micro sequence_svg_snapshot() -> unit {
    let scene: PlotScene = plot_sequence([plot_decl("a", "A"), plot_decl("b", "B")], [plot_edge("a", "b", "hi")])
    let svg: utf8 = plot_emit_svg(scene)
    let expected: utf8 = svg_document(152.0, 138.0,
        svg_path_dashed(svg_path_line_to(svg_path_move_to(33.0, 38.0), 33.0, 138.0), "#999999", 1.0, "none", "4 3")
        + svg_path_dashed(svg_path_line_to(svg_path_move_to(119.0, 38.0), 119.0, 138.0), "#999999", 1.0, "none", "4 3")
        + svg_line(33.0, 78.0, 119.0, 78.0, "#000000", 1.0)
        + plot_arrow_head(33.0, 78.0, 119.0, 78.0, 6.0)
        + svg_text(76.0, 74.0, "hi", "#000000", 10.0)
        + svg_rect(20.0, 20.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅0⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 32.0, "A", "#000000", 10.0)
        + svg_rect(106.0, 20.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅1⁆), "#000000", 1.0, "none")
        + svg_text(114.0, 32.0, "B", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("sequence svg snapshot matches")
    }
}

[test]
micro self_message_draws_stub() -> unit {
    let scene: PlotScene = plot_sequence([plot_decl("a", "A")], [plot_edge("a", "a", "loop")])
    let svg: utf8 = plot_emit_svg(scene)
    let expected: utf8 = svg_document(66.0, 138.0,
        svg_path_dashed(svg_path_line_to(svg_path_move_to(33.0, 38.0), 33.0, 138.0), "#999999", 1.0, "none", "4 3")
        + plot_emit_self_edge(33.0, 78.0, "loop", plot_font())
        + svg_rect(20.0, 20.0, 26.0, 18.0, "#ffffff")
        + svg_path(plot_rect_outline(scene.nodes⁅0⁆), "#000000", 1.0, "none")
        + svg_text(28.0, 32.0, "A", "#000000", 10.0))
    if !svg.equals(expected) {
        panic("self message svg snapshot matches")
    }
}
