namespace document.plot;

using document.layout::{BoxFont, box_char_cell_font};
using document.vector::{svg_document, svg_line, svg_path, svg_path_line_to, svg_path_move_to, svg_rect, svg_text};

# 场景模型与 SVG 发射。坐标 y 轴向下，原点左上。
#
# 边几何两种来源（`PlotEdge.direct`）：
# - `false`（flowchart）：发射时按源底中点 → 目标顶中点连线；自环在底中点出 stub。
# - `true`（sequence）：布局已写入 `(x1, y1) → (x2, y2)`；自消息以 `(x1, y1)` 为起点出 stub。
# v0 形约定：节点矩形白底黑框 + 居中标签；边标签放中点上方。

structure PlotNode {
    id: utf8
    label: utf8
    x: f64
    y: f64
    width: f64
    height: f64
}

structure PlotEdge {
    source: utf8
    target: utf8
    label: utf8
    direct: bool
    x1: f64
    y1: f64
    x2: f64
    y2: f64
}

structure PlotScene {
    width: f64
    height: f64
    nodes: [PlotNode]
    edges: [PlotEdge]
    lifelines: [utf8]
}

micro plot_node(id: utf8, label: utf8, x: f64, y: f64, width: f64, height: f64) -> PlotNode {
    return PlotNode {
        id: id,
        label: label,
        x: x,
        y: y,
        width: width,
        height: height
    }
}

# flowchart 边：几何发射时推导。
micro plot_edge(source: utf8, target: utf8, label: utf8) -> PlotEdge {
    return PlotEdge {
        source: source,
        target: target,
        label: label,
        direct: false,
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

# 自环/自消息：`(x, y)` 起点右出-下-回的三段折线 + 回指箭头；标签在起点上方。
micro plot_emit_self_edge(x: f64, y: f64, label: utf8, font: BoxFont) -> utf8 {
    let stub: f64 = 30.0
    let drop: f64 = 14.0
    let data: utf8 = svg_path_line_to(svg_path_line_to(svg_path_move_to(x, y), x + stub, y), x + stub, y + drop)
    let mut out: utf8 = svg_path(svg_path_line_to(data, x, y + drop), "#000000", 1.0, "none")
    out = out + plot_arrow_head(x + stub, y + drop, x, y + drop, 6.0)
    if !label.equals("") {
        out = out + svg_text(x + 4.0, y - 2.0, label, "#000000", font.em)
    }
    return out
}

# 矩形描边（rect 元素带填充，轮廓经 path 另描，保证描边独立于填充）。
micro plot_rect_outline(node: PlotNode) -> utf8 {
    let x1: f64 = node.x + node.width
    let y1: f64 = node.y + node.height
    return svg_path_line_to(svg_path_line_to(svg_path_line_to(svg_path_line_to(svg_path_move_to(node.x, node.y), x1, node.y), x1, y1), node.x, y1), node.x, node.y)
}

micro plot_emit_edge(scene: PlotScene, edge: PlotEdge, font: BoxFont) -> utf8 {
    if edge.direct {
        if edge.source.equals(edge.target) {
            return plot_emit_self_edge(edge.x1, edge.y1, edge.label, font)
        }
        let mut out: utf8 = svg_line(edge.x1, edge.y1, edge.x2, edge.y2, "#000000", 1.0)
        out = out + plot_arrow_head(edge.x1, edge.y1, edge.x2, edge.y2, 6.0)
        if !edge.label.equals("") {
            out = out + svg_text((edge.x1 + edge.x2) / 2.0, edge.y1 - 4.0, edge.label, "#000000", font.em)
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
    if !edge.label.equals("") {
        out = out + svg_text((x1 + x2) / 2.0, (y1 + y2) / 2.0 - 2.0, edge.label, "#000000", font.em)
    }
    return out
}

micro plot_emit_svg(scene: PlotScene) -> utf8 {
    let font: BoxFont = plot_font()
    let mut body: utf8 = ""

    let mut lifeline_index: usize = 0
    while lifeline_index < scene.lifelines.length() {
        let node: Option<PlotNode> = plot_find_node(scene, scene.lifelines⁅lifeline_index⁆)
        if node.is_some() {
            let lifeline: PlotNode = node.unwrap()
            let center_x: f64 = lifeline.x + lifeline.width / 2.0
            body = body + svg_path(svg_path_line_to(svg_path_move_to(center_x, lifeline.y + lifeline.height), center_x, scene.height), "#666666", 1.0, "none")
        }
        lifeline_index = lifeline_index + 1
    }

    let mut edge_index: usize = 0
    while edge_index < scene.edges.length() {
        body = body + plot_emit_edge(scene, scene.edges⁅edge_index⁆, font)
        edge_index = edge_index + 1
    }

    let mut node_index: usize = 0
    while node_index < scene.nodes.length() {
        let node: PlotNode = scene.nodes⁅node_index⁆
        body = body + svg_rect(node.x, node.y, node.width, node.height, "#ffffff")
        body = body + svg_path(plot_rect_outline(node), "#000000", 1.0, "none")
        let label_width: f64 = node.label.length() as f64 * font.em
        body = body + svg_text(node.x + (node.width - label_width) / 2.0, node.y + (node.height + font.ascent - font.descent) / 2.0, node.label, "#000000", font.em)
        node_index = node_index + 1
    }

    return svg_document(scene.width, scene.height, body)
}
