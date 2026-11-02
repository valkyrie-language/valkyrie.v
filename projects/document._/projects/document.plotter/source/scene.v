namespace document.plotter;

using document.layout::{BoxFont, box_char_cell_font};
using document.vector::{svg_document, svg_line, svg_path, svg_path_curve_to, svg_path_dashed, svg_path_line_to, svg_path_move_to, svg_rect, svg_rect_round, svg_text};

# 场景模型与 SVG 发射。坐标 y 轴向下，原点左上。
#
# 节点形状（`PlotNode.shape`）：0 矩形、1 菱形、2 圆角矩形。
# 边（`PlotEdge`）：`direct=false`（flowchart，发射时推导几何），`true`
# （sequence，布局直写坐标）；`bidirectional` 两端出箭头。
# 发射顺序：聚类 → 分块框 → 生命线 → 激活条 → 边 → 便签 → 节点。

structure PlotNode {
    id: utf8
    label: utf8
    x: f64
    y: f64
    width: f64
    height: f64
    shape: i32
}

structure PlotEdge {
    source: utf8
    target: utf8
    label: utf8
    direct: bool
    bidirectional: bool
    x1: f64
    y1: f64
    x2: f64
    y2: f64
}

structure PlotCluster {
    label: utf8
    x: f64
    y: f64
    width: f64
    height: f64
}

structure PlotActivation {
    center_x: f64
    y1: f64
    y2: f64
}

structure PlotNote {
    x: f64
    y: f64
    width: f64
    text: utf8
}

structure PlotFrame {
    label: utf8
    x: f64
    y: f64
    width: f64
    height: f64
    dividers: [f64]
}

structure PlotScene {
    width: f64
    height: f64
    nodes: [PlotNode]
    edges: [PlotEdge]
    lifelines: [utf8]
    clusters: [PlotCluster]
    activations: [PlotActivation]
    notes: [PlotNote]
    frames: [PlotFrame]
}

micro plot_node(id: utf8, label: utf8, x: f64, y: f64, width: f64, height: f64) -> PlotNode {
    return plot_node_shaped(id, label, x, y, width, height, 0)
}

micro plot_node_shaped(id: utf8, label: utf8, x: f64, y: f64, width: f64, height: f64, shape: i32) -> PlotNode {
    return PlotNode {
        id: id,
        label: label,
        x: x,
        y: y,
        width: width,
        height: height,
        shape: shape
    }
}

# flowchart 边：几何发射时推导。
micro plot_edge(source: utf8, target: utf8, label: utf8) -> PlotEdge {
    return plot_edge_full(source, target, label, false)
}

micro plot_edge_full(source: utf8, target: utf8, label: utf8, bidirectional: bool) -> PlotEdge {
    return PlotEdge {
        source: source,
        target: target,
        label: label,
        direct: false,
        bidirectional: bidirectional,
        x1: 0.0,
        y1: 0.0,
        x2: 0.0,
        y2: 0.0
    }
}

# sequence 消息边：布局直写几何。
micro plot_edge_direct(source: utf8, target: utf8, label: utf8, x1: f64, y1: f64, x2: f64, y2: f64) -> PlotEdge {
    return PlotEdge {
        source: source,
        target: target,
        label: label,
        direct: true,
        bidirectional: false,
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2
    }
}

micro plot_font() -> BoxFont {
    return box_char_cell_font(10.0)
}

micro plot_find_node(scene: PlotScene, id: utf8) -> Option<PlotNode> {
    let mut index: usize = 0
    while index < scene.nodes.length() {
        if scene.nodes⁅index⁆.id.equals(id) {
            return Some(scene.nodes⁅index⁆)
        }
        index = index + 1
    }
    return None
}

# Newton 迭代开方（v0 算术自给；输入非负）。
micro plot_sqrt(value: f64) -> f64 {
    if value <= 0.0 {
        return 0.0
    }
    let mut guess: f64 = value
    if guess < 1.0 {
        guess = 1.0
    }
    let mut rounds: usize = 0
    while rounds < 32 {
        guess = (guess + value / guess) / 2.0
        rounds = rounds + 1
    }
    return guess
}

# 箭头尖端：从 `(tip_x, tip_y)` 沿来向 `(from_x, from_y)` 反向伸出两条短翼。
micro plot_arrow_head(from_x: f64, from_y: f64, tip_x: f64, tip_y: f64, size: f64) -> utf8 {
    let dx: f64 = tip_x - from_x
    let dy: f64 = tip_y - from_y
    let mut length: f64 = plot_sqrt(dx * dx + dy * dy)
    if length <= 0.0 {
        length = 1.0
    }
    let ux: f64 = dx / length
    let uy: f64 = dy / length
    let left_x: f64 = tip_x - ux * size - uy * size * 0.5
    let left_y: f64 = tip_y - uy * size + ux * size * 0.5
    let right_x: f64 = tip_x - ux * size + uy * size * 0.5
    let right_y: f64 = tip_y - uy * size - ux * size * 0.5
    return svg_path(svg_path_line_to(svg_path_line_to(svg_path_move_to(left_x, left_y), tip_x, tip_y), right_x, right_y), "#000000", 1.0, "none")
}

# 自消息曲线：`(x, y)` 起点向右的三次贝塞尔回环 + 回指箭头；标签在上方。
micro plot_emit_self_edge(x: f64, y: f64, label: utf8, font: BoxFont) -> utf8 {
    let stub: f64 = 30.0
    let drop: f64 = 14.0
    let data: utf8 = svg_path_curve_to(svg_path_move_to(x, y), x + stub, y, x + stub, y + drop, x, y + drop)
    let mut out: utf8 = svg_path(data, "#000000", 1.0, "none")
    out = out + plot_arrow_head(x + stub / 2.0, y + drop, x, y + drop, 6.0)
    if !label.equals("") {
        out = out + svg_text(x + 4.0, y - 2.0, label, "#000000", font.em)
    }
    return out
}

# 边标签避让：沿边的垂直方向偏移，避免压线。
micro plot_edge_label(x1: f64, y1: f64, x2: f64, y2: f64, label: utf8, font: BoxFont) -> utf8 {
    let dx: f64 = x2 - x1
    let dy: f64 = y2 - y1
    let mut length: f64 = plot_sqrt(dx * dx + dy * dy)
    if length <= 0.0 {
        length = 1.0
    }
    let px: f64 = dy / length
    let py: f64 = 0.0 - dx / length
    let mut offset_x: f64 = px * 6.0
    let mut offset_y: f64 = py * 6.0
    if offset_y > 0.0 {
        offset_y = 0.0 - offset_y
    }
    if offset_x < 0.0 {
        offset_x = 0.0 - offset_x
    }
    return svg_text((x1 + x2) / 2.0 + offset_x, (y1 + y2) / 2.0 + offset_y - 2.0, label, "#000000", font.em)
}

micro plot_emit_edge(scene: PlotScene, edge: PlotEdge, font: BoxFont) -> utf8 {
    if edge.direct {
        if edge.source.equals(edge.target) {
            return plot_emit_self_edge(edge.x1, edge.y1, edge.label, font)
        }
        let mut out: utf8 = svg_line(edge.x1, edge.y1, edge.x2, edge.y2, "#000000", 1.0)
        out = out + plot_arrow_head(edge.x1, edge.y1, edge.x2, edge.y2, 6.0)
        if edge.bidirectional {
            out = out + plot_arrow_head(edge.x2, edge.y2, edge.x1, edge.y1, 6.0)
        }
        if !edge.label.equals("") {
            out = out + plot_edge_label(edge.x1, edge.y1, edge.x2, edge.y2, edge.label, font)
        }
        return out
    }
    let from_node: Option<PlotNode> = plot_find_node(scene, edge.source)
    let to_node: Option<PlotNode> = plot_find_node(scene, edge.target)
    if from_node.is_none() || to_node.is_none() {
        return ""
    }
    let from: PlotNode = from_node.unwrap()
    let to: PlotNode = to_node.unwrap()
    let x1: f64 = from.x + from.width / 2.0
    let y1: f64 = from.y + from.height
    if edge.source.equals(edge.target) {
        return plot_emit_self_edge(x1, y1, edge.label, font)
    }
    let x2: f64 = to.x + to.width / 2.0
    let y2: f64 = to.y
    let mut out: utf8 = svg_line(x1, y1, x2, y2, "#000000", 1.0)
    out = out + plot_arrow_head(x1, y1, x2, y2, 6.0)
    if edge.bidirectional {
        out = out + plot_arrow_head(x2, y2, x1, y1, 6.0)
    }
    if !edge.label.equals("") {
        out = out + plot_edge_label(x1, y1, x2, y2, edge.label, font)
    }
    return out
}

# 矩形描边（rect 元素带填充，轮廓经 path 另描，保证描边独立于填充）。
micro plot_rect_outline(node: PlotNode) -> utf8 {
    let x1: f64 = node.x + node.width
    let y1: f64 = node.y + node.height
    return svg_path_line_to(svg_path_line_to(svg_path_line_to(svg_path_line_to(svg_path_move_to(node.x, node.y), x1, node.y), x1, y1), node.x, y1), node.x, node.y)
}

# 菱形轮廓：顶点在四条边中点。
micro plot_diamond_outline(node: PlotNode) -> utf8 {
    let cx: f64 = node.x + node.width / 2.0
    let cy: f64 = node.y + node.height / 2.0
    return svg_path_line_to(svg_path_line_to(svg_path_line_to(svg_path_line_to(svg_path_move_to(cx, node.y), node.x + node.width, cy), cx, node.y + node.height), node.x, cy), cx, node.y)
}

micro plot_emit_node(node: PlotNode, font: BoxFont) -> utf8 {
    let mut out: utf8 = ""
    if node.shape == 1 {
        out = out + svg_path(plot_diamond_outline(node), "#000000", 1.0, "#ffffff")
    } else if node.shape == 2 {
        out = out + svg_rect_round(node.x, node.y, node.width, node.height, "#ffffff", "#000000", 6.0)
    } else {
        out = out + svg_rect(node.x, node.y, node.width, node.height, "#ffffff")
        out = out + svg_path(plot_rect_outline(node), "#000000", 1.0, "none")
    }
    let label_width: f64 = node.label.length() as f64 * font.em
    out = out + svg_text(node.x + (node.width - label_width) / 2.0, node.y + (node.height + font.ascent - font.descent) / 2.0, node.label, "#000000", font.em)
    return out
}

micro plot_emit_svg(scene: PlotScene) -> utf8 {
    let font: BoxFont = plot_font()
    let mut body: utf8 = ""

    let mut cluster_index: usize = 0
    while cluster_index < scene.clusters.length() {
        let cluster: PlotCluster = scene.clusters⁅cluster_index⁆
        body = body + svg_rect_round(cluster.x, cluster.y, cluster.width, cluster.height, "#f6f6f6", "#999999", 4.0)
        let label_width: f64 = cluster.label.length() as f64 * font.em
        body = body + svg_text(cluster.x + (cluster.width - label_width) / 2.0, cluster.y + font.ascent + 4.0, cluster.label, "#666666", font.em)
        cluster_index = cluster_index + 1
    }

    let mut frame_index: usize = 0
    while frame_index < scene.frames.length() {
        let frame: PlotFrame = scene.frames⁅frame_index⁆
        body = body + svg_path_dashed(plot_rect_path(frame.x, frame.y, frame.width, frame.height), "#666666", 1.0, "none", "4 3")
        let label_width: f64 = frame.label.length() as f64 * font.em + 8.0
        body = body + svg_rect(frame.x, frame.y, label_width, 16.0, "#eeeeee")
        body = body + svg_path(plot_frame_tab(frame.x, frame.y, label_width), "#666666", 1.0, "none")
        body = body + svg_text(frame.x + 4.0, frame.y + font.ascent + 2.0, frame.label, "#333333", font.em)
        let mut divider_index: usize = 0
        while divider_index < frame.dividers.length() {
            body = body + svg_path_dashed(svg_path_line_to(svg_path_move_to(frame.x, frame.dividers⁅divider_index⁆), frame.x + frame.width, frame.dividers⁅divider_index⁆), "#666666", 1.0, "none", "4 3")
            divider_index = divider_index + 1
        }
        frame_index = frame_index + 1
    }

    let mut lifeline_index: usize = 0
    while lifeline_index < scene.lifelines.length() {
        let node: Option<PlotNode> = plot_find_node(scene, scene.lifelines⁅lifeline_index⁆)
        if node.is_some() {
            let lifeline: PlotNode = node.unwrap()
            let center_x: f64 = lifeline.x + lifeline.width / 2.0
            body = body + svg_path_dashed(svg_path_line_to(svg_path_move_to(center_x, lifeline.y + lifeline.height), center_x, scene.height), "#999999", 1.0, "none", "4 3")
        }
        lifeline_index = lifeline_index + 1
    }

    let mut activation_index: usize = 0
    while activation_index < scene.activations.length() {
        let activation: PlotActivation = scene.activations⁅activation_index⁆
        body = body + svg_rect(activation.center_x - 4.0, activation.y1, 8.0, activation.y2 - activation.y1, "#dddddd")
        body = body + svg_path(plot_activation_outline(activation), "#666666", 1.0, "none")
        activation_index = activation_index + 1
    }

    let mut edge_index: usize = 0
    while edge_index < scene.edges.length() {
        body = body + plot_emit_edge(scene, scene.edges⁅edge_index⁆, font)
        edge_index = edge_index + 1
    }

    let mut note_index: usize = 0
    while note_index < scene.notes.length() {
        let note: PlotNote = scene.notes⁅note_index⁆
        body = body + svg_rect(note.x, note.y, note.width, 20.0, "#ffffcc")
        body = body + svg_path(plot_note_outline(note), "#999999", 1.0, "none")
        body = body + svg_text(note.x + 4.0, note.y + font.ascent + 3.0, note.text, "#333333", font.em)
        note_index = note_index + 1
    }

    let mut node_index: usize = 0
    while node_index < scene.nodes.length() {
        body = body + plot_emit_node(scene.nodes⁅node_index⁆, font)
        node_index = node_index + 1
    }

    return svg_document(scene.width, scene.height, body)
}

micro plot_rect_path(x: f64, y: f64, width: f64, height: f64) -> utf8 {
    return svg_path_line_to(svg_path_line_to(svg_path_line_to(svg_path_line_to(svg_path_move_to(x, y), x + width, y), x + width, y + height), x, y + height), x, y)
}

micro plot_frame_tab(x: f64, y: f64, width: f64) -> utf8 {
    return svg_path_line_to(svg_path_line_to(svg_path_line_to(svg_path_move_to(x, y), x + width, y), x + width, y + 16.0), x, y + 16.0)
}

micro plot_activation_outline(activation: PlotActivation) -> utf8 {
    return plot_rect_path(activation.center_x - 4.0, activation.y1, 8.0, activation.y2 - activation.y1)
}

micro plot_note_outline(note: PlotNote) -> utf8 {
    return plot_rect_path(note.x, note.y, note.width, 20.0)
}
